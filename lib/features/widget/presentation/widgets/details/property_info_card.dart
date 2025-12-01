import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Card displaying property and unit information.
///
/// Shows property name and unit name with icons.
///
/// Usage:
/// ```dart
/// PropertyInfoCard(
///   propertyName: 'Beach Villa',
///   unitName: 'Suite 1',
///   colors: ColorTokens.light,
/// )
/// ```
class PropertyInfoCard extends StatelessWidget {
  /// Property name
  final String propertyName;

  /// Unit name
  final String unitName;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const PropertyInfoCard({
    super.key,
    required this.propertyName,
    required this.unitName,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderTokens.circularLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Property',
              propertyName,
              Icons.apartment,
            ),
            const SizedBox(height: SpacingTokens.s),
            _buildInfoRow(
              'Unit',
              unitName,
              Icons.home,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: SpacingTokens.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeXS,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeM,
                  fontWeight: TypographyTokens.medium,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
