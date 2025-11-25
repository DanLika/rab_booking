import 'package:flutter/material.dart';

/// Wizard Navigation Buttons - Back, Skip, Next/Continue
/// Provides consistent navigation controls across all wizard steps
class WizardNavigationButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final String nextLabel; // "Next", "Continue", "Finish", "Publish"
  final bool showBack; // Hide on first step
  final bool showSkip; // Show only on optional steps
  final bool nextEnabled; // Enable/disable Next button
  final bool isLoading; // Show loading indicator on Next

  const WizardNavigationButtons({
    super.key,
    this.onBack,
    this.onNext,
    this.onSkip,
    this.nextLabel = 'Next',
    this.showBack = true,
    this.showSkip = false,
    this.nextEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 400; // Extra small screens (360px etc.)

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
        // Horizontal: left → right za bottom navigation (default direction)
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1A1A1A), // veryDarkGray
                  Color(0xFF2D2D2D), // mediumDarkGray
                ]
              : const [
                  Color(0xFFF5F5F5), // Light grey
                  Colors.white,      // white
                ],
          stops: const [0.0, 0.3],
        ),
        // Border removed for seamless gradient flow with content above
      ),
      child: Row(
        children: [
          // Back button - icon only on very small screens
          if (showBack)
            isVerySmall
                ? IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    tooltip: 'Back',
                  )
                : OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 12 : 14,
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Skip button (only on optional steps)
          if (showSkip) ...[
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmall ? 8 : (isMobile ? 12 : 16),
                ),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: isVerySmall ? 4 : (isMobile ? 8 : 12)),
          ],

          // Next/Continue button - shorter label on very small screens
          isVerySmall && nextLabel == 'Continue to Review'
              ? FilledButton.icon(
                  onPressed: nextEnabled && !isLoading ? onNext : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Review'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: nextEnabled && !isLoading ? onNext : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(
                          nextLabel == 'Publish'
                              ? Icons.publish
                              : Icons.arrow_forward,
                          size: 18,
                        ),
                  label: Text(nextLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmall ? 16 : (isMobile ? 20 : 32),
                      vertical: isMobile ? 12 : 14,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
