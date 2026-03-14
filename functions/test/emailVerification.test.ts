const test = require("firebase-functions-test")();

jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn(),
    update: jest.fn(),
    runTransaction: jest.fn(),
  };

  return {
    getFirestore: jest.fn(() => mockFirestoreInstance),
  };
});

jest.mock("firebase-admin/firestore", () => {
  return {
    getFirestore: jest.fn(),
    FieldValue: {
      serverTimestamp: jest.fn().mockReturnValue("mocked-timestamp"),
      increment: jest.fn().mockReturnValue("mocked-increment"),
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

jest.mock("../src/emailService", () => ({
  sendEmailVerificationCode: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

jest.mock("../src/utils/ipUtils", () => ({
  getClientIp: jest.fn().mockReturnValue("127.0.0.1"),
  hashIp: jest.fn().mockReturnValue("hash-127.0.0.1"),
}));

import { sendEmailVerificationCode, verifyEmailCode } from "../src/emailVerification";
import { getFirestore } from "firebase-admin/firestore";
import { checkRateLimit } from "../src/utils/rateLimit";
import * as emailService from "../src/emailService";

const { wrap } = test;

describe("emailVerification", () => {
  let mockDb: any;

  beforeEach(() => {
    jest.clearAllMocks();
    (checkRateLimit as jest.Mock).mockReturnValue(true);

    mockDb = {
      collection: jest.fn().mockReturnThis(),
      doc: jest.fn().mockReturnThis(),
      get: jest.fn(),
      set: jest.fn(),
      update: jest.fn(),
      runTransaction: jest.fn(),
    };
    (getFirestore as jest.Mock).mockReturnValue(mockDb);
  });

  describe("sendEmailVerificationCode", () => {
    it("should fail if email is missing", async () => {
      const wrapped = wrap(sendEmailVerificationCode);
      await expect(wrapped({ data: {} })).rejects.toThrow("Email is required");
    });

    it("should fail if email format is invalid", async () => {
      const wrapped = wrap(sendEmailVerificationCode);
      await expect(wrapped({ data: { email: "invalid-email" } })).rejects.toThrow("Invalid email format");
    });

    it("should fail if IP rate limit is exceeded", async () => {
      (checkRateLimit as jest.Mock).mockReturnValueOnce(false);
      const wrapped = wrap(sendEmailVerificationCode);
      await expect(wrapped({ data: { email: "test@example.com" } })).rejects.toThrow("Too many requests from your location");
    });

    it("should successfully create and send verification code (new user)", async () => {
      mockDb.runTransaction.mockImplementationOnce(async (cb: any) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({ exists: false }),
          set: jest.fn(),
          update: jest.fn(),
        };
        await cb(mockTransaction);
        expect(mockTransaction.set).toHaveBeenCalled();
      });

      const wrapped = wrap(sendEmailVerificationCode);
      const result = await wrapped({ data: { email: "test@example.com" } });

      expect(result.success).toBe(true);
      expect(emailService.sendEmailVerificationCode).toHaveBeenCalled();
    });

    it("should successfully update and send verification code (existing user)", async () => {
      mockDb.runTransaction.mockImplementationOnce(async (cb: any) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              lastSentAt: { toDate: () => new Date(Date.now() - 120000) }, // 2 minutes ago
              dailyCount: 1,
            }),
          }),
          set: jest.fn(),
          update: jest.fn(),
        };
        await cb(mockTransaction);
        expect(mockTransaction.update).toHaveBeenCalled();
      });

      const wrapped = wrap(sendEmailVerificationCode);
      const result = await wrapped({ data: { email: "test@example.com" } });

      expect(result.success).toBe(true);
      expect(emailService.sendEmailVerificationCode).toHaveBeenCalled();
    });

    it("should fail if cooldown hasn't expired", async () => {
      mockDb.runTransaction.mockImplementationOnce(async (cb: any) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              lastSentAt: { toDate: () => new Date(Date.now() - 30000) }, // 30 seconds ago (needs 60)
              dailyCount: 1,
            }),
          }),
        };
        await cb(mockTransaction);
      });

      const wrapped = wrap(sendEmailVerificationCode);
      await expect(wrapped({ data: { email: "test@example.com" } })).rejects.toThrow("Please wait 60 seconds");
    });
  });

  describe("verifyEmailCode", () => {
    it("should fail if code or email is missing", async () => {
      const wrapped = wrap(verifyEmailCode);
      await expect(wrapped({ data: { email: "test@example.com" } })).rejects.toThrow("Code is required");
      await expect(wrapped({ data: { code: "123456" } })).rejects.toThrow("Email is required");
    });

    it("should verify successfully for correct code", async () => {
      mockDb.runTransaction.mockImplementationOnce(async (cb: any) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              code: "123456",
              expiresAt: { toDate: () => new Date(Date.now() + 60000) }, // not expired
              attempts: 0,
              verified: false,
            }),
          }),
          update: jest.fn(),
        };
        const res = await cb(mockTransaction);
        expect(mockTransaction.update).toHaveBeenCalled();
        return res;
      });

      const wrapped = wrap(verifyEmailCode);
      const result = await wrapped({ data: { email: "test@example.com", code: "123456" } });
      expect(result.success).toBe(true);
      expect(result.verified).toBe(true);
    });

    it("should fail and increment attempts for incorrect code", async () => {
      mockDb.runTransaction.mockImplementationOnce(async (cb: any) => {
        const mockTransaction = {
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({
              code: "123456",
              expiresAt: { toDate: () => new Date(Date.now() + 60000) },
              attempts: 0,
              verified: false,
            }),
          }),
          update: jest.fn(),
        };
        return await cb(mockTransaction);
      });

      const wrapped = wrap(verifyEmailCode);
      await expect(wrapped({ data: { email: "test@example.com", code: "000000" } })).rejects.toThrow("Invalid code. 2 attempts remaining.");
    });
  });
});
