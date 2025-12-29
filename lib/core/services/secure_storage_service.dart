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
  static const _keyPassword = 'saved_password';
  static const _keyRememberMe = 'remember_me';

  /// Save user credentials securely
  /// Only call this if user explicitly checks "Remember Me"
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyRememberMe, value: 'true');
  }

  /// Get saved credentials if "Remember Me" was enabled
  /// Returns null if no credentials saved or "Remember Me" was not checked
  Future<SavedCredentials?> getCredentials() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    if (rememberMe != 'true') return null;

    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);

    if (email == null || password == null) return null;

    return SavedCredentials(email: email, password: password);
  }

  /// Clear all saved credentials
  /// Call this on logout or when user unchecks "Remember Me"
  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyRememberMe);
  }

  /// Check if credentials are currently saved
  Future<bool> hasCredentials() async {
    final rememberMe = await _storage.read(key: _keyRememberMe);
    return rememberMe == 'true';
  }
}
