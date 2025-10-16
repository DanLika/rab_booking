import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/enums.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model representing a user in the system
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    /// User ID (UUID from Supabase Auth)
    required String id,

    /// User email address
    required String email,

    /// User's first name
    required String firstName,

    /// User's last name
    required String lastName,

    /// User role (guest, owner, admin)
    required UserRole role,

    /// Optional phone number
    String? phone,

    /// Optional avatar URL
    String? avatarUrl,

    /// Account creation timestamp
    required DateTime createdAt,

    /// Last update timestamp
    DateTime? updatedAt,
  }) = _UserModel;

  const UserModel._();

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Check if user has completed profile
  bool get hasCompletedProfile {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty;
  }

  /// Check if user is a property owner
  bool get isOwner => role == UserRole.owner || role == UserRole.admin;

  /// Check if user is an admin
  bool get isAdmin => role == UserRole.admin;
}
