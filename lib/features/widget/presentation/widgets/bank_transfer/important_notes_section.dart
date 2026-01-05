import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';
import '../../l10n/widget_translations.dart';

/// Reusable important notes section for bank transfers
/// Displays either custom notes or default payment instructions
class ImportantNotesSection extends StatelessWidget {
  final bool isDarkMode;
  final BankTransferConfig? bankConfig;
  final String remainingAmount;
  final WidgetTranslations translations;

  const ImportantNotesSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
    required this.remainingAmount,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final bool useCustom = bankConfig?.useCustomNotes ?? false;
    final String? customNotes = bankConfig?.customNotes;

    final List<String> notes = [];

    if (useCustom && customNotes != null && customNotes.isNotEmpty) {
      notes.add(customNotes);
    } else {
      notes.addAll([
        translations.includeReferenceInPayment,
        translations.emailConfirmationAfterPayment,
        translations.remainingAmountOnArrival(remainingAmount),
        translations.cancellationPolicy7Days,
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.m),
          if (useCustom && customNotes != null && customNotes.isNotEmpty)
            Text(
              customNotes,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textPrimary,
                height: 1.5,
              ),
            )
          else
            ...notes.map((note) => _buildNoteItem(note, colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(MinimalistColorSchemeAdapter colors) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          color: colors.buttonPrimary,
          size: IconSizeTokens.medium,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          translations.importantInformation,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.semiBold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(String note, MinimalistColorSchemeAdapter colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.buttonPrimary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
