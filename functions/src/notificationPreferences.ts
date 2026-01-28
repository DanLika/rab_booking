import {db} from "./firebase";
import {logInfo, logWarn} from "./logger";

/**
 * Notification Preferences Types
 */
interface NotificationChannels {
    email: boolean;
    push: boolean;
    sms: boolean;
}

interface NotificationCategories {
    bookings: NotificationChannels;
    payments: NotificationChannels;
    calendar: NotificationChannels;
    marketing: NotificationChannels;
}

interface NotificationPreferences {
    masterEnabled: boolean;
    categories: NotificationCategories;
}

/**
 * Get user's notification preferences from Firestore
 * @param userId - User ID
 * @return Notification preferences or null if not found
 */
export async function getNotificationPreferences(
  userId: string
): Promise<NotificationPreferences | null> {
  try {
    const doc = await db
      .collection("users")
      .doc(userId)
      .collection("data")
      .doc("preferences")
      .get();

    if (!doc.exists) {
      logInfo("[NotificationPreferences] No preferences found for user", {userId});
      return null;
    }

    const data = doc.data();
    return {
      masterEnabled: data?.masterEnabled ?? true, // Default to true if not set
      categories: data?.categories ?? {
        bookings: {email: true, push: true, sms: false},
        payments: {email: true, push: true, sms: false},
        calendar: {email: true, push: true, sms: false},
        marketing: {email: false, push: false, sms: false},
      },
    };
  } catch (error) {
    logWarn("[NotificationPreferences] Error fetching preferences", {
      userId,
      error,
    });
    return null;
  }
}

/**
 * Check if user should receive email notification for a specific category
 * @param userId - User ID
 * @param category - Notification category (bookings, payments, calendar, marketing)
 * @return true if email should be sent, false otherwise
 */
export async function shouldSendEmailNotification(
  userId: string,
  category: "bookings" | "payments" | "calendar" | "marketing"
): Promise<boolean> {
  const preferences = await getNotificationPreferences(userId);

  // If no preferences found, default to sending (opt-out approach)
  if (!preferences) {
    logInfo(
      "[NotificationPreferences] No preferences found, defaulting to send",
      {userId, category}
    );
    return true;
  }

  // Check master switch
  if (!preferences.masterEnabled) {
    logInfo("[NotificationPreferences] Master switch disabled, not sending", {
      userId,
      category,
    });
    return false;
  }

  // Check category-specific email preference
  const shouldSend = preferences.categories[category]?.email ?? true;
  logInfo(
    `[NotificationPreferences] Email notification ${shouldSend ? "enabled" : "disabled"}`,
    {userId, category}
  );

  return shouldSend;
}

/**
 * Check if user should receive push notification for a specific category
 * @param userId - User ID
 * @param category - Notification category
 * @return true if push should be sent, false otherwise
 */
export async function shouldSendPushNotification(
  userId: string,
  category: "bookings" | "payments" | "calendar" | "marketing"
): Promise<boolean> {
  const preferences = await getNotificationPreferences(userId);

  if (!preferences) {
    return true;
  }

  if (!preferences.masterEnabled) {
    return false;
  }

  return preferences.categories[category]?.push ?? true;
}

/**
 * Check if user should receive SMS notification for a specific category
 * @param userId - User ID
 * @param category - Notification category
 * @return true if SMS should be sent, false otherwise
 */
export async function shouldSendSmsNotification(
  userId: string,
  category: "bookings" | "payments" | "calendar" | "marketing"
): Promise<boolean> {
  const preferences = await getNotificationPreferences(userId);

  if (!preferences) {
    return false; // SMS is opt-in, default to false
  }

  if (!preferences.masterEnabled) {
    return false;
  }

  return preferences.categories[category]?.sms ?? false;
}
