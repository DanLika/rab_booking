import 'dart:ui';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/widgets/auth_logo_icon.dart';

/// A premium, splash-like loading overlay for authentication processes.
///
/// Provides a blurred background (Glassmorphism), centered logo,
/// and a circular progress indicator as requested by the user.
class LoginLoadingOverlay extends StatelessWidget {
  final String? message;

  const LoginLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: (isDarkMode ? Colors.black : Colors.white).withAlpha(200), // Increased opacity for better splash feel
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with a subtle hero-like presence
              AuthLogoIcon(size: 100, isWhite: isDarkMode),
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

              if (message != null) ...[
                const SizedBox(height: 32),
                Text(
                  message!,
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
