#!/usr/bin/env node
/* eslint-disable no-console */
/*
 * Smoke: F-50-01 (PR #481) ALLOWED_SUBSCRIPTION_PRICE_IDS allowlist
 *
 * Scope: gate logic only (parse env + reject). Does NOT call Stripe / emulator.
 * Replicates lines 47-67 of functions/src/stripeSubscription.ts verbatim and
 * exercises 4 cases that flip process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS.
 *
 * Why pure-logic: F-50-01 is the gate fix. End-to-end Stripe needs real test
 * priceIds + ID token + audit/38 env provisioning — that is operator work, not
 * what this smoke validates.
 *
 * Run: node functions/scripts/smoke-allowlist.js
 */

const SOURCE_FILE = "functions/src/stripeSubscription.ts";

class FakeHttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "HttpsError";
    this.code = code;
  }
}

// Verbatim port of stripeSubscription.ts:47-67 (allowlist gate).
// If the source drifts, update this — and run npm run build before smoke
// so the artifact-grep step catches the drift independently.
function runAllowlistGate({priceId}) {
  const allowedPriceIds = (process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  if (allowedPriceIds.length === 0) {
    // logError("ALLOWED_SUBSCRIPTION_PRICE_IDS is empty — subscription checkout blocked", ...)
    throw new FakeHttpsError(
      "failed-precondition",
      "Subscription pricing is not configured. Contact support."
    );
  }
  if (!allowedPriceIds.includes(priceId)) {
    // logError("Subscription checkout rejected: priceId not in allowlist", ...)
    throw new FakeHttpsError("invalid-argument", "Price not allowed.");
  }
  // Past the gate — production code would proceed to Stripe call here.
  return {gatePassed: true, allowlistSize: allowedPriceIds.length};
}

const cases = [
  {
    name: "Case 1 — priceId in allowlist",
    env: "price_test_valid_001,price_test_valid_002",
    priceId: "price_test_valid_001",
    expect: {kind: "pass", allowlistSize: 2},
  },
  {
    name: "Case 2 — priceId NOT in allowlist",
    env: "price_test_valid_001,price_test_valid_002",
    priceId: "price_test_unknown_999",
    expect: {kind: "throw", code: "invalid-argument", message: "Price not allowed."},
  },
  {
    name: "Case 3 — empty env var (fail-CLOSED)",
    env: "", // simulates unset/empty
    priceId: "price_test_valid_001",
    expect: {
      kind: "throw",
      code: "failed-precondition",
      message: "Subscription pricing is not configured. Contact support.",
    },
  },
  {
    name: "Case 4 — env w/ whitespace + trailing comma",
    env: "  price_test_valid_001 , price_test_valid_002 ,",
    priceId: "price_test_valid_002",
    expect: {kind: "pass", allowlistSize: 2}, // trim + filter(Boolean) drops empty tail
  },
];

function fmt(obj) {
  return JSON.stringify(obj, null, 0);
}

let pass = 0;
let fail = 0;
const rows = [];

for (const c of cases) {
  process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS = c.env;
  let actual;
  try {
    actual = {kind: "pass", ...runAllowlistGate({priceId: c.priceId})};
  } catch (e) {
    actual = {kind: "throw", code: e.code, message: e.message};
  }

  // Compare
  let ok = actual.kind === c.expect.kind;
  if (ok && c.expect.kind === "throw") {
    ok = actual.code === c.expect.code && actual.message === c.expect.message;
  }
  if (ok && c.expect.kind === "pass") {
    ok = actual.allowlistSize === c.expect.allowlistSize;
  }

  if (ok) pass++;
  else fail++;
  rows.push({
    name: c.name,
    env: c.env === "" ? "(empty)" : c.env,
    priceId: c.priceId,
    expected: fmt(c.expect),
    actual: fmt(actual),
    verdict: ok ? "PASS" : "FAIL",
  });
}

console.log("\nF-50-01 smoke — ALLOWED_SUBSCRIPTION_PRICE_IDS gate");
console.log(`Source: ${SOURCE_FILE} (replicated 47-67)\n`);
for (const r of rows) {
  console.log(`[${r.verdict}] ${r.name}`);
  console.log(`        env:      ${r.env}`);
  console.log(`        priceId:  ${r.priceId}`);
  console.log(`        expected: ${r.expected}`);
  console.log(`        actual:   ${r.actual}`);
  console.log("");
}
console.log(`Summary: ${pass} pass / ${fail} fail (of ${cases.length})`);

process.exit(fail === 0 ? 0 : 1);
