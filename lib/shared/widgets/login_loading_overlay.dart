import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/widgets/auth_logo_icon.dart';

/// A premium, splash-like loading overlay for authentication processes.
///
/// Provides a blurred background (Glassmorphism), centered logo,
/// and a circular progress indicator.
///
/// Features:
/// - **Glassmorphism:** Uses [BackdropFilter] for blur effect.
/// - **Debounce:** Only shows content if loading takes longer than 300ms to prevent flickering.
class LoginLoadingOverlay extends StatefulWidget {
  final String? message;

  const LoginLoadingOverlay({super.key, this.message});

  @override
  State<LoginLoadingOverlay> createState() => _LoginLoadingOverlayState();
}

class _LoginLoadingOverlayState extends State<LoginLoadingOverlay> {
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: (isDarkMode ? Colors.black : Colors.white).withAlpha(200),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with a subtle hero-like presence
              AuthLogoIcon(isWhite: isDarkMode),
              const SizedBox(height: 48),

              // Custom Circular Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      backgroundColor: theme.colorScheme.primary.withAlpha(40),
                    ),
                  ),
                  // Inner decorative pulse could go here if needed
                ],
              ),

              if (widget.message != null) ...[
                const SizedBox(height: 32),
                Text(
                  widget.message!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
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
