import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/calendar_update_event.dart';

part 'calendar_update_tracker.g.dart';

/// Tracks recently updated dates for animation purposes
@riverpod
class CalendarUpdateTracker extends _$CalendarUpdateTracker {
  static const _animationDuration = Duration(milliseconds: 800);
  static const _trackingDuration = Duration(seconds: 3);

  @override
  Map<DateTime, UpdateInfo> build() {
    return {};
  }

  /// Mark a date as updated
  void markUpdated(DateTime date, CalendarUpdateAction action) {
    final now = DateTime.now();
    state = {
      ...state,
      date: UpdateInfo(
        action: action,
        timestamp: now,
      ),
    };

    // Schedule removal after tracking duration
    Future.delayed(_trackingDuration, () {
      if (mounted) {
        _removeUpdate(date);
      }
    });
  }

  /// Mark multiple dates as updated (e.g., for a booking range)
  void markRangeUpdated(
    DateTime startDate,
    DateTime endDate,
    CalendarUpdateAction action,
  ) {
    final now = DateTime.now();
    final updates = <DateTime, UpdateInfo>{};

    var current = startDate;
    while (current.isBefore(endDate) ||
        current.isAtSameMomentAs(endDate)) {
      updates[current] = UpdateInfo(
        action: action,
        timestamp: now,
      );
      current = current.add(const Duration(days: 1));
    }

    state = {...state, ...updates};

    // Schedule removal
    Future.delayed(_trackingDuration, () {
      if (mounted) {
        _removeRangeUpdates(startDate, endDate);
      }
    });
  }

  /// Check if a date was recently updated
  bool isRecentlyUpdated(DateTime date) {
    final info = state[date];
    if (info == null) return false;

    final age = DateTime.now().difference(info.timestamp);
    return age < _trackingDuration;
  }

  /// Get update info for a date
  UpdateInfo? getUpdateInfo(DateTime date) {
    return state[date];
  }

  /// Remove update marker
  void _removeUpdate(DateTime date) {
    final newState = Map<DateTime, UpdateInfo>.from(state);
    newState.remove(date);
    state = newState;
  }

  /// Remove update markers for a range
  void _removeRangeUpdates(DateTime startDate, DateTime endDate) {
    final newState = Map<DateTime, UpdateInfo>.from(state);
    var current = startDate;
    while (current.isBefore(endDate) ||
        current.isAtSameMomentAs(endDate)) {
      newState.remove(current);
      current = current.add(const Duration(days: 1));
    }
    state = newState;
  }

  /// Clear all updates
  void clearAll() {
    state = {};
  }

  /// Get all currently tracked updates
  List<DateTime> getTrackedDates() {
    return state.keys.toList();
  }
}

/// Information about a calendar update
class UpdateInfo {
  final CalendarUpdateAction action;
  final DateTime timestamp;

  UpdateInfo({
    required this.action,
    required this.timestamp,
  });

  /// Age of this update
  Duration get age => DateTime.now().difference(timestamp);

  /// Whether this update is still fresh (for animations)
  bool get isFresh => age < const Duration(milliseconds: 800);
}

/// Provider for conflict detection
@riverpod
class CalendarConflictDetector extends _$CalendarConflictDetector {
  @override
  Set<DateTime> build() {
    return {};
  }

  /// Check if selected dates conflict with recent updates
  void checkConflicts(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) {
      state = {};
      return;
    }

    final updateTracker = ref.read(calendarUpdateTrackerProvider);
    final conflicts = <DateTime>{};

    var current = checkIn;
    while (current.isBefore(checkOut) ||
        current.isAtSameMomentAs(checkOut)) {
      if (updateTracker.containsKey(current)) {
        conflicts.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    state = conflicts;
  }

  /// Mark specific dates as conflicting
  void markConflicts(Set<DateTime> dates) {
    state = dates;
  }

  /// Check if a specific date has a conflict
  bool hasConflict(DateTime date) {
    return state.contains(date);
  }

  /// Clear all conflicts
  void clearConflicts() {
    state = {};
  }

  /// Get conflict count
  int get conflictCount => state.length;

  /// Get all conflicting dates
  List<DateTime> getConflictingDates() {
    return state.toList()..sort();
  }
}

/// Provider for managing update notifications
@riverpod
class UpdateNotificationManager extends _$UpdateNotificationManager {
  @override
  List<UpdateNotification> build() {
    return [];
  }

  /// Show a notification
  void show({
    required String message,
    required CalendarUpdateAction action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final notification = UpdateNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      action: action,
      timestamp: DateTime.now(),
      duration: duration,
    );

    state = [...state, notification];

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (mounted) {
        dismiss(notification.id);
      }
    });
  }

  /// Dismiss a notification
  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  /// Dismiss all notifications
  void dismissAll() {
    state = [];
  }

  /// Get active notifications
  List<UpdateNotification> get activeNotifications => state;
}

/// Update notification model
class UpdateNotification {
  final String id;
  final String message;
  final CalendarUpdateAction action;
  final DateTime timestamp;
  final Duration duration;

  UpdateNotification({
    required this.id,
    required this.message,
    required this.action,
    required this.timestamp,
    required this.duration,
  });
}
