import 'package:bookbed/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.9 — CommonAppBar leadingTooltip param.
void main() {
  Widget host({String? leadingTooltip}) => MaterialApp(
    home: Scaffold(
      appBar: CommonAppBar(
        title: 'Naslov',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (_) {},
        leadingTooltip: leadingTooltip,
      ),
    ),
  );

  testWidgets('custom leadingTooltip is applied to the leading IconButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host(leadingTooltip: 'Natrag'));
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).tooltip,
      'Natrag',
    );
  });

  testWidgets('default keeps the previous Menu tooltip (backward compat)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(host());
    expect(tester.widget<IconButton>(find.byType(IconButton)).tooltip, 'Menu');
  });
}
