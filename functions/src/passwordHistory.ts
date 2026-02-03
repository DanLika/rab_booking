/**
 * Password History Management
 *
 * Tracks password history to prevent users from reusing recent passwords.
 * Stores SHA-256 hashes of passwords (not plaintext) in Firestore.
 *
 * SECURITY:
 * - Passwords are hashed with SHA-256 before storage
 * - Only the last 5 password hashes are stored
 * - Hashes are stored in a secure subcollection
 *
 * @module passwordHistory
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as bcrypt from "bcrypt";
import {logInfo, logWarn} from "./logger";
import {setUser} from "./sentry";

const db = admin.firestore();

/**
 * Number of previous passwords to track
 */
const PASSWORD_HISTORY_SIZE = 5;

/**
 * Bcrypt salt rounds - 12 provides good security/performance balance
 * Higher = more secure but slower (each +1 doubles computation time)
 */
const BCRYPT_SALT_ROUNDS = 12;

/**
 * Hash a password using bcrypt
 *
 * SECURITY: bcrypt is designed for password hashing with:
 * - Built-in salt generation (prevents rainbow table attacks)
 * - Configurable work factor (prevents brute force)
 * - Constant-time comparison (prevents timing attacks)
 *
 * @param password - Plain text password
 * @return bcrypt hash string
 */
async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_SALT_ROUNDS);
}

/**
 * Compare a password against a stored hash
 *
 * @param password - Plain text password to check
 * @param hash - Stored bcrypt hash
 * @return true if password matches hash
 */
async function comparePassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

/**
 * Check if a password was recently used
 *
 * Call this Cloud Function before changing a user's password.
 * Returns success if password is allowed, throws HttpsError if recently used.
 *
 * @param password - New password to check (will be hashed before comparison)
 * @returns {allowed: true} if password is allowed
 * @throws HttpsError with code "failed-precondition" if password was recently used
 *
 * @example
 * // Dart code:
 * final callable = FirebaseFunctions.instance.httpsCallable('checkPasswordHistory');
 * await callable.call({'password': newPassword});
 * // If no error, proceed with password change
 */
export const checkPasswordHistory = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    // Require authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    // Set user context for Sentry error tracking
    setUser(userId);

    const {password} = request.data as {password?: string};
    if (!password) {
      throw new HttpsError("invalid-argument", "Password is required");
    }

    // Get password history
    const historyRef = db
      .collection("users")
      .doc(userId)
      .collection("security")
      .doc("passwordHistory");

    const doc = await historyRef.get();
    const history = doc.exists ? (doc.data()?.hashes || []) as string[] : [];

    // Check if password was recently used
    // SECURITY: Must compare against each hash since bcrypt includes random salt
    for (const storedHash of history) {
      const isMatch = await comparePassword(password, storedHash);
      if (isMatch) {
        logWarn("[PasswordHistory] Password reuse attempt", {userId});
        throw new HttpsError(
          "failed-precondition",
          "You cannot reuse a recently used password. Please choose a different password."
        );
      }
    }

    logInfo("[PasswordHistory] Password check passed", {userId});
    return {allowed: true};
  }
);

/**
 * Save a password to history after successful change
 *
 * Call this Cloud Function after successfully changing a user's password.
 * Stores the hash and maintains only the last N passwords.
 *
 * @param password - New password that was just set (will be hashed before storage)
 * @returns {success: true} on successful save
 *
 * @example
 * // Dart code (after password change succeeds):
 * final callable = FirebaseFunctions.instance.httpsCallable('savePasswordToHistory');
 * await callable.call({'password': newPassword});
 */
export const savePasswordToHistory = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    // Require authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    // Set user context for Sentry error tracking
    setUser(userId);

    const {password} = request.data as {password?: string};
    if (!password) {
      throw new HttpsError("invalid-argument", "Password is required");
    }

    // Hash the password using bcrypt
    const passwordHash = await hashPassword(password);

    // Get current history
    const historyRef = db
      .collection("users")
      .doc(userId)
      .collection("security")
      .doc("passwordHistory");

    const doc = await historyRef.get();
    const history = doc.exists ? (doc.data()?.hashes || []) as string[] : [];

    // Add new hash and keep only last N
    const updatedHistory = [...history, passwordHash].slice(-PASSWORD_HISTORY_SIZE);

    // Save updated history
    await historyRef.set({
      hashes: updatedHistory,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logInfo("[PasswordHistory] Password saved to history", {
      userId,
      historySize: updatedHistory.length,
    });

    return {success: true};
  }
);
