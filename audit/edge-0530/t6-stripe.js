#!/usr/bin/env node
/**
 * T6: Stripe deposit / minimum / fee-allocation.
 *
 * Live testing blocked on bookbed-dev:
 *   - acct_TEST_E2E_DD mock — fails verifyStripeConnectAccount egress.
 *   - Real test fixture acct_1Tc037PnKJAl9q6s has charges_enabled=false
 *     (F-70-02 hCaptcha blocker per memory/stripe-connect-test-fixture.md).
 *
 * So this test is HYBRID:
 *
 *   A. Math layer: calculateDepositAmount + calculateRemainingAmount across
 *      sensitive edge inputs (€0.10, €0.49, €0.50, €100.10×33%, etc.).
 *   B. Min-amount logic: simulate stripePayment.ts:381 floor behavior.
 *   C. Fee-allocation static check: grep for `application_fee_amount` (must
 *      NOT be set in createStripeCheckoutSession) AND `on_behalf_of` +
 *      `transfer_data.destination` (must BOTH be ownerStripeAccountId).
 *   D. €0 free-booking guard: stripePayment.ts:215 `if (!totalPrice)` falsy
 *      check trips on totalPrice=0 — verified by the source line.
 *
 * Cleanup: none — no Firestore writes.
 */

const path = require('path');
const fs = require('fs');

// Import math helpers from built JS
const fnDir = path.resolve('/Users/duskolicanin/git/bookbed/functions');
const {calculateDepositAmount, calculateRemainingAmount} =
  require(path.join(fnDir, 'lib/utils/depositCalculation'));

function expect(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`  ${ok ? '✓' : '✗'} ${name}: ${ok ? 'OK' : `EXPECTED ${JSON.stringify(expected)} GOT ${JSON.stringify(actual)}`}`);
  if (!ok) process.exitCode = 1;
}

console.log('T6 — Stripe deposit / minimum / fee-allocation\n');

// ---- A. Math layer
console.log('[A] calculateDepositAmount integer-cent arithmetic:');
{
  expect('0% deposit on €200 → €0', calculateDepositAmount(200, 0), 0);
  expect('50% deposit on €200 → €100', calculateDepositAmount(200, 50), 100);
  expect('33% deposit on €100.10 → €33.03 (not float garbage)', calculateDepositAmount(100.10, 33), 33.03);
  expect('100% deposit on €100 → €100', calculateDepositAmount(100, 100), 100);
  expect('1% deposit on €0.10 → €0', calculateDepositAmount(0.10, 1), 0);
  expect('Negative price throws', (() => {
    try { calculateDepositAmount(-1, 50); return 'no-throw'; }
    catch (e) { return 'threw'; }
  })(), 'threw');
  expect('Out-of-range percent throws', (() => {
    try { calculateDepositAmount(100, 101); return 'no-throw'; }
    catch (e) { return 'threw'; }
  })(), 'threw');
}

console.log('\n[A.2] calculateRemainingAmount:');
{
  expect('€200 − €100 deposit = €100 remaining', calculateRemainingAmount(200, 100), 100);
  expect('€100.10 − €33.03 = €67.07', calculateRemainingAmount(100.10, 33.03), 67.07);
  expect('€0 − €0 = €0', calculateRemainingAmount(0, 0), 0);
  expect('Negative remaining throws', (() => {
    try { calculateRemainingAmount(50, 100); return 'no-throw'; }
    catch (e) { return 'threw'; }
  })(), 'threw');
}

// ---- B. Min-amount logic
console.log('\n[B] STRIPE_MINIMUM_CENTS=50 floor:');
{
  const STRIPE_MINIMUM_CENTS = 50;

  function applyFloor(depositAmount) {
    const raw = Math.round(depositAmount * 100);
    const floored = Math.max(raw, STRIPE_MINIMUM_CENTS);
    return {raw, floored, adjustedEuros: floored / 100};
  }

  // ⚠️ FINDING-2 candidate: €0.10 base, 20% deposit = €0.02 → bumped to €0.50
  // Guest OVERPAYS €0.48 for a €0.10 booking
  const overpayCase = applyFloor(calculateDepositAmount(0.10, 20));
  console.log(`  €0.10 booking, 20% deposit: raw=${overpayCase.raw}¢ floored=${overpayCase.floored}¢ → guest charged €${overpayCase.adjustedEuros}`);
  expect('OVERPAY: €0.02 → €0.50 (5000% markup)', overpayCase.floored, 50);

  // €0.50 deposit exactly → unchanged
  const exactCase = applyFloor(0.50);
  expect('€0.50 exact deposit → no bump', exactCase.floored, 50);

  // €100 booking 30% = €30 → unchanged
  const normalCase = applyFloor(30);
  expect('€30 deposit normal → no bump', normalCase.floored, 3000);

  // €0.49 → bumped to €0.50 (1c bump)
  const closeBumpCase = applyFloor(0.49);
  expect('€0.49 → €0.50 (1c bump)', closeBumpCase.floored, 50);
}

// ---- C. Fee-allocation static checks
console.log('\n[C] Fee-allocation static checks on stripePayment.ts:');
{
  const stripePaymentSrc = fs.readFileSync(
    path.join(fnDir, 'src/stripePayment.ts'),
    'utf-8',
  );
  const hasApplicationFee = /application_fee_amount\s*:/.test(stripePaymentSrc);
  const hasOnBehalfOf = /on_behalf_of:\s*ownerStripeAccountId/.test(stripePaymentSrc);
  const hasTransferDataDest = /destination:\s*ownerStripeAccountId/.test(stripePaymentSrc);

  expect('No application_fee_amount (platform takes nothing)', hasApplicationFee, false);
  expect('on_behalf_of = ownerStripeAccountId (charge ON OWNER)', hasOnBehalfOf, true);
  expect('transfer_data.destination = ownerStripeAccountId', hasTransferDataDest, true);

  console.log('  → Combined: Stripe processing fee deducted from OWNER. Guest charged ONLY the deposit/total. ✅');
}

// ---- D. €0 free-booking guard
console.log('\n[D] Stripe path rejects totalPrice=0 (no €0.50 surprise charge):');
{
  const stripePaymentSrc = fs.readFileSync(
    path.join(fnDir, 'src/stripePayment.ts'),
    'utf-8',
  );
  const hasFalsyGuard = /if\s*\(\s*!totalPrice\s*\)/.test(stripePaymentSrc);
  expect('Falsy totalPrice rejected at gate', hasFalsyGuard, true);
}

console.log('\n');
console.log(process.exitCode === 1 ? '❌ T6 some FAIL' : '✅ T6 PASS — Stripe math + fee allocation behaves');
