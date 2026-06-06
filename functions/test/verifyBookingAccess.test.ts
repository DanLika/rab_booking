/**
 * Tests for src/verifyBookingAccess.ts hardening (Sentry FLUTTER-7P).
 *
 * Verifies:
 *  - Missing property_id → returns {success:false, reason:"invalid_credentials"}
 *    and logWarn fires with bookingReference + bookingId (operator visibility,
 *    guest message stays anti-enumeration).
 *  - Missing unit_id → same.
 *  - Empty-string property_id → same (truthy-typeof guard).
 *  - Unexpected throw → logError receives an Error INSTANCE, not a plain
 *    {error, stack} object. This was the cause of Sentry events rendering as
 *    "Object captured as exception with keys: error, stack" instead of the
 *    real type + stack trace.
 *  - Happy path → returns {success:true, booking:{...}} when seed is well-formed.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();

jest.mock("firebase-functions/params", () => ({
  defineSecret: () => ({value: () => "mock-secret"}),
  defineString: () => ({value: () => ""}),
  Expression: class Expression {},
}));

// In-memory mock state
let mockBookingDoc: {id: string; data: any} | null = null;
let mockPropertyData: any = null;
let mockUnitData: any = null;
let mockBookingThrow: Error | null = null;

jest.mock("../src/firebase", () => {
  const buildDocRef = (path: string[]) => ({
    get: async () => {
      const last = path[path.length - 1];
      if (last === "properties-doc") {
        return {exists: !!mockPropertyData, data: () => mockPropertyData};
      }
      if (last === "units-doc") {
        return {exists: !!mockUnitData, data: () => mockUnitData};
      }
      return {exists: false, data: () => null};
    },
    collection: (sub: string) => {
      if (sub === "units") {
        return {doc: () => buildDocRef([...path, "units-doc"])};
      }
      return {doc: () => buildDocRef([...path, sub + "-doc"])};
    },
  });

  const firestoreInstance: any = {
    collection: (name: string) => {
      if (name === "properties") {
        return {
          doc: () => buildDocRef(["properties", "properties-doc"]),
        };
      }
      // users path used only for bank details; default no-op
      return {
        doc: () => ({
          collection: () => ({
            doc: () => ({get: async () => ({exists: false, data: () => null})}),
          }),
        }),
      };
    },
    collectionGroup: (name: string) => {
      if (name !== "bookings") {
        throw new Error(`unexpected collectionGroup ${name}`);
      }
      return {
        where: () => ({
          limit: () => ({
            get: async () => {
              if (mockBookingThrow) {
                const err = mockBookingThrow;
                mockBookingThrow = null;
                throw err;
              }
              if (!mockBookingDoc) {
                return {empty: true, docs: []};
              }
              return {
                empty: false,
                docs: [{
                  id: mockBookingDoc.id,
                  data: () => mockBookingDoc!.data,
                }],
              };
            },
          }),
        }),
      };
    },
  };

  return {
    db: firestoreInstance,
    admin: {
      firestore: Object.assign(() => firestoreInstance, {
        Timestamp: {
          fromDate: (d: Date) => ({toDate: () => d, _ts: d.getTime()}),
        },
      }),
    },
  };
});

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

const logWarnSpy = jest.fn();
const logErrorSpy = jest.fn();
const logInfoSpy = jest.fn();
jest.mock("../src/logger", () => ({
  logInfo: (...a: unknown[]) => logInfoSpy(...a),
  logWarn: (...a: unknown[]) => logWarnSpy(...a),
  logError: (...a: unknown[]) => logErrorSpy(...a),
  logSuccess: jest.fn(),
}));

jest.mock("../src/bookingAccessToken", () => ({
  verifyAccessToken: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/ipUtils", () => ({
  getClientIp: () => "127.0.0.1",
  hashIp: () => "mockhash",
}));

jest.mock("../src/utils/corsAllowlist", () => ({
  getCorsAllowlist: () => ["*"],
}));

jest.mock("../src/utils/dateValidation", () => ({
  safeToDate: (v: any) => v instanceof Date ? v : new Date(v),
  calculateBookingNights: () => 2,
}));

import {verifyBookingAccess} from "../src/verifyBookingAccess";

const {wrap} = test;

const BASE_BOOKING = {
  booking_reference: "BK-TEST01",
  guest_email: "guest@example.com",
  property_id: "prop-1",
  unit_id: "unit-1",
  check_in: new Date("2026-07-01"),
  check_out: new Date("2026-07-03"),
  guest_name: "Test Guest",
  total_price: 100,
  payment_status: "pending",
  payment_method: "bank_transfer",
  status: "confirmed",
};

describe("verifyBookingAccess: guard + logger hardening", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockBookingDoc = null;
    mockPropertyData = {name: "Test Property", owner_email: "owner@test"};
    mockUnitData = {name: "Test Unit"};
    mockBookingThrow = null;
  });

  it("guards against missing property_id (returns invalid_credentials + logWarn)", async () => {
    mockBookingDoc = {
      id: "sf079-existing-booking",
      data: {...BASE_BOOKING, property_id: undefined},
    };

    const wrapped = wrap(verifyBookingAccess);
    const result = await wrapped({
      data: {
        bookingReference: "BK-TEST01",
        email: "guest@example.com",
      },
    });

    expect(result).toEqual({success: false, reason: "invalid_credentials"});
    expect(logWarnSpy).toHaveBeenCalledWith(
      expect.stringContaining("missing property_id/unit_id"),
      expect.objectContaining({
        bookingReference: "BK-TEST01",
        bookingId: "sf079-existing-booking",
        hasPropertyId: false,
        hasUnitId: true,
      })
    );
  });

  it("guards against missing unit_id (returns invalid_credentials + logWarn)", async () => {
    mockBookingDoc = {
      id: "test-booking",
      data: {...BASE_BOOKING, unit_id: undefined},
    };

    const wrapped = wrap(verifyBookingAccess);
    const result = await wrapped({
      data: {
        bookingReference: "BK-TEST01",
        email: "guest@example.com",
      },
    });

    expect(result).toEqual({success: false, reason: "invalid_credentials"});
    expect(logWarnSpy).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({hasUnitId: false}),
    );
  });

  it("guards against empty-string property_id", async () => {
    mockBookingDoc = {
      id: "test-booking",
      data: {...BASE_BOOKING, property_id: ""},
    };

    const wrapped = wrap(verifyBookingAccess);
    const result = await wrapped({
      data: {
        bookingReference: "BK-TEST01",
        email: "guest@example.com",
      },
    });

    expect(result).toEqual({success: false, reason: "invalid_credentials"});
    expect(logWarnSpy).toHaveBeenCalled();
  });

  it("logError receives an Error INSTANCE on unexpected throw (Sentry fidelity)", async () => {
    mockBookingThrow = new Error("Firestore unavailable: simulated");

    const wrapped = wrap(verifyBookingAccess);
    await expect(
      wrapped({
        data: {
          bookingReference: "BK-TEST01",
          email: "guest@example.com",
        },
      })
    ).rejects.toMatchObject({
      code: "internal",
      message: expect.stringContaining("Failed to verify booking access"),
    });

    expect(logErrorSpy).toHaveBeenCalledTimes(1);
    const [msg, errArg] = logErrorSpy.mock.calls[0];
    expect(msg).toBe("[VerifyBookingAccess] Unexpected error");
    // Critical: must be an Error instance, NOT a {error, stack} plain object.
    expect(errArg).toBeInstanceOf(Error);
    expect((errArg as Error).message).toBe("Firestore unavailable: simulated");
  });

  it("happy path: well-formed booking returns success:true", async () => {
    mockBookingDoc = {
      id: "good-booking",
      data: BASE_BOOKING,
    };

    const wrapped = wrap(verifyBookingAccess);
    const result = await wrapped({
      data: {
        bookingReference: "BK-TEST01",
        email: "guest@example.com",
      },
    });

    expect(result).toMatchObject({
      success: true,
      booking: expect.objectContaining({
        bookingId: "good-booking",
        bookingReference: "BK-TEST01",
        propertyId: "prop-1",
        unitId: "unit-1",
        nights: 2,
      }),
    });
    expect(logWarnSpy).not.toHaveBeenCalled();
    expect(logErrorSpy).not.toHaveBeenCalled();
  });
});
