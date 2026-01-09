import 'package:cloud_firestore/cloud_firestore.dart';

/// Account status enum for subscription management
enum AccountStatus {
  /// User is in free trial period
  trial,

  /// User has an active paid subscription
  active,

  /// User's trial has expired (read-only access)
  trialExpired,

  /// User's account is suspended (no access)
  suspended,
}

/// Extension to convert AccountStatus to/from Firestore string
extension AccountStatusExtension on AccountStatus {
  String get value {
    switch (this) {
      case AccountStatus.trial:
        return 'trial';
      case AccountStatus.active:
        return 'active';
      case AccountStatus.trialExpired:
        return 'trial_expired';
      case AccountStatus.suspended:
        return 'suspended';
    }
  }

  static AccountStatus fromString(String? value) {
    switch (value) {
      case 'trial':
        return AccountStatus.trial;
      case 'active':
        return AccountStatus.active;
      case 'trial_expired':
        return AccountStatus.trialExpired;
      case 'suspended':
        return AccountStatus.suspended;
      default:
        return AccountStatus.trial; // Default to trial for new users
    }
  }
}

/// Model representing user's trial/subscription status
class TrialStatus {
  final AccountStatus accountStatus;
  final DateTime? trialStartDate;
  final DateTime? trialExpiresAt;
  final DateTime? statusChangedAt;
  final String? statusChangedBy;
  final String? statusChangeReason;

  const TrialStatus({
    required this.accountStatus,
    this.trialStartDate,
    this.trialExpiresAt,
    this.statusChangedAt,
    this.statusChangedBy,
    this.statusChangeReason,
  });

  /// Create from Firestore document data
  factory TrialStatus.fromFirestore(Map<String, dynamic> data) {
    return TrialStatus(
      accountStatus: AccountStatusExtension.fromString(
        data['accountStatus'] as String?,
      ),
      trialStartDate: (data['trialStartDate'] as Timestamp?)?.toDate(),
      trialExpiresAt: (data['trialExpiresAt'] as Timestamp?)?.toDate(),
      statusChangedAt: (data['statusChangedAt'] as Timestamp?)?.toDate(),
      statusChangedBy: data['statusChangedBy'] as String?,
      statusChangeReason: data['statusChangeReason'] as String?,
    );
  }

  /// Default trial status for new users
  factory TrialStatus.newUser() {
    final now = DateTime.now();
    return TrialStatus(
      accountStatus: AccountStatus.trial,
      trialStartDate: now,
      trialExpiresAt: now.add(const Duration(days: 30)),
    );
  }

  /// Check if user has full access (trial or active)
  bool get hasFullAccess =>
      accountStatus == AccountStatus.trial ||
      accountStatus == AccountStatus.active;

  /// Check if trial is active
  bool get isInTrial => accountStatus == AccountStatus.trial;

  /// Check if trial has expired
  bool get isTrialExpired => accountStatus == AccountStatus.trialExpired;

  /// Check if account is suspended
  bool get isSuspended => accountStatus == AccountStatus.suspended;

  /// Check if user has active paid subscription
  bool get isActive => accountStatus == AccountStatus.active;

  /// Get days remaining in trial (0 if not in trial or expired)
  int get daysRemaining {
    if (!isInTrial || trialExpiresAt == null) return 0;
    final remaining = trialExpiresAt!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if trial is expiring soon (within 7 days)
  bool get isExpiringSoon =>
      isInTrial && daysRemaining <= 7 && daysRemaining > 0;

  /// Get human-readable status text
  String get statusText {
    switch (accountStatus) {
      case AccountStatus.trial:
        if (daysRemaining <= 0) return 'Trial ending today';
        if (daysRemaining == 1) return '1 day left in trial';
        return '$daysRemaining days left in trial';
      case AccountStatus.active:
        return 'Active subscription';
      case AccountStatus.trialExpired:
        return 'Trial expired';
      case AccountStatus.suspended:
        return 'Account suspended';
    }
  }

  @override
  String toString() =>
      'TrialStatus(status: $accountStatus, daysRemaining: $daysRemaining)';
}
