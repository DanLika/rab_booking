import {db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {sendPushNotification} from "./fcmService";
import {createNotification} from "./notificationService";
import {sendEmailIfAllowed} from "./emailNotificationHelper";
import {sendSms} from "./smsService";
import {getResendClient} from "./emailService";

/**
 * External Booking Notifications Service
 * 
 * Sends notifications when new bookings are synced from external platforms (iCal)
 * Reminds owners to block dates on other platforms
 */

interface ExternalBookingData {
  bookingId: string;
  ownerId: string;
  unitId: string;
  unitName: string;
  platform: string;
  guestName: string;
  checkIn: Date;
  checkOut: Date;
}

/**
 * Send notifications for new external booking
 */
export async function sendExternalBookingNotifications(
  booking: ExternalBookingData
): Promise<void> {
  try {
    logInfo("[External Booking Notifications] Sending notifications", {
      bookingId: booking.bookingId,
      ownerId: booking.ownerId,
      platform: booking.platform,
    });

    // Get owner data
    const ownerDoc = await db.collection("users").doc(booking.ownerId).get();
    if (!ownerDoc.exists) {
      logError("[External Booking Notifications] Owner not found", null, {
        ownerId: booking.ownerId,
      });
      return;
    }

    const ownerData = ownerDoc.data()!;
    const ownerEmail = ownerData.email;
    const ownerName = ownerData.name || "Owner";
    const ownerPhone = ownerData.phone;

    // Check if owner has other platform connections
    const connectionsSnapshot = await db
      .collection("platform_connections")
      .where("unit_id", "==", booking.unitId)
      .where("status", "==", "active")
      .get();

    const otherPlatforms = connectionsSnapshot.docs
      .map((doc) => doc.data().platform)
      .filter((platform) => platform !== booking.platform);

    // Only send notification if there are other platforms to block
    if (otherPlatforms.length === 0) {
      logInfo("[External Booking Notifications] No other platforms to block", {
        bookingId: booking.bookingId,
      });
      return;
    }

    // Generate deep links
    const viewInAppUrl = `https://app.bookbed.io/owner/bookings?booking=${booking.bookingId}`;
    const blockUrls = await generateBlockUrls(booking, otherPlatforms);

    // Send all notification types in parallel
    await Promise.allSettled([
      sendExternalBookingEmailNotification(booking, {
        ownerEmail,
        ownerName,
        otherPlatforms,
        viewInAppUrl,
        blockUrls,
      }),
      sendExternalBookingPushNotification(booking, {
        ownerId: booking.ownerId,
        otherPlatforms,
        viewInAppUrl,
      }),
      createExternalBookingFirestoreNotification(booking, {
        otherPlatforms,
      }),
      ownerPhone
        ? sendExternalBookingSmsNotification(booking, {
            ownerPhone,
            otherPlatforms,
            viewInAppUrl,
          })
        : Promise.resolve(),
    ]);

    logSuccess("[External Booking Notifications] All notifications sent", {
      bookingId: booking.bookingId,
    });
  } catch (error) {
    logError("[External Booking Notifications] Error sending notifications", error, {
      bookingId: booking.bookingId,
    });
  }
}

/**
 * Send email notification for external booking
 */
async function sendExternalBookingEmailNotification(
  booking: ExternalBookingData,
  options: {
    ownerEmail: string;
    ownerName: string;
    otherPlatforms: string[];
    viewInAppUrl: string;
    blockUrls: Record<string, string>;
  }
): Promise<void> {
  try {
    const platformName = booking.platform === "booking_com" ? "Booking.com" : "Airbnb";
    const otherPlatformsText = options.otherPlatforms
      .map((p) => (p === "booking_com" ? "Booking.com" : "Airbnb"))
      .join(", ");

    const subject = `New ${platformName} Booking - Block Dates Required`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #0066cc; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
          .alert { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          .button { display: inline-block; padding: 12px 24px; background-color: #0066cc; color: white; text-decoration: none; border-radius: 4px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>New ${platformName} Booking</h1>
          </div>
          <div class="content">
            <p>Hello ${options.ownerName},</p>
            <p>A new booking has been synced from <strong>${platformName}</strong>:</p>
            <ul>
              <li><strong>Guest:</strong> ${booking.guestName}</li>
              <li><strong>Check-in:</strong> ${booking.checkIn.toLocaleDateString()}</li>
              <li><strong>Check-out:</strong> ${booking.checkOut.toLocaleDateString()}</li>
              <li><strong>Unit:</strong> ${booking.unitName}</li>
            </ul>
            <div class="alert">
              <strong>Action Required:</strong> Please block these dates on ${otherPlatformsText} to prevent overbooking.
            </div>
            <div style="text-align: center; margin: 20px 0;">
              <a href="${options.viewInAppUrl}" class="button">View in App</a>
              ${Object.entries(options.blockUrls).map(([platform, url]) => 
                `<a href="${url}" class="button">Block on ${platform === "booking_com" ? "Booking.com" : "Airbnb"}</a>`
              ).join("")}
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    await sendEmailIfAllowed(
      booking.ownerId,
      "calendar",
      async () => {
        const resendClient = getResendClient();
        const fromEmail = process.env.FROM_EMAIL || "noreply@bookbed.io";
        const fromName = process.env.FROM_NAME || "BookBed";

        await resendClient.emails.send({
          from: `${fromName} <${fromEmail}>`,
          to: options.ownerEmail,
          subject,
          html,
        });
      },
      false // Not critical, respect preferences
    );

    logSuccess("[External Booking Notifications] Email sent", {
      bookingId: booking.bookingId,
    });
  } catch (error) {
    logError("[External Booking Notifications] Failed to send email", error, {
      bookingId: booking.bookingId,
    });
  }
}

/**
 * Send push notification for external booking
 */
async function sendExternalBookingPushNotification(
  booking: ExternalBookingData,
  options: {
    ownerId: string;
    otherPlatforms: string[];
    viewInAppUrl: string;
  }
): Promise<void> {
  try {
    const platformName = booking.platform === "booking_com" ? "Booking.com" : "Airbnb";
    const otherPlatformsText = options.otherPlatforms
      .map((p) => (p === "booking_com" ? "Booking.com" : "Airbnb"))
      .join(", ");

    await sendPushNotification({
      userId: options.ownerId,
      title: `New ${platformName} Booking`,
      body: `Dates: ${booking.checkIn.toLocaleDateString()} - ${booking.checkOut.toLocaleDateString()}. Block on ${otherPlatformsText}?`,
      category: "calendar",
      data: {
        bookingId: booking.bookingId,
        unitId: booking.unitId,
        deepLink: options.viewInAppUrl,
        type: "external_booking",
      },
    });

    logSuccess("[External Booking Notifications] Push notification sent", {
      bookingId: booking.bookingId,
    });
  } catch (error) {
    logError("[External Booking Notifications] Failed to send push notification", error, {
      bookingId: booking.bookingId,
    });
  }
}

/**
 * Create Firestore notification for external booking
 */
async function createExternalBookingFirestoreNotification(
  booking: ExternalBookingData,
  options: {
    otherPlatforms: string[];
  }
): Promise<void> {
  try {
    const platformName = booking.platform === "booking_com" ? "Booking.com" : "Airbnb";
    const otherPlatformsText = options.otherPlatforms
      .map((p) => (p === "booking_com" ? "Booking.com" : "Airbnb"))
      .join(", ");

    await createNotification({
      ownerId: booking.ownerId,
      type: "external_booking_synced",
      title: `New ${platformName} Booking`,
      message: `Booking synced: ${booking.guestName}, ${booking.checkIn.toLocaleDateString()} - ${booking.checkOut.toLocaleDateString()}. Remember to block on ${otherPlatformsText}.`,
      bookingId: booking.bookingId,
      metadata: {
        platform: booking.platform,
        unitId: booking.unitId,
        unitName: booking.unitName,
        otherPlatforms: options.otherPlatforms,
      },
    });

    logSuccess("[External Booking Notifications] Firestore notification created", {
      bookingId: booking.bookingId,
    });
  } catch (error) {
    logError("[External Booking Notifications] Failed to create Firestore notification", error, {
      bookingId: booking.bookingId,
    });
  }
}

/**
 * Send SMS notification for external booking
 */
async function sendExternalBookingSmsNotification(
  booking: ExternalBookingData,
  options: {
    ownerPhone: string;
    otherPlatforms: string[];
    viewInAppUrl: string;
  }
): Promise<void> {
  try {
    const platformName = booking.platform === "booking_com" ? "Booking.com" : "Airbnb";
    const otherPlatformsText = options.otherPlatforms
      .map((p) => (p === "booking_com" ? "Booking.com" : "Airbnb"))
      .join(", ");

    const message = `New ${platformName} booking: ${booking.checkIn.toLocaleDateString()}-${booking.checkOut.toLocaleDateString()}\n` +
      `Remember to block on ${otherPlatformsText}.\n` +
      `View: ${options.viewInAppUrl}`;

    await sendSms({
      to: options.ownerPhone,
      message,
      ownerId: booking.ownerId,
      category: "calendar",
    });

    logSuccess("[External Booking Notifications] SMS sent", {
      bookingId: booking.bookingId,
    });
  } catch (error) {
    logError("[External Booking Notifications] Failed to send SMS", error, {
      bookingId: booking.bookingId,
    });
  }
}

/**
 * Generate deep link URLs for blocking dates on other platforms
 */
async function generateBlockUrls(
  booking: ExternalBookingData,
  platforms: string[]
): Promise<Record<string, string>> {
  const urls: Record<string, string> = {};

  for (const platform of platforms) {
    try {
      const connectionsSnapshot = await db
        .collection("platform_connections")
        .where("unit_id", "==", booking.unitId)
        .where("platform", "==", platform)
        .where("status", "==", "active")
        .limit(1)
        .get();

      if (connectionsSnapshot.empty) {
        continue;
      }

      const connection = connectionsSnapshot.docs[0].data();
      const checkIn = booking.checkIn.toISOString().split("T")[0];
      const checkOut = booking.checkOut.toISOString().split("T")[0];

      if (platform === "booking_com") {
        const hotelId = connection.external_property_id;
        const roomTypeId = connection.external_unit_id;
        urls[platform] = `https://admin.booking.com/hotels/${hotelId}/room-types/${roomTypeId}/calendar?checkin=${checkIn}&checkout=${checkOut}`;
      } else if (platform === "airbnb") {
        const listingId = connection.external_property_id;
        urls[platform] = `https://www.airbnb.com/hosting/listings/${listingId}/calendar?checkin=${checkIn}&checkout=${checkOut}`;
      }
    } catch (error) {
      logError("[External Booking Notifications] Failed to generate block URL", error, {
        platform,
        bookingId: booking.bookingId,
      });
    }
  }

  return urls;
}

