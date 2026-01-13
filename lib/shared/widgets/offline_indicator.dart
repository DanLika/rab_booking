import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/connectivity_provider.dart';

/// Offline Indicator Widget
///
/// Displays a non-intrusive banner when the device is offline.
/// - Appears at the bottom of the screen
/// - Animated slide-in/out
/// - Uses AppColors.warning or dark background
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connectivity status
    final isOnlineAsync = ref.watch(isOnlineProvider);

    // Default to true (online) if loading or error to avoid flashing
    final isOnline = isOnlineAsync.value ?? true;

    // Only show if offline
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.red.shade700,
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
                      color: const Color(0xFF333333), // Dark grey
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nema interneta - Prikazujem spremljene podatke',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
