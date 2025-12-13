/**
 * Password Reset Service
 * 
 * Custom password reset email using Resend with premium template
 * Replaces default Firebase Auth email with branded design
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";
import {logError, logSuccess, logOperation} from "./logger";
import {validateEmail} from "./utils/emailValidation";
import {sanitizeEmail} from "./utils/inputSanitization";
import {sendPasswordResetEmailV2} from "./email/templates/password-reset-v2";
import {Resend} from "resend";

// Lazy initialization of Resend client
let resend: Resend | null = null;
function getResendClient(): Resend {
  if (!resend) {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) {
      throw new Error(
        "RESEND_API_KEY environment variable not configured. " +
        "Get your API key from: https://resend.com/api-keys"
      );
    }
    resend = new Resend(apiKey);
  }
  return resend;
}

// Get email configuration
function getFromEmail(): string {
  const fromEmail = process.env.FROM_EMAIL;
  if (!fromEmail) {
    throw new Error("FROM_EMAIL environment variable not configured");
  }
  return fromEmail;
}

function getFromName(): string {
  return process.env.FROM_NAME || "BookBed";
}

/**
 * Send password reset email with custom template
 * 
 * This function:
 * 1. Validates email address
 * 2. Generates password reset link using Firebase Admin SDK
 * 3. Sends custom branded email via Resend
 * 
 * Rate limiting: Firebase Auth handles rate limiting automatically
 */
export const sendPasswordResetEmail = onCall(
  {cors: true},
  async (request) => {
    try {
      const {email} = request.data;

      // Validate input
      if (!email || typeof email !== "string") {
        throw new HttpsError("invalid-argument", "Email is required");
      }

      // SECURITY: Sanitize email first
      const sanitizedEmail = sanitizeEmail(email);
      if (!sanitizedEmail) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format. Please enter a valid email address."
        );
      }

      // RFC-compliant email validation
      if (!validateEmail(sanitizedEmail)) {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format. Please enter a valid email address."
        );
      }

      const emailLower = sanitizedEmail.toLowerCase().trim();
      logOperation(`Sending password reset email to: ${emailLower.substring(0, 3)}...`);

      // Get Firebase Auth instance
      const auth = getAuth();

      // Generate password reset link
      // This creates a secure, time-limited link that Firebase Auth will accept
      const actionCodeSettings = {
        // URL you want to redirect back to after password reset
        // This should be your app's password reset page
        url: process.env.PASSWORD_RESET_REDIRECT_URL || 
             (process.env.WEB_APP_URL ? `${process.env.WEB_APP_URL}/auth/reset-password` : 
              "https://bookbed.app/auth/reset-password"),
        handleCodeInApp: false, // Open link in browser, not app
      };

      const resetLink = await auth.generatePasswordResetLink(
        emailLower,
        actionCodeSettings
      );

      logSuccess(`Password reset link generated for: ${emailLower.substring(0, 3)}...`);

      // Send custom email via Resend
      const resendClient = getResendClient();
      await sendPasswordResetEmailV2(
        resendClient,
        {
          email: emailLower,
          resetLink: resetLink,
          expiresInMinutes: 60, // Firebase default is 1 hour
        },
        getFromEmail(),
        getFromName()
      );

      logSuccess(`Password reset email sent successfully to: ${emailLower.substring(0, 3)}...`);

      return {
        success: true,
        message: "Password reset email sent successfully",
      };
    } catch (error: any) {
      logError("Error sending password reset email", error);

      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      // Handle Firebase Auth errors
      if (error.code === "auth/user-not-found") {
        // Don't reveal if user exists - return success anyway for security
        // This prevents email enumeration attacks
        return {
          success: true,
          message: "If an account exists, a password reset email has been sent",
        };
      }

      if (error.code === "auth/invalid-email") {
        throw new HttpsError(
          "invalid-argument",
          "Invalid email format. Please enter a valid email address."
        );
      }

      // Wrap other errors
      throw new HttpsError(
        "internal",
        `Failed to send password reset email: ${error.message}`
      );
    }
  }
);

