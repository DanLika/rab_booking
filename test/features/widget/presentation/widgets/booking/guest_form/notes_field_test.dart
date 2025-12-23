import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookbed/features/widget/presentation/widgets/booking/guest_form/notes_field.dart';

void main() {
  group('NotesField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders text form field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotesField(controller: controller, isDarkMode: false),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders notes icon prefix', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotesField(controller: controller, isDarkMode: false),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notes), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotesField(controller: controller, isDarkMode: false),
            ),
          ),
        ),
      );

      expect(find.text('Special Requests (Optional)'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotesField(controller: controller, isDarkMode: true),
            ),
          ),
        ),
      );

      expect(find.byType(NotesField), findsOneWidget);
    });

    testWidgets('accepts multi-line text input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotesField(controller: controller, isDarkMode: false),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'Line 1\nLine 2\nLine 3',
      );
      expect(controller.text, 'Line 1\nLine 2\nLine 3');
    });

    testWidgets('is optional field (no validator)', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: NotesField(controller: controller, isDarkMode: false),
              ),
            ),
          ),
        ),
      );

      // Empty field should pass validation (it's optional)
      expect(formKey.currentState?.validate(), true);
    });
  });
}
