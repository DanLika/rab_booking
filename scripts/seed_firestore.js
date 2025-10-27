const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('../service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seedDatabase() {
  try {
    console.log('🌱 Seeding Firestore database...');

    // 1. Create demo user (property owner)
    const userId = 'demo-owner-123';
    await db.collection('users').doc(userId).set({
      id: userId,
      email: 'owner@jasko-rab.com',
      name: 'Jasko Rab Owner',
      role: 'owner',
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Created demo user');

    // 2. Create property (Villa Jasko)
    const propertyId = 'villa-jasko-rab';
    await db.collection('properties').doc(propertyId).set({
      id: propertyId,
      owner_id: userId,
      name: 'Villa Jasko - Rab',
      slug: 'villa-jasko-rab',
      description: 'Beautiful villa on Rab island with stunning sea views',
      location: 'Rab, Croatia',
      city: 'Rab',
      country: 'Croatia',
      address: 'Barbat 123',
      latitude: 44.7566,
      longitude: 14.7644,
      property_type: 'villa',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Created property: Villa Jasko');

    // 3. Create units (apartments)
    const units = [
      {
        id: 'apartman-1',
        name: 'Apartman 1',
        slug: 'apartman-1',
        price_per_night: 80,
        max_guests: 4,
        bedrooms: 2,
        bathrooms: 1
      },
      {
        id: 'apartman-2',
        name: 'Apartman 2',
        slug: 'apartman-2',
        price_per_night: 100,
        max_guests: 6,
        bedrooms: 3,
        bathrooms: 2
      }
    ];

    for (const unit of units) {
      await db.collection('units').doc(unit.id).set({
        ...unit,
        property_id: propertyId,
        description: `Spacious ${unit.name} with sea view`,
        is_available: true,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`✅ Created unit: ${unit.name}`);

      // Add sample daily prices (summer season higher prices)
      const summerMonths = [6, 7, 8]; // June, July, August
      const currentYear = new Date().getFullYear();

      for (let month = 1; month <= 12; month++) {
        for (let day = 1; day <= 31; day++) {
          try {
            const date = new Date(currentYear, month - 1, day);
            if (date.getMonth() + 1 !== month) continue; // Skip invalid dates (e.g., Feb 30)

            const isSummer = summerMonths.includes(month);
            const price = isSummer ? unit.price_per_night * 1.5 : unit.price_per_night;

            await db.collection('daily_prices').add({
              unit_id: unit.id,
              date: admin.firestore.Timestamp.fromDate(date),
              price: price,
              created_at: admin.firestore.FieldValue.serverTimestamp()
            });
          } catch (e) {
            // Skip invalid dates
          }
        }
      }
      console.log(`✅ Added daily prices for ${unit.name}`);

      // Add sample bookings
      const sampleBookings = [
        {
          check_in: new Date(currentYear, 5, 10), // June 10
          check_out: new Date(currentYear, 5, 17), // June 17
          status: 'confirmed'
        },
        {
          check_in: new Date(currentYear, 6, 20), // July 20
          check_out: new Date(currentYear, 6, 27), // July 27
          status: 'confirmed'
        }
      ];

      for (const booking of sampleBookings) {
        const nights = Math.ceil((booking.check_out - booking.check_in) / (1000 * 60 * 60 * 24));
        const totalPrice = unit.price_per_night * nights * 1.5; // Summer price

        await db.collection('bookings').add({
          unit_id: unit.id,
          property_id: propertyId,
          owner_id: userId,
          user_id: 'guest-demo',
          guest_name: 'Demo Guest',
          guest_email: 'guest@example.com',
          guest_phone: '+385911234567',
          check_in: admin.firestore.Timestamp.fromDate(booking.check_in),
          check_out: admin.firestore.Timestamp.fromDate(booking.check_out),
          status: booking.status,
          total_price: totalPrice,
          paid_amount: totalPrice * 0.2, // 20% advance
          advance_amount: totalPrice * 0.2,
          payment_method: 'bank_transfer',
          payment_status: 'paid',
          source: 'widget',
          guest_count: 2,
          created_at: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      console.log(`✅ Added sample bookings for ${unit.name}`);
    }

    console.log('\n🎉 Database seeded successfully!');
    console.log('\n📋 Embed URLs:');
    console.log(`   Apartman 1: https://rab-booking-248fc.web.app/?unit=apartman-1`);
    console.log(`   Apartman 2: https://rab-booking-248fc.web.app/?unit=apartman-2`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
