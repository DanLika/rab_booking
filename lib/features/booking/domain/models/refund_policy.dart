import 'package:freezed_annotation/freezed_annotation.dart';

part 'refund_policy.freezed.dart';
part 'refund_policy.g.dart';

/// Refund policy model for cancellation calculations
/// Based on Booking.com style progressive cancellation fees
@freezed
class RefundPolicy with _$RefundPolicy {
  const factory RefundPolicy({
    required int daysBeforeCheckIn,
    required double refundPercentage,
    required double cancellationFeePercentage,
    String? description,
  }) = _RefundPolicy;

  factory RefundPolicy.fromJson(Map<String, dynamic> json) =>
      _$RefundPolicyFromJson(json);
}

/// Refund policy helper methods
extension RefundPolicyExtension on RefundPolicy {
  /// Calculate refund amount for a given booking total
  double calculateRefund(double totalAmount) {
    return totalAmount * refundPercentage;
  }

  /// Calculate cancellation fee
  double calculateCancellationFee(double totalAmount) {
    return totalAmount * cancellationFeePercentage;
  }

  /// Get user-friendly description
  String get displayDescription {
    if (description != null) return description!;

    if (daysBeforeCheckIn >= 30) {
      return 'Free cancellation (100% refund)';
    } else if (daysBeforeCheckIn >= 14) {
      return '75% refund - 25% cancellation fee';
    } else if (daysBeforeCheckIn >= 7) {
      return '50% refund - 50% cancellation fee';
    } else {
      return 'Non-refundable';
    }
  }
}

/// Standard refund policies (Booking.com style)
class RefundPolicies {
  /// Standard policy with progressive fees
  static List<RefundPolicy> standardPolicy() => [
        const RefundPolicy(
          daysBeforeCheckIn: 30,
          refundPercentage: 1.0,
          cancellationFeePercentage: 0.0,
          description: 'Free cancellation (30+ days before check-in)',
        ),
        const RefundPolicy(
          daysBeforeCheckIn: 14,
          refundPercentage: 0.75,
          cancellationFeePercentage: 0.25,
          description: '75% refund (14-29 days before check-in)',
        ),
        const RefundPolicy(
          daysBeforeCheckIn: 7,
          refundPercentage: 0.50,
          cancellationFeePercentage: 0.50,
          description: '50% refund (7-13 days before check-in)',
        ),
        const RefundPolicy(
          daysBeforeCheckIn: 0,
          refundPercentage: 0.0,
          cancellationFeePercentage: 1.0,
          description: 'Non-refundable (less than 7 days before check-in)',
        ),
      ];

  /// Flexible policy - more guest-friendly
  static List<RefundPolicy> flexiblePolicy() => [
        const RefundPolicy(
          daysBeforeCheckIn: 7,
          refundPercentage: 1.0,
          cancellationFeePercentage: 0.0,
          description: 'Free cancellation (7+ days before check-in)',
        ),
        const RefundPolicy(
          daysBeforeCheckIn: 3,
          refundPercentage: 0.50,
          cancellationFeePercentage: 0.50,
          description: '50% refund (3-6 days before check-in)',
        ),
        const RefundPolicy(
          daysBeforeCheckIn: 0,
          refundPercentage: 0.0,
          cancellationFeePercentage: 1.0,
          description: 'Non-refundable (less than 3 days before check-in)',
        ),
      ];

  /// Strict policy - minimal refunds
  static List<RefundPolicy> strictPolicy() => [
        const RefundPolicy(
          daysBeforeCheckIn: 60,
          refundPercentage: 0.50,
          cancellationFeePercentage: 0.50,
          description: '50% refund (60+ days before check-in)',
        ),
        const RefundPolicy(
          daysBeforeCheckIn: 0,
          refundPercentage: 0.0,
          cancellationFeePercentage: 1.0,
          description: 'Non-refundable (less than 60 days before check-in)',
        ),
      ];

  /// Get applicable policy based on days until check-in
  static RefundPolicy getApplicablePolicy({
    required DateTime checkInDate,
    List<RefundPolicy>? customPolicies,
  }) {
    final policies = customPolicies ?? standardPolicy();
    final now = DateTime.now();
    final daysUntilCheckIn = checkInDate.difference(now).inDays;

    // Find first policy that matches
    return policies.firstWhere(
      (policy) => daysUntilCheckIn >= policy.daysBeforeCheckIn,
      orElse: () => policies.last,
    );
  }

  /// Check if cancellation is allowed
  static bool canCancelBooking({
    required DateTime checkInDate,
    List<RefundPolicy>? customPolicies,
  }) {
    final policy = getApplicablePolicy(
      checkInDate: checkInDate,
      customPolicies: customPolicies,
    );
    return policy.refundPercentage > 0;
  }
}
