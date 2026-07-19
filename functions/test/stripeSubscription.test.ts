/**
 * Unit tests for subscription lifecycle webhook handlers in stripePayment.ts
 * and for the createSubscriptionCheckoutSession callable in stripeSubscription.ts.
 *
 * Mirrors the mocking style of stripePayment.test.ts (firebase-functions-test
 * + jest.mock for firebase/stripe/logger).
 */

// Using require for firebase-functions-test to avoid ESM/CJS interop issues
// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();
import { HttpsError } from "firebase-functions/v2/https";

import { handleStripeWebhook } from "../src/stripePayment";
import { createSubscriptionCheckoutSession } from "../src/stripeSubscription";

const { wrap } = test;

// ─── shared mocks ────────────────────────────────────────────────────────────

jest.mock("firebase-functions/params", () => ({
  defineSecret: () => ({
    value: () => "mock-stripe-webhook-secret",
  }),
  defineString: () => ({
    value: () => "",
  }),
  Expression: class Expression {},
}));

jest.mock("../src/firebase", () => ({
  admin: {
    firestore: {
      FieldValue: {
        serverTimestamp: () => "mock-server-timestamp",
        delete: () => "mock-delete-field",
      },
    },
  },
  db: {
    collection: jest.fn(),
    runTransaction: jest.fn(),
  },
}));

jest.mock("../src/stripe", () => ({
  getStripeClient: jest.fn(),
}));

jest.mock("../src/emailService", () => ({
  sendBookingApprovedEmail: jest.fn(),
  sendOwnerNotificationEmail: jest.fn(),
}));

jest.mock("../src/notificationService", () => ({
  createPaymentNotification: jest.fn(),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  hashRateKey: jest.fn((raw: string) => `hash_${raw}`),
}));

jest.mock("../src/utils/requireActiveUnitOwner", () => ({
  requireActiveUnitOwner: jest.fn().mockResolvedValue("mock-owner-uid"),
}));

// ─── helpers ─────────────────────────────────────────────────────────────────

/** Build a minimal HTTP-like req/res pair for handleStripeWebhook. */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function makeReqRes(event: any) {
  const req = {
    method: "POST",
    headers: { "stripe-signature": "valid-sig" },
    rawBody: "raw-body",
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    send: jest.fn(),
    set: jest.fn(),
    json: jest.fn(),
  };
  return { req, res, event };
}

// ─── describe blocks ──────────────────────────────────────────────────────────

describe("Stripe Subscription Lifecycle — webhook handlers", () => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockDb: any;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockStripe: any;

  beforeEach(() => {
    jest.clearAllMocks();

    mockDb = require("../src/firebase").db;
    const firestoreMock = {
      collection: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ docs: [], empty: true }),
      update: jest.fn().mockResolvedValue(true),
      set: jest.fn().mockResolvedValue(true),
      id: "mock-generated-id",
    };
    mockDb.collection.mockReturnValue(firestoreMock);

    mockStripe = {
      webhooks: {
        constructEvent: jest.fn(),
      },
    };
    const { getStripeClient } = require("../src/stripe");
    getStripeClient.mockReturnValue(mockStripe);
  });

  // ── checkout.session.completed (mode: subscription) ──────────────────────

  describe("checkout.session.completed (mode: subscription)", () => {
    it("activates the user on a valid subscription session", async () => {
      const subscriptionEvent = {
        id: "evt_sub_001",
        type: "checkout.session.completed",
        livemode: false,
        api_version: "2023-10-16",
        data: {
          object: {
            id: "cs_sub_001",
            mode: "subscription",
            client_reference_id: "user-001",
            customer: "cus_001",
            subscription: "sub_001",
            metadata: {},
          },
        },
      };

      mockStripe.webhooks.constructEvent.mockReturnValue(subscriptionEvent);

      // dedup: transaction returns "new"
      mockDb.runTransaction = jest.fn().mockImplementation(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        async (callback: any) => {
          const t = {
            get: jest.fn().mockResolvedValue({ exists: false }),
            set: jest.fn(),
          };
          return callback(t);
        }
      );

      // The handler calls db.collection("users").doc(userId).update(...)
      // We wire the chain so update is reachable.
      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockDocRef = { update: mockUpdate };
      const mockDocFn = jest.fn().mockReturnValue(mockDocRef);
      const mockColFn = jest.fn().mockReturnValue({ doc: mockDocFn });
      mockDb.collection.mockImplementation(mockColFn);

      const { req, res } = makeReqRes(subscriptionEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "subscription_activated" })
      );
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          accountStatus: "active",
          accountType: "premium",
          stripeCustomerId: "cus_001",
          stripeSubscriptionId: "sub_001",
          stripeSubscriptionStatus: "active",
          statusChangedBy: "system_webhook",
          statusChangeReason: "subscription_purchased",
        })
      );
    });
  });

  // ── customer.subscription.deleted ─────────────────────────────────────────

  describe("customer.subscription.deleted", () => {
    const deletedEvent = {
      id: "evt_del_001",
      type: "customer.subscription.deleted",
      livemode: false,
      api_version: "2023-10-16",
      data: {
        object: {
          id: "sub_001",
          customer: "cus_001",
        },
      },
    };

    function setupDeletedEvent() {
      mockStripe.webhooks.constructEvent.mockReturnValue(deletedEvent);
      mockDb.runTransaction = jest.fn().mockImplementation(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        async (callback: any) => {
          const t = {
            get: jest.fn().mockResolvedValue({ exists: false }),
            set: jest.fn(),
          };
          return callback(t);
        }
      );
    }

    it("downgrades a regular user to trial_expired", async () => {
      setupDeletedEvent();

      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockUserDoc = {
        id: "user-001",
        ref: { update: mockUpdate },
        data: () => ({ stripeCustomerId: "cus_001", accountType: "premium" }),
      };
      const mockWhereChain = {
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockUserDoc],
        }),
      };
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnValue(mockWhereChain),
        doc: jest.fn().mockReturnValue({
          set: jest.fn(),
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const { req, res } = makeReqRes(deletedEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "subscription_canceled" })
      );
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          accountStatus: "trial_expired",
          stripeSubscriptionStatus: "canceled",
          statusChangedBy: "system_webhook",
          statusChangeReason: "subscription_canceled_by_stripe",
        })
      );
    });

    it("skips downgrade when stripeCustomerId does not match (H-09 guard)", async () => {
      setupDeletedEvent(); // event has customer: "cus_001"

      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockUserDoc = {
        id: "user-001",
        ref: { update: mockUpdate },
        // doc has a DIFFERENT customerId — mismatch
        data: () => ({ stripeCustomerId: "cus_ATTACKER", accountType: "premium" }),
      };
      const mockWhereChain = {
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockUserDoc],
        }),
      };
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnValue(mockWhereChain),
        doc: jest.fn().mockReturnValue({
          set: jest.fn(),
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const { req, res } = makeReqRes(deletedEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "customer_mismatch_skipped" })
      );
      expect(mockUpdate).not.toHaveBeenCalled();
    });

    it("preserves a lifetime account and does not set trial_expired", async () => {
      setupDeletedEvent();

      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockUserDoc = {
        id: "user-lifetime",
        ref: { update: mockUpdate },
        data: () => ({ stripeCustomerId: "cus_001", accountType: "lifetime" }),
      };
      const mockWhereChain = {
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockUserDoc],
        }),
      };
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnValue(mockWhereChain),
        doc: jest.fn().mockReturnValue({
          set: jest.fn(),
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const { req, res } = makeReqRes(deletedEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "lifetime_user_protected" })
      );
      // Must write the canceled status/reason but NOT accountStatus: "trial_expired"
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.not.objectContaining({ accountStatus: "trial_expired" })
      );
    });
  });

  // ── invoice.paid ──────────────────────────────────────────────────────────

  describe("invoice.paid", () => {
    const paidEvent = {
      id: "evt_inv_paid_001",
      type: "invoice.paid",
      livemode: false,
      api_version: "2023-10-16",
      data: {
        object: {
          subscription: "sub_001",
          customer: "cus_001",
        },
      },
    };

    function setupPaidEvent() {
      mockStripe.webhooks.constructEvent.mockReturnValue(paidEvent);
      mockDb.runTransaction = jest.fn().mockImplementation(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        async (callback: any) => {
          const t = {
            get: jest.fn().mockResolvedValue({ exists: false }),
            set: jest.fn(),
          };
          return callback(t);
        }
      );
    }

    it("confirms active + writes lastPaymentAt on happy path", async () => {
      setupPaidEvent();

      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockUserDoc = {
        id: "user-001",
        ref: { update: mockUpdate },
        data: () => ({ stripeCustomerId: "cus_001", accountType: "premium" }),
      };
      const mockWhereChain = {
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockUserDoc],
        }),
      };
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnValue(mockWhereChain),
        doc: jest.fn().mockReturnValue({
          set: jest.fn(),
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const { req, res } = makeReqRes(paidEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "subscription_renewed" })
      );
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          accountStatus: "active",
          stripeSubscriptionStatus: "active",
          lastPaymentAt: "mock-server-timestamp",
        })
      );
    });

    it("recovers from past_due: restores stripeSubscriptionStatus to active", async () => {
      setupPaidEvent();

      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockUserDoc = {
        id: "user-001",
        ref: { update: mockUpdate },
        // Simulate a previously-marked past_due user
        data: () => ({
          stripeCustomerId: "cus_001",
          accountType: "premium",
          stripeSubscriptionStatus: "past_due",
        }),
      };
      const mockWhereChain = {
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockUserDoc],
        }),
      };
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnValue(mockWhereChain),
        doc: jest.fn().mockReturnValue({
          set: jest.fn(),
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const { req, res } = makeReqRes(paidEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "subscription_renewed" })
      );
      // stripeSubscriptionStatus MUST flip back to 'active'
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ stripeSubscriptionStatus: "active" })
      );
    });
  });

  // ── invoice.payment_failed (new handler) ──────────────────────────────────

  describe("invoice.payment_failed", () => {
    const failedEvent = {
      id: "evt_inv_fail_001",
      type: "invoice.payment_failed",
      livemode: false,
      api_version: "2023-10-16",
      data: {
        object: {
          subscription: "sub_001",
          customer: "cus_001",
        },
      },
    };

    function setupFailedEvent() {
      mockStripe.webhooks.constructEvent.mockReturnValue(failedEvent);
      mockDb.runTransaction = jest.fn().mockImplementation(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        async (callback: any) => {
          const t = {
            get: jest.fn().mockResolvedValue({ exists: false }),
            set: jest.fn(),
          };
          return callback(t);
        }
      );
    }

    it("writes past_due and does NOT change accountStatus", async () => {
      setupFailedEvent();

      const mockUpdate = jest.fn().mockResolvedValue(true);
      const mockUserDoc = {
        id: "user-001",
        ref: { update: mockUpdate },
        data: () => ({
          stripeCustomerId: "cus_001",
          accountType: "premium",
          accountStatus: "active",
        }),
      };
      const mockWhereChain = {
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          empty: false,
          docs: [mockUserDoc],
        }),
      };
      mockDb.collection.mockReturnValue({
        where: jest.fn().mockReturnValue(mockWhereChain),
        doc: jest.fn().mockReturnValue({
          set: jest.fn(),
          get: jest.fn().mockResolvedValue({ exists: false }),
        }),
      });

      const { req, res } = makeReqRes(failedEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "past_due" })
      );
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          stripeSubscriptionStatus: "past_due",
          statusChangedBy: "system_webhook",
          statusChangeReason: "invoice_payment_failed",
        })
      );
      // accountStatus must NOT be touched (access continues during Stripe retries)
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.not.objectContaining({ accountStatus: expect.anything() })
      );
    });

    it("is a no-op when no user is found for the subscription", async () => {
      setupFailedEvent(); // default mockDb returns empty snapshot

      const { req, res } = makeReqRes(failedEvent);
      await handleStripeWebhook(req as any, res as any);

      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ status: "user_not_found" })
      );
    });
  });
});

// ─── createSubscriptionCheckoutSession ────────────────────────────────────────

describe("createSubscriptionCheckoutSession", () => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockDb: any;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockStripe: any;

  const validReturnUrl = "https://app.bookbed.io/owner/subscription";
  const allowedPriceId = "price_BOOKBED_MONTHLY";

  beforeEach(() => {
    jest.clearAllMocks();

    mockDb = require("../src/firebase").db;
    const firestoreMock = {
      collection: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ exists: false, data: () => ({}) }),
      update: jest.fn().mockResolvedValue(true),
      set: jest.fn().mockResolvedValue(true),
    };
    mockDb.collection.mockReturnValue(firestoreMock);

    mockStripe = {
      customers: { create: jest.fn() },
      checkout: { sessions: { create: jest.fn() } },
    };
    const { getStripeClient } = require("../src/stripe");
    getStripeClient.mockReturnValue(mockStripe);

    // Ensure returnUrl validation passes for the valid URL
    // (the real validator uses process.env indirectly; bookbed domains are
    //  hardcoded in the allowlist so app.bookbed.io always passes)
  });

  it("throws failed-precondition when ALLOWED_SUBSCRIPTION_PRICE_IDS is empty", async () => {
    const origEnv = process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS;
    process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = "";
    try {
      const wrapped = wrap(createSubscriptionCheckoutSession);
      await expect(
        wrapped({
          data: { priceId: allowedPriceId, returnUrl: validReturnUrl },
          auth: { uid: "user-001", token: { email: "owner@test.com" } },
        })
      ).rejects.toThrow(
        new HttpsError(
          "failed-precondition",
          "Subscription pricing is not configured. Contact support."
        )
      );
    } finally {
      if (origEnv === undefined) delete process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS;
      else process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = origEnv;
    }
  });

  it("throws invalid-argument when priceId is not in allowlist", async () => {
    const origEnv = process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS;
    process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = allowedPriceId;
    try {
      const wrapped = wrap(createSubscriptionCheckoutSession);
      await expect(
        wrapped({
          data: { priceId: "price_NOT_ALLOWED", returnUrl: validReturnUrl },
          auth: { uid: "user-001", token: { email: "owner@test.com" } },
        })
      ).rejects.toThrow(
        new HttpsError("invalid-argument", "Price not allowed.")
      );
    } finally {
      if (origEnv === undefined) delete process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS;
      else process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = origEnv;
    }
  });

  it("creates a checkout session and returns {url, sessionId} on allowed priceId", async () => {
    const origEnv = process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS;
    process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = allowedPriceId;
    try {
      // No existing customer (get returns empty)
      const mockUpdate = jest.fn().mockResolvedValue(true);
      mockDb.collection.mockReturnValue({
        doc: jest.fn().mockReturnValue({
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({}), // no stripe_customer_id
          }),
          update: mockUpdate,
        }),
      });

      mockStripe.customers.create.mockResolvedValue({ id: "cus_new_001" });
      mockStripe.checkout.sessions.create.mockResolvedValue({
        id: "cs_sub_test_001",
        url: "https://checkout.stripe.com/pay/cs_sub_test_001",
      });

      const wrapped = wrap(createSubscriptionCheckoutSession);
      const result = await wrapped({
        data: { priceId: allowedPriceId, returnUrl: validReturnUrl },
        auth: { uid: "user-001", token: { email: "owner@test.com" } },
      });

      expect(result.sessionId).toBe("cs_sub_test_001");
      expect(result.url).toContain("cs_sub_test_001");
      expect(mockStripe.checkout.sessions.create).toHaveBeenCalledWith(
        expect.objectContaining({
          mode: "subscription",
          line_items: expect.arrayContaining([
            expect.objectContaining({ price: allowedPriceId, quantity: 1 }),
          ]),
          client_reference_id: "user-001",
        }),
        expect.any(Object) // idempotency key options
      );
    } finally {
      if (origEnv === undefined) delete process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS;
      else process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = origEnv;
    }
  });
});
