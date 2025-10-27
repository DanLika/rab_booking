const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'rab-booking-248fc'
});

const db = admin.firestore();

async function createTestData() {
  try {
    // Create property
    const propertyRef = await db.collection('properties').add({
      name: 'Test Apartman',
      owner_id: 'test_owner',
      address: 'Test adresa',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Property created:', propertyRef.id);
    
    // Create unit
    await db.collection('units').doc('apartman-1').set({
      property_id: propertyRef.id,
      name: 'Apartman 1',
      max_guests: 4,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Unit created: apartman-1');
    
    // Create some test prices
    const today = new Date();
    for (let i = 0; i < 30; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      
      await db.collection('daily_prices').add({
        unit_id: 'apartman-1',
        date: admin.firestore.Timestamp.fromDate(date),
        price: 100,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    console.log('Created 30 daily prices');
    console.log('Test data created successfully!');
    
  } catch (error) {
    console.error('Error:', error);
  }
}

createTestData();
