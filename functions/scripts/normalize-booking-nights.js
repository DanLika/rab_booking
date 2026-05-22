#!/usr/bin/env node

/**
 * SF-026 — Normalize existing booking Timestamps to UTC midnight of
 * Zagreb civil day, so future nights derivations agree across surfaces.
 *
 * What it does
 * ------------
 * For every booking in `collectionGroup('bookings')` with
 *   status in {confirmed, pending_payment, awaiting_owner_decision}
 * recomputes `check_in` / `check_out` to UTC midnight of the Zagreb civil day
 * that each currently represents, and writes back only if the value changes.
 *
 * Safety
 * ------
 *   --dry-run (default): logs proposed updates, writes nothing.
 *   --force            : performs the writes.
 *   --project=<id>     : Firebase project id (defaults to GOOGLE_CLOUD_PROJECT).
 *
 * Auth
 * ----
 * Uses Application Default Credentials. Operator must `gcloud auth
 * application-default login` (and have Firestore write perms on the target
 * project) before passing --force.
 *
 * The companion fix in `functions/src/utils/dateValidation.ts` STEP 6 means
 * new bookings created after deploy are already normalized at write — this
 * script only touches pre-existing rows.
 */

/* eslint-disable no-console */

const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = {dryRun: true, project: process.env.GOOGLE_CLOUD_PROJECT};
  for (const raw of argv.slice(2)) {
    if (raw === "--force") {
      args.dryRun = false;
    } else if (raw === "--dry-run") {
      args.dryRun = true;
    } else if (raw.startsWith("--project=")) {
      args.project = raw.slice("--project=".length);
    }
  }
  return args;
}

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

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string" || typeof value === "number") {
    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}

async function main() {
  const args = parseArgs(process.argv);

  if (!args.project) {
    console.error(
      "ERROR: project id missing. Pass --project=<id> or set GOOGLE_CLOUD_PROJECT."
    );
    process.exit(1);
  }

  admin.initializeApp({projectId: args.project});
  const db = admin.firestore();

  console.log(`SF-026 normalize-booking-nights — project=${args.project}`);
  console.log(`Mode: ${args.dryRun ? "DRY RUN (no writes)" : "FORCE (will write)"}`);
  console.log("");

  const ELIGIBLE_STATUSES = [
    "confirmed",
    "pending_payment",
    "awaiting_owner_decision",
  ];

  const snap = await db
    .collectionGroup("bookings")
    .where("status", "in", ELIGIBLE_STATUSES)
    .get();

  console.log(`Found ${snap.size} candidate booking(s).`);

  let scanned = 0;
  let driftingCheckIn = 0;
  let driftingCheckOut = 0;
  let updated = 0;
  let skippedMissingDate = 0;
  const writes = [];

  for (const doc of snap.docs) {
    scanned++;
    const data = doc.data();
    const checkIn = toDate(data.check_in);
    const checkOut = toDate(data.check_out);

    if (!checkIn || !checkOut) {
      skippedMissingDate++;
      continue;
    }

    const normalizedIn = normalizeToZagrebCivilDayUTC(checkIn);
    const normalizedOut = normalizeToZagrebCivilDayUTC(checkOut);

    const inDrift = normalizedIn.getTime() !== checkIn.getTime();
    const outDrift = normalizedOut.getTime() !== checkOut.getTime();

    if (!inDrift && !outDrift) continue;
    if (inDrift) driftingCheckIn++;
    if (outDrift) driftingCheckOut++;

    const update = {};
    if (inDrift) update.check_in = admin.firestore.Timestamp.fromDate(normalizedIn);
    if (outDrift) update.check_out = admin.firestore.Timestamp.fromDate(normalizedOut);

    console.log(
      `  ${doc.ref.path}  status=${data.status}  ` +
      `in ${checkIn.toISOString()}→${normalizedIn.toISOString()}  ` +
      `out ${checkOut.toISOString()}→${normalizedOut.toISOString()}`
    );

    writes.push({ref: doc.ref, update});
  }

  console.log("");
  console.log(`Scanned: ${scanned}`);
  console.log(`Missing date (skipped): ${skippedMissingDate}`);
  console.log(`Drifting check_in: ${driftingCheckIn}`);
  console.log(`Drifting check_out: ${driftingCheckOut}`);
  console.log(`Bookings to update: ${writes.length}`);

  if (args.dryRun) {
    console.log("");
    console.log("DRY RUN complete — no writes performed.");
    console.log("Re-run with --force to apply.");
    return;
  }

  if (writes.length === 0) {
    console.log("Nothing to update.");
    return;
  }

  console.log("");
  console.log(`Writing ${writes.length} update(s) in batches of 400…`);
  const BATCH = 400;
  for (let i = 0; i < writes.length; i += BATCH) {
    const slice = writes.slice(i, i + BATCH);
    const batch = db.batch();
    slice.forEach(({ref, update}) => batch.update(ref, update));
    await batch.commit();
    updated += slice.length;
    console.log(`  committed ${updated}/${writes.length}`);
  }
  console.log("Done.");
}

main().catch((err) => {
  console.error("FATAL:", err);
  process.exit(1);
});
