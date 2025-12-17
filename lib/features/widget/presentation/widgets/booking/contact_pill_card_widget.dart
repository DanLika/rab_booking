import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
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
        constraints: BoxConstraints(maxWidth: _isDesktop ? _desktopMaxWidth : _mobileMaxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.m, vertical: SpacingTokens.s),
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
              ? _buildColumnLayout(hasEmail, hasPhone, colors, context)
              : _buildRowLayout(hasEmail, hasPhone, colors, context),
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

  Widget _buildColumnLayout(bool hasEmail, bool hasPhone, MinimalistColorSchemeAdapter colors, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasEmail)
          _ContactRow(
            icon: Icons.email,
            value: contactOptions!.emailAddress!,
            onTap: (ctx) => _launchUrl('mailto:${contactOptions!.emailAddress}', ctx),
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
            onTap: (ctx) => _launchUrl('tel:${contactOptions!.phoneNumber}', ctx),
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildRowLayout(bool hasEmail, bool hasPhone, MinimalistColorSchemeAdapter colors, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasEmail)
          Flexible(
            child: _ContactRow(
              icon: Icons.email,
              value: contactOptions!.emailAddress!,
              onTap: (ctx) => _launchUrl('mailto:${contactOptions!.emailAddress}', ctx),
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
              onTap: (ctx) => _launchUrl('tel:${contactOptions!.phoneNumber}', ctx),
              colors: colors,
              centerContent: true,
            ),
          ),
      ],
    );
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);

      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        // URL cannot be launched (e.g., no email/phone app installed)
        if (context.mounted) {
          SnackBarHelper.showError(
            context: context,
            message: 'Unable to open $url. Please check if you have an app installed to handle this action.',
          );
        }
        return;
      }

      // Launch URL
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on FormatException catch (e) {
      // Invalid URL format
      debugPrint('Error parsing URL: $url, error: $e');
      if (context.mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Invalid URL format. Please contact the property owner.',
        );
      }
    } catch (e) {
      // Any other error (canLaunchUrl, launchUrl, etc.)
      debugPrint('Error launching URL: $url, error: $e');
      if (context.mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Unable to open $url. Please try again or contact the property owner.',
        );
      }
    }
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final Function(BuildContext) onTap;
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
      onTap: () => onTap(context),
      borderRadius: BorderTokens.circularSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxs, vertical: SpacingTokens.xxs),
        child: Row(
          mainAxisSize: centerContent ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centerContent ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: ContactPillCardWidget._iconSize, color: colors.buttonPrimary),
            const SizedBox(width: SpacingTokens.s),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: ContactPillCardWidget._fontSize,
                  color: colors.textPrimary,
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
