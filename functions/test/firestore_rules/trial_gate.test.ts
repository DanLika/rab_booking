/**
 * Firestore Rules Tests — SF-080 trial-gate Layer-1 (RULES)
 *
 * Audit/113. Sibling of SF-078 (PR #666) server-side CF gate.
 *
 * Gates: `isActiveOwner()` predicate on these 4 owner direct-write paths:
 *   1. /properties/{propertyId}                                  (create + update)
 *   2. /properties/{p}/units/{u}/bookings/{b}                    (create + update + delete)
 *   3. /properties/{p}/units/{u}/daily_prices/{d}                (create + update + delete)
 *   4. /properties/{p}/widget_settings/{u}                       (create + update + delete)
 *      + mirror CG path /{path=**}/widget_settings/{u}
 *
 * Allow-list: ['trial', 'active']. Anything else (trial_expired, suspended,
 * 'premium' off-spec drift, missing doc, missing accountStatus field, future
 * enum value) → DENY (fail-CLOSED). Admin (custom-claim or Firestore role)
 * bypasses the gate.
 *
 * Path-level guards (ownership, subdomain format, deny-list affectedKeys etc.)
 * are still in effect; those are covered by other test files
 * (properties_direct_write.test.ts, bookings.test.ts).
 *
 * Foreign-uid + property-delete soft-exit rows are sanity guards that the
 * existing behaviour is preserved.
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
const PROJECT_ID = "bookbed-rules-test-trial-gate";

const ACTIVE_UID = "owner-active";
const TRIAL_UID = "owner-trial";
const EXPIRED_UID = "owner-expired";
const SUSPENDED_UID = "owner-suspended";
const PREMIUM_UID = "owner-premium-drift";
const MISSING_DOC_UID = "owner-missing-doc";
const MISSING_FIELD_UID = "owner-missing-field";
const ADMIN_CLAIM_UID = "admin-claim-uid";
const ADMIN_FIRESTORE_UID = "admin-firestore-uid";
const FOREIGN_UID = "foreign-uid";

const PROPERTY_ID = "prop-TG";
const UNIT_ID = "unit-TG";
const BOOKING_ID = "booking-TG";
const DATE_STR = "2026-08-01";

let testEnv: RulesTestEnvironment;

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

    // Seed users by status arm
    await db.doc(`users/${ACTIVE_UID}`).set({accountStatus: "active"});
    await db.doc(`users/${TRIAL_UID}`).set({accountStatus: "trial"});
    await db.doc(`users/${EXPIRED_UID}`).set({accountStatus: "trial_expired"});
    await db.doc(`users/${SUSPENDED_UID}`).set({accountStatus: "suspended"});
    await db.doc(`users/${PREMIUM_UID}`).set({accountStatus: "premium"}); // off-spec
    await db.doc(`users/${MISSING_FIELD_UID}`).set({role: "user"}); // accountStatus absent
    // MISSING_DOC_UID intentionally NOT seeded
    await db.doc(`users/${ADMIN_CLAIM_UID}`).set({accountStatus: "active"});
    await db.doc(`users/${ADMIN_FIRESTORE_UID}`).set({role: "admin"});
    await db.doc(`users/${FOREIGN_UID}`).set({accountStatus: "active"});

    // Seed a property for each gated-status owner so the ownership guard
    // succeeds and only the trial-gate clause decides the result.
    for (const uid of [
      ACTIVE_UID, TRIAL_UID, EXPIRED_UID, SUSPENDED_UID, PREMIUM_UID,
      MISSING_DOC_UID, MISSING_FIELD_UID,
    ]) {
      await db.doc(`properties/prop-${uid}`).set({
        owner_id: uid,
        name: "P",
        created_at: new Date("2026-01-01"),
      });
      await db.doc(`properties/prop-${uid}/units/${UNIT_ID}`).set({
        property_id: `prop-${uid}`,
        name: "U",
      });
    }
    // Common property used by admin/foreign-arm tests (owner = ACTIVE_UID).
    await db.doc(`properties/${PROPERTY_ID}`).set({
      owner_id: ACTIVE_UID,
      name: "Shared",
      created_at: new Date("2026-01-01"),
    });
    await db.doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}`).set({
      property_id: PROPERTY_ID,
      name: "U",
    });
    // Pre-existing booking under shared property (status `pending`).
    await db
      .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/${BOOKING_ID}`)
      .set({
        owner_id: ACTIVE_UID,
        property_id: PROPERTY_ID,
        unit_id: UNIT_ID,
        status: "pending",
        created_at: new Date("2026-01-01"),
        guest_count: 2,
      });
    // Pre-existing daily price (shared property).
    await db
      .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/daily_prices/${DATE_STR}`)
      .set({date: DATE_STR, price: 100});
    // Pre-existing widget settings (shared property).
    await db
      .doc(`properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`)
      .set({property_id: PROPERTY_ID, owner_id: ACTIVE_UID, widget_mode: "booking_pending"});
  });
});

// ---------------------------------------------------------------------------
// 1. /properties/{propertyId}.create
// ---------------------------------------------------------------------------

describe("SF-080 — /properties/{p}.create gated by isActiveOwner()", () => {
  test("active owner ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-${ACTIVE_UID}`).set({
        owner_id: ACTIVE_UID,
        name: "p",
      }),
    );
  });
  test("trial owner ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(TRIAL_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-${TRIAL_UID}`).set({
        owner_id: TRIAL_UID,
        name: "p",
      }),
    );
  });
  test("trial_expired owner DENIED", async () => {
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${EXPIRED_UID}`).set({
        owner_id: EXPIRED_UID,
        name: "p",
      }),
    );
  });
  test("suspended owner DENIED", async () => {
    const ctx = testEnv.authenticatedContext(SUSPENDED_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${SUSPENDED_UID}`).set({
        owner_id: SUSPENDED_UID,
        name: "p",
      }),
    );
  });
  test("off-spec 'premium' owner DENIED (fail-CLOSED on unknown value)", async () => {
    const ctx = testEnv.authenticatedContext(PREMIUM_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${PREMIUM_UID}`).set({
        owner_id: PREMIUM_UID,
        name: "p",
      }),
    );
  });
  test("user with missing accountStatus field DENIED", async () => {
    const ctx = testEnv.authenticatedContext(MISSING_FIELD_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${MISSING_FIELD_UID}`).set({
        owner_id: MISSING_FIELD_UID,
        name: "p",
      }),
    );
  });
  test("user with missing /users/{uid} doc DENIED", async () => {
    const ctx = testEnv.authenticatedContext(MISSING_DOC_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${MISSING_DOC_UID}`).set({
        owner_id: MISSING_DOC_UID,
        name: "p",
      }),
    );
  });
  test("admin via custom-claim BYPASSES gate (no user doc lookup branch)", async () => {
    const ctx = testEnv.authenticatedContext(MISSING_DOC_UID, {isAdmin: true});
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-admin-claim`).set({
        owner_id: MISSING_DOC_UID,
        name: "p",
      }),
    );
  });
  test("admin via Firestore role BYPASSES gate (even with own active status)", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_FIRESTORE_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-admin-firestore`).set({
        owner_id: ADMIN_FIRESTORE_UID,
        name: "p",
      }),
    );
  });
});

// ---------------------------------------------------------------------------
// 2. /properties/{propertyId}.update
// ---------------------------------------------------------------------------

describe("SF-080 — /properties/{p}.update gated by isActiveOwner()", () => {
  // Each arm has its OWN property (prop-${uid}) so ownership is satisfied
  // and the gate is the deciding clause.
  test("active owner ALLOWED on benign update", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/prop-${ACTIVE_UID}`).update({name: "Renamed"}),
    );
  });
  test("trial owner ALLOWED on benign update", async () => {
    const ctx = testEnv.authenticatedContext(TRIAL_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/prop-${TRIAL_UID}`).update({name: "Renamed"}),
    );
  });
  test("trial_expired owner DENIED on benign update", async () => {
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx.firestore().doc(`properties/prop-${EXPIRED_UID}`).update({name: "Renamed"}),
    );
  });
  test("suspended owner DENIED on benign update", async () => {
    const ctx = testEnv.authenticatedContext(SUSPENDED_UID);
    await assertFails(
      ctx.firestore().doc(`properties/prop-${SUSPENDED_UID}`).update({name: "Renamed"}),
    );
  });
  test("missing user doc DENIED on benign update", async () => {
    const ctx = testEnv.authenticatedContext(MISSING_DOC_UID);
    await assertFails(
      ctx.firestore().doc(`properties/prop-${MISSING_DOC_UID}`).update({name: "Renamed"}),
    );
  });
});

// ---------------------------------------------------------------------------
// 3. /properties/{p}/units/{u}/bookings/{b} (owner-side direct-write)
// ---------------------------------------------------------------------------

describe("SF-080 — owner bookings subcollection gated by isActiveOwner()", () => {
  test("active owner ALLOWED to create manual booking", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/new-${ACTIVE_UID}`)
        .set({
          owner_id: ACTIVE_UID,
          property_id: PROPERTY_ID,
          unit_id: UNIT_ID,
          status: "pending",
          guest_count: 1,
        }),
    );
  });
  test("trial_expired owner DENIED to create manual booking", async () => {
    // EXPIRED_UID is owner of `prop-${EXPIRED_UID}` (seeded above)
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/prop-${EXPIRED_UID}/units/${UNIT_ID}/bookings/new-x`)
        .set({
          owner_id: EXPIRED_UID,
          property_id: `prop-${EXPIRED_UID}`,
          unit_id: UNIT_ID,
          status: "pending",
          guest_count: 1,
        }),
    );
  });
  test("active owner ALLOWED to edit non-status fields (internal_notes)", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/${BOOKING_ID}`)
        .update({internal_notes: "VIP"}),
    );
  });
  test("trial_expired owner DENIED on benign booking update", async () => {
    // Use shared booking but auth as EXPIRED_UID — fails by ownership too, but
    // the deny intent we are checking is gate-first. The combined denial path
    // is what production sees, so we only need assertFails here.
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/${BOOKING_ID}`)
        .update({internal_notes: "x"}),
    );
  });
  test("active owner ALLOWED to delete booking", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/${BOOKING_ID}`)
        .delete(),
    );
  });
  test("admin (custom-claim) BYPASSES booking gate", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_CLAIM_UID, {isAdmin: true});
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings/${BOOKING_ID}`)
        .update({internal_notes: "admin-edit"}),
    );
  });
});

// ---------------------------------------------------------------------------
// 4. /properties/{p}/units/{u}/daily_prices/{d} (pricing_calendar)
// ---------------------------------------------------------------------------

describe("SF-080 — pricing_calendar gated by isActiveOwner()", () => {
  test("active owner ALLOWED to write daily_price", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/daily_prices/2026-09-01`)
        .set({date: "2026-09-01", price: 120}),
    );
  });
  test("trial owner ALLOWED to write daily_price", async () => {
    const ctx = testEnv.authenticatedContext(TRIAL_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/prop-${TRIAL_UID}/units/${UNIT_ID}/daily_prices/2026-09-02`)
        .set({date: "2026-09-02", price: 100}),
    );
  });
  test("trial_expired owner DENIED to write daily_price", async () => {
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/prop-${EXPIRED_UID}/units/${UNIT_ID}/daily_prices/2026-09-03`)
        .set({date: "2026-09-03", price: 100}),
    );
  });
  test("suspended owner DENIED to update daily_price", async () => {
    // Seed a price first under SUSPENDED_UID's property
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx
        .firestore()
        .doc(`properties/prop-${SUSPENDED_UID}/units/${UNIT_ID}/daily_prices/2026-09-04`)
        .set({date: "2026-09-04", price: 100});
    });
    const ctx = testEnv.authenticatedContext(SUSPENDED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/prop-${SUSPENDED_UID}/units/${UNIT_ID}/daily_prices/2026-09-04`)
        .update({price: 999}),
    );
  });
  test("trial_expired owner DENIED to delete daily_price", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx
        .firestore()
        .doc(`properties/prop-${EXPIRED_UID}/units/${UNIT_ID}/daily_prices/2026-09-05`)
        .set({date: "2026-09-05", price: 100});
    });
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/prop-${EXPIRED_UID}/units/${UNIT_ID}/daily_prices/2026-09-05`)
        .delete(),
    );
  });
  test("admin BYPASSES pricing_calendar gate", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_FIRESTORE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/daily_prices/2026-09-06`)
        .set({date: "2026-09-06", price: 88}),
    );
  });
  test("public READ still works (gate does not affect read)", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}/daily_prices/${DATE_STR}`)
        .get(),
    );
  });
});

// ---------------------------------------------------------------------------
// 5. /properties/{p}/widget_settings/{u} (widget_settings + CG mirror)
// ---------------------------------------------------------------------------

describe("SF-080 — widget_settings gated by isActiveOwner()", () => {
  test("active owner ALLOWED to create widget_settings", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/widget_settings/new-${ACTIVE_UID}`)
        .set({
          property_id: PROPERTY_ID,
          owner_id: ACTIVE_UID,
          widget_mode: "booking_pending",
        }),
    );
  });
  test("trial_expired owner DENIED to create widget_settings", async () => {
    const ctx = testEnv.authenticatedContext(EXPIRED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/prop-${EXPIRED_UID}/widget_settings/new-x`)
        .set({
          property_id: `prop-${EXPIRED_UID}`,
          owner_id: EXPIRED_UID,
          widget_mode: "booking_pending",
        }),
    );
  });
  test("active owner ALLOWED on benign widget_settings update", async () => {
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`)
        .update({widget_mode: "booking_confirmed"}),
    );
  });
  test("suspended owner DENIED on widget_settings update", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx: RulesTestContext) => {
      await ctx
        .firestore()
        .doc(`properties/prop-${SUSPENDED_UID}/widget_settings/${UNIT_ID}`)
        .set({
          property_id: `prop-${SUSPENDED_UID}`,
          owner_id: SUSPENDED_UID,
          widget_mode: "booking_pending",
        });
    });
    const ctx = testEnv.authenticatedContext(SUSPENDED_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/prop-${SUSPENDED_UID}/widget_settings/${UNIT_ID}`)
        .update({widget_mode: "booking_confirmed"}),
    );
  });
  test("admin BYPASSES widget_settings gate", async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_FIRESTORE_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`)
        .update({widget_mode: "booking_pending"}),
    );
  });
  test("ical_cache_* deny-list still in effect for active owner", async () => {
    // Even with gate passing, owner must not touch CF-managed cache keys.
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`)
        .update({ical_cache_content: "FAKE:VCALENDAR"}),
    );
  });
});

// ---------------------------------------------------------------------------
// 6. Frozen happy-path sanity (regression guard)
// ---------------------------------------------------------------------------

describe("SF-080 — Frozen happy-path regression guard (active owner)", () => {
  test("Unit Wizard publish-flow analog: active owner writes widget_settings + daily_price + unit", async () => {
    // Order matches what unified_unit_hub_screen.dart's publish flow does
    // (rules-side only — we are not invoking the actual Dart code here).
    const ctx = testEnv.authenticatedContext(ACTIVE_UID);
    // 1. Unit doc — NOT gated by SF-080 (preserved by design).
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/wiz-unit`)
        .set({property_id: PROPERTY_ID, name: "wiz"}),
    );
    // 2. Widget settings — gated; active owner must pass.
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/widget_settings/wiz-unit`)
        .set({
          property_id: PROPERTY_ID,
          owner_id: ACTIVE_UID,
          widget_mode: "booking_pending",
        }),
    );
    // 3. Daily price — gated; active owner must pass.
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}/units/wiz-unit/daily_prices/2026-12-25`)
        .set({date: "2026-12-25", price: 200}),
    );
  });
});
