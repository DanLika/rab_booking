import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/validation_result.dart';
import '../../domain/services/booking_validator.dart';
import '../../domain/services/edge_case_handlers.dart';
import '../../data/local/booking_local_storage.dart';

part 'booking_validation_provider.g.dart';

// =============================================================================
// BOOKING SETTINGS PROVIDER
// =============================================================================

/// Provider for booking settings
@riverpod
class BookingSettingsNotifier extends _$BookingSettingsNotifier {
  @override
  Future<BookingSettings> build(String unitId) async {
    // Fetch settings from database or use defaults
    return _fetchSettings(unitId);
  }

  Future<BookingSettings> _fetchSettings(String unitId) async {
    try {
      final supabase = Supabase.instance.client;

      // Get unit-specific settings
      final data = await supabase
          .from('units')
          .select('booking_settings')
          .eq('id', unitId)
          .maybeSingle();

      if (data == null || data['booking_settings'] == null) {
        // Return default settings
        return const BookingSettings();
      }

      // Parse settings from JSON
      return BookingSettings.fromJson(
        data['booking_settings'] as Map<String, dynamic>,
      );
    } catch (e) {
      // On error, return defaults
      return const BookingSettings();
    }
  }

  /// Update settings
  Future<void> updateSettings(BookingSettings settings) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('units')
          .update({'booking_settings': settings.toJson()})
          .eq('id', unitId);

      state = AsyncValue.data(settings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// =============================================================================
// BOOKING VALIDATOR PROVIDER
// =============================================================================

/// Provider for booking validator
@riverpod
BookingValidator bookingValidator(
  BookingValidatorRef ref,
  String unitId,
) {
  final supabase = Supabase.instance.client;
  final settingsAsync = ref.watch(bookingSettingsNotifierProvider(unitId));

  final settings = settingsAsync.when(
    data: (s) => s,
    loading: () => const BookingSettings(), // Use defaults while loading
    error: (_, __) => const BookingSettings(),
  );

  return BookingValidator(
    supabase: supabase,
    settings: settings,
  );
}

// =============================================================================
// VALIDATION PROVIDERS
// =============================================================================

/// Validate date range
@riverpod
Future<ValidationResult> validateDateRange(
  ValidateDateRangeRef ref,
  String unitId,
  DateTime checkIn,
  DateTime checkOut,
) async {
  final validator = ref.watch(bookingValidatorProvider(unitId));
  return validator.validateDateRange(checkIn, checkOut);
}

/// Check for booking conflicts
@riverpod
Future<ValidationResult> checkBookingConflict(
  CheckBookingConflictRef ref,
  String unitId,
  DateTime checkIn,
  DateTime checkOut,
) async {
  final validator = ref.watch(bookingValidatorProvider(unitId));
  return validator.checkConflicts(unitId, checkIn, checkOut);
}

/// Validate full booking (all rules)
@riverpod
Future<ValidationResult> validateFullBooking(
  ValidateFullBookingRef ref,
  String unitId,
  DateTime checkIn,
  DateTime checkOut,
) async {
  final validator = ref.watch(bookingValidatorProvider(unitId));
  return validator.validateBooking(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
  );
}

// =============================================================================
// ATOMIC BOOKING HANDLER PROVIDER
// =============================================================================

/// Provider for atomic booking handler
@riverpod
AtomicBookingHandler atomicBookingHandler(AtomicBookingHandlerRef ref) {
  final supabase = Supabase.instance.client;
  return AtomicBookingHandler(supabase);
}

// =============================================================================
// OFFLINE BOOKING QUEUE PROVIDER
// =============================================================================

/// Provider for local storage
@riverpod
Future<BookingLocalStorage> bookingLocalStorage(
  BookingLocalStorageRef ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return BookingLocalStorage(prefs);
}

/// Provider for offline booking queue
@riverpod
Future<OfflineBookingQueue> offlineBookingQueue(
  OfflineBookingQueueRef ref,
) async {
  final localStorage = await ref.watch(bookingLocalStorageProvider.future);
  final atomicHandler = ref.watch(atomicBookingHandlerProvider);

  return OfflineBookingQueue(
    localStorage: localStorage,
    atomicHandler: atomicHandler,
  );
}

/// Provider for pending booking count
@riverpod
Future<int> pendingBookingCount(PendingBookingCountRef ref) async {
  final localStorage = await ref.watch(bookingLocalStorageProvider.future);
  return localStorage.getPendingCount();
}

// =============================================================================
// TIME ZONE HANDLER PROVIDER
// =============================================================================

/// Provider for time zone handler
@riverpod
TimeZoneHandler timeZoneHandler(
  TimeZoneHandlerRef ref,
  String propertyTimeZone,
) {
  return TimeZoneHandler(propertyTimeZone: propertyTimeZone);
}

// =============================================================================
// OWNER CONFLICT HANDLER PROVIDER
// =============================================================================

/// Provider for owner conflict handler
@riverpod
OwnerConflictHandler ownerConflictHandler(OwnerConflictHandlerRef ref) {
  final supabase = Supabase.instance.client;
  return OwnerConflictHandler(supabase);
}

/// Check for blocking conflicts
@riverpod
Future<List<BookingConflict>> checkBlockingConflicts(
  CheckBlockingConflictsRef ref,
  String unitId,
  DateTime from,
  DateTime to,
) async {
  final handler = ref.watch(ownerConflictHandlerProvider);
  return handler.getConflictingBookings(
    unitId: unitId,
    from: from,
    to: to,
  );
}

// =============================================================================
// REALTIME CONFLICT DETECTOR PROVIDER
// =============================================================================

/// Provider for realtime conflict detector
@riverpod
RealtimeConflictDetector realtimeConflictDetector(
  RealtimeConflictDetectorRef ref,
) {
  final supabase = Supabase.instance.client;
  return RealtimeConflictDetector(supabase);
}

/// Watch availability during booking flow
@riverpod
Stream<bool> watchAvailability(
  WatchAvailabilityRef ref,
  String unitId,
  DateTime checkIn,
  DateTime checkOut,
) {
  final detector = ref.watch(realtimeConflictDetectorProvider);
  return detector.watchAvailability(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
  );
}

// =============================================================================
// VALIDATION STATE NOTIFIER
// =============================================================================

/// State for comprehensive validation
class ValidationState {
  final bool isValidating;
  final ValidationResult? result;
  final DateTime? lastChecked;

  ValidationState({
    this.isValidating = false,
    this.result,
    this.lastChecked,
  });

  ValidationState copyWith({
    bool? isValidating,
    ValidationResult? result,
    DateTime? lastChecked,
  }) {
    return ValidationState(
      isValidating: isValidating ?? this.isValidating,
      result: result ?? this.result,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// Provider for managing validation state
@riverpod
class BookingValidationState extends _$BookingValidationState {
  @override
  ValidationState build(String unitId) {
    return ValidationState();
  }

  /// Validate booking comprehensively
  Future<void> validate(DateTime checkIn, DateTime checkOut) async {
    state = state.copyWith(isValidating: true);

    try {
      final validator = ref.read(bookingValidatorProvider(unitId));

      final result = await validator.validateBooking(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      state = state.copyWith(
        isValidating: false,
        result: result,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isValidating: false,
        result: ValidationResult.error(e.toString()),
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Clear validation
  void clear() {
    state = ValidationState();
  }

  /// Check if validation is still fresh (within 30 seconds)
  bool get isFresh {
    if (state.lastChecked == null) return false;
    final age = DateTime.now().difference(state.lastChecked!);
    return age < const Duration(seconds: 30);
  }
}
