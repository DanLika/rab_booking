import { sendSMSNotification } from "../src/smsService";
import { HttpsError } from "firebase-functions/v2/https";
import * as rateLimit from "../src/utils/rateLimit";

const test = require("firebase-functions-test")();
const { wrap } = test;

// Mock the dependencies
jest.mock("../src/utils/rateLimit");
jest.mock("../src/logger");

describe("SMS Service", () => {
  const wrapped = wrap(sendSMSNotification);

  const mockRequest = (data: any, auth: any = { uid: "user123" }) => ({
    data,
    auth,
    rawRequest: { ip: "127.0.0.1" },
  } as any);

  beforeEach(() => {
    jest.clearAllMocks();
    (rateLimit.enforceRateLimit as jest.Mock).mockResolvedValue(undefined);
  });

  afterAll(() => {
    test.cleanup();
  });

  describe("sendSMSNotification", () => {
    it("should throw unauthenticated error if no auth", async () => {
      const req = mockRequest({ to: "+1234567890", message: "test", category: "bookings" }, null);
      await expect(wrapped(req)).rejects.toThrow(HttpsError);
      await expect(wrapped(req)).rejects.toMatchObject({
        code: "unauthenticated",
      });
    });

    it("should throw invalid-argument if missing phone number", async () => {
      const req = mockRequest({ message: "test", category: "bookings" });
      await expect(wrapped(req)).rejects.toThrow(HttpsError);
      await expect(wrapped(req)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });

    it("should throw invalid-argument if message is empty", async () => {
      const req = mockRequest({ to: "+1234567890", message: "", category: "bookings" });
      await expect(wrapped(req)).rejects.toThrow(HttpsError);
      await expect(wrapped(req)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });

    it("should throw invalid-argument if invalid category", async () => {
      const req = mockRequest({ to: "+1234567890", message: "test", category: "invalid" });
      await expect(wrapped(req)).rejects.toThrow(HttpsError);
      await expect(wrapped(req)).rejects.toMatchObject({
        code: "invalid-argument",
      });
    });

    it("should enforce rate limit and attempt to send SMS", async () => {
      const req = mockRequest({ to: "+1234567890", message: "test message", category: "bookings" });

      // We expect it to throw internal because Twilio is not configured,
      // thus sendSms returns false. But rateLimit should still be called.
      await expect(wrapped(req)).rejects.toThrow(HttpsError);
      await expect(wrapped(req)).rejects.toMatchObject({
        code: "internal"
      });

      expect(rateLimit.enforceRateLimit).toHaveBeenCalledWith(
        "user123",
        "send_sms_notification",
        expect.any(Object)
      );
    });
  });
});
