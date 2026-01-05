import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Key for SharedPreferences storage
const String _showEmptyUnitsPrefsKey = 'calendar_show_empty_units';

/// Provider for show empty units preference in timeline calendar
/// Persists user's preference across app restarts
final showEmptyUnitsProvider =
    StateNotifierProvider<ShowEmptyUnitsNotifier, bool>((ref) {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs == null) {
        return ShowEmptyUnitsNotifier.withDefault();
      }
      return ShowEmptyUnitsNotifier(prefs);
    });

/// State notifier for show empty units preference with persistence
class ShowEmptyUnitsNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  ShowEmptyUnitsNotifier(this._prefs) : super(_loadSavedPreference(_prefs));

  /// Create notifier with default value (used when SharedPreferences is not yet initialized)
  factory ShowEmptyUnitsNotifier.withDefault() {
    return ShowEmptyUnitsNotifier(null);
  }

  /// Load saved preference from SharedPreferences
  /// Default: true (show all units including empty ones)
  static bool _loadSavedPreference(SharedPreferences? prefs) {
    if (prefs == null) return true;
    return prefs.getBool(_showEmptyUnitsPrefsKey) ?? true;
  }

  /// Toggle the preference
  Future<void> toggle() async {
    await setValue(!state);
  }

  /// Set specific value and persist
  Future<void> setValue(bool value) async {
    state = value;
    if (_prefs != null) {
      await _prefs.setBool(_showEmptyUnitsPrefsKey, value);
    }
  }
}
