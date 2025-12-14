import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import * as crypto from "crypto";
import {encryptToken, decryptToken} from "./bookingComApi"; // Reuse encryption functions

/**
 * Airbnb Calendar API Integration
 * 
 * ⚠️ IMPORTANT: Direct API access is currently NOT AVAILABLE
 * 
 * Status: Invitation-only (no public API)
 * Requirements: Business entity, security review, NDA, invitation from Airbnb
 * Timeline: Indefinite (months to potentially never)
 * 
 * This code is kept for reference but will not work without partnership invitation.
 * 
 * RECOMMENDED ALTERNATIVE: Use channel manager APIs (Beds24, Hosthub, Guesty)
 * See: docs/CHANNEL_MANAGER_SETUP.md
 * 
 * Technical Notes:
 * - Uses standard OAuth 2.0 (for approved partners)
 * - RESTful JSON API
 * - Webhook support available (must respond within 8 seconds)
 * 
 * Documentation: https://developer.airbnb.com/ (restricted access)
 */

// Configuration
const AIRBNB_CLIENT_ID = process.env.AIRBNB_CLIENT_ID || "";
const AIRBNB_CLIENT_SECRET = process.env.AIRBNB_CLIENT_SECRET || "";
const AIRBNB_REDIRECT_URI = process.env.AIRBNB_REDIRECT_URI || "";
// TODO: Update with actual API base URL after getting API access
// Placeholder - replace with actual Airbnb API endpoint
const AIRBNB_API_BASE_URL = "https://api.airbnb.com/v2";

/**
 * Initiate OAuth 2.0 flow for Airbnb
 * Returns authorization URL for user to visit
 */
export const initiateAirbnbOAuth = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const {unitId, listingId} = request.data;

  if (!unitId || !listingId) {
    throw new HttpsError(
      "invalid-argument",
      "unitId and listingId are required"
    );
  }

  try {
    logInfo("[Airbnb OAuth] Initiating OAuth flow", {
      userId: request.auth.uid,
      unitId,
      listingId,
    });

    // Generate state parameter for CSRF protection
    const state = crypto.randomBytes(32).toString("hex");

    // Store state in Firestore for verification
    await db.collection("oauth_states").doc(state).set({
      userId: request.auth.uid,
      unitId,
      listingId,
      platform: "airbnb",
      createdAt: admin.firestore.Timestamp.now(),
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
      ),
    });

    // TODO: Update with actual OAuth authorization URL after getting API access
    // Placeholder - replace with actual Airbnb OAuth endpoint
    const authUrl = new URL("https://www.airbnb.com/oauth2/authorize");
    authUrl.searchParams.set("client_id", AIRBNB_CLIENT_ID);
    authUrl.searchParams.set("redirect_uri", AIRBNB_REDIRECT_URI);
    authUrl.searchParams.set("response_type", "code");
    authUrl.searchParams.set("state", state);
    authUrl.searchParams.set("scope", "read write");

    logSuccess("[Airbnb OAuth] Authorization URL generated", {
      state,
    });

    return {
      authorizationUrl: authUrl.toString(),
      state,
    };
  } catch (error) {
    logError("[Airbnb OAuth] Failed to initiate OAuth flow", error);
    throw new HttpsError("internal", "Failed to initiate OAuth flow");
  }
});

/**
 * Handle OAuth callback from Airbnb
 * Exchanges authorization code for access token
 */
export const handleAirbnbOAuthCallback = onRequest(
  {cors: true},
  async (req, res) => {
    try {
      const {code, state, error} = req.query;

      if (error) {
        logError("[Airbnb OAuth] OAuth error", null, {error});
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

      // TODO: Update with actual OAuth token URL after getting API access
      // Placeholder - replace with actual Airbnb OAuth token endpoint
      const tokenResponse = await fetch("https://www.airbnb.com/oauth2/token", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          code: code as string,
          redirect_uri: AIRBNB_REDIRECT_URI,
          client_id: AIRBNB_CLIENT_ID,
          client_secret: AIRBNB_CLIENT_SECRET,
        }),
      });

      if (!tokenResponse.ok) {
        const errorText = await tokenResponse.text();
        logError("[Airbnb OAuth] Token exchange failed", null, {
          status: tokenResponse.status,
          error: errorText,
        });
        res.status(400).send("Failed to exchange code for token");
        return;
      }

      const tokenData = await tokenResponse.json();
      const {access_token, refresh_token, expires_in} = tokenData;

      // Calculate expiration time
      const expiresAtTime = new Date(Date.now() + expires_in * 1000);

      // Create platform connection document
      const connectionRef = db.collection("platform_connections").doc();
      await connectionRef.set({
        owner_id: stateData.userId,
        platform: "airbnb",
        unit_id: stateData.unitId,
        external_property_id: stateData.listingId,
        external_unit_id: stateData.listingId, // Airbnb uses listing ID for both
        access_token: encryptToken(access_token),
        refresh_token: refresh_token ? encryptToken(refresh_token) : null,
        expires_at: admin.firestore.Timestamp.fromDate(expiresAtTime),
        status: "active",
        created_at: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now(),
      });

      // Delete state document
      await stateDoc.ref.delete();

      logSuccess("[Airbnb OAuth] Connection created", {
        connectionId: connectionRef.id,
        userId: stateData.userId,
      });

      // Redirect to success page
      res.redirect(
        `https://app.bookbed.io/owner/platform-connections?success=true&connectionId=${connectionRef.id}`
      );
    } catch (error) {
      logError("[Airbnb OAuth] Callback error", error);
      res.status(500).send("Internal server error");
    }
  }
);

/**
 * Refresh access token using refresh token
 */
async function refreshAirbnbToken(
  connectionId: string,
  refreshToken: string
): Promise<string> {
  try {
    logInfo("[Airbnb API] Refreshing access token", {connectionId});

    const response = await fetch("https://www.airbnb.com/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: decryptToken(refreshToken),
        client_id: AIRBNB_CLIENT_ID,
        client_secret: AIRBNB_CLIENT_SECRET,
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

    logSuccess("[Airbnb API] Token refreshed", {connectionId});

    return access_token;
  } catch (error) {
    logError("[Airbnb API] Token refresh failed", error, {connectionId});
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
      return await refreshAirbnbToken(connectionId, refreshToken);
    } else {
      throw new Error("Token expired and no refresh token available");
    }
  }

  return accessToken;
}

/**
 * Block dates on Airbnb calendar
 */
export async function blockDatesOnAirbnb(
  connectionId: string,
  listingId: string,
  dates: Array<{start: Date; end: Date}>
): Promise<void> {
  try {
    logInfo("[Airbnb API] Blocking dates", {
      connectionId,
      listingId,
      dateCount: dates.length,
    });

    const accessToken = await getValidAccessToken(connectionId);

    // Airbnb API endpoint for blocking dates
    const apiUrl = `${AIRBNB_API_BASE_URL}/listings/${listingId}/calendar_availability`;

    for (const dateRange of dates) {
      const response = await fetch(apiUrl, {
        method: "PUT",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "X-Airbnb-API-Key": AIRBNB_CLIENT_ID,
        },
        body: JSON.stringify({
          start_date: dateRange.start.toISOString().split("T")[0],
          end_date: dateRange.end.toISOString().split("T")[0],
          available: false,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logError("[Airbnb API] Failed to block dates", null, {
          status: response.status,
          error: errorText,
          dateRange,
        });
        throw new Error(`Failed to block dates: ${response.status}`);
      }
    }

    logSuccess("[Airbnb API] Dates blocked successfully", {
      connectionId,
      dateCount: dates.length,
    });
  } catch (error) {
    logError("[Airbnb API] Error blocking dates", error, {
      connectionId,
    });
    throw error;
  }
}

/**
 * Unblock dates on Airbnb calendar
 */
export async function unblockDatesOnAirbnb(
  connectionId: string,
  listingId: string,
  dates: Array<{start: Date; end: Date}>
): Promise<void> {
  try {
    logInfo("[Airbnb API] Unblocking dates", {
      connectionId,
      listingId,
      dateCount: dates.length,
    });

    const accessToken = await getValidAccessToken(connectionId);

    const apiUrl = `${AIRBNB_API_BASE_URL}/listings/${listingId}/calendar_availability`;

    for (const dateRange of dates) {
      const response = await fetch(apiUrl, {
        method: "PUT",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "X-Airbnb-API-Key": AIRBNB_CLIENT_ID,
        },
        body: JSON.stringify({
          start_date: dateRange.start.toISOString().split("T")[0],
          end_date: dateRange.end.toISOString().split("T")[0],
          available: true,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logError("[Airbnb API] Failed to unblock dates", null, {
          status: response.status,
          error: errorText,
        });
        throw new Error(`Failed to unblock dates: ${response.status}`);
      }
    }

    logSuccess("[Airbnb API] Dates unblocked successfully", {
      connectionId,
      dateCount: dates.length,
    });
  } catch (error) {
    logError("[Airbnb API] Error unblocking dates", error, {
      connectionId,
    });
    throw error;
  }
}

/**
 * Get reservations from Airbnb
 */
export async function getAirbnbReservations(
  connectionId: string,
  listingId: string
): Promise<any[]> {
  try {
    logInfo("[Airbnb API] Fetching reservations", {
      connectionId,
      listingId,
    });

    const accessToken = await getValidAccessToken(connectionId);

    // Airbnb API endpoint for getting reservations
    const apiUrl = `${AIRBNB_API_BASE_URL}/listings/${listingId}/reservations`;

    const response = await fetch(apiUrl, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "X-Airbnb-API-Key": AIRBNB_CLIENT_ID,
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      logError("[Airbnb API] Failed to fetch reservations", null, {
        status: response.status,
        error: errorText,
      });
      throw new Error(`Failed to fetch reservations: ${response.status}`);
    }

    const data = await response.json();
    const reservations = data.reservations || [];

    logSuccess("[Airbnb API] Reservations fetched", {
      connectionId,
      count: reservations.length,
    });

    return reservations;
  } catch (error) {
    logError("[Airbnb API] Error fetching reservations", error, {
      connectionId,
    });
    throw error;
  }
}

