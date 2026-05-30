/**
 * Firestore Rules Tests — Direct-write hardening (SF-068, audit/86)
 *
 * F-94-02-UPDATE — properties.subdomain CF-only:
 *   Owner can NOT bump subdomain via Firestore SDK; must call
 *   setPropertySubdomain callable. Also locks owner_id + created_at
 *   immutability on update (ownership-transfer + audit-trail integrity).
 *
 * F-94-03 — ical_feeds stats injection:
 *   sync_count / event_count / last_synced are CF-managed (icalSync.ts).
 *   Owner direct-write of these denied — otherwise owner can fake stats
 *   or freeze scheduled sync via future last_synced.
 *
 * F-94-04 — widget_settings ical_cache_* injection:
 *   ical_cache_content / ical_cache_generated_at / ical_cache_etag /
 *   ical_cache_unit_name are CF-managed (icalExport.ts + utils/icalCache.ts).
 *   Owner direct-write denied — otherwise owner can serve arbitrary content
 *   to external aggregators via the cached iCal feed, or freeze the cache
 *   by setting a future generated_at.
 *
 * Foreign-UID + benign-passthrough rows confirm we did not regress the
 * existing owner-write happy path.
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
const PROJECT_ID = "bookbed-rules-test-direct-write";

let testEnv: RulesTestEnvironment;

const OWNER_UID = "owner-uid-001";
const FOREIGN_UID = "foreign-uid-002";
const PROPERTY_ID = "prop-DW";
const UNIT_ID = "unit-DW";
const FEED_ID = "feed-DW";

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
      description: "Initial desc",
      subdomain: "initial-subdomain",
      created_at: new Date("2026-01-01"),
      updated_at: new Date("2026-01-01"),
    });
    await db.doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}`).set({
      property_id: PROPERTY_ID,
      name: "Test Unit",
    });
    await db
      .doc(`properties/${PROPERTY_ID}/ical_feeds/${FEED_ID}`)
      .set({
        unit_id: UNIT_ID,
        property_id: PROPERTY_ID,
        platform: "airbnb",
        ical_url: "https://airbnb.com/x.ics",
        import_enabled: true,
        sync_interval_minutes: 15,
        status: "active",
        last_error: null,
        sync_count: 5,
        event_count: 12,
        last_synced: new Date("2026-05-29"),
        created_at: new Date("2026-05-01"),
        updated_at: new Date("2026-05-29"),
      });
    await db
      .doc(`properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`)
      .set({
        property_id: PROPERTY_ID,
        owner_id: OWNER_UID,
        ical_export_enabled: true,
        widget_mode: "booking_pending",
        ical_cache_content: "BEGIN:VCALENDAR\nEND:VCALENDAR",
        ical_cache_generated_at: new Date("2026-05-29"),
        ical_cache_etag: "abc123",
        ical_cache_unit_name: "Real Unit Name",
        updated_at: new Date("2026-05-29"),
      });
  });
});

describe("properties.create — F-94-02 format guard (SF-068)", () => {
  test("create with subdomain=null ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-a`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: null,
      }),
    );
  });

  test("create with subdomain absent ALLOWED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-b`).set({
        owner_id: OWNER_UID,
        name: "p",
      }),
    );
  });

  test("create with format-valid subdomain ALLOWED (squat still OPEN)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-c`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: "valid-name-123",
      }),
    );
  });

  test("create with too-short subdomain (2 chars) DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-d`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: "ab",
      }),
    );
  });

  test("create with too-long subdomain (>30 chars) DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-e`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: "a".repeat(31),
      }),
    );
  });

  test("create with leading-hyphen subdomain DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-f`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: "-leading",
      }),
    );
  });

  test("create with special-char subdomain DENIED", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-g`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: "abc'); DROP",
      }),
    );
  });

  test("create with uppercase subdomain DENIED (lowercase-only regex)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-h`).set({
        owner_id: OWNER_UID,
        name: "p",
        subdomain: "ValidButCAPS",
      }),
    );
  });

  test("create with mismatched owner_id DENIED (canCreateAsOwner)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/new-${OWNER_UID}-i`).set({
        owner_id: FOREIGN_UID,
        name: "p",
        subdomain: "valid-name",
      }),
    );
  });
});

describe("properties.update — F-94-02-UPDATE (SF-068)", () => {
  test("owner DENIED writing subdomain field (CF-only)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}`)
        .update({subdomain: "squatted-name"}),
    );
  });

  test("owner DENIED writing owner_id (ownership-transfer block)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}`)
        .update({owner_id: FOREIGN_UID}),
    );
  });

  test("owner DENIED writing created_at (audit-trail integrity)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}`)
        .update({created_at: new Date("2020-01-01")}),
    );
  });

  test("owner DENIED mixing benign + protected field (atomic)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(`properties/${PROPERTY_ID}`).update({
        name: "Renamed",
        subdomain: "squat-attempt",
      }),
    );
  });

  test("owner ALLOWED updating benign fields (name + description)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(`properties/${PROPERTY_ID}`)
        .update({name: "Renamed Property", description: "Updated desc"}),
    );
  });

  test("foreign uid DENIED writing any property field", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx.firestore().doc(`properties/${PROPERTY_ID}`).update({name: "Pwn"}),
    );
  });
});

describe("ical_feeds.update — F-94-03 stats injection (SF-068)", () => {
  const FEED_PATH = `properties/${PROPERTY_ID}/ical_feeds/${FEED_ID}`;

  test("owner DENIED inflating sync_count", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(FEED_PATH).update({sync_count: 99999}),
    );
  });

  test("owner DENIED inflating event_count", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(FEED_PATH).update({event_count: 99999}),
    );
  });

  test("owner DENIED writing last_synced (could freeze scheduler)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(FEED_PATH)
        .update({last_synced: new Date("2099-01-01")}),
    );
  });

  test("owner DENIED mixing benign + stats field (atomic)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(FEED_PATH)
        .update({ical_url: "https://new.example/x.ics", sync_count: 1}),
    );
  });

  test("owner ALLOWED updating ical_url (benign passthrough)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(FEED_PATH)
        .update({ical_url: "https://new.airbnb.com/x.ics"}),
    );
  });

  test("owner ALLOWED pausing feed via status field (legit client write)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(FEED_PATH).update({status: "paused"}),
    );
  });

  test("owner ALLOWED toggling import_enabled (legit client write)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(FEED_PATH).update({import_enabled: false}),
    );
  });

  test("foreign uid DENIED writing any feed field", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(FEED_PATH)
        .update({ical_url: "https://pwn.example/x.ics"}),
    );
  });
});

describe("widget_settings.update — F-94-04 cache injection (SF-068)", () => {
  const WS_PATH = `properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`;

  test("owner DENIED writing ical_cache_content (feed-injection vector)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(WS_PATH)
        .update({
          ical_cache_content: "BEGIN:VCALENDAR\nSUMMARY:Pwned\nEND:VCALENDAR",
        }),
    );
  });

  test("owner DENIED writing ical_cache_generated_at (cache freeze)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(WS_PATH)
        .update({ical_cache_generated_at: new Date("2099-01-01")}),
    );
  });

  test("owner DENIED writing ical_cache_etag", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx.firestore().doc(WS_PATH).update({ical_cache_etag: "fake-etag"}),
    );
  });

  test("owner DENIED writing ical_cache_unit_name", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(WS_PATH)
        .update({ical_cache_unit_name: "Pwned Unit"}),
    );
  });

  test("owner DENIED mixing benign + cache field (atomic)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(WS_PATH)
        .update({
          widget_mode: "booking_instant",
          ical_cache_content: "PWN",
        }),
    );
  });

  test("owner ALLOWED updating widget_mode (benign passthrough)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx
        .firestore()
        .doc(WS_PATH)
        .update({widget_mode: "booking_instant"}),
    );
  });

  test("owner ALLOWED toggling ical_export_enabled (legit client write)", async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      ctx.firestore().doc(WS_PATH).update({ical_export_enabled: false}),
    );
  });

  test("foreign uid DENIED writing any widget_settings field", async () => {
    const ctx = testEnv.authenticatedContext(FOREIGN_UID);
    await assertFails(
      ctx
        .firestore()
        .doc(WS_PATH)
        .update({widget_mode: "booking_pending"}),
    );
  });
});
