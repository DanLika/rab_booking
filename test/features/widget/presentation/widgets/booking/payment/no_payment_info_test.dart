import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/payment/no_payment_info.dart';

void main() {
  group('NoPaymentInfo', () {
    testWidgets('renders container with error styling', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NoPaymentInfo(isDarkMode: false)),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders error icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NoPaymentInfo(isDarkMode: false)),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders default error message', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NoPaymentInfo(isDarkMode: false)),
          ),
        ),
      );

      expect(
        find.text(
          'No payment methods are currently configured. Please contact the property owner to complete your booking.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders custom message when provided', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NoPaymentInfo(
                isDarkMode: false,
                message: 'Custom error message',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom error message'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NoPaymentInfo(isDarkMode: true)),
          ),
        ),
      );

      expect(find.byType(NoPaymentInfo), findsOneWidget);
    });

    testWidgets('uses Row layout with icon and text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: NoPaymentInfo(isDarkMode: false)),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
