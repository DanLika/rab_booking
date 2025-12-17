/// Full repository providers including owner dashboard.
///
/// This file re-exports widget_repository_providers.dart and adds
/// owner-specific providers that are not needed by the booking widget.
///
/// For widget-only builds, import widget_repository_providers.dart directly
/// to avoid pulling in owner dashboard code.
library;

// Re-export all widget providers for backward compatibility
export 'widget_repository_providers.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import widget providers to use in owner-specific providers
import 'widget_repository_providers.dart';

// Owner Dashboard repositories
import '../../features/owner_dashboard/data/firebase/firebase_owner_properties_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_analytics_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_revenue_analytics_repository.dart';
import '../../features/owner_dashboard/data/firebase/firebase_property_performance_repository.dart';

// Services (owner-only)
import '../../core/services/ical_export_service.dart';

// ========== Owner-Only Firebase Instance Providers ==========

/// Firebase Auth instance provider (owner dashboard needs authentication)
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firebase Storage instance provider (owner dashboard needs file uploads)
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ========== Owner Dashboard Repository Providers ==========

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

// ========== Owner-Only Service Providers ==========

/// iCal Export Service provider (owner dashboard exports iCal feeds)
final icalExportServiceProvider = Provider<IcalExportService>((ref) {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  final storage = ref.watch(firebaseStorageProvider);
  return IcalExportService(bookingRepository: bookingRepository, storage: storage);
});
