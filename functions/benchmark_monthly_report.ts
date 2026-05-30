import * as admin from 'firebase-admin';

// Initialize Firebase Admin pointing to emulator
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
admin.initializeApp({
  projectId: "demo-benchmark"
});

const db = admin.firestore();

async function runTest() {
  const startTs = admin.firestore.Timestamp.fromDate(new Date('2023-01-01'));
  const endTs = admin.firestore.Timestamp.fromDate(new Date('2023-01-31'));

  // Seed some dummy data
  console.log("Seeding data...");
  const batch1 = db.batch();
  for (let i = 0; i < 50; i++) {
    batch1.set(db.collection('users').doc(`owner_${i}`), { accountStatus: 'active' });
    for (let j = 0; j < 5; j++) {
      batch1.set(db.collection('properties').doc(`prop_${i}`).collection('units').doc('u1').collection('bookings').doc(`b_${i}_${j}`), {
        owner_id: `owner_${i}`,
        check_in: admin.firestore.Timestamp.fromDate(new Date('2023-01-15')),
        status: 'confirmed',
        total_price: 100
      });
    }
  }
  await batch1.commit();

  // Baseline (N+1)
  console.log("Running N+1 Query...");
  const t0 = performance.now();
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
  const t1 = performance.now();
  console.log(`N+1 Query took ${t1 - t0}ms. Found ${totalBookingsN1} bookings`);

  // Optimized (1 Query)
  console.log("Running 1 Query...");
  const t2 = performance.now();
  // Fetch active owners just like before
  const ownersSnapshot2 = await db.collection("users").where("accountStatus", "in", ["trial", "active", "premium"]).limit(1000).get();

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
  for (const ownerDoc of ownersSnapshot2.docs) {
    const ownerId = ownerDoc.id;
    const ownerBookings = bookingsByOwner[ownerId] || [];
    totalBookings1Q += ownerBookings.length;
  }
  const t3 = performance.now();
  console.log(`1 Query took ${t3 - t2}ms. Found ${totalBookings1Q} bookings`);

  process.exit(0);
}

runTest().catch(e => {
  console.error(e);
  process.exit(1);
});
