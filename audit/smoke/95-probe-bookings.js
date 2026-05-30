// audit/95 — Firestore data probe on bookbed-dev
// Read-only: verifies suspected logic gaps in autoCancel/autoComplete + trial CFs
// Run: cd functions && GOOGLE_CLOUD_PROJECT=bookbed-dev node ../audit/smoke/95-probe-bookings.js
// Requires: firebase-admin in functions/node_modules (already in functions/package.json)
const admin = require("firebase-admin");

admin.initializeApp({projectId: "bookbed-dev"});
const db = admin.firestore();

(async () => {
  const now = admin.firestore.Timestamp.now();
  const todayMs = Date.now();
  const todayMidnight = new Date(todayMs); todayMidnight.setUTCHours(0,0,0,0);
  const todayTs = admin.firestore.Timestamp.fromDate(todayMidnight);

  // F-95-03 probe: pending bookings WITH external source AND payment_deadline < now
  // autoCancelExpiredBookings would cancel these. Verify if any exist.
  console.log("\n=== F-95-03 PROBE: pending+external+expired_deadline ===");
  try {
    const pendingExpired = await db.collectionGroup("bookings")
      .where("status", "==", "pending")
      .where("payment_deadline", "<", now)
      .limit(20).get();
    let externalCount = 0; let totalCount = pendingExpired.size;
    for (const d of pendingExpired.docs) {
      const data = d.data();
      const isExternal = data.source && ["booking_com","airbnb","ical","external"].includes(String(data.source).toLowerCase());
      const idExternal = d.id.startsWith("ical_");
      if (isExternal || idExternal) {
        externalCount++;
        console.log("  EXTERNAL pending+expired:", d.ref.path, "source=", data.source, "id=", d.id);
      }
    }
    console.log(`Result: ${externalCount} external / ${totalCount} total pending+expired bookings`);
  } catch (e) { console.log("ERROR:", e.message); }

  // F-95-04 probe: pending bookings with check_out < today (would be marked completed by autoComplete)
  console.log("\n=== F-95-04 PROBE: pending+checkout_past ===");
  try {
    const pendingPastCheckout = await db.collectionGroup("bookings")
      .where("status", "in", ["pending"])
      .where("check_out", "<", todayTs)
      .limit(20).get();
    console.log(`Result: ${pendingPastCheckout.size} pending bookings with checkout < today`);
    for (const d of pendingPastCheckout.docs.slice(0,5)) {
      const data = d.data();
      const pd = data.payment_deadline ? data.payment_deadline.toDate().toISOString() : "none";
      console.log("  pending+past:", d.ref.path, "checkout=", data.check_out?.toDate().toISOString(), "deadline=", pd);
    }
  } catch (e) { console.log("ERROR:", e.message); }

  // F-95-08 probe: trial users WITHOUT warning flags initialized
  console.log("\n=== F-95-08 PROBE: trial users without warning flags ===");
  try {
    const trialUsers = await db.collection("users")
      .where("accountStatus", "==", "trial")
      .limit(100).get();
    let missingFlag7 = 0, missingFlag3 = 0, missingFlag1 = 0;
    for (const d of trialUsers.docs) {
      const data = d.data();
      if (data.trialWarning7DaysSent === undefined) missingFlag7++;
      if (data.trialWarning3DaysSent === undefined) missingFlag3++;
      if (data.trialWarning1DaySent === undefined) missingFlag1++;
    }
    console.log(`Total trial users: ${trialUsers.size}. Missing flag7=${missingFlag7}, flag3=${missingFlag3}, flag1=${missingFlag1}`);
  } catch (e) { console.log("ERROR:", e.message); }

  // F-95-INFO: total active ical_feeds
  console.log("\n=== INFO: active ical_feeds count ===");
  try {
    const feeds = await db.collectionGroup("ical_feeds")
      .where("status", "in", ["active", "error"]).limit(100).get();
    console.log(`Total feeds: ${feeds.size}`);
    const byStatus = {};
    feeds.docs.forEach(d => {
      const s = d.data().status || "?";
      byStatus[s] = (byStatus[s] || 0) + 1;
    });
    console.log("By status:", byStatus);
  } catch (e) { console.log("ERROR:", e.message); }

  // Sanity: existing bookings on test owner property (read-only)
  console.log("\n=== INFO: bookings on test owner property (sample) ===");
  try {
    const props = await db.collection("properties")
      .where("owner_id", "==", "GILVItIVP5R8WXfnMmyMo1ykhUm2")
      .limit(5).get();
    console.log(`Test owner properties: ${props.size}`);
    for (const p of props.docs) {
      const bookings = await p.ref.collection("bookings").limit(3).get();
      console.log(`  ${p.id} bookings: ${bookings.size}`);
      bookings.docs.forEach(b => {
        const bd = b.data();
        console.log(`    ${b.id} status=${bd.status} method=${bd.payment_method} ref=${bd.booking_reference}`);
      });
    }
  } catch (e) { console.log("ERROR:", e.message); }

  process.exit(0);
})();
