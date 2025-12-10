import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../../domain/models/widget_settings.dart';

/// Contact pill card widget for calendar-only mode.
///
/// Displays contact options (email, phone) in a compact pill-shaped card.
/// Responsive layout adapts to screen width.
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

  // Breakpoints
  static const _mobileBreakpoint = 600.0;
  static const _desktopBreakpoint = 1024.0;

  // Widths
  static const _desktopMaxWidth = 650.0;
  static const _mobileMaxWidth = 600.0;

  // Styling
  static const _shadowAlpha = 0.04;
  static const _dividerHeight = 24.0;
  static const _iconSize = 18.0;
  static const _fontSize = 14.0;

  bool get _useColumnLayout => screenWidth < _mobileBreakpoint;
  bool get _isDesktop => screenWidth >= _desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    final hasEmail = _hasValidEmail;
    final hasPhone = _hasValidPhone;

    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _isDesktop ? _desktopMaxWidth : _mobileMaxWidth,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.m,
            vertical: SpacingTokens.s,
          ),
          decoration: BoxDecoration(
            color: colors.backgroundTertiary,
            borderRadius: BorderTokens.circularMedium,
            border: Border.all(color: colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _shadowAlpha),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: _useColumnLayout
              ? _buildColumnLayout(hasEmail, hasPhone, colors)
              : _buildRowLayout(hasEmail, hasPhone, colors),
        ),
      ),
    );
  }

  bool get _hasValidEmail =>
      contactOptions?.showEmail == true &&
      contactOptions?.emailAddress != null &&
      contactOptions!.emailAddress!.isNotEmpty;

  bool get _hasValidPhone =>
      contactOptions?.showPhone == true &&
      contactOptions?.phoneNumber != null &&
      contactOptions!.phoneNumber!.isNotEmpty;

  Widget _buildColumnLayout(
    bool hasEmail,
    bool hasPhone,
    MinimalistColorSchemeAdapter colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasEmail)
          _ContactRow(
            icon: Icons.email,
            value: contactOptions!.emailAddress!,
            onTap: () => _launchUrl('mailto:${contactOptions!.emailAddress}'),
            colors: colors,
          ),
        if (hasEmail && hasPhone)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            color: colors.borderDefault,
          ),
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

  Widget _buildRowLayout(
    bool hasEmail,
    bool hasPhone,
    MinimalistColorSchemeAdapter colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        if (hasEmail && hasPhone)
          Container(
            height: _dividerHeight,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.m),
            color: colors.borderDefault,
          ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

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
      borderRadius: BorderTokens.circularSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.xxs,
          vertical: SpacingTokens.xxs,
        ),
        child: Row(
          mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centerContent
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: ContactPillCardWidget._iconSize,
              color: colors.buttonPrimary,
            ),
            const SizedBox(width: SpacingTokens.s),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: ContactPillCardWidget._fontSize,
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
