/**
 * Tests for src/availability.ts — T11c getUnitAvailability callable.
 *
 * Exercises input validation + rate limit + the three-source merge
 * (bookings + manual_block daily_prices + ical_external) + PII strip
 * + cross-range boundary clipping + echo skip.
 */

// eslint-disable-next-line @typescript-eslint/no-var-requires
const test = require("firebase-functions-test")();

jest.mock("firebase-functions/params", () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const real = jest.requireActual("firebase-functions/params");
  return {
    ...real,
    defineSecret: () => ({value: () => "mock-secret", name: "MOCK"}),
    defineString: () => ({value: () => ""}),
  };
});

interface FakeSnap {
  empty: boolean;
  docs: Array<{data: () => Record<string, unknown>}>;
  size?: number;
}

const fakeSnaps = {
  bookings: {empty: true, docs: []} as FakeSnap,
  prices: {empty: true, docs: []} as FakeSnap,
  ical: {empty: true, docs: []} as FakeSnap,
  property: {exists: true} as {exists: boolean},
};

function setSnaps(b: FakeSnap, p: FakeSnap, i: FakeSnap, propExists = true) {
  fakeSnaps.bookings = b;
  fakeSnaps.prices = p;
  fakeSnaps.ical = i;
  fakeSnaps.property = {exists: propExists};
}

jest.mock("../src/firebase", () => {
  const Timestamp = {
    fromDate: (d: Date) => ({toDate: () => d, toMillis: () => d.getTime()}),
    now: () => ({toMillis: () => Date.now()}),
  };
  return {
    admin: {
      firestore: {
        Timestamp,
      },
    },
    db: {
      collectionGroup: (name: string) => {
        const chain: any = {
          where: () => chain,
          limit: () => chain,
          get: async () => {
            if (name === "bookings") return fakeSnaps.bookings;
            if (name === "ical_events") return fakeSnaps.ical;
            return {empty: true, docs: []};
          },
        };
        return chain;
      },
      collection: (name: string) => {
        if (name === "properties") {
          return {
            doc: (_propId: string) => ({
              collection: (_subName: string) => ({
                doc: (_unitId: string) => ({
                  collection: (_pricesName: string) => ({
                    where: function _w() { return this; },
                    limit: function _l() { return this; },
                    get: async () => fakeSnaps.prices,
                  }),
                }),
              }),
              get: async () => fakeSnaps.property,
            }),
          };
        }
        throw new Error(`unexpected collection ${name}`);
      },
    },
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
  logSuccess: jest.fn(),
}));

jest.mock("../src/utils/ipUtils", () => ({
  getClientIp: jest.fn(() => "10.0.0.1"),
  hashIp: jest.fn((ip: string) => `hash-${ip}`),
}));

jest.mock("../src/utils/rateLimit", () => ({
  checkRateLimit: jest.fn().mockReturnValue(true),
}));

import {getUnitAvailability} from "../src/availability";

const {wrap} = test;
const wrapped = wrap(getUnitAvailability);

function isoNow(offsetDays: number): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + offsetDays);
  return d.toISOString();
}

describe("availability.getUnitAvailability (T11c)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    setSnaps({empty: true, docs: []}, {empty: true, docs: []}, {empty: true, docs: []});
    const {checkRateLimit} = require("../src/utils/rateLimit");
    checkRateLimit.mockReturnValue(true);
  });

  it("rejects missing propertyId", async () => {
    await expect(
      wrapped({data: {unitId: "u-1", startDate: isoNow(0), endDate: isoNow(1)}})
    ).rejects.toThrow(/propertyId/);
  });

  it("rejects missing unitId", async () => {
    await expect(
      wrapped({data: {propertyId: "p-1", startDate: isoNow(0), endDate: isoNow(1)}})
    ).rejects.toThrow(/unitId/);
  });

  it("rejects unparseable startDate", async () => {
    await expect(
      wrapped({data: {propertyId: "p-1", unitId: "u-1", startDate: "not-a-date", endDate: isoNow(1)}})
    ).rejects.toThrow(/valid date/);
  });

  it("rejects endDate before or equal to startDate", async () => {
    const d = isoNow(0);
    await expect(
      wrapped({data: {propertyId: "p-1", unitId: "u-1", startDate: d, endDate: d}})
    ).rejects.toThrow(/endDate must be after/);
  });

  it("rejects range > 366 days", async () => {
    await expect(
      wrapped({data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(400)}})
    ).rejects.toThrow(/exceeds 366 days/);
  });

  it("rejects when per-(unit,ip) rate limit hit", async () => {
    const {checkRateLimit} = require("../src/utils/rateLimit");
    checkRateLimit.mockReturnValueOnce(false);
    await expect(
      wrapped({data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(7)}})
    ).rejects.toThrow(/Too many availability/);
  });

  it("returns empty windows when no data", async () => {
    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(7)},
    });
    expect(out.windows).toEqual([]);
    expect(out.unitId).toBe("u-1");
    expect(out.cacheHint).toBe(30);
  });

  it("merges booking + manual_block + ical_external windows, sorted by start", async () => {
    const start = isoNow(0);
    const end = isoNow(30);
    const bookingStart = isoNow(5);
    const bookingEnd = isoNow(8);
    const blockDay = isoNow(10);
    const icalStart = isoNow(15);
    const icalEnd = isoNow(17);

    setSnaps(
      {
        empty: false,
        docs: [
          {
            data: () => ({
              check_in: bookingStart,
              check_out: bookingEnd,
              guest_email: "leak@example.com", // must NOT leak
              guest_name: "Mr Leak",
              status: "confirmed",
            }),
          },
        ],
      },
      {
        empty: false,
        docs: [{data: () => ({date: blockDay, available: false})}],
      },
      {
        empty: false,
        docs: [
          {data: () => ({start_date: icalStart, end_date: icalEnd, source: "Airbnb", status: "confirmed"})},
        ],
      }
    );

    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: start, endDate: end},
    });

    expect(out.windows.length).toBe(3);
    const sources = out.windows.map((w: any) => w.source);
    expect(sources).toEqual(["booking", "manual_block", "ical_external"]);

    // PII check: no guest_email / guest_name in any window.
    const flat = JSON.stringify(out.windows);
    expect(flat).not.toMatch(/leak@example.com/);
    expect(flat).not.toMatch(/Mr Leak/);

    // Platform attribution preserved for ical only.
    const ical = out.windows.find((w: any) => w.source === "ical_external");
    expect(ical?.platform).toBe("Airbnb");
  });

  it("skips ical events with status=confirmed_echo (echo detection)", async () => {
    setSnaps(
      {empty: true, docs: []},
      {empty: true, docs: []},
      {
        empty: false,
        docs: [
          {data: () => ({start_date: isoNow(2), end_date: isoNow(4), source: "Airbnb", status: "confirmed"})},
          {data: () => ({start_date: isoNow(5), end_date: isoNow(7), source: "Airbnb", status: "confirmed_echo"})},
        ],
      }
    );

    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(10)},
    });
    expect(out.windows.length).toBe(1);
    expect(out.windows[0].source).toBe("ical_external");
  });

  it("clips booking windows that end before requested start", async () => {
    const pastStart = isoNow(-10);
    const pastEnd = isoNow(-5);
    setSnaps(
      {
        empty: false,
        docs: [{data: () => ({check_in: pastStart, check_out: pastEnd, status: "confirmed"})}],
      },
      {empty: true, docs: []},
      {empty: true, docs: []}
    );

    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(10)},
    });
    expect(out.windows).toEqual([]);
  });

  it("clips booking windows that start after requested end", async () => {
    setSnaps(
      {
        empty: false,
        docs: [{data: () => ({check_in: isoNow(20), check_out: isoNow(25), status: "confirmed"})}],
      },
      {empty: true, docs: []},
      {empty: true, docs: []}
    );
    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(10)},
    });
    expect(out.windows).toEqual([]);
  });

  it("filters bookings missing check_in or check_out", async () => {
    setSnaps(
      {
        empty: false,
        docs: [
          {data: () => ({check_out: isoNow(5), status: "confirmed"})}, // missing check_in
          {data: () => ({check_in: isoNow(3), check_out: isoNow(5), status: "confirmed"})}, // valid
        ],
      },
      {empty: true, docs: []},
      {empty: true, docs: []}
    );
    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(10)},
    });
    expect(out.windows.length).toBe(1);
  });

  it("returns Firestore Timestamp via toDate() for check_in field", async () => {
    const d1 = new Date(isoNow(3));
    const d2 = new Date(isoNow(5));
    const tsLike = {toDate: () => d1};
    const tsLike2 = {toDate: () => d2};
    setSnaps(
      {
        empty: false,
        docs: [{data: () => ({check_in: tsLike, check_out: tsLike2, status: "confirmed"})}],
      },
      {empty: true, docs: []},
      {empty: true, docs: []}
    );
    const out = await wrapped({
      data: {propertyId: "p-1", unitId: "u-1", startDate: isoNow(0), endDate: isoNow(10)},
    });
    expect(out.windows.length).toBe(1);
    expect(new Date(out.windows[0].start).getTime()).toBe(d1.getTime());
  });
});
