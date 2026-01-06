import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';
import '../../theme/minimalist_colors.dart';
import 'booking_step_indicator.dart';
import 'compact_pill_summary.dart';

/// Content widget for the booking pill bar.
///
/// Handles layout switching between compact (mobile) and wide-screen (desktop) layouts.
class PillBarContent extends StatelessWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final String formattedRoomPrice;
  final double additionalServicesTotal;
  final String formattedAdditionalServices;
  final String formattedTotal;
  final String formattedDeposit;
  final int depositPercentage;
  final bool isDarkMode;
  final bool showGuestForm;
  final bool isWideScreen;
  final VoidCallback onClose;
  final VoidCallback onReserve;
  final Widget Function() guestFormBuilder;
  final Widget Function() paymentSectionBuilder;
  final Widget Function() additionalServicesBuilder;
  final Widget Function() taxLegalBuilder;
  final WidgetTranslations translations;

  const PillBarContent({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.formattedRoomPrice,
    required this.additionalServicesTotal,
    required this.formattedAdditionalServices,
    required this.formattedTotal,
    required this.formattedDeposit,
    required this.depositPercentage,
    required this.isDarkMode,
    required this.showGuestForm,
    required this.isWideScreen,
    required this.onClose,
    required this.onReserve,
    required this.guestFormBuilder,
    required this.paymentSectionBuilder,
    required this.additionalServicesBuilder,
    required this.taxLegalBuilder,
    required this.translations,
  });

  // Layout constants
  static const _dragHandleWidth = 40.0;
  static const _dragHandleHeight = 4.0;
  static const _closeButtonPadding = 5.0;
  static const _closeButtonRadius = 16.0;
  static const _closeIconSize = 16.0;
  static const _maxHeightFactor = 0.6;
  static const _leftColumnFlex = 55;
  static const _rightColumnFlex = 45;

  @override
  Widget build(BuildContext context) {
    if (showGuestForm && isWideScreen) {
      return _buildWideScreenLayout(context);
    }
    return _buildCompactLayout(context);
  }

  Widget _buildWideScreenLayout(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    // Defensive null check: MediaQuery might not be available during initial layout
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      // Fallback to compact layout if MediaQuery not available
      return _buildCompactLayout(context);
    }

    // Defensive check: ensure size values are valid and finite
    final size = mediaQuery.size;
    if (!size.height.isFinite || size.height <= 0) {
      return _buildCompactLayout(context);
    }

    final viewInsets = mediaQuery.viewInsets.bottom;
    final screenHeight = size.height;
    final calculatedHeight = (screenHeight - viewInsets) * _maxHeightFactor;

    // Ensure calculated height is valid
    final maxHeight = calculatedHeight.isFinite && calculatedHeight > 0
        ? calculatedHeight
        : 600.0; // Fallback to reasonable default

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WideScreenHeader(onClose: onClose, colors: colors),
        const SizedBox(height: SpacingTokens.m),
        _buildStepIndicator(context),
        const SizedBox(height: SpacingTokens.m),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: _leftColumnFlex,
                  child: Column(
                    children: [
                      guestFormBuilder(),
                      additionalServicesBuilder(),
                      taxLegalBuilder(),
                    ],
                  ),
                ),
                const SizedBox(width: SpacingTokens.m),
                Expanded(
                  flex: _rightColumnFlex,
                  child: paymentSectionBuilder(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompactPillSummary(
          checkIn: checkIn,
          checkOut: checkOut,
          nights: nights,
          formattedRoomPrice: formattedRoomPrice,
          additionalServicesTotal: additionalServicesTotal,
          formattedAdditionalServices: formattedAdditionalServices,
          formattedTotal: formattedTotal,
          formattedDeposit: formattedDeposit,
          depositPercentage: depositPercentage,
          isDarkMode: isDarkMode,
          showReserveButton: !showGuestForm,
          onClose: onClose,
          onReserve: onReserve,
          translations: translations,
        ),
        if (showGuestForm && !isWideScreen) ...[
          const SizedBox(height: SpacingTokens.m),
          _buildStepIndicator(context),
          const SizedBox(height: SpacingTokens.m),
          guestFormBuilder(),
          additionalServicesBuilder(),
          taxLegalBuilder(),
          const SizedBox(height: SpacingTokens.m),
          paymentSectionBuilder(),
        ],
      ],
    );
  }

  // Helper method to build the step indicator
  Widget _buildStepIndicator(BuildContext context) {
    // Define the steps of the booking process
    final steps = [
      'Select Dates',
      'Guest Information',
      'Payment',
    ];

    // Determine the current step
    int currentStep = 0;
    if (showGuestForm) {
      currentStep = 1;
    }

    return BookingStepIndicator(
      currentStep: currentStep,
      steps: steps,
    );
  }
}

class _WideScreenHeader extends StatelessWidget {
  final VoidCallback onClose;
  final MinimalistColorSchemeAdapter colors;

  const _WideScreenHeader({required this.onClose, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Spacer(),
        Container(
          width: PillBarContent._dragHandleWidth,
          height: PillBarContent._dragHandleHeight,
          decoration: BoxDecoration(
            color: colors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(
            PillBarContent._closeButtonRadius,
          ),
          child: Container(
            padding: const EdgeInsets.all(PillBarContent._closeButtonPadding),
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              borderRadius: BorderRadius.circular(
                PillBarContent._closeButtonRadius,
              ),
              border: Border.all(color: colors.borderLight),
            ),
            child: Icon(
              Icons.close,
              size: PillBarContent._closeIconSize,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
