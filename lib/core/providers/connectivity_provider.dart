import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    // Initial check
    _checkConnectivity();

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      // If check fails, assume offline or wait for stream
      _controller.add(false);
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If any interface has connection (mobile, wifi, ethernet, vpn), we are online
    final isOnline = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
    _controller.add(isOnline);
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Stream provider for online status
/// Returns true if online, false if offline
/// Defaults to true to avoid showing "No Internet" on startup before check completes
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
