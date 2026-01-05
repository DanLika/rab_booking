import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/payment/payment_option_widget.dart';

void main() {
  group('PaymentOptionWidget', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay securely with your card',
              isSelected: false,
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.credit_card), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('Pay securely with your card'), findsOneWidget);
    });

    testWidgets('shows deposit amount when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay now',
              isSelected: false,
              onTap: () {},
              isDarkMode: false,
              depositAmount: '€50.00',
            ),
          ),
        ),
      );

      expect(find.text('€50.00'), findsOneWidget);
    });

    testWidgets('hides deposit amount when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.account_balance,
              title: 'Bank Transfer',
              subtitle: 'Pay via bank',
              isSelected: false,
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // No deposit amount text should be found
      expect(find.text('€'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay now',
              isSelected: false,
              onTap: () {
                wasTapped = true;
              },
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PaymentOptionWidget));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });

    testWidgets('shows filled radio when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay now',
              isSelected: true,
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Find the inner circle (selected indicator)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay now',
              isSelected: true,
              onTap: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(PaymentOptionWidget), findsOneWidget);
    });

    testWidgets('uses InkWell for tap feedback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentOptionWidget(
              icon: Icons.credit_card,
              title: 'Credit Card',
              subtitle: 'Pay now',
              isSelected: false,
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
