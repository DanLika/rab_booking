import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_config.dart';
import 'logging_service.dart';

/// Service for checking app version and determining update requirements
class VersionCheckService {
  final FirebaseFirestore _firestore;

  VersionCheckService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if app update is required
  /// Returns UpdateStatus based on current vs remote version
  Future<({UpdateStatus status, AppConfig config})> checkVersion() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "1.0.2"

      // Fetch remote config from Firestore
      final config = await _fetchRemoteConfig();

      // Compare versions
      final status = _determineUpdateStatus(
        currentVersion: currentVersion,
        config: config,
      );

      LoggingService.logInfo(
        'VersionCheck: current=$currentVersion, '
        'min=${config.minRequiredVersion}, '
        'latest=${config.latestVersion}, '
        'status=$status',
      );

      return (status: status, config: config);
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'VersionCheckService: Failed to check version',
        e,
        stackTrace,
      );
      // On error, allow app to continue without update check
      return (status: UpdateStatus.upToDate, config: AppConfig.defaultConfig());
    }
  }

  /// Fetch app config from Firestore
  Future<AppConfig> _fetchRemoteConfig() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('android')
          .get();

      if (!doc.exists || doc.data() == null) {
        LoggingService.logWarning(
          'VersionCheckService: app_config/android document not found, using defaults',
        );
        return AppConfig.defaultConfig();
      }

      return AppConfig.fromJson(doc.data()!);
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'VersionCheckService: Failed to fetch remote config',
        e,
        stackTrace,
      );
      return AppConfig.defaultConfig();
    }
  }

  /// Determine update status by comparing versions
  UpdateStatus _determineUpdateStatus({
    required String currentVersion,
    required AppConfig config,
  }) {
    // Parse versions (e.g., "1.0.2" -> [1, 0, 2])
    final current = _parseVersion(currentVersion);
    final minRequired = _parseVersion(config.minRequiredVersion);
    final latest = _parseVersion(config.latestVersion);

    // Force update if below minimum required version
    if (_isVersionLessThan(current, minRequired) && config.forceUpdateEnabled) {
      return UpdateStatus.forceUpdate;
    }

    // Optional update if below latest version
    if (_isVersionLessThan(current, latest)) {
      return UpdateStatus.optionalUpdate;
    }

    return UpdateStatus.upToDate;
  }

  /// Parse version string to list of integers
  /// e.g., "1.0.2" -> [1, 0, 2]
  List<int> _parseVersion(String version) {
    try {
      return version.split('.').map(int.parse).toList();
    } catch (e) {
      // Invalid version format, return [0, 0, 0]
      return [0, 0, 0];
    }
  }

  /// Compare two version arrays
  /// Returns true if v1 < v2
  bool _isVersionLessThan(List<int> v1, List<int> v2) {
    // Pad shorter version with zeros
    while (v1.length < v2.length) {
      v1.add(0);
    }
    while (v2.length < v1.length) {
      v2.add(0);
    }

    // Compare each segment
    for (int i = 0; i < v1.length; i++) {
      if (v1[i] < v2[i]) return true;
      if (v1[i] > v2[i]) return false;
    }

    return false; // Versions are equal
  }
}
