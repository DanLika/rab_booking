import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_credentials.freezed.dart';

/// Saved login credentials (email + password)
/// Used by SecureStorageService to persist "Remember Me" login state
@freezed
class SavedCredentials with _$SavedCredentials {
  const factory SavedCredentials({
    required String email,
    required String password,
  }) = _SavedCredentials;
}
