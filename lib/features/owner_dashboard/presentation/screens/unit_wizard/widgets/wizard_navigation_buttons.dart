import 'package:flutter/material.dart';

import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/design/tokens.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../../../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../../../shared/widgets/redesign.dart';

/// Wizard Navigation Buttons - Back, Skip, Next/Continue
/// Provides consistent navigation controls across all wizard steps.
///
/// Premium pass (Wave 4): raw Material buttons → [BbButton] (handoff wizard.jsx
/// footer — secondary "Natrag", tertiary "Odustani", primary "Dalje" /
/// "Objavi jedinicu"). Logic (callbacks, enabled/loading gating, keys) unchanged.
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
    final screenType = ResponsiveSpacingHelper.getScreenType(context);
    final isVerySmall = ResponsiveSpacingHelper.isVerySmallScreen(context);
    final isLandscape = screenType == ScreenType.landscapeMobile;
    final isMobile = screenType == ScreenType.portraitMobile || isLandscape;

    // Collapse the back button to an icon-only control on the tightest layouts.
    final iconOnlyBack = isVerySmall || isLandscape;
    final buttonSize = isMobile ? BbButtonSize.sm : BbButtonSize.md;

    // Use responsive bottom bar padding.
    final bottomBarPadding = ResponsiveSpacingHelper.getBottomBarPadding(
      context,
    );

    // Publish (final step) gets the rocket affordance; otherwise forward arrow.
    // Shorter primary label on the tightest screens (kept from prior behaviour).
    final isPublish = nextLabel == l10n.unitWizardPublish;
    final nextButtonLabel =
        (isVerySmall && nextLabel == l10n.unitWizardContinueToReview)
        ? l10n.unitWizardProgressReview
        : nextLabel;

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
            BbButton(
              key: const ValueKey('wizard_back'),
              label: iconOnlyBack ? null : l10n.unitWizardBack,
              iconLeft: 'arrow_back',
              variant: BbButtonVariant.secondary,
              size: buttonSize,
              asIcon: iconOnlyBack,
              semanticLabel: l10n.unitWizardBack,
              onPressed: onBack,
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Skip button (only on optional steps)
          if (showSkip) ...[
            BbButton(
              label: l10n.unitWizardSkip,
              variant: BbButtonVariant.tertiary,
              size: buttonSize,
              onPressed: onSkip,
            ),
            SizedBox(width: isVerySmall ? BBSpace.xxs : BBSpace.xs),
          ],

          // Next/Continue/Publish button.
          BbButton(
            key: const ValueKey('wizard_next'),
            label: nextButtonLabel,
            iconLeft: isPublish ? 'rocket_launch' : null,
            iconRight: isPublish ? null : 'arrow_forward',
            // variant defaults to BbButtonVariant.primary (the publish/next CTA)
            size: buttonSize,
            loading: isLoading,
            onPressed: nextEnabled ? onNext : null,
          ),
        ],
      ),
    );
  }
}
