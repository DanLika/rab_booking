import 'payment_config_base.dart';

/// Bank transfer payment configuration
///
/// Bank details are now centralized in owner's CompanyDetails profile.
/// This config stores:
/// - ownerId: Reference to owner for fetching bank details from profile
/// - Widget-specific options: paymentDeadlineDays, enableQrCode, customNotes
/// - Legacy fields: For backward compatibility with existing widgets
///
/// Uses [PaymentConfigBase] mixin for shared deposit calculation logic.
///
/// ## Example
/// ```dart
/// final bankConfig = BankTransferConfig(
///   enabled: true,
///   depositPercentage: 30,
///   ownerId: 'user_123',
///   paymentDeadlineDays: 5,
/// );
///
/// if (bankConfig.hasOwnerId) {
///   // Fetch bank details from CompanyDetails
/// }
/// ```
class BankTransferConfig with PaymentConfigBase {
  final bool enabled;

  @override
  final int depositPercentage; // 0-100

  /// Reference to owner's userId for fetching bank details from CompanyDetails
  /// New widgets should use this instead of storing bank details per-unit
  final String? ownerId;

  // Widget-specific options (NOT bank details)
  final int paymentDeadlineDays; // Days until payment deadline (1-14, default: 3)
  final bool enableQrCode; // Show EPC QR code for bank transfer
  final String? customNotes; // Custom notes from owner (max 500 chars)
  final bool useCustomNotes; // If true, show customNotes; if false, show default legal notes

  // LEGACY FIELDS - For backward compatibility with existing widgets
  // New widgets should NOT write these fields, but still read them
  final String? bankName;
  final String? accountNumber;
  final String? iban;
  final String? swift;
  final String? accountHolder;

  const BankTransferConfig({
    this.enabled = false,
    this.depositPercentage = 20,
    this.ownerId,
    this.paymentDeadlineDays = 3,
    this.enableQrCode = true,
    this.customNotes,
    this.useCustomNotes = false,
    // Legacy fields
    this.bankName,
    this.accountNumber,
    this.iban,
    this.swift,
    this.accountHolder,
  });

  factory BankTransferConfig.fromMap(Map<String, dynamic> map) {
    return BankTransferConfig(
      enabled: map['enabled'] ?? false,
      depositPercentage: (map['deposit_percentage'] ?? 20).clamp(0, 100),
      ownerId: map['owner_id'],
      paymentDeadlineDays: (map['payment_deadline_days'] ?? 3).clamp(1, 14),
      enableQrCode: map['enable_qr_code'] ?? true,
      customNotes: map['custom_notes'],
      useCustomNotes: map['use_custom_notes'] ?? false,
      // Legacy fields - still read for backward compatibility
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      iban: map['iban'],
      swift: map['swift'],
      accountHolder: map['account_holder'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'deposit_percentage': depositPercentage,
      'owner_id': ownerId,
      'payment_deadline_days': paymentDeadlineDays,
      'enable_qr_code': enableQrCode,
      'custom_notes': customNotes,
      'use_custom_notes': useCustomNotes,
      // Legacy fields - still write for backward compatibility with existing widgets
      'bank_name': bankName,
      'account_number': accountNumber,
      'iban': iban,
      'swift': swift,
      'account_holder': accountHolder,
    };
  }

  /// Check if this config has an ownerId for fetching bank details from profile
  bool get hasOwnerId => ownerId != null && ownerId!.isNotEmpty;

  /// Check if bank details are available (either from ownerId or legacy fields)
  /// Widget should first check hasOwnerId, then fall back to legacy fields
  bool get hasCompleteDetails {
    // New approach: ownerId points to CompanyDetails
    if (hasOwnerId) return true;
    // Legacy approach: bank details stored in config
    return bankName != null &&
        accountHolder != null &&
        (iban != null || accountNumber != null);
  }

  /// Check if this config has legacy bank details (for backward compatibility)
  bool get hasLegacyBankDetails {
    return bankName != null &&
        bankName!.isNotEmpty &&
        accountHolder != null &&
        accountHolder!.isNotEmpty &&
        (iban != null && iban!.isNotEmpty);
  }

  BankTransferConfig copyWith({
    bool? enabled,
    int? depositPercentage,
    String? ownerId,
    int? paymentDeadlineDays,
    bool? enableQrCode,
    String? customNotes,
    bool? useCustomNotes,
    String? bankName,
    String? accountNumber,
    String? iban,
    String? swift,
    String? accountHolder,
  }) {
    return BankTransferConfig(
      enabled: enabled ?? this.enabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      ownerId: ownerId ?? this.ownerId,
      paymentDeadlineDays: paymentDeadlineDays ?? this.paymentDeadlineDays,
      enableQrCode: enableQrCode ?? this.enableQrCode,
      customNotes: customNotes ?? this.customNotes,
      useCustomNotes: useCustomNotes ?? this.useCustomNotes,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      swift: swift ?? this.swift,
      accountHolder: accountHolder ?? this.accountHolder,
    );
  }
}
