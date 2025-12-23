import 'package:flutter/material.dart';
import '../../core/design_tokens/color_tokens.dart';

/// Standardized message box types for consistent UI across the app
enum MessageBoxType {
  /// Blue info box - for informational messages, tips, explanations
  info,

  /// Amber/yellow warning box - for warnings, important notices
  warning,
}

/// A standardized message box widget for displaying info or warning messages
///
/// Usage:
/// ```dart
/// MessageBox.info(
///   message: 'Email will be sent from your registered email address',
///   icon: Icons.info_outline,
/// )
///
/// MessageBox.warning(
///   message: 'Email will contain a link to view/edit the booking',
///   icon: Icons.warning_amber_outlined,
/// )
/// ```
class MessageBox extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final MessageBoxType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const MessageBox({
    super.key,
    required this.message,
    this.title,
    required this.icon,
    required this.type,
    this.padding,
    this.margin,
  });

  /// Creates an info message box (blue)
  ///
  /// Use for: informational messages, tips, helpful explanations
  factory MessageBox.info({
    Key? key,
    required String message,
    String? title,
    IconData icon = Icons.info_outline,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return MessageBox(
      key: key,
      message: message,
      title: title,
      icon: icon,
      type: MessageBoxType.info,
      padding: padding,
      margin: margin,
    );
  }

  /// Creates a warning message box (amber/yellow)
  ///
  /// Use for: warnings, important notices, things user should be aware of
  factory MessageBox.warning({
    Key? key,
    required String message,
    String? title,
    IconData icon = Icons.warning_amber_outlined,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return MessageBox(
      key: key,
      message: message,
      title: title,
      icon: icon,
      type: MessageBoxType.warning,
      padding: padding,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get colors based on type and theme
    final colors = _getColors(isDark);

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: title != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: colors.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: title != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withAlpha(
                            (0.85 * 255).toInt(),
                          ),
                          height: 1.4,
                        ),
                      ),
                    ],
                  )
                : Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textColor,
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  _MessageBoxColors _getColors(bool isDark) {
    // Info colors matching SnackBarColors: light #3B82F6, dark #60A5FA
    const infoLight = Color(0xFF3B82F6); // Blue 500
    const infoDark = Color(0xFF60A5FA); // Blue 400
    const infoBackgroundLight = Color(0xFFDBEAFE); // Blue 100
    const infoBackgroundDark = Color(0xFF1E3A5F); // Dark blue

    // Warning colors matching SnackBarColors: light #F59E0B, dark #FBBF24
    const warningLight = Color(0xFFF59E0B); // Amber 500
    const warningDark = Color(0xFFFBBF24); // Amber 400

    switch (type) {
      case MessageBoxType.info:
        return _MessageBoxColors(
          // Blue colors (consistent with snackbars)
          background: isDark
              ? infoBackgroundDark.withAlpha((0.5 * 255).toInt())
              : infoBackgroundLight,
          border: isDark
              ? infoDark.withAlpha((0.4 * 255).toInt())
              : infoLight.withAlpha((0.3 * 255).toInt()),
          iconBackground: isDark
              ? infoDark.withAlpha((0.2 * 255).toInt())
              : infoLight.withAlpha((0.15 * 255).toInt()),
          iconColor: isDark ? infoDark : infoLight,
          textColor: isDark
              ? ColorTokens.slate100
              : const Color(0xFF1E3A8A), // Blue 900
        );
      case MessageBoxType.warning:
        return _MessageBoxColors(
          // Amber/yellow colors (consistent with snackbars)
          background: isDark
              ? ColorTokens.amber900.withAlpha((0.4 * 255).toInt())
              : const Color(0xFFFEF3C7), // amber-100
          border: isDark
              ? warningDark.withAlpha((0.4 * 255).toInt())
              : warningLight.withAlpha((0.4 * 255).toInt()),
          iconBackground: isDark
              ? warningDark.withAlpha((0.2 * 255).toInt())
              : warningLight.withAlpha((0.15 * 255).toInt()),
          iconColor: isDark ? warningDark : ColorTokens.amber600,
          textColor: isDark ? ColorTokens.slate100 : ColorTokens.amber900,
        );
    }
  }
}

/// Internal color configuration for message box
class _MessageBoxColors {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color textColor;

  const _MessageBoxColors({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.textColor,
  });
}
