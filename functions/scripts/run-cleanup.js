#!/usr/bin/env node

/**
 * Script to trigger the deleteOldStructures Cloud Function
 *
 * ⚠️  WARNING: This script DELETES the old bookings and ical_events collections!
 * Only run this AFTER you have validated that the migration was successful
 * and all functionality works with the new subcollection structure.
 *
 * Usage: node functions/scripts/run-cleanup.js
 */

const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

async function confirmDeletion() {
  return new Promise((resolve) => {
    console.log('\n⚠️  WARNING: This will DELETE the old bookings and ical_events collections!');
    console.log('⚠️  This action CANNOT be undone!\n');
    console.log('Before proceeding, make sure you have:');
    console.log('  ✅ Validated migration results in Firebase Console');
    console.log('  ✅ Updated all Dart repositories');
    console.log('  ✅ Updated all Cloud Functions');
    console.log('  ✅ Tested all functionality with new structure');
    console.log('  ✅ Created a backup of your database\n');

    rl.question('Type "DELETE" to confirm deletion: ', (answer) => {
      rl.close();
      resolve(answer === 'DELETE');
    });
  });
}

async function runCleanup() {
  try {
    const confirmed = await confirmDeletion();

    if (!confirmed) {
      console.log('\n❌ Cleanup cancelled. No data was deleted.\n');
      process.exit(0);
    }

    console.log('\n🚀 Starting cleanup...');
    console.log('📍 Project: rab-booking-248fc');
    console.log('📍 Function: deleteOldStructures');
    console.log('📍 Region: us-central1\n');

    // Call the cleanup function
    const https = require('https');
    const { GoogleAuth } = require('google-auth-library');

    const auth = new GoogleAuth({
      scopes: 'https://www.googleapis.com/auth/cloud-platform',
    });

    const client = await auth.getClient();
    const projectId = await auth.getProjectId();

    const url = `https://us-central1-${projectId}.cloudfunctions.net/deleteOldStructures`;

    const token = await client.getAccessToken();

    const options = {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token.token}`,
        'Content-Type': 'application/json',
      },
    };

    console.log('⏳ Calling cleanup function...\n');

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

      console.log('✅ Cleanup completed successfully!\n');
      console.log('📊 Results:');
      console.log('─────────────────────────────────────────');

      if (result.result) {
        const { bookingsDeleted, icalEventsDeleted, message } = result.result;

        console.log(`\n🗑️  Deleted ${bookingsDeleted} bookings`);
        console.log(`🗑️  Deleted ${icalEventsDeleted} ical_events`);

        console.log('\n─────────────────────────────────────────');
        console.log(`\n💬 ${message}\n`);

        console.log('🎉 Migration complete!');
        console.log('   Your database now uses the new subcollection structure.\n');
      } else {
        console.log(JSON.stringify(result, null, 2));
      }
    } else {
      console.error('❌ Cleanup failed!');
      console.error(`Status: ${response.statusCode}`);
      console.error(`Body: ${response.body}\n`);
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Error running cleanup:', error);
    process.exit(1);
  }
}

// Run the cleanup
runCleanup();
