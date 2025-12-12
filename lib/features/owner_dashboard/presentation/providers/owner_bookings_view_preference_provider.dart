import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bookings_view_mode.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Provider for current bookings view mode (card/table)
/// Automatically defaults to card on mobile, table on desktop
/// Persists user's preference
final ownerBookingsViewProvider = StateNotifierProvider<OwnerBookingsViewNotifier, BookingsViewMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // If SharedPreferences is not yet initialized, use default view mode
  // This can happen during app initialization before main.dart overrides the provider
  if (prefs == null) {
    return OwnerBookingsViewNotifier.withDefault();
  }
  return OwnerBookingsViewNotifier(prefs);
});

/// State notifier for bookings view mode with persistence
class OwnerBookingsViewNotifier extends StateNotifier<BookingsViewMode> {
  final SharedPreferences? _prefs;

  OwnerBookingsViewNotifier(this._prefs) : super(_loadSavedView(_prefs));

  /// Create notifier with default view mode (used when SharedPreferences is not yet initialized)
  factory OwnerBookingsViewNotifier.withDefault() {
    return OwnerBookingsViewNotifier(null).._setDefaultView();
  }

  void _setDefaultView() {
    // Default based on platform: card for mobile, table for desktop/web
    state = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => BookingsViewMode.card,
      _ => BookingsViewMode.table,
    };
  }

  /// Load saved view from SharedPreferences
  static BookingsViewMode _loadSavedView(SharedPreferences? prefs) {
    if (prefs == null) {
      // Default based on platform: card for mobile, table for desktop/web
      return switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.android => BookingsViewMode.card,
        _ => BookingsViewMode.table,
      };
    }

    final saved = prefs.getString(BookingsViewMode.prefsKey);
    if (saved != null) {
      return BookingsViewMode.fromString(saved);
    }

    // Default based on platform: card for mobile, table for desktop/web
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => BookingsViewMode.card,
      _ => BookingsViewMode.table,
    };
  }

  /// Toggle between card and table view
  Future<void> toggle() async {
    final newMode = state == BookingsViewMode.card ? BookingsViewMode.table : BookingsViewMode.card;
    await setView(newMode);
  }

  /// Set specific view mode and persist
  Future<void> setView(BookingsViewMode mode) async {
    state = mode;
    // Only persist if SharedPreferences is available
    if (_prefs != null) {
      await _prefs.setString(BookingsViewMode.prefsKey, mode.name);
    }
  }
}
