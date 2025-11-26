import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';

/// Reusable QR code payment section for bank transfers
/// Generates EPC QR code compatible with European banking apps
class QrCodePaymentSection extends StatelessWidget {
  final bool isDarkMode;
  final BankTransferConfig bankConfig;
  final double amount;
  final String bookingReference;

  const QrCodePaymentSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
    required this.amount,
    required this.bookingReference,
  });

  @override
  Widget build(BuildContext context) {
    final epcData = _generateEpcQrData();

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: _getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: _getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: SpacingTokens.l),
          _buildQrCode(epcData),
          const SizedBox(height: SpacingTokens.m),
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.s),
          decoration: BoxDecoration(
            color: _getColor(
              MinimalistColors.buttonPrimary,
              MinimalistColorsDark.buttonPrimary,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
          ),
          child: Icon(
            Icons.qr_code_2,
            color: _getColor(
              MinimalistColors.buttonPrimary,
              MinimalistColorsDark.buttonPrimary,
            ),
            size: IconSizeTokens.medium,
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QR Kod za Uplatu',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.bold,
                  color: _getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.xxs),
              Text(
                'Skenirajte sa mobilnom bankom',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeS,
                  color: _getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode(String epcData) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: ColorTokens.pureWhite,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: _getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
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

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: _getColor(
          MinimalistColors.buttonPrimary,
          MinimalistColorsDark.buttonPrimary,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
        border: Border.all(
          color: _getColor(
            MinimalistColors.buttonPrimary,
            MinimalistColorsDark.buttonPrimary,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: IconSizeTokens.small,
            color: _getColor(
              MinimalistColors.buttonPrimary,
              MinimalistColorsDark.buttonPrimary,
            ),
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Text(
              'QR kod sadrži sve podatke o uplati (IBAN, iznos, referenca). '
              'Skenirajte ga sa aplikacijom vaše banke.',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeS,
                color: _getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
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
      'Booking deposit', // Remittance info
      '', // Information to beneficiary
    ].join('\n');

    return epcData;
  }

  Color _getColor(Color lightColor, Color darkColor) {
    return isDarkMode ? darkColor : lightColor;
  }
}
