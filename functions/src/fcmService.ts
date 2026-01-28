import {admin} from "./firebase";
import {logInfo, logError, logWarn} from "./logger";
import {shouldSendPushNotification} from "./notificationPreferences";
import {captureException, captureMessage, setUser, addBreadcrumb} from "./sentry";

/**
 * FCM Push Notification Service
 * Sends push notifications to users via Firebase Cloud Messaging
 *
 * Note: This service is implemented but hidden from UI until mobile app release.
 * FCM tokens are stored in Firestore at: users/{userId}/data/fcmTokens
 */

interface PushNotificationData {
  userId: string;
  title: string;
  body: string;
  category: "bookings" | "payments" | "calendar" | "marketing";
  data?: Record<string, string>;
}

/**
 * Get FCM tokens for a user
 * Tokens are stored per device in users/{userId}/data/fcmTokens
 *
 * Storage format (Flutter saves as map with token as key):
 * {
 *   "fcmToken123...": {
 *     "token": "fcmToken123...",
 *     "platform": "android",
 *     "createdAt": Timestamp,
 *     "lastSeen": Timestamp
 *   }
 * }
 */
async function getUserFcmTokens(userId: string): Promise<string[]> {
  try {
    const tokensDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("data")
      .doc("fcmTokens")
      .get();

    if (!tokensDoc.exists) {
      return [];
    }

    const data = tokensDoc.data();
    if (!data) {
      return [];
    }

    // Flutter saves tokens as a map with token string as the key
    // Each value contains {token, platform, createdAt, lastSeen}
    const tokens: string[] = [];
    for (const key of Object.keys(data)) {
      const tokenData = data[key];
      // The token string is stored both as the key and in the 'token' field
      const token = typeof tokenData === "object" && tokenData?.token ?
        tokenData.token :
        key;

      // Basic validation: must be a non-empty string of reasonable length
      // FCM tokens are typically 150+ characters
      if (typeof token === "string" && token.length > 20) {
        tokens.push(token);
      } else if (token) {
        logWarn("[FCM] Invalid token format", {
          userId,
          tokenLength: typeof token === "string" ? token.length : 0,
        });
        // Track invalid token formats - might indicate client-side bug
        captureMessage("[FCM] Invalid token format detected", "warning", {
          userId,
          tokenLength: typeof token === "string" ? token.length : 0,
        });
      }
    }

    return tokens;
  } catch (error) {
    logError("[FCM] Error fetching user FCM tokens", {userId, error});
    captureException(error, {userId, context: "getUserFcmTokens"});
    return [];
  }
}

/**
 * Send push notification to a specific user
 * Respects user's notification preferences
 */
export async function sendPushNotification(
  data: PushNotificationData
): Promise<boolean> {
  const {userId, title, body, category, data: notificationData} = data;

  // Set Sentry user context for error tracking
  setUser(userId);
  addBreadcrumb("Sending push notification", "fcm", {userId, category, title});

  try {
    // Check if user wants push notifications for this category
    const shouldSend = await shouldSendPushNotification(userId, category);
    if (!shouldSend) {
      logInfo("[FCM] User opted out of push notifications", {userId, category});
      addBreadcrumb("User opted out", "fcm", {userId, category});
      return false;
    }

    // Get user's FCM tokens
    const tokens = await getUserFcmTokens(userId);
    if (tokens.length === 0) {
      logInfo("[FCM] No FCM tokens available for user", {userId});
      // Track users without tokens - might indicate registration bug
      captureMessage("[FCM] No tokens available for user", "warning", {
        userId,
        category,
        title,
      });
      return false;
    }

    // Get unread notification count for iOS badge
    const unreadCount = await getUnreadNotificationCount(userId);

    // Build the message
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        category,
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        ...notificationData,
      },
      // Android specific config
      android: {
        priority: "high",
        notification: {
          channelId: `bookbed_${category}`,
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      // iOS specific config (APNs)
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: unreadCount,
            contentAvailable: true,
          },
        },
      },
      // Web push config
      webpush: {
        notification: {
          icon: "/icons/icon-192.png",
          badge: "/icons/badge-72.png",
        },
        fcmOptions: {
          link: "https://app.bookbed.io/owner/notifications",
        },
      },
    };

    // Send to all user's devices
    const response = await admin.messaging().sendEachForMulticast(message);

    logInfo("[FCM] Push notification sent", {
      userId,
      category,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    // Track delivery metrics in Sentry
    addBreadcrumb("Push notification delivered", "fcm", {
      userId,
      category,
      successCount: response.successCount,
      failureCount: response.failureCount,
      tokenCount: tokens.length,
    });

    // Clean up invalid tokens and track failures
    if (response.failureCount > 0) {
      // Log partial failures to Sentry for monitoring
      if (response.successCount === 0) {
        // Complete failure - all tokens failed
        captureMessage("[FCM] All tokens failed for user", "error", {
          userId,
          category,
          title,
          failureCount: response.failureCount,
          errors: response.responses
            .filter((r) => !r.success)
            .map((r) => r.error?.code)
            .slice(0, 5), // Limit to first 5 errors
        });
      }
      await cleanupInvalidTokens(userId, tokens, response.responses);
    }

    return response.successCount > 0;
  } catch (error) {
    logError("[FCM] Error sending push notification", {userId, category, error});
    // Capture exception to Sentry for debugging
    captureException(error, {
      userId,
      category,
      title,
      context: "sendPushNotification",
    });
    return false;
  }
}

/**
 * Remove invalid FCM tokens from Firestore
 * Uses FieldValue.delete() to remove specific token entries from the map
 */
async function cleanupInvalidTokens(
  userId: string,
  tokens: string[],
  responses: admin.messaging.SendResponse[]
): Promise<void> {
  const invalidTokens: string[] = [];

  responses.forEach((response, index) => {
    if (!response.success) {
      const error = response.error;
      // These error codes indicate the token is no longer valid
      if (
        error?.code === "messaging/invalid-registration-token" ||
        error?.code === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(tokens[index]);
      }
    }
  });

  if (invalidTokens.length === 0) return;

  try {
    const tokensRef = admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("data")
      .doc("fcmTokens");

    // Build update object to delete invalid tokens from the map
    // Flutter stores tokens as map keys, so we delete those keys
    const updates: Record<string, admin.firestore.FieldValue> = {};
    for (const token of invalidTokens) {
      updates[token] = admin.firestore.FieldValue.delete();
    }

    await tokensRef.update(updates);

    logInfo("[FCM] Cleaned up invalid tokens", {
      userId,
      removedCount: invalidTokens.length,
    });

    // Track token cleanup for monitoring device churn
    addBreadcrumb("Cleaned up invalid FCM tokens", "fcm", {
      userId,
      removedCount: invalidTokens.length,
    });
  } catch (error) {
    logWarn("[FCM] Error cleaning up invalid tokens", {userId, error});
    captureException(error, {userId, context: "cleanupInvalidTokens"});
  }
}

/**
 * Get unread notification count for a user
 * Used for iOS badge number
 */
async function getUnreadNotificationCount(userId: string): Promise<number> {
  try {
    const notificationsSnapshot = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .where("isRead", "==", false)
      .get();

    return notificationsSnapshot.size;
  } catch (error) {
    logError("[FCM] Error fetching unread notification count", {userId, error});
    return 1; // Fallback to 1 if count fails
  }
}

/**
 * Helper function to format date range for notification body (Croatian locale)
 */
function formatDateRange(checkInDate: Date, checkOutDate: Date): string {
  const formattedCheckIn = checkInDate.toLocaleDateString("hr-HR", {
    day: "2-digit",
    month: "short",
  });
  const formattedCheckOut = checkOutDate.toLocaleDateString("hr-HR", {
    day: "2-digit",
    month: "short",
  });
  return `${formattedCheckIn} - ${formattedCheckOut}`;
}

/**
 * Send payment notification via push (Croatian localized)
 * Notifies owner when a guest completes Stripe payment
 */
export async function sendPaymentPushNotification(
  userId: string,
  bookingId: string,
  guestName: string,
  amount: number,
  currency: string = "EUR"
): Promise<boolean> {
  const formattedAmount = new Intl.NumberFormat("hr-HR", {
    style: "currency",
    currency,
  }).format(amount);

  return sendPushNotification({
    userId,
    title: "Plaćena rezervacija",
    body: `${guestName} je platio/la ${formattedAmount} za rezervaciju.`,
    category: "bookings",
    data: {
      bookingId,
      amount: amount.toString(),
      currency,
    },
  });
}

/**
 * Send pending booking notification via push (Croatian localized)
 * Notifies owner when a new booking request comes in from widget
 */
export async function sendPendingBookingPushNotification(
  userId: string,
  bookingId: string,
  guestName: string,
  checkInDate: Date,
  checkOutDate: Date
): Promise<boolean> {
  const dateRange = formatDateRange(checkInDate, checkOutDate);

  return sendPushNotification({
    userId,
    title: "Nova rezervacija",
    body: `${guestName} je zatražio/la rezervaciju za ${dateRange}.`,
    category: "bookings",
    data: {
      bookingId,
      action: "pending",
    },
  });
}

/**
 * Send guest cancellation notification via push (Croatian localized)
 * Notifies owner when a guest cancels their booking via booking lookup page
 */
export async function sendGuestCancellationPushNotification(
  userId: string,
  bookingId: string,
  guestName: string,
  checkInDate: Date,
  checkOutDate: Date
): Promise<boolean> {
  const dateRange = formatDateRange(checkInDate, checkOutDate);

  return sendPushNotification({
    userId,
    title: "Otkazana rezervacija",
    body: `${guestName} je otkazao/la rezervaciju za ${dateRange}.`,
    category: "bookings",
    data: {
      bookingId,
      action: "guest_cancelled",
    },
  });
}

/**
 * Send trial expiring notification via push (Croatian localized)
 * Notifies owner when their trial is about to expire
 */
export async function sendTrialExpiringPushNotification(
  userId: string,
  daysRemaining: number
): Promise<boolean> {
  const dayText = daysRemaining === 1 ? "dan" : "dana";
  const urgency = daysRemaining === 1
    ? "ističe sutra"
    : `ističe za ${daysRemaining} ${dayText}`;

  return sendPushNotification({
    userId,
    title: "Probni period ističe",
    body: `Vaš besplatni probni period ${urgency}. Nadogradite kako biste nastavili upravljati rezervacijama.`,
    category: "marketing",
    data: {
      action: "trial_expiring",
      daysRemaining: daysRemaining.toString(),
    },
  });
}
