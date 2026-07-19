// Audit sweep F3.7 + F4.14 — skeleton loader dark ladder + bounded lists.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/shared/widgets/animations/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('F3.7: dark skeleton colors sit on the audit/127 OLED ladder', () {
    expect(SkeletonColors.darkCardBackground, const Color(0xFF1E1E1E));
    expect(SkeletonColors.darkPrimary, const Color(0xFF2A2A2A));
    expect(SkeletonColors.darkSecondary, const Color(0xFF333333));
    expect(SkeletonColors.darkBorder, const Color(0xFF333333));
    expect(SkeletonColors.darkHeader, const Color(0xFF2A2A2A));
  });

  testWidgets('F4.14: PropertyListSkeleton survives nesting in a Column', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [Text('header'), PropertyListSkeleton(itemCount: 2)],
            ),
          ),
        ),
      ),
    );
    // Unbounded ListView.builder asserted here before the fix.
    expect(tester.takeException(), isNull);
    expect(find.byType(PropertyCardSkeleton), findsNWidgets(2));
  });

  testWidgets('F4.14: NotificationsListSkeleton survives nesting', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [NotificationsListSkeleton(itemCount: 2)]),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('F3.7: stats skeleton uses dark card surface in dark theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: StatsCardsSkeleton()),
      ),
    );
    final bool hasDarkCard = tester
        .widgetList<Container>(find.byType(Container))
        .any(
          (Container w) =>
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  SkeletonColors.darkCardBackground,
        );
    expect(hasDarkCard, isTrue);
  });
}
