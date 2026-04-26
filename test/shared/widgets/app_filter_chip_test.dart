import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/shared/widgets/app_filter_chip.dart';
import 'package:bookbed/core/theme/app_gradients.dart';

void main() {
  group('AppFilterChip', () {
    Widget buildTestWidget({
      required String label,
      required bool selected,
      required VoidCallback onSelected,
      IconData? icon,
    }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [AppGradients.light],
        ),
        home: Scaffold(
          body: Center(
            child: AppFilterChip(
              label: label,
              selected: selected,
              onSelected: onSelected,
              icon: icon,
            ),
          ),
        ),
      );
    }

    testWidgets('renders label correctly when not selected', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          label: 'Test Label',
          selected: false,
          onSelected: () {
            tapped = true;
          },
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(filterChip.selected, false);
    });

    testWidgets('renders label correctly when selected', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          label: 'Selected Label',
          selected: true,
          onSelected: () {
            tapped = true;
          },
        ),
      );

      expect(find.text('Selected Label'), findsOneWidget);
      final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(filterChip.selected, true);
    });

    testWidgets('renders icon when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          label: 'With Icon',
          selected: false,
          onSelected: () {
            tapped = true;
          },
          icon: Icons.star,
        ),
      );

      expect(find.text('With Icon'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onSelected when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          label: 'Tap Me',
          selected: false,
          onSelected: () {
            tapped = true;
          },
        ),
      );

      await tester.tap(find.byType(AppFilterChip));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('mouse hover triggers state change correctly', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          label: 'Hover Me',
          selected: false,
          onSelected: () {
            tapped = true;
          },
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Verify we have MouseRegions
      expect(find.byType(MouseRegion), findsWidgets);

      // Move mouse over the chip
      await gesture.moveTo(tester.getCenter(find.byType(AppFilterChip)));
      await tester.pumpAndSettle();

      // At this point _isHovered is true, we could potentially verify colors
      // but without reflection we just make sure it doesn't crash on hover state update.
      expect(find.text('Hover Me'), findsOneWidget);

      // Move mouse away
      await gesture.moveTo(const Offset(1000, 1000));
      await tester.pumpAndSettle();

      expect(find.text('Hover Me'), findsOneWidget);
    });
  });
}
