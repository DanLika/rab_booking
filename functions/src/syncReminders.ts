import {onSchedule} from "firebase-functions/v2/scheduler";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {sendEmailIfAllowed} from "./emailNotificationHelper";
import {sendSms} from "./smsService";
import {createNotification} from "./notificationService";
import {sendPushNotification} from "./fcmService";
import {getResendClient} from "./emailService";

/**
 * Sync Reminders Service
 * 
 * Sends reminders to owners to manually block dates on external platforms
 * when bookings are created but API sync is not available
 * 
 * Runs every hour to check for recent bookings that need blocking
 */

/**
 * Scheduled function to send sync reminders
 * Runs every hour
 */
export const scheduledSyncReminders = onSchedule(
  {
    schedule: "every 1 hours",
    timeoutSeconds: 540,
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    try {
      logInfo("[Sync Reminders] Starting scheduled reminder check");

      // Get bookings created in the last hour
      const oneHourAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 60 * 60 * 1000)
      );

      // NEW STRUCTURE: Use collection group query
      const bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("created_at", ">=", oneHourAgo)
        .where("status", "in", ["pending", "confirmed"])
        .limit(100)
        .get();

      if (bookingsSnapshot.empty) {
        logInfo("[Sync Reminders] No recent bookings found");
        return;
      }

      logInfo("[Sync Reminders] Found recent bookings", {
        count: bookingsSnapshot.size,
      });

      // PERFORMANCE: Solve N+1 query problem by batching fetches
      const unitIds = [...new Set(
        bookingsSnapshot.docs
          .map(doc => doc.data().unit_id)
          .filter(Boolean)
      )];

      // 1. Batch fetch all required platform connections
      const connectionsByUnit = new Map<string, any[]>();
      if (unitIds.length > 0) {
        const connectionsSnapshot = await db
          .collection("platform_connections")
          .where("unit_id", "in", unitIds)
          .where("status", "==", "active")
          .get();

        connectionsSnapshot.docs.forEach(doc => {
          const data = doc.data();
          if (!connectionsByUnit.has(data.unit_id)) {
            connectionsByUnit.set(data.unit_id, []);
          }
          connectionsByUnit.get(data.unit_id)!.push(data);
        });
      }

      // 2. Batch fetch all required unit names
      // PERFORMANCE: Firestore `in` query limit is 30, process in chunks
      const unitNames = new Map<string, string>();
      if (unitIds.length > 0) {
        for (let i = 0; i < unitIds.length; i += 30) {
          const chunk = unitIds.slice(i, i + 30);
          const unitsSnapshot = await db
            .collection("units")
            .where(admin.firestore.FieldPath.documentId(), "in", chunk)
            .get();

          unitsSnapshot.docs.forEach(doc => {
            unitNames.set(doc.id, doc.data()?.name || "Unknown Unit");
          });
        }
      }

      // 3. Process bookings with cached data
      const remindersByOwner = new Map<string, Array<{
        bookingId: string;
        unitId: string;
        unitName: string;
        checkIn: Date;
        checkOut: Date;
        guestName: string;
      }>>();

      for (const bookingDoc of bookingsSnapshot.docs) {
        const bookingData = bookingDoc.data();
        const unitId = bookingData.unit_id;

        // Skip if this unit has no active connections
        if (!unitId || !connectionsByUnit.has(unitId)) {
          continue;
        }

        const ownerId = bookingData.owner_id;
        const checkIn = bookingData.check_in?.toDate();
        const checkOut = bookingData.check_out?.toDate();

        if (!ownerId || !checkIn || !checkOut) {
          continue;
        }

        if (!remindersByOwner.has(ownerId)) {
          remindersByOwner.set(ownerId, []);
        }

        remindersByOwner.get(ownerId)!.push({
          bookingId: bookingDoc.id,
          unitId,
          unitName: unitNames.get(unitId) || "Unknown Unit",
          checkIn,
          checkOut,
          guestName: bookingData.guest_name || "Guest",
        });
      }

      // Send reminders to each owner
      let reminderCount = 0;
      for (const [ownerId, bookings] of remindersByOwner.entries()) {
        try {
          await sendSyncReminder(ownerId, bookings);
          reminderCount++;
        } catch (error) {
          logError("[Sync Reminders] Failed to send reminder", error, {
            ownerId,
          });
        }
      }

      logSuccess("[Sync Reminders] Reminders sent", {
        ownerCount: reminderCount,
        totalBookings: bookingsSnapshot.size,
      });
    } catch (error) {
      logError("[Sync Reminders] Error in scheduled reminder check", error);
    }
  }
);

/**
 * Send sync reminder to owner
 */
async function sendSyncReminder(
  ownerId: string,
  bookings: Array<{
    bookingId: string;
    unitId: string;
    unitName: string;
    checkIn: Date;
    checkOut: Date;
    guestName: string;
  }>
): Promise<void> {
  try {
    // Get owner data
    const ownerDoc = await db.collection("users").doc(ownerId).get();
    if (!ownerDoc.exists) {
      return;
    }

    const ownerData = ownerDoc.data()!;
    const ownerEmail = ownerData.email;
    const ownerName = ownerData.name || "Owner";
    const ownerPhone = ownerData.phone;

    // PERFORMANCE: Get platform connections for all units in a single query
    const unitIds = [...new Set(bookings.map((b) => b.unitId))];
    const allConnections: Array<{unitId: string; platform: string}> = [];

    if (unitIds.length > 0) {
      const connectionsSnapshot = await db
        .collection("platform_connections")
        .where("unit_id", "in", unitIds)
        .where("status", "==", "active")
        .get();

      connectionsSnapshot.docs.forEach(connDoc => {
        const connData = connDoc.data();
        allConnections.push({
          unitId: connData.unit_id,
          platform: connData.platform,
        });
      });
    }

    if (allConnections.length === 0) {
      return; // No connections to remind about
    }

    const platforms = [...new Set(allConnections.map((c) => c.platform))];
    const platformsText = platforms
      .map((p) => (p === "booking_com" ? "Booking.com" : "Airbnb"))
      .join(", ");

    const viewInAppUrl = `https://app.bookbed.io/owner/bookings`;

    // Send all notification types
    await Promise.allSettled([
      sendSyncReminderEmail(ownerId, ownerEmail, ownerName, bookings, platformsText, viewInAppUrl),
      sendSyncReminderPush(ownerId, bookings.length, platformsText, viewInAppUrl),
      createSyncReminderFirestoreNotification(ownerId, bookings.length, platformsText),
      ownerPhone
        ? sendSyncReminderSms(ownerId, ownerPhone, bookings.length, platformsText, viewInAppUrl)
        : Promise.resolve(),
    ]);
  } catch (error) {
    logError("[Sync Reminders] Error sending reminder", error, {
      ownerId,
    });
  }
}

/**
 * Send email reminder
 */
async function sendSyncReminderEmail(
  ownerId: string,
  ownerEmail: string,
  ownerName: string,
  bookings: Array<{
    bookingId: string;
    unitId: string;
    unitName: string;
    checkIn: Date;
    checkOut: Date;
    guestName: string;
  }>,
  platformsText: string,
  viewInAppUrl: string
): Promise<void> {
  const bookingsList = bookings
    .map(
      (b) =>
        `<li><strong>${b.unitName}</strong>: ${b.guestName}, ${b.checkIn.toLocaleDateString()} - ${b.checkOut.toLocaleDateString()}</li>`
    )
    .join("");

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #ffc107; color: #333; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
        .alert { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .button { display: inline-block; padding: 12px 24px; background-color: #0066cc; color: white; text-decoration: none; border-radius: 4px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Reminder: Block Dates on External Platforms</h1>
        </div>
        <div class="content">
          <p>Hello ${ownerName},</p>
          <p>You have <strong>${bookings.length}</strong> recent booking(s) that need to be blocked on ${platformsText}:</p>
          <ul>
            ${bookingsList}
          </ul>
          <div class="alert">
            <strong>Action Required:</strong> Please block these dates on ${platformsText} to prevent overbooking.
          </div>
          <div style="text-align: center; margin: 20px 0;">
            <a href="${viewInAppUrl}" class="button">View Bookings</a>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;

  await sendEmailIfAllowed(
    ownerId,
    "calendar",
    async () => {
      const resendClient = getResendClient();
      const fromEmail = process.env.FROM_EMAIL || "noreply@bookbed.io";
      const fromName = process.env.FROM_NAME || "BookBed";

      await resendClient.emails.send({
        from: `${fromName} <${fromEmail}>`,
        to: ownerEmail,
        subject: "Reminder: Block Dates on External Platforms",
        html,
      });
    },
    false
  );
}

/**
 * Send push notification reminder
 */
async function sendSyncReminderPush(
  ownerId: string,
  bookingCount: number,
  platformsText: string,
  viewInAppUrl: string
): Promise<void> {
  await sendPushNotification({
    userId: ownerId,
    title: "Sync Reminder",
    body: `${bookingCount} booking(s) need blocking on ${platformsText}`,
    category: "calendar",
    data: {
      type: "sync_reminder",
      bookingCount: bookingCount.toString(),
      deepLink: viewInAppUrl,
    },
  });
}

/**
 * Create Firestore notification reminder
 */
async function createSyncReminderFirestoreNotification(
  ownerId: string,
  bookingCount: number,
  platformsText: string
): Promise<void> {
  await createNotification({
    ownerId,
    type: "sync_reminder",
    title: "Sync Reminder",
    message: `${bookingCount} booking(s) need blocking on ${platformsText}`,
    metadata: {
      bookingCount,
      platforms: platformsText,
    },
  });
}

/**
 * Send SMS reminder
 */
async function sendSyncReminderSms(
  ownerId: string,
  ownerPhone: string,
  bookingCount: number,
  platformsText: string,
  viewInAppUrl: string
): Promise<void> {
  const message = `Reminder: ${bookingCount} booking(s) need blocking on ${platformsText}.\n${viewInAppUrl}`;

  await sendSms({
    to: ownerPhone,
    message,
    ownerId,
    category: "calendar",
  });
}

