import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Enum representing network connectivity status
enum ConnectivityStatus {
  /// Device is online (WiFi or Mobile data)
  online,

  /// Device is offline (no connection)
  offline,

  /// Connection status is unknown
  unknown,
}

/// Stream provider for connectivity status changes
@riverpod
Stream<ConnectivityStatus> connectivityStatus(Ref ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map((results) {
    // connectivity_plus 6.x returns List<ConnectivityResult>
    if (results.isEmpty) {
      return ConnectivityStatus.unknown;
    }

    // Check if any result indicates connectivity
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    return hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
  });
}

/// Provider for checking current connectivity status (one-time check)
@riverpod
Future<ConnectivityStatus> currentConnectivityStatus(Ref ref) async {
  final connectivity = Connectivity();

  try {
    final results = await connectivity.checkConnectivity();

    if (results.isEmpty) {
      return ConnectivityStatus.unknown;
    }

    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    return hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
  } catch (e) {
    return ConnectivityStatus.unknown;
  }
}

/// Helper extension for ConnectivityStatus
extension ConnectivityStatusExtension on ConnectivityStatus {
  /// Check if device is online
  bool get isOnline => this == ConnectivityStatus.online;

  /// Check if device is offline
  bool get isOffline => this == ConnectivityStatus.offline;

  /// Get user-friendly message
  String get message {
    switch (this) {
      case ConnectivityStatus.online:
        return 'You are online';
      case ConnectivityStatus.offline:
        return 'No internet connection';
      case ConnectivityStatus.unknown:
        return 'Connection status unknown';
    }
  }
}
