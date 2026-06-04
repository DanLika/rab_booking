import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'widget_visibility_provider.g.dart';

/// Tracks whether the widget host is visible to the user.
///
/// Riverpod-wrapped `AppLifecycleListener`. Flutter Web maps the browser
/// `document.visibilitychange` event onto [AppLifecycleState]:
///   - tab visible / focused → `AppLifecycleState.resumed`
///   - tab hidden (other tab, minimized) → `inactive` then `paused`
///   - background tab → `hidden` (Flutter 3.13+)
///
/// Only `resumed` is treated as visible. Every other state pauses upstream
/// polling consumers, so a background tab stops issuing `getUnitAvailability`
/// CF calls until the user returns to the tab.
///
/// Consumed by [realtimeMonthCalendarProvider] and [realtimeYearCalendarProvider]
/// — when this returns `false`, those providers return `Stream.empty()`,
/// which closes the upstream subscription (cancelling the CF poll loop).
/// Riverpod keeps the prior `AsyncValue.data(snapshot)` so the calendar UI
/// keeps showing its last paint instead of going blank.
///
/// When the state flips back to `true`, Riverpod rebuilds the calendar
/// providers (because they `ref.watch` this one) — the real stream
/// re-subscribes and `streamAvailability` issues its first poll immediately,
/// so a returning user sees fresh availability without waiting the 30s
/// interval.
@Riverpod(keepAlive: true)
class WidgetVisibility extends _$WidgetVisibility {
  late final AppLifecycleListener _listener;

  @override
  bool build() {
    _listener = AppLifecycleListener(
      onStateChange: (lifecycleState) {
        state = lifecycleState == AppLifecycleState.resumed;
      },
    );
    ref.onDispose(_listener.dispose);
    return true; // assume visible at mount
  }
}
