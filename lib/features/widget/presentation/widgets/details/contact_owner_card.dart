import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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
class ContactOwnerCard extends StatelessWidget {
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
          Text(
            'Property Owner Contact',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          if (ownerEmail != null)
            _buildInfoRow('Email', ownerEmail!, Icons.email),
          if (ownerPhone != null) ...[
            if (ownerEmail != null) const SizedBox(height: SpacingTokens.s),
            _buildInfoRow('Phone', ownerPhone!, Icons.phone),
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
