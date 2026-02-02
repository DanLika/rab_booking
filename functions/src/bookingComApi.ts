import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess, logWarn} from "./logger";
import * as crypto from "crypto";
import {checkRateLimit} from "./utils/rateLimit";
import {setUser} from "./sentry";

/**
 * Booking.com Calendar API Integration
 *
 * ⚠️ IMPORTANT: Direct API access is currently NOT AVAILABLE
 *
 * Status: Partner program PAUSED (as of late 2024)
 * Requirements: Business registration, PCI compliance, partner approval
 * Timeline: Indefinite (3-6 months historically when accepting applications)
 *
 * This code is kept for reference but will not work without partner approval.
 *
 * RECOMMENDED ALTERNATIVE: Use channel manager APIs (Beds24, Hosthub, Guesty)
 * See: docs/CHANNEL_MANAGER_SETUP.md
 *
 * Technical Notes:
 * - Does NOT use standard OAuth 2.0 (proprietary token-based auth)
 * - Uses OTA XML format (not JSON)
 * - No reservation webhooks (must poll Reservations API)
 *
 * Documentation: https://developers.booking.com/connectivity/docs (restricted access)
 */

// Configuration
const BOOKING_COM_CLIENT_ID = process.env.BOOKING_COM_CLIENT_ID || "";
const BOOKING_COM_CLIENT_SECRET = process.env.BOOKING_COM_CLIENT_SECRET || "";
const BOOKING_COM_REDIRECT_URI = process.env.BOOKING_COM_REDIRECT_URI || "";
// TODO: Update with actual API base URL after getting API access
// Placeholder - replace with actual Booking.com API endpoint
const BOOKING_COM_API_BASE_URL = "https://distribution-xml.booking.com/2.3/json";

/**
 * Get encryption key with validation (fail-fast approach)
 * Throws HttpsError if key is not configured or uses insecure default
 * @return {string} The validated encryption key
 */
function getEncryptionKey(): string {
  const encryptionKey = process.env.ENCRYPTION_KEY;

  if (!encryptionKey || encryptionKey === "default-key-change-in-production") {
    logError(
      "[Encryption] CRITICAL: ENCRYPTION_KEY not configured or insecure.",
      new Error("ENCRYPTION_KEY is not configured.")
    );
    throw new HttpsError(
      "internal",
      "The server is misconfigured. Unable to perform encryption."
    );
  }
  return encryptionKey;
}

/**
 * Encrypt sensitive data (tokens) before storing in Firestore
 */
export function encryptToken(token: string): string {
  // In production, use proper encryption (e.g., Google Cloud KMS)
  // SECURITY: Uses AES-256-CBC with a random IV per encryption
  // TODO: Implement proper encryption with KMS
  const encryptionKey = getEncryptionKey();
  const key = crypto.createHash("sha256").update(encryptionKey).digest();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv("aes-256-cbc", key, iv);
  let encrypted = cipher.update(token, "utf8", "hex");
  encrypted += cipher.final("hex");

  // Prepend IV for decryption (iv:ciphertext)
  return `${iv.toString("hex")}:${encrypted}`;
}

/**
 * Decrypt sensitive data (tokens) from Firestore
 */
export function decryptToken(encryptedToken: string): string {
  // In production, use proper decryption (e.g., Google Cloud KMS)
  // TODO: Implement proper decryption with KMS
  const encryptionKey = getEncryptionKey();
  const key = crypto.createHash("sha256").update(encryptionKey).digest();

  // Handle legacy format (no IV prepended) and new format (iv:ciphertext)
  if (encryptedToken.includes(":")) {
    const [ivHex, ciphertext] = encryptedToken.split(":");
    const iv = Buffer.from(ivHex, "hex");
    const decipher = crypto.createDecipheriv("aes-256-cbc", key, iv);
    let decrypted = decipher.update(ciphertext, "hex", "utf8");
    decrypted += decipher.final("utf8");
    return decrypted;
  } else {
    // Legacy format fallback: uses consistent IV derived from key
    const iv = crypto.createHash("md5").update(encryptionKey).digest().slice(0, 16);
    const decipher = crypto.createDecipheriv("aes-256-cbc", key, iv);
    let decrypted = decipher.update(encryptedToken, "hex", "utf8");
    decrypted += decipher.final("utf8");
    return decrypted;
  }
}

/**
 * Initiate OAuth 2.0 flow for Booking.com
 * Returns authorization URL for user to visit
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
    logInfo("[Booking.com OAuth] Initiating OAuth flow", {
      userId: request.auth.uid,
      unitId,
      hotelId,
      roomTypeId,
    });

    // Generate state parameter for CSRF protection
    const state = crypto.randomBytes(32).toString("hex");

    // Store state in Firestore for verification
    await db.collection("oauth_states").doc(state).set({
      userId: request.auth.uid,
      unitId,
      hotelId,
      roomTypeId,
      platform: "booking_com",
      createdAt: admin.firestore.Timestamp.now(),
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
      ),
    });

    // TODO: Update with actual OAuth authorization URL after getting API access
    // Placeholder - replace with actual Booking.com OAuth endpoint
    const authUrl = new URL("https://secure.booking.com/oauth/authorize");
    authUrl.searchParams.set("client_id", BOOKING_COM_CLIENT_ID);
    authUrl.searchParams.set("redirect_uri", BOOKING_COM_REDIRECT_URI);
    authUrl.searchParams.set("response_type", "code");
    authUrl.searchParams.set("state", state);
    authUrl.searchParams.set("scope", "read write");

    logSuccess("[Booking.com OAuth] Authorization URL generated", {
      state,
    });

    return {
      authorizationUrl: authUrl.toString(),
      state,
    };
  } catch (error) {
    logError("[Booking.com OAuth] Failed to initiate OAuth flow", error);
    throw new HttpsError("internal", "Failed to initiate OAuth flow");
  }
});

/**
 * Handle OAuth callback from Booking.com
 * Exchanges authorization code for access token
 */
export const handleBookingComOAuthCallback = onRequest(
  {cors: true},
  async (req, res) => {
    // SECURITY: Rate Limiting
    const clientIp = req.ip ||
      (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ||
      "unknown";

    if (!checkRateLimit(`oauth_callback_booking_com:${clientIp}`, 10, 600)) { // 10 per 10 minutes
      logWarn("[Booking.com OAuth] Rate limit exceeded", {ip: clientIp});
      res.status(429).send("Too many requests. Please try again later.");
      return;
    }

    try {
      const {code, state, error} = req.query;

      if (error) {
        logError("[Booking.com OAuth] OAuth error", null, {error});
        res.status(400).send(`OAuth error: ${error}`);
        return;
      }

      if (!code || !state) {
        res.status(400).send("Missing code or state parameter");
        return;
      }

      // Verify state
      const stateDoc = await db.collection("oauth_states").doc(state as string).get();

      if (!stateDoc.exists) {
        res.status(400).send("Invalid state parameter");
        return;
      }

      const stateData = stateDoc.data()!;
      const expiresAt = stateData.expiresAt.toDate();

      if (expiresAt < new Date()) {
        res.status(400).send("State expired");
        return;
      }

      // Use the Machine Account 'exchange' endpoint as per Connectivity API docs
      // Note: This uses Client Credentials flow (Machine Account), effectively ignoring the 'code'
      // received from the redirect, as Booking.com Connectivity API uses pure machine-to-machine auth.
      // The 'code' flow is kept in the structure in case of future API changes supporting 3-legged OAuth.
      const tokenResponse = await fetch("https://connectivity-authentication.booking.com/token-based-authentication/exchange", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          client_id: BOOKING_COM_CLIENT_ID,
          client_secret: BOOKING_COM_CLIENT_SECRET,
        }),
      });

      if (!tokenResponse.ok) {
        const errorText = await tokenResponse.text();
        logError("[Booking.com OAuth] Token exchange failed", null, {
          status: tokenResponse.status,
          error: errorText,
        });
        res.status(400).send("Failed to exchange code for token");
        return;
      }

      const tokenData = await tokenResponse.json();
      // Booking.com returns 'jwt' (access token) and 'ruid'.
      // Token expires in 1 hour (3600 seconds). No refresh token is returned;
      // one simply requests a new token using credentials.
      const access_token = tokenData.jwt;
      const refresh_token = null; // No refresh token in this flow
      const expires_in = 3600; // Standard expiry for Booking.com tokens

      // Calculate expiration time
      const expiresAtTime = new Date(Date.now() + expires_in * 1000);

      // Create platform connection document
      const connectionRef = db.collection("platform_connections").doc();
      await connectionRef.set({
        owner_id: stateData.userId,
        platform: "booking_com",
        unit_id: stateData.unitId,
        external_property_id: stateData.hotelId,
        external_unit_id: stateData.roomTypeId,
        access_token: encryptToken(access_token),
        refresh_token: refresh_token ? encryptToken(refresh_token) : null,
        expires_at: admin.firestore.Timestamp.fromDate(expiresAtTime),
        status: "active",
        created_at: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now(),
      });

      // Delete state document
      await stateDoc.ref.delete();

      logSuccess("[Booking.com OAuth] Connection created", {
        connectionId: connectionRef.id,
        userId: stateData.userId,
      });

      // Redirect to success page
      res.redirect(
        `https://app.bookbed.io/owner/platform-connections?success=true&connectionId=${connectionRef.id}`
      );
    } catch (error) {
      logError("[Booking.com OAuth] Callback error", error);
      res.status(500).send("Internal server error");
    }
  }
);

/**
 * Refresh access token using refresh token
 */
async function refreshBookingComToken(
  connectionId: string,
  refreshToken: string
): Promise<string> {
  try {
    logInfo("[Booking.com API] Refreshing access token", {connectionId});

    const response = await fetch("https://secure.booking.com/oauth/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: decryptToken(refreshToken),
        client_id: BOOKING_COM_CLIENT_ID,
        client_secret: BOOKING_COM_CLIENT_SECRET,
      }),
    });

    if (!response.ok) {
      throw new Error(`Token refresh failed: ${response.status}`);
    }

    const tokenData = await response.json();
    const {access_token, expires_in} = tokenData;

    // Update connection with new token
    const expiresAtTime = new Date(Date.now() + expires_in * 1000);
    await db.collection("platform_connections").doc(connectionId).update({
      access_token: encryptToken(access_token),
      expires_at: admin.firestore.Timestamp.fromDate(expiresAtTime),
      updated_at: admin.firestore.Timestamp.now(),
    });

    logSuccess("[Booking.com API] Token refreshed", {connectionId});

    return access_token;
  } catch (error) {
    logError("[Booking.com API] Token refresh failed", error, {connectionId});
    throw error;
  }
}

/**
 * Get valid access token (refresh if needed)
 */
async function getValidAccessToken(connectionId: string): Promise<string> {
  const connectionDoc = await db
    .collection("platform_connections")
    .doc(connectionId)
    .get();

  if (!connectionDoc.exists) {
    throw new Error("Connection not found");
  }

  const connectionData = connectionDoc.data()!;
  const expiresAt = connectionData.expires_at.toDate();
  const accessToken = decryptToken(connectionData.access_token);
  const refreshToken = connectionData.refresh_token;

  // Check if token is expired or will expire in next 5 minutes
  if (expiresAt < new Date(Date.now() + 5 * 60 * 1000)) {
    if (refreshToken) {
      return await refreshBookingComToken(connectionId, refreshToken);
    } else {
      throw new Error("Token expired and no refresh token available");
    }
  }

  return accessToken;
}

/**
 * Block dates on Booking.com calendar
 */
export async function blockDatesOnBookingCom(
  connectionId: string,
  hotelId: string,
  roomTypeId: string,
  dates: Array<{ start: Date; end: Date }>
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
  dates: Array<{ start: Date; end: Date }>
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

