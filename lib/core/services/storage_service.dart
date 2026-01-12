import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/app_exceptions.dart';

/// Service for handling Firebase Storage operations.
///
/// Provides upload and delete operations for user content:
/// - Profile images
/// - Property images
/// - Unit images
///
/// Usage:
/// ```dart
/// final service = StorageService();
///
/// // Upload profile image
/// final url = await service.uploadProfileImage(
///   userId: userId,
///   imageBytes: bytes,
///   fileName: 'profile.jpg',
/// );
///
/// // Upload unit image
/// final unitUrl = await service.uploadUnitImage(
///   userId: userId,
///   propertyId: propertyId,
///   unitId: unitId,
///   imageBytes: bytes,
///   fileName: 'room.jpg',
/// );
/// ```
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Maximum file size: 10MB (matches storage.rules SEC-002)
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image extensions
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
  ];

  /// Validate file before upload (client-side check for better UX)
  /// Throws StorageException if validation fails
  void _validateImageFile(Uint8List bytes, String fileName) {
    // Check file size
    if (bytes.length > _maxFileSizeBytes) {
      throw StorageException.uploadFailed(
        'image',
        Exception('File too large. Maximum size is 10MB.'),
      );
    }

    // Check file extension
    final ext = fileName.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw StorageException.uploadFailed(
        'image',
        Exception('Invalid file type. Allowed: JPG, PNG, WebP, GIF.'),
      );
    }
  }

  /// Upload profile image for a user
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // SEC-002: Validate file before upload
      _validateImageFile(imageBytes, fileName);
      // Create a reference to the file location
      final String path = 'users/$userId/profile/$fileName';
      final Reference ref = _storage.ref().child(path);

      // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw StorageException.uploadFailed('profile image', e);
    }
  }

  /// Delete profile image for a user
  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    try {
      // Extract path from URL if needed
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // If delete fails, it's not critical - log and continue
    }
  }

  /// Upload property image
  Future<String> uploadPropertyImage({
    required String userId,
    required String propertyId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // SEC-002: Validate file before upload
      _validateImageFile(imageBytes, fileName);

      final String path = 'users/$userId/properties/$propertyId/$fileName';
      final Reference ref = _storage.ref().child(path);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'propertyId': propertyId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw StorageException.uploadFailed('property image', e);
    }
  }

  /// Upload unit image
  Future<String> uploadUnitImage({
    required String userId,
    required String propertyId,
    required String unitId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // SEC-002: Validate file before upload
      _validateImageFile(imageBytes, fileName);

      final String path =
          'users/$userId/properties/$propertyId/units/$unitId/$fileName';
      final Reference ref = _storage.ref().child(path);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'propertyId': propertyId,
          'unitId': unitId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw StorageException.uploadFailed('unit image', e);
    }
  }
}
