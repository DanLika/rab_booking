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

  /// Upload profile image for a user
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final String path = 'users/$userId/profile/$fileName';
      final ref = _storage.ref().child(path);

      final metadata = SettableMetadata(
        // Allow Firebase to auto-detect content type from file extension
        contentType: null,
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(imageBytes, metadata);

      // Listen for state changes and report progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((taskSnapshot) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();

    } catch (e) {
      // Improved error handling
      throw StorageException.uploadFailed(
        'profile image',
        e,
        // Add more context if helpful, e.g., fileName
      );
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
