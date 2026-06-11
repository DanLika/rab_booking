/**
 * Tests for src/loginLockout.ts — F-50-02 anon-DoS lockout CFs.
 *
 * Exercises recordLoginFailure / getLoginLockoutStatus / clearLoginAttempts
 * across happy path + rate-limit + auth-mismatch + auto-reset state-machine
 * transitions.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();

jest.mock("firebase-functions/params", () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const real = jest.requireActual("firebase-functions/params");
  return {
    ...real,
    defineSecret: () => ({value: () => "mock-secret", name: "MOCK"}),
    defineString: () => ({value: () => ""}),
  };
});

// In-memory loginAttempts store (per-test isolation via beforeEach reset).
const store: Record<string, any> = {};

jest.mock("../src/firebase", () => {
  // Build a single shared firestore instance — admin.firestore() must
  // return the same object every call so refs+transactions share state.
  const firestoreInstance: any = {
    collection: (name: string) => {
      if (name !== "loginAttempts") throw new Error(`unexpected collection ${name}`);
      return {
        doc: (id: string) => ({
          __id: id,
          get: async () => {
            const v = store[id];
            return {exists: !!v, data: () => v};
          },
          delete: async () => {
            delete store[id];
          },
        }),
      };
    },
    runTransaction: async (cb: any) => {
      const tx = {
        get: async (ref: any) => {
          const id = ref.__id;
          const v = store[id];
          return {exists: !!v, data: () => v};
        },
        set: (ref: any, val: any) => {
          store[ref.__id] = val;
        },
      };
      return await cb(tx);
    },
  };

  // Real Timestamp helpers — used by lockout state machine.
  const Timestamp = {
    now: () => {
      const ms = Date.now();
      return {toMillis: () => ms};
    },
    fromMillis: (ms: number) => ({toMillis: () => ms}),
  };

  const firestoreFn: any = () => firestoreInstance;
  firestoreFn.FieldValue = {serverTimestamp: () => "mock-ts"};
  firestoreFn.Timestamp = Timestamp;

  return {
    admin: {
      firestore: firestoreFn,
    },
    db: {},
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
  logSuccess: jest.fn(),
}));

jest.mock("../src/utils/ipUtils", () => ({
  getClientIp: jest.fn(() => "1.2.3.4"),
  hashIp: jest.fn((ip: string) => `hash-${ip}`),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  hashRateKey: jest.fn((raw: string) => `hash_${raw}`),
}));

jest.mock("../src/utils/inputSanitization", () => ({
  sanitizeEmail: jest.fn((e: string) => {
    if (typeof e !== "string") return "";
    const t = e.trim().toLowerCase();
    if (!t.includes("@")) return "";
    return t;
  }),
}));

import {
  recordLoginFailure,
  getLoginLockoutStatus,
  clearLoginAttempts,
} from "../src/loginLockout";

const {wrap} = test;

// Helper: patch the inline tx + non-tx ref chain to know about the email.
function emailDocId(email: string) {
  return email.trim().toLowerCase().replace(/[^a-z0-9@._\-]/g, "_");
}

describe("loginLockout (F-50-02)", () => {
  beforeEach(() => {
    Object.keys(store).forEach((k) => delete store[k]);
    jest.clearAllMocks();
    const {checkRateLimit} = require("../src/utils/rateLimit");
    checkRateLimit.mockReturnValue(true);
  });

  describe("recordLoginFailure", () => {
    const wrapped = wrap(recordLoginFailure);

    it("rejects non-email input with invalid-argument", async () => {
      await expect(wrapped({data: {email: "notanemail"}})).rejects.toThrow(/valid email/);
    });

    it("rejects empty email with invalid-argument", async () => {
      await expect(wrapped({data: {}})).rejects.toThrow(/valid email/);
    });

    it("rejects when per-IP rate limit hit", async () => {
      const {checkRateLimit} = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValueOnce(false);
      await expect(wrapped({data: {email: "victim@example.com"}})).rejects.toThrow(/Too many/);
    });

    it("creates attempt state on first failure", async () => {
      const r = await wrapped({data: {email: "first@example.com"}});
      expect(r.attemptCount).toBe(1);
      expect(r.remainingAttempts).toBe(4);
      expect(r.locked).toBe(false);
      expect(r.lockedUntilMs).toBeNull();
    });

    it("increments counter on subsequent failures", async () => {
      await wrapped({data: {email: "ramp@example.com"}});
      await wrapped({data: {email: "ramp@example.com"}});
      const r = await wrapped({data: {email: "ramp@example.com"}});
      expect(r.attemptCount).toBe(3);
      expect(r.remainingAttempts).toBe(2);
      expect(r.locked).toBe(false);
    });

    it("locks at MAX_ATTEMPTS=5 with lockedUntilMs ≈ now+15min", async () => {
      const email = "lockout@example.com";
      for (let i = 0; i < 4; i++) await wrapped({data: {email}});
      const r5 = await wrapped({data: {email}});
      expect(r5.attemptCount).toBe(5);
      expect(r5.remainingAttempts).toBe(0);
      expect(r5.locked).toBe(true);
      expect(r5.lockedUntilMs).toBeGreaterThan(Date.now() + 14 * 60 * 1000);
      expect(r5.lockedUntilMs).toBeLessThan(Date.now() + 16 * 60 * 1000);
    });

    it("resets counter after ATTEMPT_RESET_MS of inactivity", async () => {
      const email = "stale@example.com";
      // Seed the store with an old attempt.
      const docId = emailDocId(email);
      store[docId] = {
        email,
        attemptCount: 4,
        lockedUntil: null,
        lastAttemptAt: {toMillis: () => Date.now() - 2 * 60 * 60 * 1000}, // 2h ago > 1h reset
      };
      const r = await wrapped({data: {email}});
      // Old state expired → reset to count=1
      expect(r.attemptCount).toBe(1);
      expect(r.locked).toBe(false);
    });
  });

  describe("getLoginLockoutStatus", () => {
    const wrapped = wrap(getLoginLockoutStatus);

    it("returns clean state for unknown email", async () => {
      const r = await wrapped({data: {email: "unknown@example.com"}});
      expect(r.locked).toBe(false);
      expect(r.attemptCount).toBe(0);
      expect(r.remainingAttempts).toBe(5);
      expect(r.lockedUntilMs).toBeNull();
    });

    it("returns locked state with lockedUntilMs when locked", async () => {
      const email = "locked@example.com";
      const docId = emailDocId(email);
      const until = Date.now() + 10 * 60 * 1000;
      store[docId] = {
        email,
        attemptCount: 5,
        lockedUntil: {toMillis: () => until},
        lastAttemptAt: {toMillis: () => Date.now() - 1000},
      };
      const r = await wrapped({data: {email}});
      expect(r.locked).toBe(true);
      expect(r.lockedUntilMs).toBe(until);
      expect(r.attemptCount).toBe(5);
    });

    it("auto-resets and deletes doc on read past reset window", async () => {
      const email = "expired@example.com";
      const docId = emailDocId(email);
      store[docId] = {
        email,
        attemptCount: 3,
        lockedUntil: null,
        lastAttemptAt: {toMillis: () => Date.now() - 2 * 60 * 60 * 1000},
      };
      const r = await wrapped({data: {email}});
      expect(r.attemptCount).toBe(0);
      expect(r.locked).toBe(false);
    });

    it("throws resource-exhausted when per-IP status rate limit hit", async () => {
      const {checkRateLimit} = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValueOnce(false);
      await expect(wrapped({data: {email: "any@example.com"}})).rejects.toThrow(/Too many status/);
    });

    it("rejects invalid email input", async () => {
      await expect(wrapped({data: {email: 12345}})).rejects.toThrow(/valid email/);
    });
  });

  describe("clearLoginAttempts", () => {
    const wrapped = wrap(clearLoginAttempts);

    it("rejects unauthenticated callers", async () => {
      await expect(wrapped({data: {email: "x@y.com"}})).rejects.toThrow(/authenticated/);
    });

    it("rejects when email arg missing", async () => {
      await expect(
        wrapped({data: {}, auth: {uid: "u-1", token: {email: "x@y.com"}}})
      ).rejects.toThrow(/valid email/);
    });

    it("rejects when token.email mismatches request email (cross-tenant clear)", async () => {
      await expect(
        wrapped({
          data: {email: "victim@example.com"},
          auth: {uid: "u-1", token: {email: "attacker@example.com"}},
        })
      ).rejects.toThrow(/your own email/);
    });

    it("clears attempts on happy path", async () => {
      const email = "owner@example.com";
      const docId = emailDocId(email);
      store[docId] = {email, attemptCount: 3, lockedUntil: null, lastAttemptAt: {toMillis: () => Date.now()}};
      const r = await wrapped({
        data: {email},
        auth: {uid: "u-1", token: {email}},
      });
      expect(r).toEqual({cleared: true});
    });
  });
});
