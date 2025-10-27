/**
 * Script to add test daily prices to Firestore
 *
 * Setup:
 * 1. Download service account key from Firebase Console:
 *    Project Settings → Service Accounts → Generate new private key
 * 2. Save as: functions/service-account-key.json
 *
 * Run with: node add_test_prices.js
 */

const admin = require('firebase-admin');

// Try to load service account, fallback to application default credentials
let credential;
try {
  const serviceAccount = require('./service-account-key.json');
  credential = admin.credential.cert(serviceAccount);
  console.log('Using service account credentials');
} catch (error) {
  credential = admin.credential.applicationDefault();
  console.log('Using application default credentials');
}

admin.initializeApp({
  credential: credential,
  projectId: 'rab-booking-248fc'
});

const db = admin.firestore();

async function addTestPrices() {
  const unitId = 'apartman-1';
  const basePrice = 50; // €50 base price per night

  console.log('Adding test daily prices for unit:', unitId);

  // Add prices for next 90 days
  const batch = db.batch();
  const startDate = new Date();
  startDate.setHours(0, 0, 0, 0);

  for (let i = 0; i < 90; i++) {
    const date = new Date(startDate);
    date.setDate(date.getDate() + i);

    // Vary price based on day of week
    const dayOfWeek = date.getDay();
    let price = basePrice;

    // Weekend prices are higher
    if (dayOfWeek === 5 || dayOfWeek === 6) { // Friday or Saturday
      price = basePrice * 1.5; // €75
    }

    const docRef = db.collection('daily_prices').doc();
    batch.set(docRef, {
      unit_id: unitId,
      date: admin.firestore.Timestamp.fromDate(date),
      price: price,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (i % 10 === 0) {
      console.log(`Added price for ${date.toISOString().split('T')[0]}: €${price}`);
    }
  }

  await batch.commit();
  console.log('✅ Successfully added 90 days of test prices!');
  console.log('📊 Weekday price: €50');
  console.log('📊 Weekend price: €75');
}

addTestPrices()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
