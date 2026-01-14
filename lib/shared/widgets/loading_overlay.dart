import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'bookbed_branded_loader.dart';

/// Loading overlay with BookBed branded loader
///
/// Shows BookBed logo with animated progress bar.
/// Used for route transitions and async operations in owner dashboard.
///
/// Features:
/// - **Glassmorphism:** Uses [BackdropFilter] for blur effect.
/// - **Debounce:** Only shows content if loading takes longer than 300ms to prevent flickering.
class LoadingOverlay extends StatefulWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({super.key, this.message, this.backgroundColor});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  bool _shouldShow = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Debounce: Only show if loading takes > 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _shouldShow = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use user provided color or default to semi-transparent for glassmorphism
    final bgColor =
        widget.backgroundColor ??
        (isDarkMode
            ? Colors.black.withValues(alpha: 0.60)
            : Colors.white.withValues(alpha: 0.60));

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookBedBrandedLoader(isDarkMode: isDarkMode),
              if (widget.message != null) ...[
                const SizedBox(height: 24),
                Text(
                  widget.message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
