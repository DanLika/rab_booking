import {db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {sendPushNotification} from "./fcmService";
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
    const blockBookingComUrl = await generateBlockBookingComUrl(conflict);
    const blockAirbnbUrl = await generateBlockAirbnbUrl(conflict);

    // Send all notification types in parallel
    await Promise.allSettled([
      sendOverbookingEmailNotification(conflict, {
        ownerEmail,
        ownerName,
        viewInAppUrl,
        blockBookingComUrl,
        blockAirbnbUrl,
      }),
      sendOverbookingPushNotification(conflict, {
        ownerId: conflict.ownerId,
        viewInAppUrl,
      }),
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
    blockBookingComUrl?: string;
    blockAirbnbUrl?: string;
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
      blockBookingComUrl: options.blockBookingComUrl,
      blockAirbnbUrl: options.blockAirbnbUrl,
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

/**
 * Generate deep link URL for blocking dates on Booking.com
 */
async function generateBlockBookingComUrl(
  conflict: OverbookingConflictData
): Promise<string | undefined> {
  try {
    // Get platform connection for this unit
    const connectionsSnapshot = await db
      .collection("platform_connections")
      .where("unit_id", "==", conflict.unitId)
      .where("platform", "==", "booking_com")
      .where("status", "==", "active")
      .limit(1)
      .get();

    if (connectionsSnapshot.empty) {
      return undefined;
    }

    const connection = connectionsSnapshot.docs[0].data();
    const hotelId = connection.external_property_id;
    const roomTypeId = connection.external_unit_id;
    const checkIn = conflict.conflictDates[0];
    const checkOut = conflict.conflictDates[conflict.conflictDates.length - 1];

    return `https://admin.booking.com/hotels/${hotelId}/room-types/${roomTypeId}/calendar?checkin=${checkIn.toISOString().split("T")[0]}&checkout=${checkOut.toISOString().split("T")[0]}`;
  } catch (error) {
    logError("[Overbooking Notifications] Failed to generate Booking.com URL", error);
    return undefined;
  }
}

/**
 * Generate deep link URL for blocking dates on Airbnb
 */
async function generateBlockAirbnbUrl(
  conflict: OverbookingConflictData
): Promise<string | undefined> {
  try {
    // Get platform connection for this unit
    const connectionsSnapshot = await db
      .collection("platform_connections")
      .where("unit_id", "==", conflict.unitId)
      .where("platform", "==", "airbnb")
      .where("status", "==", "active")
      .limit(1)
      .get();

    if (connectionsSnapshot.empty) {
      return undefined;
    }

    const connection = connectionsSnapshot.docs[0].data();
    const listingId = connection.external_property_id;
    const checkIn = conflict.conflictDates[0];
    const checkOut = conflict.conflictDates[conflict.conflictDates.length - 1];

    return `https://www.airbnb.com/hosting/listings/${listingId}/calendar?checkin=${checkIn.toISOString().split("T")[0]}&checkout=${checkOut.toISOString().split("T")[0]}`;
  } catch (error) {
    logError("[Overbooking Notifications] Failed to generate Airbnb URL", error);
    return undefined;
  }
}

