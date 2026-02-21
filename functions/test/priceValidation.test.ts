// Mock dependencies
const mockFirestoreInstance = {
  collection: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnThis(),
  where: jest.fn().mockReturnThis(),
  orderBy: jest.fn().mockReturnThis(),
  get: jest.fn(),
};

jest.mock("../src/firebase", () => {
  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("MOCK_TIMESTAMP"),
    },
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
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logPriceMismatch: jest.fn().mockResolvedValue(true),
}));

import { calculateBookingPrice, validateBookingPrice } from "../src/utils/priceValidation";
import { logPriceMismatch } from "../src/utils/securityMonitoring";
import { admin, db } from "../src/firebase";

describe("Price Validation", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.orderBy.mockReturnThis();
  });

  const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01")); // Monday
  const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-05")); // Friday (4 nights)

  describe("calculateBookingPrice", () => {
    it("should calculate price from daily_prices", async () => {
      // Mock daily prices query result
      mockDb.get.mockResolvedValueOnce({
        docs: [
          { data: () => ({ date: { toDate: () => new Date("2026-06-01") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-02") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-03") }, price: 120 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-04") }, price: 120 }) },
        ],
      });

      const result = await calculateBookingPrice("u1", checkIn, checkOut, "p1");

      expect(result.totalPrice).toBe(440); // 100+100+120+120
      expect(result.nights).toBe(4);
    });

    it("should use fallback price if daily_prices missing", async () => {
      // Mock empty daily prices
      mockDb.get.mockResolvedValueOnce({ docs: [] });

      // Mock unit fetch for fallback
      mockDb.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({ base_price: 150 }),
      });

      const result = await calculateBookingPrice("u1", checkIn, checkOut, "p1");

      expect(result.totalPrice).toBe(600); // 150 * 4
    });
  });

  describe("validateBookingPrice", () => {
    it("should succeed if price matches", async () => {
      // Mock daily prices
      mockDb.get.mockResolvedValueOnce({
        docs: [
          { data: () => ({ date: { toDate: () => new Date("2026-06-01") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-02") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-03") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-04") }, price: 100 }) },
        ],
      });

      await expect(
        validateBookingPrice("u1", checkIn, checkOut, 400, "p1")
      ).resolves.not.toThrow();
    });

    it("should throw error if price mismatch detected", async () => {
      // Mock daily prices (total 400)
      mockDb.get.mockResolvedValueOnce({
        docs: [
          { data: () => ({ date: { toDate: () => new Date("2026-06-01") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-02") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-03") }, price: 100 }) },
          { data: () => ({ date: { toDate: () => new Date("2026-06-04") }, price: 100 }) },
        ],
      });

      // Client sends 100 (way too low)
      await expect(
        validateBookingPrice("u1", checkIn, checkOut, 100, "p1")
      ).rejects.toThrow("Price mismatch");
    });

    it("should alert Sentry if mismatch is suspicious (> €10 or > 5%)", async () => {
      // Server: 400. Client: 300. Diff: 100. %: 25%. Suspicious!
      mockDb.get.mockResolvedValueOnce({
        docs: Array(4).fill(null).map((_, i) => ({
          data: () => ({ date: { toDate: () => new Date(`2026-06-0${i+1}`) }, price: 100 })
        }))
      });

      try {
        await validateBookingPrice("u1", checkIn, checkOut, 300, "p1");
      } catch (e) {
        // Expected
      }

      expect(logPriceMismatch).toHaveBeenCalled();
    });

    it("should NOT alert Sentry for small mismatches (< €10 and < 5%)", async () => {
      // Server: 400. Client: 395. Diff: 5. %: 1.25%. Not suspicious.
      mockDb.get.mockResolvedValueOnce({
        docs: Array(4).fill(null).map((_, i) => ({
          data: () => ({ date: { toDate: () => new Date(`2026-06-0${i+1}`) }, price: 100 })
        }))
      });

      try {
        await validateBookingPrice("u1", checkIn, checkOut, 395, "p1");
      } catch (e) {
        // Expected
      }

      expect(logPriceMismatch).not.toHaveBeenCalled();
    });
  });
});
