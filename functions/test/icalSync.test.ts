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
      await expect(wrapped({ data: validData })).rejects.toThrow("User must be authenticated");
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
