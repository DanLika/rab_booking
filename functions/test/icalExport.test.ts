// Mock dependencies inside factory
jest.mock("../src/firebase", () => {
  const mockFirestoreInstance = {
    collection: jest.fn().mockReturnThis(),
    collectionGroup: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn(),
    update: jest.fn().mockResolvedValue(true),
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

jest.mock("../src/utils/ipUtils", () => ({
  getClientIp: jest.fn().mockReturnValue("127.0.0.1"),
  hashIp: jest.fn().mockReturnValue("hash-127.0.0.1"),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

import { getUnitIcalFeed } from "../src/icalExport";
import { checkRateLimit } from "../src/utils/rateLimit";
import { db } from "../src/firebase";

describe("iCal Export Endpoint", () => {
  let req: any;
  let res: any;
  const mockDb = db as any;

  beforeEach(() => {
    jest.clearAllMocks();

    // Reset default mocks
    mockDb.collection.mockReturnThis();
    mockDb.collectionGroup.mockReturnThis();
    mockDb.doc.mockReturnThis();
    mockDb.where.mockReturnThis();
    mockDb.orderBy.mockReturnThis();
    mockDb.limit.mockReturnThis();

    req = {
      method: "GET",
      path: "/prop-123/unit-123/valid-token",
      query: {},
      headers: {},
    };

    res = {
      status: jest.fn().mockReturnThis(),
      send: jest.fn(),
      set: jest.fn(),
    };
  });

  it("should return 429 if rate limit exceeded", async () => {
    (checkRateLimit as jest.Mock).mockReturnValueOnce(false);

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(429);
    expect(res.send).toHaveBeenCalledWith(expect.stringContaining("Too many requests"));
  });

  it("should return 405 for invalid method", async () => {
    req.method = "POST";

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(405);
  });

  it("should allow HEAD requests", async () => {
    req.method = "HEAD";
    // Mock not found to exit early but pass method check
    mockDb.get.mockResolvedValueOnce({ exists: false });

    await getUnitIcalFeed(req, res);

    expect(res.status).not.toHaveBeenCalledWith(405);
  });

  it("should return 400 for invalid URL format", async () => {
    req.path = "/invalid";

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  it("should return 404 if widget settings not found", async () => {
    mockDb.get.mockResolvedValueOnce({ exists: false });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(404);
  });

  it("should return 403 if export disabled", async () => {
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({ ical_export_enabled: false }),
    });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.send).toHaveBeenCalledWith("iCal export is disabled for this unit");
  });

  it("should return 403 for invalid token", async () => {
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "secret-token",
      }),
    });

    req.path = "/prop-123/unit-123/wrong-token";

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.send).toHaveBeenCalledWith("Invalid token");
  });

  it("should return 304 if ETag matches", async () => {
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "valid-token",
        ical_cache_content: "cached-ical",
        ical_cache_generated_at: { toDate: () => new Date() }, // fresh
        ical_cache_etag: '"etag-123"',
      }),
    });

    req.headers["if-none-match"] = '"etag-123"';

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(304);
  });

  it("should return cached content if valid", async () => {
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "valid-token",
        ical_cache_content: "cached-ical",
        ical_cache_generated_at: { toDate: () => new Date() }, // fresh
        ical_cache_etag: '"etag-123"',
      }),
    });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.send).toHaveBeenCalledWith("cached-ical");
  });

  it("should generate fresh feed if cache invalid", async () => {
    // 1. Widget Settings (cache invalid/missing)
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "valid-token",
      }),
      ref: { update: jest.fn() },
    });

    // 2. Unit Doc
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({ name: "Test Unit" }),
    });

    // 3. Bookings
    mockDb.get.mockResolvedValueOnce({
      size: 1,
      docs: [{
        id: "bk-1",
        data: () => ({
          status: "confirmed",
          check_in: { toDate: () => new Date("2026-06-01") },
          check_out: { toDate: () => new Date("2026-06-05") },
          created_at: { toDate: () => new Date() },
          updated_at: { toDate: () => new Date() },
        })
      }],
    });

    // 4. Blocked Days
    mockDb.get.mockResolvedValueOnce({ size: 0, docs: [] });

    // 5. Imported Events
    mockDb.get.mockResolvedValueOnce({ size: 0, docs: [] });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    const content = res.send.mock.calls[0][0];
    expect(content).toContain("BEGIN:VCALENDAR");
    expect(content).toContain("UID:booking-bk-1@bookbed.io");
    expect(content).toContain("SUMMARY:Reserved"); // GDPR check
  });

  it("should filter events when ?exclude= is used", async () => {
    req.query.exclude = "airbnb";

    // 1. Widget Settings
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "valid-token",
        ical_cache_content: "cached-ical", // Should ignore cache
        ical_cache_generated_at: { toDate: () => new Date() },
      }),
      ref: { update: jest.fn() },
    });

    // 2. Unit Doc
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({ name: "Test Unit" }),
    });

    // 3. Bookings
    mockDb.get.mockResolvedValueOnce({ size: 0, docs: [] });

    // 4. Blocked Days
    mockDb.get.mockResolvedValueOnce({ size: 0, docs: [] });

    // 5. Imported Events - One from Airbnb, one from Booking.com
    mockDb.get.mockResolvedValueOnce({
      size: 2,
      docs: [
        {
          id: "ev-1",
          data: () => ({ source: "airbnb", start_date: { toDate: () => new Date() }, end_date: { toDate: () => new Date() } }),
        },
        {
          id: "ev-2",
          data: () => ({ source: "booking_com", start_date: { toDate: () => new Date() }, end_date: { toDate: () => new Date() } }),
        },
      ],
    });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    const content = res.send.mock.calls[0][0];
    // Should NOT contain Airbnb event
    expect(content).not.toContain("UID:ical-ev-1");
    // Should contain Booking.com event
    expect(content).toContain("UID:ical-ev-2");
  });

  it("should handle HEAD requests correctly", async () => {
    req.method = "HEAD";

    // 1. Widget Settings
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "valid-token",
        ical_cache_content: "cached-ical",
        ical_cache_generated_at: { toDate: () => new Date() }, // fresh
        ical_cache_etag: '"etag-123"',
      }),
    });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    // Function sends content, runtime handles body stripping for HEAD
    expect(res.send).toHaveBeenCalledWith("cached-ical");
  });

  it("should export blocked days as VEVENT", async () => {
    // 1. Widget Settings
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        ical_export_enabled: true,
        ical_export_token: "valid-token",
      }),
      ref: { update: jest.fn() },
    });

    // 2. Unit Doc
    mockDb.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({ name: "Test Unit" }),
    });

    // 3. Bookings
    mockDb.get.mockResolvedValueOnce({ size: 0, docs: [] });

    // 4. Blocked Days - 3 consecutive days blocked
    mockDb.get.mockResolvedValueOnce({
      size: 3,
      docs: [
        { data: () => ({ date: { toDate: () => new Date("2026-07-01") }, available: false }) },
        { data: () => ({ date: { toDate: () => new Date("2026-07-02") }, available: false }) },
        { data: () => ({ date: { toDate: () => new Date("2026-07-03") }, available: false }) },
      ],
    });

    // 5. Imported Events
    mockDb.get.mockResolvedValueOnce({ size: 0, docs: [] });

    await getUnitIcalFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    const content = res.send.mock.calls[0][0];

    // Should contain a blocked event spanning the range
    expect(content).toContain("SUMMARY:Not Available");
    // Date range should be 20260701 to 20260704 (exclusive end)
    expect(content).toContain("DTSTART;VALUE=DATE:20260701");
    expect(content).toContain("DTEND;VALUE=DATE:20260704");
  });
});
