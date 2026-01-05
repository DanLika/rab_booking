import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_credentials.freezed.dart';

/// Saved login credentials (email only)
/// Used by SecureStorageService to persist "Remember Me" login state
///
/// SECURITY FIX SF-007: Password field removed.
/// Storing passwords (even in secure storage) is a security risk.
@freezed
class SavedCredentials with _$SavedCredentials {
  const factory SavedCredentials({
    required String email,
    // SF-007: password field removed - never store passwords locally
  }) = _SavedCredentials;
}
