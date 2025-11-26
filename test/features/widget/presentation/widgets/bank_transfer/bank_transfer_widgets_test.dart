import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/domain/models/widget_settings.dart';
import 'package:rab_booking/features/widget/presentation/widgets/bank_transfer/bank_details_section.dart';
import 'package:rab_booking/features/widget/presentation/widgets/bank_transfer/payment_warning_section.dart';
import 'package:rab_booking/features/widget/presentation/widgets/bank_transfer/important_notes_section.dart';
import 'package:rab_booking/features/widget/presentation/widgets/bank_transfer/qr_code_payment_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BankDetailsSection', () {
    BankTransferConfig createConfig({
      String? accountHolder,
      String? bankName,
      String? iban,
      String? swift,
      String? accountNumber,
    }) {
      return BankTransferConfig(
        enabled: true,
        accountHolder: accountHolder,
        bankName: bankName,
        iban: iban,
        swift: swift,
        accountNumber: accountNumber,
      );
    }

    testWidgets('renders header with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: createConfig(
                accountHolder: 'Test User',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Podaci za Uplatu'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('renders account holder when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: createConfig(
                accountHolder: 'John Doe',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Vlasnik Računa'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('renders bank name when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: createConfig(
                bankName: 'Test Bank',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Naziv Banke'), findsOneWidget);
      expect(find.text('Test Bank'), findsOneWidget);
    });

    testWidgets('renders IBAN when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: createConfig(
                iban: 'HR1234567890123456789',
              ),
            ),
          ),
        ),
      );

      expect(find.text('IBAN'), findsOneWidget);
      expect(find.text('HR1234567890123456789'), findsOneWidget);
    });

    testWidgets('renders SWIFT when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: createConfig(
                swift: 'TESTHR2X',
              ),
            ),
          ),
        ),
      );

      expect(find.text('SWIFT/BIC'), findsOneWidget);
      expect(find.text('TESTHR2X'), findsOneWidget);
    });

    testWidgets('renders account number when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: createConfig(
                accountNumber: '1234567890',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Broj Računa'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });

    testWidgets('does not render fields when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: false,
              bankConfig: const BankTransferConfig(enabled: true),
            ),
          ),
        ),
      );

      expect(find.text('Vlasnik Računa'), findsNothing);
      expect(find.text('Naziv Banke'), findsNothing);
      expect(find.text('IBAN'), findsNothing);
      expect(find.text('SWIFT/BIC'), findsNothing);
      expect(find.text('Broj Računa'), findsNothing);
    });

    testWidgets('renders all fields when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BankDetailsSection(
                isDarkMode: false,
                bankConfig: createConfig(
                  accountHolder: 'John Doe',
                  bankName: 'Test Bank',
                  iban: 'HR1234567890123456789',
                  swift: 'TESTHR2X',
                  accountNumber: '1234567890',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Test Bank'), findsOneWidget);
      expect(find.text('HR1234567890123456789'), findsOneWidget);
      expect(find.text('TESTHR2X'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BankDetailsSection(
              isDarkMode: true,
              bankConfig: createConfig(
                accountHolder: 'Test User',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Podaci za Uplatu'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });
  });

  group('PaymentWarningSection', () {
    testWidgets('renders deposit amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentWarningSection(
              isDarkMode: false,
              depositAmount: '€50.00',
              deadline: '3 dana',
            ),
          ),
        ),
      );

      expect(find.text('Uplata: €50.00'), findsOneWidget);
    });

    testWidgets('renders deadline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentWarningSection(
              isDarkMode: false,
              depositAmount: '€50.00',
              deadline: '3 dana',
            ),
          ),
        ),
      );

      expect(find.text('Rok: 3 dana'), findsOneWidget);
    });

    testWidgets('renders warning icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentWarningSection(
              isDarkMode: false,
              depositAmount: '€50.00',
              deadline: '3 dana',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: PaymentWarningSection(
              isDarkMode: true,
              depositAmount: '€100.00',
              deadline: '5 dana',
            ),
          ),
        ),
      );

      expect(find.text('Uplata: €100.00'), findsOneWidget);
      expect(find.text('Rok: 5 dana'), findsOneWidget);
    });

    testWidgets('renders with different amounts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentWarningSection(
              isDarkMode: false,
              depositAmount: '€250.75',
              deadline: '24 sata',
            ),
          ),
        ),
      );

      expect(find.text('Uplata: €250.75'), findsOneWidget);
      expect(find.text('Rok: 24 sata'), findsOneWidget);
    });
  });

  group('ImportantNotesSection', () {
    testWidgets('renders header with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImportantNotesSection(
              isDarkMode: false,
              bankConfig: null,
              remainingAmount: '€80.00',
            ),
          ),
        ),
      );

      expect(find.text('Važne Informacije'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders default notes when bankConfig is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImportantNotesSection(
                isDarkMode: false,
                bankConfig: null,
                remainingAmount: '€80.00',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Obavezno navedite referentni broj u opisu uplate'),
        findsOneWidget,
      );
      expect(
        find.text('Primit ćete email potvrdu nakon što uplata bude zaprimljena'),
        findsOneWidget,
      );
      expect(
        find.text('Preostali iznos (€80.00) plaća se po dolasku'),
        findsOneWidget,
      );
    });

    testWidgets('renders default notes when useCustomNotes is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImportantNotesSection(
                isDarkMode: false,
                bankConfig: BankTransferConfig(
                  enabled: true,
                  useCustomNotes: false,
                ),
                remainingAmount: '€120.00',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Preostali iznos (€120.00) plaća se po dolasku'),
        findsOneWidget,
      );
    });

    testWidgets('renders custom notes when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImportantNotesSection(
              isDarkMode: false,
              bankConfig: BankTransferConfig(
                enabled: true,
                useCustomNotes: true,
                customNotes: 'Ovo je prilagođena poruka za kupce.',
              ),
              remainingAmount: '€80.00',
            ),
          ),
        ),
      );

      expect(
        find.text('Ovo je prilagođena poruka za kupce.'),
        findsOneWidget,
      );
      // Should not show default notes
      expect(
        find.text('Obavezno navedite referentni broj u opisu uplate'),
        findsNothing,
      );
    });

    testWidgets('renders default notes when custom notes empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImportantNotesSection(
                isDarkMode: false,
                bankConfig: BankTransferConfig(
                  enabled: true,
                  useCustomNotes: true,
                  customNotes: '', // Empty custom notes
                ),
                remainingAmount: '€50.00',
              ),
            ),
          ),
        ),
      );

      // Should show default notes because custom is empty
      expect(
        find.text('Preostali iznos (€50.00) plaća se po dolasku'),
        findsOneWidget,
      );
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ImportantNotesSection(
              isDarkMode: true,
              bankConfig: null,
              remainingAmount: '€100.00',
            ),
          ),
        ),
      );

      expect(find.text('Važne Informacije'), findsOneWidget);
    });
  });

  group('QrCodePaymentSection', () {
    BankTransferConfig createConfig({
      String? iban = 'HR1234567890123456789',
      String? swift = 'TESTHR2X',
      String? accountHolder = 'Test User',
    }) {
      return BankTransferConfig(
        enabled: true,
        iban: iban,
        swift: swift,
        accountHolder: accountHolder,
      );
    }

    testWidgets('renders header with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QrCodePaymentSection(
                isDarkMode: false,
                bankConfig: createConfig(),
                amount: 100.0,
                bookingReference: 'REF123',
              ),
            ),
          ),
        ),
      );

      expect(find.text('QR Kod za Uplatu'), findsOneWidget);
      expect(find.text('Skenirajte sa mobilnom bankom'), findsOneWidget);
    });

    testWidgets('renders QR code icon in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QrCodePaymentSection(
                isDarkMode: false,
                bankConfig: createConfig(),
                amount: 100.0,
                bookingReference: 'REF123',
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    });

    testWidgets('renders info banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QrCodePaymentSection(
                isDarkMode: false,
                bankConfig: createConfig(),
                amount: 100.0,
                bookingReference: 'REF123',
              ),
            ),
          ),
        ),
      );

      expect(
        find.textContaining('QR kod sadrži sve podatke o uplati'),
        findsOneWidget,
      );
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: QrCodePaymentSection(
                isDarkMode: true,
                bankConfig: createConfig(),
                amount: 150.0,
                bookingReference: 'REF456',
              ),
            ),
          ),
        ),
      );

      expect(find.text('QR Kod za Uplatu'), findsOneWidget);
    });

    testWidgets('renders with different amounts and references', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QrCodePaymentSection(
                isDarkMode: false,
                bankConfig: createConfig(),
                amount: 299.99,
                bookingReference: 'BOOKING-2025-001',
              ),
            ),
          ),
        ),
      );

      // Widget renders successfully with custom values
      expect(find.text('QR Kod za Uplatu'), findsOneWidget);
    });
  });
}
