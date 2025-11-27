/// Base mixin for payment configuration classes
/// Provides shared deposit calculation logic
mixin PaymentConfigBase {
  /// Deposit percentage (0-100)
  /// 0 or 100 = full payment required
  int get depositPercentage;

  /// Calculate deposit amount based on total
  double calculateDeposit(double totalAmount) {
    if (depositPercentage == 0 || depositPercentage == 100) {
      return totalAmount; // Full payment
    }
    return totalAmount * (depositPercentage / 100);
  }

  /// Calculate remaining amount after deposit
  double calculateRemaining(double totalAmount) {
    if (depositPercentage == 0 || depositPercentage == 100) {
      return 0.0; // No remaining
    }
    return totalAmount * ((100 - depositPercentage) / 100);
  }
}
