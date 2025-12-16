import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/services/logging_service.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';
import '../../l10n/widget_translations.dart';

/// Reusable QR code payment section for bank transfers
/// Generates EPC QR code compatible with European banking apps
class QrCodePaymentSection extends StatelessWidget {
  final bool isDarkMode;
  final BankTransferConfig bankConfig;
  final double amount;
  final String bookingReference;
  final WidgetTranslations translations;
  /// Currency code (ISO 4217, e.g., 'EUR', 'HRK', 'USD')
  /// Defaults to 'EUR' for SEPA compatibility
  final String currency;

  const QrCodePaymentSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
    required this.amount,
    required this.bookingReference,
    required this.translations,
    this.currency = 'EUR',
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final epcData = _generateEpcQrData();

    // Bug Fix: Don't render QR section if IBAN is missing (prevents crash)
    if (epcData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.l),
          _buildQrCode(epcData, colors),
          const SizedBox(height: SpacingTokens.m),
          _buildInfoBanner(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(MinimalistColorSchemeAdapter colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.s),
          decoration: BoxDecoration(
            color: colors.buttonPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
          ),
          child: Icon(
            Icons.qr_code_2,
            color: colors.buttonPrimary,
            size: IconSizeTokens.medium,
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translations.qrCodeForPayment,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: SpacingTokens.xxs),
              Text(
                translations.scanWithMobileBank,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeS,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode(String epcData, MinimalistColorSchemeAdapter colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: ColorTokens.pureWhite,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthMedium,
        ),
      ),
      child: QrImageView(
        data: epcData,
        size: 200.0,
        backgroundColor: ColorTokens.pureWhite,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  Widget _buildInfoBanner(MinimalistColorSchemeAdapter colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: colors.buttonPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
        border: Border.all(color: colors.buttonPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: IconSizeTokens.small,
            color: colors.buttonPrimary,
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Text(
              translations.qrCodeContainsPaymentData,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeS,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate EPC QR code data for SEPA bank transfers
  /// Format follows European Payments Council standard
  /// Returns null if required fields are missing or invalid
  String? _generateEpcQrData() {
    // Validate required fields
    final validationError = _validateRequiredFields();
    if (validationError != null) {
      LoggingService.logWarning(
        'QrCodePaymentSection: Cannot generate EPC QR - $validationError',
      );
      return null;
    }

    // Prepare and validate field values
    final String iban = bankConfig.iban!.replaceAll(' ', '');
    final String bic = bankConfig.swift?.trim() ?? '';
    final String beneficiaryName = _truncateField(bankConfig.accountHolder!, 70);
    final String amountStr = amount.toStringAsFixed(2);
    final String reference = _truncateField(bookingReference, 25);
    final String remittanceInfo = _truncateField(translations.bookingDeposit, 140);
    final String currencyCode = _validateCurrencyCode(currency);

    // Validate EPC format constraints
    final formatError = _validateEpcFormat(iban, bic, beneficiaryName);
    if (formatError != null) {
      LoggingService.logWarning(
        'QrCodePaymentSection: EPC format validation failed - $formatError',
      );
      return null;
    }

    final epcData = [
      'BCD', // Service tag
      '002', // Version
      '1', // Character set (UTF-8)
      'SCT', // Identification code
      bic, // BIC/SWIFT (can be empty for domestic transfers)
      beneficiaryName, // Beneficiary name (max 70 chars)
      iban, // IBAN (max 34 chars)
      '$currencyCode$amountStr', // Amount with currency
      '', // Purpose
      reference, // Reference (max 25 chars)
      remittanceInfo, // Remittance info (max 140 chars)
      '', // Information to beneficiary
    ].join('\n');

    return epcData;
  }

  /// Validate that all required fields are present and valid
  /// Returns error message if validation fails, null if valid
  String? _validateRequiredFields() {
    // IBAN is required
    if (bankConfig.iban == null || bankConfig.iban!.trim().isEmpty) {
      return 'IBAN is missing';
    }

    // Account holder is required (not null, empty, or 'N/A')
    final holder = bankConfig.accountHolder;
    if (holder == null || holder.trim().isEmpty || holder.trim() == 'N/A') {
      return 'Account holder name is missing or invalid';
    }

    // Amount must be positive
    if (amount <= 0) {
      return 'Amount must be positive';
    }

    return null;
  }

  /// Validate EPC QR code format constraints
  /// Returns error message if validation fails, null if valid
  String? _validateEpcFormat(String iban, String bic, String beneficiaryName) {
    // IBAN max 34 characters (without spaces)
    if (iban.length > 34) {
      return 'IBAN exceeds 34 characters';
    }

    // BIC must be 8 or 11 characters, or empty (for domestic transfers)
    if (bic.isNotEmpty && bic.length != 8 && bic.length != 11) {
      return 'BIC must be 8 or 11 characters (got ${bic.length})';
    }

    // Beneficiary name is required and max 70 characters (already truncated)
    if (beneficiaryName.isEmpty) {
      return 'Beneficiary name is empty';
    }

    return null;
  }

  /// Validate and normalize currency code (ISO 4217)
  /// Returns uppercase 3-letter code, defaults to 'EUR' if invalid
  String _validateCurrencyCode(String code) {
    final normalized = code.trim().toUpperCase();
    // Must be exactly 3 letters
    if (normalized.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
      return normalized;
    }
    // Fall back to EUR for SEPA compatibility
    return 'EUR';
  }

  /// Truncate field to maximum length (EPC standard requirement)
  String _truncateField(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return trimmed.substring(0, maxLength);
  }
}
