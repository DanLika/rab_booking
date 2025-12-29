import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/models/saved_credentials.dart';

/// Secure storage service for sensitive data (credentials, tokens)
/// Uses platform-specific secure storage:
/// - Android: EncryptedSharedPreferences (AES encryption)
/// - iOS: Keychain
/// - Web: Not recommended for production (uses localStorage - not encrypted)
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyEmail = 'saved_email';
  static const _keyRememberMe = 'remember_me';

  /// Save user's email securely if "Remember Me" is enabled.
  /// Does NOT save the password.
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyRememberMe, value: 'true');
  }

  /// Get saved email if "Remember Me" was enabled.
  /// Returns null if no email is saved or "Remember Me" was not checked.
  Future<String?> getEmail() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    if (rememberMe != 'true') return null;

    return await _storage.read(key: _keyEmail);
  }

  /// Clear all saved data (email and remember me flag).
  /// Call this on logout or when user unchecks "Remember Me".
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyRememberMe);
  }

  /// Check if credentials are currently saved
  Future<bool> hasCredentials() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    return rememberMe == 'true';
  }
}
