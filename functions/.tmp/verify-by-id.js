const admin = require('firebase-admin');
const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, cur, i, arr) => {
    if (cur.startsWith('--')) {
      const k = cur.slice(2);
      const v = arr[i + 1] && !arr[i + 1].startsWith('--') ? arr[i + 1] : true;
      acc.push([k, v]);
    }
    return acc;
  }, [])
);
admin.initializeApp({projectId: 'bookbed-dev'});
const db = admin.firestore();
const PROPERTY = args.property;
const UNIT = args.unit;
const BOOKING = args.booking;
(async () => {
  // Try BOTH paths (per memory booking-lookup-strategy2-path)
  const paths = [
    `properties/${PROPERTY}/units/${UNIT}/bookings/${BOOKING}`,
    `properties/${PROPERTY}/bookings/${BOOKING}`,
  ];
  for (const p of paths) {
    const ref = db.doc(p);
    const snap = await ref.get();
    console.log(`\n=== ${p} ===`);
    console.log(`exists: ${snap.exists}`);
    if (snap.exists) {
      const d = snap.data();
      console.log(`booking_reference: ${d.booking_reference}`);
      console.log(`status: ${d.status}`);
      console.log(`owner_id: ${d.owner_id}`);
      console.log(`property_id: ${d.property_id}`);
      console.log(`unit_id: ${d.unit_id}`);
      console.log(`check_in: ${d.check_in}  check_out: ${d.check_out}`);
      console.log(`guest_name: ${d.guest_name}  guest_email: ${d.guest_email}`);
      console.log(`total_price: ${d.total_price}`);
      console.log(`payment_method: ${d.payment_method}  payment_option: ${d.payment_option}`);
      console.log(`source: ${d.source}`);
      console.log(`created_at: ${d.created_at?.toDate?.()?.toISOString()}`);
      console.log(`emails_sent: ${JSON.stringify(d.emails_sent ?? null)}`);
      console.log(`notifications_sent: ${JSON.stringify(d.notifications_sent ?? null)}`);
    }
  }
})().catch(e => { console.error('ERR:', e.message); process.exit(1); });
