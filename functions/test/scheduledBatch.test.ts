/**
 * Tests for src/cleanupExpiredPendingBookings.ts + completeCheckedOutBookings.ts.
 *
 * Both are scheduled CFs that exercise the same batch-delete / batch-update
 * recovery pattern. We test happy path + empty result + filter-out external
 * iCal + batch failure → individual fallback.
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

// Per-test snap + batch behavior.
interface FakeDoc {
  id: string;
  data: () => Record<string, unknown>;
  ref: {
    delete: jest.Mock;
    update: jest.Mock;
  };
}

const state: {
  expiredDocs: FakeDoc[];
  checkoutDocs: FakeDoc[];
  batchCommitFail: boolean;
} = {
  expiredDocs: [],
  checkoutDocs: [],
  batchCommitFail: false,
};

function makeDoc(id: string, data: Record<string, unknown>): FakeDoc {
  return {
    id,
    data: () => data,
    ref: {
      delete: jest.fn().mockResolvedValue(true),
      update: jest.fn().mockResolvedValue(true),
    },
  };
}

jest.mock("../src/firebase", () => {
  // Lazy build a snapshot for each collectionGroup query.
  const collectionGroup = (name: string) => {
    const chain: any = {
      where: () => chain,
      limit: () => chain,
      get: async () => {
        if (name !== "bookings") return {empty: true, docs: [], size: 0};
        // Heuristic: the cleanup query filters by status=pending +
        // stripe_pending_expires_at < now; complete query filters by
        // status in (confirmed, pending) + check_out < today.
        // Tests inject the right doc list per-spec via `state.*`.
        const docs = state.expiredDocs.length > 0 ? state.expiredDocs : state.checkoutDocs;
        return {empty: docs.length === 0, docs, size: docs.length};
      },
    };
    return chain;
  };

  return {
    admin: {
      firestore: {
        Timestamp: {
          fromDate: (d: Date) => ({toMillis: () => d.getTime(), toDate: () => d}),
          now: () => ({toMillis: () => Date.now()}),
        },
      },
    },
    db: {
      collectionGroup,
      batch: () => ({
        delete: jest.fn(),
        update: jest.fn(),
        commit: async () => {
          if (state.batchCommitFail) {
            throw new Error("simulated batch commit failure");
          }
          return [];
        },
      }),
    },
  };
});

jest.mock("../src/logger", () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
  logSuccess: jest.fn(),
}));

import {cleanupExpiredStripePendingBookings} from "../src/cleanupExpiredPendingBookings";
import {autoCompleteCheckedOutBookings} from "../src/completeCheckedOutBookings";

const {wrap} = test;

describe("cleanupExpiredStripePendingBookings", () => {
  const wrapped = wrap(cleanupExpiredStripePendingBookings);

  beforeEach(() => {
    state.expiredDocs = [];
    state.checkoutDocs = [];
    state.batchCommitFail = false;
    jest.clearAllMocks();
  });

  it("logs empty result when no expired pending bookings", async () => {
    const {logInfo} = require("../src/logger");
    await wrapped({});
    const allMsgs = logInfo.mock.calls.map((c: any[]) => c[0]).join("|");
    expect(allMsgs).toMatch(/No expired Stripe pending bookings/);
  });

  it("commits batch delete on happy path", async () => {
    state.expiredDocs = [
      makeDoc("b-1", {booking_reference: "BB-001"}),
      makeDoc("b-2", {booking_reference: "BB-002"}),
      makeDoc("b-3", {booking_reference: "BB-003"}),
    ];
    const {logSuccess} = require("../src/logger");
    await wrapped({});
    // No fallback per-doc deletes when batch commits.
    for (const d of state.expiredDocs) {
      expect(d.ref.delete).not.toHaveBeenCalled();
    }
    const success = logSuccess.mock.calls.find((c: any[]) => /Cleanup completed/.test(c[0]));
    expect(success).toBeDefined();
    expect(success[1].successfulDeletions).toBe(3);
    expect(success[1].failedDeletions).toBe(0);
  });

  it("falls back to per-doc delete when batch commit fails", async () => {
    state.expiredDocs = [makeDoc("b-1", {}), makeDoc("b-2", {})];
    state.batchCommitFail = true;
    await wrapped({});
    expect(state.expiredDocs[0].ref.delete).toHaveBeenCalledTimes(1);
    expect(state.expiredDocs[1].ref.delete).toHaveBeenCalledTimes(1);
  });

  it("counts failed deletes and logs failed_ids", async () => {
    const doc1 = makeDoc("ok", {});
    const doc2 = makeDoc("bad", {});
    doc2.ref.delete = jest.fn().mockRejectedValue(new Error("perm denied"));
    state.expiredDocs = [doc1, doc2];
    state.batchCommitFail = true;
    const {logSuccess, logError} = require("../src/logger");
    await wrapped({});
    const summary = logSuccess.mock.calls.find((c: any[]) => /Cleanup completed/.test(c[0]));
    expect(summary[1].successfulDeletions).toBe(1);
    expect(summary[1].failedDeletions).toBe(1);
    expect(summary[1].failedIds).toEqual(["bad"]);
    const errCall = logError.mock.calls.find((c: any[]) => /Some deletions failed/.test(c[0]));
    expect(errCall).toBeDefined();
  });
});

describe("autoCompleteCheckedOutBookings", () => {
  const wrapped = wrap(autoCompleteCheckedOutBookings);

  beforeEach(() => {
    state.expiredDocs = [];
    state.checkoutDocs = [];
    state.batchCommitFail = false;
    jest.clearAllMocks();
  });

  it("logs empty result when no checked-out bookings", async () => {
    const {logInfo} = require("../src/logger");
    await wrapped({});
    const msgs = logInfo.mock.calls.map((c: any[]) => c[0]).join("|");
    expect(msgs).toMatch(/No checked-out bookings found/);
  });

  it("filters out external bookings by source field", async () => {
    state.checkoutDocs = [
      makeDoc("native-1", {source: undefined}),
      makeDoc("ext-1", {source: "Airbnb"}),
      makeDoc("ext-2", {source: "booking_com"}),
      makeDoc("ext-3", {source: "ical"}),
      makeDoc("ext-4", {source: "external"}),
    ];
    const {logSuccess} = require("../src/logger");
    await wrapped({});
    // Only native-1 was updated.
    expect(state.checkoutDocs[0].ref.update).not.toHaveBeenCalled(); // batch commit branch
    const summary = logSuccess.mock.calls.find((c: any[]) => /Auto-complete job finished/.test(c[0]));
    expect(summary[1].successfulUpdates).toBe(1);
    expect(summary[1].filteredOut).toBe(4);
  });

  it("filters out ical_-prefixed booking IDs", async () => {
    state.checkoutDocs = [
      makeDoc("regular-1", {}),
      makeDoc("ical_imported-1", {}),
      makeDoc("ical_imported-2", {}),
    ];
    const {logSuccess} = require("../src/logger");
    await wrapped({});
    const summary = logSuccess.mock.calls.find((c: any[]) => /Auto-complete job finished/.test(c[0]));
    expect(summary[1].successfulUpdates).toBe(1);
    expect(summary[1].filteredOut).toBe(2);
  });

  it("short-circuits when all filtered out (no batch commit)", async () => {
    state.checkoutDocs = [
      makeDoc("ical_a", {}),
      makeDoc("ical_b", {}),
    ];
    const {logInfo} = require("../src/logger");
    await wrapped({});
    const msgs = logInfo.mock.calls.map((c: any[]) => c[0]).join("|");
    expect(msgs).toMatch(/All checked-out bookings are external\/iCal/);
  });

  it("falls back to per-doc update when batch commit fails", async () => {
    state.checkoutDocs = [makeDoc("a", {}), makeDoc("b", {})];
    state.batchCommitFail = true;
    await wrapped({});
    expect(state.checkoutDocs[0].ref.update).toHaveBeenCalledWith(
      expect.objectContaining({status: "completed"})
    );
    expect(state.checkoutDocs[1].ref.update).toHaveBeenCalledTimes(1);
  });

  it("commits batch update on happy path with status=completed", async () => {
    state.checkoutDocs = [makeDoc("ok-1", {}), makeDoc("ok-2", {}), makeDoc("ok-3", {})];
    const {logSuccess} = require("../src/logger");
    await wrapped({});
    const summary = logSuccess.mock.calls.find((c: any[]) => /Auto-complete job finished/.test(c[0]));
    expect(summary[1].successfulUpdates).toBe(3);
    expect(summary[1].failedUpdates).toBe(0);
  });
});
