import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';
import '../common/contact/contact_item_widget.dart';

/// Contact pill card widget for calendar-only mode.
///
/// Displays contact options (email, phone) in a compact pill-shaped card.
/// Automatically switches between row (desktop) and column (mobile) layout
/// based on screen width.
///
/// Extracted from BookingWidgetScreen to reduce build() method complexity.
class ContactPillCardWidget extends StatelessWidget {
  final ContactOptions? contactOptions;
  final bool isDarkMode;
  final double screenWidth;

  const ContactPillCardWidget({
    super.key,
    required this.contactOptions,
    required this.isDarkMode,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Check if there's anything to display
    final hasEmail =
        contactOptions?.showEmail == true &&
        contactOptions?.emailAddress != null &&
        contactOptions!.emailAddress!.isNotEmpty;
    final hasPhone =
        contactOptions?.showPhone == true &&
        contactOptions?.phoneNumber != null &&
        contactOptions!.phoneNumber!.isNotEmpty;

    // If no contact options to display, return empty widget
    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    // Only use column layout on very small screens (< 350px)
    final useRowLayout = screenWidth >= 350;

    // Dynamic max width: allow row layout on most screens
    final maxWidth = useRowLayout ? 500.0 : 200.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? MinimalistColorsDark.backgroundSecondary
                : MinimalistColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12), // Pill style
            border: Border.all(
              color: isDarkMode
                  ? MinimalistColorsDark.borderDefault
                  : MinimalistColors.borderDefault,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: useRowLayout
              ? _buildDesktopContactRow(hasEmail, hasPhone)
              : _buildMobileContactColumn(hasEmail, hasPhone),
        ),
      ),
    );
  }

  /// Desktop layout: email + phone in same row with divider
  Widget _buildDesktopContactRow(bool hasEmail, bool hasPhone) {
    // Defensive check: if no items, return empty widget to avoid empty Row
    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Email
        if (hasEmail)
          Flexible(
            child: ContactItemWidget(
              icon: Icons.email,
              value: contactOptions!.emailAddress!,
              onTap: () => _launchUrl('mailto:${contactOptions!.emailAddress}'),
              isDarkMode: isDarkMode,
            ),
          ),

        // Vertical divider
        if (hasEmail && hasPhone)
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: isDarkMode
                ? MinimalistColorsDark.borderDefault
                : MinimalistColors.borderDefault,
          ),

        // Phone
        if (hasPhone)
          Flexible(
            child: ContactItemWidget(
              icon: Icons.phone,
              value: contactOptions!.phoneNumber!,
              onTap: () => _launchUrl('tel:${contactOptions!.phoneNumber}'),
              isDarkMode: isDarkMode,
            ),
          ),
      ],
    );
  }

  /// Mobile layout: email and phone stacked vertically
  Widget _buildMobileContactColumn(bool hasEmail, bool hasPhone) {
    // Defensive check: if no items, return empty widget to avoid empty Column
    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Email
        if (hasEmail)
          ContactItemWidget(
            icon: Icons.email,
            value: contactOptions!.emailAddress!,
            onTap: () => _launchUrl('mailto:${contactOptions!.emailAddress}'),
            isDarkMode: isDarkMode,
          ),

        // Horizontal divider between email and phone
        if (hasEmail && hasPhone)
          Divider(
            color: isDarkMode
                ? MinimalistColorsDark.borderDefault
                : MinimalistColors.borderDefault,
            height: 12,
            thickness: 1,
          ),

        // Phone
        if (hasPhone)
          ContactItemWidget(
            icon: Icons.phone,
            value: contactOptions!.phoneNumber!,
            onTap: () => _launchUrl('tel:${contactOptions!.phoneNumber}'),
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  /// Helper to launch URLs (phone, email)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
