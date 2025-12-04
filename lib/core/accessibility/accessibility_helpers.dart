import 'package:flutter/material.dart';

/// Accessibility helpers for improved screen reader support
///
/// These helpers wrap common widgets with proper semantic labels
/// to improve accessibility for users with disabilities.

/// Accessible IconButton with semantic label
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double? iconSize;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final String? tooltip;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.iconSize,
    this.color,
    this.padding,
    this.constraints,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        iconSize: iconSize,
        color: color,
        padding: padding ?? const EdgeInsets.all(8.0),
        constraints: constraints,
        tooltip: tooltip ?? semanticLabel,
      ),
    );
  }
}

/// Accessible InkWell with semantic label
class AccessibleInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool isButton;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;

  const AccessibleInkWell({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.isButton = true,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isButton,
      label: semanticLabel,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: child,
      ),
    );
  }
}

/// Accessible GestureDetector with semantic label
class AccessibleGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool isButton;
  final HitTestBehavior behavior;

  const AccessibleGestureDetector({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.isButton = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isButton,
      label: semanticLabel,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: behavior,
        child: child,
      ),
    );
  }
}

/// Accessible Card with semantic label for navigation
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    required this.semanticLabel,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Card(
      margin: margin,
      color: color,
      elevation: elevation,
      shape: borderRadius != null
          ? RoundedRectangleBorder(borderRadius: borderRadius!)
          : null,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        label: semanticLabel,
        enabled: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: cardWidget,
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: cardWidget,
    );
  }
}

/// Accessible Image with semantic label for screen readers
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String semanticLabel;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Extension methods for adding semantics to existing widgets
extension AccessibilityExtensions on Widget {
  /// Add semantic label to any widget
  Widget withSemantics({
    required String label,
    bool? button,
    bool? enabled,
    bool? focusable,
    bool? header,
    bool? image,
  }) {
    return Semantics(
      label: label,
      button: button,
      enabled: enabled,
      focusable: focusable,
      header: header,
      image: image,
      child: this,
    );
  }

  /// Mark widget as excluded from semantics tree (decorative only)
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}

/// Accessibility constants
class A11yConstants {
  // Minimum tap target size (44x44 per Material Design)
  static const double minTapTargetSize = 44.0;

  // Recommended touch target sizes
  static const double touchTargetSmall = 40.0;
  static const double touchTargetMedium = 48.0;
  static const double touchTargetLarge = 56.0;

  // Semantic label prefixes for common actions
  static const String prefixButton = 'Button: ';
  static const String prefixLink = 'Link: ';
  static const String prefixImage = 'Image: ';
  static const String prefixIcon = 'Icon: ';
}

/// Helper to wrap widget with minimum tap target size
Widget withMinTapTarget({
  required Widget child,
  double size = A11yConstants.minTapTargetSize,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: size,
      minHeight: size,
    ),
    child: child,
  );
}
