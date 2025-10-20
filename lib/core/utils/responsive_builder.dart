import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

/// Responsive builder for creating adaptive layouts
/// Provides declarative API for building responsive UIs
class ResponsiveBuilder extends StatelessWidget {
  /// Widget to display on mobile devices
  final Widget Function(BuildContext context, BoxConstraints constraints)? mobile;

  /// Widget to display on tablet devices
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;

  /// Widget to display on desktop devices
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktop;

  /// Widget to display on large desktop devices
  final Widget Function(BuildContext context, BoxConstraints constraints)? largeDesktop;

  /// Default widget if specific breakpoint not provided
  final Widget Function(BuildContext context, BoxConstraints constraints)? defaultWidget;

  const ResponsiveBuilder({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    this.defaultWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Large desktop (>= 1440px)
        if (width >= AppDimensions.desktop) {
          return (largeDesktop ?? desktop ?? tablet ?? mobile ?? defaultWidget)
                  ?.call(context, constraints) ??
              const SizedBox.shrink();
        }

        // Desktop (>= 1024px)
        if (width >= AppDimensions.tablet) {
          return (desktop ?? tablet ?? mobile ?? defaultWidget)
                  ?.call(context, constraints) ??
              const SizedBox.shrink();
        }

        // Tablet (>= 600px)
        if (width >= AppDimensions.mobile) {
          return (tablet ?? mobile ?? defaultWidget)?.call(context, constraints) ??
              const SizedBox.shrink();
        }

        // Mobile (< 600px)
        return (mobile ?? defaultWidget)?.call(context, constraints) ??
            const SizedBox.shrink();
      },
    );
  }
}

/// Responsive value builder that returns different values based on breakpoint
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  /// Get value for current screen width
  T getValue(double width) {
    if (width >= AppDimensions.desktop) {
      return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
    if (width >= AppDimensions.tablet) {
      return desktop ?? tablet ?? mobile;
    }
    if (width >= AppDimensions.mobile) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Get value from context
  T fromContext(BuildContext context) {
    return getValue(MediaQuery.of(context).size.width);
  }

  /// Get value from constraints
  T fromConstraints(BoxConstraints constraints) {
    return getValue(constraints.maxWidth);
  }
}

/// Orientation-based builder
class OrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context)? portrait;
  final Widget Function(BuildContext context)? landscape;
  final Widget Function(BuildContext context)? defaultWidget;

  const OrientationBuilder({
    super.key,
    this.portrait,
    this.landscape,
    this.defaultWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        if (isLandscape) {
          return (landscape ?? defaultWidget)?.call(context) ?? const SizedBox.shrink();
        } else {
          return (portrait ?? defaultWidget)?.call(context) ?? const SizedBox.shrink();
        }
      },
    );
  }
}

/// Screen type enum
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Get current screen type from width
ScreenType getScreenType(double width) {
  if (width >= AppDimensions.desktop) {
    return ScreenType.largeDesktop;
  }
  if (width >= AppDimensions.tablet) {
    return ScreenType.desktop;
  }
  if (width >= AppDimensions.mobile) {
    return ScreenType.tablet;
  }
  return ScreenType.mobile;
}

/// Get current screen type from context
ScreenType getScreenTypeFromContext(BuildContext context) {
  return getScreenType(MediaQuery.of(context).size.width);
}

/// Responsive grid builder
class ResponsiveGrid extends StatelessWidget {
  /// Items to display in grid
  final List<Widget> children;

  /// Responsive column count
  final ResponsiveValue<int> columns;

  /// Spacing between items
  final double? spacing;

  /// Run spacing (vertical)
  final double? runSpacing;

  /// Child aspect ratio
  final double? childAspectRatio;

  /// Padding around grid
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.columns,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
    this.padding,
  });

  /// Constructor with default property listing grid columns
  factory ResponsiveGrid.properties({
    required List<Widget> children,
    double? spacing,
    double? runSpacing,
    double? childAspectRatio,
    EdgeInsets? padding,
  }) {
    return ResponsiveGrid(
      columns: const ResponsiveValue(
        mobile: 1,
        tablet: 2,
        desktop: 3,
        largeDesktop: 4,
      ),
      spacing: spacing ?? AppDimensions.spaceM,
      runSpacing: runSpacing ?? AppDimensions.spaceM,
      childAspectRatio: childAspectRatio ?? 0.75,
      padding: padding,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = columns.fromConstraints(constraints);
        final effectiveSpacing = spacing ?? AppDimensions.spaceM;
        final effectiveRunSpacing = runSpacing ?? AppDimensions.spaceM;

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: effectiveRunSpacing,
            crossAxisSpacing: effectiveSpacing,
            childAspectRatio: childAspectRatio ?? 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive wrap builder
class ResponsiveWrap extends StatelessWidget {
  /// Items to display
  final List<Widget> children;

  /// Spacing between items
  final double? spacing;

  /// Run spacing (vertical)
  final double? runSpacing;

  /// Alignment
  final WrapAlignment alignment;

  /// Run alignment
  final WrapAlignment runAlignment;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = getScreenType(constraints.maxWidth);

        // Responsive spacing based on screen size
        double effectiveSpacing;
        double effectiveRunSpacing;

        switch (screenType) {
          case ScreenType.mobile:
            effectiveSpacing = spacing ?? AppDimensions.spaceS;
            effectiveRunSpacing = runSpacing ?? AppDimensions.spaceS;
            break;
          case ScreenType.tablet:
            effectiveSpacing = spacing ?? AppDimensions.spaceM;
            effectiveRunSpacing = runSpacing ?? AppDimensions.spaceM;
            break;
          case ScreenType.desktop:
          case ScreenType.largeDesktop:
            effectiveSpacing = spacing ?? AppDimensions.spaceL;
            effectiveRunSpacing = runSpacing ?? AppDimensions.spaceL;
            break;
        }

        return Wrap(
          spacing: effectiveSpacing,
          runSpacing: effectiveRunSpacing,
          alignment: alignment,
          runAlignment: runAlignment,
          children: children,
        );
      },
    );
  }
}

/// Max width container that constrains width on large screens
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerOnDesktop;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerOnDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = maxWidth ?? AppDimensions.containerXL;

        if (constraints.maxWidth > effectiveMaxWidth && centerOnDesktop) {
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
              padding: padding,
              child: child,
            ),
          );
        }

        return Container(
          padding: padding,
          child: child,
        );
      },
    );
  }
}
