import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// App configuration fetched from Firestore
/// Used for version control and force updates
@freezed
class AppConfig with _$AppConfig {
  const factory AppConfig({
    /// Minimum required app version (force update if below this)
    required String minRequiredVersion,

    /// Latest available app version (optional update if below this)
    required String latestVersion,

    /// Whether force update is enabled globally
    @Default(true) bool forceUpdateEnabled,

    /// Custom message to display in update dialog (optional)
    String? updateMessage,

    /// URL to redirect users (defaults to Play Store)
    String? storeUrl,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// Default config when Firestore fetch fails
  factory AppConfig.defaultConfig() => const AppConfig(
    minRequiredVersion: '1.0.0',
    latestVersion: '1.0.0',
    forceUpdateEnabled: false,
  );
}

/// Update status after version check
enum UpdateStatus {
  /// App is up to date
  upToDate,

  /// Optional update available
  optionalUpdate,

  /// Force update required
  forceUpdate,
}
