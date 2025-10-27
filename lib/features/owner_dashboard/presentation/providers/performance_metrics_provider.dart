import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/firebase/firebase_property_performance_repository.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'performance_metrics_provider.g.dart';

/// Get occupancy rate
@riverpod
Future<double> occupancyRate(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) return 0.0;

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getOccupancyRate(userId);
}

/// Get occupancy trend
@riverpod
Future<double> occupancyTrend(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) return 0.0;

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getOccupancyTrend(userId);
}

/// Get total bookings count
@riverpod
Future<int> totalBookingsCount(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) return 0;

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getTotalBookingsCount(userId);
}

/// Get bookings trend
@riverpod
Future<double> bookingsTrend(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) return 0.0;

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getBookingsTrend(userId);
}

/// Get active listings count
@riverpod
Future<int> activeListingsCount(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) return 0;

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getActiveListingsCount(userId);
}

/// Get cancellation rate
@riverpod
Future<double> cancellationRate(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) return 0.0;

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getCancellationRate(userId);
}

/// Get complete performance stats
@riverpod
Future<PerformanceStats> performanceStats(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  if (userId == null) {
    return PerformanceStats(
      occupancyRate: 0.0,
      occupancyTrend: 0.0,
      totalBookings: 0,
      bookingsTrend: 0.0,
      activeListings: 0,
      cancellationRate: 0.0,
    );
  }

  final repository = ref.watch(propertyPerformanceRepositoryProvider);
  return repository.getPerformanceStats(userId);
}
