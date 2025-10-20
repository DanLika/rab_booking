import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_stats.freezed.dart';
part 'admin_stats.g.dart';

/// Admin dashboard statistics
@freezed
class AdminStats with _$AdminStats {
  const factory AdminStats({
    // User statistics
    @Default(0) int totalUsers,
    @Default(0) int activeUsers,
    @Default(0) int newUsersToday,
    @Default(0) int newUsersThisWeek,
    @Default(0) int newUsersThisMonth,

    // Property statistics
    @Default(0) int totalProperties,
    @Default(0) int activeProperties,
    @Default(0) int pendingProperties,
    @Default(0) int rejectedProperties,

    // Booking statistics
    @Default(0) int totalBookings,
    @Default(0) int activeBookings,
    @Default(0) int completedBookings,
    @Default(0) int cancelledBookings,

    // Revenue statistics
    @Default(0.0) double totalRevenue,
    @Default(0.0) double revenueToday,
    @Default(0.0) double revenueThisWeek,
    @Default(0.0) double revenueThisMonth,

    // Platform statistics
    @Default(0.0) double platformFeeTotal,
    @Default(0.0) double averageBookingValue,
    @Default(0.0) double occupancyRate,
  }) = _AdminStats;

  const AdminStats._();

  factory AdminStats.fromJson(Map<String, dynamic> json) =>
      _$AdminStatsFromJson(json);
}

/// User activity entry for recent activity feed
@freezed
class UserActivity with _$UserActivity {
  const factory UserActivity({
    required String id,
    required String userId,
    String? userName,
    String? userEmail,
    required String action,
    required String resourceType,
    String? resourceId,
    String? resourceName,
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserActivity;

  const UserActivity._();

  factory UserActivity.fromJson(Map<String, dynamic> json) =>
      _$UserActivityFromJson(json);
}

/// System health metrics
@freezed
class SystemHealth with _$SystemHealth {
  const factory SystemHealth({
    @Default(true) bool databaseHealthy,
    @Default(true) bool storageHealthy,
    @Default(true) bool realtimeHealthy,
    @Default(0) int activeConnections,
    @Default(0.0) double cpuUsage,
    @Default(0.0) double memoryUsage,
    DateTime? lastChecked,
  }) = _SystemHealth;

  const SystemHealth._();

  factory SystemHealth.fromJson(Map<String, dynamic> json) =>
      _$SystemHealthFromJson(json);
}
