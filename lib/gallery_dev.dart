/// Dev-only standalone entry point that boots straight into the BB design
/// system gallery. No Firebase, no auth, no routing — just the primitives.
///
/// Run:
///   flutter run --target lib/gallery_dev.dart -d chrome
///   flutter run --target lib/gallery_dev.dart -d ios-simulator
///
/// This is the canonical way to verify visual parity / Croatian diacritics /
/// tabular-figure alignment / reduced-motion fallback after any change to
/// `lib/core/design/tokens.dart` or `lib/core/widgets/bb_*.dart`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design/gallery_screen.dart';

void main() {
  assert(kDebugMode, 'gallery_dev is dev-only — refusing release-mode boot.');
  runApp(const _GalleryHostApp());
}

class _GalleryHostApp extends StatelessWidget {
  const _GalleryHostApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BB Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const BBGalleryScreen(),
    );
  }
}
