import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rab_booking/main.dart' as app;

/// Integration test for complete booking flow
/// Tests: Home → Search → Property Details → Booking → Payment
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Flow Integration Tests', () {
    testWidgets('Complete booking flow from search to confirmation',
        (WidgetTester tester) async {
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle();

      // 2. Verify home screen loaded
      expect(find.text('Pronađi savršen smještaj'), findsOneWidget);

      // 3. Enter search location
      final locationField = find.byType(TextField).first;
      await tester.tap(locationField);
      await tester.pumpAndSettle();
      await tester.enterText(locationField, 'Rab');
      await tester.pumpAndSettle();

      // 4. Select dates (if date picker present)
      final checkInField = find.text('Check-in');
      if (checkInField.evaluate().isNotEmpty) {
        await tester.tap(checkInField);
        await tester.pumpAndSettle();

        // Select date 7 days from now
        final today = DateTime.now();
        final checkInDate = today.add(const Duration(days: 7));
        await tester.tap(find.text('${checkInDate.day}'));
        await tester.pumpAndSettle();

        // Select check-out (3 days after check-in)
        final checkOutDate = checkInDate.add(const Duration(days: 3));
        await tester.tap(find.text('${checkOutDate.day}'));
        await tester.pumpAndSettle();

        // Confirm dates
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      // 5. Select guests
      final guestsField = find.text('Gosti');
      if (guestsField.evaluate().isNotEmpty) {
        await tester.tap(guestsField);
        await tester.pumpAndSettle();

        // Increment guests to 2
        final incrementButton = find.byIcon(Icons.add);
        if (incrementButton.evaluate().isNotEmpty) {
          await tester.tap(incrementButton);
          await tester.pumpAndSettle();
        }

        // Close guests selector
        await tester.tap(find.text('Potvrdi'));
        await tester.pumpAndSettle();
      }

      // 6. Submit search
      final searchButton = find.widgetWithText(ElevatedButton, 'Pretraži');
      await tester.tap(searchButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 7. Verify search results screen
      expect(find.text('Rezultati pretrage'), findsOneWidget);

      // 8. Wait for results to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 9. Tap on first property card
      final firstProperty = find.byType(Card).first;
      await tester.tap(firstProperty);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 10. Verify property details screen
      expect(find.text('Detalji smještaja'), findsOneWidget);

      // 11. Scroll to booking section
      await tester.dragUntilVisible(
        find.text('Rezerviraj'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // 12. Tap "Book Now" button
      final bookButton = find.widgetWithText(ElevatedButton, 'Rezerviraj');
      await tester.tap(bookButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 13. Verify booking review screen
      expect(find.text('Pregled rezervacije'), findsOneWidget);

      // 14. Verify booking details displayed
      expect(find.text('Check-in:'), findsOneWidget);
      expect(find.text('Check-out:'), findsOneWidget);
      expect(find.text('Gosti:'), findsOneWidget);
      expect(find.text('Ukupno:'), findsOneWidget);

      // 15. Enter guest details (if required)
      final firstNameField = find.widgetWithText(TextField, 'Ime');
      if (firstNameField.evaluate().isNotEmpty) {
        await tester.enterText(firstNameField, 'Marko');
        await tester.pumpAndSettle();

        final lastNameField = find.widgetWithText(TextField, 'Prezime');
        await tester.enterText(lastNameField, 'Horvat');
        await tester.pumpAndSettle();

        final emailField = find.widgetWithText(TextField, 'Email');
        await tester.enterText(emailField, 'marko@example.com');
        await tester.pumpAndSettle();

        final phoneField = find.widgetWithText(TextField, 'Telefon');
        await tester.enterText(phoneField, '+385912345678');
        await tester.pumpAndSettle();
      }

      // 16. Scroll to continue button
      await tester.dragUntilVisible(
        find.text('Nastavi na plaćanje'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // 17. Tap "Continue to Payment"
      final continueButton =
          find.widgetWithText(ElevatedButton, 'Nastavi na plaćanje');
      await tester.tap(continueButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 18. Verify payment screen
      expect(find.text('Plaćanje'), findsOneWidget);

      // 19. Verify payment methods displayed
      expect(
        find.byType(RadioListTile<String>),
        findsWidgets,
      ); // Card, PayPal, etc.

      // 20. Select credit card payment
      final cardPayment = find.widgetWithText(RadioListTile, 'Kreditna kartica');
      if (cardPayment.evaluate().isNotEmpty) {
        await tester.tap(cardPayment);
        await tester.pumpAndSettle();
      }

      // 21. Enter card details (in test mode)
      final cardNumberField = find.widgetWithText(TextField, 'Broj kartice');
      if (cardNumberField.evaluate().isNotEmpty) {
        await tester.enterText(cardNumberField, '4242424242424242');
        await tester.pumpAndSettle();

        final expiryField = find.widgetWithText(TextField, 'MM/GG');
        await tester.enterText(expiryField, '12/25');
        await tester.pumpAndSettle();

        final cvvField = find.widgetWithText(TextField, 'CVV');
        await tester.enterText(cvvField, '123');
        await tester.pumpAndSettle();
      }

      // 22. Scroll to pay button
      await tester.dragUntilVisible(
        find.text('Plati'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // 23. Tap "Pay Now" button
      final payButton = find.widgetWithText(ElevatedButton, 'Plati');
      await tester.tap(payButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 24. Verify payment processing
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );

      // 25. Wait for payment confirmation
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 26. Verify booking confirmation screen
      expect(find.text('Rezervacija potvrđena'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // 27. Verify booking reference displayed
      expect(find.textContaining('Broj rezervacije:'), findsOneWidget);

      // 28. Verify confirmation email message
      expect(
        find.textContaining('Potvrda je poslana na email'),
        findsOneWidget,
      );

      // 29. Tap "View Booking" button
      final viewBookingButton =
          find.widgetWithText(ElevatedButton, 'Pogledaj rezervaciju');
      await tester.tap(viewBookingButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 30. Verify booking details screen
      expect(find.text('Detalji rezervacije'), findsOneWidget);

      // 31. Verify booking status is "Confirmed"
      expect(find.text('Potvrđeno'), findsOneWidget);

      // Test completed successfully
    });

    testWidgets('Search with filters and sorting', (WidgetTester tester) async {
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle();

      // 2. Navigate to search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 3. Open filters
      final filterButton = find.byIcon(Icons.filter_list);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // 4. Set price range
      final priceRangeSlider = find.byType(RangeSlider);
      if (priceRangeSlider.evaluate().isNotEmpty) {
        // Interact with slider (simplified - would need custom drag in real test)
        await tester.pumpAndSettle();
      }

      // 5. Select property type
      final apartmentChip = find.text('Apartman');
      if (apartmentChip.evaluate().isNotEmpty) {
        await tester.tap(apartmentChip);
        await tester.pumpAndSettle();
      }

      // 6. Select amenities
      final wifiCheckbox = find.text('WiFi');
      if (wifiCheckbox.evaluate().isNotEmpty) {
        await tester.tap(wifiCheckbox);
        await tester.pumpAndSettle();
      }

      // 7. Apply filters
      final applyButton = find.text('Primijeni filtere');
      await tester.tap(applyButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 8. Verify results updated
      expect(find.text('Rezultati pretrage'), findsOneWidget);

      // 9. Open sort menu
      final sortButton = find.byIcon(Icons.sort);
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // 10. Select sort by price (low to high)
      final sortByPrice = find.text('Cijena: Niska → Visoka');
      await tester.tap(sortByPrice);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 11. Verify results re-sorted
      // First property should have lowest price
      // (Would verify with actual price values in real test)

      // 12. Test view mode toggle
      final listViewButton = find.byIcon(Icons.view_list);
      if (listViewButton.evaluate().isNotEmpty) {
        await tester.tap(listViewButton);
        await tester.pumpAndSettle();

        // Verify layout changed to list view
        // (Visual verification)
      }
    });

    testWidgets('Test infinite scroll pagination', (WidgetTester tester) async {
      // 1. Launch app and navigate to search results
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search with results
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 2. Count initial results
      final initialResults = find.byType(Card);
      final initialCount = initialResults.evaluate().length;

      // 3. Scroll to bottom (80% threshold)
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      // 4. Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 5. Wait for more results to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 6. Count new results
      final newResults = find.byType(Card);
      final newCount = newResults.evaluate().length;

      // 7. Verify more results loaded
      expect(newCount, greaterThan(initialCount));

      // 8. Scroll to bottom again
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 9. Verify additional results loaded (if available)
      final finalResults = find.byType(Card);
      final finalCount = finalResults.evaluate().length;

      expect(finalCount, greaterThanOrEqualTo(newCount));
    });

    testWidgets('Test error handling and retry', (WidgetTester tester) async {
      // This test requires mocking network failures
      // In real implementation, would use mock HTTP client

      // 1. Launch app
      app.main();
      await tester.pumpAndSettle();

      // 2. Simulate network error by going offline
      // (Would require platform channel or mock)

      // 3. Try to load search results
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 4. Verify error message displayed
      expect(
        find.textContaining('Greška'),
        findsOneWidget,
      );

      // 5. Verify retry button present
      expect(
        find.widgetWithText(ElevatedButton, 'Pokušaj ponovo'),
        findsOneWidget,
      );

      // 6. Simulate network restored
      // (Would require platform channel or mock)

      // 7. Tap retry button
      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 8. Verify results loaded successfully
      expect(find.text('Rezultati pretrage'), findsOneWidget);
    });
  });
}
