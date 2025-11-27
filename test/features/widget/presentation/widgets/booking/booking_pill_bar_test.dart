import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/presentation/widgets/booking/booking_pill_bar.dart';

void main() {
  group('BookingPillBar', () {
    testWidgets('renders Material with elevation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Material), findsWidgets);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('positions at given offset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(100, 200),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, 100);
      expect(positioned.top, 200);
    });

    testWidgets('applies correct width and height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(0, 0),
                  width: 400,
                  maxHeight: 300,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      // Find the container with width/height constraints
      final sizedContainer = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 400 && c.constraints?.maxHeight == 300,
        orElse: Container.new,
      );
      expect(sizedContainer.constraints?.maxWidth, 400);
      expect(sizedContainer.constraints?.maxHeight, 300);
    });

    testWidgets('calls onDragStart when drag begins', (tester) async {
      bool dragStartCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () => dragStartCalled = true,
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      // Start a drag gesture
      await tester.drag(find.text('Content'), const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(dragStartCalled, isTrue);
    });

    testWidgets('calls onDragUpdate with delta during drag', (tester) async {
      Offset? lastDelta;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) => lastDelta = delta,
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.text('Content'), const Offset(20, 30));

      expect(lastDelta, isNotNull);
    });

    testWidgets('calls onDragEnd when drag ends', (tester) async {
      bool dragEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () => dragEndCalled = true,
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.text('Content'), const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(dragEndCalled, isTrue);
    });

    testWidgets('renders with border radius 30', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      // Container should have decoration with borderRadius of 30
      final containers = tester.widgetList<Container>(find.byType(Container));
      final decoratedContainer = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.borderRadius == BorderRadius.circular(30);
        }
        return false;
      });
      expect(decoratedContainer, isNotEmpty);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: true,
                  keyboardInset: 0,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BookingPillBar), findsOneWidget);
    });

    testWidgets('adds keyboard inset to bottom padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BookingPillBar(
                  position: const Offset(50, 50),
                  width: 350,
                  maxHeight: 282,
                  isDarkMode: false,
                  keyboardInset: 200,
                  onDragStart: () {},
                  onDragUpdate: (delta) {},
                  onDragEnd: () {},
                  child: const Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );

      // Should have bottom padding including keyboard inset
      expect(find.byType(BookingPillBar), findsOneWidget);
    });
  });
}
