import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/common/contact/contact_item_widget.dart';

void main() {
  group('ContactItemWidget', () {
    testWidgets('renders icon and value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactItemWidget(
              icon: Icons.email,
              value: 'test@example.com',
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactItemWidget(
              icon: Icons.phone,
              value: '+385 99 123 4567',
              onTap: () {
                wasTapped = true;
              },
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ContactItemWidget));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactItemWidget(
              icon: Icons.email,
              value: 'test@example.com',
              onTap: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(ContactItemWidget), findsOneWidget);
    });

    testWidgets('uses InkWell for tap feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactItemWidget(
              icon: Icons.email,
              value: 'test@example.com',
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('text has underline decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactItemWidget(
              icon: Icons.email,
              value: 'test@example.com',
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('test@example.com'));
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });
  });
}
