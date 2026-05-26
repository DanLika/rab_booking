/**
 * Tests for functions/src/logger.ts — F-50-04 v2.
 *
 * Two leak paths covered:
 *   Path 1 — explicit `logData.error.stack` field (PR #483 scope; carried forward).
 *   Path 2 — firebase-functions/logger entryFromArgs wrap, which synthesizes
 *            `new Error(msg).stack` into jsonPayload.message when severity === "ERROR"
 *            and no Error instance is in args. v2 fix: route ERROR through
 *            `functions.logger.write({severity: "ERROR", ...})` which bypasses
 *            entryFromArgs entirely.
 *
 * Unit-test caveat: write() is asserted with a plain string `message`. The actual
 * "entryFromArgs is bypassed" property is firebase-functions's contract, validated
 * via the smoke gate (audit/50-f-50-04-addendum.md).
 */

import * as functions from "firebase-functions";
import {HttpsError} from "firebase-functions/v2/https";

// jest.mock is hoisted above imports, so `functions` resolves to the mock at runtime.
jest.mock("firebase-functions", () => ({
  logger: {
    write: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

// Mock Sentry — Logger.error calls captureException; we don't want side effects.
jest.mock("../src/sentry", () => ({
  captureException: jest.fn(),
  addBreadcrumb: jest.fn(),
}));

import {logError} from "../src/logger";

const writeMock = functions.logger.write as jest.Mock;
const warnMock = functions.logger.warn as jest.Mock;
const errorMock = functions.logger.error as jest.Mock;

beforeEach(() => {
  writeMock.mockClear();
  warnMock.mockClear();
  errorMock.mockClear();
});

describe("logger F-50-04 v2 — stack scrub + entryFromArgs bypass", () => {
  test("logError(msg, plainError) → write({severity:ERROR, ...}), no stack field, no logger.error", () => {
    const err = new Error("boom");
    err.stack = "Error: boom\n    at /workspace/lib/foo.js:42:13";

    logError("Something failed", err);

    expect(errorMock).not.toHaveBeenCalled();
    expect(warnMock).not.toHaveBeenCalled();
    expect(writeMock).toHaveBeenCalledTimes(1);

    const payload = writeMock.mock.calls[0][0];
    expect(payload.severity).toBe("ERROR");
    expect(payload.message).toBe("Something failed");
    expect(payload.error).toEqual({message: "boom", name: "Error"});
    expect(payload.error).not.toHaveProperty("stack");
  });

  test("logError(msg, internalHttpsError) → write() with error.code, no stack", () => {
    const err = new HttpsError("internal", "kaboom");

    logError("Internal failure", err);

    expect(errorMock).not.toHaveBeenCalled();
    expect(warnMock).not.toHaveBeenCalled();
    expect(writeMock).toHaveBeenCalledTimes(1);

    const payload = writeMock.mock.calls[0][0];
    expect(payload.severity).toBe("ERROR");
    expect(payload.message).toBe("Internal failure");
    expect(payload.error.code).toBe("internal");
    expect(payload.error).not.toHaveProperty("stack");
  });

  test("logError(msg, clientFaultHttpsError) → warn() (NOT write), no stack", () => {
    const err = new HttpsError("invalid-argument", "bad input");

    logError("Validation rejected", err);

    expect(writeMock).not.toHaveBeenCalled();
    expect(errorMock).not.toHaveBeenCalled();
    expect(warnMock).toHaveBeenCalledTimes(1);

    const [msg, data] = warnMock.mock.calls[0];
    expect(msg).toBe("Validation rejected");
    expect(data.error.code).toBe("invalid-argument");
    expect(data.error).not.toHaveProperty("stack");
  });

  test("logError(msg) bare → write({severity:ERROR, message}) only", () => {
    logError("Plain message");

    expect(errorMock).not.toHaveBeenCalled();
    expect(warnMock).not.toHaveBeenCalled();
    expect(writeMock).toHaveBeenCalledTimes(1);

    const payload = writeMock.mock.calls[0][0];
    expect(payload).toEqual({severity: "ERROR", message: "Plain message"});
    // entryFromArgs-bypass intent: message is a plain string we control. The actual
    // bypass is firebase-functions's write() contract — smoke-gate verifies it.
    expect(typeof payload.message).toBe("string");
    expect(payload.message).not.toMatch(/\n {4}at \/workspace\//);
  });

  test("logError(msg, null, data) → write() merges logData, message stays plain", () => {
    logError("Op failed", null, {userId: "u123", priceIdPrefix: "price_test_"});

    expect(errorMock).not.toHaveBeenCalled();
    expect(warnMock).not.toHaveBeenCalled();
    expect(writeMock).toHaveBeenCalledTimes(1);

    const payload = writeMock.mock.calls[0][0];
    expect(payload.severity).toBe("ERROR");
    expect(payload.message).toBe("Op failed");
    expect(payload.userId).toBe("u123");
    expect(payload.priceIdPrefix).toBe("price_test_");
    // No Error in args → no `error` key set by Logger
    expect(payload).not.toHaveProperty("error");
    // Plain message — no synthesized stack
    expect(payload.message).not.toMatch(/\n {4}at \/workspace\//);
  });

  test("explicit message arg wins over a stray message key in data", () => {
    logError("real message", null, {message: "should-be-overridden", userId: "u1"});

    expect(writeMock).toHaveBeenCalledTimes(1);
    const payload = writeMock.mock.calls[0][0];
    expect(payload.message).toBe("real message");
    expect(payload.userId).toBe("u1");
  });

  test("rejects logData.severity override — output severity=ERROR even if logData provides 'INFO'", () => {
    // Advisor flag (PR #495 v2 review): if `severity` were placed BEFORE
    // ...logData spread, a caller's data object containing `severity: "INFO"`
    // would silently downgrade the log. Verify our fix (severity last) holds.
    logError("real error", null, {severity: "INFO", userId: "u1"});

    expect(writeMock).toHaveBeenCalledTimes(1);
    const payload = writeMock.mock.calls[0][0];
    expect(payload.severity).toBe("ERROR");
    expect(payload.message).toBe("real error");
    expect(payload.userId).toBe("u1");
  });
});
