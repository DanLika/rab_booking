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
  });
});
