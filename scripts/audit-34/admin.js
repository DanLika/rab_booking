#!/usr/bin/env node
// audit/34 admin helper — reads/mutates bookbed-dev fixtures via ADC.
//
// Prereqs:
//   1. `cd functions && npm install` once at repo root (provides firebase-admin under functions/node_modules)
//   2. ADC: `gcloud auth application-default login`
//   3. Project override per session: `GOOGLE_CLOUD_PROJECT=bookbed-dev node scripts/audit-34/admin.js <cmd>`
//      (or temp swap `gcloud config set project bookbed-dev` — see memory/gcloud-quota-project-bookbed.md)
//
// Subcommands:
//   read-unit                                -> dump unit + widget_settings keys (esp. pricing + widget_mode)
//   flip-widget-mode <new-mode>              -> set widget_mode, return old value
//   list-bookings                            -> list all bookings under subcoll path
//   read-booking <bookingId>                 -> dump booking doc + emails_sent keys
//   approve-booking <bookingId>              -> mirror repository.approveBooking() (status/approved_at/updated_at)
//   reject-booking <bookingId> <reason>      -> mirror repository.rejectBooking()
//   delete-booking <bookingId>               -> delete booking doc by ID (subcoll path)
//   availability <iso-start> <iso-end>       -> POST anon callable getUnitAvailability
//   ical                                     -> GET https iCal feed (path-style {prop}/{unit}/{token})
//   flush-ical-cache                         -> delete the 4 ical_cache_* fields on widget_settings doc
const path = require('path');
const admin = require(path.resolve(__dirname, '../../functions/node_modules/firebase-admin'));

const PROJECT = 'bookbed-dev';
const PROPERTY = 'SEED_test_owner_property_01';
const UNIT = 'SEED_test_owner_unit_01';

admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

const propRef = () => db.collection('properties').doc(PROPERTY);
const unitRef = () => propRef().collection('units').doc(UNIT);
const wsRef = () => propRef().collection('widget_settings').doc(UNIT);
const bookingsCol = () => unitRef().collection('bookings');

async function cmdReadUnit() {
  const unit = await unitRef().get();
  const ws = await wsRef().get();
  console.log(JSON.stringify({
    exists: { unit: unit.exists, widget_settings: ws.exists },
    unitKeys: unit.exists ? Object.keys(unit.data()) : null,
    pricing: unit.exists ? {
      base_price: unit.data().base_price,
      weekend_price: unit.data().weekend_price,
      currency: unit.data().currency,
      min_nights: unit.data().min_nights,
    } : null,
    widget_settings: ws.exists ? {
      widget_mode: ws.data().widget_mode,
      ical_export_token: ws.data().ical_export_token ? '[present]' : '[absent]',
      ical_export_enabled: ws.data().ical_export_enabled,
      min_days_advance: ws.data().min_days_advance,
      max_days_advance: ws.data().max_days_advance,
      min_nights: ws.data().min_nights,
      stripe_config: ws.data().stripe_config,
      bank_transfer_config: ws.data().bank_transfer_config,
      allow_pay_on_arrival: ws.data().allow_pay_on_arrival,
      cancellation_deadline_hours: ws.data().cancellation_deadline_hours,
    } : null,
  }, null, 2));
}

async function cmdFlipWidgetMode(newMode) {
  const ws = await wsRef().get();
  if (!ws.exists) throw new Error('widget_settings doc missing');
  const old = ws.data().widget_mode;
  await wsRef().update({ widget_mode: newMode });
  console.log(JSON.stringify({ ok: true, oldMode: old, newMode }, null, 2));
}

async function cmdListBookings() {
  const snap = await bookingsCol().get();
  const out = snap.docs.map(d => {
    const x = d.data();
    return {
      id: d.id,
      ref: x.booking_reference,
      status: x.status,
      check_in: x.check_in && x.check_in.toDate ? x.check_in.toDate().toISOString() : x.check_in,
      check_out: x.check_out && x.check_out.toDate ? x.check_out.toDate().toISOString() : x.check_out,
      guest_email: x.guest_email,
      payment_method: x.payment_method,
      total_price: x.total_price,
      created_at: x.created_at && x.created_at.toDate ? x.created_at.toDate().toISOString() : null,
      emails_sent_keys: x.emails_sent ? Object.keys(x.emails_sent) : [],
      rejection_reason: x.rejection_reason,
      approved_at: x.approved_at && x.approved_at.toDate ? x.approved_at.toDate().toISOString() : null,
      rejected_at: x.rejected_at && x.rejected_at.toDate ? x.rejected_at.toDate().toISOString() : null,
    };
  });
  console.log(JSON.stringify(out, null, 2));
}

async function cmdReadBooking(bookingId) {
  const doc = await bookingsCol().doc(bookingId).get();
  if (!doc.exists) { console.log(JSON.stringify({ exists: false })); return; }
  const d = doc.data();
  const flatten = (v) => v && v.toDate ? v.toDate().toISOString() : v;
  const emailsOut = {};
  if (d.emails_sent) {
    for (const k of Object.keys(d.emails_sent)) {
      emailsOut[k] = {
        sent_at: flatten(d.emails_sent[k].sent_at),
        email: d.emails_sent[k].email,
        booking_id: d.emails_sent[k].booking_id,
        provider_id: d.emails_sent[k].provider_id || null,
      };
    }
  }
  console.log(JSON.stringify({
    exists: true,
    id: doc.id,
    path: doc.ref.path,
    booking_reference: d.booking_reference,
    status: d.status,
    check_in: flatten(d.check_in),
    check_out: flatten(d.check_out),
    guest_email: d.guest_email,
    guest_name: d.guest_name,
    payment_method: d.payment_method,
    total_price: d.total_price,
    nights: d.nights,
    created_at: flatten(d.created_at),
    updated_at: flatten(d.updated_at),
    approved_at: flatten(d.approved_at),
    rejected_at: flatten(d.rejected_at),
    rejection_reason: d.rejection_reason,
    emails_sent: emailsOut,
    access_token: d.access_token ? '[present, redacted]' : null,
    token_expires_at: flatten(d.token_expires_at),
  }, null, 2));
}

async function cmdDeleteBooking(bookingId) {
  await bookingsCol().doc(bookingId).delete();
  console.log(JSON.stringify({ ok: true, deleted: bookingId }));
}

async function cmdApproveBooking(bookingId) {
  await bookingsCol().doc(bookingId).update({
    status: 'confirmed',
    approved_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(JSON.stringify({ ok: true, approved: bookingId }));
}

async function cmdRejectBooking(bookingId, reason) {
  await bookingsCol().doc(bookingId).update({
    status: 'cancelled',
    rejection_reason: reason,
    rejected_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(JSON.stringify({ ok: true, rejected: bookingId, reason }));
}

async function cmdAvailability(start, end) {
  const fetch = global.fetch || (await import('node-fetch')).default;
  const url = 'https://europe-west1-bookbed-dev.cloudfunctions.net/getUnitAvailability';
  const body = { data: { propertyId: PROPERTY, unitId: UNIT, startDate: start, endDate: end } };
  const r = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const j = await r.json();
  console.log(JSON.stringify({ status: r.status, body: j }, null, 2));
}

async function cmdIcal() {
  const ws = await wsRef().get();
  const token = ws.data().ical_export_token;
  const fetch = global.fetch || (await import('node-fetch')).default;
  const url = `https://us-central1-bookbed-dev.cloudfunctions.net/getUnitIcalFeed/${PROPERTY}/${UNIT}/${encodeURIComponent(token)}`;
  const r = await fetch(url);
  const t = await r.text();
  // Count VEVENTs and dump SUMMARY lines
  const vevents = (t.match(/BEGIN:VEVENT/g) || []).length;
  const summaries = (t.match(/SUMMARY:.*/g) || []).map(s => s.trim());
  console.log(JSON.stringify({ status: r.status, vevents, summaries, contentLength: t.length }, null, 2));
}

async function cmdFlushIcalCache() {
  await wsRef().update({
    ical_cache_content: admin.firestore.FieldValue.delete(),
    ical_cache_generated_at: admin.firestore.FieldValue.delete(),
    ical_cache_etag: admin.firestore.FieldValue.delete(),
    ical_cache_unit_name: admin.firestore.FieldValue.delete(),
  });
  console.log(JSON.stringify({ ok: true, flushed: true }));
}

const [cmd, ...rest] = process.argv.slice(2);
const dispatch = {
  'read-unit': cmdReadUnit,
  'flip-widget-mode': () => cmdFlipWidgetMode(rest[0]),
  'list-bookings': cmdListBookings,
  'read-booking': () => cmdReadBooking(rest[0]),
  'delete-booking': () => cmdDeleteBooking(rest[0]),
  'approve-booking': () => cmdApproveBooking(rest[0]),
  'reject-booking': () => cmdRejectBooking(rest[0], rest[1] || 'test_smoke_reject'),
  'availability': () => cmdAvailability(rest[0], rest[1]),
  'ical': cmdIcal,
  'flush-ical-cache': cmdFlushIcalCache,
};
const fn = dispatch[cmd];
if (!fn) { console.error('unknown cmd:', cmd, 'known:', Object.keys(dispatch)); process.exit(2); }
fn().then(() => process.exit(0)).catch(e => { console.error('ERR', e.message, e.stack); process.exit(1); });
