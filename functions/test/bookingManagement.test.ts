/**
 * Unit tests for bookingManagement.ts cloud functions.
 * Mocks Firestore triggers and scheduled functions.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();

// Mock dependencies
jest.mock("../src/firebase", () => {
  const mockFirestore = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
    doc: jest.fn().mockReturnThis(),
    update: jest.fn().mockResolvedValue(true),
  };
  return {
    admin: {
      firestore: {
        FieldValue: {
          serverTimestamp: () => "mock-timestamp",
        },
        Timestamp: {
          now: () => ({ toMillis: () => Date.now() }),
        },
      },
    },
    db: mockFirestore,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/emailService", () => ({
  sendBookingApprovedEmail: jest.fn(),
  sendBookingCancellationEmail: jest.fn(),
  sendBookingRejectedEmail: jest.fn(),
}));

jest.mock("../src/utils/bookingHelpers", () => ({
  fetchPropertyAndUnitDetails: jest.fn().mockResolvedValue({
    propertyName: "Test Property",
    unitName: "Test Unit",
    propertyData: { owner_id: "owner-123" },
  }),
}));

jest.mock("../src/notificationService", () => ({
  createBookingNotification: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/bookingAccessToken", () => ({
  generateBookingAccessToken: jest.fn().mockReturnValue({
    token: "plain-token",
    hashedToken: "hashed-token",
  }),
  calculateTokenExpiration: jest.fn().mockReturnValue({ toDate: () => new Date() }),
}));

// Import the functions to be tested
import {
  autoCancelExpiredBookings,
  onBookingCreated,
  onBookingStatusChange,
} from "../src/bookingManagement";

describe("Booking Management Functions", () => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockDb: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb = require("../src/firebase").db;
  });

  describe("autoCancelExpiredBookings", () => {
    it("should cancel expired pending bookings", async () => {
      // Arrange
      const mockExpiredBooking = {
        id: "booking-123",
        ref: { update: jest.fn().mockResolvedValue(true) },
        data: () => ({
          status: "pending",
          guest_email: "guest@example.com",
          booking_reference: "REF-123",
          property_id: "prop-123",
          unit_id: "unit-123",
          check_in: new Date(),
          check_out: new Date(),
        }),
      };
      mockDb.collectionGroup().where().where().get.mockResolvedValue({
        size: 1,
        docs: [mockExpiredBooking],
      });

      const wrapped = test.wrap(autoCancelExpiredBookings);

      // Act
      await wrapped({});

      // Assert
      expect(mockExpiredBooking.ref.update).toHaveBeenCalledWith(
        expect.objectContaining({ status: "cancelled" })
      );
      const { sendBookingCancellationEmail } = require("../src/emailService");
      expect(sendBookingCancellationEmail).toHaveBeenCalled();
    });
  });

  describe("onBookingCreated", () => {
    it("should create an in-app notification for owner", async () => {
      // Arrange
      const bookingData = {
        property_id: "prop-123",
        unit_id: "unit-123",
        guest_name: "John Doe",
        payment_method: "bank_transfer",
        require_owner_approval: true,
      };
      const snapshot = test.firestore.makeDocumentSnapshot(bookingData, "properties/prop-123/units/unit-123/bookings/booking-123");
      const wrapped = test.wrap(onBookingCreated);

      // Act
      await wrapped({
        data: snapshot,
        params: {
          propertyId: "prop-123",
          unitId: "unit-123",
          bookingId: "booking-123",
        },
      });

      // Assert
      const { createBookingNotification } = require("../src/notificationService");
      expect(createBookingNotification).toHaveBeenCalledWith(
        "owner-123",
        "booking-123",
        "John Doe",
        "created"
      );
    });

    // audit/34 §5 — per-trigger idempotency marker for retry storms.
    it("should write emails_sent.initial_trigger_processed marker so redelivery short-circuits", async () => {
      // Arrange
      const bookingData = {
        property_id: "prop-456",
        unit_id: "unit-456",
        guest_name: "Jane Doe",
        guest_email: "jane@example.com",
        payment_method: "bank_transfer",
        require_owner_approval: true,
      };
      const snapshot = test.firestore.makeDocumentSnapshot(
        bookingData,
        "properties/prop-456/units/unit-456/bookings/booking-456"
      );
      const mockUpdate = jest.fn().mockResolvedValue(true);
      Object.defineProperty(snapshot.ref, "update", { value: mockUpdate });
      const wrapped = test.wrap(onBookingCreated);

      // Act
      await wrapped({
        data: snapshot,
        params: { propertyId: "prop-456", unitId: "unit-456", bookingId: "booking-456" },
      });

      // Assert — marker written under emails_sent.initial_trigger_processed
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          "emails_sent.initial_trigger_processed": expect.objectContaining({
            email: "jane@example.com",
            booking_id: "booking-456",
            provider_id: null,
          }),
        })
      );
    });

    // Retry storm prevention — second delivery short-circuits when marker present.
    it("should skip processing when emails_sent.initial_trigger_processed already set", async () => {
      // Arrange — booking already has the marker (mid-retry state)
      const bookingData = {
        property_id: "prop-789",
        unit_id: "unit-789",
        guest_name: "Already Processed",
        payment_method: "bank_transfer",
        require_owner_approval: true,
        emails_sent: {
          initial_trigger_processed: {
            sent_at: "mock-timestamp",
            email: "x@example.com",
            booking_id: "booking-789",
            provider_id: null,
          },
        },
      };
      const snapshot = test.firestore.makeDocumentSnapshot(
        bookingData,
        "properties/prop-789/units/unit-789/bookings/booking-789"
      );
      const wrapped = test.wrap(onBookingCreated);

      const { createBookingNotification } = require("../src/notificationService");
      createBookingNotification.mockClear();

      // Act
      await wrapped({
        data: snapshot,
        params: { propertyId: "prop-789", unitId: "unit-789", bookingId: "booking-789" },
      });

      // Assert — no notification created on retry (short-circuit)
      expect(createBookingNotification).not.toHaveBeenCalled();
    });
  });

  describe("onBookingStatusChange", () => {
    it("should send approval email when status changes from pending to confirmed", async () => {
      // Arrange
      const beforeData = { status: "pending", property_id: "prop-123" };
      const afterData = {
        status: "confirmed",
        approved_at: new Date(),
        property_id: "prop-123",
        guest_email: "guest@example.com",
        booking_reference: "REF-123",
        check_in: new Date(),
        check_out: new Date(),
      };

      // Mock Firestore doc retrieval for property
      mockDb.collection().doc().get.mockResolvedValue({
        exists: true,
        data: () => ({ name: "Test Property" }),
      });

      const beforeSnapshot = test.firestore.makeDocumentSnapshot(beforeData, "properties/p/units/u/bookings/b");
      const afterSnapshot = test.firestore.makeDocumentSnapshot(afterData, "properties/p/units/u/bookings/b");

      // Use Object.defineProperty to bypass getter-only restriction if possible,
      // or just mock the prototype of the ref
      const mockUpdate = jest.fn().mockResolvedValue(true);
      Object.defineProperty(afterSnapshot.ref, "update", { value: mockUpdate });

      const wrapped = test.wrap(onBookingStatusChange);

      // Act
      await wrapped({
        data: test.makeChange(beforeSnapshot, afterSnapshot),
        params: { propertyId: "p", unitId: "u", bookingId: "b" }
      });

      // Assert
      const { sendBookingApprovedEmail } = require("../src/emailService");
      expect(sendBookingApprovedEmail).toHaveBeenCalled();
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ access_token: "hashed-token" })
      );
    });

    it("should send rejection email when status changes from pending to cancelled with rejection_reason", async () => {
      // Arrange
      const beforeData = { status: "pending", property_id: "prop-123" };
      const afterData = {
        status: "cancelled",
        rejection_reason: "Not available",
        property_id: "prop-123",
        guest_email: "guest@example.com",
        booking_reference: "REF-123",
      };

      mockDb.collection().doc().get.mockResolvedValue({
        exists: true,
        data: () => ({ name: "Test Property" }),
      });

      const beforeSnapshot = test.firestore.makeDocumentSnapshot(beforeData, "properties/p/units/u/bookings/b");
      const afterSnapshot = test.firestore.makeDocumentSnapshot(afterData, "properties/p/units/u/bookings/b");

      const mockUpdate = jest.fn().mockResolvedValue(true);
      Object.defineProperty(afterSnapshot.ref, "update", { value: mockUpdate });

      const wrapped = test.wrap(onBookingStatusChange);

      // Act
      await wrapped({
        data: test.makeChange(beforeSnapshot, afterSnapshot),
        params: { propertyId: "p", unitId: "u", bookingId: "b" }
      });

      // Assert
      const { sendBookingRejectedEmail } = require("../src/emailService");
      expect(sendBookingRejectedEmail).toHaveBeenCalledWith(
        "guest@example.com",
        "Guest",
        "REF-123",
        "Test Property",
        "Not available"
      );
    });

    // FLUTTER-7E regression: refless rejection → auto-heal + email sends.
    it("should auto-heal missing booking_reference on rejection and still send email", async () => {
      // Arrange — SEED-style booking written without booking_reference
      // (mirrors audit/67 F-67-01 fixture path that triggered FLUTTER-7E).
      const beforeData = { status: "pending", property_id: "prop-x" };
      const afterData = {
        status: "cancelled",
        rejection_reason: "F-67-01 smoke reject",
        property_id: "prop-x",
        guest_email: "guest@example.com",
        // NOTE: no booking_reference
      };

      mockDb.collection().doc().get.mockResolvedValue({
        exists: true,
        data: () => ({ name: "Test Property" }),
      });

      const beforeSnapshot = test.firestore.makeDocumentSnapshot(
        beforeData, "properties/prop-x/units/unit-x/bookings/3kG0vFHcc71k73Ykx3Mg"
      );
      const afterSnapshot = test.firestore.makeDocumentSnapshot(
        afterData, "properties/prop-x/units/unit-x/bookings/3kG0vFHcc71k73Ykx3Mg"
      );

      const mockUpdate = jest.fn().mockResolvedValue(true);
      Object.defineProperty(afterSnapshot.ref, "update", { value: mockUpdate });

      const wrapped = test.wrap(onBookingStatusChange);

      // Act
      await wrapped({
        data: test.makeChange(beforeSnapshot, afterSnapshot),
        params: { propertyId: "prop-x", unitId: "unit-x", bookingId: "3kG0vFHcc71k73Ykx3Mg" }
      });

      // Assert — auto-heal persisted + email called with healed ref (not empty)
      const expectedRef = "BK-3KG0VFHCC71K";
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ booking_reference: expectedRef })
      );
      const { sendBookingRejectedEmail } = require("../src/emailService");
      expect(sendBookingRejectedEmail).toHaveBeenCalledWith(
        "guest@example.com",
        "Guest",
        expectedRef,
        "Test Property",
        "F-67-01 smoke reject"
      );
    });

    // FLUTTER-7E sibling: refless approval → auto-heal + email sends.
    it("should auto-heal missing booking_reference on approval and still send email", async () => {
      // Arrange
      const beforeData = { status: "pending", property_id: "prop-y" };
      const afterData = {
        status: "confirmed",
        approved_at: new Date(),
        property_id: "prop-y",
        guest_email: "guest@example.com",
        check_in: new Date(),
        check_out: new Date(),
        // NOTE: no booking_reference
      };

      mockDb.collection().doc().get.mockResolvedValue({
        exists: true,
        data: () => ({ name: "Test Property" }),
      });

      const beforeSnapshot = test.firestore.makeDocumentSnapshot(
        beforeData, "properties/prop-y/units/unit-y/bookings/abcdEFgh1234"
      );
      const afterSnapshot = test.firestore.makeDocumentSnapshot(
        afterData, "properties/prop-y/units/unit-y/bookings/abcdEFgh1234"
      );

      const mockUpdate = jest.fn().mockResolvedValue(true);
      Object.defineProperty(afterSnapshot.ref, "update", { value: mockUpdate });

      const wrapped = test.wrap(onBookingStatusChange);

      // Act
      await wrapped({
        data: test.makeChange(beforeSnapshot, afterSnapshot),
        params: { propertyId: "prop-y", unitId: "unit-y", bookingId: "abcdEFgh1234" }
      });

      // Assert
      const expectedRef = "BK-ABCDEFGH1234";
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ booking_reference: expectedRef })
      );
      const { sendBookingApprovedEmail } = require("../src/emailService");
      expect(sendBookingApprovedEmail).toHaveBeenCalled();
      const callArgs = sendBookingApprovedEmail.mock.calls[0];
      // 3rd positional arg is booking_reference
      expect(callArgs[2]).toBe(expectedRef);
    });
  });
});
