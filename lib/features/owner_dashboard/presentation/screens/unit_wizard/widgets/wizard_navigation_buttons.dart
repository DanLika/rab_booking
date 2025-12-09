import 'package:flutter/material.dart';

import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../../../../../../core/utils/responsive_spacing_helper.dart';

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenType = ResponsiveSpacingHelper.getScreenType(context);
    final isVerySmall = ResponsiveSpacingHelper.isVerySmallScreen(context);
    final isLandscape = screenType == ScreenType.landscapeMobile;
    final isMobile = screenType == ScreenType.portraitMobile || isLandscape;

    // Use responsive bottom bar padding
    final bottomBarPadding = ResponsiveSpacingHelper.getBottomBarPadding(context);

    return Container(
      padding: bottomBarPadding,
      decoration: BoxDecoration(
        gradient: context.gradients.pageBackground,
        // Border removed for seamless gradient flow with content above
      ),
      child: Row(
        children: [
          // Back button - icon only on very small screens or landscape
          if (showBack)
            isVerySmall || isLandscape
                ? IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    style: IconButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    tooltip: l10n.unitWizardBack,
                  )
                : OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(l10n.unitWizardBack),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 14),
                      side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
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
                padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : (isMobile ? 12 : 16)),
              ),
              child: Text(l10n.unitWizardSkip, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            SizedBox(width: isVerySmall ? 4 : (isMobile ? 8 : 12)),
          ],

          // Next/Continue button - shorter label on very small screens or landscape
          isVerySmall && nextLabel == l10n.unitWizardContinueToReview
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
                  label: Text(l10n.unitWizardProgressReview),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 8 : 12),
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
                      : Icon(nextLabel == l10n.unitWizardPublish ? Icons.publish : Icons.arrow_forward, size: 18),
                  label: Text(nextLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmall ? 16 : (isMobile ? 20 : 32),
                      vertical: isLandscape ? 8 : (isMobile ? 12 : 14),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
