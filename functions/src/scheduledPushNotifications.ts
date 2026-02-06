import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess, logWarn} from "./logger";
import {sendPushNotification} from "./fcmService";

/**
 * Scheduled Push Notifications Service
 *
 * Contains scheduled Cloud Functions for sending push notifications:
 * - Check-in Tomorrow (18:00 daily)
 * - Check-out Today (08:00 daily)
 * - Pending Payment Reminder (Day 6 of 7, 10:00 daily)
 * - Comeback Reminder (5 days inactive, 12:00 daily)
 * - Bi-weekly Summary (1st and 15th, 09:00)
 * - Monthly Revenue Report (1st of month, 10:00)
 *
 * All times are Europe/Zagreb timezone.
 */

/**
 * Croatian plural helper for "rezervacija"
 * Rules: 1 → "rezervacija", 2-4 → "rezervacije", 5+ → "rezervacija"
 * Exception: 11-14 → "rezervacija" (not "rezervacije")
 */
function getBookingPluralHr(count: number): string {
  const lastDigit = count % 10;
  const lastTwoDigits = count % 100;

  // 11-14 are special - always "rezervacija"
  if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
    return "rezervacija";
  }
  // 2, 3, 4, 22, 23, 24, 32, 33, 34... → "rezervacije"
  if (lastDigit >= 2 && lastDigit <= 4) {
    return "rezervacije";
  }
  // 1, 5-9, 0, 11-14, 21, 25-30... → "rezervacija"
  return "rezervacija";
}

// ============================================================================
// CHECK-IN TOMORROW REMINDER
// Runs daily at 18:00 (Europe/Zagreb)
// Notifies owners about guests arriving tomorrow
// ============================================================================
export const checkInTomorrowReminder = onSchedule(
  {
    schedule: "0 18 * * *", // 18:00 every day
    timeZone: "Europe/Zagreb",
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    logInfo("[Check-in Reminder] Starting daily check-in reminder");

    try {
      // Calculate tomorrow's date range (00:00 - 23:59)
      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setDate(now.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      const tomorrowEnd = new Date(tomorrow);
      tomorrowEnd.setHours(23, 59, 59, 999);

      const tomorrowStart = admin.firestore.Timestamp.fromDate(tomorrow);
      const tomorrowEndTs = admin.firestore.Timestamp.fromDate(tomorrowEnd);

      // Find confirmed bookings with check-in tomorrow
      const bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("status", "==", "confirmed")
        .where("check_in", ">=", tomorrowStart)
        .where("check_in", "<=", tomorrowEndTs)
        .limit(500)
        .get();

      if (bookingsSnapshot.empty) {
        logInfo("[Check-in Reminder] No check-ins tomorrow");
        return;
      }

      logInfo("[Check-in Reminder] Found bookings", {
        count: bookingsSnapshot.size,
      });

      let sentCount = 0;
      let errorCount = 0;

      for (const doc of bookingsSnapshot.docs) {
        const booking = doc.data();
        const ownerId = booking.owner_id;

        if (!ownerId) {
          logWarn("[Check-in Reminder] Booking missing owner_id", {
            bookingId: doc.id,
          });
          continue;
        }

        const guestName = booking.guest_details?.name ||
          booking.guest_name ||
          "Guest";

        // Skip if we already sent this reminder (prevent duplicates on retries)
        if (booking.checkInReminderSent) {
          continue;
        }

        try {
          await sendPushNotification({
            userId: ownerId,
            title: "Dolazak sutra",
            body: `${guestName} dolazi sutra. Pobrinite se da je sve spremno!`,
            category: "calendar",
            data: {
              bookingId: doc.id,
              action: "check_in_reminder",
            },
          });

          // Mark as sent to prevent duplicates
          await doc.ref.update({
            checkInReminderSent: true,
          });

          sentCount++;
        } catch (error) {
          logError("[Check-in Reminder] Failed to send notification", error, {
            bookingId: doc.id,
            ownerId,
          });
          errorCount++;
        }
      }

      logSuccess("[Check-in Reminder] Completed", {
        sent: sentCount,
        errors: errorCount,
        total: bookingsSnapshot.size,
      });
    } catch (error) {
      logError("[Check-in Reminder] Function failed", error);
    }
  }
);

// ============================================================================
// CHECK-OUT TODAY REMINDER
// Runs daily at 08:00 (Europe/Zagreb)
// Notifies owners about guests leaving today
// ============================================================================
export const checkOutTodayReminder = onSchedule(
  {
    schedule: "0 8 * * *", // 08:00 every day
    timeZone: "Europe/Zagreb",
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    logInfo("[Check-out Reminder] Starting daily check-out reminder");

    try {
      // Calculate today's date range (00:00 - 23:59)
      const now = new Date();
      const today = new Date(now);
      today.setHours(0, 0, 0, 0);

      const todayEnd = new Date(today);
      todayEnd.setHours(23, 59, 59, 999);

      const todayStart = admin.firestore.Timestamp.fromDate(today);
      const todayEndTs = admin.firestore.Timestamp.fromDate(todayEnd);

      // Find confirmed bookings with check-out today
      const bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("status", "==", "confirmed")
        .where("check_out", ">=", todayStart)
        .where("check_out", "<=", todayEndTs)
        .limit(500)
        .get();

      if (bookingsSnapshot.empty) {
        logInfo("[Check-out Reminder] No check-outs today");
        return;
      }

      logInfo("[Check-out Reminder] Found bookings", {
        count: bookingsSnapshot.size,
      });

      let sentCount = 0;
      let errorCount = 0;

      for (const doc of bookingsSnapshot.docs) {
        const booking = doc.data();
        const ownerId = booking.owner_id;

        if (!ownerId) {
          logWarn("[Check-out Reminder] Booking missing owner_id", {
            bookingId: doc.id,
          });
          continue;
        }

        const guestName = booking.guest_details?.name ||
          booking.guest_name ||
          "Guest";

        // Skip if we already sent this reminder (prevent duplicates on retries)
        if (booking.checkOutReminderSent) {
          continue;
        }

        try {
          await sendPushNotification({
            userId: ownerId,
            title: "Odlazak danas",
            body: `${guestName} odlazi danas. Ne zaboravite zakazati čišćenje!`,
            category: "calendar",
            data: {
              bookingId: doc.id,
              action: "check_out_reminder",
            },
          });

          // Mark as sent to prevent duplicates
          await doc.ref.update({
            checkOutReminderSent: true,
          });

          sentCount++;
        } catch (error) {
          logError("[Check-out Reminder] Failed to send notification", error, {
            bookingId: doc.id,
            ownerId,
          });
          errorCount++;
        }
      }

      logSuccess("[Check-out Reminder] Completed", {
        sent: sentCount,
        errors: errorCount,
        total: bookingsSnapshot.size,
      });
    } catch (error) {
      logError("[Check-out Reminder] Function failed", error);
    }
  }
);

// ============================================================================
// PENDING PAYMENT REMINDER (Day 6 of 7)
// Runs daily at 10:00 (Europe/Zagreb)
// Reminds owners about bookings where payment deadline is approaching
// ============================================================================
export const pendingPaymentReminder = onSchedule(
  {
    schedule: "0 10 * * *", // 10:00 every day
    timeZone: "Europe/Zagreb",
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    logInfo("[Payment Reminder] Starting pending payment check");

    try {
      const now = new Date();

      // Find bookings where payment deadline is in the next 24-48 hours
      // (Day 6 of 7-day deadline = 1-2 days remaining)
      const oneDayFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
      const twoDaysFromNow = new Date(now.getTime() + 48 * 60 * 60 * 1000);

      const oneDayTs = admin.firestore.Timestamp.fromDate(oneDayFromNow);
      const twoDaysTs = admin.firestore.Timestamp.fromDate(twoDaysFromNow);

      // Find pending bank transfer bookings with deadline in 24-48 hours
      const bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("status", "==", "pending")
        .where("payment_method", "==", "bank_transfer")
        .where("payment_deadline", ">=", oneDayTs)
        .where("payment_deadline", "<=", twoDaysTs)
        .limit(500)
        .get();

      if (bookingsSnapshot.empty) {
        logInfo("[Payment Reminder] No payments due soon");
        return;
      }

      logInfo("[Payment Reminder] Found bookings with approaching deadline", {
        count: bookingsSnapshot.size,
      });

      let sentCount = 0;
      let errorCount = 0;

      for (const doc of bookingsSnapshot.docs) {
        const booking = doc.data();
        const ownerId = booking.owner_id;

        if (!ownerId) {
          continue;
        }

        const guestName = booking.guest_details?.name ||
          booking.guest_name ||
          "Guest";

        // Check if we already sent this reminder (prevent duplicates)
        if (booking.paymentReminderSent) {
          continue;
        }

        try {
          await sendPushNotification({
            userId: ownerId,
            title: "Rok za uplatu ističe sutra",
            body: `Rezervacija od ${guestName} - rok za uplatu ističe sutra.`,
            category: "payments",
            data: {
              bookingId: doc.id,
              action: "payment_deadline",
            },
          });

          // Mark reminder as sent
          await doc.ref.update({
            paymentReminderSent: true,
            paymentReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          sentCount++;
        } catch (error) {
          logError("[Payment Reminder] Failed to send notification", error, {
            bookingId: doc.id,
            ownerId,
          });
          errorCount++;
        }
      }

      logSuccess("[Payment Reminder] Completed", {
        sent: sentCount,
        errors: errorCount,
        total: bookingsSnapshot.size,
      });
    } catch (error) {
      logError("[Payment Reminder] Function failed", error);
    }
  }
);

// ============================================================================
// COMEBACK REMINDER (5 days inactive)
// Runs daily at 12:00 (Europe/Zagreb)
// Reminds owners who haven't opened the app in 5 days
//
// NOTE: This function requires Flutter app to update 'lastActiveAt' field
// on user login/app open. Without that, query returns 0 users.
// ============================================================================
export const comebackReminder = onSchedule(
  {
    schedule: "0 12 * * *", // 12:00 every day
    timeZone: "Europe/Zagreb",
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    logInfo("[Comeback Reminder] Starting inactivity check");

    try {
      // Find users who haven't been active in 5 days
      const fiveDaysAgo = new Date();
      fiveDaysAgo.setDate(fiveDaysAgo.getDate() - 5);
      fiveDaysAgo.setHours(0, 0, 0, 0);

      const sixDaysAgo = new Date();
      sixDaysAgo.setDate(sixDaysAgo.getDate() - 6);
      sixDaysAgo.setHours(0, 0, 0, 0);

      const fiveDaysAgoTs = admin.firestore.Timestamp.fromDate(fiveDaysAgo);
      const sixDaysAgoTs = admin.firestore.Timestamp.fromDate(sixDaysAgo);

      // Find users inactive for exactly 5 days (to avoid spamming)
      // lastActiveAt between 5-6 days ago
      // NOTE: Can't use "!=" filter because it excludes docs where field doesn't exist
      const usersSnapshot = await db
        .collection("users")
        .where("lastActiveAt", ">=", sixDaysAgoTs)
        .where("lastActiveAt", "<", fiveDaysAgoTs)
        .limit(500)
        .get();

      if (usersSnapshot.empty) {
        logInfo("[Comeback Reminder] No inactive users to remind");
        return;
      }

      logInfo("[Comeback Reminder] Found potentially inactive users", {
        count: usersSnapshot.size,
      });

      let sentCount = 0;
      let skippedCount = 0;
      let errorCount = 0;

      for (const doc of usersSnapshot.docs) {
        const userId = doc.id;
        const userData = doc.data();

        // Skip if already sent (filter in code instead of query)
        if (userData.comebackReminderSent === true) {
          skippedCount++;
          continue;
        }

        try {
          await sendPushNotification({
            userId,
            title: "Nedostajete nam! 👋",
            body: "Provjerite svoje rezervacije i pogledajte što je novo u BookBed-u.",
            category: "marketing",
            data: {
              action: "comeback_reminder",
            },
          });

          // Mark reminder as sent (reset when user opens app)
          await doc.ref.update({
            comebackReminderSent: true,
            comebackReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          sentCount++;
        } catch (error) {
          logError("[Comeback Reminder] Failed to send notification", error, {
            userId,
          });
          errorCount++;
        }
      }

      logSuccess("[Comeback Reminder] Completed", {
        sent: sentCount,
        skipped: skippedCount,
        errors: errorCount,
        total: usersSnapshot.size,
      });
    } catch (error) {
      logError("[Comeback Reminder] Function failed", error);
    }
  }
);

// ============================================================================
// BI-WEEKLY SUMMARY
// Runs on 1st and 15th of each month at 09:00 (Europe/Zagreb)
// Sends summary of bookings and revenue for the past 15 days
// ============================================================================
export const biweeklySummary = onSchedule(
  {
    schedule: "0 9 1,15 * *", // 09:00 on 1st and 15th
    timeZone: "Europe/Zagreb",
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    logInfo("[Bi-weekly Summary] Starting summary generation");

    try {
      // Calculate date range (last 15 days)
      const now = new Date();
      const fifteenDaysAgo = new Date(now);
      fifteenDaysAgo.setDate(now.getDate() - 15);
      fifteenDaysAgo.setHours(0, 0, 0, 0);

      const startTs = admin.firestore.Timestamp.fromDate(fifteenDaysAgo);

      // Get all active owners
      const ownersSnapshot = await db
        .collection("users")
        .where("accountStatus", "in", ["trial", "active", "premium"])
        .limit(1000)
        .get();

      if (ownersSnapshot.empty) {
        logInfo("[Bi-weekly Summary] No active owners");
        return;
      }

      logInfo("[Bi-weekly Summary] Processing owners", {
        count: ownersSnapshot.size,
      });

      let sentCount = 0;
      let errorCount = 0;

      for (const ownerDoc of ownersSnapshot.docs) {
        const ownerId = ownerDoc.id;

        try {
          // Get bookings created in the last 15 days for this owner
          const bookingsSnapshot = await db
            .collectionGroup("bookings")
            .where("owner_id", "==", ownerId)
            .where("created_at", ">=", startTs)
            .limit(100)
            .get();

          const bookingsCount = bookingsSnapshot.size;

          // Calculate revenue from confirmed/completed bookings
          let totalRevenue = 0;
          bookingsSnapshot.docs.forEach((doc) => {
            const booking = doc.data();
            if (booking.status === "confirmed" || booking.status === "completed") {
              totalRevenue += booking.total_price || 0;
            }
          });

          // Only send if there's activity
          if (bookingsCount === 0 && totalRevenue === 0) {
            continue;
          }

          const formattedRevenue = new Intl.NumberFormat("hr-HR", {
            style: "currency",
            currency: "EUR",
          }).format(totalRevenue);

          await sendPushNotification({
            userId: ownerId,
            title: "Vaš dvotjedni pregled 📊",
            body: `Zadnjih 15 dana: ${bookingsCount} ${getBookingPluralHr(bookingsCount)}, ${formattedRevenue} prihoda.`,
            category: "payments",
            data: {
              action: "biweekly_summary",
              bookingsCount: bookingsCount.toString(),
              revenue: totalRevenue.toString(),
            },
          });

          sentCount++;
        } catch (error) {
          logError("[Bi-weekly Summary] Failed for owner", error, {ownerId});
          errorCount++;
        }
      }

      logSuccess("[Bi-weekly Summary] Completed", {
        sent: sentCount,
        errors: errorCount,
        totalOwners: ownersSnapshot.size,
      });
    } catch (error) {
      logError("[Bi-weekly Summary] Function failed", error);
    }
  }
);

// ============================================================================
// MONTHLY REVENUE REPORT
// Runs on 1st of each month at 10:00 (Europe/Zagreb)
// Sends detailed revenue report for the previous month
// ============================================================================
export const monthlyRevenueReport = onSchedule(
  {
    schedule: "0 10 1 * *", // 10:00 on 1st of each month
    timeZone: "Europe/Zagreb",
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    logInfo("[Monthly Report] Starting monthly revenue report");

    try {
      // Calculate previous month's date range
      const now = new Date();
      const firstDayPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const lastDayPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);

      const startTs = admin.firestore.Timestamp.fromDate(firstDayPrevMonth);
      const endTs = admin.firestore.Timestamp.fromDate(lastDayPrevMonth);

      const monthName = firstDayPrevMonth.toLocaleDateString("hr-HR", {month: "long"});

      // Get all active owners
      const ownersSnapshot = await db
        .collection("users")
        .where("accountStatus", "in", ["trial", "active", "premium"])
        .limit(1000)
        .get();

      if (ownersSnapshot.empty) {
        logInfo("[Monthly Report] No active owners");
        return;
      }

      logInfo("[Monthly Report] Processing owners", {
        count: ownersSnapshot.size,
        month: monthName,
      });

      let sentCount = 0;
      let errorCount = 0;

      for (const ownerDoc of ownersSnapshot.docs) {
        const ownerId = ownerDoc.id;

        try {
          // Get bookings for previous month (by check_in date for accurate reporting)
          const bookingsSnapshot = await db
            .collectionGroup("bookings")
            .where("owner_id", "==", ownerId)
            .where("check_in", ">=", startTs)
            .where("check_in", "<=", endTs)
            .limit(500)
            .get();

          // Calculate stats
          let totalRevenue = 0;
          let confirmedCount = 0;
          let cancelledCount = 0;

          bookingsSnapshot.docs.forEach((doc) => {
            const booking = doc.data();
            if (booking.status === "confirmed" || booking.status === "completed") {
              totalRevenue += booking.total_price || 0;
              confirmedCount++;
            } else if (booking.status === "cancelled") {
              cancelledCount++;
            }
          });

          // Only send if there's activity
          if (confirmedCount === 0 && cancelledCount === 0) {
            continue;
          }

          const formattedRevenue = new Intl.NumberFormat("hr-HR", {
            style: "currency",
            currency: "EUR",
          }).format(totalRevenue);

          await sendPushNotification({
            userId: ownerId,
            title: `Izvještaj prihoda za ${monthName} 💰`,
            body: `${confirmedCount} ${getBookingPluralHr(confirmedCount)}, ukupno ${formattedRevenue} prihoda.`,
            category: "payments",
            data: {
              action: "monthly_report",
              month: monthName,
              bookingsCount: confirmedCount.toString(),
              revenue: totalRevenue.toString(),
              cancelled: cancelledCount.toString(),
            },
          });

          sentCount++;
        } catch (error) {
          logError("[Monthly Report] Failed for owner", error, {ownerId});
          errorCount++;
        }
      }

      logSuccess("[Monthly Report] Completed", {
        sent: sentCount,
        errors: errorCount,
        totalOwners: ownersSnapshot.size,
        month: monthName,
      });
    } catch (error) {
      logError("[Monthly Report] Function failed", error);
    }
  }
);

// ============================================================================
// NEW APP UPDATE NOTIFICATION
// Triggered when app_config/{platform} document is updated
// Sends push notification to all users with FCM tokens about the new version
// ============================================================================
export const newAppUpdateNotification = onDocumentUpdated(
  {
    document: "app_config/{platform}",
    region: "europe-west1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (event) => {
    const platform = event.params.platform;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logWarn("[App Update] Missing before/after data");
      return;
    }

    const previousVersion = beforeData.latestVersion;
    const newVersion = afterData.latestVersion;

    // Only proceed if latestVersion actually changed
    if (previousVersion === newVersion) {
      logInfo("[App Update] No version change detected");
      return;
    }

    logInfo("[App Update] New version detected", {
      platform,
      previousVersion,
      newVersion,
    });

    try {
      // Get all users with FCM tokens (they have the app installed)
      // We check for users who have fcmTokens subcollection
      const usersSnapshot = await db
        .collection("users")
        .where("accountStatus", "in", ["trial", "active", "premium"])
        .limit(1000)
        .get();

      if (usersSnapshot.empty) {
        logInfo("[App Update] No active users to notify");
        return;
      }

      logInfo("[App Update] Checking users for FCM tokens", {
        totalUsers: usersSnapshot.size,
      });

      let sentCount = 0;
      let skippedCount = 0;
      let errorCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Check if user was already notified for this version
        if (userData.lastNotifiedAppVersion === newVersion) {
          skippedCount++;
          continue;
        }

        try {
          // Check if user has FCM tokens (means they have the app installed)
          const tokensDoc = await db
            .collection("users")
            .doc(userId)
            .collection("data")
            .doc("fcmTokens")
            .get();

          if (!tokensDoc.exists || !tokensDoc.data()) {
            skippedCount++;
            continue;
          }

          const tokensData = tokensDoc.data();
          const hasTokens = tokensData && Object.keys(tokensData).length > 0;

          if (!hasTokens) {
            skippedCount++;
            continue;
          }

          // Send push notification
          const sent = await sendPushNotification({
            userId,
            title: "Nova verzija dostupna 🚀",
            body: `BookBed ${newVersion} je sada dostupna s poboljšanjima i ispravkama.`,
            category: "marketing",
            data: {
              action: "app_update",
              version: newVersion,
              platform,
            },
          });

          if (sent) {
            // Mark user as notified for this version
            await db.collection("users").doc(userId).update({
              lastNotifiedAppVersion: newVersion,
            });
            sentCount++;
          } else {
            skippedCount++;
          }
        } catch (error) {
          logError("[App Update] Failed for user", error, {userId});
          errorCount++;
        }
      }

      logSuccess("[App Update] Notification complete", {
        platform,
        newVersion,
        sent: sentCount,
        skipped: skippedCount,
        errors: errorCount,
      });
    } catch (error) {
      logError("[App Update] Function failed", error, {platform, newVersion});
    }
  }
);
