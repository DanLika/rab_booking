import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/calendar_view_mode.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Provider for current owner calendar view mode
/// Persists user's last selected view (week/month/timeline)
final ownerCalendarViewProvider =
    StateNotifierProvider<OwnerCalendarViewNotifier, CalendarViewMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OwnerCalendarViewNotifier(prefs);
});

/// State notifier for calendar view mode with persistence
class OwnerCalendarViewNotifier extends StateNotifier<CalendarViewMode> {
  final SharedPreferences _prefs;

  OwnerCalendarViewNotifier(this._prefs) : super(_loadSavedView(_prefs));

  /// Load saved view from SharedPreferences
  static CalendarViewMode _loadSavedView(SharedPreferences prefs) {
    final saved = prefs.getString(CalendarViewMode.prefsKey);
    return CalendarViewMode.fromString(saved);
  }

  /// Change view and persist to SharedPreferences
  Future<void> setView(CalendarViewMode mode) async {
    state = mode;
    await _prefs.setString(CalendarViewMode.prefsKey, mode.name);
  }
}
