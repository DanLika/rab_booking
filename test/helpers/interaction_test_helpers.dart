import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helpers for testing user interactions and flows
class InteractionTestHelpers {
  InteractionTestHelpers._();

  // ============================================================================
  // FORM INTERACTION HELPERS
  // ============================================================================

  /// Enter text into a text field
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Tap a widget and wait for animations
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Scroll until widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100.0,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }

  /// Long press a widget
  static Future<void> longPress(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// Drag widget by offset
  static Future<void> drag(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  // ============================================================================
  // FORM VALIDATION HELPERS
  // ============================================================================

  /// Fill form field and verify validation
  static Future<void> testFieldValidation(
    WidgetTester tester, {
    required Finder field,
    required String validInput,
    required String invalidInput,
    required String expectedError,
  }) async {
    // Test invalid input
    await enterText(tester, field, invalidInput);

    // Try to submit or trigger validation
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify error message appears
    expect(find.text(expectedError), findsOneWidget);

    // Test valid input
    await enterText(tester, field, validInput);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify error message disappears
    expect(find.text(expectedError), findsNothing);
  }

  /// Test complete form submission
  static Future<void> submitForm(
    WidgetTester tester, {
    required Map<Finder, String> fields,
    required Finder submitButton,
  }) async {
    // Fill all fields
    for (final entry in fields.entries) {
      await enterText(tester, entry.key, entry.value);
    }

    // Submit form
    await tapAndSettle(tester, submitButton);
  }

  // ============================================================================
  // NAVIGATION HELPERS
  // ============================================================================

  /// Navigate to route and verify
  static Future<void> navigateToRoute(
    WidgetTester tester,
    Finder navigationTrigger,
    Type expectedScreen,
  ) async {
    await tapAndSettle(tester, navigationTrigger);
    expect(find.byType(expectedScreen), findsOneWidget);
  }

  /// Navigate back and verify
  static Future<void> navigateBack(
    WidgetTester tester,
    Type expectedScreen,
  ) async {
    // Find back button (app bar back button or custom)
    final backButton = find.byTooltip('Back');
    if (tester.any(backButton)) {
      await tapAndSettle(tester, backButton);
    } else {
      // Simulate system back navigation
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    expect(find.byType(expectedScreen), findsOneWidget);
  }

  /// Test complete navigation flow
  static Future<void> testNavigationFlow(
    WidgetTester tester,
    List<NavigationStep> steps,
  ) async {
    for (final step in steps) {
      await tapAndSettle(tester, step.trigger);
      expect(find.byType(step.expectedScreen), findsOneWidget);

      if (step.verification != null) {
        await step.verification!(tester);
      }
    }
  }

  // ============================================================================
  // STATE TESTING HELPERS
  // ============================================================================

  /// Wait for loading state to complete
  static Future<void> waitForLoading(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));

      // Check if loading indicator is gone
      if (!tester.any(find.byType(CircularProgressIndicator))) {
        await tester.pumpAndSettle();
        return;
      }
    }

    throw Exception('Loading did not complete within timeout');
  }

  /// Verify error state is displayed
  static void verifyErrorState(
    WidgetTester tester, {
    String? errorMessage,
    Type? errorWidget,
  }) {
    if (errorWidget != null) {
      expect(find.byType(errorWidget), findsOneWidget);
    }

    if (errorMessage != null) {
      expect(find.text(errorMessage), findsOneWidget);
    }
  }

  /// Verify empty state is displayed
  static void verifyEmptyState(
    WidgetTester tester, {
    String? emptyMessage,
  }) {
    if (emptyMessage != null) {
      expect(find.textContaining(emptyMessage), findsOneWidget);
    }
  }

  // ============================================================================
  // GESTURE HELPERS
  // ============================================================================

  /// Simulate swipe gesture
  static Future<void> swipe(
    WidgetTester tester,
    Finder finder,
    AxisDirection direction, {
    double distance = 300.0,
  }) async {
    final offset = switch (direction) {
      AxisDirection.left => Offset(-distance, 0),
      AxisDirection.right => Offset(distance, 0),
      AxisDirection.up => Offset(0, -distance),
      AxisDirection.down => Offset(0, distance),
    };

    await drag(tester, finder, offset);
  }

  /// Simulate pinch to zoom
  static Future<void> pinchZoom(
    WidgetTester tester,
    Finder finder, {
    double scale = 2.0,
  }) async {
    // Get widget center
    final center = tester.getCenter(finder);

    // Create gesture for pinch
    final gesture1 = await tester.startGesture(center);
    final gesture2 = await tester.startGesture(center);

    // Move gestures apart
    await gesture1.moveBy(Offset(-50 * scale, 0));
    await gesture2.moveBy(Offset(50 * scale, 0));

    await tester.pumpAndSettle();

    // Release
    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();
  }

  // ============================================================================
  // ANIMATION TESTING HELPERS
  // ============================================================================

  /// Verify animation is running smoothly
  static Future<void> verifyAnimation(
    WidgetTester tester, {
    required Duration duration,
    int minFrames = 10,
  }) async {
    int frameCount = 0;
    final endTime = DateTime.now().add(duration);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 16)); // ~60fps
      frameCount++;
    }

    expect(frameCount, greaterThanOrEqualTo(minFrames));
  }

  /// Wait for animation to complete
  static Future<void> waitForAnimation(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await tester.pumpAndSettle(timeout);
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Navigation step for flow testing
class NavigationStep {
  final Finder trigger;
  final Type expectedScreen;
  final Future<void> Function(WidgetTester)? verification;

  NavigationStep({
    required this.trigger,
    required this.expectedScreen,
    this.verification,
  });
}

/// Form field configuration for testing
class FormFieldConfig {
  final Finder field;
  final String validInput;
  final String invalidInput;
  final String errorMessage;

  FormFieldConfig({
    required this.field,
    required this.validInput,
    required this.invalidInput,
    required this.errorMessage,
  });
}
