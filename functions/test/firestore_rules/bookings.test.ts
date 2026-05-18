/**
 * Firestore Rules Tests — Bookings (T11-hotfix-partial)
 *
 * Verifies the booking-read security boundary after the public-read clauses on
 * `stripe_session_id` and `booking_reference` were removed from
 * `firestore.rules`. Clause 1 (unit_id + status) is INTENTIONALLY kept and is
 * still expected to allow the widget calendar availability queries until the
 * T11c availability CF rollout (see audit/06-availability-cf-design.md).
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

describe("bookings rule (T11-hotfix-partial)", () => {
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

  test("widget calendar (unit_id + status) clause STILL ALLOWS reads — kept until T11c", async () => {
    // INTENTIONAL: Until T11c (getUnitAvailability CF rollout) the widget needs
    // to read booking documents to render the calendar overlay. This test is
    // the regression guard that ensures the migration sequencing isn't broken
    // by an accidental rule tightening.
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(ctx.firestore().doc(BOOKING_PATH).get());
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
});
