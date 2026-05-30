jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
}));

const originalEnv = process.env;

describe("smsService", () => {
  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
    jest.clearAllMocks();
    global.fetch = jest.fn();
  });

  afterAll(() => {
    process.env = originalEnv;
    jest.restoreAllMocks();
  });

  describe("when Twilio is not configured", () => {
    it("should return false and log info if TWILIO_ACCOUNT_SID is missing", async () => {
      process.env.TWILIO_ACCOUNT_SID = "";
      process.env.TWILIO_AUTH_TOKEN = "token";
      process.env.TWILIO_PHONE_NUMBER = "+1234567890";

      const {sendSms} = await import("../src/smsService");

      const result = await sendSms({
        to: "+0987654321",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);

      // Need to require logger dynamically to check mocks when using jest.resetModules
      const { logInfo } = await import("../src/logger");
      expect(logInfo).toHaveBeenCalledWith(
        "[SMS Service] Twilio not configured, skipping SMS",
        { ownerId: "owner-1" }
      );
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it("should return false and log info if TWILIO_AUTH_TOKEN is missing", async () => {
      process.env.TWILIO_ACCOUNT_SID = "sid";
      process.env.TWILIO_AUTH_TOKEN = "";
      process.env.TWILIO_PHONE_NUMBER = "+1234567890";

      const {sendSms} = await import("../src/smsService");

      const result = await sendSms({
        to: "+0987654321",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);
    });

    it("should return false and log info if TWILIO_PHONE_NUMBER is missing", async () => {
      process.env.TWILIO_ACCOUNT_SID = "sid";
      process.env.TWILIO_AUTH_TOKEN = "token";
      process.env.TWILIO_PHONE_NUMBER = "";

      const {sendSms} = await import("../src/smsService");

      const result = await sendSms({
        to: "+0987654321",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);
    });
  });

  describe("when Twilio is configured", () => {
    beforeEach(() => {
      process.env.TWILIO_ACCOUNT_SID = "test_sid";
      process.env.TWILIO_AUTH_TOKEN = "test_token";
      process.env.TWILIO_PHONE_NUMBER = "+1234567890";
    });

    it("should return false and log error if phone number is invalid", async () => {
      const {sendSms} = await import("../src/smsService");

      const result = await sendSms({
        to: "invalid-phone",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);

      const { logError } = await import("../src/logger");
      expect(logError).toHaveBeenCalledWith(
        "[SMS Service] Invalid phone number format",
        null,
        { to: "invalid-phone", ownerId: "owner-1" }
      );
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it("should return false and log error if message is too long", async () => {
      const {sendSms} = await import("../src/smsService");
      const longMessage = "a".repeat(1601);

      const result = await sendSms({
        to: "+0987654321",
        message: longMessage,
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);

      const { logError } = await import("../src/logger");
      expect(logError).toHaveBeenCalledWith(
        "[SMS Service] Message too long",
        null,
        { messageLength: 1601, ownerId: "owner-1" }
      );
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it("should return true and log success if fetch succeeds", async () => {
      const {sendSms} = await import("../src/smsService");
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
      });

      const result = await sendSms({
        to: "+0987654321",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(true);

      const { logInfo, logSuccess } = await import("../src/logger");
      expect(logInfo).toHaveBeenCalledWith(
        "[SMS Service] Sending SMS",
        { to: "+0987654321", ownerId: "owner-1", messageLength: 12 }
      );
      expect(global.fetch).toHaveBeenCalledWith(
        "https://api.twilio.com/2010-04-01/Accounts/test_sid/Messages.json",
        expect.objectContaining({
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": `Basic ${Buffer.from("test_sid:test_token").toString("base64")}`,
          },
          body: new URLSearchParams({
            From: "+1234567890",
            To: "+0987654321",
            Body: "Test message",
          }),
        })
      );
      expect(logSuccess).toHaveBeenCalledWith(
        "[SMS Service] SMS sent successfully",
        { to: "+0987654321", ownerId: "owner-1" }
      );
    });

    it("should return false and log error if fetch returns not ok", async () => {
      const {sendSms} = await import("../src/smsService");
      const mockText = jest.fn().mockResolvedValue("Unauthorized");
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: false,
        status: 401,
        text: mockText,
      });

      const result = await sendSms({
        to: "+0987654321",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);
      expect(mockText).toHaveBeenCalled();

      const { logError } = await import("../src/logger");
      expect(logError).toHaveBeenCalledWith(
        "[SMS Service] Twilio API error",
        null,
        { status: 401, error: "Unauthorized" }
      );
    });

    it("should return false and log error if fetch throws an exception", async () => {
      const {sendSms} = await import("../src/smsService");
      const networkError = new Error("Network Error");
      (global.fetch as jest.Mock).mockRejectedValue(networkError);

      const result = await sendSms({
        to: "+0987654321",
        message: "Test message",
        ownerId: "owner-1",
        category: "bookings",
      });

      expect(result).toBe(false);

      const { logError } = await import("../src/logger");
      expect(logError).toHaveBeenCalledWith(
        "[SMS Service] Error sending SMS",
        networkError,
        { to: "+0987654321", ownerId: "owner-1" }
      );
    });
  });
});
