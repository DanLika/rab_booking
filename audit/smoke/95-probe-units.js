// audit/95 — list units + widget_settings for the dev test owner property
// Run: cd functions && GOOGLE_CLOUD_PROJECT=bookbed-dev node ../audit/smoke/95-probe-units.js
const admin = require("firebase-admin");
admin.initializeApp({projectId: "bookbed-dev"});
const db = admin.firestore();

(async () => {
  const propId = "SEED_test_owner_property_01";
  const units = await db.collection("properties").doc(propId).collection("units").limit(5).get();
  console.log(`Units under ${propId}: ${units.size}`);
  units.docs.forEach(u => {
    const d = u.data();
    console.log(`  ${u.id} name=${d.name} active=${d.active}`);
  });
  const widgetSettings = await db.collection("properties").doc(propId).collection("widget_settings").limit(5).get();
  console.log(`Widget settings: ${widgetSettings.size}`);
  widgetSettings.docs.forEach(w => {
    console.log(`  ${w.id} ical_cache_content present=${!!w.data().ical_cache_content} cached_at=${w.data().ical_cache_generated_at?.toDate().toISOString()}`);
  });
  process.exit(0);
})();
