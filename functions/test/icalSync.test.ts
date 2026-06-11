const test = require("firebase-functions-test")();

// Setup mocks inside the factory to avoid hoisting issues
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn().mockResolvedValue(true),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    }),
    limit: jest.fn().mockReturnThis(),
  };

  const firestoreFn = jest.fn(() => mockFirestoreInstance);

  Object.assign(firestoreFn, {
    FieldValue: {
      increment: jest.fn(),
    },
    Timestamp: {
      fromDate: (date: Date) => ({
        toDate: () => date,
        toMillis: () => date.getTime(),
      }),
      now: () => {
        const now = new Date();
        return {
          toDate: () => now,
          toMillis: () => now.getTime(),
        };
      },
    },
  });

  return {
    admin: {
      firestore: firestoreFn,
    },
    db: mockFirestoreInstance,
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logSuccess: jest.fn(),
  logWarn: jest.fn(),
}));

jest.mock("../src/sentry", () => ({
  setUser: jest.fn(),
}));

// SF-078: mock trial gate (same as atomicBooking.test.ts / stripeConnect.test.ts).
// Gate semantics covered by test/requireActiveOwner.test.ts.
jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
  enforceRateLimit: jest.fn().mockResolvedValue(undefined),
  hashRateKey: jest.fn((raw: string) => `hash_${raw}`),
}));

jest.mock("../src/utils/requireActiveOwner", () => ({
  requireActiveOwner: jest.fn().mockImplementation(async (auth: { uid?: string | null } | null | undefined) => {
    if (!auth?.uid) {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const {HttpsError} = require("firebase-functions/v2/https");
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    return auth.uid;
  }),
}));

jest.mock("../src/utils/echoDetection", () => ({
  analyzeEvent: jest.fn().mockReturnValue({
    isProbableEcho: false,
    confidence: 0,
    reasons: [],
    recommendedAction: "save_unique",
  }),
}));

// Mock https for fetchIcalData
const mockRequest = {
  on: jest.fn(),
  setTimeout: jest.fn(),
  destroy: jest.fn(),
};

const mockResponse = {
  statusCode: 200,
  statusMessage: "OK",
  headers: {},
  on: jest.fn(),
};

jest.mock("https", () => ({
  get: jest.fn(),
}));

// F-NEW-05: validateIcalUrl is now async and DNS-resolves the hostname.
// Mock dns/promises so tests don't hit real DNS in CI. Default returns a
// public IP; tests that need to exercise the SSRF block override below.
jest.mock("dns/promises", () => ({
  lookup: jest.fn(async (hostname: string, _opts: unknown) => {
    if (hostname === "localhost" || hostname === "127.0.0.1") {
      return [{ address: "127.0.0.1", family: 4 }];
    }
    return [{ address: "203.0.113.10", family: 4 }]; // TEST-NET-3 RFC5737
  }),
}));

import { syncIcalFeedNow, scheduledIcalSync } from "../src/icalSync";
import * as https from "https";
import { db } from "../src/firebase";
import * as logger from "../src/logger";

const { wrap } = test;

describe("iCal Sync Functions", () => {
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();

    // Reset default mock implementations that might be overwritten
    mockDb.collection.mockReturnThis();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.limit.mockReturnThis();
    mockDb.batch.mockReturnValue({
      set: jest.fn(),
      delete: jest.fn(),
      commit: jest.fn().mockResolvedValue(true),
    });

    // Setup default mock request/response behavior.
    // F-NEW-05: fetchIcalData now always calls https.get(url, options, callback)
    // (3-arg form) — options carries the pinned-IP lookup callback when set.
    // Support both 2-arg (legacy) and 3-arg signatures so the mock survives.
    (https.get as jest.Mock).mockImplementation((url, optsOrCb, maybeCb) => {
      const callback = typeof optsOrCb === "function" ? optsOrCb : maybeCb;
      callback(mockResponse);
      return mockRequest;
    });

    mockResponse.on.mockImplementation((event, callback) => {
      if (event === "data") callback("BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nUID:123\nDTSTART:20260101\nDTEND:20260105\nEND:VEVENT\nEND:VCALENDAR");
      if (event === "end") callback();
    });
  });

  describe("syncIcalFeedNow", () => {
    const validData = {
      feedId: "feed-123",
      propertyId: "prop-123",
    };

    const mockAuth = { uid: "user-123" };

    const mockPropertyDoc = {
      exists: true,
      data: () => ({ owner_id: "user-123" }),
    };

    const mockFeedDoc = {
      exists: true,
      data: () => ({
        unit_id: "unit-1",
        ical_url: "https://airbnb.com/calendar.ics",
        platform: "airbnb",
        import_enabled: true,
      }),
      ref: {
        update: jest.fn().mockResolvedValue(true),
      },
    };

    it("should throw error if user is unauthenticated", async () => {
      const wrapped = wrap(syncIcalFeedNow);
      await expect(wrapped({ data: validData })).rejects.toThrow("Authentication required.");
    });

    it("should throw error if arguments are missing", async () => {
      const wrapped = wrap(syncIcalFeedNow);
      await expect(wrapped({ data: {}, auth: mockAuth })).rejects.toThrow("feedId and propertyId are required");
    });

    it("should throw error if property not owned by user", async () => {
      mockDb.get.mockResolvedValueOnce({
        exists: true,
        data: () => ({ owner_id: "other-user" }),
      });

      const wrapped = wrap(syncIcalFeedNow);
      await expect(wrapped({ data: validData, auth: mockAuth })).rejects.toThrow("You do not own this property");
    });

    it("should skip sync if import is disabled", async () => {
      // Setup mock chain
      mockDb.get
        .mockResolvedValueOnce(mockPropertyDoc) // property check
        .mockResolvedValueOnce({ // feed fetch
          exists: true,
          data: () => ({ ...mockFeedDoc.data(), import_enabled: false }),
        });

      const wrapped = wrap(syncIcalFeedNow);
      const result = await wrapped({ data: validData, auth: mockAuth });

      expect(result.skipped).toBe(true);
      expect(result.message).toContain("Import is disabled");
    });

    it("should fail for invalid iCal URL (SSRF check)", async () => {
       // Setup mock chain
       mockDb.get
       .mockResolvedValueOnce(mockPropertyDoc) // property check
       .mockResolvedValueOnce({ // feed fetch
         exists: true,
         data: () => ({ ...mockFeedDoc.data(), ical_url: "http://localhost:8080/hack" }),
         ref: { update: jest.fn() }
       });

      const wrapped = wrap(syncIcalFeedNow);
      // F-NEW-05: error string changed when validator switched from substring
      // blocklist to DNS-resolve + private-IP check. localhost resolves to
      // 127.0.0.1 which isPrivateOrUnsafeIp rejects.
      await expect(wrapped({ data: validData, auth: mockAuth })).rejects.toThrow(
        /private or reserved IP address/i
      );
    });

    it("should sync successfully for valid input", async () => {
      // Mock chain for complex calls
      // 1. Property owner check
      // 2. Feed fetch
      // 3. Existing bookings fetch (native)
      // 4. Existing ical events fetch (other)
      // 5. Old events fetch (for deletion)

      mockDb.get
        .mockResolvedValueOnce(mockPropertyDoc) // 1
        .mockResolvedValueOnce(mockFeedDoc) // 2
        .mockResolvedValueOnce({ docs: [], size: 0 }) // 3
        .mockResolvedValueOnce({ docs: [] }) // 4
        .mockResolvedValueOnce({ docs: [], length: 0 }); // 5

      const wrapped = wrap(syncIcalFeedNow);
      const result = await wrapped({ data: validData, auth: mockAuth });

      expect(result.success).toBe(true);
      expect(https.get).toHaveBeenCalled();
    });

    // Regression: Node 18+ with autoSelectFamily calls our pinned lookup with
    // `options.all === true` and expects the array-form callback
    // `(err, [{address, family}, ...])`. The 3-arg form yields
    // `ERR_INVALID_IP_ADDRESS: Invalid IP address: undefined`, breaking every
    // legit feed sync. Assert both shapes are dispatched correctly.
    it("pinned lookup dispatches array form when options.all === true", async () => {
      mockDb.get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce(mockFeedDoc)
        .mockResolvedValueOnce({ docs: [], size: 0 })
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ docs: [], length: 0 });

      let capturedOptions: any = null;
      (https.get as jest.Mock).mockImplementation((url, optsOrCb, maybeCb) => {
        if (typeof optsOrCb === "object") capturedOptions = optsOrCb;
        const callback = typeof optsOrCb === "function" ? optsOrCb : maybeCb;
        callback(mockResponse);
        return mockRequest;
      });

      const wrapped = wrap(syncIcalFeedNow);
      await wrapped({ data: validData, auth: mockAuth });

      expect(capturedOptions).toBeTruthy();
      expect(typeof capturedOptions.lookup).toBe("function");

      // all === true → array form
      let arrResult: any = null;
      capturedOptions.lookup("any.host", { all: true }, (...args: unknown[]) => {
        arrResult = args;
      });
      expect(arrResult).toHaveLength(2);
      expect(arrResult[0]).toBeNull();
      expect(Array.isArray(arrResult[1])).toBe(true);
      expect(arrResult[1][0]).toMatchObject({ address: "203.0.113.10", family: 4 });

      // all === false → 3-arg form
      let threeArgResult: any = null;
      capturedOptions.lookup("any.host", { all: false }, (...args: unknown[]) => {
        threeArgResult = args;
      });
      expect(threeArgResult).toHaveLength(3);
      expect(threeArgResult[0]).toBeNull();
      expect(threeArgResult[1]).toBe("203.0.113.10");
      expect(threeArgResult[2]).toBe(4);

      // options undefined → 3-arg form
      let undefResult: any = null;
      capturedOptions.lookup("any.host", undefined, (...args: unknown[]) => {
        undefResult = args;
      });
      expect(undefResult).toHaveLength(3);
      expect(undefResult[1]).toBe("203.0.113.10");
    });

    // F-67-05: an arbitrary thrown Error inside syncSingleFeed must NOT
    // surface its raw message (which can carry upstream host / status /
    // response body) to the client. The outer handler must wrap it in a
    // generic HttpsError.
    it("does not leak upstream Error message in HttpsError response", async () => {
      // Only enqueue the 2 doc reads before fetchIcalData throws —
      // leaving extra onces in the queue would bleed into the next test.
      mockDb.get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce(mockFeedDoc);

      // Force fetchIcalData to surface a host-bearing error message.
      // Save + restore implementation so it doesn't bleed across tests
      // (beforeEach clears call history, not impl).
      const prevImpl = (https.get as jest.Mock).getMockImplementation();
      (https.get as jest.Mock).mockImplementation(() => {
        throw new Error("connect ECONNREFUSED ical.booking.com:443");
      });
      try {
        const wrapped = wrap(syncIcalFeedNow);
        let captured: unknown;
        try {
          await wrapped({ data: validData, auth: mockAuth });
        } catch (err) {
          captured = err;
        }

        expect(captured).toBeTruthy();
        const msg =
          (captured as { message?: string }).message ?? String(captured);
        expect(msg).not.toContain("ical.booking.com");
        expect(msg).not.toContain("ECONNREFUSED");
        expect(msg).toMatch(/feed url|ical feed|verify the feed/i);
      } finally {
        if (prevImpl) {
          (https.get as jest.Mock).mockImplementation(prevImpl);
        }
      }
    });

    // FLUTTER-7B: owner-fault iCal validation rejections (file://, private
    // IPs, malformed URL) must NOT escalate to Sentry. They surface to the
    // owner via feed.last_error already. Since F-67-05 the URL-validation
    // throw at syncSingleFeed is an HttpsError("failed-precondition") — the
    // outer syncIcalFeedNow catch short-circuits via
    // `if (error instanceof HttpsError) throw error;`, so the asserts here
    // target the INNER syncSingleFeed catch where the filter actually fires.
    it("FLUTTER-7B: file:// URL routes through logWarn, not logError", async () => {
      mockDb.get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce({
          exists: true,
          data: () => ({
            ...mockFeedDoc.data(),
            ical_url: "file:///etc/passwd",
          }),
          ref: { update: jest.fn().mockResolvedValue(true) },
        });

      const wrapped = wrap(syncIcalFeedNow);
      await expect(
        wrapped({ data: validData, auth: mockAuth })
      ).rejects.toThrow(/Invalid iCal URL: Invalid protocol: file/);

      // Inner syncSingleFeed catch MUST route owner-fault validation through
      // logWarn — keeps Sentry quiet on bad-paste / SSRF-smoke probes.
      const errCalls = (logger.logError as jest.Mock).mock.calls.map(
        (c) => c[0]
      );
      expect(errCalls).not.toContain("[iCal Sync] Error syncing feed");

      const warnCalls = (logger.logWarn as jest.Mock).mock.calls.map(
        (c) => c[0]
      );
      expect(warnCalls).toContain(
        "[iCal Sync] Owner-fault validation rejection"
      );
    });

    // FLUTTER-7B over-broadening guard: genuine non-owner-fault errors (parse
    // failure, missing BEGIN:VCALENDAR, unexpected internal exceptions) MUST
    // still hit logError → Sentry. The filter only catches the documented
    // owner-fault patterns, not all throws.
    it("FLUTTER-7B: empty-body parse failure stays on logError", async () => {
      mockDb.get
        .mockResolvedValueOnce(mockPropertyDoc)
        .mockResolvedValueOnce(mockFeedDoc);

      // Force fetchIcalData to return empty body (200 OK, no VCALENDAR).
      // The BUG-009 guard inside syncSingleFeed throws "Fetched iCal data is
      // empty or invalid for feed: …" which is NOT in the owner-fault
      // pattern set — must escalate to logError.
      const prevImpl = (https.get as jest.Mock).getMockImplementation();
      mockResponse.on.mockImplementation((event: string, cb: (arg?: string) => void) => {
        if (event === "data") cb("");
        if (event === "end") cb();
      });
      try {
        const wrapped = wrap(syncIcalFeedNow);
        await expect(
          wrapped({ data: validData, auth: mockAuth })
        ).rejects.toThrow(/empty or invalid for feed/);

        const errCalls = (logger.logError as jest.Mock).mock.calls.map(
          (c) => c[0]
        );
        expect(errCalls).toContain("[iCal Sync] Error syncing feed");
      } finally {
        if (prevImpl) {
          (https.get as jest.Mock).mockImplementation(prevImpl);
        }
      }
    });
  });

  describe("scheduledIcalSync", () => {
    it("should process multiple feeds", async () => {
      const wrapped = wrap(scheduledIcalSync);

      // Mock active feeds
      const feed1 = {
        id: "feed-1",
        data: () => ({
          unit_id: "unit-1",
          ical_url: "https://example.com/1.ics",
          platform: "airbnb",
          import_enabled: true,
        }),
        ref: { path: "properties/prop-1/ical_feeds/feed-1", update: jest.fn() }
      };

      const feed2 = {
        id: "feed-2",
        data: () => ({
          unit_id: "unit-2",
          ical_url: "https://example.com/2.ics",
          platform: "booking_com",
          import_enabled: true,
        }),
        ref: { path: "properties/prop-2/ical_feeds/feed-2", update: jest.fn() }
      };

      // Mock feeds fetch
      mockDb.get.mockResolvedValueOnce({
        empty: false,
        size: 2,
        docs: [feed1, feed2],
      });

      // For each feed:
      // 1. Existing bookings
      // 2. Existing ical events
      // 3. Old events

      // Feed 1
      mockDb.get
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ docs: [] });

      // Feed 2
      mockDb.get
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ docs: [] })
        .mockResolvedValueOnce({ docs: [] });

      await wrapped({});

      expect(https.get).toHaveBeenCalledTimes(2);
    });

    it("should skip recently synced feeds", async () => {
      const wrapped = wrap(scheduledIcalSync);

      const recentlySynced = new Date();
      // Synced 5 mins ago, interval 15 mins -> skip
      recentlySynced.setMinutes(recentlySynced.getMinutes() - 5);

      const feed1 = {
        id: "feed-1",
        data: () => ({
          unit_id: "unit-1",
          ical_url: "https://example.com/1.ics",
          platform: "airbnb",
          import_enabled: true,
          last_synced: { toDate: () => recentlySynced },
          sync_interval_minutes: 15,
        }),
        ref: { path: "properties/prop-1/ical_feeds/feed-1", update: jest.fn() }
      };

      // Mock feeds fetch
      mockDb.get.mockResolvedValueOnce({
        empty: false,
        size: 1,
        docs: [feed1],
      });

      await wrapped({});

      expect(https.get).not.toHaveBeenCalled();
    });
  });
});

/**
 * SF-vibe57 M-11 — Hex IPv4-mapped IPv6 SSRF bypass coverage.
 *
 * `dns.lookup` may return IPv4-mapped IPv6 in either dotted
 * (`::ffff:169.254.169.254`) OR hex (`::ffff:a9fe:a9fe`) form depending on
 * resolver + `verbatim` flag. Pre-fix the validator only matched dotted;
 * hex slipped through to `net.isIPv6` (returns false from the private
 * matchers → `isPrivateOrUnsafeIp` returned false → SSRF reach).
 *
 * Cases below pin both: existing dotted branch still catches metadata IPs,
 * AND new hex branch catches the same IPs in hex form + edge ranges
 * (0.0.0.0, 255.255.255.255, mixed case, non-IPv4-mapped IPv6 pass-through).
 */
import { isPrivateOrUnsafeIp } from "../src/icalSync";

describe("isPrivateOrUnsafeIp — SF-vibe57 M-11 hex IPv4-mapped IPv6", () => {
  // Existing dotted branch (regression guard)
  it("dotted IPv4-mapped IPv6 metadata IP → blocked", () => {
    expect(isPrivateOrUnsafeIp("::ffff:169.254.169.254")).toBe(true);
  });

  // M-11 new branch
  it("hex IPv4-mapped IPv6 metadata IP (lowercase) → blocked", () => {
    expect(isPrivateOrUnsafeIp("::ffff:a9fe:a9fe")).toBe(true);
  });

  it("hex IPv4-mapped IPv6 metadata IP (uppercase) → blocked", () => {
    expect(isPrivateOrUnsafeIp("::FFFF:A9FE:A9FE")).toBe(true);
  });

  it("hex IPv4-mapped IPv6 loopback (::ffff:7f00:1) → blocked", () => {
    expect(isPrivateOrUnsafeIp("::ffff:7f00:1")).toBe(true);
  });

  it("hex IPv4-mapped IPv6 0.0.0.0 (::ffff:0:0) → blocked", () => {
    expect(isPrivateOrUnsafeIp("::ffff:0:0")).toBe(true);
  });

  it("hex IPv4-mapped IPv6 RFC1918 10.0.0.1 (::ffff:a00:1) → blocked", () => {
    expect(isPrivateOrUnsafeIp("::ffff:a00:1")).toBe(true);
  });

  it("hex IPv4-mapped IPv6 broadcast 255.255.255.255 (::ffff:ffff:ffff) → blocked", () => {
    expect(isPrivateOrUnsafeIp("::ffff:ffff:ffff")).toBe(true);
  });

  it("hex IPv4-mapped IPv6 public IP 8.8.8.8 (::ffff:808:808) → allowed", () => {
    expect(isPrivateOrUnsafeIp("::ffff:808:808")).toBe(false);
  });

  // Boundary: regex MUST NOT match generic IPv6 that happens to share
  // the ::ffff prefix without the 2-group structure
  it("generic IPv6 ::ffff:a:b:c:d → NOT matched by hex regex, falls to IPv6 path", () => {
    // Not IPv4-mapped (4 hex groups after ::ffff is unusual but valid IPv6);
    // regex requires exactly 2 groups after ::ffff. Falls to net.isIPv6 path
    // which returns false (not a private prefix). Acceptable — DNS lookup
    // downstream still validates.
    expect(isPrivateOrUnsafeIp("::ffff:a:b:c:d")).toBe(false);
  });

  it("invalid hex (out-of-range chars) → NOT matched, falls through", () => {
    // 'gggg' has chars outside [0-9a-f]; regex requires [0-9a-f]{1,4}.
    expect(isPrivateOrUnsafeIp("::ffff:gggg:1")).toBe(false);
  });

  // Existing IPv4 + IPv6 paths (regression guards — confirm M-11 didn't
  // break adjacent branches)
  it("plain IPv4 RFC1918 10.0.0.1 → blocked", () => {
    expect(isPrivateOrUnsafeIp("10.0.0.1")).toBe(true);
  });

  it("plain IPv4 public 8.8.8.8 → allowed", () => {
    expect(isPrivateOrUnsafeIp("8.8.8.8")).toBe(false);
  });

  it("IPv6 loopback ::1 → blocked", () => {
    expect(isPrivateOrUnsafeIp("::1")).toBe(true);
  });

  it("IPv6 ULA fd00::1 → blocked", () => {
    expect(isPrivateOrUnsafeIp("fd00::1")).toBe(true);
  });

  it("empty string → blocked (fail-closed)", () => {
    expect(isPrivateOrUnsafeIp("")).toBe(true);
  });
});
