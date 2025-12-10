import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../../theme/minimalist_colors.dart';

/// A tappable contact item displaying an icon and value.
///
/// Used for contact information like email and phone number
/// in the booking widget header section.
///
/// Uses AutoSizeText to scale down long values (emails, phones) to fit
/// within the available space without overflowing.
///
/// When multiple ContactItemWidgets share the same [autoSizeGroup], they will
/// all scale to the same font size (the smallest needed by any item in the group).
/// This ensures visual consistency between email and phone in ContactPillCardWidget.
///
/// Usage:
/// ```dart
/// final group = AutoSizeGroup();
/// ContactItemWidget(
///   icon: Icons.email,
///   value: 'contact@example.com',
///   onTap: () => _launchEmail('contact@example.com'),
///   isDarkMode: isDarkMode,
///   autoSizeGroup: group, // Share with phone widget
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

  /// Optional AutoSizeGroup for synchronized font scaling across multiple items.
  /// When provided, all widgets sharing this group will use the same font size.
  final AutoSizeGroup? autoSizeGroup;

  const ContactItemWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
    required this.isDarkMode,
    this.autoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // CRITICAL: Prevent unbounded expansion
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: colors.buttonPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AutoSizeText(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
                minFontSize: 10, // Minimum readable size
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                group: autoSizeGroup, // Sync font size with other items in group
              ),
            ),
          ],
        ),
      ),
    );
  }
}
