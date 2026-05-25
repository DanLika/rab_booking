// Logger F-50-04 scrub regression test.
//
// Verifies that `error.stack` is NOT included in the Cloud Logging payload
// when an Error is passed to `logError`. The full Error (with stack) is still
// shipped to Sentry via `captureException`, which is the appropriate sink.

import { HttpsError } from "firebase-functions/v2/https";

// Capture what gets sent to functions.logger.error so we can assert on it.
const loggerErrorMock = jest.fn();
const loggerWarnMock = jest.fn();

jest.mock("firebase-functions", () => ({
  logger: {
    info: jest.fn(),
    debug: jest.fn(),
    warn: (...args: unknown[]) => loggerWarnMock(...args),
    error: (...args: unknown[]) => loggerErrorMock(...args),
  },
}));

jest.mock("../src/sentry", () => ({
  captureException: jest.fn(),
  addBreadcrumb: jest.fn(),
}));

import { logError } from "../src/logger";

describe("logger F-50-04 stack scrub", () => {
  beforeEach(() => {
    loggerErrorMock.mockClear();
    loggerWarnMock.mockClear();
  });

  it("does NOT include error.stack in Cloud Logging payload for plain Error", () => {
    const err = new Error("boom");
    // Sanity: real Error has a stack.
    expect(typeof err.stack).toBe("string");
    expect(err.stack!.length).toBeGreaterThan(0);

    logError("operation failed", err, { userId: "u-1" });

    expect(loggerErrorMock).toHaveBeenCalledTimes(1);
    const [message, payload] = loggerErrorMock.mock.calls[0];
    expect(message).toBe("operation failed");
    expect(payload.userId).toBe("u-1");
    expect(payload.error).toEqual({
      message: "boom",
      name: "Error",
    });
    expect(payload.error).not.toHaveProperty("stack");
  });

  it("preserves error.code on HttpsError server-fault paths (not stack)", () => {
    // `internal` is a server-fault code: Cloud Logging gets full error object
    // (without stack), Sentry receives the full Error via captureException.
    const err = new HttpsError("internal", "db unavailable");
    logError("write failed", err);

    expect(loggerErrorMock).toHaveBeenCalledTimes(1);
    const [, payload] = loggerErrorMock.mock.calls[0];
    expect(payload.error.code).toBe("internal");
    expect(payload.error.message).toBe("db unavailable");
    // Note: HttpsError sets .name to "Error" upstream — assert on .code instead.
    expect(payload.error).not.toHaveProperty("stack");
  });

  it("client-fault HttpsError still scrubs stack (downgraded to WARN)", () => {
    // `invalid-argument` is a client-fault code → routed to functions.logger.warn
    // per existing CLIENT_FAULT_HTTPS_CODES gate, but stack scrub applies before
    // the WARN dispatch so payload.error must still lack `stack`.
    const err = new HttpsError("invalid-argument", "bad payload");
    logError("validation failed", err, { field: "email" });

    expect(loggerWarnMock).toHaveBeenCalledTimes(1);
    expect(loggerErrorMock).not.toHaveBeenCalled();
    const [, payload] = loggerWarnMock.mock.calls[0];
    expect(payload.error.code).toBe("invalid-argument");
    expect(payload.error).not.toHaveProperty("stack");
  });
});
