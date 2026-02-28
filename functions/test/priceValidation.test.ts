import { calculateBookingPrice, validateBookingPrice } from "../src/utils/priceValidation";
import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { logPriceMismatch } from "../src/utils/securityMonitoring";

jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    get: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    Timestamp: {
      fromDate: (date: Date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }),
    },
  });

  return {
    admin: {
      firestore: firestoreFn,
    },
    db: mockFirestoreInstance,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logPriceMismatch: jest.fn().mockResolvedValue(true),
}));

import { db } from "../src/firebase";

describe("priceValidation", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.orderBy.mockReturnThis();
  });

  const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
  const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-04T00:00:00Z")); // 3 nights

  describe("calculateBookingPrice", () => {
    it("should calculate total price using daily prices", async () => {
      // Mock daily prices query
      mockDb.get.mockResolvedValueOnce({
        docs: [
          { data: () => ({ date: admin.firestore.Timestamp.fromDate(new Date("2026-06-01")), price: 100 }) },
          { data: () => ({ date: admin.firestore.Timestamp.fromDate(new Date("2026-06-02")), price: 120 }) },
          { data: () => ({ date: admin.firestore.Timestamp.fromDate(new Date("2026-06-03")), price: 100 }) },
        ]
      });

      const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

      expect(result.nights).toBe(3);
      expect(result.totalPrice).toBe(320); // 100 + 120 + 100
      expect(result.breakdown.length).toBe(3);
    });

    it("should use fallback unit price if daily prices are missing", async () => {
       // Mock daily prices query (empty)
       mockDb.get.mockResolvedValueOnce({ docs: [] });

       // Mock unit query for fallback
       mockDb.get.mockResolvedValueOnce({
         exists: true,
         data: () => ({ base_price: 150 })
       });

       const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

       expect(result.nights).toBe(3);
       expect(result.totalPrice).toBe(450); // 3 * 150
    });

    it("should throw error if check-out is before check-in", async () => {
       await expect(calculateBookingPrice("unit-1", checkOut, checkIn, "prop-1")).rejects.toThrow(
         new HttpsError("invalid-argument", "Check-out must be after check-in")
       );
    });
  });

  describe("validateBookingPrice", () => {
    it("should pass validation if client price matches server price exactly", async () => {
       // Mock daily prices calculation to return 300
       mockDb.get.mockResolvedValueOnce({ docs: [] });
       mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100 }) });

       await expect(validateBookingPrice("unit-1", checkIn, checkOut, 300, "prop-1")).resolves.not.toThrow();
    });

    it("should pass validation with services total included", async () => {
       // Server calculates 300 for nights. Client says 350 total (300 nights + 50 services).
       mockDb.get.mockResolvedValueOnce({ docs: [] });
       mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100 }) });

       await expect(validateBookingPrice("unit-1", checkIn, checkOut, 350, "prop-1", 50)).resolves.not.toThrow();
    });

    it("should throw error and log suspicious mismatch (> $10 or > 5%)", async () => {
       // Server calculates 300. Client says 100. Diff = 200 (Suspicious)
       mockDb.get.mockResolvedValueOnce({ docs: [] });
       mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100 }) });

       await expect(validateBookingPrice("unit-1", checkIn, checkOut, 100, "prop-1")).rejects.toThrow(
         new HttpsError("invalid-argument", "Price mismatch. Expected €300.00, received €100.00. Please refresh the page to see current pricing.")
       );

       expect(logPriceMismatch).toHaveBeenCalled();
    });

    it("should throw error but NOT log to Sentry for small benign mismatch", async () => {
       // Server calculates 300. Client says 295. Diff = 5 (Not suspicious)
       mockDb.get.mockResolvedValueOnce({ docs: [] });
       mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100 }) });

       await expect(validateBookingPrice("unit-1", checkIn, checkOut, 295, "prop-1")).rejects.toThrow(
         new HttpsError("invalid-argument", "Price mismatch. Expected €300.00, received €295.00. Please refresh the page to see current pricing.")
       );

       expect(logPriceMismatch).not.toHaveBeenCalled();
    });
  });
});
