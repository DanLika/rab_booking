/**
 * Unit tests for stripeConnect.ts cloud functions.
 * Mocks Firebase and Stripe services.
 */

// Using require for firebase-functions-test to avoid ESM/CJS interop issues
// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();
import { HttpsError } from "firebase-functions/v2/https";

// Import the functions to be tested
import {
  createStripeConnectAccount,
  getStripeAccountStatus,
  disconnectStripeAccount
} from "../src/stripeConnect";

// Initialize the test environment
const { wrap } = test;

// Mock dependencies
jest.mock("../src/firebase", () => ({
  admin: {
    firestore: {
      FieldValue: {
        serverTimestamp: () => "mock-server-timestamp",
        delete: () => "mock-delete-timestamp",
      },
    },
  },
  db: {
    collection: jest.fn(),
  },
}));

jest.mock("../src/stripe", () => ({
  getStripeClient: jest.fn(),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true), // Default to allow
}));

describe("Stripe Connect Functions", () => {
  // Mock Firestore and Stripe clients with explicit 'any' types for testing
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockDb: any, mockStripe: any;

  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();

    // Setup mock Firestore
    mockDb = require("../src/firebase").db;
    const firestoreMock = {
      collection: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ exists: false, data: () => ({}) }),
      update: jest.fn().mockResolvedValue(true),
    };
    mockDb.collection.mockReturnValue(firestoreMock);

    // Setup mock Stripe
    mockStripe = {
      accounts: {
        create: jest.fn(),
        retrieve: jest.fn(),
      },
      accountLinks: {
        create: jest.fn(),
      },
      balance: {
        retrieve: jest.fn(),
      }
    };
    const { getStripeClient } = require("../src/stripe");
    getStripeClient.mockReturnValue(mockStripe);

    // Explicitly reset mocks that have their behavior changed in tests
    const { checkRateLimit } = require("../src/utils/rateLimit");
    checkRateLimit.mockReturnValue(true);
  });

  describe("createStripeConnectAccount", () => {
    const validRequest = {
      auth: { uid: "owner-123" },
      data: {
        returnUrl: "https://app.bookbed.io/return",
        refreshUrl: "https://app.bookbed.io/refresh",
      },
    };

    const mockOwnerDoc = {
      exists: true,
      data: () => ({ email: "owner@example.com" }),
    };

    it("should create a new Stripe account if one does not exist", async () => {
      // Arrange
      mockDb.collection().doc().get.mockResolvedValue(mockOwnerDoc);
      mockStripe.accounts.create.mockResolvedValue({ id: "acct_new" });
      mockStripe.accountLinks.create.mockResolvedValue({ url: "https://stripe.com/onboard" });

      const wrapped = wrap(createStripeConnectAccount);

      // Act
      const result = await wrapped(validRequest);

      // Assert
      expect(result.success).toBe(true);
      expect(result.accountId).toBe("acct_new");
      expect(result.onboardingUrl).toBe("https://stripe.com/onboard");
      expect(mockStripe.accounts.create).toHaveBeenCalledTimes(1);
      expect(mockDb.collection().doc().update).toHaveBeenCalledWith(
        expect.objectContaining({
          stripe_account_id: "acct_new",
        })
      );
    });

    it("should use an existing Stripe account if one exists", async () => {
      // Arrange
      const existingOwnerDoc = {
        exists: true,
        data: () => ({
          email: "owner@example.com",
          stripe_account_id: "acct_existing",
        }),
      };
      mockDb.collection().doc().get.mockResolvedValue(existingOwnerDoc);
      mockStripe.accountLinks.create.mockResolvedValue({ url: "https://stripe.com/onboard-existing" });

      const wrapped = wrap(createStripeConnectAccount);

      // Act
      const result = await wrapped(validRequest);

      // Assert
      expect(result.success).toBe(true);
      expect(result.accountId).toBe("acct_existing");
      expect(result.onboardingUrl).toBe("https://stripe.com/onboard-existing");
      expect(mockStripe.accounts.create).not.toHaveBeenCalled();
      expect(mockDb.collection().doc().update).not.toHaveBeenCalled();
    });

    it("should throw an error if the user is unauthenticated", async () => {
      const wrapped = wrap(createStripeConnectAccount);
      await expect(wrapped({ data: validRequest.data })).rejects.toThrow(
        new HttpsError("unauthenticated", "User must be authenticated")
      );
    });

    it("should throw an error if rate limit is exceeded", async () => {
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(false);

      const wrapped = wrap(createStripeConnectAccount);
      await expect(wrapped(validRequest)).rejects.toThrow(
        new HttpsError("resource-exhausted", "Too many attempts. Please try again later.")
      );
    });

    it("should throw an error if the owner document is not found", async () => {
      mockDb.collection().doc().get.mockResolvedValue({ exists: false });

      const wrapped = wrap(createStripeConnectAccount);
      await expect(wrapped(validRequest)).rejects.toThrow(
        new HttpsError("not-found", "Owner not found")
      );
    });
  });

  describe("getStripeAccountStatus", () => {
    const validRequest = { auth: { uid: "owner-123" } };

    it("should return the status for a fully onboarded account", async () => {
      // Arrange
      const ownerDocWithStripe = {
        exists: true,
        data: () => ({ stripe_account_id: "acct_123" }),
      };
      const mockStripeAccount = {
        charges_enabled: true,
        payouts_enabled: true,
        email: "owner@stripe.com",
        country: "HR",
        requirements: {},
      };
      const mockStripeBalance = {
        available: [{ amount: 10000, currency: "eur" }],
        pending: [{ amount: 5000, currency: "eur" }],
      };
      mockDb.collection().doc().get.mockResolvedValue(ownerDocWithStripe);
      mockStripe.accounts.retrieve.mockResolvedValue(mockStripeAccount);
      mockStripe.balance.retrieve.mockResolvedValue(mockStripeBalance);

      const wrapped = wrap(getStripeAccountStatus);

      // Act
      const result = await wrapped(validRequest);

      // Assert
      expect(result.connected).toBe(true);
      expect(result.onboarded).toBe(true);
      expect(result.accountId).toBe("acct_123");
      expect(result.balance.available[0].amount).toBe(100); // 10000 cents -> 100 eur
      expect(mockStripe.accounts.retrieve).toHaveBeenCalledWith("acct_123");
      expect(mockStripe.balance.retrieve).toHaveBeenCalled();
    });

    it("should return not connected if no Stripe account is linked", async () => {
      // Arrange
      const ownerDocWithoutStripe = {
        exists: true,
        data: () => ({}), // No stripe_account_id
      };
      mockDb.collection().doc().get.mockResolvedValue(ownerDocWithoutStripe);

      const wrapped = wrap(getStripeAccountStatus);

      // Act
      const result = await wrapped(validRequest);

      // Assert
      expect(result.connected).toBe(false);
      expect(result.message).toBe("No Stripe account connected");
      expect(mockStripe.accounts.retrieve).not.toHaveBeenCalled();
    });

    it("should throw an error if the user is unauthenticated", async () => {
      const wrapped = wrap(getStripeAccountStatus);
      await expect(wrapped({})).rejects.toThrow(
        new HttpsError("unauthenticated", "User must be authenticated")
      );
    });

    it("should throw an error if the owner document is not found", async () => {
      mockDb.collection().doc().get.mockResolvedValue({ exists: false });

      const wrapped = wrap(getStripeAccountStatus);
      await expect(wrapped(validRequest)).rejects.toThrow(
        new HttpsError("not-found", "Owner not found")
      );
    });
  });

  describe("disconnectStripeAccount", () => {
    const validRequest = { auth: { uid: "owner-123" } };

    it("should successfully disconnect a Stripe account", async () => {
      // Arrange
      const ownerDocWithStripe = {
        exists: true,
        data: () => ({ stripe_account_id: "acct_123" }),
      };
      mockDb.collection().doc().get.mockResolvedValue(ownerDocWithStripe);

      const wrapped = wrap(disconnectStripeAccount);

      // Act
      const result = await wrapped(validRequest);

      // Assert
      expect(result.success).toBe(true);
      expect(mockDb.collection().doc().update).toHaveBeenCalledWith({
        stripe_account_id: "mock-delete-timestamp",
        stripe_connected_at: "mock-delete-timestamp",
        stripe_disconnected_at: "mock-server-timestamp",
      });
    });

    it("should throw an error if no Stripe account is connected", async () => {
      // Arrange
      const ownerDocWithoutStripe = {
        exists: true,
        data: () => ({}), // No stripe_account_id
      };
      mockDb.collection().doc().get.mockResolvedValue(ownerDocWithoutStripe);

      const wrapped = wrap(disconnectStripeAccount);

      // Act & Assert
      await expect(wrapped(validRequest)).rejects.toThrow(
        new HttpsError("failed-precondition", "No Stripe account connected")
      );
    });

    it("should throw an error if the user is unauthenticated", async () => {
      const wrapped = wrap(disconnectStripeAccount);
      await expect(wrapped({})).rejects.toThrow(
        new HttpsError("unauthenticated", "User must be authenticated")
      );
    });

    it("should throw an error if the owner document is not found", async () => {
      mockDb.collection().doc().get.mockResolvedValue({ exists: false });
      const wrapped = wrap(disconnectStripeAccount);
      await expect(wrapped(validRequest)).rejects.toThrow(
        new HttpsError("not-found", "Owner not found")
      );
    });
  });
});
