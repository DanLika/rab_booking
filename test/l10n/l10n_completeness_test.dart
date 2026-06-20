// P7 — l10n completeness net.
//
// Asserts the `en` + `hr` ARB key sets are IDENTICAL: every user-facing key
// resolves in BOTH locales, no silent gaps. A key added to one locale but not
// the other fails here immediately — otherwise it only surfaces at runtime, in
// the wrong language, for a real user. Also guards against empty values.
//
// Pure file IO (reads the committed ARBs) — no app code, no Firebase, fast.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const Map<String, String> _arbs = <String, String>{
  'en': 'lib/l10n/app_en.arb',
  'hr': 'lib/l10n/app_hr.arb',
};

Map<String, dynamic> _load(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Message keys only — drops `@@locale` and the `@key` metadata entries.
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((String k) => !k.startsWith('@')).toSet();

void main() {
  group('l10n ARB completeness', () {
    final Set<String> en = _messageKeys(_load(_arbs['en']!));
    final Set<String> hr = _messageKeys(_load(_arbs['hr']!));

    test('en and hr define exactly the same keys', () {
      final List<String> missingInHr = en.difference(hr).toList()..sort();
      final List<String> missingInEn = hr.difference(en).toList()..sort();

      expect(
        missingInHr,
        isEmpty,
        reason:
            'In en but MISSING in hr (${missingInHr.length}) — add HR '
            'translations:\n  ${missingInHr.join('\n  ')}',
      );
      expect(
        missingInEn,
        isEmpty,
        reason:
            'In hr but MISSING in en (${missingInEn.length}) — add EN '
            'strings:\n  ${missingInEn.join('\n  ')}',
      );
    });

    for (final MapEntry<String, String> arb in _arbs.entries) {
      test('${arb.key}: no message has an empty value', () {
        final Map<String, dynamic> map = _load(arb.value);
        final List<String> empties = <String>[];
        map.forEach((String k, dynamic v) {
          if (!k.startsWith('@') && v is String && v.trim().isEmpty) {
            empties.add(k);
          }
        });
        expect(
          empties,
          isEmpty,
          reason: '${arb.key} has empty values: ${empties.join(', ')}',
        );
      });
    }

    for (final MapEntry<String, String> arb in _arbs.entries) {
      test('${arb.key}: no duplicate top-level key', () {
        // Top-level keys sit at exactly 2-space indent; nested @meta content is
        // deeper. JSON would silently keep-last, so duplicates only surface
        // here. Catches the dead/drifting earlier definition.
        final RegExp topKey = RegExp(r'^  "([^"]+)"\s*:');
        final Set<String> seen = <String>{};
        final List<String> dups = <String>[];
        for (final String line in File(arb.value).readAsLinesSync()) {
          final Match? m = topKey.firstMatch(line);
          if (m != null && !seen.add(m.group(1)!)) dups.add(m.group(1)!);
        }
        expect(
          dups.toSet().toList()..sort(),
          isEmpty,
          reason:
              '${arb.key} has duplicate keys — keep-last wins at runtime, so '
              'remove the EARLIER definition:\n  ${dups.toSet().join('\n  ')}',
        );
      });
    }
  });
}
