import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying property owner contact information.
///
/// Shows email and phone with icons.
///
/// Usage:
/// ```dart
/// ContactOwnerCard(
///   ownerEmail: 'owner@example.com',
///   ownerPhone: '+385 91 123 4567',
///   colors: ColorTokens.light,
/// )
/// ```
class ContactOwnerCard extends ConsumerWidget {
  /// Owner email address (optional)
  final String? ownerEmail;

  /// Owner phone number (optional)
  final String? ownerPhone;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const ContactOwnerCard({
    super.key,
    this.ownerEmail,
    this.ownerPhone,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    final cardBackground = isDark
        ? colors.backgroundTertiary
        : colors.backgroundSecondary;
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
          Text(
            tr.propertyOwnerContact,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          if (ownerEmail != null)
            _buildInfoRow(tr.email, ownerEmail!, Icons.email),
          if (ownerPhone != null) ...[
            if (ownerEmail != null) const SizedBox(height: SpacingTokens.s),
            _buildInfoRow(tr.phone, ownerPhone!, Icons.phone),
          ],
        ],
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
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeXS,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
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
