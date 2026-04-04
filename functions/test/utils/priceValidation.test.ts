import * as admin from "firebase-admin";

const mockFirestoreInstance = {
  collection: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnThis(),
  where: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  orderBy: jest.fn().mockReturnThis(),
  get: jest.fn(),
};

const mockFirestoreFn = jest.fn(() => mockFirestoreInstance);
Object.assign(mockFirestoreFn, {
  FieldValue: { serverTimestamp: jest.fn(), increment: jest.fn() }
});

jest.mock("firebase-admin", () => {
  return {
    initializeApp: jest.fn(),
    apps: [{ length: 1 }],
    firestore: mockFirestoreFn,
  };
});

jest.mock("../../src/firebase", () => {
  const fAdmin = require("firebase-admin");
  return {
    admin: fAdmin,
    db: fAdmin.firestore(),
  };
});

jest.mock("../../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../../src/utils/securityMonitoring", () => ({
  logPriceMismatch: jest.fn().mockResolvedValue(true),
}));

import { calculateBookingPrice, validateBookingPrice } from "../../src/utils/priceValidation";
import { logPriceMismatch } from "../../src/utils/securityMonitoring";

describe("priceValidation", () => {
  const mockDb = mockFirestoreInstance as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
    mockDb.orderBy.mockReturnThis();
  });

  const checkIn = {
    toDate: () => new Date("2026-06-01T00:00:00Z"),
    toMillis: () => new Date("2026-06-01T00:00:00Z").getTime(),
  } as admin.firestore.Timestamp;
  const checkOut = {
    toDate: () => new Date("2026-06-03T00:00:00Z"),
    toMillis: () => new Date("2026-06-03T00:00:00Z").getTime(),
  } as admin.firestore.Timestamp; // 2 nights

  describe("calculateBookingPrice", () => {
    it("should calculate price using fallback if no daily prices exist", async () => {
      // 1. Daily prices query (empty)
      mockDb.get.mockResolvedValueOnce({ empty: true, docs: [] });
      // 2. Unit doc query (has base_price)
      mockDb.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({ base_price: 150.0 }),
      });

      const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

      expect(result.nights).toBe(2);
      expect(result.totalPrice).toBe(300.0);
    });

    it("should calculate price using daily prices", async () => {
      const mockDailyDoc1 = {
        id: "2026-06-01",
        data: () => ({
          price: 200.0,
          date: { toDate: () => new Date("2026-06-01T00:00:00Z") }
        }),
      };
      const mockDailyDoc2 = {
        id: "2026-06-02",
        data: () => ({
          price: 250.0,
          date: { toDate: () => new Date("2026-06-02T00:00:00Z") }
        }),
      };

      // 1. Daily prices query
      mockDb.get.mockResolvedValueOnce({
        empty: false,
        docs: [mockDailyDoc1, mockDailyDoc2],
      });

      const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

      expect(result.nights).toBe(2);
      expect(result.totalPrice).toBe(450.0);
    });
  });

  describe("validateBookingPrice", () => {
    it("should pass validation if prices match exactly", async () => {
      // Mock calculateBookingPrice internally via DB calls
      mockDb.get.mockResolvedValueOnce({ empty: true, docs: [] }); // Daily prices
      mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100.0 }) }); // Unit

      // Server price will be 200. Client price is 200.
      await expect(validateBookingPrice("unit-1", checkIn, checkOut, 200.0, "prop-1")).resolves.not.toThrow();
    });

    it("should allow small mismatch without triggering Sentry", async () => {
      mockDb.get.mockResolvedValueOnce({ empty: true, docs: [] });
      mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100.0 }) });

      // Server price is 200. Client price is 200.01 (within 0.01 tolerance maybe, or small mismatch logged but throws)
      // Actually, any difference > 0.01 throws. Let's provide 202.0 which is a difference of 2.0 (< 10, < 5%)
      // It should throw but NOT call logPriceMismatch
      try {
        await validateBookingPrice("unit-1", checkIn, checkOut, 202.0, "prop-1");
        fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).toContain("Price mismatch");
      }
      expect(logPriceMismatch).not.toHaveBeenCalled();
    });

    it("should trigger Sentry alert if mismatch > $10", async () => {
      mockDb.get.mockResolvedValueOnce({ empty: true, docs: [] });
      mockDb.get.mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100.0 }) });

      // Server price is 200. Client price is 150 (diff 50 > 10)
      try {
        await validateBookingPrice("unit-1", checkIn, checkOut, 150.0, "prop-1");
        fail("Should have thrown");
      } catch (e: any) {
        expect(e.message).toContain("Price mismatch");
      }
      expect(logPriceMismatch).toHaveBeenCalled();
    });
  });
});
