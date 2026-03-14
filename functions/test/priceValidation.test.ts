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
    Transaction: jest.fn(),
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

import { calculateBookingPrice, validateBookingPrice } from "../src/utils/priceValidation";
import { admin, db } from "../src/firebase";
import * as securityMonitoring from "../src/utils/securityMonitoring";

describe("priceValidation", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.orderBy.mockReturnThis();
  });

  describe("calculateBookingPrice", () => {
    it("should throw error if check-out is before check-in", async () => {
      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-05T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));

      await expect(calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1")).rejects.toThrow("Check-out must be after check-in");
    });

    it("should calculate correctly using only fallback base_price when no daily_prices exist", async () => {
      // Mock daily_prices query to return empty
      mockDb.get.mockResolvedValueOnce({ docs: [] });

      // Mock unit fallback fetch
      mockDb.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({ base_price: 100 }), // Using new property name "base_price"
      });

      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-04T00:00:00Z")); // 3 nights

      const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

      expect(result.nights).toBe(3);
      expect(result.totalPrice).toBe(300); // 3 * 100
      expect(result.breakdown).toHaveLength(3);
    });

    it("should calculate correctly using weekend_base_price fallback", async () => {
        // Mock daily_prices query to return empty
        mockDb.get.mockResolvedValueOnce({ docs: [] });

        // Mock unit fallback fetch
        mockDb.get.mockResolvedValueOnce({
          exists: true,
          data: () => ({ base_price: 100, weekend_base_price: 120, weekend_days: [5, 6] }), // Friday, Saturday in JS
        });

        // 2026-06-05 is Friday, 2026-06-06 is Saturday
        const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-04T00:00:00Z")); // Thursday
        const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-07T00:00:00Z")); // Sunday

        const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

        expect(result.nights).toBe(3);
        // Thursday (100) + Friday (120) + Saturday (120) = 340
        expect(result.totalPrice).toBe(340);
        expect(result.breakdown).toHaveLength(3);
    });

    it("should calculate correctly using daily_prices", async () => {
      // Mock daily_prices query
      mockDb.get.mockResolvedValueOnce({
        docs: [
          {
            data: () => ({
              date: admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z")),
              price: 150,
            }),
          },
          {
            data: () => ({
              date: admin.firestore.Timestamp.fromDate(new Date("2026-06-02T00:00:00Z")),
              price: 160,
            }),
          },
        ],
      });

      // Unit document should not be fetched if daily prices cover all nights
      // Wait actually, checking length inside so let's mock the unit fetch just in case it attempts
      mockDb.get.mockResolvedValueOnce({ exists: false });

      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-03T00:00:00Z")); // 2 nights

      const result = await calculateBookingPrice("unit-1", checkIn, checkOut, "prop-1");

      expect(result.nights).toBe(2);
      expect(result.totalPrice).toBe(310); // 150 + 160
    });
  });

  describe("validateBookingPrice", () => {
    it("should fail if client price is invalid", async () => {
      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-02T00:00:00Z"));
      await expect(validateBookingPrice("unit-1", checkIn, checkOut, -100, "prop-1")).rejects.toThrow("Invalid total price provided");
    });

    it("should pass if client price matches server price exactly", async () => {
      // Server price will be 1 night * 100 = 100
      mockDb.get.mockReset();
      mockDb.get
        .mockResolvedValueOnce({ docs: [] }) // No daily prices
        .mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100, weekend_days: [5, 6] }) }); // Fallback

      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-02T00:00:00Z"));

      await expect(validateBookingPrice("unit-1", checkIn, checkOut, 100, "prop-1")).resolves.not.toThrow();
    });

    it("should pass if client price has services added correctly", async () => {
        // Server price 100, services 50. Total expected: 150.
        mockDb.get.mockReset();
        mockDb.get
          .mockResolvedValueOnce({ docs: [] })
          .mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100, weekend_days: [5, 6] }) });

        const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
        const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-02T00:00:00Z"));

        await expect(validateBookingPrice("unit-1", checkIn, checkOut, 150, "prop-1", 50)).resolves.not.toThrow();
    });

    it("should fail but NOT report to sentry for small mismatch (e.g., cached price off by < 10 AND < 5%)", async () => {
      // Server expects 200, client gives 205. Diff = 5 (<= 10) AND Diff% = 2.5% (<= 5%).
      // This is a small mismatch.
      mockDb.get.mockReset();
      mockDb.get
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100, weekend_days: [5, 6] }) }); // 2 nights = 200

      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-03T00:00:00Z")); // 2 nights

      await expect(validateBookingPrice("unit-1", checkIn, checkOut, 205, "prop-1")).rejects.toThrow("Price mismatch.");
      expect(securityMonitoring.logPriceMismatch).not.toHaveBeenCalled();
    });

    it("should fail AND report to sentry for suspicious mismatch (> 10 EUR)", async () => {
      // Server expects 200, client gives 150. Diff = 50 (> 10). Suspicious!
      mockDb.get.mockReset();
      mockDb.get
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 100, weekend_days: [5, 6] }) });

      const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
      const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-03T00:00:00Z"));

      await expect(validateBookingPrice("unit-1", checkIn, checkOut, 150, "prop-1")).rejects.toThrow("Price mismatch.");
      expect(securityMonitoring.logPriceMismatch).toHaveBeenCalled();
    });

    it("should fail AND report to sentry for suspicious mismatch (> 5%)", async () => {
        // Server expects 50, client gives 40. Diff = 10 (<= 10), but Diff% = 10 / 50 = 20% (> 5%).
        mockDb.get.mockReset();
        mockDb.get
          .mockResolvedValueOnce({ docs: [] })
          .mockResolvedValueOnce({ exists: true, data: () => ({ base_price: 50, weekend_days: [5, 6] }) });

        const checkIn = admin.firestore.Timestamp.fromDate(new Date("2026-06-01T00:00:00Z"));
        const checkOut = admin.firestore.Timestamp.fromDate(new Date("2026-06-02T00:00:00Z"));

        await expect(validateBookingPrice("unit-1", checkIn, checkOut, 40, "prop-1")).rejects.toThrow("Price mismatch.");
        expect(securityMonitoring.logPriceMismatch).toHaveBeenCalled();
    });
  });
});
