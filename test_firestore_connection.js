const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

console.log('Firebase Admin SDK connected!');
console.log('Project ID:', serviceAccount.project_id);
console.log('');

(async () => {
  try {
    console.log('Fetching properties from Firestore...\n');

    const snapshot = await db.collection('properties').limit(5).get();
    console.log(`Found ${snapshot.size} properties:\n`);

    for (const doc of snapshot.docs) {
      const data = doc.data();
      console.log(`Property ID: ${doc.id}`);
      console.log(`  Name: ${data.name || 'N/A'}`);
      console.log(`  Location: ${data.location || 'N/A'}`);
      console.log(`  Owner ID: ${data.owner_id || 'N/A'}`);

      // Get units subcollection
      const unitsSnapshot = await db
        .collection('properties')
        .doc(doc.id)
        .collection('units')
        .limit(3)
        .get();

      console.log(`  Units: ${unitsSnapshot.size}`);

      unitsSnapshot.forEach(unitDoc => {
        const unitData = unitDoc.data();
        console.log(`    - Unit ID: ${unitDoc.id}`);
        console.log(`      Name: ${unitData.name || 'N/A'}`);
        console.log(`      TEST LINK: http://localhost:8080/?property=${doc.id}&unit=${unitDoc.id}`);
      });

      console.log('');
    }

    process.exit(0);
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
})();
