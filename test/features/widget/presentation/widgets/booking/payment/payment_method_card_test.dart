import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/payment/payment_method_card.dart';

void main() {
  group('PaymentMethodCard', () {
    testWidgets('renders container with styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(icon: Icons.credit_card, title: 'Credit Card', isDarkMode: false),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders provided icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(icon: Icons.credit_card, title: 'Credit Card', isDarkMode: false),
          ),
        ),
      );

      expect(find.byIcon(Icons.credit_card), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(icon: Icons.credit_card, title: 'Credit Card', isDarkMode: false),
          ),
        ),
      );

      expect(find.text('Credit Card'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: '€50.00 deposit',
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('€50.00 deposit'), findsOneWidget);
    });

    testWidgets('does not render subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(icon: Icons.credit_card, title: 'Credit Card', isDarkMode: false),
          ),
        ),
      );

      // Only title should be in the Column
      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.children.length, 1);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(
              icon: Icons.account_balance,
              title: 'Bank Transfer',
              subtitle: '€100.00 deposit',
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(PaymentMethodCard), findsOneWidget);
    });

    testWidgets('uses Row layout with icon and column', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodCard(icon: Icons.home_outlined, title: 'Pay on Arrival', isDarkMode: false),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });
  });
}
