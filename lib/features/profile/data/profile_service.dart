import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/user_preferences.dart';
import '../../../shared/models/user_model.dart';

part 'profile_service.g.dart';

/// Profile service for managing user preferences and avatar
class ProfileService {
  final SupabaseClient _supabase;
  final ImagePicker _imagePicker;

  ProfileService(this._supabase, this._imagePicker);

  /// Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Load user preferences from database
  Future<UserPreferences> loadPreferences() async {
    if (_userId == null) {
      return const UserPreferences();
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('preferences')
          .eq('id', _userId!)
          .single();

      if (response['preferences'] != null) {
        return UserPreferences.fromJson(
          response['preferences'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      // Return default preferences if not found
      return const UserPreferences();
    }

    return const UserPreferences();
  }

  /// Save user preferences to database
  Future<void> savePreferences(UserPreferences preferences) async {
    if (_userId == null) return;

    await _supabase.from('profiles').update({
      'preferences': preferences.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId!);
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(bool enabled) async {
    final current = await loadPreferences();
    await savePreferences(current.copyWith(notificationsEnabled: enabled));
  }

  /// Update language preference
  Future<void> updateLanguage(String languageCode) async {
    final current = await loadPreferences();
    await savePreferences(current.copyWith(language: languageCode));
  }

  /// Update theme preference
  Future<void> updateTheme(String themeCode) async {
    final current = await loadPreferences();
    await savePreferences(current.copyWith(theme: themeCode));
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    return await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    return await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  }

  /// Upload avatar to Supabase Storage
  Future<String> uploadAvatar(XFile imageFile) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Delete old avatar if exists
    await _deleteOldAvatar();

    // Generate unique filename
    final fileExt = imageFile.path.split('.').last;
    final fileName = '$_userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'avatars/$fileName';

    // Upload to Supabase Storage
    final bytes = await imageFile.readAsBytes();
    await _supabase.storage.from('user-uploads').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    // Get public URL
    final publicUrl = _supabase.storage.from('user-uploads').getPublicUrl(filePath);

    // Update profile with new avatar URL
    await _supabase.from('profiles').update({
      'avatar_url': publicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId!);

    // Update preferences with avatar URL
    final current = await loadPreferences();
    await savePreferences(current.copyWith(avatarUrl: publicUrl));

    return publicUrl;
  }

  /// Delete old avatar from storage
  Future<void> _deleteOldAvatar() async {
    if (_userId == null) return;

    try {
      // Get current avatar URL
      final response = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', _userId!)
          .single();

      final oldAvatarUrl = response['avatar_url'] as String?;
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        // Extract file path from URL
        final uri = Uri.parse(oldAvatarUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3) {
          // Path format: /storage/v1/object/public/user-uploads/avatars/filename
          final filePath = pathSegments.sublist(pathSegments.indexOf('avatars')).join('/');
          await _supabase.storage.from('user-uploads').remove([filePath]);
        }
      }
    } catch (e) {
      // Ignore errors when deleting old avatar
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUser() async {
    if (_userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', _userId!)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;

    await _supabase.from('profiles').update(updates).eq('id', _userId!);
  }
}

/// Provider for ProfileService
@riverpod
ProfileService profileService(Ref ref) {
  return ProfileService(
    Supabase.instance.client,
    ImagePicker(),
  );
}

/// Provider for user preferences
@riverpod
class UserPreferencesNotifier extends _$UserPreferencesNotifier {
  @override
  Future<UserPreferences> build() async {
    final service = ref.watch(profileServiceProvider);
    return await service.loadPreferences();
  }

  /// Update notification settings
  Future<void> updateNotifications(bool enabled) async {
    final service = ref.read(profileServiceProvider);
    await service.updateNotificationSettings(enabled);
    ref.invalidateSelf();
  }

  /// Update language
  Future<void> updateLanguage(String languageCode) async {
    final service = ref.read(profileServiceProvider);
    await service.updateLanguage(languageCode);
    ref.invalidateSelf();
  }

  /// Update theme
  Future<void> updateTheme(String themeCode) async {
    final service = ref.read(profileServiceProvider);
    await service.updateTheme(themeCode);
    ref.invalidateSelf();
  }

  /// Upload avatar
  Future<String> uploadAvatar(XFile imageFile) async {
    final service = ref.read(profileServiceProvider);
    final avatarUrl = await service.uploadAvatar(imageFile);
    ref.invalidateSelf();
    return avatarUrl;
  }
}
