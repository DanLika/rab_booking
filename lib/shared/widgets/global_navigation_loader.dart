import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

/// Loading state provider for global navigation overlay
/// Tracks whether a navigation/async operation is in progress
class LoadingStateNotifier extends StateNotifier<bool> {
  LoadingStateNotifier() : super(false);

  Timer? _delayTimer;
  bool _shouldShow = false;

  /// Show loading overlay with 300ms delay (prevents flicker for fast operations)
  void show() {
    _shouldShow = true;
    _delayTimer?.cancel();
    _delayTimer = Timer(const Duration(milliseconds: 300), () {
      if (_shouldShow && mounted) {
        state = true;
      }
    });
  }

  /// Hide loading overlay immediately
  void hide() {
    _shouldShow = false;
    _delayTimer?.cancel();
    if (mounted) {
      state = false;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }
}

/// Global loading state provider
final loadingStateProvider = StateNotifierProvider<LoadingStateNotifier, bool>((
  ref,
) {
  return LoadingStateNotifier();
});

/// Global Navigation Overlay - Minimalist Design (Opcija A)
///
/// Features:
/// - Semi-transparent dark overlay (0.3 opacity)
/// - Circular spinner (40px) - centered
/// - Purple color (AppColors.primary)
/// - No text
/// - 300ms delay before showing (prevents flicker)
///
/// Usage:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return GlobalNavigationOverlay(child: child!);
///   },
/// )
/// ```
class GlobalNavigationOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalNavigationOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingStateProvider);

    return Stack(
      children: [
        // Main app content
        child,

        // Loading overlay (shown only when isLoading = true)
        if (isLoading) Positioned.fill(child: _LoadingOverlay()),
      ],
    );
  }
}

/// Internal loading overlay widget
class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3), // Semi-transparent dark overlay
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary, // Purple spinner
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper extension for easy access to loading state
extension LoadingStateExtension on WidgetRef {
  /// Show global loading overlay
  void showLoading() {
    read(loadingStateProvider.notifier).show();
  }

  /// Hide global loading overlay
  void hideLoading() {
    read(loadingStateProvider.notifier).hide();
  }
}
