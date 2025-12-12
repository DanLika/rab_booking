import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/booking_repository.dart';
// Tab Communication Service (cross-tab communication for Stripe payments)
import '../../core/services/tab_communication_service.dart';
import '../repositories/daily_price_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/unit_repository.dart';
import '../repositories/firebase/firebase_booking_repository.dart';
import '../../features/widget/data/repositories/firebase_daily_price_repository.dart';
import '../repositories/firebase/firebase_property_repository.dart';
import '../repositories/firebase/firebase_unit_repository.dart';
// Owner Dashboard imports
import '../../features/owner_dashboard/data/firebase/firebase_owner_properties_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_analytics_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_revenue_analytics_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_property_performance_repository.dart';
// Widget imports
import '../../features/widget/data/repositories/firebase_widget_settings_repository.dart';
// Services
import '../../core/services/booking_service.dart';
import '../../core/services/stripe_service.dart';
import '../../core/services/ical_export_service.dart';
// iCal Repository
import '../../features/owner_dashboard/data/firebase/firebase_ical_repository.dart';
// Calendar Data Service
import '../../features/widget/domain/services/calendar_data_service.dart';

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firebase Storage instance provider
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// SharedPreferences instance provider
/// Must be overridden in main.dart with the actual instance
/// Returns null if not yet initialized (during splash screen phase)
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  // Return null instead of throwing error - allows app to work during initialization
  // The provider will be overridden in main.dart once SharedPreferences is ready
  return null;
});

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

// ========== Owner Dashboard Repositories ==========

/// Widget Settings repository provider
final widgetSettingsRepositoryProvider = Provider<FirebaseWidgetSettingsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseWidgetSettingsRepository(firestore);
});

/// Owner Properties repository provider
final ownerPropertiesRepositoryProvider = Provider<FirebaseOwnerPropertiesRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  final widgetSettingsRepo = ref.watch(widgetSettingsRepositoryProvider);
  return FirebaseOwnerPropertiesRepository(firestore, storage, widgetSettingsRepo);
});

/// Owner Bookings repository provider
final ownerBookingsRepositoryProvider = Provider<FirebaseOwnerBookingsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FirebaseOwnerBookingsRepository(firestore, auth);
});

/// Analytics repository provider
final analyticsRepositoryProvider = Provider<FirebaseAnalyticsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseAnalyticsRepository(firestore);
});

/// Revenue Analytics repository provider
final revenueAnalyticsRepositoryProvider = Provider<FirebaseRevenueAnalyticsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseRevenueAnalyticsRepository(firestore);
});

/// Property Performance repository provider
final propertyPerformanceRepositoryProvider = Provider<FirebasePropertyPerformanceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebasePropertyPerformanceRepository(firestore);
});

// ========== Services ==========

/// Firebase Functions instance provider
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

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

/// iCal Export Service provider
final icalExportServiceProvider = Provider<IcalExportService>((ref) {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final storage = ref.watch(firebaseStorageProvider);
  return IcalExportService(bookingRepository: bookingRepository, storage: storage);
});

// ========== iCal Repository ==========

/// iCal Repository provider (centralized - replaces duplicates in widget/owner_dashboard)
final icalRepositoryProvider = Provider<FirebaseIcalRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseIcalRepository(firestore);
});

// ========== Calendar Data Service ==========

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

// ========== Tab Communication Service ==========

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
