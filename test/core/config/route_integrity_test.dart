// P7 — route-table integrity smoke (owner GoRouter).
//
// The full router can't be instantiated hermetically (it watches
// `enhancedAuthProvider`, a StateNotifier that can't be faked — memory
// `seam-test-proves-fn-not-wiring`), so this guards the route table at the
// source level instead. It catches the real bug classes: a malformed path, an
// ACCIDENTAL duplicate route, and a `path: OwnerRoutes.X` that references an
// undefined constant.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String src = File(
    'lib/core/config/router_owner.dart',
  ).readAsStringSync();

  // OwnerRoutes constants: name -> path. `\s*` spans the few multi-line
  // declarations (e.g. icalImport).
  final Map<String, String> routes = <String, String>{};
  for (final RegExpMatch m in RegExp(
    r"static const String (\w+)\s*=\s*'([^']*)'",
  ).allMatches(src)) {
    routes[m.group(1)!] = m.group(2)!;
  }

  test('OwnerRoutes parses to a non-trivial table', () {
    expect(routes.length, greaterThan(20), reason: 'parsed ${routes.length}');
  });

  test('every route path is well-formed (starts with /)', () {
    final List<String> bad = routes.entries
        .where((MapEntry<String, String> e) => !e.value.startsWith('/'))
        .map((MapEntry<String, String> e) => '${e.key} = "${e.value}"')
        .toList();
    expect(
      bad,
      isEmpty,
      reason: 'Malformed route paths:\n  ${bad.join('\n  ')}',
    );
  });

  test('no ACCIDENTAL duplicate route path', () {
    // Known intentional alias — two constant names, same path, by design.
    const Set<String> knownAliasPaths = <String>{'/owner/guides/ical'};
    final Map<String, List<String>> byPath = <String, List<String>>{};
    routes.forEach(
      (String k, String v) => byPath.putIfAbsent(v, () => <String>[]).add(k),
    );
    final List<String> dups = byPath.entries
        .where(
          (MapEntry<String, List<String>> e) =>
              e.value.length > 1 && !knownAliasPaths.contains(e.key),
        )
        .map(
          (MapEntry<String, List<String>> e) =>
              '${e.key}  ←  ${e.value.join(', ')}',
        )
        .toList();
    expect(
      dups,
      isEmpty,
      reason:
          'Duplicate route paths (give each a distinct path, or allowlist '
          'the alias):\n  ${dups.join('\n  ')}',
    );
  });

  test('every OwnerRoutes.X referenced in the router is defined', () {
    final Set<String> refs = RegExp(
      r'OwnerRoutes\.(\w+)',
    ).allMatches(src).map((RegExpMatch m) => m.group(1)!).toSet();
    final Set<String> undefined = refs.difference(routes.keys.toSet());
    expect(
      undefined,
      isEmpty,
      reason: 'Referenced but undefined OwnerRoutes: ${undefined.join(', ')}',
    );
  });
}
