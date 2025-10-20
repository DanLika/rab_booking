import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Premium payment success animation widget
/// Features: Animated checkmark, confetti effect, success message
class PaymentSuccessAnimation extends StatefulWidget {
  /// Success message
  final String message;

  /// Amount paid
  final String amount;

  /// Show confetti
  final bool showConfetti;

  const PaymentSuccessAnimation({
    super.key,
    this.message = 'Payment Successful!',
    required this.amount,
    this.showConfetti = true,
  });

  @override
  State<PaymentSuccessAnimation> createState() =>
      _PaymentSuccessAnimationState();
}

class _PaymentSuccessAnimationState extends State<PaymentSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  late Animation<double> _checkmarkAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Checkmark animation
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Start animations sequentially
    _scaleController.forward().then((_) {
      _checkmarkController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated checkmark circle
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glowPrimary,
            ),
            child: ScaleTransition(
              scale: _checkmarkAnimation,
              child: Icon(
                Icons.check_rounded,
                size: 80,
                color: context.textColorInverted,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spaceXXL),

        // Success message
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Text(
                widget.message,
                style: AppTypography.h1.copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceM),

              // Amount
              Builder(
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                    vertical: AppDimensions.spaceM,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.withOpacity(
                          AppColors.success,
                          AppColors.opacity10,
                        ),
                        AppColors.withOpacity(
                          AppColors.primary,
                          AppColors.opacity10,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Text(
                    widget.amount,
                    style: AppTypography.displaySmall.copyWith(
                      fontWeight: AppTypography.weightBold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceM),

              Builder(
                builder: (context) => Text(
                  'Your booking is confirmed!',
                  style: AppTypography.bodyLarge.copyWith(
                    color: context.textColorSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Payment success details widget
class PaymentSuccessDetails extends StatelessWidget {
  /// Payment reference
  final String paymentReference;

  /// Receipt email
  final String? receiptEmail;

  /// Show download receipt button
  final bool showReceiptButton;

  /// On download receipt
  final VoidCallback? onDownloadReceipt;

  const PaymentSuccessDetails({
    super.key,
    required this.paymentReference,
    this.receiptEmail,
    this.showReceiptButton = true,
    this.onDownloadReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment reference
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: context.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: AppDimensions.iconM,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Text(
                    'Payment Reference',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColorSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                paymentReference,
                style: AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightBold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        if (receiptEmail != null) ...[
          const SizedBox(height: AppDimensions.spaceL),

          // Email confirmation
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.withOpacity(
                AppColors.success,
                AppColors.opacity10,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: AppDimensions.iconM,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt Sent',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: AppTypography.weightSemibold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXXS),
                      Text(
                        'Check $receiptEmail for your receipt',
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (showReceiptButton) ...[
          const SizedBox(height: AppDimensions.spaceL),

          // Download receipt button
          OutlinedButton.icon(
            onPressed: onDownloadReceipt,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download Receipt'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceL,
                vertical: AppDimensions.spaceM,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
