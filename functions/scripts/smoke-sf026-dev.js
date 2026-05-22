#!/usr/bin/env node

/**
 * SF-026 — Post-deploy smoke check on bookbed-dev.
 *
 * Reads bookings on bookbed-dev, inspects timestamps, computes nights with
 * BOTH derivation algorithms (Dart-equivalent floor + TS canonical ceil) and
 * reports any drift. Read-only — never writes.
 *
 * Usage:
 *   GOOGLE_CLOUD_PROJECT=bookbed-dev node functions/scripts/smoke-sf026-dev.js
 */

/* eslint-disable no-console */

const admin = require("firebase-admin");

function normalizeToZagrebCivilDayUTC(date) {
  const ymd = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Zagreb",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
  const [yStr, mStr, dStr] = ymd.split("-");
  return new Date(Date.UTC(Number(yStr), Number(mStr) - 1, Number(dStr)));
}

function nightsCeil(checkIn, checkOut) {
  return Math.ceil(
    (checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24)
  );
}

function nightsFloor(checkIn, checkOut) {
  return Math.floor(
    (checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24)
  );
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  return value instanceof Date ? value : new Date(value);
}

async function main() {
  const project = process.env.GOOGLE_CLOUD_PROJECT;
  if (!project) {
    console.error("GOOGLE_CLOUD_PROJECT env var required.");
    process.exit(1);
  }

  admin.initializeApp({projectId: project});
  const db = admin.firestore();

  console.log(`SF-026 smoke check — project=${project}`);
  console.log("");

  const snap = await db.collectionGroup("bookings").get();
  console.log(`Total booking docs: ${snap.size}`);
  console.log("");

  let drift = 0;
  let aligned = 0;
  let perStatus = {};

  for (const doc of snap.docs) {
    const data = doc.data();
    const checkIn = toDate(data.check_in);
    const checkOut = toDate(data.check_out);
    if (!checkIn || !checkOut) continue;

    perStatus[data.status] = (perStatus[data.status] || 0) + 1;

    const normalizedIn = normalizeToZagrebCivilDayUTC(checkIn);
    const normalizedOut = normalizeToZagrebCivilDayUTC(checkOut);
    const inAligned = checkIn.getTime() === normalizedIn.getTime();
    const outAligned = checkOut.getTime() === normalizedOut.getTime();
    const fullyAligned = inAligned && outAligned;

    const ceil = nightsCeil(checkIn, checkOut);
    const floor = nightsFloor(checkIn, checkOut);
    const algorithmsAgree = ceil === floor;

    if (fullyAligned) aligned++; else drift++;

    console.log(`Booking: ${doc.ref.path}`);
    console.log(`  status: ${data.status}`);
    console.log(`  check_in : ${checkIn.toISOString()}  ${inAligned ? "[ALIGNED]" : "[LEGACY drift]"}`);
    console.log(`  check_out: ${checkOut.toISOString()}  ${outAligned ? "[ALIGNED]" : "[LEGACY drift]"}`);
    console.log(`  nights ceil (TS):  ${ceil}`);
    console.log(`  nights floor (Dart): ${floor}`);
    console.log(`  algorithms agree: ${algorithmsAgree ? "YES" : "NO (off-by-one risk)"}`);
    console.log("");
  }

  console.log("=== Summary ===");
  console.log(`Aligned (post-SF-026 format): ${aligned}`);
  console.log(`Legacy (pre-SF-026 drift):    ${drift}`);
  console.log("By status:");
  for (const [s, n] of Object.entries(perStatus)) {
    console.log(`  ${s}: ${n}`);
  }
}

main().catch((err) => {
  console.error("FATAL:", err);
  process.exit(1);
});
