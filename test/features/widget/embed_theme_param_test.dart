// Guards the ?theme= embed parameter wiring (2026-07-13 finding: the
// widgetConfigProvider was never seeded from the URL, so every documented
// embed parameter — theme, primaryColor, … — was silently ignored, and the
// calendar's own themeProvider only ever consulted the platform brightness).

import 'dart:ui';

import 'package:bookbed/features/widget/domain/models/embed_url_params.dart';
import 'package:bookbed/features/widget/presentation/providers/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('?theme= URL parameter parses into the embed config', () {
    final uri = Uri.parse(
      'https://view.bookbed.io/?property=p&unit=u&theme=dark',
    );
    expect(EmbedUrlParams.fromUrlParameters(uri).themeMode, 'dark');

    final invalid = Uri.parse('https://view.bookbed.io/?theme=bogus');
    expect(EmbedUrlParams.fromUrlParameters(invalid).themeMode, 'system');
  });

  test('initial dark flag: explicit theme wins, system follows brightness', () {
    expect(initialDarkFromConfig('dark', Brightness.light), isTrue);
    expect(initialDarkFromConfig('DARK', Brightness.light), isTrue);
    expect(initialDarkFromConfig('light', Brightness.dark), isFalse);
    expect(initialDarkFromConfig('system', Brightness.dark), isTrue);
    expect(initialDarkFromConfig('system', Brightness.light), isFalse);
    expect(initialDarkFromConfig('', Brightness.dark), isTrue);
  });
}
