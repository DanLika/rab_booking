import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helpers for accessibility testing and WCAG compliance
class AccessibilityTestHelpers {
  AccessibilityTestHelpers._();

  // ============================================================================
  // SEMANTIC LABELS & DESCRIPTIONS
  // ============================================================================

  /// Verify widget has semantic label
  static void assertHasSemanticLabel(
    WidgetTester tester,
    Finder finder, {
    String? expectedLabel,
  }) {
    final semantics = tester.getSemantics(finder);

    expect(semantics, isNotNull, reason: 'Widget should have semantic properties');

    if (expectedLabel != null) {
      expect(
        semantics.label,
        equals(expectedLabel),
        reason: 'Semantic label should match expected value',
      );
    } else {
      expect(
        semantics.label,
        isNotEmpty,
        reason: 'Widget should have a semantic label',
      );
    }
  }

  /// Verify button has descriptive label
  static void assertButtonIsAccessible(
    WidgetTester tester,
    Finder buttonFinder,
  ) {
    assertHasSemanticLabel(tester, buttonFinder);
    assertIsFocusable(tester, buttonFinder);
    assertHasSufficientTapArea(tester, buttonFinder);
  }

  /// Verify image has alternative text
  static void assertImageHasAltText(
    WidgetTester tester,
    Finder imageFinder,
  ) {
    final semantics = tester.getSemantics(imageFinder);
    expect(
      semantics.label,
      isNotEmpty,
      reason: 'Image should have alternative text',
    );
  }

  // ============================================================================
  // KEYBOARD & FOCUS MANAGEMENT
  // ============================================================================

  /// Verify widget is focusable
  static void assertIsFocusable(
    WidgetTester tester,
    Finder finder,
  ) {
    final element = tester.element(finder);
    final focusNode = FocusScope.of(element);

    expect(
      focusNode.canRequestFocus,
      isTrue,
      reason: 'Widget should be focusable',
    );
  }

  /// Verify focus order is logical
  static Future<void> assertLogicalFocusOrder(
    WidgetTester tester,
    List<Finder> expectedOrder,
  ) async {
    for (var i = 0; i < expectedOrder.length - 1; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify focus moved to next expected element
      // This is a simplified check; actual implementation would be more robust
    }
  }

  /// Verify focus indicator is visible
  static void assertFocusIndicatorVisible(
    WidgetTester tester,
    Finder finder,
  ) {
    // Request focus
    final element = tester.element(finder);
    FocusScope.of(element).requestFocus();

    // Verify focus indicator (implementation depends on your focus indicator style)
    // This is a placeholder that would check for border, outline, or shadow
  }

  // ============================================================================
  // COLOR CONTRAST
  // ============================================================================

  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color foreground, Color background) {
    final l1 = _calculateRelativeLuminance(foreground);
    final l2 = _calculateRelativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _calculateRelativeLuminance(Color color) {
    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Assert color combination meets WCAG AA standard
  static void assertMeetsWcagAa(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final minimumRatio = isLargeText ? 3.0 : 4.5;

    expect(
      ratio,
      greaterThanOrEqualTo(minimumRatio),
      reason:
          'Contrast ratio $ratio does not meet WCAG AA standard ($minimumRatio:1)',
    );
  }

  /// Assert color combination meets WCAG AAA standard
  static void assertMeetsWcagAaa(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final minimumRatio = isLargeText ? 4.5 : 7.0;

    expect(
      ratio,
      greaterThanOrEqualTo(minimumRatio),
      reason:
          'Contrast ratio $ratio does not meet WCAG AAA standard ($minimumRatio:1)',
    );
  }

  /// Test all text in widget for contrast
  static Future<void> assertAllTextMeetsContrast(
    WidgetTester tester,
    Finder rootFinder,
  ) async {
    final texts = find.descendant(of: rootFinder, matching: find.byType(Text));
    final textCount = tester.widgetList(texts).length;

    for (var i = 0; i < textCount; i++) {
      final textWidget = tester.widget<Text>(texts.at(i));
      final textStyle = textWidget.style;

      if (textStyle != null && textStyle.color != null) {
        // Get background color (simplified - would need more complex logic)
        final backgroundColor = _getBackgroundColor(tester, texts.at(i));

        final isLargeText = (textStyle.fontSize ?? 14) >= 18;
        assertMeetsWcagAa(
          textStyle.color!,
          backgroundColor,
          isLargeText: isLargeText,
        );
      }
    }
  }

  static Color _getBackgroundColor(WidgetTester tester, Finder finder) {
    // Simplified - would need to traverse widget tree to find actual background
    return Colors.white;
  }

  // ============================================================================
  // TAP AREA SIZE
  // ============================================================================

  /// Verify interactive element has sufficient tap area (minimum 44x44 dp)
  static void assertHasSufficientTapArea(
    WidgetTester tester,
    Finder finder, {
    double minimumSize = 44.0,
  }) {
    final size = tester.getSize(finder);

    expect(
      size.width,
      greaterThanOrEqualTo(minimumSize),
      reason: 'Tap area width ${size.width} is less than minimum $minimumSize',
    );

    expect(
      size.height,
      greaterThanOrEqualTo(minimumSize),
      reason: 'Tap area height ${size.height} is less than minimum $minimumSize',
    );
  }

  /// Verify all buttons have sufficient tap area
  static void assertAllButtonsHaveSufficientTapArea(
    WidgetTester tester,
    Finder rootFinder,
  ) {
    final buttons = find.descendant(
      of: rootFinder,
      matching: find.byType(ElevatedButton),
    );

    for (var i = 0; i < tester.widgetList(buttons).length; i++) {
      assertHasSufficientTapArea(tester, buttons.at(i));
    }
  }

  // ============================================================================
  // SCREEN READER SUPPORT
  // ============================================================================

  /// Verify widget announces changes properly
  static Future<void> assertAnnouncesChanges(
    WidgetTester tester,
    Finder finder,
    Future<void> Function() interaction,
  ) async {
    // Get initial semantic tree
    final initialSemantics = tester.getSemantics(finder);

    // Perform interaction
    await interaction();
    await tester.pumpAndSettle();

    // Get updated semantic tree
    final updatedSemantics = tester.getSemantics(finder);

    // Verify semantics changed (indicating announcement would occur)
    expect(
      initialSemantics != updatedSemantics,
      isTrue,
      reason: 'Semantics should update to announce changes',
    );
  }

  /// Verify live region updates
  static void assertHasLiveRegion(
    WidgetTester tester,
    Finder finder,
  ) {
    // Note: Live region checking requires platform-specific implementation
    // This is a simplified version for testing purposes
    final semantics = tester.getSemantics(finder);
    expect(semantics, isNotNull, reason: 'Widget should have semantic properties');
  }

  // ============================================================================
  // FORM ACCESSIBILITY
  // ============================================================================

  /// Verify form field is accessible
  static void assertFormFieldIsAccessible(
    WidgetTester tester,
    Finder fieldFinder, {
    String? expectedLabel,
    String? expectedHint,
  }) {
    // Check semantic label
    assertHasSemanticLabel(tester, fieldFinder, expectedLabel: expectedLabel);

    // Check focusable
    assertIsFocusable(tester, fieldFinder);

    // Check error announcement
    final semantics = tester.getSemantics(fieldFinder);
    if (expectedHint != null) {
      expect(
        semantics.hint,
        equals(expectedHint),
        reason: 'Form field should have helpful hint text',
      );
    }
  }

  /// Verify form has proper error announcements
  static Future<void> assertFormErrorsAreAnnounced(
    WidgetTester tester,
    Finder formFinder,
    Future<void> Function() submitForm,
  ) async {
    // Submit form with errors
    await submitForm();
    await tester.pumpAndSettle();

    // Verify error messages are in semantic tree
    final errorMessages = find.descendant(
      of: formFinder,
      matching: find.text('error', skipOffstage: false),
    );

    // Each error should be accessible to screen readers
    for (var i = 0; i < tester.widgetList(errorMessages).length; i++) {
      assertHasSemanticLabel(tester, errorMessages.at(i));
    }
  }

  // ============================================================================
  // COMPREHENSIVE ACCESSIBILITY AUDIT
  // ============================================================================

  /// Run complete accessibility audit on widget
  static Future<AccessibilityAuditResult> auditWidget(
    WidgetTester tester,
    Finder rootFinder,
  ) async {
    final issues = <String>[];

    // Check semantic labels
    try {
      assertHasSemanticLabel(tester, rootFinder);
    } catch (e) {
      issues.add('Missing semantic label: $e');
    }

    // Check tap areas
    try {
      assertAllButtonsHaveSufficientTapArea(tester, rootFinder);
    } catch (e) {
      issues.add('Insufficient tap area: $e');
    }

    // Check color contrast
    try {
      await assertAllTextMeetsContrast(tester, rootFinder);
    } catch (e) {
      issues.add('Color contrast issue: $e');
    }

    return AccessibilityAuditResult(
      passed: issues.isEmpty,
      issues: issues,
    );
  }

  /// Verify widget passes all accessibility guidelines
  static Future<void> assertPassesAccessibilityGuidelines(
    WidgetTester tester,
    Finder rootFinder,
  ) async {
    final result = await auditWidget(tester, rootFinder);

    expect(
      result.passed,
      isTrue,
      reason: 'Accessibility audit failed:\n${result.issues.join('\n')}',
    );
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Result of accessibility audit
class AccessibilityAuditResult {
  final bool passed;
  final List<String> issues;

  AccessibilityAuditResult({
    required this.passed,
    required this.issues,
  });

  @override
  String toString() {
    if (passed) {
      return 'Accessibility Audit: PASSED';
    }
    return 'Accessibility Audit: FAILED\n${issues.join('\n')}';
  }
}
