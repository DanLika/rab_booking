// Script to list Firestore data for testing widget
const admin = require('firebase-admin');

// Initialize with project ID (will use application default credentials)
admin.initializeApp({
  projectId: 'rab-booking-248fc'
});

const db = admin.firestore();

async function listData() {
  console.log('\n=== FIREBASE FIRESTORE DATA ===\n');

  // List users
  const usersSnapshot = await db.collection('users').limit(5).get();
  console.log(`📧 USERS (${usersSnapshot.size} found):`);
  usersSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`  - ${doc.id}: ${data.email || 'no email'}`);
  });

  // List properties
  const propertiesSnapshot = await db.collection('properties').limit(10).get();
  console.log(`\n🏨 PROPERTIES (${propertiesSnapshot.size} found):`);

  for (const propertyDoc of propertiesSnapshot.docs) {
    const property = propertyDoc.data();
    console.log(`\n  Property: ${property.name} (ID: ${propertyDoc.id})`);
    console.log(`    Owner: ${property.owner_id}`);
    console.log(`    Location: ${property.location || 'N/A'}`);

    // List units for this property
    const unitsSnapshot = await db.collection('properties').doc(propertyDoc.id).collection('units').limit(5).get();
    console.log(`    Units (${unitsSnapshot.size} found):`);

    unitsSnapshot.forEach(unitDoc => {
      const unit = unitDoc.data();
      console.log(`      - ${unit.name} (ID: ${unitDoc.id})`);
      console.log(`        Base Price: €${unit.base_price || 'N/A'}`);
      console.log(`        Max Guests: ${unit.max_guests || 'N/A'}`);
      console.log(`        🔗 Widget URL: http://localhost:8080/?unit=${unitDoc.id}&lang=hr`);
    });

    // Check widget_settings
    const widgetSettingsSnapshot = await db.collection('properties').doc(propertyDoc.id).collection('widget_settings').limit(5).get();
    if (widgetSettingsSnapshot.size > 0) {
      console.log(`    Widget Settings (${widgetSettingsSnapshot.size} found):`);
      widgetSettingsSnapshot.forEach(wsDoc => {
        const ws = wsDoc.data();
        console.log(`      - Unit ${wsDoc.id}: Mode = ${ws.widget_mode || 'N/A'}`);
      });
    }
  }

  // List bookings
  const bookingsSnapshot = await db.collection('bookings').limit(5).get();
  console.log(`\n📅 BOOKINGS (${bookingsSnapshot.size} found):`);
  bookingsSnapshot.forEach(doc => {
    const booking = doc.data();
    console.log(`  - ${booking.guest_name || 'N/A'}: ${booking.status || 'N/A'}`);
    console.log(`    Check-in: ${booking.check_in ? booking.check_in.toDate().toLocaleDateString() : 'N/A'}`);
  });

  // List iCal feeds
  const icalSnapshot = await db.collection('ical_feeds').limit(5).get();
  console.log(`\n🔄 iCAL FEEDS (${icalSnapshot.size} found):`);
  icalSnapshot.forEach(doc => {
    const feed = doc.data();
    console.log(`  - ${feed.platform || 'N/A'}: ${feed.status || 'N/A'}`);
  });

  console.log('\n=================================\n');
  process.exit(0);
}

listData().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
