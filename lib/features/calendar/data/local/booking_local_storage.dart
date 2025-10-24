import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for offline booking queue
class BookingLocalStorage {
  static const _pendingBookingsKey = 'pending_bookings';

  final SharedPreferences _prefs;

  BookingLocalStorage(this._prefs);

  // =============================================================================
  // PENDING BOOKINGS
  // =============================================================================

  /// Save a pending booking
  Future<void> savePendingBooking(Map<String, dynamic> bookingData) async {
    final pending = await getPendingBookings();

    // Add timestamp and unique ID
    final booking = {
      ...bookingData,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'queued_at': DateTime.now().toIso8601String(),
    };

    pending.add(booking);

    await _prefs.setString(
      _pendingBookingsKey,
      jsonEncode(pending),
    );
  }

  /// Get all pending bookings
  Future<List<Map<String, dynamic>>> getPendingBookings() async {
    final data = _prefs.getString(_pendingBookingsKey);
    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Delete a pending booking
  Future<void> deletePendingBooking(String id) async {
    final pending = await getPendingBookings();
    pending.removeWhere((b) => b['id'] == id);

    await _prefs.setString(
      _pendingBookingsKey,
      jsonEncode(pending),
    );
  }

  /// Clear all pending bookings
  Future<void> clearPendingBookings() async {
    await _prefs.remove(_pendingBookingsKey);
  }

  /// Get count of pending bookings
  Future<int> getPendingCount() async {
    final pending = await getPendingBookings();
    return pending.length;
  }

  // =============================================================================
  // CACHED AVAILABILITY
  // =============================================================================

  /// Cache calendar availability data
  Future<void> cacheAvailability(
    String unitId,
    DateTime month,
    List<Map<String, dynamic>> data,
  ) async {
    final key = _getAvailabilityKey(unitId, month);
    final cacheData = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(key, jsonEncode(cacheData));
  }

  /// Get cached availability data
  Future<List<Map<String, dynamic>>?> getCachedAvailability(
    String unitId,
    DateTime month, {
    Duration maxAge = const Duration(minutes: 5),
  }) async {
    final key = _getAvailabilityKey(unitId, month);
    final data = _prefs.getString(key);

    if (data == null) return null;

    final Map<String, dynamic> cacheData = jsonDecode(data);
    final cachedAt = DateTime.parse(cacheData['cached_at']);

    // Check if cache is still fresh
    if (DateTime.now().difference(cachedAt) > maxAge) {
      return null; // Cache expired
    }

    final List<dynamic> availability = cacheData['data'];
    return availability.cast<Map<String, dynamic>>();
  }

  /// Clear cached availability
  Future<void> clearAvailabilityCache() async {
    final keys = _prefs.getKeys();
    final availabilityKeys = keys.where((k) => k.startsWith('availability_'));

    for (final key in availabilityKeys) {
      await _prefs.remove(key);
    }
  }

  /// Get availability cache key
  String _getAvailabilityKey(String unitId, DateTime month) {
    return 'availability_${unitId}_${month.year}_${month.month}';
  }

  // =============================================================================
  // BOOKING DRAFT
  // =============================================================================

  /// Save booking draft (for multi-step process)
  Future<void> saveDraft(String unitId, Map<String, dynamic> draftData) async {
    final key = 'draft_$unitId';
    final draft = {
      ...draftData,
      'saved_at': DateTime.now().toIso8601String(),
    };

    await _prefs.setString(key, jsonEncode(draft));
  }

  /// Get booking draft
  Future<Map<String, dynamic>?> getDraft(
    String unitId, {
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final key = 'draft_$unitId';
    final data = _prefs.getString(key);

    if (data == null) return null;

    final Map<String, dynamic> draft = jsonDecode(data);
    final savedAt = DateTime.parse(draft['saved_at']);

    // Check if draft is still valid
    if (DateTime.now().difference(savedAt) > maxAge) {
      await deleteDraft(unitId);
      return null;
    }

    return draft;
  }

  /// Delete booking draft
  Future<void> deleteDraft(String unitId) async {
    final key = 'draft_$unitId';
    await _prefs.remove(key);
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    final keys = _prefs.getKeys();
    final draftKeys = keys.where((k) => k.startsWith('draft_'));

    for (final key in draftKeys) {
      await _prefs.remove(key);
    }
  }
}
