import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_profile.freezed.dart';
part 'public_profile.g.dart';

/// Public profile model containing only non-sensitive user information
/// Used for displaying property owner details, reviews, etc.
///
/// This model does NOT include sensitive data like email or phone.
/// For full user data, use UserModel (only accessible to the user themselves).
@freezed
class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    /// User ID
    required String id,

    /// First name (required for display)
    @Default('') String firstName,

    /// Last name (optional)
    @Default('') String lastName,

    /// Avatar URL (optional)
    String? avatarUrl,

    /// User role (guest, owner, admin)
    @Default('guest') String role,

    /// Account creation date
    DateTime? createdAt,
  }) = _PublicProfile;

  const PublicProfile._();

  /// Get full name (first + last)
  String get fullName {
    if (lastName.isEmpty) return firstName;
    return '$firstName $lastName'.trim();
  }

  /// Get display name (full name or "Anonymous" if empty)
  String get displayName {
    final name = fullName;
    return name.isEmpty ? 'Anonymous User' : name;
  }

  /// Get initials for avatar (e.g., "John Doe" -> "JD")
  String get initials {
    if (firstName.isEmpty) return '?';
    if (lastName.isEmpty) return firstName[0].toUpperCase();
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  /// Check if user is a property owner
  bool get isOwner => role == 'owner' || role == 'admin';

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);
}
