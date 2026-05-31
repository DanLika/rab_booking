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
/// `question_mark` so missing icons never crash.
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
  });

  final String name;
  final double size;
  final int fill;
  final int weight;
  final Color? color;

  static IconData _resolve(String name) {
    final int codePoint =
        materialSymbolsIconNameToUnicodeMap[name] ??
        materialSymbolsIconNameToUnicodeMap['question_mark']!;
    return IconData(
      codePoint,
      fontFamily: 'MaterialSymbolsRounded',
      fontPackage: 'material_symbols_icons',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _resolve(name),
      size: size,
      color: color ?? BBColor.of(context).textPrimary,
      fill: fill.toDouble(),
      weight: weight.toDouble(),
      grade: 0,
      opticalSize: 24,
    );
  }
}
