/**
 * Tests for src/utils/requireActiveUnitOwner.ts — SF-079 L2 trial gate.
 *
 * Verifies:
 *   - empty/missing propertyId → invalid-argument
 *   - property doc missing → failed-precondition + Sentry WARN
 *   - property doc missing owner_id field → failed-precondition + WARN
 *   - owner users/{uid} doc missing → failed-precondition + WARN
 *   - owner accountStatus ∈ {trial, active} → returns ownerUid
 *   - owner accountStatus ∈ {trial_expired, suspended} → failed-precondition
 *     (NO Sentry WARN — known blocking state, not data drift)
 *   - owner unknown accountStatus → failed-precondition + Sentry WARN
 *   - Firestore read failure → internal
 *   - generic guest-facing message identical across all block branches
 *     (does not leak owner's billing posture)
 */

import {HttpsError} from "firebase-functions/v2/https";

jest.mock("firebase-functions/params", () => {
  const real = jest.requireActual("firebase-functions/params");
  return {
    ...real,
    defineSecret: () => ({value: () => "mock-secret", name: "MOCK"}),
    defineString: () => ({value: () => ""}),
  };
});

// Stores keyed by collection.
const propertiesStore: Record<string, Record<string, unknown> | undefined> = {};
const usersStore: Record<string, Record<string, unknown> | undefined> = {};

// Force the next read against a collection to throw.
let nextPropertiesReadError: Error | null = null;
let nextUsersReadError: Error | null = null;

jest.mock("../src/firebase", () => {
  const collectionImpl = (name: string) => ({
    doc: (id: string) => ({
      get: async () => {
        if (name === "properties") {
          if (nextPropertiesReadError) {
            const err = nextPropertiesReadError;
            nextPropertiesReadError = null;
            throw err;
          }
          const v = propertiesStore[id];
          return {exists: v !== undefined, data: () => v};
        }
        if (name === "users") {
          if (nextUsersReadError) {
            const err = nextUsersReadError;
            nextUsersReadError = null;
            throw err;
          }
          const v = usersStore[id];
          return {exists: v !== undefined, data: () => v};
        }
        throw new Error(`unexpected collection ${name}`);
      },
    }),
  });

  const firestoreInstance: any = {collection: collectionImpl};
  return {
    admin: {firestore: () => firestoreInstance},
    db: firestoreInstance,
  };
});

const captureMessageSpy = jest.fn();
jest.mock("../src/sentry", () => ({
  captureMessage: (...args: unknown[]) => captureMessageSpy(...args),
  setUser: jest.fn(),
  captureException: jest.fn(),
  addBreadcrumb: jest.fn(),
}));

const logWarnSpy = jest.fn();
jest.mock("../src/logger", () => ({
  logWarn: (...args: unknown[]) => logWarnSpy(...args),
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logDebug: jest.fn(),
  logOperation: jest.fn(),
  logComplete: jest.fn(),
}));

const {requireActiveUnitOwner} = require("../src/utils/requireActiveUnitOwner");

const GUEST_MSG = "This property is currently unavailable for new bookings.";

beforeEach(() => {
  for (const k of Object.keys(propertiesStore)) delete propertiesStore[k];
  for (const k of Object.keys(usersStore)) delete usersStore[k];
  nextPropertiesReadError = null;
  nextUsersReadError = null;
  captureMessageSpy.mockReset();
  logWarnSpy.mockReset();
});

describe("requireActiveUnitOwner (SF-079)", () => {
  it("throws invalid-argument on empty/missing propertyId", async () => {
    await expect(requireActiveUnitOwner("", "callable-name"))
      .rejects.toMatchObject({code: "invalid-argument"});
    await expect(requireActiveUnitOwner(undefined as any, "callable-name"))
      .rejects.toMatchObject({code: "invalid-argument"});
  });

  it("returns ownerUid when owner accountStatus is 'active'", async () => {
    propertiesStore["prop-1"] = {owner_id: "owner-active"};
    usersStore["owner-active"] = {accountStatus: "active"};
    await expect(requireActiveUnitOwner("prop-1", "test"))
      .resolves.toBe("owner-active");
    expect(captureMessageSpy).not.toHaveBeenCalled();
  });

  it("returns ownerUid when owner accountStatus is 'trial'", async () => {
    propertiesStore["prop-trial"] = {owner_id: "owner-trial"};
    usersStore["owner-trial"] = {accountStatus: "trial"};
    await expect(requireActiveUnitOwner("prop-trial", "test"))
      .resolves.toBe("owner-trial");
  });

  it("blocks 'trial_expired' with generic guest message (no Sentry WARN)", async () => {
    propertiesStore["prop-expired"] = {owner_id: "owner-expired"};
    usersStore["owner-expired"] = {accountStatus: "trial_expired"};
    try {
      await requireActiveUnitOwner("prop-expired", "test");
      throw new Error("should not reach");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      expect((e as HttpsError).code).toBe("failed-precondition");
      expect((e as HttpsError).message).toBe(GUEST_MSG);
    }
    // Known blocking state — operator already knows; no Sentry alert.
    expect(captureMessageSpy).not.toHaveBeenCalled();
  });

  it("blocks 'suspended' with generic guest message (no Sentry WARN)", async () => {
    propertiesStore["prop-susp"] = {owner_id: "owner-susp"};
    usersStore["owner-susp"] = {accountStatus: "suspended"};
    try {
      await requireActiveUnitOwner("prop-susp", "test");
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
      expect((e as HttpsError).message).toBe(GUEST_MSG);
    }
    expect(captureMessageSpy).not.toHaveBeenCalled();
  });

  it("blocks unknown accountStatus + Sentry WARN with propertyId + ownerUid", async () => {
    propertiesStore["prop-prem"] = {owner_id: "owner-prem"};
    usersStore["owner-prem"] = {accountStatus: "premium"};
    try {
      await requireActiveUnitOwner("prop-prem", "createBookingAtomic");
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
      expect((e as HttpsError).message).toBe(GUEST_MSG);
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("unknown owner accountStatus"),
      "warning",
      expect.objectContaining({
        propertyId: "prop-prem",
        ownerUid: "owner-prem",
        observed: "premium",
        callable: "createBookingAtomic",
      }),
    );
    expect(logWarnSpy).toHaveBeenCalled();
  });

  it("blocks missing accountStatus + Sentry WARN", async () => {
    propertiesStore["prop-bare"] = {owner_id: "owner-bare"};
    usersStore["owner-bare"] = {};
    try {
      await requireActiveUnitOwner("prop-bare", "test");
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.any(String),
      "warning",
      expect.objectContaining({observed: "<missing>"}),
    );
  });

  it("blocks when property doc does not exist + Sentry WARN", async () => {
    try {
      await requireActiveUnitOwner("missing-prop", "getUnitAvailability");
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
      expect((e as HttpsError).message).toBe(GUEST_MSG);
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("property doc missing"),
      "warning",
      expect.objectContaining({propertyId: "missing-prop", callable: "getUnitAvailability"}),
    );
  });

  it("blocks when property doc has no owner_id + Sentry WARN", async () => {
    propertiesStore["prop-no-owner"] = {name: "Some property"};
    try {
      await requireActiveUnitOwner("prop-no-owner", "test");
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("property missing owner_id field"),
      "warning",
      expect.objectContaining({propertyId: "prop-no-owner"}),
    );
  });

  it("blocks when owner users/{uid} doc does not exist + Sentry WARN", async () => {
    propertiesStore["prop-orphan"] = {owner_id: "owner-orphan"};
    // usersStore intentionally empty for owner-orphan
    try {
      await requireActiveUnitOwner("prop-orphan", "test");
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("owner users/{uid} doc missing"),
      "warning",
      expect.objectContaining({propertyId: "prop-orphan", ownerUid: "owner-orphan"}),
    );
  });

  it("throws internal when properties read fails", async () => {
    nextPropertiesReadError = new Error("network down");
    await expect(requireActiveUnitOwner("any-prop", "test"))
      .rejects.toMatchObject({code: "internal"});
  });

  it("throws internal when users read fails", async () => {
    propertiesStore["prop-ok"] = {owner_id: "owner-ok"};
    nextUsersReadError = new Error("network down");
    await expect(requireActiveUnitOwner("prop-ok", "test"))
      .rejects.toMatchObject({code: "internal"});
  });

  it("guest-facing message is identical across all blocking branches (no posture leak)", async () => {
    // trial_expired
    propertiesStore["p1"] = {owner_id: "u1"};
    usersStore["u1"] = {accountStatus: "trial_expired"};
    // suspended
    propertiesStore["p2"] = {owner_id: "u2"};
    usersStore["u2"] = {accountStatus: "suspended"};
    // unknown
    propertiesStore["p3"] = {owner_id: "u3"};
    usersStore["u3"] = {accountStatus: "premium"};
    // missing property
    // (p4 not seeded)
    // missing owner_id
    propertiesStore["p5"] = {};
    // missing owner doc
    propertiesStore["p6"] = {owner_id: "u6"};

    const messages: string[] = [];
    for (const propId of ["p1", "p2", "p3", "p4", "p5", "p6"]) {
      try {
        await requireActiveUnitOwner(propId, "test");
        messages.push("(no throw)");
      } catch (e) {
        messages.push((e as HttpsError).message);
      }
    }
    expect(new Set(messages).size).toBe(1);
    expect(messages[0]).toBe(GUEST_MSG);
  });
});
