import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../common/detail_row_widget.dart';

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
class PropertyInfoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: colors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching BookingSummaryCard style
          Text(
            'Property Information',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          // Use DetailRowWidget for consistent styling
          DetailRowWidget(
            label: 'Property',
            value: propertyName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Unit',
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
