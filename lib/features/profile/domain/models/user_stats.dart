import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';
part 'user_stats.g.dart';

/// User statistics model combining all profile stats
/// Used to reduce multiple API calls into a single batch request
@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    /// Total number of bookings made by user
    @Default(0) int bookingsCount,

    /// Total number of favorited properties
    @Default(0) int favoritesCount,

    /// Total number of reviews written by user
    @Default(0) int reviewsCount,

    /// Average rating for properties owned by user (null if not an owner)
    double? averageRating,

    /// Total number of properties owned (for property owners)
    @Default(0) int propertiesCount,

    /// Timestamp when stats were fetched (for cache invalidation)
    DateTime? lastUpdated,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}
