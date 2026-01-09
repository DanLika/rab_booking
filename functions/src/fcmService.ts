import {admin} from "./firebase";
import {logInfo, logError, logWarn} from "./logger";
import {shouldSendPushNotification} from "./notificationPreferences";

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
      logInfo("[FCM] No FCM tokens found for user", {userId});
      return [];
    }

    const data = tokensDoc.data();
    if (!data || !data.tokens) {
      return [];
    }

    // tokens is an array of {token: string, platform: string, updatedAt: Timestamp}
    const tokens = data.tokens as Array<{token: string; platform: string}>;
    return tokens
      .map((t) => t.token)
      .filter((token): token is string => {
        // Basic validation: must be a non-empty string of reasonable length.
        // This prevents sending to clearly invalid/malformed tokens.
        const isValid = typeof token === "string" && token.length > 20;
        if (!isValid) {
          logWarn("[FCM] Found invalid token format in Firestore", {userId});
        }
        return isValid;
      });
  } catch (error) {
    logError("[FCM] Error fetching user FCM tokens", {userId, error});
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

  try {
    // Check if user wants push notifications for this category
    const shouldSend = await shouldSendPushNotification(userId, category);
    if (!shouldSend) {
      logInfo("[FCM] User opted out of push notifications", {userId, category});
      return false;
    }

    // Get user's FCM tokens
    const tokens = await getUserFcmTokens(userId);
    if (tokens.length === 0) {
      logInfo("[FCM] No FCM tokens available for user", {userId});
      return false;
    }

    // Get unread notification count for badge
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

    // Clean up invalid tokens
    if (response.failureCount > 0) {
      await cleanupInvalidTokens(userId, tokens, response.responses);
    }

    return response.successCount > 0;
  } catch (error) {
    logError("[FCM] Error sending push notification", {userId, category, error});
    return false;
  }
}

/**
 * Remove invalid FCM tokens from Firestore
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

    const tokensDoc = await tokensRef.get();
    if (!tokensDoc.exists) return;

    const data = tokensDoc.data();
    if (!data || !data.tokens) return;

    // Filter out invalid tokens
    const validTokens = (data.tokens as Array<{token: string}>).filter(
      (t) => !invalidTokens.includes(t.token)
    );

    await tokensRef.update({tokens: validTokens});

    logInfo("[FCM] Cleaned up invalid tokens", {
      userId,
      removedCount: invalidTokens.length,
    });
  } catch (error) {
    logWarn("[FCM] Error cleaning up invalid tokens", {userId, error});
  }
}

/**
 * Get unread notification count for a user
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
 * Helper function to format date range for notification body
 */
function _formatDateRange(checkInDate: Date, checkOutDate: Date): string {
  const formattedCheckIn = checkInDate.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
  });
  const formattedCheckOut = checkOutDate.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
  });
  return `${formattedCheckIn} - ${formattedCheckOut}`;
}

/**
 * Send booking notification via push
 */
export async function sendBookingPushNotification(
  userId: string,
  bookingId: string,
  guestName: string,
  action: "created" | "updated" | "cancelled",
  checkInDate: Date,
  checkOutDate: Date,
  cancellationReason?: string
): Promise<boolean> {
  const titles: Record<string, string> = {
    created: "New Booking",
    updated: "Booking Updated",
    cancelled: "Booking Cancelled",
  };

  const dateRange = _formatDateRange(checkInDate, checkOutDate);

  const bodies: Record<string, string> = {
    created: `${guestName} has booked for ${dateRange}.`,
    updated: `Booking for ${guestName} (${dateRange}) has been updated.`,
    cancelled: `Booking for ${guestName} (${dateRange}) has been cancelled. ${
      cancellationReason ? `Reason: ${cancellationReason}` : ""
    }`,
  };

  return sendPushNotification({
    userId,
    title: titles[action] || "Booking Notification",
    body: bodies[action] || "There's an update on a booking.",
    category: "bookings",
    data: {
      bookingId,
      action,
      cancellationReason: cancellationReason || "",
    },
  });
}

/**
 * Send payment failed notification via push
 */
export async function sendPaymentFailedPushNotification(
  userId: string,
  bookingId: string,
  guestName: string
): Promise<boolean> {
  return sendPushNotification({
    userId,
    title: "Payment Failed",
    body: `A payment from ${guestName} for booking ${bookingId} failed. Please check Stripe and contact the guest.`,
    category: "payments",
    data: {
      bookingId,
    },
  });
}

/**
 * Send pending booking notification via push
 */
export async function sendPendingBookingPushNotification(
  userId: string,
  bookingId: string,
  guestName: string,
  checkInDate: Date,
  checkOutDate: Date
): Promise<boolean> {
  const dateRange = _formatDateRange(checkInDate, checkOutDate);

  return sendPushNotification({
    userId,
    title: "Booking Awaiting Approval",
    body: `${guestName} has requested a booking for ${dateRange}.`,
    category: "bookings",
    data: {
      bookingId,
      action: "pending",
    },
  });
}

/**
 * Send payment notification via push
 */
export async function sendPaymentPushNotification(
  userId: string,
  bookingId: string,
  guestName: string,
  amount: number,
  currency: string = "EUR"
): Promise<boolean> {
  const formattedAmount = new Intl.NumberFormat("en-EU", {
    style: "currency",
    currency,
  }).format(amount);

  return sendPushNotification({
    userId,
    title: "Payment Received",
    body: `${guestName} paid ${formattedAmount}.`,
    category: "payments",
    data: {
      bookingId,
      amount: amount.toString(),
      currency,
    },
  });
}
