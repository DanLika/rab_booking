import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {createHash, randomInt} from "crypto";
import {logError, logSuccess, logOperation} from "./logger";
import {sendEmailVerificationCode as sendVerificationEmail} from "./emailService";
import {validateEmail} from "./utils/emailValidation";
import {sanitizeEmail} from "./utils/inputSanitization";

/**
 * Get UTC day string (YYYY-MM-DD) for consistent daily reset across timezones
 *
 * SECURITY: Using UTC ensures consistent behavior globally and prevents
 * timezone manipulation attacks
 */
function getUTCDayString(date: Date): string {
  return date.toISOString().split("T")[0];
}

// ============================================
// Configuration Constants
// ============================================
const VERIFICATION_TTL_MINUTES = 30; // Extended from 10 to 30 minutes
const MAX_ATTEMPTS = 3;
const DAILY_LIMIT = 5;
const RESEND_COOLDOWN_SECONDS = 60;

/**
 * Generate 6-digit verification code
 * Uses crypto.randomInt for cryptographically secure random numbers
 */
function generateVerificationCode(): string {
  return randomInt(100000, 1000000).toString();
}

/**
 * Hash email for Firestore document ID (privacy)
 */
function hashEmail(email: string): string {
  return createHash("sha256").update(email.toLowerCase().trim()).digest("hex");
}

/**
 * Send email verification code to guest
 *
 * Callable function that:
 * 1. Generates 6-digit code
 * 2. Stores in Firestore with 30-minute expiry
 * 3. Sends email via Resend
 * 4. Tracks session ID and device fingerprint
 *
 * Rate limiting: Max 5 codes per email per day
 */
export const sendEmailVerificationCode = onCall(
  {cors: true},
  async (request) => {
    try {
      const {email} = request.data;

      // Validate input
      if (!email || typeof email !== "string") {
        throw new HttpsError("invalid-argument", "Email is required");
      }

      // SECURITY FIX: Sanitize email first (removes confusables, control chars)
      const sanitizedEmail = sanitizeEmail(email);
      if (!sanitizedEmail) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format. Please enter a valid email address."
        );
      }

      // RFC-compliant email validation (better UX than basic check)
      if (!validateEmail(sanitizedEmail)) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format. Please enter a valid email address."
        );
      }

      // SECURITY: Use sanitized email for all operations
      const emailLower = sanitizedEmail;

      // PII REDUCTION: Log hashed email instead of full address
      const emailHashForLog = hashEmail(emailLower).substring(0, 8);
      logOperation(`Sending verification code to email hash: ${emailHashForLog}...`);

      const db = getFirestore();
      const emailHash = hashEmail(emailLower);
      const verificationRef = db.collection("email_verifications").doc(emailHash);

      // Generate new code and session ID BEFORE transaction
      // (These don't depend on document state)
      const code = generateVerificationCode();
      const expiresAt = new Date(Date.now() + VERIFICATION_TTL_MINUTES * 60 * 1000); // 30 minutes

      // Generate session ID for tracking (SHA-256 of timestamp + email + random)
      const sessionId = createHash("sha256")
        .update(`${Date.now()}-${emailLower}-${Math.random()}`)
        .digest("hex");

      // Extract device fingerprint from request headers
      const userAgent = request.rawRequest?.headers?.["user-agent"] || "unknown";
      const ipAddress = request.rawRequest?.ip || "unknown";

      // RACE CONDITION FIX: Use transaction to atomically check AND update daily count
      // This ensures two simultaneous requests can't both pass the limit check
      await db.runTransaction(async (transaction) => {
        const existingDoc = await transaction.get(verificationRef);
        const now = new Date();

        // Rate limiting: Check daily count INSIDE transaction
        if (existingDoc.exists) {
          const data = existingDoc.data();
          const createdAt = data?.createdAt?.toDate();

          // SECURITY FIX: Use UTC day boundary for consistent global behavior
          // Previous code used 24-hour window which allowed timezone gaming
          // Now resets at midnight UTC for all users regardless of timezone
          const createdAtUTCDay = createdAt ? getUTCDayString(createdAt) : null;
          const nowUTCDay = getUTCDayString(now);
          const isDifferentDay = !createdAtUTCDay || createdAtUTCDay !== nowUTCDay;

          // Get current count (0 if resetting for new day)
          const currentCount = isDifferentDay ? 0 : (data?.dailyCount || 0);

          if (currentCount >= DAILY_LIMIT) {
            throw new HttpsError(
              "resource-exhausted",
              "Too many verification attempts. Please try again tomorrow."
            );
          }

          // Prevent spam: Min 60 seconds between sends
          const lastSentAt = data?.lastSentAt?.toDate();
          if (lastSentAt && (now.getTime() - lastSentAt.getTime()) < (RESEND_COOLDOWN_SECONDS * 1000)) {
            throw new HttpsError(
              "resource-exhausted",
              `Please wait ${RESEND_COOLDOWN_SECONDS} seconds before requesting a new code`
            );
          }

          // Update existing document with incremented count
          transaction.update(verificationRef, {
            code,
            expiresAt,
            verified: false,
            attempts: 0,
            lastSentAt: FieldValue.serverTimestamp(),
            // Reset createdAt and dailyCount if it's a new day
            ...(isDifferentDay ? {
              createdAt: FieldValue.serverTimestamp(),
              dailyCount: 1,
            } : {
              dailyCount: FieldValue.increment(1),
            }),
            sessionId,
            deviceFingerprint: {userAgent, ipAddress},
          });
        } else {
          // Create new document
          transaction.set(verificationRef, {
            code,
            email: emailLower,
            expiresAt,
            verified: false,
            attempts: 0,
            lastSentAt: FieldValue.serverTimestamp(),
            createdAt: FieldValue.serverTimestamp(),
            dailyCount: 1,
            sessionId,
            deviceFingerprint: {userAgent, ipAddress},
          });
        }
      });

      // Send email via Resend
      await sendVerificationEmail(emailLower, code);

      // PII REDUCTION: Log hash instead of full email
      logSuccess(`Verification code sent to email hash: ${emailHashForLog}...`);

      return {
        success: true,
        expiresAt: expiresAt.toISOString(),
        message: "Verification code sent successfully",
      };
    } catch (error: any) {
      logError("Error sending verification code", error);

      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      // Wrap other errors
      throw new HttpsError(
        "internal",
        `Failed to send verification code: ${error.message}`
      );
    }
  }
);

/**
 * Verify email code entered by guest
 *
 * Callable function that:
 * 1. Validates code against Firestore
 * 2. Checks expiry (30 minutes)
 * 3. Checks attempts (max 3)
 * 4. Marks as verified if valid
 */
export const verifyEmailCode = onCall(
  {cors: true},
  async (request) => {
    try {
      const {email, code} = request.data;

      // Validate input
      if (!email || typeof email !== "string") {
        throw new HttpsError("invalid-argument", "Email is required");
      }
      if (!code || typeof code !== "string") {
        throw new HttpsError("invalid-argument", "Code is required");
      }

      // SECURITY FIX: Sanitize email (removes confusables, control chars)
      const sanitizedEmail = sanitizeEmail(email);
      if (!sanitizedEmail) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format."
        );
      }

      const emailLower = sanitizedEmail;
      const codeClean = code.trim();

      // PII REDUCTION: Log hash instead of full email
      const emailHashForLog = hashEmail(emailLower).substring(0, 8);
      logOperation(`Verifying code for email hash: ${emailHashForLog}...`);

      const db = getFirestore();
      const emailHash = hashEmail(emailLower);
      const verificationRef = db.collection("email_verifications").doc(emailHash);

      // RACE CONDITION FIX: Use transaction to atomically check AND update attempts
      // This ensures two simultaneous requests can't both pass the attempt limit check
      const result = await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(verificationRef);

        if (!doc.exists) {
          throw new HttpsError(
            "not-found",
            "No verification code found. Please request a new code."
          );
        }

        const data = doc.data()!;

        // Check if already verified
        if (data.verified === true) {
          return {
            alreadyVerified: true,
          };
        }

        // Check expiry
        const expiresAt = data.expiresAt?.toDate();
        if (!expiresAt || new Date() > expiresAt) {
          throw new HttpsError(
            "deadline-exceeded",
            "Verification code expired. Please request a new code."
          );
        }

        // Check max attempts (3 failed attempts = locked)
        if (data.attempts >= MAX_ATTEMPTS) {
          throw new HttpsError(
            "permission-denied",
            "Too many failed attempts. Please request a new code."
          );
        }

        // Verify code
        if (data.code !== codeClean) {
          // Increment failed attempts ATOMICALLY inside transaction
          const newAttempts = (data.attempts || 0) + 1;
          transaction.update(verificationRef, {
            attempts: newAttempts,
          });

          // Calculate remaining based on NEW value (after increment)
          const remainingAttempts = MAX_ATTEMPTS - newAttempts;

          // If this was the last attempt, throw lockout error
          if (remainingAttempts <= 0) {
            throw new HttpsError(
              "permission-denied",
              "Too many failed attempts. Please request a new code."
            );
          }

          throw new HttpsError(
            "invalid-argument",
            `Invalid code. ${remainingAttempts} attempt${remainingAttempts === 1 ? "" : "s"} remaining.`
          );
        }

        // CODE IS VALID - Mark as verified ATOMICALLY
        transaction.update(verificationRef, {
          verified: true,
          verifiedAt: FieldValue.serverTimestamp(),
        });

        return {
          verified: true,
        };
      });

      // Handle already verified case (returned from transaction)
      if (result.alreadyVerified) {
        return {
          success: true,
          verified: true,
          message: "Email already verified",
        };
      }

      // PII REDUCTION: Log hash instead of full email
      logSuccess(`Email verified successfully: hash ${emailHashForLog}...`);

      return {
        success: true,
        verified: true,
        message: "Email verified successfully",
      };
    } catch (error: any) {
      logError("Error verifying code", error);

      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      // Wrap other errors
      throw new HttpsError(
        "internal",
        `Failed to verify code: ${error.message}`
      );
    }
  }
);

/**
 * Check if email is verified (helper for booking flow)
 *
 * Returns verification status without requiring code.
 * Useful for pre-checking if user needs to verify email again
 * or if their verification is still valid.
 *
 * Response includes:
 * - verified: boolean - Is email verified and not expired?
 * - exists: boolean - Does verification document exist?
 * - expired: boolean - Is verification expired?
 * - remainingMinutes: number - Minutes until expiry
 * - verifiedAt: string | null - ISO timestamp when verified
 * - sessionId: string | null - Session ID for tracking
 */
export const checkEmailVerificationStatus = onCall(
  {cors: true},
  async (request) => {
    try {
      const {email} = request.data;

      if (!email || typeof email !== "string") {
        throw new HttpsError("invalid-argument", "Email is required");
      }

      // SECURITY FIX: Sanitize email (removes confusables, control chars)
      const sanitizedEmail = sanitizeEmail(email);
      if (!sanitizedEmail) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format."
        );
      }

      const emailLower = sanitizedEmail;
      const db = getFirestore();
      const emailHash = hashEmail(emailLower);
      const verificationRef = db.collection("email_verifications").doc(emailHash);

      const doc = await verificationRef.get();

      if (!doc.exists) {
        return {
          verified: false,
          exists: false,
          expired: false,
          remainingMinutes: 0,
          verifiedAt: null,
          sessionId: null,
        };
      }

      const data = doc.data()!;
      const expiresAt = data.expiresAt?.toDate();
      const isExpired = !expiresAt || new Date() > expiresAt;

      // Calculate remaining time in minutes
      const remainingMinutes = expiresAt ?
        Math.max(0, Math.floor((expiresAt.getTime() - Date.now()) / 60000)) :
        0;

      return {
        verified: data.verified === true && !isExpired,
        exists: true,
        expired: isExpired,
        remainingMinutes, // How many minutes until expiry
        verifiedAt: data.verifiedAt?.toDate().toISOString() || null,
        sessionId: data.sessionId || null, // Include for session tracking
      };
    } catch (error: any) {
      logError("Error checking verification status", error);
      throw new HttpsError(
        "internal",
        `Failed to check verification status: ${error.message}`
      );
    }
  }
);
