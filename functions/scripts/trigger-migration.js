#!/usr/bin/env node

const admin = require('firebase-admin');
const https = require('https');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'rab-booking-248fc',
});

async function triggerMigration() {
  try {
    console.log('🚀 Pokretanje migracije...\n');

    // Get access token using Firebase Admin
    const accessToken = await admin.app().options.credential.getAccessToken();

    const url = 'https://us-central1-rab-booking-248fc.cloudfunctions.net/migrateToSubcollections';

    const postData = JSON.stringify({ data: {} });

    const options = {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken.access_token}`,
        'Content-Type': 'application/json',
        'Content-Length': postData.length,
      },
    };

    console.log('⏳ Pozivam migracionu funkciju...\n');

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
      req.write(postData);
      req.end();
    });

    console.log(`📡 Status: ${response.statusCode}\n`);

    if (response.statusCode === 200) {
      const result = JSON.parse(response.body);

      console.log('✅ Migracija uspješno završena!\n');
      console.log('📊 Rezultati:');
      console.log('═══════════════════════════════════════════\n');

      const data = result.result || result;

      console.log('📦 Bookings:');
      console.log(`   Stara struktura:   ${data.bookings.old} dokumenata`);
      console.log(`   Migrirano:         ${data.bookings.migrated} dokumenata`);
      console.log(`   Nova struktura:    ${data.bookings.new} dokumenata`);
      console.log(`   Greške:            ${data.bookings.errors}`);
      console.log(`   Validno:           ${data.bookings.valid ? '✅' : '❌'}\n`);

      console.log('📅 iCal Events:');
      console.log(`   Stara struktura:   ${data.icalEvents.old} dokumenata`);
      console.log(`   Migrirano:         ${data.icalEvents.migrated} dokumenata`);
      console.log(`   Nova struktura:    ${data.icalEvents.new} dokumenata`);
      console.log(`   Greške:            ${data.icalEvents.errors}`);
      console.log(`   Validno:           ${data.icalEvents.valid ? '✅' : '❌'}\n`);

      console.log('═══════════════════════════════════════════');
      console.log(`\n💬 ${data.message}\n`);

      if (data.bookings.valid && data.icalEvents.valid) {
        console.log('🎉 Sljedeći koraci:');
        console.log('   1. Validacija podataka u Firebase Console');
        console.log('   2. Update Dart repositories');
        console.log('   3. Update Cloud Functions');
        console.log('   4. Testiranje funkcionalnosti');
        console.log('   5. Cleanup stare strukture\n');
      }
    } else {
      console.error('❌ Migracija neuspješna!');
      console.error(`Status: ${response.statusCode}`);
      console.error(`Body: ${response.body}\n`);
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Greška prilikom pokretanja migracije:', error.message);
    process.exit(1);
  }
}

triggerMigration();
