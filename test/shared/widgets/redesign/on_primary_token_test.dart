// Audit sweep F3.3 — BBColorSet.onPrimary token.
//
// Visually neutral by construction: the token IS Colors.white in both
// themes. The test pins that neutrality (a future brand shift must change
// the token deliberately, and this test names the contract) and checks the
// migrated primitives read the token.

import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/shared/widgets/redesign/bb_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onPrimary is white in both themes (visual-neutrality pin)', () {
    expect(BBColor.light.onPrimary, Colors.white);
    expect(BBColor.dark.onPrimary, Colors.white);
  });

  testWidgets('primary button ink renders with the token value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: BbButton(label: 'Spremi', onPressed: () {}),
          ),
        ),
      ),
    );
    final Text label = tester.widget<Text>(find.text('Spremi'));
    expect(label.style?.color, BBColor.light.onPrimary);
  });
}
