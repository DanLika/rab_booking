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
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (showBack)
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(isMobile ? 'Back' : 'Back'),
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
              child: Text(
                isMobile ? 'Skip' : 'Skip for Now',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
          ],

          // Next/Continue button
          FilledButton.icon(
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
                horizontal: isMobile ? 20 : 32,
                vertical: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
