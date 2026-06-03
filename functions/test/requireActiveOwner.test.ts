/**
 * Tests for src/utils/requireActiveOwner.ts — SF-078 trial gate (L1).
 *
 * Verifies:
 *  - no auth → throws unauthenticated
 *  - status ∈ {trial, active} → returns uid
 *  - status ∈ {trial_expired, suspended} → throws failed-precondition with
 *    matched user-facing message
 *  - status missing / unknown → throws failed-precondition + Sentry WARN
 *  - user doc missing → throws failed-precondition + Sentry WARN
 *  - Firestore read throws → throws internal (passes through)
 */

import {HttpsError} from "firebase-functions/v2/https";

jest.mock("firebase-functions/params", () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const real = jest.requireActual("firebase-functions/params");
  return {
    ...real,
    defineSecret: () => ({value: () => "mock-secret", name: "MOCK"}),
    defineString: () => ({value: () => ""}),
  };
});

// In-memory users store keyed by uid → user-doc data.
const usersStore: Record<string, Record<string, unknown> | undefined> = {};

// Optional injection: force the next Firestore read to throw.
let nextReadError: Error | null = null;

jest.mock("../src/firebase", () => {
  const firestoreInstance: any = {
    collection: (name: string) => {
      if (name !== "users") throw new Error(`unexpected collection ${name}`);
      return {
        doc: (uid: string) => ({
          get: async () => {
            if (nextReadError) {
              const err = nextReadError;
              nextReadError = null;
              throw err;
            }
            const v = usersStore[uid];
            return {exists: v !== undefined, data: () => v};
          },
        }),
      };
    },
  };
  return {
    admin: {firestore: () => firestoreInstance},
    db: firestoreInstance,
  };
});

// Sentry captureMessage is the operator-visible alert path. Verify it fires
// on the unknown-status branch by spying on the helper module.
const captureMessageSpy = jest.fn();
jest.mock("../src/sentry", () => ({
  captureMessage: (...args: unknown[]) => captureMessageSpy(...args),
  setUser: jest.fn(),
  captureException: jest.fn(),
  addBreadcrumb: jest.fn(),
}));

// Logger is mocked to a no-op so test output isn't polluted; capture
// `logWarn` calls so we can assert dual logging (Cloud Logging + Sentry).
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

// eslint-disable-next-line @typescript-eslint/no-var-requires
const {requireActiveOwner} = require("../src/utils/requireActiveOwner");

beforeEach(() => {
  for (const k of Object.keys(usersStore)) delete usersStore[k];
  nextReadError = null;
  captureMessageSpy.mockReset();
  logWarnSpy.mockReset();
});

describe("requireActiveOwner (SF-078)", () => {
  it("throws unauthenticated when auth is missing", async () => {
    await expect(requireActiveOwner(undefined)).rejects.toMatchObject({
      code: "unauthenticated",
    });
    await expect(requireActiveOwner(null)).rejects.toMatchObject({
      code: "unauthenticated",
    });
    await expect(requireActiveOwner({uid: ""})).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("returns uid for accountStatus 'active'", async () => {
    usersStore["uid-active"] = {accountStatus: "active"};
    await expect(requireActiveOwner({uid: "uid-active"})).resolves.toBe(
      "uid-active",
    );
    // Happy path: no Sentry WARN, no Cloud-Logging WARN.
    expect(captureMessageSpy).not.toHaveBeenCalled();
    expect(logWarnSpy).not.toHaveBeenCalled();
  });

  it("returns uid for accountStatus 'trial'", async () => {
    usersStore["uid-trial"] = {accountStatus: "trial"};
    await expect(requireActiveOwner({uid: "uid-trial"})).resolves.toBe(
      "uid-trial",
    );
  });

  it("throws failed-precondition with upgrade message on 'trial_expired'", async () => {
    usersStore["uid-expired"] = {accountStatus: "trial_expired"};
    try {
      await requireActiveOwner({uid: "uid-expired"});
      throw new Error("should not reach");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      const httpsErr = e as HttpsError;
      expect(httpsErr.code).toBe("failed-precondition");
      expect(httpsErr.message).toMatch(/trial expired/i);
      expect(httpsErr.message).toMatch(/upgrade/i);
    }
    // Documented blocking value: should NOT fire Sentry WARN (only unknown does).
    expect(captureMessageSpy).not.toHaveBeenCalled();
  });

  it("throws failed-precondition with support message on 'suspended'", async () => {
    usersStore["uid-suspended"] = {accountStatus: "suspended"};
    try {
      await requireActiveOwner({uid: "uid-suspended"});
      throw new Error("should not reach");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      const httpsErr = e as HttpsError;
      expect(httpsErr.code).toBe("failed-precondition");
      expect(httpsErr.message).toMatch(/suspended/i);
      expect(httpsErr.message).toMatch(/support/i);
    }
    expect(captureMessageSpy).not.toHaveBeenCalled();
  });

  it("throws failed-precondition + Sentry WARN on unknown status value", async () => {
    usersStore["uid-premium"] = {accountStatus: "premium"};
    try {
      await requireActiveOwner({uid: "uid-premium"});
      throw new Error("should not reach");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("unknown accountStatus"),
      "warning",
      expect.objectContaining({uid: "uid-premium", observed: "premium"}),
    );
    expect(logWarnSpy).toHaveBeenCalled();
  });

  it("throws failed-precondition + Sentry WARN when accountStatus field is missing", async () => {
    usersStore["uid-missing-field"] = {};
    try {
      await requireActiveOwner({uid: "uid-missing-field"});
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("unknown accountStatus"),
      "warning",
      expect.objectContaining({uid: "uid-missing-field", observed: "<missing>"}),
    );
  });

  it("throws failed-precondition + Sentry WARN when users/{uid} doc does not exist", async () => {
    // usersStore intentionally empty for "uid-no-doc"
    try {
      await requireActiveOwner({uid: "uid-no-doc"});
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    expect(captureMessageSpy).toHaveBeenCalledWith(
      expect.stringContaining("users/{uid} doc missing"),
      "warning",
      expect.objectContaining({uid: "uid-no-doc"}),
    );
  });

  it("throws internal when Firestore read fails", async () => {
    usersStore["uid-read-fail"] = {accountStatus: "active"};
    nextReadError = new Error("network down");
    try {
      await requireActiveOwner({uid: "uid-read-fail"});
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("internal");
    }
  });

  it("rate-limit-budget guarantee: gate runs before rate-limit in caller, " +
     "so a trial_expired caller's rate-limit budget is not burned", async () => {
    // This documents the calling-site invariant in audit/110: in all 7 L1
    // callables, `requireActiveOwner` is the first await + runs BEFORE
    // `enforceRateLimit` / `checkRateLimit`. The unit test for the helper
    // can only assert the helper itself doesn't touch any rate-limit
    // collection — the calling-order property is enforced by reading the
    // diff in callable bodies. We assert (a) helper resolves with
    // failed-precondition early on expired status and (b) no rate-limit
    // collection was touched (mock would surface unexpected collection
    // access via the `unexpected collection ${name}` throw in the
    // firebase.ts mock).
    usersStore["uid-expired-burn"] = {accountStatus: "trial_expired"};
    try {
      await requireActiveOwner({uid: "uid-expired-burn"});
      throw new Error("should not reach");
    } catch (e) {
      expect((e as HttpsError).code).toBe("failed-precondition");
    }
    // If the helper had reached into `rateLimits` or any other collection,
    // the firebase.ts mock would throw `unexpected collection …`.
  });
});
