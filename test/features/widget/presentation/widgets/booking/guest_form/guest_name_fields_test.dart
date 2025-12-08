import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/guest_form/guest_name_fields.dart';

void main() {
  group('GuestNameFields', () {
    late TextEditingController firstNameController;
    late TextEditingController lastNameController;

    setUp(() {
      firstNameController = TextEditingController();
      lastNameController = TextEditingController();
    });

    tearDown(() {
      firstNameController.dispose();
      lastNameController.dispose();
    });

    testWidgets('renders two text fields in a row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('renders first name and last name labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('First Name *'), findsOneWidget);
      expect(find.text('Last Name *'), findsOneWidget);
    });

    testWidgets('renders person icon for first name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(GuestNameFields), findsOneWidget);
    });

    testWidgets('accepts text input for first name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'John');
      expect(firstNameController.text, 'John');
    });

    testWidgets('accepts text input for last name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).last, 'Doe');
      expect(lastNameController.text, 'Doe');
    });

    testWidgets('fields are expanded equally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuestNameFields(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              isDarkMode: false,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.whereType<Expanded>().length, 2);
    });
  });
}
