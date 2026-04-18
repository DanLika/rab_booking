// Mock dependencies
jest.mock("../../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
}));

jest.mock("../../src/utils/securityMonitoring", () => ({
  logPriceMismatch: jest.fn().mockResolvedValue(undefined),
}));

// Mock firebase-admin completely before any imports
const mockGet = jest.fn();
const mockWhere = jest.fn().mockReturnThis();
const mockCollection = jest.fn();
const mockDoc = jest.fn();

jest.mock("firebase-admin", () => {
  const mockFirestore = jest.fn(() => ({
    collection: mockCollection,
  }));

  // Attach Timestamp to the mock to avoid TDZ
  (mockFirestore as any).Timestamp = {
    fromDate: jest.fn((date) => ({
      toDate: () => date,
      toMillis: () => date.getTime(),
    })),
  };

  return {
    apps: {length: 1}, // Prevent initialization errors
    initializeApp: jest.fn(),
    firestore: mockFirestore,
  };
});

import {HttpsError} from "firebase-functions/v2/https";
import {validateBookingPrice, calculateBookingPrice} from "../../src/utils/priceValidation";
import {logPriceMismatch} from "../../src/utils/securityMonitoring";

describe("Price Validation Utils", () => {
  const createMockTimestamp = (dateStr: string) => {
    const date = new Date(dateStr);
    return {
      toDate: () => date,
      toMillis: () => date.getTime(),
    } as any;
  };

  beforeEach(() => {
    jest.clearAllMocks();

    const collectionResponse = {
      doc: mockDoc,
    };

    const docResponse = {
      get: mockGet,
      collection: mockCollection,
    };

    mockCollection.mockReturnValue(collectionResponse);
    mockDoc.mockReturnValue(docResponse);

    // For queries
    mockCollection.mockReturnValue({
      doc: jest.fn().mockReturnValue({
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: mockGet,
            collection: jest.fn().mockReturnValue({
              where: mockWhere,
            }),
          }),
        }),
      }),
    });

    // More complex mock chain for daily_prices
    mockWhere.mockReturnValue({
      where: jest.fn().mockReturnValue({
        orderBy: jest.fn().mockReturnValue({
          get: mockGet,
        }),
      }),
    });
  });

  describe("calculateBookingPrice", () => {
    it("should calculate price using daily prices", async () => {
      // Mock daily prices response
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-04T00:00:00Z"); // 3 nights

      mockGet.mockResolvedValueOnce({
        empty: false,
        docs: [
          {id: "2024-05-01", data: () => ({price: 110, date: createMockTimestamp("2024-05-01T00:00:00Z")})},
          {id: "2024-05-02", data: () => ({price: 120, date: createMockTimestamp("2024-05-02T00:00:00Z")})},
          {id: "2024-05-03", data: () => ({price: 130, date: createMockTimestamp("2024-05-03T00:00:00Z")})},
        ],
      });

      const result = await calculateBookingPrice("unit1", checkIn, checkOut, "prop1");

      expect(result.nights).toBe(3);
      expect(result.totalPrice).toBe(360); // 110 + 120 + 130
      expect(result.breakdown.length).toBe(3);
    });

    it("should fallback to unit base price if daily prices are missing", async () => {
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-03T00:00:00Z"); // 2 nights

      // Empty daily prices
      mockGet.mockResolvedValueOnce({empty: true, docs: []});

      // Unit fallback
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({base_price: 150}),
      });

      const result = await calculateBookingPrice("unit1", checkIn, checkOut, "prop1");

      expect(result.nights).toBe(2);
      expect(result.totalPrice).toBe(300); // 150 * 2
    });

    it("should use weekend prices if defined in daily_prices", async () => {
      // May 3 2024 is Friday (weekend), May 4 is Saturday (weekend)
      const checkIn = createMockTimestamp("2024-05-03T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-05T00:00:00Z"); // 2 nights

      mockGet.mockResolvedValueOnce({
        empty: false,
        docs: [
          {id: "2024-05-03", data: () => ({price: 100, weekend_price: 150, date: createMockTimestamp("2024-05-03T00:00:00Z")})},
          {id: "2024-05-04", data: () => ({price: 100, weekend_price: 160, date: createMockTimestamp("2024-05-04T00:00:00Z")})},
        ],
      });

      const result = await calculateBookingPrice("unit1", checkIn, checkOut, "prop1");

      expect(result.nights).toBe(2);
      expect(result.totalPrice).toBe(310); // 150 + 160
    });
  });

  describe("validateBookingPrice", () => {
    it("should pass validation if client price matches server price exactly", async () => {
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-03T00:00:00Z");

      // Server calculates 300
      mockGet.mockResolvedValueOnce({empty: true, docs: []});
      mockGet.mockResolvedValueOnce({exists: true, data: () => ({base_price: 150})});

      // Client price = 300 + 50 (services) = 350
      await expect(validateBookingPrice("unit1", checkIn, checkOut, 350, "prop1", 50)).resolves.not.toThrow();
    });

    it("should pass validation with tiny tolerance mismatch (< 0.01)", async () => {
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-03T00:00:00Z");

      mockGet.mockResolvedValueOnce({empty: true, docs: []});
      mockGet.mockResolvedValueOnce({exists: true, data: () => ({base_price: 150})});

      await expect(validateBookingPrice("unit1", checkIn, checkOut, 300.009, "prop1", 0)).resolves.not.toThrow();
    });

    it("should throw error and NOT trigger Sentry for small difference (<$10 and <5%)", async () => {
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-03T00:00:00Z");

      // Server = 300
      mockGet.mockResolvedValueOnce({empty: true, docs: []});
      mockGet.mockResolvedValueOnce({exists: true, data: () => ({base_price: 150})});

      // Client = 295 (Diff 5 is < 10 AND < 5% of 300)
      const prom = validateBookingPrice("unit1", checkIn, checkOut, 295, "prop1", 0);

      await expect(prom).rejects.toThrow(HttpsError);
      expect(logPriceMismatch).not.toHaveBeenCalled();
    });

    it("should throw error and trigger Sentry for large absolute difference (>$10)", async () => {
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-03T00:00:00Z");

      // Server = 300
      mockGet.mockResolvedValueOnce({empty: true, docs: []});
      mockGet.mockResolvedValueOnce({exists: true, data: () => ({base_price: 150})});

      // Client = 285 (Diff 15 is > 10)
      const prom = validateBookingPrice("unit1", checkIn, checkOut, 285, "prop1", 0);

      await expect(prom).rejects.toThrow(HttpsError);
      expect(logPriceMismatch).toHaveBeenCalled();
    });

    it("should throw error and trigger Sentry for large percentage difference (>5%)", async () => {
      const checkIn = createMockTimestamp("2024-05-01T00:00:00Z");
      const checkOut = createMockTimestamp("2024-05-03T00:00:00Z");

      // Server = 100
      mockGet.mockResolvedValueOnce({empty: true, docs: []});
      mockGet.mockResolvedValueOnce({exists: true, data: () => ({base_price: 50})});

      // Client = 94 (Diff 6 is < 10, BUT 6/100 = 6% > 5%)
      const prom = validateBookingPrice("unit1", checkIn, checkOut, 94, "prop1", 0);

      await expect(prom).rejects.toThrow(HttpsError);
      expect(logPriceMismatch).toHaveBeenCalled();
    });
  });
});
