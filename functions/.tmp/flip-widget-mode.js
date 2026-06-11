#!/usr/bin/env node
/** One-shot: flip widget_mode for SEED_test_owner_unit_01 to booking_pending then back. */
const admin = require('firebase-admin');
const args = process.argv.slice(2);
const mode = args[0] || 'booking_pending';
const PROPERTY = 'SEED_test_owner_property_01';
const UNIT = 'SEED_test_owner_unit_01';

admin.initializeApp({projectId: 'bookbed-dev'});
const db = admin.firestore();

(async () => {
  const ref = db.collection('properties').doc(PROPERTY)
    .collection('widget_settings').doc(UNIT);
  const before = await ref.get();
  console.log('Before:', {
    exists: before.exists,
    widget_mode: before.data()?.widget_mode,
    stripe_enabled: before.data()?.stripe_config?.enabled,
    bank_enabled: before.data()?.bank_transfer_config?.enabled,
  });
  await ref.set({widget_mode: mode}, {merge: true});
  const after = await ref.get();
  console.log('After:', {widget_mode: after.data()?.widget_mode});
})().catch(e => { console.error(e.message); process.exit(1); });
