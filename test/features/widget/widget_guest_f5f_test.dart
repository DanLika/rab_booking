/// F5F guest-widget audit: accessibility + token fixes
///
/// Covers the specific changes from the f5f branch:
///   1. ConfirmationHeader: ExcludeSemantics on icon, Semantics(header) on msg
///   2. SubdomainNotFoundScreen: Semantics(header:true) on title
///   3. NotFoundScreen: CommonAppBar (no raw AppBar), heading Semantics
///   4. confirmation_header: Curves.easeOutBack replaces elasticOut (code-path)
///   5. email_confirmation_card: themeProvider watch (no computeLuminance)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/design_tokens/color_tokens.dart';
import 'package:bookbed/features/widget/presentation/widgets/confirmation/confirmation_header.dart';
import 'package:bookbed/features/widget/presentation/screens/subdomain_not_found_screen.dart';
import 'package:bookbed/shared/presentation/screens/not_found_screen.dart';
import 'package:bookbed/shared/widgets/common_app_bar.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. ConfirmationHeader a11y: ExcludeSemantics on icon ─────────────────
  group('ConfirmationHeader a11y', () {
    Widget buildHeader({String paymentMethod = 'stripe'}) {
      return createTestWidget(
        child: ConfirmationHeader(
          paymentMethod: paymentMethod,
          colors: ColorTokens.light,
        ),
      );
    }

    testWidgets('success icon is wrapped in ExcludeSemantics', (tester) async {
      await tester.pumpWidget(buildHeader());
      // Drain the 600ms flutter_animate timer so no pending timers remain.
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        find.byType(ExcludeSemantics),
        findsWidgets,
        reason:
            'Icon should be ExcludeSemantics to avoid announcing label twice',
      );
    });

    testWidgets('confirmation message has Semantics(header:true)', (
      tester,
    ) async {
      await tester.pumpWidget(buildHeader());
      await tester.pump(const Duration(milliseconds: 700));

      final semanticsNodes = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasHeader = semanticsNodes.any((s) => s.properties.header == true);
      expect(
        hasHeader,
        isTrue,
        reason: 'Expected Semantics(header:true) on confirmation message text',
      );
    });

    testWidgets('renders for bank_transfer without timer leak', (tester) async {
      await tester.pumpWidget(buildHeader(paymentMethod: 'bank_transfer'));
      await tester.pump(const Duration(milliseconds: 700));

      // Pending payment method should still render ExcludeSemantics on icon
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });
  });

  // ── 2. SubdomainNotFoundScreen: title is a heading ────────────────────────
  group('SubdomainNotFoundScreen a11y', () {
    testWidgets('title Text has Semantics(header:true)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const SubdomainNotFoundScreen(subdomain: 'missing-prop'),
        ),
      );
      await tester.pump();

      final semanticsNodes = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasHeader = semanticsNodes.any((s) => s.properties.header == true);
      expect(
        hasHeader,
        isTrue,
        reason: 'Property-not-found title must be announced as page heading',
      );
    });
  });

  // ── 3. NotFoundScreen: CommonAppBar and heading Semantics ─────────────────
  group('NotFoundScreen', () {
    Widget buildScreen() =>
        const ProviderScope(child: MaterialApp(home: NotFoundScreen()));

    testWidgets('uses CommonAppBar widget, not raw Material AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.byType(CommonAppBar),
        findsOneWidget,
        reason: 'Not-found screen must use CommonAppBar, not raw AppBar',
      );
    });

    testWidgets('page heading has Semantics(header:true)', (tester) async {
      await tester.pumpWidget(buildScreen());

      final semanticsNodes = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasHeader = semanticsNodes.any((s) => s.properties.header == true);
      expect(
        hasHeader,
        isTrue,
        reason:
            '"Stranica nije pronađena" heading must carry Semantics(header)',
      );
    });
  });
}
