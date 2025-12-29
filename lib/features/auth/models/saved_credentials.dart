import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_credentials.freezed.dart';

/// Saved login credentials (email only)
/// Used by SecureStorageService to persist "Remember Me" login state
@freezed
class SavedCredentials with _$SavedCredentials {
  const factory SavedCredentials({
    required String email,
  }) = _SavedCredentials;
}
