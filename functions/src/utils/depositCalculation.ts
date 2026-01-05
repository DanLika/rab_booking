/**
 * Calculate deposit amount using integer arithmetic
 *
 * FIXES floating point errors by using cent-based calculations:
 * - Converts prices to cents (integer)
 * - Performs calculation in cents
 * - Converts back to dollars with proper rounding
 *
 * EXAMPLES:
 * - totalPrice: $100.10, percentage: 33% → $33.03 (not 33.033000000000005)
 * - totalPrice: $50.00, percentage: 50% → $25.00 (exactly)
 *
 * @param totalPrice - Total booking price in dollars (e.g., 100.50)
 * @param depositPercentage - Deposit percentage (e.g., 20 for 20%)
 * @returns Deposit amount in dollars, rounded to 2 decimal places
 */
export function calculateDepositAmount(
  totalPrice: number,
  depositPercentage: number
): number {
  // ========================================================================
  // STEP 1: VALIDATION
  // ========================================================================
  if (totalPrice < 0) {
    throw new Error(`Total price cannot be negative: ${totalPrice}`);
  }

  if (depositPercentage < 0 || depositPercentage > 100) {
    throw new Error(
      `Deposit percentage must be 0-100: ${depositPercentage}`
    );
  }

  // Edge case: 0% deposit or $0 price
  if (depositPercentage === 0 || totalPrice === 0) {
    return 0.0;
  }

  // ========================================================================
  // STEP 2: INTEGER ARITHMETIC (avoid floating point errors)
  // ========================================================================

  // Convert to cents (multiply by 100, round to nearest integer)
  const totalPriceCents = Math.round(totalPrice * 100);

  // Calculate deposit in cents (integer division)
  // Use Math.round for proper rounding (not floor/ceil)
  const depositCents = Math.round((totalPriceCents * depositPercentage) / 100);

  // Convert back to dollars
  const depositAmount = depositCents / 100;

  // ========================================================================
  // STEP 3: ROUND TO 2 DECIMAL PLACES (safety check)
  // ========================================================================
  // This should already be 2 decimals from cent-based calculation,
  // but we round again to be absolutely sure
  return Math.round(depositAmount * 100) / 100;
}

/**
 * Calculate remaining amount after deposit
 *
 * @param totalPrice - Total booking price in dollars
 * @param depositAmount - Deposit amount in dollars (from calculateDepositAmount)
 * @returns Remaining amount in dollars, rounded to 2 decimal places
 */
export function calculateRemainingAmount(
  totalPrice: number,
  depositAmount: number
): number {
  // Use same integer arithmetic to avoid floating point errors
  const totalPriceCents = Math.round(totalPrice * 100);
  const depositCents = Math.round(depositAmount * 100);
  const remainingCents = totalPriceCents - depositCents;

  // Safety check: remaining should never be negative
  if (remainingCents < 0) {
    throw new Error(
      `Remaining amount cannot be negative. Total: $${totalPrice}, Deposit: $${depositAmount}`
    );
  }

  return remainingCents / 100;
}
