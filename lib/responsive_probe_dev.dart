/// Dev-only standalone entry that boots straight into the Responsive Probe.
/// No Firebase, no auth, no routing — just the harness verification screen.
///
/// Run:
///   flutter run --target lib/responsive_probe_dev.dart -d chrome
///   flutter run --target lib/responsive_probe_dev.dart -d ios-simulator
///   flutter run --target lib/responsive_probe_dev.dart -d android-emulator
///
/// Use this to verify BBResponsive / BBResponsiveBuilder / BBScaffold behave
/// correctly on every target. Resize the Chrome window, rotate the device,
/// open the keyboard — every value in the live snapshot updates in real time.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design/responsive_probe_screen.dart';

void main() {
  assert(
    kDebugMode,
    'responsive_probe_dev is dev-only — refusing release-mode boot.',
  );
  runApp(const _ProbeHostApp());
}

class _ProbeHostApp extends StatelessWidget {
  const _ProbeHostApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BB Responsive Probe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const BBResponsiveProbeScreen(),
    );
  }
}
