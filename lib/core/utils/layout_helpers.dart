/// Layout helper utilities for responsive design
///
/// Provides helper widgets and utilities for building responsive layouts
library;

import 'package:flutter/widgets.dart';
import '../constants/breakpoints.dart';

/// Responsive padding widget
///
/// Example:
/// ```dart
/// ResponsivePadding(
///   mobile: EdgeInsets.all(16),
///   tablet: EdgeInsets.all(24),
///   desktop: EdgeInsets.all(32),
///   child: YourWidget(),
/// )
/// ```
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    required this.mobile,
    this.tablet,
    required this.desktop,
    required this.child,
    super.key,
  });

  final EdgeInsets mobile;
  final EdgeInsets? tablet;
  final EdgeInsets desktop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Breakpoints.getValue(
        context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
      child: child,
    );
  }
}

/// Responsive sized box for spacing
///
/// Example:
/// ```dart
/// ResponsiveSpacing(
///   mobile: 16,
///   tablet: 24,
///   desktop: 32,
/// )
/// ```
class ResponsiveSpacing extends StatelessWidget {
  const ResponsiveSpacing({
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.vertical = false,
    super.key,
  });

  final double mobile;
  final double? tablet;
  final double desktop;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final spacing = Breakpoints.getValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );

    return SizedBox(
      width: vertical ? null : spacing,
      height: vertical ? spacing : null,
    );
  }
}

/// Responsive container with max width constraint
///
/// Useful for constraining content width on large screens
///
/// Example:
/// ```dart
/// ResponsiveContainer(
///   maxWidth: 1200,
///   child: YourContent(),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Responsive columns layout
///
/// Automatically adjusts number of columns based on screen size
///
/// Example:
/// ```dart
/// ResponsiveColumns(
///   mobileColumns: 1,
///   tabletColumns: 2,
///   desktopColumns: 3,
///   spacing: 16,
///   children: [
///     Card1(),
///     Card2(),
///     Card3(),
///   ],
/// )
/// ```
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
    super.key,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final columns = Breakpoints.getValue(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

/// Conditional widget based on screen size
///
/// Shows/hides widgets based on breakpoints
///
/// Example:
/// ```dart
/// ConditionalWidget(
///   showOnMobile: true,
///   showOnTablet: false,
///   showOnDesktop: false,
///   child: MobileOnlyWidget(),
/// )
/// ```
class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget({
    required this.child,
    this.showOnMobile = true,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.placeholder,
    super.key,
  });

  final Widget child;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final shouldShow = Breakpoints.getValue(
      context,
      mobile: showOnMobile,
      tablet: showOnTablet,
      desktop: showOnDesktop,
    );

    if (!shouldShow) {
      return placeholder ?? const SizedBox.shrink();
    }

    return child;
  }
}

/// Mobile-only widget
///
/// Shorthand for ConditionalWidget that only shows on mobile
class MobileOnly extends StatelessWidget {
  const MobileOnly({required this.child, this.placeholder, super.key});

  final Widget child;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
      showOnTablet: false,
      showOnDesktop: false,
      placeholder: placeholder,
      child: child,
    );
  }
}

/// Desktop-only widget
///
/// Shorthand for ConditionalWidget that only shows on desktop
class DesktopOnly extends StatelessWidget {
  const DesktopOnly({required this.child, this.placeholder, super.key});

  final Widget child;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
      showOnMobile: false,
      showOnTablet: false,
      placeholder: placeholder,
      child: child,
    );
  }
}

/// Responsive row/column switcher
///
/// Displays children in a Row on desktop/tablet, Column on mobile
///
/// Example:
/// ```dart
/// ResponsiveRowColumn(
///   spacing: 16,
///   children: [
///     Widget1(),
///     Widget2(),
///     Widget3(),
///   ],
/// )
/// ```
class ResponsiveRowColumn extends StatelessWidget {
  const ResponsiveRowColumn({
    required this.children,
    this.spacing = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.breakpoint = 600,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isColumn = width < breakpoint;

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1 && spacing > 0) {
        spacedChildren.add(
          SizedBox(
            width: isColumn ? 0 : spacing,
            height: isColumn ? spacing : 0,
          ),
        );
      }
    }

    if (isColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: spacedChildren,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: spacedChildren,
      );
    }
  }
}
