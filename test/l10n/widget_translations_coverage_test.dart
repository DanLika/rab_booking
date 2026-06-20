import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gate (b): the hand-rolled `WidgetTranslations` (System B, embedded booking
/// widget) must provide all four languages — HR / EN / DE / IT — for every key.
///
/// Each translation is a `String` getter/method whose body is a
/// `switch (locale.languageCode)`. "Present in all 4 langs" therefore means:
/// every such switch has an explicit `case 'hr'`, `case 'de'`, `case 'it'`, and
/// either `case 'en'` or a `default:` (EN is the fallback). A missing case would
/// silently fall through to the English `default`, shipping English text for that
/// language — exactly the drift this gate catches.
///
/// This is a pure SOURCE SCAN (reads the .dart file as text) so it has zero
/// dependency on code generation or the riverpod `languageProvider`.
void main() {
  const path = 'lib/features/widget/presentation/l10n/widget_translations.dart';

  test('every switch(locale.languageCode) covers hr + de + it + en/default', () {
    final src = File(path).readAsStringSync();

    // Method declarations, in source order, for human-readable failure naming.
    final decls = RegExp(r'\n  String (?:get )?(\w+)').allMatches(src).toList();
    String enclosingMethod(int pos) {
      var name = '<top-level>';
      for (final m in decls) {
        if (m.start < pos) {
          name = m.group(1)!;
        } else {
          break;
        }
      }
      return name;
    }

    final switches = RegExp(
      r'switch \(locale\.languageCode\)',
    ).allMatches(src).toList();

    // Sanity floor: the file currently has 330+ translation switches. A large
    // drop means the structure changed and this scan may be silently passing.
    expect(
      switches.length,
      greaterThan(250),
      reason:
          'Expected 330+ language switches; found ${switches.length}. '
          'Did widget_translations.dart change shape?',
    );

    final failures = <String>[];
    for (var i = 0; i < switches.length; i++) {
      final start = switches[i].end;
      final end = (i + 1 < switches.length)
          ? switches[i + 1].start
          : src.length;
      final window = src.substring(start, end);

      bool hasCase(String lang) => window.contains("case '$lang':");
      final ok =
          hasCase('hr') &&
          hasCase('de') &&
          hasCase('it') &&
          (hasCase('en') || window.contains('default:'));

      if (!ok) {
        final present = ['hr', 'de', 'it', 'en'].where(hasCase).toList();
        failures.add(
          '${enclosingMethod(switches[i].start)} '
          '(present: $present, default: ${window.contains('default:')})',
        );
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'WidgetTranslations methods missing a language case '
          '(each must cover HR + DE + IT + EN/default):\n'
          '${failures.map((f) => '  • $f').join('\n')}',
    );
  });
}
