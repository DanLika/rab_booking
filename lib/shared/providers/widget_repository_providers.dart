/// Widget-only repository providers.
///
/// This file contains ONLY the providers needed by the booking widget.
/// It excludes owner dashboard repositories to reduce the widget bundle size.
///
/// IMPORTANT: Do NOT import owner dashboard repositories here!
/// This file is designed to be imported by widget_main.dart to avoid
/// pulling in unnecessary code that inflates the JS bundle.
///
/// For owner dashboard, use repository_providers.dart which re-exports
/// this file plus owner-specific providers.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models needed for providers
import '../models/property_model.dart';
import '../models/unit_model.dart';

// Core repositories (shared between widget and owner)
import '../repositories/booking_repository.dart';
import '../repositories/daily_price_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/unit_repository.dart';
import '../repositories/firebase/firebase_booking_repository.dart';
import '../repositories/firebase/firebase_property_repository.dart';
import '../repositories/firebase/firebase_unit_repository.dart';
import '../../features/widget/data/repositories/firebase_daily_price_repository.dart';
import '../../features/widget/data/repositories/firebase_widget_settings_repository.dart';

// Services (widget needs these)
import '../../core/services/booking_service.dart';
import '../../core/services/stripe_service.dart';
import '../../core/services/tab_communication_service.dart';
import '../../features/widget/domain/services/calendar_data_service.dart';

// iCal Repository (widget needs for calendar sync status display)
import '../../features/owner_dashboard/data/firebase/firebase_ical_repository.dart';

// ========== Firebase Instance Providers ==========

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// SharedPreferences instance provider
/// Must be overridden in main.dart with the actual instance
/// Returns null if not yet initialized (during splash screen phase)
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  // Return null instead of throwing error - allows app to work during initialization
  // The provider will be overridden in main.dart once SharedPreferences is ready
  return null;
});

/// Firebase Functions instance provider
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

// Alias for compatibility with existing code
final functionsProvider = firebaseFunctionsProvider;

// ========== Core Repository Providers ==========

/// Property repository provider
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebasePropertyRepository(firestore);
});

/// Unit repository provider
final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseUnitRepository(firestore);
});

/// Booking repository provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseBookingRepository(firestore);
});

/// Daily Price repository provider
final dailyPriceRepositoryProvider = Provider<DailyPriceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseDailyPriceRepository(firestore);
});

/// Widget Settings repository provider
final widgetSettingsRepositoryProvider = Provider<FirebaseWidgetSettingsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseWidgetSettingsRepository(firestore);
});

/// iCal Repository provider
/// Widget uses this for displaying calendar sync status
final icalRepositoryProvider = Provider<FirebaseIcalRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseIcalRepository(firestore);
});

// ========== Service Providers ==========

/// Booking Service provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return BookingService(firestore: firestore);
});

/// Stripe Service provider
final stripeServiceProvider = Provider<StripeService>((ref) {
  final functions = ref.watch(firebaseFunctionsProvider);
  return StripeService(functions: functions);
});

/// Calendar Data Service provider
/// Provides centralized calendar logic (gap blocking, price calculation, booking status)
final calendarDataServiceProvider = Provider<CalendarDataService>((ref) {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final dailyPriceRepository = ref.watch(dailyPriceRepositoryProvider);
  final icalRepository = ref.watch(icalRepositoryProvider);
  return CalendarDataService(
    bookingRepository: bookingRepository,
    dailyPriceRepository: dailyPriceRepository,
    icalRepository: icalRepository,
  );
});

/// Tab Communication Service provider
/// Provides cross-tab communication for Stripe payment flow
/// When payment completes in one tab, other tabs are notified to update UI
///
/// On web: Uses BroadcastChannel API (with localStorage fallback)
/// On mobile/desktop: Returns stub (no cross-tab communication needed)
///
/// NOTE: The actual web implementation is created directly in booking_widget_screen.dart
/// using conditional imports to avoid dart:html issues on non-web platforms.
final tabCommunicationServiceProvider = Provider<TabCommunicationService>((ref) {
  // Return stub - actual implementation created in widget screen
  // This is because conditional imports for dart:html are tricky with providers
  return TabCommunicationServiceStub();
});

// ========== Widget-Specific Data Providers ==========
// These providers are needed by subdomain_provider and widget_context_provider
// to avoid importing owner_properties_provider which pulls in owner dashboard code.

/// Get property by ID (widget version - uses PropertyRepository)
/// This is a lightweight alternative to owner_properties_provider.propertyByIdProvider
/// Named widgetPropertyByIdProvider to avoid conflict with the owner version
final widgetPropertyByIdProvider = FutureProvider.family<PropertyModel?, String>((ref, propertyId) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return repository.fetchPropertyById(propertyId);
});

/// Get unit by ID (widget version - direct Firestore query)
/// This is a lightweight alternative to owner_properties_provider.unitByIdProvider
/// Uses direct Firestore access for efficiency (single doc fetch)
final unitByIdProvider = FutureProvider.family<UnitModel?, (String, String)>((ref, params) async {
  final (propertyId, unitId) = params;
  final firestore = ref.watch(firestoreProvider);

  try {
    final doc = await firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return UnitModel.fromJson({...doc.data()!, 'id': doc.id});
  } catch (e) {
    return null;
  }
});
