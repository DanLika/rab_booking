import 'package:flutter/material.dart';

/// Tablet layout utilities
/// Provides split-view patterns, master-detail layouts, and tablet-optimized widgets
class TabletLayoutUtils {
  TabletLayoutUtils._();

  /// Check if device is tablet (width >= 600 && < 1024)
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.shortestSide;
    return width >= 600 && width < 1024;
  }

  /// Check if device is large tablet/desktop (>= 1024)
  static bool isLargeTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.shortestSide;
    return width >= 1024;
  }

  /// Check if split view should be used
  static bool shouldUseSplitView(BuildContext context) {
    return isTablet(context) || isLargeTablet(context);
  }

  /// Get optimal master pane width for split view
  static double getMasterPaneWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLargeTablet(context)) {
      return 400; // Fixed width for large tablets
    } else if (isTablet(context)) {
      return screenWidth * 0.35; // 35% of screen width for tablets
    }

    return screenWidth; // Full width for mobile
  }

  /// Get optimal detail pane width for split view
  static double getDetailPaneWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final masterWidth = getMasterPaneWidth(context);

    return screenWidth - masterWidth;
  }

  /// Get optimal touch target size for tablets
  static double getTouchTargetSize(BuildContext context) {
    if (shouldUseSplitView(context)) {
      return 56.0; // Larger touch targets for tablets
    }
    return 48.0; // Standard mobile size
  }

  /// Get optimal spacing for tablets
  static double getSpacing(BuildContext context) {
    if (shouldUseSplitView(context)) {
      return 24.0; // More spacing on tablets
    }
    return 16.0; // Standard mobile spacing
  }

  /// Get optimal padding for tablets
  static EdgeInsets getPadding(BuildContext context) {
    if (shouldUseSplitView(context)) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }
}

/// Split view layout for tablets (master-detail pattern)
class TabletSplitView extends StatelessWidget {
  /// Master pane (left side - typically a list)
  final Widget master;

  /// Detail pane (right side - typically details of selected item)
  final Widget detail;

  /// Master pane width (optional, auto-calculated if not provided)
  final double? masterWidth;

  /// Show divider between panes
  final bool showDivider;

  /// Divider color
  final Color? dividerColor;

  /// Master pane background color
  final Color? masterBackgroundColor;

  /// Detail pane background color
  final Color? detailBackgroundColor;

  const TabletSplitView({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth,
    this.showDivider = true,
    this.dividerColor,
    this.masterBackgroundColor,
    this.detailBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // On mobile, show only master (detail should be pushed separately)
    if (!TabletLayoutUtils.shouldUseSplitView(context)) {
      return master;
    }

    final masterPaneWidth =
        masterWidth ?? TabletLayoutUtils.getMasterPaneWidth(context);

    return Row(
      children: [
        // Master pane
        Container(
          width: masterPaneWidth,
          color: masterBackgroundColor,
          child: master,
        ),

        // Divider
        if (showDivider)
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: dividerColor ?? Theme.of(context).dividerColor,
          ),

        // Detail pane
        Expanded(
          child: Container(
            color: detailBackgroundColor,
            child: detail,
          ),
        ),
      ],
    );
  }
}

/// Adaptive master-detail navigator
class MasterDetailScaffold extends StatefulWidget {
  /// Master view builder
  final Widget Function(BuildContext context, void Function(Widget) showDetail)
      masterBuilder;

  /// Initial detail view (shown on tablets)
  final Widget? initialDetail;

  /// App bar for master view
  final PreferredSizeWidget? masterAppBar;

  /// App bar for detail view (used on mobile)
  final PreferredSizeWidget? detailAppBar;

  /// Master pane width (optional)
  final double? masterWidth;

  const MasterDetailScaffold({
    super.key,
    required this.masterBuilder,
    this.initialDetail,
    this.masterAppBar,
    this.detailAppBar,
    this.masterWidth,
  });

  @override
  State<MasterDetailScaffold> createState() => _MasterDetailScaffoldState();
}

class _MasterDetailScaffoldState extends State<MasterDetailScaffold> {
  Widget? _currentDetail;

  @override
  void initState() {
    super.initState();
    _currentDetail = widget.initialDetail;
  }

  void _showDetail(Widget detail) {
    if (TabletLayoutUtils.shouldUseSplitView(context)) {
      // On tablet, update detail pane
      setState(() {
        _currentDetail = detail;
      });
    } else {
      // On mobile, push new route
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: widget.detailAppBar,
            body: detail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterView = widget.masterBuilder(context, _showDetail);

    if (!TabletLayoutUtils.shouldUseSplitView(context)) {
      // Mobile: show only master
      return Scaffold(
        appBar: widget.masterAppBar,
        body: masterView,
      );
    }

    // Tablet: show split view
    return Scaffold(
      body: TabletSplitView(
        master: Column(
          children: [
            if (widget.masterAppBar != null)
              SizedBox(
                height: kToolbarHeight,
                child: widget.masterAppBar!,
              ),
            Expanded(child: masterView),
          ],
        ),
        detail: _currentDetail ??
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select an item to view details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                  ),
                ],
              ),
            ),
        masterWidth: widget.masterWidth,
      ),
    );
  }
}

/// Grid with adaptive column count based on screen size
class AdaptiveGrid extends StatelessWidget {
  /// Items to display
  final List<Widget> children;

  /// Minimum item width
  final double minItemWidth;

  /// Spacing between items
  final double spacing;

  /// Main axis spacing
  final double mainAxisSpacing;

  /// Cross axis spacing
  final double crossAxisSpacing;

  /// Child aspect ratio
  final double childAspectRatio;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 200.0,
    this.spacing = 16.0,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
    this.childAspectRatio = 1.0,
  });

  int _calculateColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (spacing * 2);
    final columns = (availableWidth / (minItemWidth + crossAxisSpacing)).floor();
    return columns.clamp(1, 6);
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = _calculateColumnCount(context);

    return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: EdgeInsets.all(TabletLayoutUtils.getSpacing(context)),
      children: children,
    );
  }
}

/// Responsive columns layout
class ResponsiveColumns extends StatelessWidget {
  /// Children widgets
  final List<Widget> children;

  /// Spacing between columns
  final double spacing;

  /// Mobile: 1 column
  /// Tablet: 2 columns
  /// Desktop: 3+ columns
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveColumns({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
  });

  int _getColumnCount(BuildContext context) {
    if (TabletLayoutUtils.isLargeTablet(context)) {
      return desktopColumns ?? 3;
    } else if (TabletLayoutUtils.isTablet(context)) {
      return tabletColumns ?? 2;
    }
    return mobileColumns ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = _getColumnCount(context);

    if (columnCount == 1) {
      return Column(
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: child,
                ))
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += columnCount) {
      final rowChildren = <Widget>[];
      for (int j = 0; j < columnCount && i + j < children.length; j++) {
        rowChildren.add(
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: j < columnCount - 1 ? spacing : 0,
              ),
              child: children[i + j],
            ),
          ),
        );
      }

      // Fill remaining space if last row is incomplete
      while (rowChildren.length < columnCount) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

/// Extension on BuildContext for tablet utilities
extension TabletContextExtension on BuildContext {
  /// Check if device is tablet
  bool get isTablet => TabletLayoutUtils.isTablet(this);

  /// Check if device is large tablet
  bool get isLargeTablet => TabletLayoutUtils.isLargeTablet(this);

  /// Check if split view should be used
  bool get shouldUseSplitView => TabletLayoutUtils.shouldUseSplitView(this);

  /// Get tablet-optimized spacing
  double get tabletSpacing => TabletLayoutUtils.getSpacing(this);

  /// Get tablet-optimized padding
  EdgeInsets get tabletPadding => TabletLayoutUtils.getPadding(this);

  /// Get tablet-optimized touch target size
  double get tabletTouchTargetSize => TabletLayoutUtils.getTouchTargetSize(this);
}
