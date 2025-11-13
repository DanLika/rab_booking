import * as crypto from "crypto";
import {admin} from "./firebase";

/**
 * Generate a secure access token for booking lookup
 * Token is a random 32-character string that is hashed before storage
 */
export function generateBookingAccessToken(): {
  token: string;
  hashedToken: string;
} {
  // Generate random 32-character token (alphanumeric)
  const token = crypto.randomBytes(24).toString("base64url").substring(0, 32);

  // Hash token for secure storage (SHA-256)
  const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

  return {token, hashedToken};
}

/**
 * Calculate token expiration date (checkout date + 30 days)
 */
export function calculateTokenExpiration(
  checkOutDate: admin.firestore.Timestamp
): admin.firestore.Timestamp {
  const checkOut = checkOutDate.toDate();
  const expiration = new Date(checkOut);
  expiration.setDate(expiration.getDate() + 30); // 30 days after checkout

  return admin.firestore.Timestamp.fromDate(expiration);
}

/**
 * Verify if access token matches stored hash
 */
export function verifyAccessToken(
  providedToken: string,
  storedHash: string
): boolean {
  const hashedProvidedToken = crypto
    .createHash("sha256")
    .update(providedToken)
    .digest("hex");

  return hashedProvidedToken === storedHash;
}
