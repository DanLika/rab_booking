import * as admin from "firebase-admin";

// Mock external dependencies BEFORE importing the module
jest.mock("firebase-admin", () => {
  const mockSet = jest.fn();
  const mockUpdate = jest.fn();
  const mockGet = jest.fn();

  const mockDoc = jest.fn(() => ({
    get: mockGet,
    set: mockSet,
    update: mockUpdate,
  }));

  const mockCollection = jest.fn(() => ({
    doc: mockDoc,
  }));

  const mockRunTransaction = jest.fn(async (callback) => {
    // For transactions, we provide a mock transaction object
    const mockTransaction = {
      get: mockGet,
      set: mockSet,
      update: mockUpdate,
    };
    return callback(mockTransaction);
  });

  const mockFirestore = jest.fn(() => ({
    collection: mockCollection,
    runTransaction: mockRunTransaction,
  })) as any;

  const mockIncrement = jest.fn((val) => val);
  const mockServerTimestamp = jest.fn(() => new Date());

  mockFirestore.FieldValue = {
    increment: mockIncrement,
    serverTimestamp: mockServerTimestamp,
  };

  return {
    firestore: mockFirestore,
    getFirestore: mockFirestore,
    FieldValue: mockFirestore.FieldValue,
    initializeApp: jest.fn(),
    apps: { length: 1 },
  };
});

jest.mock("firebase-admin/firestore", () => {
  const admin = require("firebase-admin");
  return {
    getFirestore: admin.getFirestore,
    FieldValue: admin.FieldValue,
  };
});

jest.mock("../src/emailService", () => ({
  sendEmailVerificationCode: jest.fn().mockResolvedValue(true),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logOperation: jest.fn(),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

// Now import the module
import { sendEmailVerificationCode, verifyEmailCode } from "../src/emailVerification";
import { checkRateLimit } from "../src/utils/rateLimit";
import { sendEmailVerificationCode as sendVerificationEmail } from "../src/emailService";
import { HttpsError } from "firebase-functions/v2/https";

describe("emailVerification", () => {
  let db: any;
  let mockGet: jest.Mock;
  let mockSet: jest.Mock;
  let mockUpdate: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    db = admin.firestore();
    mockGet = db.collection().doc().get as jest.Mock;
    mockSet = db.collection().doc().set as jest.Mock;
    mockUpdate = db.collection().doc().update as jest.Mock;
  });

  // Wrap callable functions correctly for testing
  const wrapFunction = (fn: any) => {
    return async (data: any, context?: any) => {
      // Simulate callable context
      const req = {
        data: data.data || data,
        rawRequest: data.rawRequest || { ip: "127.0.0.1", headers: {} },
      };

      // Need to execute the actual wrapped handler
      // The wrapping returns an Express middleware that expects (req, res)
      // but test wrappers typically expose a .run method
      if (fn.run) {
        return fn.run(req);
      }

      // If .run is not available, try to handle it as the unwrapped function
      // (This applies depending on how firebase-functions handles its wrapper)
      try {
        return await fn(req);
      } catch (err) {
        throw err;
      }
    };
  };

  describe("sendEmailVerificationCode", () => {
    const validRequest = {
      data: { email: "test@example.com" },
      rawRequest: { ip: "127.0.0.1", headers: {} },
    };

    it("should throw error if email is missing", async () => {
      const req = { data: {}, rawRequest: { ip: "127.0.0.1" } };
      await expect(wrapFunction(sendEmailVerificationCode)(req)).rejects.toThrow(
        new HttpsError("invalid-argument", "Email is required")
      );
    });

    it("should throw error if email format is invalid", async () => {
      const req = { data: { email: "invalid-email" }, rawRequest: { ip: "127.0.0.1" } };
      await expect(wrapFunction(sendEmailVerificationCode)(req)).rejects.toThrow(
        new HttpsError("invalid-argument", "Invalid email format. Please enter a valid email address.")
      );
    });

    it("should throw resource-exhausted if IP rate limit exceeded", async () => {
      (checkRateLimit as jest.Mock).mockReturnValueOnce(false);

      await expect(wrapFunction(sendEmailVerificationCode)(validRequest)).rejects.toThrow(
        new HttpsError("resource-exhausted", "Too many requests from your location. Please try again later.")
      );
    });

    it("should create new verification doc if it doesn't exist", async () => {
      mockGet.mockResolvedValueOnce({ exists: false });

      const result = await wrapFunction(sendEmailVerificationCode)(validRequest);

      expect(mockSet).toHaveBeenCalled();
      const setData = mockSet.mock.calls[0][1];
      expect(setData.email).toBe("test@example.com");
      expect(setData.code).toMatch(/^[0-9]{6}$/); // 6 digits
      expect(setData.verified).toBe(false);
      expect(sendVerificationEmail).toHaveBeenCalledWith("test@example.com", setData.code);
      expect(result.success).toBe(true);
    });

    it("should throw if requested too soon (cooldown)", async () => {
      // Create a doc where lastSentAt was just 10 seconds ago
      const recentTime = new Date(Date.now() - 10000);
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          lastSentAt: { toDate: () => recentTime },
          dailyCount: 1
        })
      });

      await expect(wrapFunction(sendEmailVerificationCode)(validRequest)).rejects.toThrow(/Please wait .* seconds/);
    });

    it("should throw if daily limit exceeded", async () => {
      // Simulate existing doc on same day with 20 attempts
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          lastSentAt: { toDate: () => new Date(Date.now() - 100000) }, // past cooldown
          createdAt: { toDate: () => new Date() }, // same day
          dailyCount: 20
        })
      });

      await expect(wrapFunction(sendEmailVerificationCode)(validRequest)).rejects.toThrow(/Too many verification attempts/);
    });
  });

  describe("verifyEmailCode", () => {
    const validRequest = {
      data: { email: "test@example.com", code: "123456" }
    };

    it("should throw if code is missing", async () => {
      const req = { data: { email: "test@example.com" } };
      await expect(wrapFunction(verifyEmailCode)(req)).rejects.toThrow(
        new HttpsError("invalid-argument", "Code is required")
      );
    });

    it("should throw if no verification found", async () => {
      mockGet.mockResolvedValueOnce({ exists: false });
      await expect(wrapFunction(verifyEmailCode)(validRequest)).rejects.toThrow(/No verification code found/);
    });

    it("should return success immediately if already verified", async () => {
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({ verified: true })
      });

      const result = await wrapFunction(verifyEmailCode)(validRequest);
      expect(result.success).toBe(true);
      expect(result.message).toBe("Email already verified");
    });

    it("should throw if code is expired", async () => {
      const expiredTime = new Date(Date.now() - 10000); // in the past
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          verified: false,
          expiresAt: { toDate: () => expiredTime }
        })
      });

      await expect(wrapFunction(verifyEmailCode)(validRequest)).rejects.toThrow(/Verification code expired/);
    });

    it("should throw if max attempts reached", async () => {
      const futureTime = new Date(Date.now() + 100000); // not expired
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          verified: false,
          expiresAt: { toDate: () => futureTime },
          attempts: 3 // MAX_ATTEMPTS
        })
      });

      await expect(wrapFunction(verifyEmailCode)(validRequest)).rejects.toThrow(/Too many failed attempts/);
    });

    it("should increment attempts and throw if code is wrong", async () => {
      const futureTime = new Date(Date.now() + 100000);
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          verified: false,
          expiresAt: { toDate: () => futureTime },
          attempts: 0,
          code: "654321" // different from request (123456)
        })
      });

      await expect(wrapFunction(verifyEmailCode)(validRequest)).rejects.toThrow(/Invalid code/);
      expect(mockUpdate).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        attempts: 1
      }));
    });

    it("should verify successfully on correct code", async () => {
      const futureTime = new Date(Date.now() + 100000);
      mockGet.mockResolvedValueOnce({
        exists: true,
        data: () => ({
          verified: false,
          expiresAt: { toDate: () => futureTime },
          attempts: 0,
          code: "123456" // matches request
        })
      });

      const result = await wrapFunction(verifyEmailCode)(validRequest);

      expect(mockUpdate).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({
        verified: true
      }));
      expect(result.success).toBe(true);
      expect(result.verified).toBe(true);
    });
  });
});
