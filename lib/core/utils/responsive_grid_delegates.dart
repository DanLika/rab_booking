import 'package:flutter/widgets.dart';
import '../constants/app_dimensions.dart';

/// Factory class for creating responsive SliverGridDelegate instances
/// Provides consistent grid layouts across the app for common use cases
class ResponsiveGridDelegates {
  ResponsiveGridDelegates._(); // Private constructor

  /// Get property grid delegate (1-3 columns, uses mainAxisExtent)
  ///
  /// Mobile: 1 column
  /// Tablet: 2 columns
  /// Desktop: 3 columns
  ///
  /// Usage:
  /// ```dart
  /// GridView.builder(
  ///   gridDelegate: ResponsiveGridDelegates.getPropertyGrid(context, mainAxisExtent: 320),
  ///   ...
  /// )
  /// ```
  static SliverGridDelegate getPropertyGrid(
    BuildContext context, {
    double? mainAxisExtent,
  }) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _getPropertyCrossAxisCount(width);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppDimensions.spaceM,
      mainAxisSpacing: AppDimensions.spaceM,
      mainAxisExtent: mainAxisExtent,
    );
  }

  /// Get unit grid delegate (1-3 columns, uses childAspectRatio)
  ///
  /// Mobile: 1 column (aspect ratio 1.1)
  /// Tablet: 2 columns (aspect ratio 1.0)
  /// Desktop: 3 columns (aspect ratio 0.95)
  ///
  /// Usage:
  /// ```dart
  /// GridView.builder(
  ///   gridDelegate: ResponsiveGridDelegates.getUnitGrid(context),
  ///   ...
  /// )
  /// ```
  static SliverGridDelegate getUnitGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = AppDimensions.getGridColumns(width);

    // Adjust aspect ratio based on columns for better card proportions
    final aspectRatio = switch (crossAxisCount) {
      1 => 1.1, // Mobile: slightly taller cards
      2 => 1.0, // Tablet: square-ish cards
      _ => 0.95, // Desktop: slightly wider cards
    };

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppDimensions.spaceS,
      mainAxisSpacing: AppDimensions.spaceS,
      childAspectRatio: aspectRatio,
    );
  }

  /// Get price calendar grid delegate (7 columns for days of week)
  ///
  /// Always 7 columns (Mon-Sun)
  /// Dynamic aspect ratio based on available width
  ///
  /// Usage:
  /// ```dart
  /// GridView.builder(
  ///   gridDelegate: ResponsiveGridDelegates.getPriceCalendarGrid(context, aspectRatio: 1.0),
  ///   ...
  /// )
  /// ```
  static SliverGridDelegate getPriceCalendarGrid(
    BuildContext context, {
    double aspectRatio = 1.0,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7, // 7 days of week
      mainAxisSpacing: AppDimensions.spaceXS,
      crossAxisSpacing: AppDimensions.spaceXS,
      childAspectRatio: aspectRatio,
    );
  }

  /// Get generic responsive grid delegate
  ///
  /// Allows custom column counts per breakpoint
  ///
  /// Usage:
  /// ```dart
  /// GridView.builder(
  ///   gridDelegate: ResponsiveGridDelegates.getGenericGrid(
  ///     context,
  ///     mobileColumns: 2,
  ///     tabletColumns: 4,
  ///     desktopColumns: 6,
  ///   ),
  ///   ...
  /// )
  /// ```
  static SliverGridDelegate getGenericGrid(
    BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
    double? spacing,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    double? childAspectRatio,
    double? mainAxisExtent,
  }) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = _getGenericCrossAxisCount(
      width,
      mobileColumns,
      tabletColumns,
      desktopColumns,
    );

    // Use provided spacing or default to AppDimensions.spaceS
    final effectiveMainSpacing = mainAxisSpacing ?? spacing ?? AppDimensions.spaceS;
    final effectiveCrossSpacing = crossAxisSpacing ?? spacing ?? AppDimensions.spaceS;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: effectiveMainSpacing,
      crossAxisSpacing: effectiveCrossSpacing,
      childAspectRatio: childAspectRatio ?? 1.0,
      mainAxisExtent: mainAxisExtent,
    );
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Get property cross axis count based on screen width
  /// Uses custom logic for better property card layout
  static int _getPropertyCrossAxisCount(double width) {
    if (width >= 1280) {
      return 3; // Desktop: 3 columns
    } else if (width >= 960) {
      return 2; // Tablet landscape: 2 columns
    } else if (width >= AppDimensions.mobile) {
      return 2; // Tablet portrait: 2 columns
    } else if (width >= 480) {
      return 1; // Mobile landscape: 1 column
    } else {
      return 1; // Small mobile: 1 column
    }
  }

  /// Get generic cross axis count based on screen width
  static int _getGenericCrossAxisCount(
    double width,
    int mobileColumns,
    int tabletColumns,
    int desktopColumns,
  ) {
    if (width < AppDimensions.mobile) {
      return mobileColumns;
    } else if (width < AppDimensions.tablet) {
      return tabletColumns;
    } else {
      return desktopColumns;
    }
  }
}
