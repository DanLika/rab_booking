import {admin, db} from "./firebase";
import {logInfo, logError} from "./logger";

/**
 * Notification Service
 * Creates notifications for owners in Firestore
 */

export interface NotificationData {
  ownerId: string;
  type: string;
  title: string;
  message: string;
  bookingId?: string;
  metadata?: Record<string, any>;
}

/**
 * Create a notification in Firestore
 * Uses idempotency key to prevent duplicate notifications from Cloud Function retries
 */
export async function createNotification(data: NotificationData): Promise<void> {
  try {
    // BUG-011 FIX: Improved idempotency key to include action
    // Format: {ownerId}_{type}_{bookingId}_{action}_{timestamp_minute}
    // This prevents race condition where multiple distinct notifications for the same
    // booking (e.g., created and updated) could be dropped if they occurred within the same minute
    const timestampMinute = Math.floor(Date.now() / 60000); // Round to minute
    const bookingPart = data.bookingId || "general";
    const actionPart = data.metadata?.action || "default";
    const idempotencyKey = `${data.ownerId}_${data.type}_${bookingPart}_${actionPart}_${timestampMinute}`;

    // Use set() with merge:false to prevent duplicates
    // If document already exists, this will overwrite (idempotent behavior)
    // NEW STRUCTURE: Write to users/{ownerId}/notifications subcollection
    await db
      .collection("users")
      .doc(data.ownerId)
      .collection("notifications")
      .doc(idempotencyKey)
      .set({
        ownerId: data.ownerId,
        type: data.type,
        title: data.title,
        message: data.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        bookingId: data.bookingId || null,
        metadata: data.metadata || null,
      });

    logInfo(`Notification created for owner ${data.ownerId}: ${data.type}`);
  } catch (error) {
    logError("Error creating notification", error);
    throw error;
  }
}

/**
 * Create booking-related notification
 */
export async function createBookingNotification(
  ownerId: string,
  bookingId: string,
  guestName: string,
  action: "created" | "updated" | "cancelled"
): Promise<void> {
  const titles: Record<string, string> = {
    created: "Nova rezervacija",
    updated: "Rezervacija ažurirana",
    cancelled: "Rezervacija otkazana",
  };

  const messages: Record<string, string> = {
    created: `${guestName} je kreirao novu rezervaciju.`,
    updated: `Rezervacija za ${guestName} je ažurirana.`,
    cancelled: `Rezervacija za ${guestName} je otkazana.`,
  };

  await createNotification({
    ownerId,
    type: `booking_${action}`,
    title: titles[action] || "Obavještenje",
    message: messages[action] || "Nova aktivnost na rezervaciji.",
    bookingId: bookingId,
    metadata: {guestName, action},  // BUG-011 FIX: Include action in metadata for idempotency
  });
}

/**
 * Create payment notification
 */
export async function createPaymentNotification(
  ownerId: string,
  bookingId: string,
  guestName: string,
  amount: number
): Promise<void> {
  await createNotification({
    ownerId,
    type: "payment_received",
    title: "Plaćanje primljeno",
    message: `Primljeno plaćanje od ${guestName} u iznosu od €${amount.toFixed(2)}.`,
    bookingId,
    metadata: {
      guestName,
      amount,
    },
  });
}
