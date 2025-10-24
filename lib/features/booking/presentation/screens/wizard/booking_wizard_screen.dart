import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../providers/booking_flow_notifier.dart';
import '../../widgets/booking_flow_progress.dart';
import 'steps/guest_details_step.dart';
import 'steps/date_selection_step.dart';
import 'steps/review_summary_step.dart';
import 'steps/payment_method_step.dart';
import 'steps/payment_processing_step.dart';
import 'steps/success_step.dart';

/// 6-Step Booking Wizard Coordinator Screen
///
/// Manages the entire booking flow from guest details to success.
/// Steps: Guest Details → Date Selection → Review → Payment Method → Processing → Success
class BookingWizardScreen extends ConsumerStatefulWidget {
  const BookingWizardScreen({
    required this.unitId,
    super.key,
  });

  final String unitId;

  @override
  ConsumerState<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize booking flow with unit on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        ref.read(bookingFlowNotifierProvider.notifier).initializeWithUnit(widget.unitId);
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);
    final bookingNotifier = ref.read(bookingFlowNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, bookingState, bookingNotifier),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            BookingFlowProgress(
              currentStep: bookingState.currentStep,
              showLabels: !context.isMobile,
              compact: context.isMobile,
              showIcons: true,
            ),

            // Divider
            const Divider(height: 1, color: AppColors.borderLight),

            // Step Content (scrollable)
            Expanded(
              child: _buildStepContent(context, bookingState, bookingNotifier),
            ),

            // Navigation Buttons
            if (bookingState.currentStep != BookingStep.success)
              _buildNavigationButtons(context, bookingState, bookingNotifier),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    BookingFlowState state,
    BookingFlowNotifier notifier,
  ) {
    final canGoBack = state.currentStep != BookingStep.guestDetails;

    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => notifier.previousStep(),
            )
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
      title: Text(
        'Rezervacija',
        style: AppTypography.h3.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    BookingFlowState state,
    BookingFlowNotifier notifier,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _getStepWidget(state.currentStep, state),
    );
  }

  Widget _getStepWidget(BookingStep step, BookingFlowState state) {
    switch (step) {
      case BookingStep.guestDetails:
        return const GuestDetailsStep(key: ValueKey('guest-details'));

      case BookingStep.dateSelection:
        return const DateSelectionStep(key: ValueKey('date-selection'));

      case BookingStep.reviewSummary:
        return const ReviewSummaryStep(key: ValueKey('review-summary'));

      case BookingStep.paymentMethod:
        return const PaymentMethodStep(key: ValueKey('payment-method'));

      case BookingStep.paymentProcessing:
        return const PaymentProcessingStep(key: ValueKey('payment-processing'));

      case BookingStep.success:
        return const SuccessStep(key: ValueKey('success'));
    }
  }

  Widget _buildPlaceholder({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              title,
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              subtitle,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              'Screen implementation coming soon...',
              style: AppTypography.small.copyWith(
                color: AppColors.textTertiaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    BookingFlowState state,
    BookingFlowNotifier notifier,
  ) {
    final canGoBack = state.currentStep != BookingStep.guestDetails;
    final isLastStep = state.currentStep == BookingStep.paymentProcessing;

    return Container(
      padding: EdgeInsets.all(context.horizontalPadding),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back Button
            if (canGoBack)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : () => notifier.previousStep(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceM,
                    ),
                    side: const BorderSide(
                      color: AppColors.borderLight,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: Text(
                    'Nazad',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                ),
              ),

            if (canGoBack) const SizedBox(width: AppDimensions.spaceM),

            // Next/Continue Button
            Expanded(
              flex: canGoBack ? 2 : 1,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => _handleNextStep(context, state, notifier),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: AppDimensions.spaceM,
                  ),
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surfaceVariantLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  elevation: 0,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isLastStep ? 'Plati' : 'Nastavi',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNextStep(
    BuildContext context,
    BookingFlowState state,
    BookingFlowNotifier notifier,
  ) async {
    // Validate current step before proceeding
    switch (state.currentStep) {
      case BookingStep.guestDetails:
        if (!notifier.validateGuestDetails()) {
          _showError(context, 'Molimo popunite sve podatke');
          return;
        }
        break;

      case BookingStep.dateSelection:
        if (state.checkInDate == null || state.checkOutDate == null) {
          _showError(context, 'Molimo odaberite datum dolaska i odlaska');
          return;
        }
        break;

      case BookingStep.reviewSummary:
        // Create booking in database before proceeding to payment
        try {
          await notifier.createBooking();
        } catch (e) {
          _showError(context, 'Greška pri kreiranju rezervacije: $e');
          return;
        }
        break;

      case BookingStep.paymentMethod:
        // Validate payment method selection
        // TODO: Implement payment method validation
        break;

      case BookingStep.paymentProcessing:
        // Payment processing is automatic
        break;

      case BookingStep.success:
        // Already at success
        break;
    }

    // Move to next step
    notifier.nextStep();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }
}
