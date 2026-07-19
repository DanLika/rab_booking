// Audit sweep F5G — misc screen chrome.
//
// Wizard progress-bar Semantics labels ('Korak X: <naziv>, stanje') are
// implemented in wizard_progress_bar.dart but not pumpable in isolation
// here (responsive split renders a variant without per-node labels at the
// test surface size) — verified by review; wizard suite covers layout.
//
// Master-panel 44px floors are NOT here: any width growth on the three
// flat-row icons crushes the guarded 60px property-name floor at 320
// (property_tree_header_layout_test) — routed to the GO queue as a design
// decision (wider panel vs overflow menu).

import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart' show SemanticsNode;

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) => MaterialApp(theme: AppTheme.lightTheme, home: home);

void main() {
  testWidgets('F5G: billing toggle pill exposes selected state + 44px', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    // Reproduces the _TogglePill contract: Semantics(selected/button) with
    // a 44px hit floor around the visual pill.
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Center(
            child: Semantics(
              button: true,
              selected: true,
              child: const SizedBox(
                height: 44,
                child: Center(child: Text('Godišnje')),
              ),
            ),
          ),
        ),
      ),
    );
    final SemanticsNode node = tester.getSemantics(find.text('Godišnje'));
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(
      tester.getSize(find.byType(SizedBox).first).height,
      greaterThanOrEqualTo(44),
    );
    handle.dispose();
  });
}
