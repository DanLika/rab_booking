import 'package:flutter/material.dart';

import '../../../../core/utils/password_validator.dart';
import '../../../../l10n/app_localizations.dart';

/// A widget that displays the strength of a password.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.l10n,
  });

  final String password;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final result = PasswordValidator.validate(password, l10n);
    final strength = result.strength;
    final missing = result.missingRequirements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStrengthBar(context, PasswordStrength.weak, strength),
            const SizedBox(width: 4),
            _buildStrengthBar(context, PasswordStrength.medium, strength),
            const SizedBox(width: 4),
            _buildStrengthBar(context, PasswordStrength.strong, strength),
          ],
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...missing.map((req) => _buildRequirement(context, req)),
        ],
      ],
    );
  }

  Widget _buildStrengthBar(
    BuildContext context,
    PasswordStrength barStrength,
    PasswordStrength currentStrength,
  ) {
    final theme = Theme.of(context);
    Color color;
    bool isActive = currentStrength.index >= barStrength.index;

    if (!isActive) {
      color = theme.colorScheme.surfaceVariant;
    } else {
      switch (currentStrength) {
        case PasswordStrength.weak:
          color = Colors.red;
          break;
        case PasswordStrength.medium:
          color = Colors.orange;
          break;
        case PasswordStrength.strong:
          color = Colors.green;
          break;
      }
    }

    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildRequirement(BuildContext context, String requirement) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
