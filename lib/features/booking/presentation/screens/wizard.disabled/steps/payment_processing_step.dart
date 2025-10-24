import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../providers/booking_flow_notifier.dart';

/// Step 5: Payment Processing
///
/// Shows processing UI while Stripe PaymentIntent is being confirmed
/// - Animated loading indicator
/// - Processing status messages
/// - Error handling with retry option
/// - Auto-advances to success step on completion
class PaymentProcessingStep extends ConsumerStatefulWidget {
  const PaymentProcessingStep({super.key});

  @override
  ConsumerState<PaymentProcessingStep> createState() =>
      _PaymentProcessingStepState();
}

class _PaymentProcessingStepState extends ConsumerState<PaymentProcessingStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Start processing automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPayment();
    });
  }

  /// Process payment and create booking
  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(bookingFlowNotifierProvider.notifier);

      // Process payment (this confirms the PaymentIntent with Stripe)
      await notifier.processPayment();

      // On success, automatically advance to success step
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        notifier.nextStep();
      }
    } catch (error) {
      // Error handling - show error message but keep on this step
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(error.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Greška pri plaćanju: $message'),
        backgroundColor: AppColors.errorLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Pokušaj ponovo',
          textColor: Colors.white,
          onPressed: _processPayment,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: context.isMobile ? 60 : 100),

              // Processing Animation
              SizedBox(
                height: 250,
                child: Lottie.asset(
                  'assets/animations/payment_processing.json',
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if Lottie file doesn't exist
                    return FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          size: 90,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Processing Title
              Text(
                'Plaćanje u tijeku...',
                style: context.isMobile ? AppTypography.h2 : AppTypography.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceM),

              // Processing Message
              Text(
                'Molimo pričekajte dok procesuiramo vašu uplatu putem Stripe-a.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Loading Indicator
              if (_isProcessing) ...[
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
              ],

              // Status Messages
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatusItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Potvrđivanje plaćanja',
                      subtitle: 'Stripe PaymentIntent se procesira...',
                      isComplete: false,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _buildStatusItem(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Kreiranje rezervacije',
                      subtitle: 'Spremanje vaših podataka u bazu...',
                      isComplete: false,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _buildStatusItem(
                      icon: Icons.email_outlined,
                      title: 'Slanje potvrde',
                      subtitle: 'Priprema e-računa i potvrde...',
                      isComplete: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Security Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.successLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.successLight,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    Flexible(
                      child: Text(
                        'Vaša uplata je sigurna i zaštićena Stripe enkripcijom',
                        style: AppTypography.small.copyWith(
                          color: AppColors.successLight,
                          fontWeight: AppTypography.weightSemibold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Retry Button (only shown if processing failed)
              if (!_isProcessing && bookingState.error != null) ...[
                const SizedBox(height: AppDimensions.spaceXL),
                ElevatedButton.icon(
                  onPressed: _processPayment,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingXL,
                      vertical: AppDimensions.paddingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                ),
              ],

              SizedBox(height: context.isMobile ? 60 : 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isComplete,
  }) {
    return Row(
      children: [
        // Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isComplete
                ? AppColors.successLight
                : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isComplete ? Icons.check : icon,
            color: isComplete ? Colors.white : AppColors.primary,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: isComplete
                      ? AppColors.textPrimaryLight
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                subtitle,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        // Loading indicator for current item
        if (!isComplete) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}
