import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import * as crypto from "crypto";
import {setUser} from "./sentry";

/**
 * Booking.com Calendar API Integration
 * 
 * Implements Booking.com Connectivity API using Machine Account Authentication.
 * 
 * Documentation: https://developers.booking.com/connectivity/docs/token-based-authentication
 */

// Configuration
const BOOKING_COM_CLIENT_ID = process.env.BOOKING_COM_CLIENT_ID || "";
const BOOKING_COM_CLIENT_SECRET = process.env.BOOKING_COM_CLIENT_SECRET || "";

// API Base URLs
const BOOKING_COM_AUTH_URL = "https://connectivity-authentication.booking.com/token-based-authentication/exchange";
// TODO: Update with actual API base URL after getting API access
// Placeholder - replace with actual Booking.com API endpoint
const BOOKING_COM_API_BASE_URL = "https://distribution-xml.booking.com/2.3/json";

/**
 * Encrypt sensitive data (tokens) before storing in Firestore
 */
export function encryptToken(token: string): string {
  // In production, use proper encryption (e.g., Google Cloud KMS)
  // For now, we'll use a simple base64 encoding (NOT secure for production)
  // TODO: Implement proper encryption with KMS
  const encryptionKey = process.env.ENCRYPTION_KEY || "default-key-change-in-production";
  // Generate a consistent IV from the key (not secure, but matches deprecated createCipher behavior)
  const key = crypto.createHash("sha256").update(encryptionKey).digest();
  const iv = crypto.createHash("md5").update(encryptionKey).digest().slice(0, 16);
  const cipher = crypto.createCipheriv("aes-256-cbc", key, iv);
  let encrypted = cipher.update(token, "utf8", "hex");
  encrypted += cipher.final("hex");
  return encrypted;
}

/**
 * Decrypt sensitive data (tokens) from Firestore
 */
export function decryptToken(encryptedToken: string): string {
  // In production, use proper decryption (e.g., Google Cloud KMS)
  // TODO: Implement proper decryption with KMS
  const encryptionKey = process.env.ENCRYPTION_KEY || "default-key-change-in-production";
  // Generate a consistent IV from the key (not secure, but matches deprecated createDecipher behavior)
  const key = crypto.createHash("sha256").update(encryptionKey).digest();
  const iv = crypto.createHash("md5").update(encryptionKey).digest().slice(0, 16);
  const decipher = crypto.createDecipheriv("aes-256-cbc", key, iv);
  let decrypted = decipher.update(encryptedToken, "hex", "utf8");
  decrypted += decipher.final("utf8");
  return decrypted;
}

/**
 * Get or create the global Machine Account Token.
 * Handles caching in Firestore to respect the 30 requests/hour rate limit.
 */
async function getGlobalMachineAccountToken(): Promise<string> {
  const tokenDocRef = db.collection("system_configs").doc("booking_com_token");

  try {
    // 1. Try to get cached token
    const doc = await tokenDocRef.get();
    if (doc.exists) {
      const data = doc.data()!;
      const expiresAt = data.expiresAt.toDate();
      // Add buffer of 5 minutes to ensure token is valid when used
      if (expiresAt > new Date(Date.now() + 5 * 60 * 1000)) {
        return decryptToken(data.accessToken);
      }
    }

    // 2. If missing or expired, fetch new one
    logInfo("[Booking.com Auth] Global token missing or expired, fetching new one");

    const response = await fetch(BOOKING_COM_AUTH_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        client_id: BOOKING_COM_CLIENT_ID,
        client_secret: BOOKING_COM_CLIENT_SECRET,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      logError("[Booking.com Auth] Token exchange failed", null, {
        status: response.status,
        error: errorText,
      });
      throw new Error(`Token exchange failed: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    const accessToken = data.jwt || data.access_token;
    // Default to 1 hour (3600s) if not provided
    const expiresIn = data.expires_in || 3600;
    const expiresAt = new Date(Date.now() + expiresIn * 1000);

    // 3. Store in Firestore
    await tokenDocRef.set({
      accessToken: encryptToken(accessToken),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    return accessToken;

  } catch (error) {
    logError("[Booking.com Auth] Error getting global machine token", error);
    throw error;
  }
}

/**
 * Initiate/Create Booking.com Connection
 *
 * Uses Machine Account Authentication. Since there is no user redirect flow,
 * this function directly verifies credentials (by ensuring we have a valid global token)
 * and creates the connection record.
 */
export const initiateBookingComOAuth = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Set user context for Sentry error tracking
  setUser(request.auth.uid);

  const {unitId, hotelId, roomTypeId} = request.data;

  if (!unitId || !hotelId || !roomTypeId) {
    throw new HttpsError(
      "invalid-argument",
      "unitId, hotelId, and roomTypeId are required"
    );
  }

  try {
    logInfo("[Booking.com Connection] Creating connection", {
      userId: request.auth.uid,
      unitId,
      hotelId,
      roomTypeId,
    });

    // 1. Ensure we have a valid global token (validates app credentials indirectly)
    // We don't store the token in the connection document anymore to avoid duplication
    // and rate limit issues.
    await getGlobalMachineAccountToken();

    // 2. Create/Update platform connection document
    // We check if one exists for this unit to avoid duplicates or update existing
    const connectionsQuery = await db.collection("platform_connections")
      .where("owner_id", "==", request.auth.uid)
      .where("unit_id", "==", unitId)
      .where("platform", "==", "booking_com")
      .get();

    let connectionRef;
    if (!connectionsQuery.empty) {
      connectionRef = connectionsQuery.docs[0].ref;
    } else {
      connectionRef = db.collection("platform_connections").doc();
    }

    await connectionRef.set({
      owner_id: request.auth.uid,
      platform: "booking_com",
      unit_id: unitId,
      external_property_id: hotelId,
      external_unit_id: roomTypeId,
      // We do NOT store access_token here anymore. It's managed globally.
      status: "active",
      created_at: admin.firestore.Timestamp.now(),
      updated_at: admin.firestore.Timestamp.now(),
    }, { merge: true });

    logSuccess("[Booking.com Connection] Connection created successfully", {
      connectionId: connectionRef.id,
      userId: request.auth.uid,
    });

    // Return success. Frontend expects a Map but handles missing 'authorizationUrl'.
    return {
      success: true,
      connectionId: connectionRef.id,
      status: "connected"
    };

  } catch (error) {
    logError("[Booking.com Connection] Failed to create connection", error);
    throw new HttpsError("internal", "Failed to create Booking.com connection. Please check configuration.");
  }
});

/**
 * Get valid access token for a connection.
 *
 * For Machine Accounts, this now retrieves the Shared/Global token
 * instead of a connection-specific one.
 */
async function getValidAccessToken(connectionId: string): Promise<string> {
  // We still verify the connection exists and is active
  const connectionDoc = await db
    .collection("platform_connections")
    .doc(connectionId)
    .get();

  if (!connectionDoc.exists) {
    throw new Error("Connection not found");
  }

  // Future: Check if connection.status === 'active'

  // Return the global token
  return await getGlobalMachineAccountToken();
}

/**
 * Block dates on Booking.com calendar
 */
export async function blockDatesOnBookingCom(
  connectionId: string,
  hotelId: string,
  roomTypeId: string,
  dates: Array<{start: Date; end: Date}>
): Promise<void> {
  try {
    logInfo("[Booking.com API] Blocking dates", {
      connectionId,
      hotelId,
      roomTypeId,
      dateCount: dates.length,
    });

    const accessToken = await getValidAccessToken(connectionId);

    // Booking.com API endpoint for blocking dates
    // Note: This is a placeholder - actual API endpoint may differ
    const apiUrl = `${BOOKING_COM_API_BASE_URL}/hotels/${hotelId}/room-types/${roomTypeId}/availability`;

    for (const dateRange of dates) {
      const response = await fetch(apiUrl, {
        method: "PUT",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          start_date: dateRange.start.toISOString().split("T")[0],
          end_date: dateRange.end.toISOString().split("T")[0],
          available: false,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logError("[Booking.com API] Failed to block dates", null, {
          status: response.status,
          error: errorText,
          dateRange,
        });
        throw new Error(`Failed to block dates: ${response.status}`);
      }
    }

    logSuccess("[Booking.com API] Dates blocked successfully", {
      connectionId,
      dateCount: dates.length,
    });
  } catch (error) {
    logError("[Booking.com API] Error blocking dates", error, {
      connectionId,
    });
    throw error;
  }
}

/**
 * Unblock dates on Booking.com calendar
 */
export async function unblockDatesOnBookingCom(
  connectionId: string,
  hotelId: string,
  roomTypeId: string,
  dates: Array<{start: Date; end: Date}>
): Promise<void> {
  try {
    logInfo("[Booking.com API] Unblocking dates", {
      connectionId,
      hotelId,
      roomTypeId,
      dateCount: dates.length,
    });

    const accessToken = await getValidAccessToken(connectionId);

    const apiUrl = `${BOOKING_COM_API_BASE_URL}/hotels/${hotelId}/room-types/${roomTypeId}/availability`;

    for (const dateRange of dates) {
      const response = await fetch(apiUrl, {
        method: "PUT",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          start_date: dateRange.start.toISOString().split("T")[0],
          end_date: dateRange.end.toISOString().split("T")[0],
          available: true,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logError("[Booking.com API] Failed to unblock dates", null, {
          status: response.status,
          error: errorText,
        });
        throw new Error(`Failed to unblock dates: ${response.status}`);
      }
    }

    logSuccess("[Booking.com API] Dates unblocked successfully", {
      connectionId,
      dateCount: dates.length,
    });
  } catch (error) {
    logError("[Booking.com API] Error unblocking dates", error, {
      connectionId,
    });
    throw error;
  }
}

/**
 * Get reservations from Booking.com
 */
export async function getBookingComReservations(
  connectionId: string,
  hotelId: string,
  roomTypeId: string
): Promise<any[]> {
  try {
    logInfo("[Booking.com API] Fetching reservations", {
      connectionId,
      hotelId,
      roomTypeId,
    });

    const accessToken = await getValidAccessToken(connectionId);

    // Booking.com API endpoint for getting reservations
    const apiUrl = `${BOOKING_COM_API_BASE_URL}/hotels/${hotelId}/reservations`;

    const response = await fetch(apiUrl, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      logError("[Booking.com API] Failed to fetch reservations", null, {
        status: response.status,
        error: errorText,
      });
      throw new Error(`Failed to fetch reservations: ${response.status}`);
    }

    const data = await response.json();
    const reservations = data.reservations || [];

    logSuccess("[Booking.com API] Reservations fetched", {
      connectionId,
      count: reservations.length,
    });

    return reservations;
  } catch (error) {
    logError("[Booking.com API] Error fetching reservations", error, {
      connectionId,
    });
    throw error;
  }
}
