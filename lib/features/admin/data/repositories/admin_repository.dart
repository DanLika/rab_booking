import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/admin_stats.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/booking_model.dart';

part 'admin_repository.g.dart';

@riverpod
AdminRepository adminRepository(Ref ref) {
  return AdminRepository(Supabase.instance.client);
}

/// Repository for admin operations
class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // ==================== STATISTICS ====================

  /// Get admin dashboard statistics
  Future<AdminStats> getAdminStats() async {
    try {
      // Get user stats
      final usersResponse = await _supabase
          .from('users')
          .select('id, created_at')
          .order('created_at', ascending: false) as List<dynamic>;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final totalUsers = usersResponse.length;
      final newUsersToday = usersResponse
          .where((u) => DateTime.parse(u['created_at']).isAfter(todayStart))
          .length;
      final newUsersThisWeek = usersResponse
          .where((u) => DateTime.parse(u['created_at']).isAfter(weekStart))
          .length;
      final newUsersThisMonth = usersResponse
          .where((u) => DateTime.parse(u['created_at']).isAfter(monthStart))
          .length;

      // Get property stats
      final propertiesResponse = await _supabase
          .from('properties')
          .select('id, is_active') as List<dynamic>;

      final totalProperties = propertiesResponse.length;
      final activeProperties =
          propertiesResponse.where((p) => p['is_active'] == true).length;

      // Get booking stats
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('id, status, total_price') as List<dynamic>;

      final totalBookings = bookingsResponse.length;
      final activeBookings =
          bookingsResponse.where((b) => b['status'] == 'confirmed').length;
      final completedBookings =
          bookingsResponse.where((b) => b['status'] == 'completed').length;
      final cancelledBookings =
          bookingsResponse.where((b) => b['status'] == 'cancelled').length;

      // Calculate revenue
      final totalRevenue = bookingsResponse
          .where((b) => b['status'] != 'cancelled')
          .fold<double>(
              0.0, (sum, b) => sum + (b['total_price'] as num).toDouble());

      final platformFee = totalRevenue * 0.15; // 15% platform fee

      return AdminStats(
        totalUsers: totalUsers,
        activeUsers: totalUsers, // TODO: Add last_seen tracking
        newUsersToday: newUsersToday,
        newUsersThisWeek: newUsersThisWeek,
        newUsersThisMonth: newUsersThisMonth,
        totalProperties: totalProperties,
        activeProperties: activeProperties,
        pendingProperties: 0, // TODO: Add approval system
        totalBookings: totalBookings,
        activeBookings: activeBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
        totalRevenue: totalRevenue,
        platformFeeTotal: platformFee,
        averageBookingValue: totalBookings > 0 ? totalRevenue / totalBookings : 0,
      );
    } catch (e) {
      throw Exception('Failed to load admin stats: $e');
    }
  }

  /// Get recent user activity
  Future<List<UserActivity>> getRecentActivity({int limit = 20}) async {
    try {
      // TODO: Implement activity logging table
      // For now, return recent bookings as activity
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            user_id,
            status,
            created_at,
            users!inner(full_name, email)
          ''')
          .order('created_at', ascending: false)
          .limit(limit) as List<dynamic>;

      return response.map((item) {
        return UserActivity(
          id: item['id'],
          userId: item['user_id'],
          userName: item['users']['full_name'],
          userEmail: item['users']['email'],
          action: 'created_booking',
          resourceType: 'booking',
          resourceId: item['id'],
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load recent activity: $e');
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get all users with pagination
  Future<List<UserModel>> getUsers({
    int page = 0,
    int pageSize = 50,
    String? searchQuery,
    String? role,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('users')
          .select('*');

      // Apply filters first
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or('full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      if (role != null && role != 'all') {
        queryBuilder = queryBuilder.eq('role', role);
      }

      // Then apply ordering and pagination
      final query = queryBuilder
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final response = await query as List<dynamic>;

      return response.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase
          .from('users')
          .update({'role': newRole})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Suspend/unsuspend user
  Future<void> toggleUserSuspension(String userId, bool suspend) async {
    try {
      await _supabase
          .from('users')
          .update({'is_suspended': suspend})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to toggle user suspension: $e');
    }
  }

  /// Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user's bookings first
      await _supabase.from('bookings').delete().eq('user_id', userId);

      // Delete user's properties if owner
      await _supabase.from('properties').delete().eq('owner_id', userId);

      // Delete user
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ==================== PROPERTY MANAGEMENT ====================

  /// Get all properties with filters
  Future<List<PropertyModel>> getProperties({
    int page = 0,
    int pageSize = 50,
    String? searchQuery,
    bool? isActive,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('properties')
          .select('*');

      // Apply filters first
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or('name.ilike.%$searchQuery%,location.ilike.%$searchQuery%');
      }

      if (isActive != null) {
        queryBuilder = queryBuilder.eq('is_active', isActive);
      }

      // Then apply ordering and pagination
      final query = queryBuilder
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final response = await query as List<dynamic>;

      return response.map((item) => PropertyModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load properties: $e');
    }
  }

  /// Toggle property active status
  Future<void> togglePropertyStatus(String propertyId, bool isActive) async {
    try {
      await _supabase
          .from('properties')
          .update({'is_active': isActive})
          .eq('id', propertyId);
    } catch (e) {
      throw Exception('Failed to toggle property status: $e');
    }
  }

  /// Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      // Delete associated units first
      await _supabase.from('units').delete().eq('property_id', propertyId);

      // Delete property bookings
      await _supabase.from('bookings').delete().eq('property_id', propertyId);

      // Delete property
      await _supabase.from('properties').delete().eq('id', propertyId);
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  // ==================== BOOKING MANAGEMENT ====================

  /// Get all bookings with filters
  Future<List<BookingModel>> getBookings({
    int page = 0,
    int pageSize = 50,
    String? status,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('bookings')
          .select('''
            *,
            users!inner(id, full_name, email),
            properties!inner(id, name, location)
          ''');

      // Apply filters first
      if (status != null && status != 'all') {
        queryBuilder = queryBuilder.eq('status', status);
      }

      // Then apply ordering and pagination
      final query = queryBuilder
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final response = await query as List<dynamic>;

      return response.map((item) {
        // Parse nested objects
        final bookingData = Map<String, dynamic>.from(item);
        bookingData['user_name'] = item['users']['full_name'];
        bookingData['user_email'] = item['users']['email'];
        bookingData['property_name'] = item['properties']['name'];
        bookingData['property_location'] = item['properties']['location'];

        return BookingModel.fromJson(bookingData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  /// Cancel booking (admin)
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _supabase
          .from('bookings')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // ==================== SYSTEM HEALTH ====================

  /// Get system health metrics
  Future<SystemHealth> getSystemHealth() async {
    try {
      // Check database connection
      final databaseHealthy = await _checkDatabaseHealth();

      return SystemHealth(
        databaseHealthy: databaseHealthy,
        storageHealthy: true, // TODO: Implement storage check
        realtimeHealthy: true, // TODO: Implement realtime check
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      return const SystemHealth(
        databaseHealthy: false,
        storageHealthy: false,
        realtimeHealthy: false,
      );
    }
  }

  Future<bool> _checkDatabaseHealth() async {
    try {
      await _supabase.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}
