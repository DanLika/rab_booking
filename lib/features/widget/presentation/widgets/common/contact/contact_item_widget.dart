import 'package:flutter/material.dart';
import '../../../theme/minimalist_colors.dart';

/// A tappable contact item displaying an icon and value.
///
/// Used for contact information like email and phone number
/// in the booking widget header section.
///
/// Usage:
/// ```dart
/// ContactItemWidget(
///   icon: Icons.email,
///   value: 'contact@example.com',
///   onTap: () => _launchEmail('contact@example.com'),
///   isDarkMode: isDarkMode,
/// )
/// ```
class ContactItemWidget extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Contact value (email, phone, etc.)
  final String value;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Whether dark mode is active
  final bool isDarkMode;

  const ContactItemWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode
                  ? MinimalistColorsDark.buttonPrimary
                  : MinimalistColors.buttonPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? MinimalistColorsDark.textPrimary
                      : MinimalistColors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
