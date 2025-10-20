import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';

/// Responsive grid that adapts column count based on screen size
///
/// Example:
/// ```dart
/// ResponsiveGrid(
///   mobileColumns: 1,
///   tabletColumns: 2,
///   desktopColumns: 3,
///   spacing: 16,
///   children: [
///     PropertyCard(),
///     PropertyCard(),
///     PropertyCard(),
///   ],
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = true,
    this.physics,
    super.key,
  });

  /// List of widgets to display in grid
  final List<Widget> children;

  /// Number of columns on mobile (< 600px)
  final int mobileColumns;

  /// Number of columns on tablet (600px - 1440px)
  final int tabletColumns;

  /// Number of columns on desktop (>= 1440px)
  final int desktopColumns;

  /// Spacing between grid items
  final double spacing;

  /// Aspect ratio of each grid item
  final double childAspectRatio;

  /// Whether the grid should shrink wrap
  final bool shrinkWrap;

  /// Scroll physics
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        // Use AppDimensions breakpoints
        if (constraints.maxWidth < AppDimensions.mobile) {
          columns = mobileColumns;
        } else if (constraints.maxWidth < AppDimensions.tablet) {
          columns = tabletColumns;
        } else {
          columns = desktopColumns;
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive wrap that adapts spacing based on screen size
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    required this.children,
    this.mobileSpacing = 8.0,
    this.tabletSpacing = 12.0,
    this.desktopSpacing = 16.0,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    super.key,
  });

  /// List of widgets to display
  final List<Widget> children;

  /// Spacing on mobile
  final double mobileSpacing;

  /// Spacing on tablet
  final double tabletSpacing;

  /// Spacing on desktop
  final double desktopSpacing;

  /// Wrap alignment
  final WrapAlignment alignment;

  /// Run alignment
  final WrapAlignment runAlignment;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double spacing;
    // Use AppDimensions breakpoints
    if (width < AppDimensions.mobile) {
      spacing = mobileSpacing;
    } else if (width < AppDimensions.tablet) {
      spacing = tabletSpacing;
    } else {
      spacing = desktopSpacing;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: alignment,
      runAlignment: runAlignment,
      children: children,
    );
  }
}
