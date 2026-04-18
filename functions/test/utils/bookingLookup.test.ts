import * as admin from "firebase-admin";
import {findBookingById, findBookingByReference} from "../../src/utils/bookingLookup";

// Mock firebase-admin
jest.mock("firebase-admin", () => {
  const mockWhere = jest.fn();
  const mockLimit = jest.fn();
  const mockCollectionGroup = jest.fn();
  const mockCollection = jest.fn();

  // Create chainable mock methods
  mockWhere.mockReturnThis();
  mockLimit.mockReturnThis();

  return {
    firestore: jest.fn(() => ({
      collectionGroup: mockCollectionGroup,
      collection: mockCollection,
    })),
  };
});

describe("Booking Lookup Utils", () => {
  const db = admin.firestore();

  beforeEach(() => {
    jest.clearAllMocks();

    // Set up default chain behavior for db.collectionGroup
    (db.collectionGroup as jest.Mock).mockReturnValue({
      where: jest.fn().mockReturnValue({
        limit: jest.fn().mockReturnValue({
          get: jest.fn(),
        }),
        get: jest.fn(),
      }),
    });

    // Set up default chain behavior for db.collection
    (db.collection as jest.Mock).mockReturnValue({
      doc: jest.fn().mockReturnValue({
        get: jest.fn(),
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn(),
            collection: jest.fn().mockReturnValue({
              doc: jest.fn().mockReturnValue({
                get: jest.fn(),
              }),
            }),
          }),
          get: jest.fn(),
        }),
      }),
      get: jest.fn(),
      where: jest.fn().mockReturnValue({
        limit: jest.fn().mockReturnValue({
          get: jest.fn(),
        }),
      }),
    });
  });

  describe("findBookingById", () => {
    it("should find booking by owner_id (Strategy 1)", async () => {
      const mockDoc = {
        id: "booking123",
        exists: true,
        data: () => ({property_id: "prop1", unit_id: "unit1", owner_id: "owner1"}),
        ref: {path: "some/path"},
      };

      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          get: jest.fn().mockResolvedValueOnce({docs: [mockDoc]}),
        }),
      });

      const result = await findBookingById("booking123", "owner1");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop1");
      expect(result?.unitId).toBe("unit1");
      expect(db.collectionGroup).toHaveBeenCalledWith("bookings");
    });

    it("should find booking by parallel property search (Strategy 2)", async () => {
      // Mock failure for Strategy 1
      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          get: jest.fn().mockResolvedValueOnce({docs: []}),
        }),
      });

      // Mock properties snapshot
      const mockPropertiesSnapshot = {
        empty: false,
        docs: [
          {id: "prop1"},
        ],
      };

      const mockUnitsSnapshot = {
        docs: [
          {id: "unit1"},
        ],
      };

      const mockBookingDoc = {
        exists: true,
        data: () => ({property_id: "prop1", unit_id: "unit1"}),
        ref: {path: "props/prop1/units/unit1/bookings/booking123"},
      };

      // Set up complex mock chain for db.collection().get()
      const collectionMock = db.collection as jest.Mock;

      collectionMock.mockImplementation((path) => {
        if (path === "properties") {
          return {
            get: jest.fn().mockResolvedValueOnce(mockPropertiesSnapshot),
            doc: jest.fn((docId) => ({
              collection: jest.fn((subcol) => ({
                get: jest.fn().mockResolvedValueOnce(mockUnitsSnapshot),
                doc: jest.fn((subdocId) => ({
                  collection: jest.fn((subsubcol) => ({
                    doc: jest.fn((bookingId) => ({
                      get: jest.fn().mockResolvedValueOnce(mockBookingDoc),
                    })),
                  })),
                })),
              })),
            })),
          };
        }
        return {get: jest.fn()};
      });

      const result = await findBookingById("booking123", "owner1");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop1");
      expect(result?.unitId).toBe("unit1");
    });

    it("should find booking in legacy collection (Strategy 3)", async () => {
      // Strategy 1 fail
      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          get: jest.fn().mockResolvedValueOnce({docs: []}),
        }),
      });

      // Strategy 2 fail (no properties)
      const mockPropertiesSnapshot = {
        empty: true,
        docs: [],
      };

      const mockLegacyBookingDoc = {
        exists: true,
        data: () => ({property_id: "propL", unit_id: "unitL"}),
        ref: {path: "bookings/booking123"},
      };

      const collectionMock = db.collection as jest.Mock;
      collectionMock.mockImplementation((path) => {
        if (path === "properties") {
          return {get: jest.fn().mockResolvedValueOnce(mockPropertiesSnapshot)};
        }
        if (path === "bookings") {
          return {
            doc: jest.fn().mockReturnValueOnce({
              get: jest.fn().mockResolvedValueOnce(mockLegacyBookingDoc),
            }),
          };
        }
        return {get: jest.fn()};
      });

      const result = await findBookingById("booking123", "owner1");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("propL");
    });

    it("should return null if booking not found anywhere", async () => {
      // Strategy 1 fail
      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          get: jest.fn().mockResolvedValueOnce({docs: []}),
        }),
      });

      // Strategy 2 fail
      const collectionMock = db.collection as jest.Mock;
      collectionMock.mockImplementation((path) => {
        if (path === "properties") {
          return {get: jest.fn().mockResolvedValueOnce({empty: true, docs: []})};
        }
        if (path === "bookings") {
          return {
            doc: jest.fn().mockReturnValueOnce({
              get: jest.fn().mockResolvedValueOnce({exists: false}),
            }),
          };
        }
        return {get: jest.fn()};
      });

      const result = await findBookingById("booking123", "owner1");

      expect(result).toBeNull();
    });
  });

  describe("findBookingByReference", () => {
    it("should find booking by reference in collectionGroup", async () => {
      const mockDoc = {
        exists: true,
        data: () => ({property_id: "prop1", unit_id: "unit1"}),
        ref: {path: "some/path"},
      };

      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          limit: jest.fn().mockReturnValueOnce({
            get: jest.fn().mockResolvedValueOnce({empty: false, docs: [mockDoc]}),
          }),
        }),
      });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop1");
    });

    it("should fallback to legacy collection if not found in collectionGroup", async () => {
      // collectionGroup fail
      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          limit: jest.fn().mockReturnValueOnce({
            get: jest.fn().mockResolvedValueOnce({empty: true}),
          }),
        }),
      });

      const mockDoc = {
        exists: true,
        data: () => ({property_id: "prop2", unit_id: "unit2"}),
        ref: {path: "legacy/path"},
      };

      const collectionMock = db.collection as jest.Mock;
      collectionMock.mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          limit: jest.fn().mockReturnValueOnce({
            get: jest.fn().mockResolvedValueOnce({empty: false, docs: [mockDoc]}),
          }),
        }),
      });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeDefined();
      expect(result?.propertyId).toBe("prop2");
    });

    it("should return null if not found anywhere", async () => {
      (db.collectionGroup as jest.Mock).mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          limit: jest.fn().mockReturnValueOnce({
            get: jest.fn().mockResolvedValueOnce({empty: true}),
          }),
        }),
      });

      const collectionMock = db.collection as jest.Mock;
      collectionMock.mockReturnValueOnce({
        where: jest.fn().mockReturnValueOnce({
          limit: jest.fn().mockReturnValueOnce({
            get: jest.fn().mockResolvedValueOnce({empty: true}),
          }),
        }),
      });

      const result = await findBookingByReference("REF-123");

      expect(result).toBeNull();
    });
  });
});
