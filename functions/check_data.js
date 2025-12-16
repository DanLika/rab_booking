const admin = require('firebase-admin');

// Initialize with service account
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkData() {
  console.log('=== Checking Firestore Data Structure ===\n');
  
  // Check top-level collections
  const collections = await db.listCollections();
  console.log('Top-level collections:');
  collections.forEach(col => console.log('  -', col.id));
  
  // Check for old flat bookings collection
  const oldBookings = await db.collection('bookings').limit(1).get();
  console.log('\n📋 Old flat /bookings/ collection:');
  console.log('  Count:', oldBookings.size, oldBookings.empty ? '(EMPTY - MIGRATED ✅)' : '(HAS DATA - NOT CLEANED UP ❌)');
  
  // Check for old flat ical_events collection  
  const oldIcalEvents = await db.collection('ical_events').limit(1).get();
  console.log('\n📅 Old flat /ical_events/ collection:');
  console.log('  Count:', oldIcalEvents.size, oldIcalEvents.empty ? '(EMPTY - MIGRATED ✅)' : '(HAS DATA - NOT CLEANED UP ❌)');
  
  // Check bookings in subcollections using collection group
  const newBookings = await db.collectionGroup('bookings').limit(10).get();
  console.log('\n📦 New subcollection bookings (collection group):');
  console.log('  Found:', newBookings.size, 'bookings');
  if (!newBookings.empty) {
    newBookings.docs.forEach(doc => {
      console.log('    -', doc.ref.path);
    });
  }
  
  // Check ical_events in subcollections
  const newIcalEvents = await db.collectionGroup('ical_events').limit(5).get();
  console.log('\n📆 New subcollection ical_events (collection group):');
  console.log('  Found:', newIcalEvents.size, 'events');
  if (!newIcalEvents.empty) {
    newIcalEvents.docs.forEach(doc => {
      console.log('    -', doc.ref.path);
    });
  }
  
  // Check daily_prices in subcollections
  const dailyPrices = await db.collectionGroup('daily_prices').limit(5).get();
  console.log('\n💰 Daily prices in subcollections:');
  console.log('  Found:', dailyPrices.size, 'price entries');
  
  process.exit(0);
}

checkData().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
