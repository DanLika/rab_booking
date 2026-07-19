// P7 — hardcoded-string guard.
//
// Scans every `*_screen.dart` / `*_dialog.dart` for user-facing `Text('literal')`
// (`SelectableText` / `AutoSizeText` too) — a string with a letter, not wired
// through `AppLocalizations`. The guard FREEZES the current set: it fails on a
// NEW literal (localize it, or allowlist it if it is a deliberate dev-only
// label), and also fails when an allowlisted literal disappears (you localized
// it → trim the baseline). Keeps the l10n debt from growing silently.
//
// The two design-showcase screens (gallery / responsive_probe) are dev tools
// whose whole point is literal style labels — excluded from the scan.
//
// Heuristic, not an AST pass: catches single-line literal first-args (no
// interpolation). Good enough to stop the common regression.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pre-existing hardcoded literals, grouped by file. Each is l10n debt to pay
/// later; for now it is frozen so nothing NEW slips in. When you localize one,
/// remove its line here.
const Map<String, List<String>> _allowed = <String, List<String>>{
  'lib/features/admin/presentation/screens/activity_log_screen.dart': <String>[
    'Refresh',
    'Retry',
  ],
  'lib/features/admin/presentation/screens/admin_login_screen.dart': <String>[
    'Cancel',
    'Password reset email sent.',
    'Reset password',
    'Send link',
  ],
  'lib/features/admin/presentation/screens/user_detail_screen.dart': <String>[
    'Copied to clipboard',
  ],
  'lib/features/admin/presentation/screens/users_list_screen.dart': <String>[
    'Account Type',
    'Actions',
    'Created At',
    'Email',
    'Name',
    'Sort: Created',
    'Sort: Email',
    'Sort: Name',
  ],
  'lib/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart':
      <String>['Grid'],
  'lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart':
      <String>['Grid'],
  'lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart':
      <String>['Kopiraj'],
  'lib/features/subscription/screens/subscription_screen.dart': <String>[
    'Besplatno',
    'Pro',
  ],
  // booking_widget_screen.dart — 'Cancel'/'Continue' localized to
  // WidgetTranslations in #768 (4-lang); entry dropped (ratcheted down).
  // popup_blocked_dialog.dart — 'Cancel' (its last hardcoded literal) localized
  // to WidgetTranslations (popupCancel) in 7.33; entry dropped (ratcheted down).
  // not_found_screen.dart — the F5F CommonAppBar/BbButton restructure moved
  // 'Povratak na početnu' + 'Stranica nije pronađena' out of Text() adjacency
  // (still hardcoded, tagged TODO(l10n) for F6); ratcheted down per the
  // guard's own instruction.
  'lib/shared/presentation/screens/not_found_screen.dart': <String>['Natrag'],
};

/// Dev-only design showcases — literal style labels by design, not l10n debt.
const Set<String> _excludedFiles = <String>{
  'lib/core/design/gallery_screen.dart',
  'lib/core/design/responsive_probe_screen.dart',
};

const String _sep = '\u0000';
String _pretty(String k) => k.replaceFirst(_sep, '  →  ');

void main() {
  test('no NEW hardcoded user-facing Text() literal in screens/dialogs', () {
    final RegExp re = RegExp(
      r'''(?:Text|SelectableText|AutoSizeText)\(\s*['"]([^'"$\\]+)['"]''',
    );
    final RegExp hasLetter = RegExp(r'[A-Za-zÀ-ÿčćžšđČĆŽŠĐ]');

    final Set<String> found = <String>{};
    for (final FileSystemEntity e in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (e is! File) continue;
      final String path = e.path;
      if (!(path.endsWith('_screen.dart') || path.endsWith('_dialog.dart'))) {
        continue;
      }
      if (_excludedFiles.contains(path)) continue;
      for (final String line in e.readAsLinesSync()) {
        for (final Match m in re.allMatches(line)) {
          final String s = m.group(1)!;
          if (s.trim().length >= 2 && hasLetter.hasMatch(s)) {
            found.add('$path$_sep$s');
          }
        }
      }
    }

    final Set<String> allow = <String>{
      for (final MapEntry<String, List<String>> e in _allowed.entries)
        for (final String s in e.value) '${e.key}$_sep$s',
    };

    final List<String> added = found.difference(allow).map(_pretty).toList()
      ..sort();
    final List<String> removed = allow.difference(found).map(_pretty).toList()
      ..sort();

    expect(
      added,
      isEmpty,
      reason:
          'NEW hardcoded user-facing string(s) — wire through AppLocalizations '
          '(or add to _allowed if it is a deliberate dev-only label):\n  '
          '${added.join('\n  ')}',
    );
    expect(
      removed,
      isEmpty,
      reason:
          'Allowlisted string(s) no longer found (localized? renamed?) — remove '
          'from _allowed so the baseline shrinks:\n  ${removed.join('\n  ')}',
    );
  });
}
