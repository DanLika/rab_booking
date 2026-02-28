const test = require("firebase-functions-test")();
// Setup mocks inside the factory to avoid hoisting issues
jest.mock("firebase-admin/firestore", () => {
  const mockFirestoreInstance = {
    runTransaction: jest.fn(),
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn(),
    update: jest.fn(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  return {
    getFirestore: firestoreFn,
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("mock-timestamp"),
      increment: jest.fn().mockImplementation((val) => ({ _increment: val })),
    },
  };
});

jest.mock("../src/emailService", () => ({
  sendEmailVerificationCode: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn(),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
  logOperation: jest.fn(),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

import { sendEmailVerificationCode, verifyEmailCode, checkEmailVerificationStatus } from "../src/emailVerification";
import { checkRateLimit } from "../src/utils/rateLimit";
import { getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

const { wrap } = test;

describe("emailVerification", () => {
  const mockDb = getFirestore() as any;

  beforeEach(() => {
    jest.clearAllMocks();
    (checkRateLimit as jest.Mock).mockReturnValue(true);
    mockDb.collection.mockReturnThis();
    mockDb.doc.mockReturnThis();
  });

  describe("sendEmailVerificationCode", () => {
    const validRequest = {
      data: { email: "test@example.com" },
      rawRequest: { ip: "127.0.0.1", headers: {} }
    };

    it("should throw rate limit error if exceeded", async () => {
      (checkRateLimit as jest.Mock).mockReturnValueOnce(false);

      const wrapped = wrap(sendEmailVerificationCode);
      await expect(wrapped(validRequest as any)).rejects.toThrow(
        new HttpsError("resource-exhausted", "Too many requests from your location. Please try again later.")
      );
    });

    it("should throw invalid-argument if email is missing or invalid", async () => {
      const wrapped = wrap(sendEmailVerificationCode);
      await expect(wrapped({ data: {}, rawRequest: {} } as any)).rejects.toThrow(
        new HttpsError("invalid-argument", "Email is required")
      );

      await expect(wrapped({ data: { email: "not-an-email" }, rawRequest: {} } as any)).rejects.toThrow(
        new HttpsError("invalid-argument", "Invalid email format. Please enter a valid email address.")
      );
    });

    it("should send verification code successfully", async () => {
      // Mock successful transaction result
      mockDb.runTransaction.mockImplementationOnce(async (callback: any) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({ exists: false }),
          set: jest.fn(),
          update: jest.fn(),
        };
        await callback(mockTransaction);
      });

      const wrapped = wrap(sendEmailVerificationCode);
      const result = await wrapped(validRequest as any);

      expect(result.success).toBe(true);
      expect(mockDb.runTransaction).toHaveBeenCalled();
    });
  });

  describe("verifyEmailCode", () => {
    const validRequest = {
      data: { email: "test@example.com", code: "123456" }
    };

    it("should verify code successfully", async () => {
       mockDb.runTransaction.mockImplementationOnce(async () => {
         return { verified: true };
       });

       const wrapped = wrap(verifyEmailCode);
       const result = await wrapped(validRequest as any);

       expect(result.success).toBe(true);
       expect(result.verified).toBe(true);
    });

    it("should return alreadyVerified if applicable", async () => {
       mockDb.runTransaction.mockImplementationOnce(async () => {
         return { alreadyVerified: true };
       });

       const wrapped = wrap(verifyEmailCode);
       const result = await wrapped(validRequest as any);

       expect(result.success).toBe(true);
       expect(result.message).toBe("Email already verified");
    });
  });

  describe("checkEmailVerificationStatus", () => {
    it("should return false if document not found", async () => {
      mockDb.get.mockResolvedValueOnce({ exists: false });

      const wrapped = wrap(checkEmailVerificationStatus);
      const result = await wrapped({ data: { email: "test@example.com" } } as any);

      expect(result.verified).toBe(false);
      expect(result.exists).toBe(false);
    });

    it("should return true if verified and not expired", async () => {
      const futureDate = new Date();
      futureDate.setMinutes(futureDate.getMinutes() + 10);

      mockDb.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          verified: true,
          expiresAt: { toDate: () => futureDate },
          verifiedAt: { toDate: () => new Date() },
          sessionId: "session-123"
        })
      });

      const wrapped = wrap(checkEmailVerificationStatus);
      const result = await wrapped({ data: { email: "test@example.com" } } as any);

      expect(result.verified).toBe(true);
      expect(result.exists).toBe(true);
      expect(result.expired).toBe(false);
    });
  });
});
