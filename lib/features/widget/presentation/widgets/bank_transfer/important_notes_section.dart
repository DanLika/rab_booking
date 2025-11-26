import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';

/// Reusable important notes section for bank transfers
/// Displays either custom notes or default payment instructions
class ImportantNotesSection extends StatelessWidget {
  final bool isDarkMode;
  final BankTransferConfig? bankConfig;
  final String remainingAmount;

  const ImportantNotesSection({
    super.key,
    required this.isDarkMode,
    required this.bankConfig,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final bool useCustom = bankConfig?.useCustomNotes ?? false;
    final String? customNotes = bankConfig?.customNotes;

    final List<String> notes = [];

    if (useCustom && customNotes != null && customNotes.isNotEmpty) {
      notes.add(customNotes);
    } else {
      notes.addAll([
        'Obavezno navedite referentni broj u opisu uplate',
        'Primit ćete email potvrdu nakon što uplata bude zaprimljena',
        'Preostali iznos ($remainingAmount) plaća se po dolasku',
        'Politika otkazivanja: 7 dana prije dolaska za potpuni povrat',
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: SpacingTokens.m),
          if (useCustom && customNotes != null && customNotes.isNotEmpty)
            Text(
              customNotes,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: _getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
                height: 1.5,
              ),
            )
          else
            ...notes.map(_buildNoteItem),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          color: _getColor(
            MinimalistColors.buttonPrimary,
            MinimalistColorsDark.buttonPrimary,
          ),
          size: IconSizeTokens.medium,
        ),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          'Važne Informacije',
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: TypographyTokens.semiBold,
            color: _getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(
              top: 8,
              right: SpacingTokens.s,
            ),
            decoration: BoxDecoration(
              color: _getColor(
                MinimalistColors.buttonPrimary,
                MinimalistColorsDark.buttonPrimary,
              ),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: _getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(Color lightColor, Color darkColor) {
    return isDarkMode ? darkColor : lightColor;
  }
}
