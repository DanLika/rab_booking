/**
 * Unit tests for authRateLimit.ts cloud functions.
 * Mocks rate limiting utilities and logger.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();
import { HttpsError } from "firebase-functions/v2/https";

// Import the functions to be tested
import { checkLoginRateLimit, checkRegistrationRateLimit } from "../src/authRateLimit";

// Initialize the test environment
const { wrap } = test;

// Mock dependencies
jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn(),
}));

jest.mock("../src/utils/securityMonitoring", () => ({
  logRateLimitExceeded: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logWarn: jest.fn(),
}));

describe("Auth Rate Limit Functions", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("checkLoginRateLimit", () => {
    it("should allow login if within rate limit", async () => {
      // Arrange
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(true);

      const wrapped = wrap(checkLoginRateLimit);
      const request = {
        data: { email: "test@example.com" },
        rawRequest: { ip: "127.0.0.1" },
      };

      // Act
      const result = await wrapped(request);

      // Assert
      expect(result).toEqual({ allowed: true });
      expect(checkRateLimit).toHaveBeenCalledWith(
        expect.stringContaining("login_ip_"),
        15,
        15 * 60
      );
    });

    it("should throw HttpsError if rate limit is exceeded", async () => {
      // Arrange
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(false);

      const wrapped = wrap(checkLoginRateLimit);
      const request = {
        data: { email: "test@example.com" },
        rawRequest: { ip: "127.0.0.1" },
      };

      // Act & Assert
      await expect(wrapped(request)).rejects.toThrow(
        new HttpsError("resource-exhausted", "Too many login attempts from your location. Please wait 15 minutes before trying again.")
      );

      const { logRateLimitExceeded } = require("../src/utils/securityMonitoring");
      expect(logRateLimitExceeded).toHaveBeenCalled();
    });

    it("should extract IP from x-forwarded-for header", async () => {
      // Arrange
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(true);

      const wrapped = wrap(checkLoginRateLimit);
      const request = {
        data: { email: "test@example.com" },
        rawRequest: {
          headers: { "x-forwarded-for": "192.168.1.1, 10.0.0.1" },
        },
      };

      // Act
      await wrapped(request);

      // Assert
      // 192.168.1.1 SHA-256 hash (first 16 chars) - matches ipUtils.ts hashIp()
      const crypto = require("crypto");
      const expectedIpHash = crypto.createHash("sha256").update("192.168.1.1").digest("hex").substring(0, 16);
      expect(checkRateLimit).toHaveBeenCalledWith(
        `login_ip_${expectedIpHash}`,
        expect.any(Number),
        expect.any(Number)
      );
    });
  });

  describe("checkRegistrationRateLimit", () => {
    it("should allow registration if within rate limit", async () => {
      // Arrange
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(true);

      const wrapped = wrap(checkRegistrationRateLimit);
      const request = {
        data: { email: "new@example.com" },
        rawRequest: { ip: "127.0.0.1" },
      };

      // Act
      const result = await wrapped(request);

      // Assert
      expect(result).toEqual({ allowed: true });
      expect(checkRateLimit).toHaveBeenCalledWith(
        expect.stringContaining("register_ip_"),
        5,
        60 * 60
      );
    });

    it("should throw HttpsError if registration rate limit is exceeded", async () => {
      // Arrange
      const { checkRateLimit } = require("../src/utils/rateLimit");
      checkRateLimit.mockReturnValue(false);

      const wrapped = wrap(checkRegistrationRateLimit);
      const request = {
        data: { email: "new@example.com" },
        rawRequest: { ip: "127.0.0.1" },
      };

      // Act & Assert
      await expect(wrapped(request)).rejects.toThrow(
        new HttpsError("resource-exhausted", "Too many registration attempts from your location. Please wait 1 hour before trying again.")
      );
    });
  });
});
