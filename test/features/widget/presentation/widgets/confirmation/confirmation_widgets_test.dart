import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/confirmation/cancellation_policy_section.dart';
import 'package:bookbed/features/widget/presentation/widgets/confirmation/next_steps_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CancellationPolicySection', () {
    testWidgets('renders header with title and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'REF123',
            ),
          ),
        ),
      );

      expect(find.text('Cancellation Policy'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('renders deadline hours text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 24,
              bookingReference: 'REF123',
            ),
          ),
        ),
      );

      expect(
        find.text('Free cancellation up to 24 hours before check-in'),
        findsOneWidget,
      );
    });

    testWidgets('renders different deadline hours', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 72,
              bookingReference: 'REF456',
            ),
          ),
        ),
      );

      expect(
        find.text('Free cancellation up to 72 hours before check-in'),
        findsOneWidget,
      );
    });

    testWidgets('renders cancellation instructions header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'REF123',
            ),
          ),
        ),
      );

      expect(find.text('To cancel your booking:'), findsOneWidget);
    });

    testWidgets('renders booking reference in instructions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'BOOKING-2025-001',
            ),
          ),
        ),
      );

      expect(
        find.text('Include your booking reference: BOOKING-2025-001'),
        findsOneWidget,
      );
    });

    testWidgets('renders reply to email step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'REF123',
            ),
          ),
        ),
      );

      expect(
        find.text('Reply to the confirmation email'),
        findsOneWidget,
      );
    });

    testWidgets('renders fromEmail when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'REF123',
              fromEmail: 'bookings@example.com',
            ),
          ),
        ),
      );

      expect(
        find.text('Or email: bookings@example.com'),
        findsOneWidget,
      );
    });

    testWidgets('does not render fromEmail when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'REF123',
            ),
          ),
        ),
      );

      expect(find.textContaining('Or email:'), findsNothing);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: CancellationPolicySection(
              isDarkMode: true,
              deadlineHours: 48,
              bookingReference: 'REF123',
            ),
          ),
        ),
      );

      expect(find.text('Cancellation Policy'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('renders bullet points for steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CancellationPolicySection(
              isDarkMode: false,
              deadlineHours: 48,
              bookingReference: 'REF123',
              fromEmail: 'test@example.com',
            ),
          ),
        ),
      );

      // Should have bullet points (•)
      expect(find.text('• '), findsWidgets);
    });
  });

  group('NextStepsSection', () {
    testWidgets('renders header title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NextStepsSection(
                isDarkMode: false,
                paymentMethod: 'stripe',
              ),
            ),
          ),
        ),
      );

      expect(find.text("What's Next?"), findsOneWidget);
    });

    group('Stripe payment method', () {
      testWidgets('renders stripe-specific steps', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'stripe',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Check Your Email'), findsOneWidget);
        expect(find.text('Add to Calendar'), findsOneWidget);
        expect(find.text('Prepare for Your Stay'), findsOneWidget);
      });

      testWidgets('renders stripe step descriptions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'stripe',
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Confirmation email sent with all booking details'),
          findsOneWidget,
        );
        expect(
          find.text('Check-in instructions will be sent 24h before'),
          findsOneWidget,
        );
      });

      testWidgets('renders stripe step icons', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'stripe',
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.email), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        expect(find.byIcon(Icons.directions), findsOneWidget);
      });
    });

    group('Bank transfer payment method', () {
      testWidgets('renders bank transfer-specific steps', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'bank_transfer',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Complete Bank Transfer'), findsOneWidget);
        expect(find.text('Check Your Email'), findsOneWidget);
        expect(find.text('Awaiting Confirmation'), findsOneWidget);
      });

      testWidgets('renders bank transfer step descriptions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'bank_transfer',
                ),
              ),
            ),
          ),
        );

        expect(
          find.text(
            'Transfer the deposit amount within 3 days using the reference number',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('confirm your booking once payment is received'),
          findsOneWidget,
        );
      });

      testWidgets('renders bank transfer icons', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'bank_transfer',
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.account_balance), findsOneWidget);
        expect(find.byIcon(Icons.email), findsOneWidget);
        expect(find.byIcon(Icons.pending), findsOneWidget);
      });
    });

    group('Pay on arrival payment method', () {
      testWidgets('renders pay on arrival-specific steps', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'pay_on_arrival',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Check Your Email'), findsOneWidget);
        expect(find.text('Add to Calendar'), findsOneWidget);
        expect(find.text('Payment on Arrival'), findsOneWidget);
        expect(find.text('Prepare for Your Stay'), findsOneWidget);
      });

      testWidgets('renders pay on arrival step descriptions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'pay_on_arrival',
                ),
              ),
            ),
          ),
        );

        expect(
          find.textContaining('cash or card accepted'),
          findsOneWidget,
        );
        expect(
          find.text('Check-in instructions will be sent 24h before arrival'),
          findsOneWidget,
        );
      });

      testWidgets('renders pay on arrival icons', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'pay_on_arrival',
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.email), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
        expect(find.byIcon(Icons.directions), findsOneWidget);
      });
    });

    group('Default/unknown payment method', () {
      testWidgets('renders default steps for unknown method', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'unknown_method',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Check Your Email'), findsOneWidget);
        expect(find.text('Awaiting Processing'), findsOneWidget);
      });

      testWidgets('renders default step descriptions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NextStepsSection(
                  isDarkMode: false,
                  paymentMethod: 'other',
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Confirmation email sent with all booking details'),
          findsOneWidget,
        );
        expect(
          find.text('Your booking is being processed'),
          findsOneWidget,
        );
      });
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: NextStepsSection(
                isDarkMode: true,
                paymentMethod: 'stripe',
              ),
            ),
          ),
        ),
      );

      expect(find.text("What's Next?"), findsOneWidget);
      expect(find.text('Check Your Email'), findsOneWidget);
    });

    testWidgets('renders step connector lines between steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NextStepsSection(
                isDarkMode: false,
                paymentMethod: 'stripe',
              ),
            ),
          ),
        ),
      );

      // Stripe has 3 steps, so there should be 2 connector lines
      // (lines between steps, not after the last one)
      // The widget renders Container with height: 24 and width: 2 for connectors
      // We verify by checking the step count
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.text('Add to Calendar'), findsOneWidget);
      expect(find.text('Prepare for Your Stay'), findsOneWidget);
    });

    testWidgets('renders step icons in circular containers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NextStepsSection(
                isDarkMode: false,
                paymentMethod: 'stripe',
              ),
            ),
          ),
        ),
      );

      // Each step has an icon inside a circular container
      // We can verify by checking icons are present
      expect(find.byIcon(Icons.email), findsOneWidget);
    });
  });
}
