import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';

/// Contact pill card widget for calendar-only mode.
///
/// Displays contact options (email, phone) in a compact pill-shaped card.
///
/// Responsive layout:
/// - Mobile (< 600px): Column layout with email on top, phone below (~80px height)
/// - Tablet/Desktop (≥ 600px): Row layout with email and phone side by side (~48px height)
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

  /// Returns true if using column layout (mobile)
  bool get _useColumnLayout => screenWidth < 600;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

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

    final isDesktop = screenWidth >= 1024;

    // Match calendar width: 650px desktop, 600px mobile/tablet (same as CalendarCompactLegend)
    final maxWidth = isDesktop ? 650.0 : 600.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: _useColumnLayout
              ? _buildColumnLayout(hasEmail, hasPhone, colors)
              : _buildRowLayout(hasEmail, hasPhone, colors),
        ),
      ),
    );
  }

  /// Column layout for mobile (< 600px)
  /// Email on top, phone below with horizontal divider between
  Widget _buildColumnLayout(
    bool hasEmail,
    bool hasPhone,
    MinimalistColorSchemeAdapter colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email row
        if (hasEmail)
          _ContactRow(
            icon: Icons.email,
            value: contactOptions!.emailAddress!,
            onTap: () => _launchUrl('mailto:${contactOptions!.emailAddress}'),
            colors: colors,
          ),

        // Horizontal divider (only if both email and phone are shown)
        if (hasEmail && hasPhone)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: colors.borderDefault,
          ),

        // Phone row
        if (hasPhone)
          _ContactRow(
            icon: Icons.phone,
            value: contactOptions!.phoneNumber!,
            onTap: () => _launchUrl('tel:${contactOptions!.phoneNumber}'),
            colors: colors,
          ),
      ],
    );
  }

  /// Row layout for tablet/desktop (≥ 600px)
  /// Email and phone side by side with vertical divider between
  Widget _buildRowLayout(
    bool hasEmail,
    bool hasPhone,
    MinimalistColorSchemeAdapter colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Email
        if (hasEmail)
          Flexible(
            child: _ContactRow(
              icon: Icons.email,
              value: contactOptions!.emailAddress!,
              onTap: () => _launchUrl('mailto:${contactOptions!.emailAddress}'),
              colors: colors,
              centerContent: true,
            ),
          ),

        // Vertical divider (only if both email and phone are shown)
        if (hasEmail && hasPhone)
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: colors.borderDefault,
          ),

        // Phone
        if (hasPhone)
          Flexible(
            child: _ContactRow(
              icon: Icons.phone,
              value: contactOptions!.phoneNumber!,
              onTap: () => _launchUrl('tel:${contactOptions!.phoneNumber}'),
              colors: colors,
              centerContent: true,
            ),
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

/// Internal widget for a single contact row (email or phone)
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final MinimalistColorSchemeAdapter colors;
  final bool centerContent;

  const _ContactRow({
    required this.icon,
    required this.value,
    required this.onTap,
    required this.colors,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centerContent ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: colors.buttonPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
