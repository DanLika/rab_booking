import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/owner_dashboard/utils/responsive_calendar_layout.dart';

void main() {
  Widget buildTestableWidget({
    required Widget child,
    Size size = const Size(800, 600),
    TargetPlatform platform = TargetPlatform.android,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return MaterialApp(
      theme: ThemeData(platform: platform),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
        ),
        child: child,
      ),
    );
  }

  group('ResponsiveCalendarLayout', () {
    testWidgets('buildTestableWidget helper works', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        size: const Size(400, 800),
        child: Builder(builder: (context) {
          final size = MediaQuery.of(context).size;
          expect(size.width, 400);
          expect(size.height, 800);
          expect(MediaQuery.of(context).orientation, Orientation.portrait);
          return const SizedBox();
        }),
      ));
    });

    group('getLayoutMode', () {
      testWidgets('returns mobilePortrait for small width and portrait', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getLayoutMode(context), CalendarLayoutMode.mobilePortrait);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('returns mobileLandscape for small width and landscape', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(599, 400),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getLayoutMode(context), CalendarLayoutMode.mobileLandscape);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('returns tablet for medium width', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getLayoutMode(context), CalendarLayoutMode.tablet);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('returns desktop for large width', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getLayoutMode(context), CalendarLayoutMode.desktop);
            return const SizedBox();
          }),
        ));
      });
    });

    group('device/web detection', () {
      testWidgets('isMobileDevice returns true for iOS and Android', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          platform: TargetPlatform.android,
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.isMobileDevice(context), isTrue);
            return const SizedBox();
          }),
        ));

        await tester.pumpWidget(buildTestableWidget(
          platform: TargetPlatform.iOS,
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.isMobileDevice(context), isTrue);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('isMobileDevice returns false for desktop platforms', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          platform: TargetPlatform.macOS,
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.isMobileDevice(context), isFalse);
            return const SizedBox();
          }),
        ));

        await tester.pumpWidget(buildTestableWidget(
          platform: TargetPlatform.windows,
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.isMobileDevice(context), isFalse);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('isWeb behaves predictably based on the runtime', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          child: Builder(builder: (context) {
            // Note: kIsWeb evaluates based on the actual platform running the test
            expect(ResponsiveCalendarLayout.isWeb(context), isFalse);
            return const SizedBox();
          }),
        ));
      });
    });

    group('layout behavior methods', () {
      testWidgets('getRecommendedBookingListView returns correct mode based on layout', (WidgetTester tester) async {
        // Mobile portrait -> card
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getRecommendedBookingListView(context), BookingListViewMode.card);
            return const SizedBox();
          }),
        ));

        // Mobile landscape -> card
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(599, 400),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getRecommendedBookingListView(context), BookingListViewMode.card);
            return const SizedBox();
          }),
        ));

        // Tablet -> card
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getRecommendedBookingListView(context), BookingListViewMode.card);
            return const SizedBox();
          }),
        ));

        // Desktop -> table
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getRecommendedBookingListView(context), BookingListViewMode.table);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('shouldEnableHorizontalScroll enables on mobile modes only', (WidgetTester tester) async {
        // Mobile portrait -> true
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.shouldEnableHorizontalScroll(context), isTrue);
            return const SizedBox();
          }),
        ));

        // Tablet -> false
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.shouldEnableHorizontalScroll(context), isFalse);
            return const SizedBox();
          }),
        ));
      });



      testWidgets('getVisibleDaysForWeek returns correct days based on layout', (WidgetTester tester) async {
        // Mobile portrait -> 5
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getVisibleDaysForWeek(context), 5);
            return const SizedBox();
          }),
        ));

        // Mobile landscape -> 7
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(599, 400),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getVisibleDaysForWeek(context), 7);
            return const SizedBox();
          }),
        ));

        // Tablet -> 7
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getVisibleDaysForWeek(context), 7);
            return const SizedBox();
          }),
        ));
      });
    });

    group('dimension and sizing methods', () {
      testWidgets('getSidebarWidth returns correct width based on layout', (WidgetTester tester) async {
        // Mobile portrait -> 0
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getSidebarWidth(context), 0);
            return const SizedBox();
          }),
        ));

        // Tablet -> 280
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getSidebarWidth(context), 280);
            return const SizedBox();
          }),
        ));

        // Desktop -> 320
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getSidebarWidth(context), 320);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('getDialogWidth returns correct width based on layout', (WidgetTester tester) async {
        // Mobile portrait -> 90% of screen width
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getDialogWidth(context), 400 * 0.9);
            return const SizedBox();
          }),
        ));

        // Tablet -> 500
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getDialogWidth(context), 500);
            return const SizedBox();
          }),
        ));

        // Desktop -> 600
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getDialogWidth(context), 600);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('getAppBarHeight returns kToolbarHeight', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getAppBarHeight(context), kToolbarHeight);
            return const SizedBox();
          }),
        ));
      });

      // Skip testing getBottomNavHeight with macOS platform in the same block to avoid Theme platform caching weirdness
      testWidgets('getBottomNavHeight returns 56 on mobile', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          platform: TargetPlatform.android, // Mobile
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getBottomNavHeight(context), 56);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('getAvailableCalendarHeight calculates correctly', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          platform: TargetPlatform.android, // Mobile -> bottom nav = 56
          child: Builder(builder: (context) {
            final expectedHeight = 800 - kToolbarHeight - 56 - 20 - 20;
            expect(ResponsiveCalendarLayout.getAvailableCalendarHeight(context), expectedHeight);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('shouldUseDrawerForFilters uses drawer for mobile only', (WidgetTester tester) async {
        // Mobile
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.shouldUseDrawerForFilters(context), isTrue);
            return const SizedBox();
          }),
        ));

        // Desktop
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.shouldUseDrawerForFilters(context), isFalse);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('getMaxDialogHeight calculates using ResponsiveSpacingHelper', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000), // tablet
          child: Builder(builder: (context) {
            // ScreenType.tablet -> 0.9 max height percent
            expect(ResponsiveCalendarLayout.getMaxDialogHeight(context), 1000 * 0.9);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('shouldUseFullscreenDialog uses fullscreen for mobile portrait only', (WidgetTester tester) async {
        // Mobile portrait
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.shouldUseFullscreenDialog(context), isTrue);
            return const SizedBox();
          }),
        ));

        // Mobile landscape
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(599, 400),
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.shouldUseFullscreenDialog(context), isFalse);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('getGridHorizontalPadding returns correct padding based on layout', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800), // Mobile
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getGridHorizontalPadding(context), 8);
            return const SizedBox();
          }),
        ));

        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000), // Tablet
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getGridHorizontalPadding(context), 16);
            return const SizedBox();
          }),
        ));

        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800), // Desktop
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getGridHorizontalPadding(context), 24);
            return const SizedBox();
          }),
        ));
      });

      testWidgets('getGridVerticalPadding returns correct padding based on layout', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget(
          size: const Size(400, 800), // Mobile
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getGridVerticalPadding(context), 8);
            return const SizedBox();
          }),
        ));

        await tester.pumpWidget(buildTestableWidget(
          size: const Size(800, 1000), // Tablet
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getGridVerticalPadding(context), 12);
            return const SizedBox();
          }),
        ));

        await tester.pumpWidget(buildTestableWidget(
          size: const Size(1200, 800), // Desktop
          child: Builder(builder: (context) {
            expect(ResponsiveCalendarLayout.getGridVerticalPadding(context), 16);
            return const SizedBox();
          }),
        ));
      });
    });

    group('CalendarLayoutModeX extensions', () {
      test('isMobile returns true for mobile modes only', () {
        expect(CalendarLayoutMode.mobilePortrait.isMobile, isTrue);
        expect(CalendarLayoutMode.mobileLandscape.isMobile, isTrue);
        expect(CalendarLayoutMode.tablet.isMobile, isFalse);
        expect(CalendarLayoutMode.desktop.isMobile, isFalse);
      });

      test('isTablet returns true for tablet mode only', () {
        expect(CalendarLayoutMode.mobilePortrait.isTablet, isFalse);
        expect(CalendarLayoutMode.mobileLandscape.isTablet, isFalse);
        expect(CalendarLayoutMode.tablet.isTablet, isTrue);
        expect(CalendarLayoutMode.desktop.isTablet, isFalse);
      });

      test('isDesktop returns true for desktop mode only', () {
        expect(CalendarLayoutMode.mobilePortrait.isDesktop, isFalse);
        expect(CalendarLayoutMode.mobileLandscape.isDesktop, isFalse);
        expect(CalendarLayoutMode.tablet.isDesktop, isFalse);
        expect(CalendarLayoutMode.desktop.isDesktop, isTrue);
      });

      test('isPortrait returns true for mobilePortrait mode only', () {
        expect(CalendarLayoutMode.mobilePortrait.isPortrait, isTrue);
        expect(CalendarLayoutMode.mobileLandscape.isPortrait, isFalse);
        expect(CalendarLayoutMode.tablet.isPortrait, isFalse);
        expect(CalendarLayoutMode.desktop.isPortrait, isFalse);
      });

      test('isLandscape returns true for mobileLandscape mode only', () {
        expect(CalendarLayoutMode.mobilePortrait.isLandscape, isFalse);
        expect(CalendarLayoutMode.mobileLandscape.isLandscape, isTrue);
        expect(CalendarLayoutMode.tablet.isLandscape, isFalse);
        expect(CalendarLayoutMode.desktop.isLandscape, isFalse);
      });
    });
  });
}
