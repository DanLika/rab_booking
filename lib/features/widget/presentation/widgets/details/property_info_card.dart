import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../common/detail_row_widget.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying property and unit information.
///
/// Shows property name and unit name in a consistent detail row format.
///
/// Usage:
/// ```dart
/// PropertyInfoCard(
///   propertyName: 'Beach Villa',
///   unitName: 'Suite 1',
///   colors: ColorTokens.light,
///   isDarkMode: false,
/// )
/// ```
class PropertyInfoCard extends ConsumerWidget {
  /// Property name
  final String propertyName;

  /// Unit name
  final String unitName;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Whether dark mode is active
  final bool isDarkMode;

  const PropertyInfoCard({
    super.key,
    required this.propertyName,
    required this.unitName,
    required this.colors,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Use backgroundTertiary in dark mode for better contrast
    final cardBackground = isDarkMode ? colors.backgroundTertiary : colors.backgroundSecondary;
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
          // Header matching BookingSummaryCard style
          Text(
            tr.propertyInformation,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          // Use DetailRowWidget for consistent styling
          DetailRowWidget(
            label: tr.property,
            value: propertyName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.unit,
            value: unitName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}
