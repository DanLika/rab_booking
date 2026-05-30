/**
 * Firestore Rules Tests — Bookings (T11c CLOSED, 2026-05-22)
 *
 * Verifies the booking-read security boundary after T11c — the
 * unit_id+status public-read clause is now REMOVED. Widget calendar reads
 * route through the `getUnitAvailability` Cloud Function instead. Anonymous
 * direct reads of booking docs must now FAIL regardless of which "lookup"
 * field the caller supplies.
 *
 * History:
 *   - T11-hotfix-partial (2026-05-18, commit 9f3d86b4):
 *       stripe_session_id + booking_reference public clauses removed.
 *   - T11c (2026-05-22, this file):
 *       unit_id + status public clause removed → last anonymous surface closed.
 */

import * as fs from "fs";
import * as path from "path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestContext,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

const RULES_FILE = path.resolve(__dirname, "../../../firestore.rules");
const PROJECT_ID = "bookbed-rules-test";

let testEnv: RulesTestEnvironment;

const OWNER_UID = "owner-uid-123";
const FOREIGN_UID = "intruder-uid-456";
const ADMIN_CLAIM_UID = "admin-claim-uid";
const ADMIN_FIRESTORE_UID = "admin-firestore-uid";
const PROPERTY_ID = "prop-A";
const UNIT_ID = "unit-A1";
const BOOKING_ID = "booking-A1-001";
const BOOKING_PATH = `properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/${BOOKING_ID}`;

const FULL_BOOKING_DOC = {
  owner_id: OWNER_UID,
  property_id: PROPERTY_ID,
  unit_id: UNIT_ID,
  status: "confirmed",
  guest_email: "guest@example.com",
  guest_name: "Guest Example",
  booking_reference: "BK-ABCDEF",
  stripe_session_id: "cs_test_aaaaaaaa",
  total_price: 100,
  check_in: new Date("2026-06-01"),
  check_out: new Date("2026-06-05"),
};

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_FILE, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
    const db = ctx.firestore();
    await db.doc(`properties/${PROPERTY_ID}`).set({
      owner_id: OWNER_UID,
      name: "Test Property",
    });
    await db.doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}`).set({
      property_id: PROPERTY_ID,
      name: "Test Unit",
    });
    await db.doc(BOOKING_PATH).set(FULL_BOOKING_DOC);
    await db.doc(`users/${ADMIN_FIRESTORE_UID}`).set({role: "admin"});
    await db.doc(`users/${OWNER_UID}`).set({role: "user"});
    await db.doc(`users/${FOREIGN_UID}`).set({role: "user"});
    await db.doc(`users/${ADMIN_CLAIM_UID}`).set({role: "user"});
  });
});

describe("bookings rule (T11c closed)", () => {
  test("unauthenticated reader is DENIED on subcollection booking when clause 1 missing", async () => {
    // Remove the unit_id+status clause-1 enabling fields to isolate this case.
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        booking_reference: "BK-ABCDEF",
        stripe_session_id: "cs_test_aaaaaaaa",
      });
    });
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("foreign authenticated uid is DENIED reading someone else's booking (clause 1 absent)", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        booking_reference: "BK-ABCDEF",
      });
    });
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("booking owner_id ALLOWED via owner_id clause", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("admin via isAdmin() custom claim ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_CLAIM_UID, {isAdmin: true});
    await assertSucceeds(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("admin via Firestore /users/{uid}.role=='admin' ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_FIRESTORE_UID);
    await assertSucceeds(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("widget calendar (unit_id + status) clause DENIED — T11c closed", async () => {
    // T11c (2026-05-22): the unit_id+status public-read clause was removed
    // after the widget migrated to the `getUnitAvailability` callable. This
    // is the regression guard that the clause does not silently come back.
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("authenticated stranger reading by stripe_session_id alone is DENIED (clause removed)", async () => {
    // Pre-hotfix this read succeeded via the `'stripe_session_id' in resource.data` clause.
    // Mutate the doc to strip unit_id/status so clause 1 cannot mask the regression.
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        stripe_session_id: "cs_test_aaaaaaaa",
      });
    });
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("authenticated stranger reading by booking_reference alone is DENIED (clause removed)", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        booking_reference: "BK-ABCDEF",
      });
    });
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  // ---- audit/16-cf-smoke-and-rules: extended clause-1 shape coverage ----

  test("clause 1 — unit_id + status BOTH present → unauth DENIED (T11c closed)", async () => {
    // T11c (2026-05-22): clause 1 removed. Even when both unit_id + status
    // are present, anonymous callers MUST be denied. The widget reads
    // availability via the getUnitAvailability callable now, not direct CG.
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("clause 1 — only unit_id present (status missing) → unauth DENIED", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        unit_id: UNIT_ID,
        // status intentionally omitted
      });
    });
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  test("clause 1 — only status present (unit_id missing) → unauth DENIED", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx.firestore().doc(BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        status: "confirmed",
        // unit_id intentionally omitted
      });
    });
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(BOOKING_PATH).get());
  });

  // ---- audit/78 Phase B: status-machine field denylist on client SDK updates ----

  test("Phase B — owner update with status field DENIED (must use approveBooking CF)", async () => {
    // Use a DIFFERENT value than the seed ('confirmed') so diff() detects a change.
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({status: "cancelled"}),
    );
  });

  test("Phase B — owner update with any of the 7 status-machine fields DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    const denied = [
      {approved_at: new Date()},
      {rejected_at: new Date()},
      {rejection_reason: "spam"},
      {cancelled_at: new Date()},
      {cancellation_reason: "guest no-show"},
      {completed_at: new Date()},
    ];
    for (const patch of denied) {
      await assertFails(ctx.firestore().doc(BOOKING_PATH).update(patch));
    }
  });

  test("Phase B — owner update of non-status fields ALLOWED (internal_notes)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(BOOKING_PATH).update({internal_notes: "VIP — repeat guest"}),
    );
  });

  test("Phase B — owner update mixing allowed + denied field DENIED (atomic)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({
        internal_notes: "moved to cancelled",
        status: "cancelled", // diff() vs seed 'confirmed' → poisons the write
      }),
    );
  });

  test("Phase B — create with pending status ALLOWED (status set, not affected by diff)", async () => {
    const NEW_BOOKING_PATH =
      `properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/new-booking-phase-b`;
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(NEW_BOOKING_PATH).set({
        owner_id: OWNER_UID,
        property_id: PROPERTY_ID,
        unit_id: UNIT_ID,
        status: "pending",
        guest_email: "guest@example.com",
        guest_name: "New Guest",
        total_price: 50,
        check_in: new Date("2026-07-01"),
        check_out: new Date("2026-07-03"),
      }),
    );
  });

  test("Phase B — foreign uid update still DENIED (not property owner) regardless of fields", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({internal_notes: "hijack"}),
    );
  });

  test("Phase B — owner delete still ALLOWED (rule split preserved delete semantics)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(BOOKING_PATH).delete());
  });

  // ---- F-99-01 (audit/100): CF-managed scalar deny extends Phase B coverage ----

  test("F-99-01 — owner update of payment_intent_id DENIED (Stripe webhook lookup key)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({payment_intent_id: "pi_test_other"}),
    );
  });

  test("F-99-01 — owner update of emails_sent DENIED (CF idempotency marker)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({
        emails_sent: {initial_trigger_processed: true},
      }),
    );
  });

  test("F-99-01 — owner update of booking_reference DENIED (guest lookup capability)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({booking_reference: "BK-FORGED"}),
    );
  });

  test("F-99-01 — owner update of owner_id DENIED (cross-owner detach)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({owner_id: FOREIGN_UID}),
    );
  });

  test("F-99-01 — owner update of created_at DENIED (audit-trail tamper)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({created_at: new Date("2020-01-01")}),
    );
  });

  test("F-99-01 — owner update of source DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({source: "imported"}),
    );
  });

  test("F-99-01 — owner update of provider_id DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(BOOKING_PATH).update({provider_id: "airbnb"}),
    );
  });

  test("F-99-01 — owner update of internal_notes still ALLOWED (deny-list narrow)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(BOOKING_PATH).update({internal_notes: "follow-up email sent"}),
    );
  });
});
