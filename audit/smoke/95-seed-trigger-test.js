// audit/95 F-95-SMOKE: live trigger test for onBookingCreated → invalidateIcalCache
// 1. Note baseline cache state
// 2. Write throwaway pending booking
// 3. Poll cache state until flushed (max 30s)
// 4. Delete throwaway booking
// 5. Report timings
// Run: cd functions && GOOGLE_CLOUD_PROJECT=bookbed-dev node ../audit/smoke/95-seed-trigger-test.js
// Writes ONE throwaway pending bank_transfer booking, polls until onBookingCreated
// invalidates the widget iCal cache (max 30 s), then deletes the seed booking.
const admin = require("firebase-admin");
admin.initializeApp({projectId: "bookbed-dev"});
const db = admin.firestore();

const PROP_ID = "SEED_test_owner_property_01";
const UNIT_ID = "SEED_test_owner_unit_01";
const BOOK_ID = `AUDIT95_throwaway_${Date.now()}`;

(async () => {
  const widgetRef = db.collection("properties").doc(PROP_ID).collection("widget_settings").doc(UNIT_ID);
  const bookingRef = db.collection("properties").doc(PROP_ID).collection("units").doc(UNIT_ID).collection("bookings").doc(BOOK_ID);

  // Step 1: baseline
  const before = await widgetRef.get();
  const hadCacheBefore = !!before.data()?.ical_cache_content;
  const cachedAtBefore = before.data()?.ical_cache_generated_at?.toDate()?.toISOString() || "none";
  console.log(`[1] BASELINE cache=${hadCacheBefore} cached_at=${cachedAtBefore}`);

  // Step 2: seed throwaway pending bank_transfer booking
  const now = admin.firestore.Timestamp.now();
  const checkIn = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 60*24*60*60*1000));   // 60d future
  const checkOut = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 62*24*60*60*1000)); // 62d future
  const deadline = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7*24*60*60*1000));   // 7d
  const seedDoc = {
    booking_reference: `AUDIT95-${Date.now().toString(36).toUpperCase()}`,
    property_id: PROP_ID, unit_id: UNIT_ID,
    owner_id: "GILVItIVP5R8WXfnMmyMo1ykhUm2",
    guest_name: "AUDIT95 Throwaway", guest_email: "bookbed-test@bookbed.io",
    check_in: checkIn, check_out: checkOut, status: "pending",
    payment_method: "bank_transfer", payment_deadline: deadline,
    total_price: 100, nights: 2,
    created_at: now, updated_at: now, source: "audit_95_smoke",
    _smoke_marker: "AUDIT_95_DELETE_ME",
  };
  await bookingRef.set(seedDoc);
  const tSeed = Date.now();
  console.log(`[2] SEED written: ${bookingRef.path}`);

  // Step 3: poll cache (every 1s, max 30s)
  let flushed = false; let pollAttempts = 0;
  for (let i = 0; i < 30; i++) {
    await new Promise(r => setTimeout(r, 1000));
    const cur = await widgetRef.get();
    const hasCache = !!cur.data()?.ical_cache_content;
    const cachedAt = cur.data()?.ical_cache_generated_at?.toDate()?.toISOString() || "none";
    pollAttempts++;
    if (hadCacheBefore && !hasCache) {
      flushed = true;
      console.log(`[3] CACHE FLUSHED after ${pollAttempts}s (was ${cachedAtBefore} → now ${cachedAt})`);
      break;
    }
  }
  if (!flushed) {
    const finalCheck = await widgetRef.get();
    console.log(`[3] CACHE NOT FLUSHED in 30s. final cache=${!!finalCheck.data()?.ical_cache_content}`);
  }

  // Step 4: cleanup
  await bookingRef.delete();
  const tDel = Date.now();
  console.log(`[4] DELETED booking (${tDel - tSeed}ms after seed)`);

  // Step 5: verify cleanup
  const verify = await bookingRef.get();
  console.log(`[5] CLEANUP verify exists=${verify.exists}`);

  process.exit(flushed ? 0 : 1);
})();
