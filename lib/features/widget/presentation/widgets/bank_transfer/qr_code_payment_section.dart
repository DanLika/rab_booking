import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
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

  const QrCodePaymentSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
    required this.amount,
    required this.bookingReference,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final epcData = _generateEpcQrData();

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
  String _generateEpcQrData() {
    final String bic = bankConfig.swift ?? '';
    final String beneficiaryName = bankConfig.accountHolder ?? 'N/A';
    final String iban = bankConfig.iban!.replaceAll(' ', '');
    final String amountStr = amount.toStringAsFixed(2);
    final String reference = bookingReference;

    final epcData = [
      'BCD', // Service tag
      '002', // Version
      '1', // Character set (UTF-8)
      'SCT', // Identification code
      bic, // BIC/SWIFT
      beneficiaryName, // Beneficiary name
      iban, // IBAN
      'EUR$amountStr', // Amount
      '', // Purpose
      reference, // Reference
      translations.bookingDeposit, // Remittance info
      '', // Information to beneficiary
    ].join('\n');

    return epcData;
  }
}
