import 'package:flutter/material.dart';
import '../../core/design/tokens.dart';

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

  // Handoff `tokens.css` semantic tints: `--bb-info(-tint)` and
  // `--bb-warning(-tint)`, dark `.theme-dark` lifts (audit/121).
  _MessageBoxColors _getColors(bool isDark) {
    final info = isDark ? BBColor.infoDarkMode : BBColor.info;
    final warning = isDark ? BBColor.warningDarkMode : BBColor.warning;

    switch (type) {
      case MessageBoxType.info:
        return _MessageBoxColors(
          background: info.withValues(alpha: isDark ? 0.18 : 0.12),
          border: info.withValues(alpha: isDark ? 0.4 : 0.3),
          iconBackground: info.withValues(alpha: isDark ? 0.2 : 0.15),
          iconColor: info,
          textColor: isDark
              ? BBColor.textPrimaryDark
              : const Color(0xFF3576BC), // info pressed/deep — AA on tint
        );
      case MessageBoxType.warning:
        return _MessageBoxColors(
          background: warning.withValues(alpha: isDark ? 0.22 : 0.16),
          border: warning.withValues(alpha: 0.4),
          iconBackground: warning.withValues(alpha: isDark ? 0.2 : 0.15),
          // AA-safe darker amber on light tint (`--bb-status-pending`)
          iconColor: isDark ? warning : BBColor.statusPending,
          textColor: isDark ? BBColor.textPrimaryDark : BBColor.statusPending,
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
