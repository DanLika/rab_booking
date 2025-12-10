import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';

/// An informational card widget for displaying messages with an icon.
///
/// Used throughout the booking flow to show contextual information,
/// warnings, or status messages to the user.
///
/// Usage:
/// ```dart
/// // Simple info message
/// InfoCardWidget(
///   message: 'Your booking will be pending until confirmed',
///   isDarkMode: isDarkMode,
/// )
///
/// // With title and custom icon
/// InfoCardWidget(
///   title: 'Payment Verification',
///   message: 'We are verifying your payment...',
///   icon: Icons.payment,
///   isDarkMode: isDarkMode,
/// )
/// ```
class InfoCardWidget extends StatelessWidget {
  /// The main message text to display
  final String message;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Optional title displayed above the message in bold
  final String? title;

  /// Icon to display (defaults to info_outline)
  final IconData icon;

  /// Icon size (defaults to 16 for simple, 24 for title variant)
  final double? iconSize;

  /// Whether to center content vertically (for single-line banners)
  final bool centerContent;

  /// Whether to use minimal width (for centered banners)
  /// When true, Row uses mainAxisSize.min and text is centered
  final bool useMinimalWidth;

  const InfoCardWidget({
    super.key,
    required this.message,
    required this.isDarkMode,
    this.title,
    this.icon = Icons.info_outline,
    this.iconSize,
    this.centerContent = false,
    this.useMinimalWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final hasTitle = title != null && title!.isNotEmpty;
    final effectiveIconSize = iconSize ?? (hasTitle ? 24.0 : 16.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: hasTitle ? SpacingTokens.m : SpacingTokens.s,
        vertical: hasTitle ? SpacingTokens.m : SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        mainAxisSize: useMinimalWidth ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: centerContent ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: (hasTitle || centerContent) ? 0 : 1),
            child: Icon(icon, color: colors.textSecondary, size: effectiveIconSize),
          ),
          SizedBox(width: hasTitle ? SpacingTokens.s : 6),
          // Flexible allows text to wrap to multiple lines when constrained
          if (useMinimalWidth)
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
              ),
            )
          else
            Expanded(
              child: hasTitle
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeM,
                            fontWeight: TypographyTokens.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          message,
                          style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                        ),
                      ],
                    )
                  : Text(
                      message,
                      style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                    ),
            ),
        ],
      ),
    );
  }
}
