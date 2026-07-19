import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/iconname_to_unicode_map.dart';
// Imported for side-effect: forces tree-shaker to keep all icon code points
// reachable so name-based lookup works at runtime.
// ignore: unused_import
import 'package:material_symbols_icons/symbols_map.dart';

import '../../../core/design/tokens.dart';

/// Material Symbols Rounded icon (handoff [BBIcon]).
///
/// Looks up the icon by string name (matches the icon-name strings used
/// throughout `primitives.jsx` and screen modules). Defaults `FILL 1`,
/// `wght 500`, `opsz 24` per handoff spec. Unknown names fall through to
/// `question_mark` so missing icons never crash (a debug print flags the
/// typo in dev builds).
///
/// **A11y (audit sweep F2.4):** icons are DECORATIVE BY DEFAULT — without a
/// [semanticLabel] the widget wraps itself in [ExcludeSemantics] so screen
/// readers skip it (a bare [Icon] otherwise surfaces its glyph to the
/// semantics tree). Pass [semanticLabel] when the icon carries meaning on
/// its own (icon-only affordances with no adjacent text).
///
/// NOTE: builds MUST pass `--no-tree-shake-icons` (standard in this repo
/// for `flutter build`) AND keep the `symbols_map` side-effect import below
/// or runtime lookup returns the fallback glyph for everything.
class BbIcon extends StatelessWidget {
  const BbIcon({
    super.key,
    required this.name,
    this.size = 20,
    this.fill = 1,
    this.weight = 500,
    this.color,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final int fill;
  final int weight;
  final Color? color;

  /// Accessible name for meaningful icons. `null` (default) marks the icon
  /// decorative and excludes it from the semantics tree entirely.
  final String? semanticLabel;

  // Resolved-glyph cache — the map lookup + IconData allocation ran on every
  // build for every icon on screen (audit F2.4). Bounded by the number of
  // distinct icon names actually used.
  static final Map<String, IconData> _cache = <String, IconData>{};

  static IconData _resolve(String name) {
    return _cache.putIfAbsent(name, () {
      final int? codePoint = materialSymbolsIconNameToUnicodeMap[name];
      assert(() {
        if (codePoint == null) {
          debugPrint('[BbIcon] unknown icon name "$name" — rendering fallback');
        }
        return true;
      }());
      return IconData(
        codePoint ?? materialSymbolsIconNameToUnicodeMap['question_mark']!,
        fontFamily: 'MaterialSymbolsRounded',
        fontPackage: 'material_symbols_icons',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(
      _resolve(name),
      size: size,
      color: color ?? BBColor.of(context).textPrimary,
      fill: fill.toDouble(),
      weight: weight.toDouble(),
      grade: 0,
      opticalSize: 24,
      semanticLabel: semanticLabel,
    );
    // Icon.semanticLabel = null does NOT suppress the semantics node —
    // decorative icons need the explicit exclusion.
    return semanticLabel == null ? ExcludeSemantics(child: icon) : icon;
  }
}
