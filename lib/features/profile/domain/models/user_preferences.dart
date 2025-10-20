import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// User preferences model for app settings
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(true) bool notificationsEnabled,
    @Default('hr') String language, // 'hr' or 'en'
    @Default('system') String theme, // 'light', 'dark', or 'system'
    String? avatarUrl,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}

/// Language enum
enum AppLanguage {
  croatian('hr', 'Hrvatski'),
  english('en', 'English');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.croatian,
    );
  }
}

/// Theme mode enum
enum AppThemeMode {
  light('light', 'Svijetla'),
  dark('dark', 'Tamna'),
  system('system', 'Automatski po sistemu');

  const AppThemeMode(this.code, this.displayName);
  final String code;
  final String displayName;

  static AppThemeMode fromCode(String code) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.code == code,
      orElse: () => AppThemeMode.system,
    );
  }
}
