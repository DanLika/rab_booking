import 'package:flutter/material.dart';
import '../../core/utils/responsive_builder.dart';
import '../../core/constants/app_dimensions.dart';

/// Adaptive row/column layout
/// Displays children in a row on desktop, column on mobile
class AdaptiveLayout extends StatelessWidget {
  /// Children widgets
  final List<Widget> children;

  /// Spacing between children
  final double? spacing;

  /// Main axis alignment
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment
  final CrossAxisAlignment crossAxisAlignment;

  /// Breakpoint width to switch from row to column
  final double? breakpoint;

  /// Reverse order on mobile
  final bool reverseOnMobile;

  const AdaptiveLayout({
    super.key,
    required this.children,
    this.spacing,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.breakpoint,
    this.reverseOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveBreakpoint = breakpoint ?? AppDimensions.tablet;
        final isRow = constraints.maxWidth >= effectiveBreakpoint;
        final effectiveSpacing = spacing ?? AppDimensions.spaceM;

        // Add spacing between children
        final spacedChildren = <Widget>[];
        for (int i = 0; i < children.length; i++) {
          spacedChildren.add(children[i]);
          if (i < children.length - 1) {
            spacedChildren.add(SizedBox(
              width: isRow ? effectiveSpacing : 0,
              height: isRow ? 0 : effectiveSpacing,
            ));
          }
        }

        // Reverse if needed on mobile
        final finalChildren = (!isRow && reverseOnMobile)
            ? spacedChildren.reversed.toList()
            : spacedChildren;

        if (isRow) {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: finalChildren,
          );
        }

        return Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: finalChildren,
        );
      },
    );
  }
}

/// Adaptive sidebar layout
/// Shows sidebar on desktop, drawer on mobile
class AdaptiveSidebarLayout extends StatelessWidget {
  /// Main content
  final Widget content;

  /// Sidebar widget (shown on desktop)
  final Widget sidebar;

  /// Sidebar width on desktop
  final double sidebarWidth;

  /// Drawer widget (shown on mobile, defaults to sidebar)
  final Widget? drawer;

  /// AppBar widget
  final PreferredSizeWidget? appBar;

  /// Bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Background color
  final Color? backgroundColor;

  /// Sidebar position (left or right)
  final SidebarPosition sidebarPosition;

  const AdaptiveSidebarLayout({
    super.key,
    required this.content,
    required this.sidebar,
    this.sidebarWidth = 280,
    this.drawer,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.sidebarPosition = SidebarPosition.left,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= AppDimensions.tablet;

        if (showSidebar) {
          // Desktop layout with sidebar
          return Scaffold(
            appBar: appBar,
            backgroundColor: backgroundColor,
            body: Row(
              children: [
                if (sidebarPosition == SidebarPosition.left)
                  SizedBox(
                    width: sidebarWidth,
                    child: sidebar,
                  ),
                Expanded(child: content),
                if (sidebarPosition == SidebarPosition.right)
                  SizedBox(
                    width: sidebarWidth,
                    child: sidebar,
                  ),
              ],
            ),
          );
        }

        // Mobile layout with drawer
        return Scaffold(
          appBar: appBar,
          backgroundColor: backgroundColor,
          drawer: drawer ?? SizedBox(width: sidebarWidth, child: sidebar),
          body: content,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}

/// Sidebar position enum
enum SidebarPosition {
  left,
  right,
}

/// Adaptive grid/list layout
/// Shows grid on desktop, list on mobile
class AdaptiveGridList extends StatelessWidget {
  /// Items to display
  final List<Widget> children;

  /// Grid columns on desktop
  final int gridColumns;

  /// Spacing
  final double? spacing;

  /// Child aspect ratio for grid
  final double? childAspectRatio;

  /// Padding
  final EdgeInsets? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Shrink wrap
  final bool shrinkWrap;

  const AdaptiveGridList({
    super.key,
    required this.children,
    this.gridColumns = 2,
    this.spacing,
    this.childAspectRatio,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context, constraints) => _buildList(),
      tablet: (context, constraints) => _buildGrid(2),
      desktop: (context, constraints) => _buildGrid(gridColumns),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing ?? AppDimensions.spaceM),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _buildGrid(int columns) {
    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing ?? AppDimensions.spaceM,
        mainAxisSpacing: spacing ?? AppDimensions.spaceM,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Adaptive split view
/// Two-pane layout on desktop, stacked on mobile
class AdaptiveSplitView extends StatelessWidget {
  /// Primary pane (left on desktop, top on mobile)
  final Widget primary;

  /// Secondary pane (right on desktop, bottom on mobile)
  final Widget secondary;

  /// Split ratio (0.0 - 1.0, default 0.5)
  final double splitRatio;

  /// Minimum width for split view
  final double minWidthForSplit;

  /// Spacing between panes
  final double? spacing;

  const AdaptiveSplitView({
    super.key,
    required this.primary,
    required this.secondary,
    this.splitRatio = 0.5,
    this.minWidthForSplit = 800,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldSplit = constraints.maxWidth >= minWidthForSplit;

        if (shouldSplit) {
          // Split view (desktop)
          return Row(
            children: [
              Expanded(
                flex: (splitRatio * 100).toInt(),
                child: primary,
              ),
              if (spacing != null) SizedBox(width: spacing),
              Expanded(
                flex: ((1 - splitRatio) * 100).toInt(),
                child: secondary,
              ),
            ],
          );
        }

        // Stacked view (mobile)
        return Column(
          children: [
            Expanded(child: primary),
            if (spacing != null) SizedBox(height: spacing),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

/// Adaptive card layout
/// Changes card width and layout based on screen size
class AdaptiveCardLayout extends StatelessWidget {
  /// Cards to display
  final List<Widget> cards;

  /// Padding around layout
  final EdgeInsets? padding;

  /// Spacing between cards
  final double? spacing;

  /// Maximum card width on desktop
  final double? maxCardWidth;

  const AdaptiveCardLayout({
    super.key,
    required this.cards,
    this.padding,
    this.spacing,
    this.maxCardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context, constraints) => _buildMobileLayout(),
      tablet: (context, constraints) => _buildTabletLayout(),
      desktop: (context, constraints) => _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(AppDimensions.spaceS),
      itemCount: cards.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: spacing ?? AppDimensions.spaceM),
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildTabletLayout() {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(AppDimensions.spaceM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: spacing ?? AppDimensions.spaceM,
        mainAxisSpacing: spacing ?? AppDimensions.spaceM,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildDesktopLayout() {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(AppDimensions.spaceL),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCardWidth ?? 400,
        crossAxisSpacing: spacing ?? AppDimensions.spaceL,
        mainAxisSpacing: spacing ?? AppDimensions.spaceL,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

/// Adaptive app bar actions
/// Shows actions in app bar on desktop, in menu on mobile
class AdaptiveAppBarActions extends StatelessWidget {
  /// Actions to display
  final List<Widget> actions;

  /// Max actions to show on mobile before menu
  final int maxMobileActions;

  const AdaptiveAppBarActions({
    super.key,
    required this.actions,
    this.maxMobileActions = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppDimensions.tablet;

        if (isDesktop) {
          // Show all actions on desktop
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          );
        }

        // On mobile, show limited actions + menu
        if (actions.length <= maxMobileActions) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...actions.take(maxMobileActions - 1),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => List.generate(
                actions.length - (maxMobileActions - 1),
                (index) => PopupMenuItem<int>(
                  value: index,
                  child: actions[maxMobileActions - 1 + index],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
