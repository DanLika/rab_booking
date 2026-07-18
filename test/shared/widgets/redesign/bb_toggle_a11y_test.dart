import 'package:bookbed/shared/widgets/redesign/bb_checkbox.dart';
import 'package:bookbed/shared/widgets/redesign/bb_radio.dart';
import 'package:bookbed/shared/widgets/redesign/bb_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.7 — checkbox/radio/switch a11y contracts.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[child],
      ),
    ),
  );

  group('BbCheckbox', () {
    testWidgets('label-less box hit area is >=44x44 (ROOT fix)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(BbCheckbox(value: false, onChanged: (_) {})),
      );
      final Size size = tester.getSize(find.byType(BbCheckbox));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('subtitle is folded into ONE announced label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          BbCheckbox(
            value: true,
            onChanged: (_) {},
            label: 'Prihvaćam uvjete',
            subtitle: 'Pročitao sam pravila',
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Prihvaćam uvjete, Pročitao sam pravila'),
      );
      expect(node.hasFlag(SemanticsFlag.hasCheckedState), isTrue);
      expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
      handle.dispose();
    });

    testWidgets('validator error stays announced as a sibling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          BbCheckbox(
            value: false,
            onChanged: (_) {},
            label: 'Uvjeti',
            error: 'Obavezno polje',
          ),
        ),
      );
      expect(find.text('Obavezno polje'), findsOneWidget);
    });
  });

  group('BbRadio', () {
    testWidgets('announces radio contract (checked + mutually exclusive)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          BbRadio<int>(
            value: 1,
            groupValue: 1,
            onChanged: (_) {},
            label: 'Opcija A',
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Opcija A'),
      );
      expect(node.hasFlag(SemanticsFlag.isChecked), isTrue);
      expect(node.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup), isTrue);
      handle.dispose();
    });

    testWidgets('label-less dot hit area is >=48 wide', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(BbRadio<int>(value: 1, groupValue: 2, onChanged: (_) {})),
      );
      expect(
        tester.getSize(find.byType(BbRadio<int>)).width,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('BbSwitch', () {
    testWidgets('one merged node with toggled state (no double-read)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          BbSwitch(
            value: true,
            onChanged: (_) {},
            label: 'Notifikacije',
            subtitle: 'Email obavijesti',
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Notifikacije, Email obavijesti'),
      );
      expect(node.hasFlag(SemanticsFlag.hasToggledState), isTrue);
      expect(node.hasFlag(SemanticsFlag.isToggled), isTrue);
      handle.dispose();
    });

    testWidgets('keyboard Space toggles a focused switch', (
      WidgetTester tester,
    ) async {
      bool value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => BbSwitch(
              value: value,
              onChanged: (bool v) => setState(() => value = v),
              label: 'Tipkovnica',
            ),
          ),
        ),
      );
      // Tab focuses the InkWell (only focusable), Space activates it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isTrue);
    });
  });
}
