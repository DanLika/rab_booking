import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../common/detail_row_widget.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying guest information (name, email, phone)
/// Matches design of PropertyInfoCard and BookingDatesCard
class GuestInfoCard extends ConsumerWidget {
  /// Guest name
  final String guestName;

  /// Guest email
  final String guestEmail;

  /// Guest phone (optional)
  final String? guestPhone;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Whether dark mode is active
  final bool isDarkMode;

  const GuestInfoCard({
    super.key,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    required this.colors,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Dark mode: pure black background matching parent, with visible border
    final cardBackground = isDarkMode
        ? ColorTokens.pureBlack
        : colors.backgroundSecondary;
    final cardBorder = isDarkMode ? colors.borderMedium : colors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: cardBorder, width: isDarkMode ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching other cards
          Text(
            tr.guestInformation,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          // Use DetailRowWidget for consistent styling
          DetailRowWidget(
            label: tr.guest,
            value: guestName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.email,
            value: guestEmail,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
            stacked: true, // Email can be long, show below label
          ),
          if (guestPhone != null && guestPhone!.isNotEmpty)
            DetailRowWidget(
              label: tr.phone,
              value: guestPhone!,
              isDarkMode: isDarkMode,
              hasPadding: true,
              valueFontWeight: FontWeight.w400,
            ),
        ],
      ),
    );
  }
}
