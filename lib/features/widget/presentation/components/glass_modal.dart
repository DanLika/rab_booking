import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/design_tokens/glassmorphism_tokens.dart';

/// Glass Dialog - Modal dialog with glassmorphism effect
///
/// Features:
/// - Frosted glass background
/// - Blurred backdrop
/// - Semi-transparent surface
/// - Customizable blur intensity
/// - Works in both light and dark mode
///
/// Usage:
/// ```dart
/// showGlassDialog(
///   context: context,
///   builder: (context) => AlertDialog(
///     title: Text('Title'),
///     content: Text('Content'),
///   ),
/// );
/// ```
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  GlassPreset? preset,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool enabled = true,
}) {
  if (!enabled) {
    // Show normal dialog without glass effect
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
    );
  }

  final effectivePreset = preset ?? GlassmorphismTokens.presetStrong;

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.3),
    barrierLabel: barrierLabel,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectivePreset.blur * 0.5, // Slightly less blur for backdrop
          sigmaY: effectivePreset.blur * 0.5,
          tileMode: TileMode.clamp,
        ),
        child: builder(context),
      );
    },
  );
}

/// Glass Bottom Sheet - Bottom sheet with glassmorphism effect
///
/// Usage:
/// ```dart
/// showGlassModalBottomSheet(
///   context: context,
///   builder: (context) => Container(
///     child: Text('Content'),
///   ),
/// );
/// ```
Future<T?> showGlassModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  GlassPreset? preset,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  Color? barrierColor,
  bool enabled = true,
}) {
  if (!enabled) {
    // Show normal bottom sheet without glass effect
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      barrierColor: barrierColor,
    );
  }

  final effectivePreset = preset ?? GlassmorphismTokens.presetMedium;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.3),
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectivePreset.blur * 0.3,
          sigmaY: effectivePreset.blur * 0.3,
          tileMode: TileMode.clamp,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: effectivePreset.blur,
              sigmaY: effectivePreset.blur,
              tileMode: TileMode.clamp,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: effectivePreset.opacity,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: effectivePreset.borderOpacity,
                    ),
                  ),
                ),
              ),
              child: builder(context),
            ),
          ),
        ),
      );
    },
  );
}

/// Glass Modal Barrier - Blurred overlay for custom modals
///
/// Use this to create custom modal layouts with glassmorphism
///
/// Usage:
/// ```dart
/// GlassModalBarrier(
///   onDismiss: () => Navigator.pop(context),
///   child: Center(
///     child: GlassCard(
///       child: Text('Modal Content'),
///     ),
///   ),
/// )
/// ```
class GlassModalBarrier extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismiss;
  final GlassPreset? preset;
  final Color? barrierColor;
  final bool dismissible;
  final bool enabled;

  const GlassModalBarrier({
    super.key,
    required this.child,
    this.onDismiss,
    this.preset,
    this.barrierColor,
    this.dismissible = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePreset = preset ?? GlassmorphismTokens.presetMedium;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: dismissible ? onDismiss : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: barrierColor ?? Colors.black.withValues(alpha: 0.3),
          child: enabled
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: effectivePreset.blur * 0.4,
                    sigmaY: effectivePreset.blur * 0.4,
                    tileMode: TileMode.clamp,
                  ),
                  child: GestureDetector(
                    onTap: () {}, // Prevent dismissing when tapping content
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

/// Glass Alert Dialog - Pre-styled alert dialog with glassmorphism
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => GlassAlertDialog(
///     title: 'Confirm',
///     content: 'Are you sure?',
///     actions: [
///       TextButton(onPressed: () {}, child: Text('Cancel')),
///       TextButton(onPressed: () {}, child: Text('OK')),
///     ],
///   ),
/// );
/// ```
class GlassAlertDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final Widget? titleWidget;
  final Widget? contentWidget;
  final List<Widget>? actions;
  final GlassPreset? preset;
  final bool enabled;

  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.titleWidget,
    this.contentWidget,
    this.actions,
    this.preset,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectivePreset = preset ?? GlassmorphismTokens.presetMedium;

    if (!enabled) {
      return AlertDialog(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        content: contentWidget ?? (content != null ? Text(content!) : null),
        actions: actions,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectivePreset.blur,
            sigmaY: effectivePreset.blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.white).withValues(
                alpha: effectivePreset.opacity + 0.7,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: effectivePreset.borderOpacity,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titleWidget != null || title != null) ...[
                  DefaultTextStyle(
                    style: theme.textTheme.titleLarge ?? const TextStyle(),
                    child: titleWidget ?? Text(title!),
                  ),
                  const SizedBox(height: 16),
                ],
                if (contentWidget != null || content != null) ...[
                  DefaultTextStyle(
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    child: contentWidget ?? Text(content!),
                  ),
                  const SizedBox(height: 24),
                ],
                if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass Snackbar - Snackbar with glassmorphism effect
///
/// Usage:
/// ```dart
/// showGlassSnackbar(
///   context: context,
///   message: 'Action completed!',
/// );
/// ```
void showGlassSnackbar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
  GlassPreset? preset,
  SnackBarAction? action,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final effectivePreset = preset ?? GlassmorphismTokens.presetLight;

  if (!enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      // Wrap content with glass effect
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectivePreset.blur,
            sigmaY: effectivePreset.blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: effectivePreset.opacity + 0.6,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: effectivePreset.borderOpacity,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
