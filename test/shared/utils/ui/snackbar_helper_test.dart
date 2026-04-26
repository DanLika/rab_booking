import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/utils/ui/snackbar_helper.dart'; // Adjust path if needed

void main() {
  Widget buildTestApp({
    required Brightness brightness,
    required void Function(BuildContext) onShowSnackbar,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () => onShowSnackbar(context),
                child: const Text('Show SnackBar'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('SnackBarHelper', () {
    testWidgets('showSuccess displays correct snackbar in light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.light,
          onShowSnackbar: (context) => SnackBarHelper.showSuccess(
            context: context,
            message: 'Success Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 100)); // Halfway

      expect(find.text('Success Message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.successLight));
    });

    testWidgets('showSuccess displays correct snackbar in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.dark,
          onShowSnackbar: (context) => SnackBarHelper.showSuccess(
            context: context,
            message: 'Success Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Success Message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.successDark));
    });

    testWidgets('showError displays correct snackbar in light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.light,
          onShowSnackbar: (context) => SnackBarHelper.showError(
            context: context,
            message: 'Error Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error Message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.errorLight));
    });

    testWidgets('showError displays correct snackbar in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.dark,
          onShowSnackbar: (context) => SnackBarHelper.showError(
            context: context,
            message: 'Error Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Error Message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.errorDark));
    });

    testWidgets('showWarning displays correct snackbar in light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.light,
          onShowSnackbar: (context) => SnackBarHelper.showWarning(
            context: context,
            message: 'Warning Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Warning Message'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.warningLight));
    });

    testWidgets('showWarning displays correct snackbar in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.dark,
          onShowSnackbar: (context) => SnackBarHelper.showWarning(
            context: context,
            message: 'Warning Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Warning Message'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.warningDark));
    });

    testWidgets('showInfo displays correct snackbar in light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.light,
          onShowSnackbar: (context) => SnackBarHelper.showInfo(
            context: context,
            message: 'Info Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Info Message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.infoLight));
    });

    testWidgets('showInfo displays correct snackbar in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          brightness: Brightness.dark,
          onShowSnackbar: (context) => SnackBarHelper.showInfo(
            context: context,
            message: 'Info Message',
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Info Message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, equals(SnackBarColors.infoDark));
    });

    testWidgets('consecutive calls hide the previous snackbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        key: const Key('btn1'),
                        onPressed: () => SnackBarHelper.showSuccess(
                          context: context,
                          message: 'First Message',
                        ),
                        child: const Text('Show 1'),
                      ),
                      ElevatedButton(
                        key: const Key('btn2'),
                        onPressed: () => SnackBarHelper.showInfo(
                          context: context,
                          message: 'Second Message',
                        ),
                        child: const Text('Show 2'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Tap first button
      await tester.tap(find.byKey(const Key('btn1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('First Message'), findsOneWidget);

      // Tap second button immediately
      await tester.tap(find.byKey(const Key('btn2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // First snackbar should be hiding (or gone), second should be visible
      // By the time second is pumped with 100ms, the first might still be in the widget tree animating out,
      // but its text might not be found if it was immediately removed or hidden.
      // ScaffoldMessenger.hideCurrentSnackBar() immediately stops showing the previous one.
      await tester.pumpAndSettle();
      expect(find.text('First Message'), findsNothing);
      expect(find.text('Second Message'), findsOneWidget);
    });
  });
}
