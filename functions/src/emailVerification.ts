import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {createHash} from "crypto";
import {logError, logSuccess, logOperation} from "./logger";
import {sendEmailVerificationCode as sendVerificationEmail} from "./emailService";

/**
 * Generate 6-digit verification code
 */
function generateVerificationCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
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
 * 2. Stores in Firestore with 10-minute expiry
 * 3. Sends email via Resend
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

      const emailLower = email.toLowerCase().trim();

      // Basic email validation
      if (!emailLower.includes("@") || !emailLower.includes(".")) {
        throw new HttpsError("invalid-argument", "Invalid email format");
      }

      logOperation(`Sending verification code to ${emailLower}`);

      const db = getFirestore();
      const emailHash = hashEmail(emailLower);
      const verificationRef = db.collection("email_verifications").doc(emailHash);

      // Check existing verification document
      const existingDoc = await verificationRef.get();

      // Rate limiting: Check daily count
      if (existingDoc.exists) {
        const data = existingDoc.data();
        const now = new Date();
        const createdAt = data?.createdAt?.toDate();

        // Reset daily count if last sent was more than 24 hours ago
        const isDifferentDay = !createdAt ||
          (now.getTime() - createdAt.getTime()) > 24 * 60 * 60 * 1000;

        if (!isDifferentDay && data?.dailyCount >= 5) {
          throw new HttpsError(
            "resource-exhausted",
            "Too many verification attempts. Please try again tomorrow."
          );
        }

        // Prevent spam: Min 60 seconds between sends
        const lastSentAt = data?.lastSentAt?.toDate();
        if (lastSentAt && (now.getTime() - lastSentAt.getTime()) < 60000) {
          throw new HttpsError(
            "resource-exhausted",
            "Please wait 60 seconds before requesting a new code"
          );
        }
      }

      // Generate new code
      const code = generateVerificationCode();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

      // Store in Firestore
      await verificationRef.set({
        code,
        email: emailLower,
        expiresAt,
        verified: false,
        attempts: 0,
        lastSentAt: FieldValue.serverTimestamp(),
        createdAt: existingDoc.exists ?
          existingDoc.data()?.createdAt :
          FieldValue.serverTimestamp(),
        dailyCount: existingDoc.exists ?
          FieldValue.increment(1) :
          1,
      }, {merge: true});

      // Send email via Resend
      await sendVerificationEmail(emailLower, code);

      logSuccess(`Verification code sent to ${emailLower}`);

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
 * 2. Checks expiry (10 minutes)
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

      const emailLower = email.toLowerCase().trim();
      const codeClean = code.trim();

      logOperation(`Verifying code for ${emailLower}`);

      const db = getFirestore();
      const emailHash = hashEmail(emailLower);
      const verificationRef = db.collection("email_verifications").doc(emailHash);

      // Get verification document
      const doc = await verificationRef.get();

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
          success: true,
          verified: true,
          message: "Email already verified",
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
      if (data.attempts >= 3) {
        throw new HttpsError(
          "permission-denied",
          "Too many failed attempts. Please request a new code."
        );
      }

      // Verify code
      if (data.code !== codeClean) {
        // Increment failed attempts
        await verificationRef.update({
          attempts: FieldValue.increment(1),
        });

        const remainingAttempts = 3 - (data.attempts + 1);

        throw new HttpsError(
          "invalid-argument",
          `Invalid code. ${remainingAttempts} attempt${remainingAttempts === 1 ? "" : "s"} remaining.`
        );
      }

      // CODE IS VALID - Mark as verified
      await verificationRef.update({
        verified: true,
        verifiedAt: FieldValue.serverTimestamp(),
      });

      logSuccess(`Email verified successfully: ${emailLower}`);

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
 * Returns verification status without requiring code
 */
export const checkEmailVerificationStatus = onCall(
  {cors: true},
  async (request) => {
    try {
      const {email} = request.data;

      if (!email || typeof email !== "string") {
        throw new HttpsError("invalid-argument", "Email is required");
      }

      const emailLower = email.toLowerCase().trim();
      const db = getFirestore();
      const emailHash = hashEmail(emailLower);
      const verificationRef = db.collection("email_verifications").doc(emailHash);

      const doc = await verificationRef.get();

      if (!doc.exists) {
        return {
          verified: false,
          exists: false,
        };
      }

      const data = doc.data()!;
      const expiresAt = data.expiresAt?.toDate();
      const isExpired = !expiresAt || new Date() > expiresAt;

      return {
        verified: data.verified === true && !isExpired,
        exists: true,
        expired: isExpired,
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
