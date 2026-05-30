import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp({
  projectId: "demo-project"
});

const db = admin.firestore();

async function runTest() {
  const startTs = admin.firestore.Timestamp.fromDate(new Date('2023-01-01'));
  const endTs = admin.firestore.Timestamp.fromDate(new Date('2023-01-31'));

  // Seed some dummy data
  console.log("Seeding data...");
  const batch = db.batch();
  for (let i = 0; i < 50; i++) {
    batch.set(db.collection('users').doc(`owner_${i}`), { accountStatus: 'active' });
    for (let j = 0; j < 5; j++) {
      batch.set(db.collection('properties').doc(`prop_${i}`).collection('units').doc('u1').collection('bookings').doc(`b_${i}_${j}`), {
        owner_id: `owner_${i}`,
        check_in: admin.firestore.Timestamp.fromDate(new Date('2023-01-15')),
        status: 'confirmed',
        total_price: 100
      });
    }
  }
  await batch.commit();

  // Baseline (N+1)
  console.time('N+1 Query');
  const ownersSnapshot = await db.collection("users").where("accountStatus", "in", ["trial", "active", "premium"]).limit(1000).get();
  let totalBookingsN1 = 0;
  for (const ownerDoc of ownersSnapshot.docs) {
    const ownerId = ownerDoc.id;
    const bookingsSnapshot = await db
      .collectionGroup("bookings")
      .where("owner_id", "==", ownerId)
      .where("check_in", ">=", startTs)
      .where("check_in", "<=", endTs)
      .get();
    totalBookingsN1 += bookingsSnapshot.size;
  }
  console.timeEnd('N+1 Query');
  console.log(`Found ${totalBookingsN1} bookings (N+1)`);

  // Optimized (1 Query)
  console.time('1 Query');
  const allBookings = await db
    .collectionGroup("bookings")
    .where("check_in", ">=", startTs)
    .where("check_in", "<=", endTs)
    .get();

  const bookingsByOwner: Record<string, any[]> = {};
  allBookings.forEach(doc => {
    const data = doc.data();
    if (data.owner_id) {
      if (!bookingsByOwner[data.owner_id]) bookingsByOwner[data.owner_id] = [];
      bookingsByOwner[data.owner_id].push(data);
    }
  });

  let totalBookings1Q = 0;
  for (const ownerDoc of ownersSnapshot.docs) {
    const ownerId = ownerDoc.id;
    const ownerBookings = bookingsByOwner[ownerId] || [];
    totalBookings1Q += ownerBookings.length;
  }
  console.timeEnd('1 Query');
  console.log(`Found ${totalBookings1Q} bookings (1 Query)`);
}

runTest().catch(console.error);
