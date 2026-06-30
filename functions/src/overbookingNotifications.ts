import {db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {sendPushNotification} from "./fcmService";
import {sendOverbookingSmsNotification} from "./smsService";
import {createNotification} from "./notificationService";
import {sendEmailIfAllowed} from "./emailNotificationHelper";
import {sendOverbookingDetectedEmailV2} from "./email";
import {getResendClient} from "./emailService";

/**
 * Overbooking Notifications Service
 *
 * Sends notifications (email, push, Firestore) when overbooking is detected
 */

interface OverbookingConflictData {
  conflictId: string;
  ownerId: string;
  unitId: string;
  unitName: string;
  booking1: {
    id: string;
    guestName: string;
    checkIn: Date;
    checkOut: Date;
    source: string;
  };
  booking2: {
    id: string;
    guestName: string;
    checkIn: Date;
    checkOut: Date;
    source: string;
  };
  conflictDates: Date[];
}

/**
 * Send all notifications for overbooking conflict
 */
export async function sendOverbookingNotifications(
  conflict: OverbookingConflictData
): Promise<void> {
  try {
    logInfo("[Overbooking Notifications] Sending notifications", {
      conflictId: conflict.conflictId,
      ownerId: conflict.ownerId,
    });

    // Get owner data
    const ownerDoc = await db.collection("users").doc(conflict.ownerId).get();
    if (!ownerDoc.exists) {
      logError("[Overbooking Notifications] Owner not found", null, {
        ownerId: conflict.ownerId,
      });
      return;
    }

    const ownerData = ownerDoc.data()!;
    const ownerEmail = ownerData.email;
    const ownerName = ownerData.name || "Owner";

    // Generate deep links
    const viewInAppUrl = `https://app.bookbed.io/owner/calendar?unit=${conflict.unitId}&conflict=${conflict.conflictId}`;

    // Send all notification types in parallel
    await Promise.allSettled([
      sendOverbookingEmailNotification(conflict, {
        ownerEmail,
        ownerName,
        viewInAppUrl,
      }),
      sendOverbookingPushNotification(conflict, {
        ownerId: conflict.ownerId,
        viewInAppUrl,
      }),
      sendOverbookingSmsNotification(
        conflict.ownerId,
        conflict.unitName,
        conflict.booking1.guestName,
        conflict.booking2.guestName
      ).catch((e) => logError("[Overbooking Notifications] SMS failed", e)),
      createOverbookingFirestoreNotification(conflict),
    ]);

    logSuccess("[Overbooking Notifications] All notifications sent", {
      conflictId: conflict.conflictId,
    });
  } catch (error) {
    logError("[Overbooking Notifications] Error sending notifications", error, {
      conflictId: conflict.conflictId,
    });
  }
}

/**
 * Send email notification for overbooking
 */
async function sendOverbookingEmailNotification(
  conflict: OverbookingConflictData,
  options: {
    ownerEmail: string;
    ownerName: string;
    viewInAppUrl: string;
  }
): Promise<void> {
  try {
    const emailParams = {
      ownerEmail: options.ownerEmail,
      ownerName: options.ownerName,
      unitName: conflict.unitName,
      conflictId: conflict.conflictId,
      booking1GuestName: conflict.booking1.guestName,
      booking1CheckIn: conflict.booking1.checkIn,
      booking1CheckOut: conflict.booking1.checkOut,
      booking1Source: conflict.booking1.source,
      booking2GuestName: conflict.booking2.guestName,
      booking2CheckIn: conflict.booking2.checkIn,
      booking2CheckOut: conflict.booking2.checkOut,
      booking2Source: conflict.booking2.source,
      conflictDates: conflict.conflictDates,
      viewConflictUrl: options.viewInAppUrl,
      viewInAppUrl: options.viewInAppUrl,
    };

    await sendEmailIfAllowed(
      conflict.ownerId,
      "calendar",
      async () => {
        const resendClient = getResendClient();
        const fromEmail = process.env.FROM_EMAIL || "";
        const fromName = process.env.FROM_NAME || "BookBed";

        await sendOverbookingDetectedEmailV2(
          resendClient,
          emailParams,
          fromEmail,
          fromName
        );
      },
      true // Force send for critical events
    );

    logSuccess("[Overbooking Notifications] Email sent", {
      conflictId: conflict.conflictId,
      ownerEmail: options.ownerEmail,
    });
  } catch (error) {
    logError("[Overbooking Notifications] Failed to send email", error, {
      conflictId: conflict.conflictId,
    });
  }
}

/**
 * Send push notification for overbooking (Croatian localized)
 */
async function sendOverbookingPushNotification(
  conflict: OverbookingConflictData,
  options: {
    ownerId: string;
    viewInAppUrl: string;
  }
): Promise<void> {
  try {
    await sendPushNotification({
      userId: options.ownerId,
      title: "⚠️ Overbooking detektiran",
      body: `${conflict.unitName}: Konflikt između ${conflict.booking1.guestName} i ${conflict.booking2.guestName}. Riješite odmah!`,
      category: "calendar",
      data: {
        conflictId: conflict.conflictId,
        unitId: conflict.unitId,
        deepLink: options.viewInAppUrl,
        type: "overbooking",
      },
    });

    logSuccess("[Overbooking Notifications] Push notification sent", {
      conflictId: conflict.conflictId,
    });
  } catch (error) {
    logError("[Overbooking Notifications] Failed to send push notification", error, {
      conflictId: conflict.conflictId,
    });
  }
}

/**
 * Create Firestore notification for overbooking (Croatian localized)
 */
async function createOverbookingFirestoreNotification(
  conflict: OverbookingConflictData
): Promise<void> {
  try {
    await createNotification({
      ownerId: conflict.ownerId,
      type: "overbooking_detected",
      title: "⚠️ Overbooking detektiran",
      message: `Konflikt za ${conflict.unitName}: ${conflict.booking1.guestName} vs ${conflict.booking2.guestName}. Otkažite jednu rezervaciju.`,
      bookingId: conflict.booking1.id, // Use first booking ID
      metadata: {
        conflictId: conflict.conflictId,
        unitId: conflict.unitId,
        unitName: conflict.unitName,
        booking1Id: conflict.booking1.id,
        booking2Id: conflict.booking2.id,
        conflictDates: conflict.conflictDates.map((d) => d.toISOString()),
      },
    });

    logSuccess("[Overbooking Notifications] Firestore notification created", {
      conflictId: conflict.conflictId,
    });
  } catch (error) {
    logError("[Overbooking Notifications] Failed to create Firestore notification", error, {
      conflictId: conflict.conflictId,
    });
  }
}


