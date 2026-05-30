#!/usr/bin/env node
/**
 * audit/86 live probe — F-94-02 / F-94-03 / F-94-04 direct-write deny smoke.
 *
 * Target: bookbed-dev (rules deployed at audit/86 PR head).
 *
 * Provisions throwaway property + ical_feed + widget_settings docs via Admin
 * SDK, mints custom tokens for an owner + a foreign UID, then attempts
 * direct-write writes via the Firebase JS SDK (the same path a real owner
 * device would take). Expected outcomes per cell printed at the end.
 *
 * Usage:
 *   GOOGLE_CLOUD_PROJECT=bookbed-dev node audit86-direct-write-smoke.js
 */

const admin = require("firebase-admin");
const {initializeApp} = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const {getFirestore, doc, updateDoc} = require("firebase/firestore");

const PROJECT_ID = "bookbed-dev";
// Firebase Web client identifier (public by design — ships in every Flutter
// web bundle, restricted server-side via App Check / Auth domain allowlist).
// Read from env to keep this smoke checked into the repo without tripping
// secret-scanners. Source: lib/firebase_options_dev.dart web.apiKey.
const WEB_API_KEY = process.env.BOOKBED_DEV_WEB_API_KEY;
if (!WEB_API_KEY) {
  console.error(
    "Set BOOKBED_DEV_WEB_API_KEY env var (value: lib/firebase_options_dev.dart web.apiKey)"
  );
  process.exit(64);
}
const STAMP = Date.now();
const PROPERTY_ID = `audit86-smoke-prop-${STAMP}`;
const UNIT_ID = `audit86-smoke-unit-${STAMP}`;
const FEED_ID = `audit86-smoke-feed-${STAMP}`;
const FOREIGN_EMAIL = `audit86-smoke-foreign-${STAMP}@bookbed-test.invalid`;
const FOREIGN_PASS = `AuditSmoke_${STAMP}_pwx!`;
// Owner = persistent test account (memory: test-account.md); throwaway
// property is created under this UID and torn down at the end of the run.
const OWNER_EMAIL = process.env.BOOKBED_DEV_OWNER_EMAIL || "bookbed-test@bookbed.io";
const OWNER_PASS = process.env.BOOKBED_DEV_OWNER_PASS;
if (!OWNER_PASS) {
  console.error(
    "Set BOOKBED_DEV_OWNER_PASS env var (memory: test-account.md)."
  );
  process.exit(64);
}

admin.initializeApp({projectId: PROJECT_ID});

const results = [];

function record(label, expected, gotDeny, errCode) {
  const pass = expected === "deny" ? gotDeny : !gotDeny;
  results.push({label, expected, got: gotDeny ? "deny" : "allow", errCode, pass});
}

async function expectDeny(label, fn) {
  try {
    await fn();
    record(label, "deny", false);
  } catch (e) {
    const code = e?.code || e?.message?.slice(0, 80);
    record(label, "deny", true, code);
  }
}

async function expectAllow(label, fn) {
  try {
    await fn();
    record(label, "allow", false);
  } catch (e) {
    const code = e?.code || e?.message?.slice(0, 80);
    record(label, "allow", true, code);
  }
}

async function seed(ownerUid) {
  const db = admin.firestore();
  await db.doc(`properties/${PROPERTY_ID}`).set({
    owner_id: ownerUid,
    name: "Audit86 smoke property",
    description: "smoke",
    subdomain: `audit86-${STAMP}`,
    created_at: new Date("2026-01-01"),
    updated_at: new Date(),
  });
  await db.doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}`).set({
    property_id: PROPERTY_ID,
    name: "smoke unit",
  });
  await db.doc(`properties/${PROPERTY_ID}/ical_feeds/${FEED_ID}`).set({
    unit_id: UNIT_ID,
    property_id: PROPERTY_ID,
    platform: "airbnb",
    ical_url: "https://x.example/x.ics",
    import_enabled: true,
    sync_interval_minutes: 15,
    status: "active",
    last_error: null,
    sync_count: 5,
    event_count: 12,
    last_synced: new Date("2026-05-29"),
    created_at: new Date(),
    updated_at: new Date(),
  });
  await db.doc(`properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`).set({
    property_id: PROPERTY_ID,
    owner_id: ownerUid,
    ical_export_enabled: true,
    widget_mode: "booking_pending",
    ical_cache_content: "BEGIN:VCALENDAR\nEND:VCALENDAR",
    ical_cache_generated_at: new Date("2026-05-29"),
    ical_cache_etag: "abc123",
    ical_cache_unit_name: "smoke unit",
    updated_at: new Date(),
  });
}

async function cleanup() {
  const db = admin.firestore();
  try {
    const subs = [
      `properties/${PROPERTY_ID}/ical_feeds/${FEED_ID}`,
      `properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`,
      `properties/${PROPERTY_ID}/units/${UNIT_ID}`,
      `properties/${PROPERTY_ID}`,
    ];
    for (const p of subs) {
      await db.doc(p).delete().catch(() => {});
    }
  } catch (e) {
    console.error("cleanup error", e.message);
  }
}

function initClient(label) {
  const app = initializeApp(
    {
      apiKey: WEB_API_KEY,
      projectId: PROJECT_ID,
      authDomain: `${PROJECT_ID}.firebaseapp.com`,
    },
    `app-${label}-${Date.now()}-${Math.random()}`
  );
  return {app, auth: getAuth(app), db: getFirestore(app)};
}

async function loginExisting(email, password) {
  const ctx = initClient("existing");
  const cred = await signInWithEmailAndPassword(ctx.auth, email, password);
  return {...ctx, uid: cred.user.uid};
}

async function loginNewThrowaway(email, password) {
  const ctx = initClient("foreign");
  const cred = await createUserWithEmailAndPassword(
    ctx.auth,
    email,
    password
  );
  return {...ctx, uid: cred.user.uid};
}

async function main() {
  console.log("=== audit/86 LIVE probe on", PROJECT_ID, "===");
  console.log("STAMP:", STAMP);

  const owner = await loginExisting(OWNER_EMAIL, OWNER_PASS);
  console.log("logged in owner:", owner.uid);

  await seed(owner.uid);
  console.log("seeded property", PROPERTY_ID);

  const foreign = await loginNewThrowaway(FOREIGN_EMAIL, FOREIGN_PASS);
  console.log("created foreign uid:", foreign.uid);

  // ─── F-94-02 properties update ───
  await expectDeny("F-94-02 owner DIRECT subdomain", () =>
    updateDoc(doc(owner.db, `properties/${PROPERTY_ID}`), {
      subdomain: `squat-${STAMP}`,
    })
  );
  await expectDeny("F-94-02 owner DIRECT owner_id", () =>
    updateDoc(doc(owner.db, `properties/${PROPERTY_ID}`), {
      owner_id: foreign.uid,
    })
  );
  await expectDeny("F-94-02 owner DIRECT created_at", () =>
    updateDoc(doc(owner.db, `properties/${PROPERTY_ID}`), {
      created_at: new Date("2020-01-01"),
    })
  );
  await expectAllow("F-94-02 owner benign name update", () =>
    updateDoc(doc(owner.db, `properties/${PROPERTY_ID}`), {
      name: "Renamed",
    })
  );
  await expectDeny("F-94-02 foreign uid name update", () =>
    updateDoc(doc(foreign.db, `properties/${PROPERTY_ID}`), {
      name: "pwn",
    })
  );

  // ─── F-94-03 ical_feeds update ───
  const feedPath = `properties/${PROPERTY_ID}/ical_feeds/${FEED_ID}`;
  await expectDeny("F-94-03 owner DIRECT sync_count=99999", () =>
    updateDoc(doc(owner.db, feedPath), {sync_count: 99999})
  );
  await expectDeny("F-94-03 owner DIRECT event_count=99999", () =>
    updateDoc(doc(owner.db, feedPath), {event_count: 99999})
  );
  await expectDeny("F-94-03 owner DIRECT last_synced=2099", () =>
    updateDoc(doc(owner.db, feedPath), {
      last_synced: new Date("2099-01-01"),
    })
  );
  await expectAllow("F-94-03 owner benign ical_url update", () =>
    updateDoc(doc(owner.db, feedPath), {
      ical_url: "https://new.example/y.ics",
    })
  );
  await expectAllow("F-94-03 owner legit pause via status", () =>
    updateDoc(doc(owner.db, feedPath), {status: "paused"})
  );
  await expectDeny("F-94-03 foreign uid feed write", () =>
    updateDoc(doc(foreign.db, feedPath), {
      ical_url: "https://pwn.example/y.ics",
    })
  );

  // ─── F-94-04 widget_settings update ───
  const wsPath = `properties/${PROPERTY_ID}/widget_settings/${UNIT_ID}`;
  await expectDeny("F-94-04 owner DIRECT ical_cache_content=PWN", () =>
    updateDoc(doc(owner.db, wsPath), {
      ical_cache_content: "BEGIN:VCALENDAR\nSUMMARY:PWN\nEND:VCALENDAR",
    })
  );
  await expectDeny("F-94-04 owner DIRECT ical_cache_generated_at=2099", () =>
    updateDoc(doc(owner.db, wsPath), {
      ical_cache_generated_at: new Date("2099-01-01"),
    })
  );
  await expectAllow("F-94-04 owner benign widget_mode toggle", () =>
    updateDoc(doc(owner.db, wsPath), {widget_mode: "booking_instant"})
  );
  await expectAllow("F-94-04 owner ical_export_enabled toggle", () =>
    updateDoc(doc(owner.db, wsPath), {ical_export_enabled: false})
  );
  await expectDeny("F-94-04 foreign uid widget_settings write", () =>
    updateDoc(doc(foreign.db, wsPath), {widget_mode: "booking_pending"})
  );

  await signOut(owner.auth);
  await signOut(foreign.auth);
  await cleanup();

  console.log("\n=== RESULTS ===");
  let pass = 0;
  let fail = 0;
  for (const r of results) {
    const mark = r.pass ? "✅" : "❌";
    console.log(
      `${mark}  expected=${r.expected.padEnd(5)}  got=${r.got.padEnd(5)}  ${r.label}${r.errCode ? `  [${r.errCode}]` : ""}`
    );
    if (r.pass) pass++; else fail++;
  }
  console.log(`\nTotals: ${pass} pass / ${fail} fail / ${results.length} total`);

  // Auth user cleanup
  try {
    // OWNER is the persistent test account — never delete.
    // FOREIGN throwaway gets removed via Admin SDK lookupByEmail then delete.
    try {
      const f = await admin.auth().getUserByEmail(FOREIGN_EMAIL);
      await admin.auth().deleteUser(f.uid).catch(() => {});
    } catch (_) {}
  } catch (_) {}

  process.exit(fail === 0 ? 0 : 1);
}

main().catch(async (e) => {
  console.error("FATAL", e);
  await cleanup();
  try {
    // OWNER is the persistent test account — never delete.
    // FOREIGN throwaway gets removed via Admin SDK lookupByEmail then delete.
    try {
      const f = await admin.auth().getUserByEmail(FOREIGN_EMAIL);
      await admin.auth().deleteUser(f.uid).catch(() => {});
    } catch (_) {}
  } catch (_) {}
  process.exit(2);
});
