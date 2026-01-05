/// Base mixin for payment configuration classes
/// Provides shared deposit calculation logic using cent-based arithmetic
/// to avoid floating point precision errors.
///
/// This mirrors the backend implementation in `functions/src/utils/depositCalculation.ts`
/// for consistency between client and server calculations.
mixin PaymentConfigBase {
  /// Deposit percentage (0-100)
  /// 0 or 100 = full payment required
  int get depositPercentage;

  /// Calculate deposit amount based on total using integer arithmetic.
  ///
  /// Uses cent-based calculation to avoid floating point errors:
  /// - Converts prices to cents (integer)
  /// - Performs calculation in cents
  /// - Converts back to currency with proper rounding
  ///
  /// Example:
  /// - totalAmount: 100.10, depositPercentage: 33% → 33.03 (not 33.033000000000005)
  double calculateDeposit(double totalAmount) {
    // Debug assertions for development
    assert(totalAmount >= 0, 'totalAmount cannot be negative: $totalAmount');
    assert(
      depositPercentage >= 0 && depositPercentage <= 100,
      'depositPercentage must be 0-100: $depositPercentage',
    );

    // Safe fallback for invalid input in release mode
    if (totalAmount < 0) return 0.0;
    if (depositPercentage < 0 || depositPercentage > 100) return 0.0;

    // Edge cases: full payment required
    if (depositPercentage == 0 || depositPercentage == 100) {
      return totalAmount;
    }

    // Integer arithmetic to avoid floating point errors
    final totalCents = (totalAmount * 100).round();
    final depositCents = (totalCents * depositPercentage / 100).round();
    return depositCents / 100;
  }

  /// Calculate remaining amount after deposit using integer arithmetic.
  ///
  /// Uses cent-based calculation to avoid floating point errors.
  double calculateRemaining(double totalAmount) {
    // Debug assertions for development
    assert(totalAmount >= 0, 'totalAmount cannot be negative: $totalAmount');
    assert(
      depositPercentage >= 0 && depositPercentage <= 100,
      'depositPercentage must be 0-100: $depositPercentage',
    );

    // Safe fallback for invalid input in release mode
    if (totalAmount < 0) return 0.0;
    if (depositPercentage < 0 || depositPercentage > 100) return 0.0;

    // Edge cases: full payment required, no remaining
    if (depositPercentage == 0 || depositPercentage == 100) {
      return 0.0;
    }

    // Integer arithmetic to avoid floating point errors
    final totalCents = (totalAmount * 100).round();
    final depositCents = (totalCents * depositPercentage / 100).round();
    final remainingCents = totalCents - depositCents;
    return remainingCents / 100;
  }
}
