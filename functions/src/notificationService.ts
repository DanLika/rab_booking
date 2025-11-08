import {admin, db} from "./firebase";

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
 */
export async function createNotification(data: NotificationData): Promise<void> {
  try {
    await db.collection("notifications").add({
      ownerId: data.ownerId,
      type: data.type,
      title: data.title,
      message: data.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      bookingId: data.bookingId || null,
      metadata: data.metadata || null,
    });

    console.log(`✅ Notification created for owner ${data.ownerId}: ${data.type}`);
  } catch (error) {
    console.error("❌ Error creating notification:", error);
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
    bookingId,
    metadata: {guestName},
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
