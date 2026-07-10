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

interface QuietHours {
    enabled: boolean;
    start: string; // "HH:mm"
    end: string; // "HH:mm"
    timezone: string; // IANA name, e.g. "Europe/Zagreb"
}

interface NotificationPreferences {
    masterEnabled: boolean;
    categories: NotificationCategories;
    quietHours?: QuietHours;
}

/**
 * Parse an "HH:mm" string into minutes-since-midnight.
 * Returns null if malformed.
 * @param hhmm - Time string in 24h "HH:mm" form
 * @return Minutes since midnight [0,1439], or null
 */
export function parseHhmmToMinutes(hhmm: string): number | null {
  const m = /^([0-9]{1,2}):([0-9]{2})$/.exec(hhmm ?? "");
  if (!m) return null;
  const h = Number(m[1]);
  const min = Number(m[2]);
  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return h * 60 + min;
}

/**
 * Return the current minutes-since-midnight in the given IANA timezone.
 * Uses Intl (DST-correct); falls back to UTC minutes if the tz is invalid.
 * @param timezone - IANA timezone name
 * @param now - Reference instant (defaults to now); injectable for tests
 * @return Minutes since local midnight [0,1439]
 */
export function nowMinutesInTz(
  timezone: string,
  now: Date = new Date()
): number {
  try {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).formatToParts(now);
    let h = 0;
    let min = 0;
    for (const p of parts) {
      // Intl may emit "24" at midnight in some engines; wrap to 0.
      if (p.type === "hour") h = Number(p.value) % 24;
      if (p.type === "minute") min = Number(p.value);
    }
    return h * 60 + min;
  } catch {
    return now.getUTCHours() * 60 + now.getUTCMinutes();
  }
}

/**
 * Pure predicate: is `nowMin` inside the quiet-hours window [start,end)?
 * Handles windows that cross midnight (start > end). If start === end the
 * window is treated as empty (never quiet) to avoid a 24h silent trap.
 * @param nowMin - Current minutes-since-midnight
 * @param startMin - Window start minutes-since-midnight
 * @param endMin - Window end minutes-since-midnight
 * @return true if now is within the suppression window
 */
export function isWithinQuietWindow(
  nowMin: number,
  startMin: number,
  endMin: number
): boolean {
  if (startMin === endMin) return false;
  if (startMin < endMin) {
    // Same-day window, e.g. 09:00 → 17:00
    return nowMin >= startMin && nowMin < endMin;
  }
  // Crosses midnight, e.g. 22:00 → 07:00
  return nowMin >= startMin || nowMin < endMin;
}

/**
 * Whether push should be suppressed right now by the user's quiet hours.
 * Malformed/disabled config = not suppressed (fail-open: never silently drop).
 * @param quietHours - The user's quiet-hours config (may be undefined)
 * @param now - Reference instant (injectable for tests)
 * @return true if the push should be suppressed
 */
export function isQuietNow(
  quietHours: QuietHours | undefined,
  now: Date = new Date()
): boolean {
  if (!quietHours || !quietHours.enabled) return false;
  const startMin = parseHhmmToMinutes(quietHours.start);
  const endMin = parseHhmmToMinutes(quietHours.end);
  if (startMin === null || endMin === null) return false;
  const tz = quietHours.timezone || "Europe/Zagreb";
  const nowMin = nowMinutesInTz(tz, now);
  return isWithinQuietWindow(nowMin, startMin, endMin);
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
      quietHours: data?.quietHours as QuietHours | undefined,
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

  const categoryAllows = preferences.categories[category]?.push ?? true;
  if (!categoryAllows) {
    return false;
  }

  // Quiet Hours (Tihi sati) — suppress PUSH during the user's configured
  // window. Email + in-app/DB records are unaffected (handled elsewhere), so
  // nothing is lost — only the device buzz is withheld.
  if (isQuietNow(preferences.quietHours)) {
    logInfo(
      "[NotificationPreferences] Quiet hours active, suppressing push",
      {userId, category, quietHours: preferences.quietHours}
    );
    return false;
  }

  return true;
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
