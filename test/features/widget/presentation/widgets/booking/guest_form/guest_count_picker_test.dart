import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/guest_form/guest_count_picker.dart';

void main() {
  group('GuestCountPicker', () {
    testWidgets('renders title and guest counts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 2,
              children: 1,
              maxGuests: 6,
              isDarkMode: false,
              onAdultsChanged: (_) {},
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Number of Guests'), findsOneWidget);
      expect(find.text('Adults'), findsOneWidget);
      expect(find.text('Children'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Adults count
      expect(find.text('1'), findsOneWidget); // Children count
    });

    testWidgets('shows max guests info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 2,
              children: 0,
              maxGuests: 4,
              isDarkMode: false,
              onAdultsChanged: (_) {},
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Max: 4'), findsOneWidget);
    });

    testWidgets('calls onAdultsChanged when increment tapped', (tester) async {
      int newValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 2,
              children: 0,
              maxGuests: 6,
              isDarkMode: false,
              onAdultsChanged: (value) => newValue = value,
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the add button for adults (first add_circle_outline icon)
      final addButtons = find.byIcon(Icons.add_circle_outline);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      expect(newValue, 3);
    });

    testWidgets('calls onAdultsChanged when decrement tapped', (tester) async {
      int newValue = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 2,
              children: 0,
              maxGuests: 6,
              isDarkMode: false,
              onAdultsChanged: (value) => newValue = value,
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the remove button for adults (first remove_circle_outline icon)
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      expect(newValue, 1);
    });

    testWidgets('shows capacity warning when at max', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 4,
              children: 2,
              maxGuests: 6,
              isDarkMode: false,
              onAdultsChanged: (_) {},
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Max capacity: 6 guests'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('hides capacity warning when below max', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 2,
              children: 1,
              maxGuests: 6,
              isDarkMode: false,
              onAdultsChanged: (_) {},
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Max capacity: 6 guests'), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 2,
              children: 0,
              maxGuests: 4,
              isDarkMode: true,
              onAdultsChanged: (_) {},
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GuestCountPicker), findsOneWidget);
    });

    testWidgets('prevents adults below 1', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestCountPicker(
              adults: 1,
              children: 0,
              maxGuests: 6,
              isDarkMode: false,
              onAdultsChanged: (_) => callCount++,
              onChildrenChanged: (_) {},
            ),
          ),
        ),
      );

      // Try to decrement adults below 1
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Should not have called the callback
      expect(callCount, 0);
    });
  });
}
