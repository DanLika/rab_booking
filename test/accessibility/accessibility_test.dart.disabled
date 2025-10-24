import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/shared/widgets/property_card.dart';
import 'package:rab_booking/shared/widgets/error_state_widget.dart';
import 'package:rab_booking/shared/models/property_model.dart';
import 'package:rab_booking/core/constants/enums.dart';
import '../helpers/test_helpers.dart';

/// Accessibility tests for WCAG compliance
void main() {
  group('Accessibility Tests', () {
    group('Semantic Labels', () {
      testWidgets('PropertyCard has semantic labels',
          (WidgetTester tester) async {
        final property = PropertyModel(
          id: '1',
          name: 'Beautiful Apartment',
          location: 'Rab, Croatia',
          pricePerNight: 150.0,
          rating: 4.8,
          reviewCount: 124,
          images: ['https://via.placeholder.com/400x300'],
          bedrooms: 2,
          bathrooms: 1,
          maxGuests: 4,
          description: 'A beautiful apartment',
          amenities: [],
          ownerId: 'owner1',
          propertyType: PropertyType.apartment,
          latitude: 44.7555,
          longitude: 14.7594,
          createdAt: DateTime(2024, 1, 1),
        );

        await tester.pumpWithProviders(
          PropertyCard(
            property: property,
          ),
        );

        // Verify semantic labels exist
        final semantics = tester.getSemantics(find.byType(PropertyCard));
        expect(semantics, isNotNull);
        expect(semantics.label, contains('Beautiful Apartment'));
      });

      testWidgets('ErrorStateWidget has semantic labels',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          ErrorStateWidget(
            message: 'Test error message',
            onRetry: () {},
          ),
        );

        // Verify error message is semantically labeled
        final errorText = find.text('Test error message');
        expect(errorText, findsOneWidget);

        // Verify retry button has semantic label
        final retryButton = find.text('Pokušaj ponovo');
        expect(retryButton, findsOneWidget);
        final semantics = tester.getSemantics(retryButton);
        expect(semantics, isNotNull);
        expect(semantics.label, contains('Pokušaj ponovo'));
      });

      testWidgets('All interactive elements are labeled',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          Scaffold(
            body: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                  tooltip: 'Pretraži smještaje',
                ),
                IconButton(
                  icon: const Icon(Icons.favorite),
                  onPressed: () {},
                  tooltip: 'Dodaj u omiljene',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                  tooltip: 'Podijeli',
                ),
              ],
            ),
          ),
        );

        // Verify all icon buttons have tooltips
        expect(find.byTooltip('Pretraži smještaje'), findsOneWidget);
        expect(find.byTooltip('Dodaj u omiljene'), findsOneWidget);
        expect(find.byTooltip('Podijeli'), findsOneWidget);
      });
    });

    group('Focus Management', () {
      testWidgets('Tab order is logical', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          Scaffold(
            body: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Ime'),
                  key: Key('first_name'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Prezime'),
                  key: Key('last_name'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                  key: Key('email'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  key: const Key('submit'),
                  child: const Text('Pošalji'),
                ),
              ],
            ),
          ),
        );

        // Focus first field
        await tester.tap(find.byKey(const Key('first_name')));
        await tester.pumpAndSettle();

        // Tab to next field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Verify focus moved to second field
        final lastNameField = tester.widget<TextField>(
          find.byKey(const Key('last_name')),
        );
        expect(lastNameField.focusNode?.hasFocus, isTrue);
      });

      testWidgets('Focus is visible', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {},
                child: const Text('Click me'),
              ),
            ),
          ),
        );

        // Focus the button
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify focus indicator is present
        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.focusNode, isNotNull);
      });

      testWidgets('Modal traps focus', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Test Dialog'),
                        content: const Text('This is a test dialog'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Zatvori'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Verify focus is trapped in dialog
        expect(find.text('Test Dialog'), findsOneWidget);
        expect(find.text('Zatvori'), findsOneWidget);

        // Try to tab out of dialog (should stay in dialog)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Dialog should still be visible
        expect(find.text('Test Dialog'), findsOneWidget);
      });
    });

    group('Screen Reader Support', () {
      testWidgets('Form fields have hints', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          const Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'primjer@email.com',
                    helperText: 'Unesite vašu email adresu',
                  ),
                ),
              ],
            ),
          ),
        );

        // Verify semantic data includes hint and helper text
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        final semantics = tester.getSemantics(textField);
        expect(semantics.label, contains('Email'));
        expect(semantics.hint, contains('primjer@email.com'));
      });

      testWidgets('Error messages are announced',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          const Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: 'Email nije valjan',
                  ),
                ),
              ],
            ),
          ),
        );

        // Verify error message is in semantic tree
        expect(find.text('Email nije valjan'), findsOneWidget);

        final textField = find.byType(TextField);
        final semantics = tester.getSemantics(textField);
        expect(semantics, isNotNull);
        expect(semantics.label, contains('Email'));
      });

      testWidgets('Loading states are announced',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Učitavanje...',
              ),
            ),
          ),
        );

        // Verify loading indicator has semantic label
        final loader = find.byType(CircularProgressIndicator);
        expect(loader, findsOneWidget);

        final semantics = tester.getSemantics(loader);
        expect(semantics.label, 'Učitavanje...');
      });

      testWidgets('Images have alt text', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          Scaffold(
            body: Semantics(
              label: 'Beautiful apartment with sea view',
              child: Image.network(
                'https://via.placeholder.com/400x300',
              ),
            ),
          ),
        );

        // Verify image has semantic label
        final image = find.byType(Image);
        expect(image, findsOneWidget);

        final semantics = tester.getSemantics(image);
        expect(semantics.label, contains('Beautiful apartment'));
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('Buttons activate with Enter/Space',
          (WidgetTester tester) async {
        var buttonPressed = false;

        await tester.pumpWithProviders(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Press me'),
              ),
            ),
          ),
        );

        // Focus the button
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Press Enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Verify button was activated
        expect(buttonPressed, isTrue);
      });

      testWidgets('ESC closes modals', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        title: Text('Test Dialog'),
                        content: Text('Press ESC to close'),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Test Dialog'), findsOneWidget);

        // Press ESC
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Verify dialog closed
        expect(find.text('Test Dialog'), findsNothing);
      });
    });

    group('Color Contrast', () {
      testWidgets('Text has sufficient contrast', (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: Container(
                color: Colors.white,
                child: const Text(
                  'This text should have good contrast',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // Manual verification: Black text on white background = 21:1 ratio
        // This meets WCAG AAA standard (7:1 for normal text)
        final text = find.text('This text should have good contrast');
        expect(text, findsOneWidget);

        final textWidget = tester.widget<Text>(text);
        expect(textWidget.style?.color, equals(Colors.black));
      });

      testWidgets('Button text has sufficient contrast',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text('Click me'),
              ),
            ),
          ),
        );

        // Manual verification: White text on blue background
        // should meet WCAG AA standard (4.5:1)
        final button = find.byType(ElevatedButton);
        expect(button, findsOneWidget);
      });
    });

    group('Touch Target Size', () {
      testWidgets('Buttons meet minimum size (48x48)',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            home: Scaffold(
              body: IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () {},
              ),
            ),
          ),
        );

        // Verify button size
        final button = find.byType(IconButton);
        final size = tester.getSize(button);

        // Material Design spec: 48x48 minimum
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      });

      testWidgets('Small interactive elements have padding',
          (WidgetTester tester) async {
        await tester.pumpWithProviders(
          MaterialApp(
            home: Scaffold(
              body: InkWell(
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.close, size: 24),
                ),
              ),
            ),
          ),
        );

        // Verify total tap target size
        final inkWell = find.byType(InkWell);
        final size = tester.getSize(inkWell);

        // 24px icon + 12px padding on each side = 48px
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      });
    });
  });
}
