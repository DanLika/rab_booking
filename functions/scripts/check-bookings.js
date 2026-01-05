#!/usr/bin/env node

/**
 * Script to check current bookings in Firestore
 *
 * Shows:
 * - Count of bookings in old structure (/bookings)
 * - Count of bookings in new structure (/properties/{pId}/units/{uId}/bookings)
 * - Sample booking data
 *
 * Usage: node functions/scripts/check-bookings.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'rab-booking-248fc',
});

const db = admin.firestore();

async function checkBookings() {
  try {
    console.log('🔍 Checking Firestore bookings...\n');

    // ============================================
    // 1. CHECK OLD STRUCTURE
    // ============================================
    console.log('📊 OLD STRUCTURE: /bookings');
    console.log('─────────────────────────────────────────');

    const oldBookingsSnapshot = await db.collection('bookings').get();
    const oldCount = oldBookingsSnapshot.size;

    console.log(`Total bookings: ${oldCount}\n`);

    if (oldCount > 0) {
      console.log('Sample bookings:');
      oldBookingsSnapshot.docs.slice(0, 3).forEach((doc, index) => {
        const data = doc.data();
        console.log(`\n${index + 1}. Booking ID: ${doc.id}`);
        console.log(`   Property: ${data.property_id || 'MISSING'}`);
        console.log(`   Unit: ${data.unit_id || 'MISSING'}`);
        console.log(`   Status: ${data.status}`);
        console.log(`   Check-in: ${data.check_in?.toDate?.() || 'N/A'}`);
        console.log(`   Check-out: ${data.check_out?.toDate?.() || 'N/A'}`);
      });

      if (oldCount > 3) {
        console.log(`\n... and ${oldCount - 3} more bookings`);
      }
    }

    // ============================================
    // 2. CHECK NEW STRUCTURE
    // ============================================
    console.log('\n\n📊 NEW STRUCTURE: /properties/{pId}/units/{uId}/bookings');
    console.log('─────────────────────────────────────────');

    const newBookingsSnapshot = await db.collectionGroup('bookings').get();
    const newCount = newBookingsSnapshot.size;

    console.log(`Total bookings: ${newCount}\n`);

    if (newCount > 0) {
      console.log('Sample bookings:');
      newBookingsSnapshot.docs.slice(0, 3).forEach((doc, index) => {
        const data = doc.data();
        const pathParts = doc.ref.path.split('/');
        const propertyId = pathParts[1];
        const unitId = pathParts[3];

        console.log(`\n${index + 1}. Booking ID: ${doc.id}`);
        console.log(`   Path: properties/${propertyId}/units/${unitId}/bookings/${doc.id}`);
        console.log(`   Property: ${data.property_id || propertyId}`);
        console.log(`   Unit: ${data.unit_id || unitId}`);
        console.log(`   Status: ${data.status}`);
        console.log(`   Check-in: ${data.check_in?.toDate?.() || 'N/A'}`);
        console.log(`   Check-out: ${data.check_out?.toDate?.() || 'N/A'}`);
      });

      if (newCount > 3) {
        console.log(`\n... and ${newCount - 3} more bookings`);
      }
    }

    // ============================================
    // 3. SUMMARY
    // ============================================
    console.log('\n\n📋 SUMMARY');
    console.log('─────────────────────────────────────────');
    console.log(`Old structure (/bookings):              ${oldCount} bookings`);
    console.log(`New structure (subcollections):         ${newCount} bookings`);
    console.log(`Migration needed:                       ${oldCount > 0 ? 'YES' : 'NO'}`);
    console.log(`Ready for cleanup (if migration done):  ${oldCount === newCount && newCount > 0 ? 'YES' : 'NO'}\n`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error checking bookings:', error);
    process.exit(1);
  }
}

// Run the check
checkBookings();
