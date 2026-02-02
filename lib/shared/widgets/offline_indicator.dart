import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/connectivity_provider.dart';

/// Offline Indicator Widget
///
/// Displays a non-intrusive banner when the device is offline.
/// When connectivity returns, briefly shows "Back online" in green
/// before sliding out.
class OfflineIndicator extends ConsumerStatefulWidget {
  const OfflineIndicator({super.key});

  @override
  ConsumerState<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends ConsumerState<OfflineIndicator> {
  bool _wasOffline = false;
  bool _showReconnected = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    // Default to true (online) if loading or error to avoid flashing
    final isOnline = isOnlineAsync.value ?? true;

    if (!isOnline) {
      // Device is offline — show red banner
      _wasOffline = true;
      _showReconnected = false;
      _hideTimer?.cancel();
      return _buildBanner(
        color: const Color(0xFF333333),
        icon: Icons.wifi_off,
        text: 'Nema interneta',
      );
    }

    if (_wasOffline && !_showReconnected) {
      // Just came back online — show green "reconnected" briefly
      _wasOffline = false;
      _showReconnected = true;
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showReconnected = false);
      });
    }

    if (_showReconnected) {
      return _buildBanner(
        color: const Color(0xFF2E7D32),
        icon: Icons.wifi,
        text: 'Ponovo povezano',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBanner({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: color,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child:
                Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      color: color,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .slideY(
                      begin: 1.0,
                      end: 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    )
                    .fadeIn(),
          ),
        ),
      ),
    );
  }
}
