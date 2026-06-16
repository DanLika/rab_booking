// Locks the CommonAppBar title contract (audit/126 §2A).
//
//  * Default (`showTitle` omitted/true) renders the title — this is the
//    regression guard for the ~29 non-premium screens whose AppBar title is
//    their ONLY title and must never be stripped.
//  * `showTitle: false` hides the title while keeping the leading (hamburger)
//    and actions — this is how the 4 premium screens kill the double-header
//    (their in-body premium header carries the title instead).

import 'package:bookbed/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required bool showTitle, required bool useDefault}) {
    return MaterialApp(
      home: Scaffold(
        appBar: useDefault
            ? CommonAppBar(
                title: 'My Title',
                leadingIcon: Icons.menu,
                onLeadingIconTap: (_) {},
                actions: const [Icon(Icons.add)],
              )
            : CommonAppBar(
                title: 'My Title',
                leadingIcon: Icons.menu,
                onLeadingIconTap: (_) {},
                actions: const [Icon(Icons.add)],
                showTitle: showTitle,
              ),
      ),
    );
  }

  testWidgets('default renders the title (non-premium screens keep it)', (
    tester,
  ) async {
    await tester.pumpWidget(harness(showTitle: true, useDefault: true));

    expect(find.text('My Title'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget); // leading kept
    expect(find.byIcon(Icons.add), findsOneWidget); // actions kept
  });

  testWidgets('showTitle:false hides the title but keeps leading + actions '
      '(premium double-header fix)', (tester) async {
    await tester.pumpWidget(harness(showTitle: false, useDefault: false));

    expect(find.text('My Title'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget); // leading kept
    expect(find.byIcon(Icons.add), findsOneWidget); // actions kept
  });
}
