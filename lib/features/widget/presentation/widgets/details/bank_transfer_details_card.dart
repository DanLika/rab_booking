import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';
import '../../../domain/models/booking_details_model.dart';

/// Card displaying bank transfer payment details.
///
/// Shows IBAN, bank name, account holder, and SWIFT code for bank transfers.
/// Includes copy-to-clipboard functionality for easy payment setup.
///
/// Only shown when:
/// - Payment method is 'bank_transfer'
/// - Bank details are provided by the owner
/// - Booking is not yet fully paid
class BankTransferDetailsCard extends ConsumerWidget {
  /// Bank details from owner's company settings
  final BankDetails bankDetails;

  /// Booking reference for payment description
  final String bookingReference;

  /// Amount to pay
  final double amount;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BankTransferDetailsCard({
    super.key,
    required this.bankDetails,
    required this.bookingReference,
    required this.amount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    final cardBackground = isDark ? colors.backgroundTertiary : colors.backgroundSecondary;
    final cardBorder = isDark ? colors.borderMedium : colors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: cardBorder, width: isDark ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Icon(Icons.account_balance, color: colors.primary, size: 20),
              const SizedBox(width: SpacingTokens.s),
              Text(
                tr.bankTransferDetails,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          // Info alert
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularSmall,
              border: Border.all(color: colors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colors.info, size: 16),
                const SizedBox(width: SpacingTokens.s),
                Expanded(
                  child: Text(
                    tr.bankTransferInstructions,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeXS,
                      color: colors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Bank details
          if (bankDetails.bankName != null) ...[
            _buildDetailRow(context, ref, tr.bankName, bankDetails.bankName!),
            const SizedBox(height: SpacingTokens.xs),
          ],
          if (bankDetails.accountHolder != null) ...[
            _buildDetailRow(context, ref, tr.accountHolder, bankDetails.accountHolder!),
            const SizedBox(height: SpacingTokens.xs),
          ],
          if (bankDetails.iban != null) ...[
            _buildDetailRow(context, ref, 'IBAN', bankDetails.iban!, copyable: true),
            const SizedBox(height: SpacingTokens.xs),
          ],
          if (bankDetails.swift != null) ...[
            _buildDetailRow(context, ref, 'SWIFT/BIC', bankDetails.swift!, copyable: true),
            const SizedBox(height: SpacingTokens.xs),
          ],

          const SizedBox(height: SpacingTokens.s),
          Divider(color: colors.borderDefault),
          const SizedBox(height: SpacingTokens.s),

          // Payment reference and amount
          _buildDetailRow(context, ref, tr.paymentReference, bookingReference, copyable: true, highlight: true),
          const SizedBox(height: SpacingTokens.xs),
          _buildDetailRow(
            context,
            ref,
            tr.amountToPay,
            '€${amount.toStringAsFixed(2)}',
            highlight: true,
            highlightColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value, {
    bool copyable = false,
    bool highlight = false,
    Color? highlightColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: highlight ? TypographyTokens.fontSizeM : TypographyTokens.fontSizeS,
                    fontWeight: highlight ? TypographyTokens.bold : TypographyTokens.medium,
                    color: highlightColor ?? colors.textPrimary,
                    fontFamily: copyable ? 'monospace' : null,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: SpacingTokens.xs),
                InkWell(
                  onTap: () => _copyToClipboard(context, ref, value),
                  borderRadius: BorderTokens.circularSmall,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 16, color: colors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context, WidgetRef ref, String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: WidgetTranslations.of(context, ref).copiedToClipboard,
        );
      }
    } catch (e) {
      // Clipboard API can fail on some browsers (e.g., Safari in iframe)
      // Handle gracefully - user can still see the value on screen
      debugPrint('Failed to copy to clipboard: $e');
    }
  }
}
