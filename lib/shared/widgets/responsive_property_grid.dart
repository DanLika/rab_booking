import 'package:flutter/material.dart';
import '../../core/utils/responsive_builder.dart';
import '../../core/constants/app_dimensions.dart';

/// Responsive property grid
/// Optimized for displaying property listings with adaptive column counts
class ResponsivePropertyGrid extends StatelessWidget {
  /// Property items to display
  final List<Widget> properties;

  /// Padding around grid
  final EdgeInsets? padding;

  /// Spacing between items
  final double? spacing;

  /// Run spacing (vertical)
  final double? runSpacing;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Shrink wrap
  final bool shrinkWrap;

  /// Scroll controller
  final ScrollController? controller;

  /// Child aspect ratio
  final double? childAspectRatio;

  /// Custom column counts
  final ResponsiveValue<int>? customColumns;

  const ResponsivePropertyGrid({
    super.key,
    required this.properties,
    this.padding,
    this.spacing,
    this.runSpacing,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
    this.childAspectRatio,
    this.customColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Default responsive column counts
        final columns = customColumns ??
            const ResponsiveValue<int>(
              mobile: 1,
              tablet: 2,
              desktop: 3,
              largeDesktop: 4,
            );

        final columnCount = columns.fromConstraints(constraints);
        final effectiveSpacing = spacing ?? AppDimensions.spaceM;
        final effectiveRunSpacing = runSpacing ?? AppDimensions.spaceM;

        // Calculate responsive child aspect ratio
        final effectiveAspectRatio = childAspectRatio ??
            _getResponsiveAspectRatio(constraints.maxWidth);

        return GridView.builder(
          controller: controller,
          padding: padding ?? _getResponsivePadding(constraints.maxWidth),
          physics: physics,
          shrinkWrap: shrinkWrap,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: effectiveSpacing,
            mainAxisSpacing: effectiveRunSpacing,
            childAspectRatio: effectiveAspectRatio,
          ),
          itemCount: properties.length,
          itemBuilder: (context, index) => properties[index],
        );
      },
    );
  }

  EdgeInsets _getResponsivePadding(double width) {
    if (width >= AppDimensions.desktop) {
      return const EdgeInsets.all(AppDimensions.spaceXL);
    }
    if (width >= AppDimensions.tablet) {
      return const EdgeInsets.all(AppDimensions.spaceL);
    }
    return const EdgeInsets.all(AppDimensions.spaceM);
  }

  double _getResponsiveAspectRatio(double width) {
    if (width >= AppDimensions.desktop) {
      return 0.75; // Taller cards on desktop
    }
    if (width >= AppDimensions.tablet) {
      return 0.8; // Medium cards on tablet
    }
    return 0.85; // Wider cards on mobile
  }
}

/// Responsive property list (alternative to grid)
/// Displays properties in a list format with adaptive sizing
class ResponsivePropertyList extends StatelessWidget {
  /// Property items to display
  final List<Widget> properties;

  /// Padding around list
  final EdgeInsets? padding;

  /// Spacing between items
  final double? spacing;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Shrink wrap
  final bool shrinkWrap;

  /// Scroll controller
  final ScrollController? controller;

  const ResponsivePropertyList({
    super.key,
    required this.properties,
    this.padding,
    this.spacing,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveSpacing = spacing ?? _getResponsiveSpacing(constraints.maxWidth);
        final effectivePadding = padding ?? _getResponsivePadding(constraints.maxWidth);

        return ListView.separated(
          controller: controller,
          padding: effectivePadding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          itemCount: properties.length,
          separatorBuilder: (context, index) => SizedBox(height: effectiveSpacing),
          itemBuilder: (context, index) => properties[index],
        );
      },
    );
  }

  double _getResponsiveSpacing(double width) {
    if (width >= AppDimensions.desktop) {
      return AppDimensions.spaceL;
    }
    if (width >= AppDimensions.tablet) {
      return AppDimensions.spaceM;
    }
    return AppDimensions.spaceS;
  }

  EdgeInsets _getResponsivePadding(double width) {
    if (width >= AppDimensions.desktop) {
      return const EdgeInsets.all(AppDimensions.spaceXL);
    }
    if (width >= AppDimensions.tablet) {
      return const EdgeInsets.all(AppDimensions.spaceL);
    }
    return const EdgeInsets.all(AppDimensions.spaceM);
  }
}

/// Responsive masonry grid for properties
/// Creates a Pinterest-style layout with varying heights
class ResponsiveMasonryGrid extends StatelessWidget {
  /// Property items to display
  final List<Widget> properties;

  /// Padding around grid
  final EdgeInsets? padding;

  /// Spacing between items
  final double? spacing;

  /// Custom column counts
  final ResponsiveValue<int>? customColumns;

  const ResponsiveMasonryGrid({
    super.key,
    required this.properties,
    this.padding,
    this.spacing,
    this.customColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = customColumns ??
            const ResponsiveValue<int>(
              mobile: 1,
              tablet: 2,
              desktop: 3,
              largeDesktop: 4,
            );

        final columnCount = columns.fromConstraints(constraints);
        final effectiveSpacing = spacing ?? AppDimensions.spaceM;
        final effectivePadding = padding ?? _getResponsivePadding(constraints.maxWidth);

        // Create columns
        final columnWidgets = List.generate(
          columnCount,
          (index) => <Widget>[],
        );

        // Distribute items across columns
        for (int i = 0; i < properties.length; i++) {
          final columnIndex = i % columnCount;
          columnWidgets[columnIndex].add(properties[i]);
        }

        return SingleChildScrollView(
          padding: effectivePadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              columnCount,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: index == 0 || index == columnCount - 1
                        ? 0
                        : effectiveSpacing / 2,
                  ),
                  child: Column(
                    children: columnWidgets[index]
                        .expand(
                          (widget) => [
                            widget,
                            SizedBox(height: effectiveSpacing),
                          ],
                        )
                        .take(columnWidgets[index].length * 2 - 1)
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getResponsivePadding(double width) {
    if (width >= AppDimensions.desktop) {
      return const EdgeInsets.all(AppDimensions.spaceXL);
    }
    if (width >= AppDimensions.tablet) {
      return const EdgeInsets.all(AppDimensions.spaceL);
    }
    return const EdgeInsets.all(AppDimensions.spaceM);
  }
}

/// Property grid view mode enum
enum PropertyGridViewMode {
  grid,
  list,
  masonry,
}

/// Responsive property grid with view mode switcher
/// Allows users to switch between grid, list, and masonry views
class ResponsivePropertyGridWithMode extends StatefulWidget {
  /// Property items to display
  final List<Widget> properties;

  /// Initial view mode
  final PropertyGridViewMode initialMode;

  /// Show view mode switcher
  final bool showModeSwitcher;

  /// On view mode changed callback
  final ValueChanged<PropertyGridViewMode>? onModeChanged;

  /// Padding
  final EdgeInsets? padding;

  /// Spacing
  final double? spacing;

  const ResponsivePropertyGridWithMode({
    super.key,
    required this.properties,
    this.initialMode = PropertyGridViewMode.grid,
    this.showModeSwitcher = true,
    this.onModeChanged,
    this.padding,
    this.spacing,
  });

  @override
  State<ResponsivePropertyGridWithMode> createState() =>
      _ResponsivePropertyGridWithModeState();
}

class _ResponsivePropertyGridWithModeState
    extends State<ResponsivePropertyGridWithMode> {
  late PropertyGridViewMode _viewMode;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showModeSwitcher) _buildModeSwitcher(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () => _setMode(PropertyGridViewMode.grid),
            color: _viewMode == PropertyGridViewMode.grid
                ? Theme.of(context).primaryColor
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => _setMode(PropertyGridViewMode.list),
            color: _viewMode == PropertyGridViewMode.list
                ? Theme.of(context).primaryColor
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () => _setMode(PropertyGridViewMode.masonry),
            color: _viewMode == PropertyGridViewMode.masonry
                ? Theme.of(context).primaryColor
                : null,
          ),
        ],
      ),
    );
  }

  void _setMode(PropertyGridViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
    widget.onModeChanged?.call(mode);
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case PropertyGridViewMode.grid:
        return ResponsivePropertyGrid(
          properties: widget.properties,
          padding: widget.padding,
          spacing: widget.spacing,
        );
      case PropertyGridViewMode.list:
        return ResponsivePropertyList(
          properties: widget.properties,
          padding: widget.padding,
          spacing: widget.spacing,
        );
      case PropertyGridViewMode.masonry:
        return ResponsiveMasonryGrid(
          properties: widget.properties,
          padding: widget.padding,
          spacing: widget.spacing,
        );
    }
  }
}
