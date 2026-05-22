/**
 * Firestore Rules Tests — ical_events (SF-023)
 *
 * Verifies the lockdown of the `properties/{p}/units/{u}/ical_events/{e}`
 * subcollection + the matching collection-group path. Pre-fix, both paths
 * had `allow read: if true`, exposing guest_name + dates per-unit via an
 * anonymous CG query. The widget calendar + availability gate were rewired
 * to route through the `getUnitAvailability` callable so client-side
 * Firestore reads of `ical_events` are no longer required.
 *
 * The regression guards below pin: anonymous CG reads DENIED, owner reads
 * ALLOWED, foreign user DENIED, all client writes DENIED. The latter
 * matters because the legacy rule allowed owner writes from the client —
 * `icalSync.ts` always wrote via Admin SDK, so removing client write is a
 * surface-area reduction with zero functional impact.
 *
 * The `booking_services` rule cleanup (orphan junction table — zero
 * readers/writers across functions/src/** and lib/** per audit/16) is
 * covered too: anonymous + authenticated reads must DENY.
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
const PROPERTY_ID = "prop-A";
const UNIT_ID = "unit-A1";
const EVENT_ID = "evt-A1-001";
const EVENT_PATH = `properties/${PROPERTY_ID}/units/${UNIT_ID}/ical_events/${EVENT_ID}`;

const ICAL_EVENT_DOC = {
  property_id: PROPERTY_ID,
  unit_id: UNIT_ID,
  start_date: new Date("2026-07-01"),
  end_date: new Date("2026-07-05"),
  source: "Airbnb",
  status: "imported",
  guest_name: "External Guest",
};

const BOOKING_SERVICE_ID = "bsvc-001";
const BOOKING_SERVICE_PATH = `booking_services/${BOOKING_SERVICE_ID}`;

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
    await db.doc(EVENT_PATH).set(ICAL_EVENT_DOC);
    // Seed booking_services so the deletion-rule test has a real doc to
    // request (without it, missing-doc returns null and rules don't run).
    await db.doc(BOOKING_SERVICE_PATH).set({
      booking_id: "booking-X",
      service_id: "svc-Y",
    });
  });
});

describe("ical_events rule (SF-023 lockdown)", () => {
  test("anonymous read of subcollection doc is DENIED", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(EVENT_PATH).get());
  });

  test("foreign authenticated uid is DENIED reading another owner's ical_event", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(ctx.firestore().doc(EVENT_PATH).get());
  });

  test("property owner ALLOWED reading their own ical_event", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(ctx.firestore().doc(EVENT_PATH).get());
  });

  test("owner CLIENT write (create) is DENIED — CF Admin SDK is the sole writer", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(
          `properties/${PROPERTY_ID}/units/${UNIT_ID}/ical_events/new-evt`
        )
        .set({
          property_id: PROPERTY_ID,
          unit_id: UNIT_ID,
          start_date: new Date("2026-08-01"),
          end_date: new Date("2026-08-05"),
        })
    );
  });

  test("owner CLIENT write (update) is DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(EVENT_PATH).update({source: "Mutated"})
    );
  });

  test("owner CLIENT write (delete) is DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(ctx.firestore().doc(EVENT_PATH).delete());
  });

  test("CG query — anonymous DENIED for any ical_event doc", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(
      ctx
        .firestore()
        .collectionGroup("ical_events")
        .where("unit_id", "==", UNIT_ID)
        .get()
    );
  });

  test("CG query — owner ALLOWED to read by property_id filter", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .collectionGroup("ical_events")
        .where("property_id", "==", PROPERTY_ID)
        .get()
    );
  });

  test("CG query — foreign uid DENIED on owner's property_id filter", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx
        .firestore()
        .collectionGroup("ical_events")
        .where("property_id", "==", PROPERTY_ID)
        .get()
    );
  });

  test("legacy top-level /ical_events/* read is DENIED (rule removed)", async () => {
    // The deprecated top-level rule was deleted in this PR. Default-deny
    // catch-all now applies. Anonymous, owner, and admin alike are denied
    // — the path is no longer addressable from the client at all.
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(`ical_events/${EVENT_ID}`).get());
  });
});

describe("booking_services rule (SF-023 follow-up cleanup)", () => {
  test("anonymous read is DENIED (rule removed → default deny)", async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(ctx.firestore().doc(BOOKING_SERVICE_PATH).get());
  });

  test("authenticated read is DENIED (rule removed → default deny)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(ctx.firestore().doc(BOOKING_SERVICE_PATH).get());
  });

  test("client write is DENIED (rule removed → default deny)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc("booking_services/new-svc").set({
        booking_id: "booking-Y",
        service_id: "svc-Z",
      })
    );
  });
});
