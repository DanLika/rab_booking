import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Receipt Storage Service
///
/// Manages PDF receipts in Supabase Storage.
/// Handles:
/// - Uploading receipts to storage bucket
/// - Generating public URLs for download
/// - Deleting old/cancelled bookings receipts
/// - Storage path management
class ReceiptStorageService {
  final SupabaseClient _supabase;

  /// Storage bucket name for receipts
  static const String bucketName = 'receipts';

  /// Constructor
  ReceiptStorageService({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  /// Upload receipt PDF to Supabase Storage
  ///
  /// Returns the public URL to the uploaded receipt.
  ///
  /// Storage path structure:
  /// `receipts/{userId}/{bookingId}/receipt.pdf`
  ///
  /// Example:
  /// ```dart
  /// final pdfBytes = await receiptGenerator.generateReceipt(...);
  /// final url = await storageService.uploadReceipt(
  ///   userId: currentUserId,
  ///   bookingId: booking.id,
  ///   pdfBytes: pdfBytes,
  /// );
  /// ```
  Future<String> uploadReceipt({
    required String userId,
    required String bookingId,
    required Uint8List pdfBytes,
  }) async {
    try {
      // Generate storage path
      final path = _getReceiptPath(userId, bookingId);

      // Upload to Supabase Storage
      // upsert: true allows overwriting if receipt already exists
      await _supabase.storage.from(bucketName).uploadBinary(
            path,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true, // Overwrite if exists
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw ReceiptStorageException(
        'Failed to upload receipt: ${e.toString()}',
      );
    }
  }

  /// Download receipt PDF from Supabase Storage
  ///
  /// Returns the PDF bytes for local download or display.
  ///
  /// Example:
  /// ```dart
  /// final pdfBytes = await storageService.downloadReceipt(
  ///   userId: currentUserId,
  ///   bookingId: booking.id,
  /// );
  /// await saveToDevice(pdfBytes);
  /// ```
  Future<Uint8List> downloadReceipt({
    required String userId,
    required String bookingId,
  }) async {
    try {
      final path = _getReceiptPath(userId, bookingId);

      final bytes = await _supabase.storage.from(bucketName).download(path);

      return bytes;
    } catch (e) {
      throw ReceiptStorageException(
        'Failed to download receipt: ${e.toString()}',
      );
    }
  }

  /// Get public URL for a receipt
  ///
  /// Returns the direct public URL without downloading.
  ///
  /// Example:
  /// ```dart
  /// final url = storageService.getReceiptUrl(
  ///   userId: currentUserId,
  ///   bookingId: booking.id,
  /// );
  /// // Share URL or open in browser
  /// ```
  String getReceiptUrl({
    required String userId,
    required String bookingId,
  }) {
    final path = _getReceiptPath(userId, bookingId);
    return _supabase.storage.from(bucketName).getPublicUrl(path);
  }

  /// Delete receipt from storage
  ///
  /// Used when:
  /// - Booking is cancelled
  /// - User requests data deletion
  /// - Receipt regeneration (old receipt is deleted first)
  ///
  /// Example:
  /// ```dart
  /// await storageService.deleteReceipt(
  ///   userId: currentUserId,
  ///   bookingId: cancelledBooking.id,
  /// );
  /// ```
  Future<void> deleteReceipt({
    required String userId,
    required String bookingId,
  }) async {
    try {
      final path = _getReceiptPath(userId, bookingId);

      await _supabase.storage.from(bucketName).remove([path]);
    } catch (e) {
      throw ReceiptStorageException(
        'Failed to delete receipt: ${e.toString()}',
      );
    }
  }

  /// Check if receipt exists in storage
  ///
  /// Returns true if receipt file exists, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await storageService.receiptExists(...)) {
  ///   // Receipt already generated
  /// } else {
  ///   // Generate new receipt
  /// }
  /// ```
  Future<bool> receiptExists({
    required String userId,
    required String bookingId,
  }) async {
    try {
      final path = _getReceiptPath(userId, bookingId);

      // List files in the directory
      final files = await _supabase.storage.from(bucketName).list(
            path: _getUserReceiptFolder(userId, bookingId),
          );

      // Check if receipt.pdf exists
      return files.any((file) => file.name == 'receipt.pdf');
    } catch (e) {
      // If folder doesn't exist, file doesn't exist
      return false;
    }
  }

  /// Delete all receipts for a user
  ///
  /// Used for GDPR compliance / account deletion.
  ///
  /// Example:
  /// ```dart
  /// await storageService.deleteAllUserReceipts(userId: currentUserId);
  /// ```
  Future<void> deleteAllUserReceipts({required String userId}) async {
    try {
      // List all files in user's folder
      final files = await _supabase.storage.from(bucketName).list(
            path: userId,
          );

      if (files.isEmpty) return;

      // Get all file paths
      final filePaths = files.map((file) => '$userId/${file.name}').toList();

      // Delete all files
      await _supabase.storage.from(bucketName).remove(filePaths);
    } catch (e) {
      throw ReceiptStorageException(
        'Failed to delete user receipts: ${e.toString()}',
      );
    }
  }

  /// Get receipt metadata (size, created date, etc.)
  ///
  /// Example:
  /// ```dart
  /// final metadata = await storageService.getReceiptMetadata(...);
  /// print('Receipt size: ${metadata['size']} bytes');
  /// ```
  Future<Map<String, dynamic>> getReceiptMetadata({
    required String userId,
    required String bookingId,
  }) async {
    try {
      final path = _getReceiptPath(userId, bookingId);

      // List files to get metadata
      final files = await _supabase.storage.from(bucketName).list(
            path: _getUserReceiptFolder(userId, bookingId),
          );

      final receiptFile = files.firstWhere(
        (file) => file.name == 'receipt.pdf',
        orElse: () => throw ReceiptStorageException('Receipt not found'),
      );

      return {
        'name': receiptFile.name,
        'size': receiptFile.metadata?['size'],
        'created_at': receiptFile.createdAt,
        'updated_at': receiptFile.updatedAt,
        'last_accessed_at': receiptFile.lastAccessedAt,
      };
    } catch (e) {
      throw ReceiptStorageException(
        'Failed to get receipt metadata: ${e.toString()}',
      );
    }
  }

  /// Initialize storage bucket
  ///
  /// Creates the receipts bucket if it doesn't exist.
  /// Should be called once during app initialization or setup.
  ///
  /// Bucket configuration:
  /// - Public: true (receipts are publicly accessible via URL)
  /// - File size limit: 5MB (receipts are typically < 500KB)
  ///
  /// Note: This requires admin/service role permissions.
  /// Run manually in Supabase Dashboard or via migration.
  ///
  /// Example SQL migration:
  /// ```sql
  /// -- Create receipts bucket
  /// INSERT INTO storage.buckets (id, name, public)
  /// VALUES ('receipts', 'receipts', true)
  /// ON CONFLICT (id) DO NOTHING;
  ///
  /// -- Allow authenticated users to upload their own receipts
  /// CREATE POLICY "Users can upload their own receipts"
  /// ON storage.objects FOR INSERT
  /// TO authenticated
  /// WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);
  ///
  /// -- Allow users to read their own receipts
  /// CREATE POLICY "Users can read their own receipts"
  /// ON storage.objects FOR SELECT
  /// TO authenticated
  /// USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);
  ///
  /// -- Allow users to delete their own receipts
  /// CREATE POLICY "Users can delete their own receipts"
  /// ON storage.objects FOR DELETE
  /// TO authenticated
  /// USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);
  ///
  /// -- Allow public access to receipts (for sharing links)
  /// CREATE POLICY "Public can read receipts"
  /// ON storage.objects FOR SELECT
  /// TO public
  /// USING (bucket_id = 'receipts');
  /// ```
  static String get bucketSetupSQL => '''
-- Create receipts storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload their own receipts
CREATE POLICY "Users can upload their own receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow users to read their own receipts
CREATE POLICY "Users can read their own receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow users to update their own receipts
CREATE POLICY "Users can update their own receipts"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow users to delete their own receipts
CREATE POLICY "Users can delete their own receipts"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow public access to receipts (for sharing links)
CREATE POLICY "Public can read receipts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'receipts');
''';

  /// Generate storage path for a receipt
  ///
  /// Path structure: `{userId}/{bookingId}/receipt.pdf`
  String _getReceiptPath(String userId, String bookingId) {
    return '$userId/$bookingId/receipt.pdf';
  }

  /// Get user receipt folder path
  ///
  /// Path structure: `{userId}/{bookingId}`
  String _getUserReceiptFolder(String userId, String bookingId) {
    return '$userId/$bookingId';
  }
}

/// Receipt Storage Exception
///
/// Thrown when storage operations fail.
class ReceiptStorageException implements Exception {
  final String message;

  ReceiptStorageException(this.message);

  @override
  String toString() => 'ReceiptStorageException: $message';
}
