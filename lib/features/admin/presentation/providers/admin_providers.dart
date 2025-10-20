import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_stats.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/booking_model.dart';

part 'admin_providers.g.dart';

// ==================== STATISTICS ====================

@riverpod
Future<AdminStats> adminStats(Ref ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getAdminStats();
}

@riverpod
Future<List<UserActivity>> recentActivity(Ref ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getRecentActivity(limit: 20);
}

@riverpod
Future<SystemHealth> systemHealth(Ref ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSystemHealth();
}

// ==================== USER MANAGEMENT ====================

/// State for user filters
@riverpod
class AdminUserFilters extends _$AdminUserFilters {
  @override
  ({String? searchQuery, String? role, int page}) build() {
    return (searchQuery: null, role: 'all', page: 0);
  }

  void setSearchQuery(String? query) {
    state = (searchQuery: query, role: state.role, page: 0);
  }

  void setRole(String? role) {
    state = (searchQuery: state.searchQuery, role: role, page: 0);
  }

  void setPage(int page) {
    state = (searchQuery: state.searchQuery, role: state.role, page: page);
  }

  void reset() {
    state = (searchQuery: null, role: 'all', page: 0);
  }
}

@riverpod
Future<List<UserModel>> adminUsers(Ref ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filters = ref.watch(adminUserFiltersProvider);

  return await repository.getUsers(
    page: filters.page,
    searchQuery: filters.searchQuery,
    role: filters.role,
  );
}

// ==================== PROPERTY MANAGEMENT ====================

/// State for property filters
@riverpod
class AdminPropertyFilters extends _$AdminPropertyFilters {
  @override
  ({String? searchQuery, bool? isActive, int page}) build() {
    return (searchQuery: null, isActive: null, page: 0);
  }

  void setSearchQuery(String? query) {
    state = (searchQuery: query, isActive: state.isActive, page: 0);
  }

  void setActiveStatus(bool? isActive) {
    state = (searchQuery: state.searchQuery, isActive: isActive, page: 0);
  }

  void setPage(int page) {
    state = (searchQuery: state.searchQuery, isActive: state.isActive, page: page);
  }

  void reset() {
    state = (searchQuery: null, isActive: null, page: 0);
  }
}

@riverpod
Future<List<PropertyModel>> adminProperties(Ref ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filters = ref.watch(adminPropertyFiltersProvider);

  return await repository.getProperties(
    page: filters.page,
    searchQuery: filters.searchQuery,
    isActive: filters.isActive,
  );
}

// ==================== BOOKING MANAGEMENT ====================

/// State for booking filters
@riverpod
class AdminBookingFilters extends _$AdminBookingFilters {
  @override
  ({String? status, int page}) build() {
    return (status: 'all', page: 0);
  }

  void setStatus(String? status) {
    state = (status: status, page: 0);
  }

  void setPage(int page) {
    state = (status: state.status, page: page);
  }

  void reset() {
    state = (status: 'all', page: 0);
  }
}

@riverpod
Future<List<BookingModel>> adminBookings(Ref ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final filters = ref.watch(adminBookingFiltersProvider);

  return await repository.getBookings(
    page: filters.page,
    status: filters.status,
  );
}
