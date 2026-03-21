import * as admin from "firebase-admin";

// Mock external dependencies
jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logPriceMismatch: jest.fn().mockResolvedValue(undefined),
}));

// Mock firebase-admin completely before any imports
jest.mock("firebase-admin", () => {
  const mockGet = jest.fn();
  const mockWhere = jest.fn().mockReturnThis();
  const mockOrderBy = jest.fn().mockReturnThis();

  const mockDoc = jest.fn(() => ({
    get: mockGet,
    collection: mockCollection,
    path: "mock/path",
  }));

  const mockCollection = jest.fn(() => ({
    doc: mockDoc,
    where: mockWhere,
    orderBy: mockOrderBy,
    get: mockGet,
  })) as any;

  const mockFirestore = jest.fn(() => ({
    collection: mockCollection,
  })) as any;

  mockFirestore.Timestamp = {
    fromDate: (d: Date) => ({
      toDate: () => d,
      toMillis: () => d.getTime(),
    }),
  };

  return {
    firestore: mockFirestore,
  };
});

jest.mock("../src/firebase", () => {
  const admin = require("firebase-admin");
  return {
    admin,
    db: admin.firestore(),
  };
});

import { calculateBookingPrice, validateBookingPrice } from "../src/utils/priceValidation";
import { HttpsError } from "firebase-functions/v2/https";
import { logPriceMismatch } from "../src/utils/securityMonitoring";

describe("priceValidation", () => {
  let db: any;
  let mockGet: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    db = require("../src/firebase").db;
    // We need to drill down to the mockGet function for the queries
    mockGet = db.collection().doc().collection().doc().collection().get as jest.Mock;

    // Also need mockGet for the fallback unit lookup
    db.collection().doc().collection().doc().get = jest.fn();
  });

  const createTimestamp = (dateStr: string) => {
    const d = new Date(dateStr);
    return {
      toDate: () => d,
      toMillis: () => d.getTime(),
    } as admin.firestore.Timestamp;
  };

  describe("calculateBookingPrice", () => {
    const checkIn = createTimestamp("2023-10-01T00:00:00Z"); // Sunday
    const checkOut = createTimestamp("2023-10-04T00:00:00Z"); // Wednesday (3 nights)
    const propertyId = "prop-1";
    const unitId = "unit-1";

    it("should calculate total price using daily_prices correctly", async () => {
      // Mock daily prices query
      mockGet.mockResolvedValueOnce({
        docs: [
          { data: () => ({ date: createTimestamp("2023-10-01T00:00:00Z"), price: 100 }) }, // Sun
          { data: () => ({ date: createTimestamp("2023-10-02T00:00:00Z"), price: 110 }) }, // Mon
          { data: () => ({ date: createTimestamp("2023-10-03T00:00:00Z"), price: 120 }) }, // Tue
        ],
        size: 3,
      });

      const result = await calculateBookingPrice(unitId, checkIn, checkOut, propertyId);

      expect(result.nights).toBe(3);
      expect(result.totalPrice).toBe(330); // 100 + 110 + 120
      expect(result.breakdown.length).toBe(3);
    });

    it("should fallback to unit base price if daily_prices are missing", async () => {
      // No daily prices found
      mockGet.mockResolvedValueOnce({ docs: [], size: 0 });

      // Mock unit document for fallback
      const mockUnitGet = db.collection().doc().collection().doc().get;
      mockUnitGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({ base_price: 150 }), // Flutter style
      });

      const result = await calculateBookingPrice(unitId, checkIn, checkOut, propertyId);

      expect(result.nights).toBe(3);
      expect(result.totalPrice).toBe(450); // 150 * 3
      expect(mockUnitGet).toHaveBeenCalled();
    });

    it("should handle weekend pricing in fallback correctly", async () => {
      const weekendCheckIn = createTimestamp("2023-10-06T00:00:00Z"); // Friday
      const weekendCheckOut = createTimestamp("2023-10-09T00:00:00Z"); // Monday (3 nights: Fri, Sat, Sun)

      // No daily prices
      mockGet.mockResolvedValueOnce({ docs: [], size: 0 });

      // Mock unit doc with weekend prices
      const mockUnitGet = db.collection().doc().collection().doc().get;
      mockUnitGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          base_price: 100,
          weekend_base_price: 150,
          weekend_days: [6, 7] // Sat, Sun (Mon=1 format)
        }),
      });

      const result = await calculateBookingPrice(unitId, weekendCheckIn, weekendCheckOut, propertyId);

      // Fri (100) + Sat (150) + Sun (150) = 400
      expect(result.totalPrice).toBe(400);
    });

    it("should throw error if check-out is before check-in", async () => {
      await expect(calculateBookingPrice(unitId, checkOut, checkIn, propertyId)).rejects.toThrow(
        new HttpsError("invalid-argument", "Check-out must be after check-in")
      );
    });
  });

  describe("validateBookingPrice", () => {
    const checkIn = createTimestamp("2023-10-01T00:00:00Z");
    const checkOut = createTimestamp("2023-10-03T00:00:00Z"); // 2 nights
    const propertyId = "prop-1";
    const unitId = "unit-1";

    beforeEach(() => {
      // Setup a standard valid daily_price mock for 2 nights @ 100 = 200 total
      mockGet.mockResolvedValue({
        docs: [
          { data: () => ({ date: createTimestamp("2023-10-01T00:00:00Z"), price: 100 }) },
          { data: () => ({ date: createTimestamp("2023-10-02T00:00:00Z"), price: 100 }) },
        ],
        size: 2,
      });
    });

    it("should validate successfully when prices match exactly", async () => {
      const clientPrice = 200;
      await expect(validateBookingPrice(unitId, checkIn, checkOut, clientPrice, propertyId)).resolves.toBeUndefined();
    });

    it("should validate successfully with additional services", async () => {
      const clientPrice = 250; // 200 nightly + 50 services
      const servicesTotal = 50;
      await expect(validateBookingPrice(unitId, checkIn, checkOut, clientPrice, propertyId, servicesTotal)).resolves.toBeUndefined();
    });

    it("should throw if client price is invalid", async () => {
      await expect(validateBookingPrice(unitId, checkIn, checkOut, -50, propertyId)).rejects.toThrow(
        /Invalid total price provided/
      );
    });

    it("should throw on price mismatch and NOT trigger alert if under threshold", async () => {
      const clientPrice = 205; // 200 expected, difference is 5 (< 10 EUR and < 5%)

      await expect(validateBookingPrice(unitId, checkIn, checkOut, clientPrice, propertyId)).rejects.toThrow(
        /Price mismatch/
      );

      // Should NOT log security mismatch for small differences
      expect(logPriceMismatch).not.toHaveBeenCalled();
    });

    it("should throw on price mismatch and trigger alert if over 10 EUR threshold", async () => {
      const clientPrice = 180; // 200 expected, difference is 20 (> 10 EUR)

      await expect(validateBookingPrice(unitId, checkIn, checkOut, clientPrice, propertyId)).rejects.toThrow(
        /Price mismatch/
      );

      // Should log security mismatch
      expect(logPriceMismatch).toHaveBeenCalledWith(
        unitId,
        clientPrice,
        200, // expected
        expect.any(Object)
      );
    });

    it("should throw on price mismatch and trigger alert if over 5% threshold", async () => {
      // Let's mock a smaller booking where 5% is less than 10 EUR
      mockGet.mockResolvedValueOnce({
        docs: [
          { data: () => ({ date: createTimestamp("2023-10-01T00:00:00Z"), price: 50 }) },
        ],
        size: 1,
      });
      // 1 night check-out
      const smallCheckOut = createTimestamp("2023-10-02T00:00:00Z");

      const clientPrice = 45; // diff is 5 EUR, which is 10% of 50

      await expect(validateBookingPrice(unitId, checkIn, smallCheckOut, clientPrice, propertyId)).rejects.toThrow(
        /Price mismatch/
      );

      // Should log security mismatch (percentage > 5%)
      expect(logPriceMismatch).toHaveBeenCalled();
    });
  });
});
