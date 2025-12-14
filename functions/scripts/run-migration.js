#!/usr/bin/env node

/**
 * Script to trigger the migrateToSubcollections Cloud Function
 *
 * This script calls the deployed migration function to copy bookings
 * from the old structure to the new subcollection structure.
 *
 * Usage: node functions/scripts/run-migration.js
 */

const { initializeApp } = require('firebase-admin/app');
const { getFunctions } = require('firebase-admin/functions');

// Initialize Firebase Admin
const app = initializeApp({
  projectId: 'rab-booking-248fc',
});

async function runMigration() {
  try {
    console.log('🚀 Starting migration...');
    console.log('📍 Project: rab-booking-248fc');
    console.log('📍 Function: migrateToSubcollections');
    console.log('📍 Region: us-central1\n');

    // Call the migration function
    const https = require('https');
    const { GoogleAuth } = require('google-auth-library');

    const auth = new GoogleAuth({
      scopes: 'https://www.googleapis.com/auth/cloud-platform',
    });

    const client = await auth.getClient();
    const projectId = await auth.getProjectId();

    const url = `https://us-central1-${projectId}.cloudfunctions.net/migrateToSubcollections`;

    const token = await client.getAccessToken();

    const options = {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token.token}`,
        'Content-Type': 'application/json',
      },
    };

    console.log('⏳ Calling migration function...\n');

    const response = await new Promise((resolve, reject) => {
      const req = https.request(url, options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          resolve({ statusCode: res.statusCode, body: data });
        });
      });

      req.on('error', reject);
      req.write(JSON.stringify({ data: {} }));
      req.end();
    });

    console.log(`📡 Response Status: ${response.statusCode}\n`);

    if (response.statusCode === 200) {
      const result = JSON.parse(response.body);

      console.log('✅ Migration completed successfully!\n');
      console.log('📊 Results:');
      console.log('─────────────────────────────────────────');

      if (result.result) {
        const { bookings, icalEvents, message } = result.result;

        console.log('\n📦 Bookings:');
        console.log(`   Old structure:     ${bookings.old} documents`);
        console.log(`   Migrated:          ${bookings.migrated} documents`);
        console.log(`   New structure:     ${bookings.new} documents`);
        console.log(`   Errors:            ${bookings.errors}`);
        console.log(`   Valid:             ${bookings.valid ? '✅' : '❌'}`);

        console.log('\n📅 iCal Events:');
        console.log(`   Old structure:     ${icalEvents.old} documents`);
        console.log(`   Migrated:          ${icalEvents.migrated} documents`);
        console.log(`   New structure:     ${icalEvents.new} documents`);
        console.log(`   Errors:            ${icalEvents.errors}`);
        console.log(`   Valid:             ${icalEvents.valid ? '✅' : '❌'}`);

        console.log('\n─────────────────────────────────────────');
        console.log(`\n💬 ${message}\n`);

        if (bookings.valid && icalEvents.valid) {
          console.log('🎉 Next steps:');
          console.log('   1. Validate data in Firebase Console');
          console.log('   2. Update Dart repositories');
          console.log('   3. Update Cloud Functions');
          console.log('   4. Test all functionality');
          console.log('   5. Run cleanup: node functions/scripts/run-cleanup.js\n');
        } else {
          console.log('⚠️  Migration completed with errors!');
          console.log('   Check Firebase Console logs for details.\n');
        }
      } else {
        console.log(JSON.stringify(result, null, 2));
      }
    } else {
      console.error('❌ Migration failed!');
      console.error(`Status: ${response.statusCode}`);
      console.error(`Body: ${response.body}\n`);
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Error running migration:', error);
    process.exit(1);
  }
}

// Run the migration
runMigration();
