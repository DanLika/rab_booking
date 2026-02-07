/**
 * Unit tests for passwordHistory.ts cloud functions.
 * Mocks Firebase Admin, Bcrypt, and Logger.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();
import { HttpsError } from "firebase-functions/v2/https";

// Mock dependencies before importing functions
jest.mock("firebase-admin", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn().mockResolvedValue(true),
  };
  const firestore = jest.fn().mockReturnValue(mockFirestoreInstance);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (firestore as any).FieldValue = {
    serverTimestamp: () => "mock-timestamp",
  };
  return {
    firestore,
  };
});

jest.mock("bcrypt", () => ({
  hash: jest.fn().mockResolvedValue("hashed-password"),
  compare: jest.fn(),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

// Import the functions to be tested
import { checkPasswordHistory, savePasswordToHistory } from "../src/passwordHistory";

// Initialize the test environment
const { wrap } = test;

describe("Password History Functions", () => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let mockDb: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockDb = require("firebase-admin").firestore();
  });

  describe("checkPasswordHistory", () => {
    it("should allow a password that has not been used before", async () => {
      // Arrange
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({ hashes: ["hash1", "hash2"] }),
      });
      const bcrypt = require("bcrypt");
      bcrypt.compare.mockResolvedValue(false); // No match

      const wrapped = wrap(checkPasswordHistory);
      const request = {
        auth: { uid: "user-123" },
        data: { password: "new-password" },
      };

      // Act
      const result = await wrapped(request);

      // Assert
      expect(result).toEqual({ allowed: true });
      expect(bcrypt.compare).toHaveBeenCalledTimes(2);
    });

    it("should allow a password if no history exists", async () => {
      // Arrange
      mockDb.get.mockResolvedValue({
        exists: false,
      });

      const wrapped = wrap(checkPasswordHistory);
      const result = await wrapped({
        auth: { uid: "user-123" },
        data: { password: "new-password" },
      });

      expect(result).toEqual({ allowed: true });
    });

    it("should throw HttpsError if password was recently used", async () => {
      // Arrange
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({ hashes: ["hash1", "hash2"] }),
      });
      const bcrypt = require("bcrypt");
      bcrypt.compare.mockImplementation(async (pw: string, hash: string) => {
        return hash === "hash2"; // Match on the second hash
      });

      const wrapped = wrap(checkPasswordHistory);
      const request = {
        auth: { uid: "user-123" },
        data: { password: "old-password" },
      };

      // Act & Assert
      await expect(wrapped(request)).rejects.toThrow(
        new HttpsError("failed-precondition", "You cannot reuse a recently used password. Please choose a different password.")
      );
    });

    it("should throw unauthenticated error if user is not logged in", async () => {
      const wrapped = wrap(checkPasswordHistory);
      await expect(wrapped({ data: { password: "password" } })).rejects.toThrow(
        new HttpsError("unauthenticated", "User must be authenticated")
      );
    });

    it("should throw invalid-argument if password is missing", async () => {
      const wrapped = wrap(checkPasswordHistory);
      await expect(wrapped({ auth: { uid: "user-123" }, data: {} })).rejects.toThrow(
        new HttpsError("invalid-argument", "Password is required")
      );
    });
  });

  describe("savePasswordToHistory", () => {
    it("should save a new password hash to history", async () => {
      // Arrange
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({ hashes: ["hash1", "hash2"] }),
      });
      const bcrypt = require("bcrypt");
      bcrypt.hash.mockResolvedValue("new-hash");

      const wrapped = wrap(savePasswordToHistory);
      const request = {
        auth: { uid: "user-123" },
        data: { password: "new-password" },
      };

      // Act
      const result = await wrapped(request);

      // Assert
      expect(result).toEqual({ success: true });
      expect(mockDb.set).toHaveBeenCalledWith({
        hashes: ["hash1", "hash2", "new-hash"],
        updatedAt: "mock-timestamp",
      });
    });

    it("should truncate history to 5 latest passwords", async () => {
      // Arrange
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({ hashes: ["h1", "h2", "h3", "h4", "h5"] }),
      });
      const bcrypt = require("bcrypt");
      bcrypt.hash.mockResolvedValue("h6");

      const wrapped = wrap(savePasswordToHistory);
      const request = {
        auth: { uid: "user-123" },
        data: { password: "p6" },
      };

      // Act
      await wrapped(request);

      // Assert
      expect(mockDb.set).toHaveBeenCalledWith({
        hashes: ["h2", "h3", "h4", "h5", "h6"],
        updatedAt: "mock-timestamp",
      });
    });

    it("should create new history if none exists", async () => {
      // Arrange
      mockDb.get.mockResolvedValue({ exists: false });
      const bcrypt = require("bcrypt");
      bcrypt.hash.mockResolvedValue("first-hash");

      const wrapped = wrap(savePasswordToHistory);
      await wrapped({
        auth: { uid: "user-123" },
        data: { password: "first-password" },
      });

      expect(mockDb.set).toHaveBeenCalledWith({
        hashes: ["first-hash"],
        updatedAt: "mock-timestamp",
      });
    });
  });
});
