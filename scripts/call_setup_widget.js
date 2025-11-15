#!/usr/bin/env node

const https = require('https');

// Cloud Function URL - replace with your actual region
const FUNCTION_URL = 'https://us-central1-rab-booking-248fc.cloudfunctions.net/setupWidgetConfig';

const data = JSON.stringify({
  data: {
    propertyId: 'fg5nlt3aLlx4HWJeqliq',
    unitId: 'gMIOos56siO74VkCsSwY'
  }
});

const options = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

console.log('🚀 Calling setupWidgetConfig Cloud Function...\n');

const req = https.request(FUNCTION_URL, options, (res) => {
  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('\nResponse:');
    try {
      const result = JSON.parse(responseData);
      console.log(JSON.stringify(result, null, 2));

      if (result.result && result.result.success) {
        console.log('\n✅ Widget settings configured successfully!');
        console.log('\n📋 Configured features:');
        console.log('   ✓ Custom Logo: Villa Jasko logo');
        console.log('   ✓ Blur Effects: Enabled');
        console.log('   ✓ Tax/Legal Disclaimer: Enabled');
        console.log('   ✓ iCal Sync Warning: Enabled');
        console.log('   ✓ Additional Services: 3 services');
        console.log('   ✓ Floating Booking Summary: Enabled');
        console.log('\n🎯 Widget ready at: localhost:8080');
        console.log('🔄 Refresh the page to see changes');
      }
    } catch (e) {
      console.log(responseData);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error calling Cloud Function:', error);
  process.exit(1);
});

req.write(data);
req.end();
