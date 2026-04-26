import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/constants/app_dimensions.dart';
import 'package:bookbed/shared/widgets/responsive/responsive_grid.dart';

void main() {
  group('ResponsiveGrid Tests', () {
    Widget buildTestableGrid({
      int mobileColumns = 1,
      int tabletColumns = 2,
      int desktopColumns = 3,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ResponsiveGrid(
              mobileColumns: mobileColumns,
              tabletColumns: tabletColumns,
              desktopColumns: desktopColumns,
              children: List.generate(
                6,
                (index) => Container(
                  height: 100,
                  color: Colors.blue,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders mobile columns correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(AppDimensions.mobile - 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableGrid());

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
    });

    testWidgets('renders tablet columns correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(AppDimensions.tablet - 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableGrid());

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('renders desktop columns correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(AppDimensions.tablet + 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableGrid());

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });
  });

  group('ResponsiveWrap Tests', () {
    Widget buildTestableWrap({
      double mobileSpacing = 8.0,
      double tabletSpacing = 16.0,
      double desktopSpacing = 24.0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ResponsiveWrap(
              mobileSpacing: mobileSpacing,
              tabletSpacing: tabletSpacing,
              desktopSpacing: desktopSpacing,
              children: List.generate(
                6,
                (index) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.blue,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders mobile spacing correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(AppDimensions.mobile - 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWrap());

      final wrapFinder = find.byType(Wrap);
      expect(wrapFinder, findsOneWidget);

      final wrap = tester.widget<Wrap>(wrapFinder);
      expect(wrap.spacing, 8.0);
      expect(wrap.runSpacing, 8.0);
    });

    testWidgets('renders tablet spacing correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(AppDimensions.tablet - 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWrap());

      final wrapFinder = find.byType(Wrap);
      expect(wrapFinder, findsOneWidget);

      final wrap = tester.widget<Wrap>(wrapFinder);
      expect(wrap.spacing, 16.0);
      expect(wrap.runSpacing, 16.0);
    });

    testWidgets('renders desktop spacing correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = Size(AppDimensions.tablet + 100, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWrap());

      final wrapFinder = find.byType(Wrap);
      expect(wrapFinder, findsOneWidget);

      final wrap = tester.widget<Wrap>(wrapFinder);
      expect(wrap.spacing, 24.0);
      expect(wrap.runSpacing, 24.0);
    });
  });
}
