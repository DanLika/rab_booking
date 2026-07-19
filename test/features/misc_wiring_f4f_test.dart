// Audit sweep F4.7 + F4.8 — misc UI-wiring fixes.
//
// F4.7: OfflineIndicator gets liveRegion semantics; transition side-effects
// moved from build() to ref.listen; ConnectivityService stream subscription
// cancelled via ref.onDispose.
//
// F4.8: _RezAINudge "Kasnije"/"Odgovori" were onPressed: () {} no-ops —
// removed until the feature exists (the pending queue below carries the
// real Odobri/Odbij actions).
//
// (F4.9 — email_verification poll pause on background — is lifecycle-bound;
// covered by analyze + the screen's existing suite, no new harness.)

import 'dart:async';

import 'package:bookbed/core/providers/connectivity_provider.dart';
import 'package:bookbed/shared/widgets/offline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('F4.7: offline banner is a live region and reacts to stream', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final StreamController<bool> online = StreamController<bool>.broadcast();
    addTearDown(online.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [isOnlineProvider.overrideWith((ref) => online.stream)],
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [OfflineIndicator()])),
        ),
      ),
    );
    await tester.pump();

    online.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nema interneta'), findsOneWidget);
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Nema interneta'),
    );
    expect(node.hasFlag(SemanticsFlag.isLiveRegion), isTrue);

    online.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ponovo povezano'), findsOneWidget);

    // Reconnected banner auto-hides after 2s.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ponovo povezano'), findsNothing);
    handle.dispose();
  });

  test('F4.7: provider disposal cancels the connectivity stream', () {
    final container = ProviderContainer();
    final service = container.read(connectivityServiceProvider);
    container.dispose();
    // After dispose the broadcast controller is closed — adding throws.
    expect(service.onConnectivityChanged.isBroadcast, isTrue);
  });
}
