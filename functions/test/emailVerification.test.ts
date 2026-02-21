const test = require("firebase-functions-test")();

// Mock dependencies
const mockFirestoreInstance = {
  collection: jest.fn().mockReturnThis(),
  doc: jest.fn().mockReturnThis(),
  runTransaction: jest.fn(),
  update: jest.fn(),
  set: jest.fn(),
  get: jest.fn(),
};

jest.mock("firebase-admin", () => {
  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("MOCK_TIMESTAMP"),
      increment: jest.fn(),
    },
  });
  return {
    getFirestore: firestoreFn,
    initializeApp: jest.fn(),
  };
});

// Also mock firebase-admin/firestore
jest.mock("firebase-admin/firestore", () => {
  const firestoreFn = jest.fn(() => mockFirestoreInstance);
  Object.assign(firestoreFn, {
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("MOCK_TIMESTAMP"),
      increment: jest.fn(),
    },
    getFirestore: firestoreFn,
  });
  return {
    getFirestore: firestoreFn,
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("MOCK_TIMESTAMP"),
      increment: jest.fn(),
    },
  };
});

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

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/ipUtils", () => ({
  getClientIp: jest.fn().mockReturnValue("127.0.0.1"),
  hashIp: jest.fn().mockReturnValue("hash-127.0.0.1"),
}));

jest.mock("../src/emailService", () => ({
  sendEmailVerificationCode: jest.fn(),
}));

jest.mock("../src/utils/emailValidation", () => ({
  validateEmail: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/utils/inputSanitization", () => ({
  sanitizeEmail: jest.fn((e) => e.trim().toLowerCase()),
}));

import { sendEmailVerificationCode, verifyEmailCode } from "../src/emailVerification";
import { checkRateLimit } from "../src/utils/rateLimit";
import { sendEmailVerificationCode as sendEmailService } from "../src/emailService";

const { wrap } = test;

describe("Email Verification", () => {
  const mockDb = mockFirestoreInstance as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb.collection.mockReturnThis();
    mockDb.doc.mockReturnThis();
    (checkRateLimit as jest.Mock).mockReturnValue(true);
  });

  describe("sendEmailVerificationCode", () => {
    const wrapped = wrap(sendEmailVerificationCode);
    const validData = { email: "test@example.com" };

    it("should throw error if rate limit exceeded", async () => {
      (checkRateLimit as jest.Mock).mockReturnValue(false);
      await expect(wrapped({ data: validData })).rejects.toThrow("Too many requests");
    });

    it("should throw error if email missing", async () => {
      await expect(wrapped({ data: {} })).rejects.toThrow("Email is required");
    });

    it("should send verification code successfully", async () => {
      // Mock transaction
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const mockTx = {
          get: jest.fn().mockResolvedValue({ exists: false }),
          set: jest.fn(),
          update: jest.fn(),
        };
        return callback(mockTx);
      });

      const result = await wrapped({ data: validData });

      expect(result.success).toBe(true);
      expect(result.message).toContain("sent successfully");
      expect(sendEmailService).toHaveBeenCalled();
    });

    it("should enforce daily limit", async () => {
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const mockTx = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              dailyCount: 20, // Limit exceeded
              createdAt: { toDate: () => new Date() }, // Today
            }),
          }),
          set: jest.fn(),
          update: jest.fn(),
        };
        return callback(mockTx);
      });

      // Wrapped function re-throws "resource-exhausted" error
      // Note: The function implementation re-throws HttpsError as is.
      await expect(wrapped({ data: validData })).rejects.toThrow("Too many verification attempts");
    });
  });

  describe("verifyEmailCode", () => {
    const wrapped = wrap(verifyEmailCode);
    const validData = { email: "test@example.com", code: "123456" };

    it("should verify code successfully", async () => {
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const mockTx = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              code: "123456",
              verified: false,
              attempts: 0,
              expiresAt: { toDate: () => new Date(Date.now() + 10000) }, // Future
            }),
          }),
          update: jest.fn(),
        };
        return callback(mockTx);
      });

      const result = await wrapped({ data: validData });

      expect(result.success).toBe(true);
      expect(result.verified).toBe(true);
    });

    it("should fail if code incorrect", async () => {
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const mockTx = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              code: "654321", // Different
              verified: false,
              attempts: 0,
              expiresAt: { toDate: () => new Date(Date.now() + 10000) },
            }),
          }),
          update: jest.fn(),
        };
        return callback(mockTx);
      });

      await expect(wrapped({ data: validData })).rejects.toThrow("Invalid code");
    });

    it("should fail if expired", async () => {
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const mockTx = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              code: "123456",
              verified: false,
              attempts: 0,
              expiresAt: { toDate: () => new Date(Date.now() - 10000) }, // Past
            }),
          }),
          update: jest.fn(),
        };
        return callback(mockTx);
      });

      await expect(wrapped({ data: validData })).rejects.toThrow("Verification code expired");
    });

    it("should fail if max attempts exceeded", async () => {
      mockDb.runTransaction.mockImplementation(async (callback: any) => {
        const mockTx = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              code: "123456",
              verified: false,
              attempts: 3, // Max
              expiresAt: { toDate: () => new Date(Date.now() + 10000) },
            }),
          }),
          update: jest.fn(),
        };
        return callback(mockTx);
      });

      await expect(wrapped({ data: validData })).rejects.toThrow("Too many failed attempts");
    });
  });
});
