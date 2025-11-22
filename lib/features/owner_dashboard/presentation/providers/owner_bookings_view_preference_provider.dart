import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bookings_view_mode.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Provider for current bookings view mode (card/table)
/// Automatically defaults to card on mobile, table on desktop
/// Persists user's preference
final ownerBookingsViewProvider =
    StateNotifierProvider<OwnerBookingsViewNotifier, BookingsViewMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OwnerBookingsViewNotifier(prefs);
});

/// State notifier for bookings view mode with persistence
class OwnerBookingsViewNotifier extends StateNotifier<BookingsViewMode> {
  final SharedPreferences _prefs;

  OwnerBookingsViewNotifier(this._prefs) : super(_loadSavedView(_prefs));

  /// Load saved view from SharedPreferences
  static BookingsViewMode _loadSavedView(SharedPreferences prefs) {
    final saved = prefs.getString(BookingsViewMode.prefsKey);
    if (saved != null) {
      return BookingsViewMode.fromString(saved);
    }

    // Default based on platform
    // On mobile (iOS/Android), default to card view
    // On desktop/web, default to table view
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      return BookingsViewMode.card;
    } else {
      return BookingsViewMode.table;
    }
  }

  /// Toggle between card and table view
  Future<void> toggle() async {
    final newMode = state == BookingsViewMode.card
        ? BookingsViewMode.table
        : BookingsViewMode.card;
    await setView(newMode);
  }

  /// Set specific view mode and persist
  Future<void> setView(BookingsViewMode mode) async {
    state = mode;
    await _prefs.setString(BookingsViewMode.prefsKey, mode.name);
  }
}
