/**
 * Tests for src/utils/bookingLookup.ts — findBookingById +
 * findBookingByReference. Exercises Strategy 1 (owner_id query),
 * Strategy 2 (parallel property-units search), Strategy 3 (legacy
 * top-level), plus the "FieldPath.documentId() bug" preventive
 * behavior (lookup matches by doc.id, not by FieldPath).
 */

interface FakeDoc {
  id: string;
  ref: {path: string};
  exists?: boolean;
  data: () => Record<string, unknown>;
}

const fixtures: {
  ownerGroupSnap: {docs: FakeDoc[]; empty: boolean};
  properties: FakeDoc[];
  unitsByProperty: Record<string, FakeDoc[]>;
  bookingsByPath: Record<string, FakeDoc>; // path → doc
  legacyDoc: FakeDoc | null;
  refSnap: {docs: FakeDoc[]; empty: boolean};
  legacySnap: {docs: FakeDoc[]; empty: boolean};
} = {
  ownerGroupSnap: {docs: [], empty: true},
  properties: [],
  unitsByProperty: {},
  bookingsByPath: {},
  legacyDoc: null,
  refSnap: {docs: [], empty: true},
  legacySnap: {docs: [], empty: true},
};

function doc(id: string, data: Record<string, unknown> = {}, path = `bookings/${id}`): FakeDoc {
  return {
    id,
    ref: {path},
    exists: true,
    data: () => data,
  };
}

jest.mock("firebase-admin", () => {
  const fb = jest.requireActual("firebase-admin");
  // Replace .firestore with a custom impl.
  const firestoreImpl = () => ({
    collectionGroup: (name: string) => ({
      where: function (_f: string, _op: string, _v: unknown) { return this; },
      limit: function () { return this; },
      get: async () => {
        if (name === "bookings") {
          // Distinguish owner_id query (returns ownerGroupSnap) from
          // booking_reference query (returns refSnap). The two never
          // run in the same test.
          if (fixtures.refSnap.docs.length > 0) return fixtures.refSnap;
          return fixtures.ownerGroupSnap;
        }
        return {docs: [], empty: true};
      },
    }),
    collection: (top: string) => {
      if (top === "properties") {
        return {
          doc: (propId: string) => ({
            collection: (sub: string) => {
              if (sub === "bookings") {
                // audit/93 F-93-02 — canonical property-level booking subcollection.
                return {
                  doc: (bookingId: string) => ({
                    get: async () => {
                      const key = `properties/${propId}/bookings/${bookingId}`;
                      const found = fixtures.bookingsByPath[key];
                      if (found) {
                        return {
                          exists: true,
                          data: () => found.data(),
                          ref: {path: key},
                        };
                      }
                      return {
                        exists: false,
                        data: () => undefined,
                        ref: {path: key},
                      };
                    },
                  }),
                };
              }
              if (sub === "units") {
                return {
                  get: async () => ({docs: fixtures.unitsByProperty[propId] || []}),
                  doc: (unitId: string) => ({
                    collection: (sub2: string) => {
                      if (sub2 === "bookings") {
                        return {
                          doc: (bookingId: string) => ({
                            get: async () => {
                              const key = `properties/${propId}/units/${unitId}/bookings/${bookingId}`;
                              const found = fixtures.bookingsByPath[key];
                              if (found) {
                                return {
                                  exists: true,
                                  data: () => found.data(),
                                  ref: {path: key},
                                };
                              }
                              return {
                                exists: false,
                                data: () => undefined,
                                ref: {path: key},
                              };
                            },
                          }),
                        };
                      }
                      throw new Error(`unexpected sub-subcollection ${sub2}`);
                    },
                  }),
                };
              }
              throw new Error(`unexpected subcollection ${sub}`);
            },
          }),
          get: async () => ({
            docs: fixtures.properties,
            empty: fixtures.properties.length === 0,
          }),
        };
      }
      if (top === "bookings") {
        return {
          doc: (id: string) => ({
            get: async () => {
              if (fixtures.legacyDoc && fixtures.legacyDoc.id === id) {
                return {
                  exists: true,
                  ref: fixtures.legacyDoc.ref,
                  data: () => fixtures.legacyDoc!.data(),
                };
              }
              return {
                exists: false,
                data: () => undefined,
                ref: {path: `bookings/${id}`},
              };
            },
          }),
          where: (_f: string, _op: string, _v: unknown) => ({
            limit: () => ({
              get: async () => fixtures.legacySnap,
            }),
          }),
        };
      }
      throw new Error(`unexpected collection ${top}`);
    },
  });
  return {
    ...fb,
    firestore: firestoreImpl,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
}));

import {findBookingById, findBookingByReference} from "../src/utils/bookingLookup";

function resetFixtures() {
  fixtures.ownerGroupSnap = {docs: [], empty: true};
  fixtures.properties = [];
  fixtures.unitsByProperty = {};
  fixtures.bookingsByPath = {};
  fixtures.legacyDoc = null;
  fixtures.refSnap = {docs: [], empty: true};
  fixtures.legacySnap = {docs: [], empty: true};
}

describe("findBookingById", () => {
  beforeEach(() => {
    resetFixtures();
    jest.clearAllMocks();
  });

  it("returns null when nothing matches across all strategies", async () => {
    const result = await findBookingById("nope-123", "owner-1");
    expect(result).toBeNull();
  });

  it("Strategy 1: owner_id query — finds booking when doc.id matches", async () => {
    fixtures.ownerGroupSnap = {
      docs: [
        doc("other-123", {property_id: "p", unit_id: "u"}),
        doc("target-456", {property_id: "p-x", unit_id: "u-y"}),
      ],
      empty: false,
    };
    const r = await findBookingById("target-456", "owner-1");
    expect(r).not.toBeNull();
    expect(r!.propertyId).toBe("p-x");
    expect(r!.unitId).toBe("u-y");
  });

  it("Strategy 1: owner_id query — ignores docs with non-matching id (FieldPath.documentId() guard)", async () => {
    fixtures.ownerGroupSnap = {
      docs: [doc("decoy-1", {}), doc("decoy-2", {})],
      empty: false,
    };
    // Strategy 2 + 3 also empty.
    const r = await findBookingById("not-among-decoys", "owner-1");
    expect(r).toBeNull();
  });

  it("Strategy 2: parallel search finds booking in properties/<p>/units/<u>/bookings/<id>", async () => {
    fixtures.properties = [doc("p-1", {})];
    fixtures.unitsByProperty["p-1"] = [doc("u-1", {})];
    fixtures.bookingsByPath["properties/p-1/units/u-1/bookings/lost-1"] = doc(
      "lost-1",
      {check_in: "2026-06-01", property_id: "p-1", unit_id: "u-1"}
    );
    const r = await findBookingById("lost-1");
    expect(r).not.toBeNull();
    expect(r!.propertyId).toBe("p-1");
    expect(r!.unitId).toBe("u-1");
  });

  it("Strategy 2: parallel search finds booking at canonical properties/<p>/bookings/<id> (audit/93 F-93-02)", async () => {
    fixtures.properties = [doc("p-2", {})];
    fixtures.unitsByProperty["p-2"] = [doc("u-2", {})];
    // Canonical path — what atomicBooking writes today.
    fixtures.bookingsByPath["properties/p-2/bookings/canon-1"] = doc(
      "canon-1",
      {check_in: "2026-09-01", property_id: "p-2", unit_id: "u-canon-from-doc"}
    );
    const r = await findBookingById("canon-1"); // no ownerId — guest cancel sim
    expect(r).not.toBeNull();
    expect(r!.propertyId).toBe("p-2");
    // unitId falls back to data.unit_id when path doesn't include it.
    expect(r!.unitId).toBe("u-canon-from-doc");
  });

  it("Strategy 3: legacy top-level collection fallback", async () => {
    fixtures.legacyDoc = doc(
      "legacy-9",
      {property_id: "legacy-p", unit_id: "legacy-u"},
      "bookings/legacy-9"
    );
    const r = await findBookingById("legacy-9");
    expect(r).not.toBeNull();
    expect(r!.propertyId).toBe("legacy-p");
    expect(r!.unitId).toBe("legacy-u");
  });

  it("logs warn when ownerId query yields no match (Strategy 1 miss)", async () => {
    const {logWarn} = require("../src/logger");
    await findBookingById("absent-1", "owner-1");
    const calls = logWarn.mock.calls.map((c: any[]) => c[0]).join("|");
    expect(calls).toMatch(/Booking not found/);
  });
});

describe("findBookingByReference", () => {
  beforeEach(() => {
    resetFixtures();
    jest.clearAllMocks();
  });

  it("returns null when not in either collection group nor legacy", async () => {
    const r = await findBookingByReference("BB-MISSING");
    expect(r).toBeNull();
  });

  it("returns hit from collection group query when present", async () => {
    fixtures.refSnap = {
      docs: [doc("bk-1", {property_id: "p-cg", unit_id: "u-cg"})],
      empty: false,
    };
    const r = await findBookingByReference("BB-CG-1");
    expect(r).not.toBeNull();
    expect(r!.propertyId).toBe("p-cg");
  });

  it("falls through to legacy collection when CG empty", async () => {
    fixtures.legacySnap = {
      docs: [doc("bk-leg-1", {property_id: "p-leg", unit_id: "u-leg"})],
      empty: false,
    };
    const r = await findBookingByReference("BB-LEG-1");
    expect(r).not.toBeNull();
    expect(r!.propertyId).toBe("p-leg");
    expect(r!.unitId).toBe("u-leg");
  });
});
