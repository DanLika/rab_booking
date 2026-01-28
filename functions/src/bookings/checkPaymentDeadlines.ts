/**
 * @deprecated REPLACED by pendingPaymentReminder in scheduledPushNotifications.ts
 *
 * This file is kept for reference but is no longer exported or used.
 * The new function has:
 * - Specific time (10:00 Europe/Zagreb) instead of "every 24 hours"
 * - Duplicate prevention via paymentReminderSent flag
 * - Better logging and error handling
 *
 * TODO: Delete this file after verifying new function works in production.
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import {admin, db} from "../firebase";
import {logInfo, logError, logSuccess} from "../logger";
import {sendPaymentDeadlinePushNotification} from "../fcmService";
import {createNotification} from "../notificationService";

/**
 * @deprecated Use pendingPaymentReminder from scheduledPushNotifications.ts instead
 */
export const checkPaymentDeadlines = onSchedule("every 24 hours", async () => {
  logInfo("Pokrećem provjeru rokova plaćanja...");

  try {
    const now = admin.firestore.Timestamp.now();
    const twentyFourHoursFromNow = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 24 * 60 * 60 * 1000
    );

    const expiringBookings = await db
      .collectionGroup("bookings")
      .where("status", "==", "pending")
      .where("payment_method", "==", "bank_transfer")
      .where("payment_deadline", "<=", twentyFourHoursFromNow)
      .where("payment_deadline", ">", now)
      .get();

    if (expiringBookings.empty) {
      logInfo("Nema rezervacija s istečenim rokom plaćanja.");
      return;
    }

    logInfo(`Pronađeno ${expiringBookings.size} rezervacija s istečenim rokom.`);

    const notificationPromises = expiringBookings.docs.map(async (doc) => {
      const booking = doc.data();
      const bookingId = doc.id;
      const ownerId = booking.owner_id;
      const guestName = booking.guest_name || "Gost";

      if (!ownerId) {
        logError("Rezervacija nema owner_id, ne mogu poslati obavijest", null, {bookingId});
        return;
      }

      // Send push notification
      await sendPaymentDeadlinePushNotification(ownerId, bookingId, guestName);

      // Create in-app notification
      await createNotification({
        ownerId,
        type: "payment_deadline_approaching",
        title: "Rok plaćanja ističe",
        message: `Rok plaćanja za rezervaciju od ${guestName} uskoro ističe.`,
        bookingId,
      });
    });

    await Promise.all(notificationPromises);

    logSuccess("Uspješno provjereni rokovi plaćanja.");
  } catch (error) {
    logError("Greška pri provjeri rokova plaćanja", error);
  }
});
