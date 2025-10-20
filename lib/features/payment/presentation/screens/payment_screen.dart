import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../booking/presentation/providers/booking_flow_notifier.dart';
import '../providers/payment_notifier.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_summary.dart';

/// Premium payment processing screen with Stripe integration
/// Features: Premium UI, Stripe CardField, payment summary, error handling
class PremiumPaymentScreen extends ConsumerStatefulWidget {
  /// Booking ID
  final String bookingId;

  const PremiumPaymentScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<PremiumPaymentScreen> createState() =>
      _PremiumPaymentScreenState();
}

class _PremiumPaymentScreenState extends ConsumerState<PremiumPaymentScreen> {
  bool _isCardComplete = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _createPaymentIntent();
        _hasInitialized = true;
      }
    });
  }

  Future<void> _createPaymentIntent() async {
    final bookingFlow = ref.read(bookingFlowNotifierProvider);

    if (bookingFlow.totalPrice <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid payment amount'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      }
      return;
    }

    try {
      // Convert to cents for Stripe
      final amountInCents = (bookingFlow.advanceAmount * 100).round();

      await ref.read(paymentNotifierProvider.notifier).createPaymentIntent(
            bookingId: widget.bookingId,
            totalAmount: amountInCents,
          );
    } catch (e) {
      if (mounted) {
        _showError('Failed to initialize payment: ${e.toString()}');
      }
    }
  }

  Future<void> _handlePayment() async {
    if (!_isCardComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete card details'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final bookingFlow = ref.read(bookingFlowNotifierProvider);

    try {
      // Create billing details
      final billingDetails = BillingDetails(
        email: bookingFlow.guestEmail,
        name:
            '${bookingFlow.guestFirstName ?? ''} ${bookingFlow.guestLastName ?? ''}'
                .trim(),
        phone: bookingFlow.guestPhone,
      );

      // Process payment
      await ref.read(paymentNotifierProvider.notifier).processPayment(
            bookingId: widget.bookingId,
            billingDetails: billingDetails,
          );

      // Check payment status
      final paymentState = ref.read(paymentNotifierProvider);

      if (paymentState.isSuccess && mounted) {
        // Navigate to success screen
        context.go('/booking-success/${widget.bookingId}');
      } else if (paymentState.isFailed && mounted) {
        _showPaymentErrorDialog(
          paymentState.error ?? 'Payment failed',
        );
      }
    } catch (e) {
      if (mounted) {
        _showPaymentErrorDialog(_getUserFriendlyError(e));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showPaymentErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 28),
            SizedBox(width: AppDimensions.spaceM),
            Text('Payment Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: AppDimensions.spaceL),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(
                  AppColors.info,
                  AppColors.opacity10,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: AppDimensions.iconM,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(
                    child: Text(
                      'Your booking is still saved. You can try again.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PremiumButton.text(
            label: 'Cancel',
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
          ),
          PremiumButton.primary(
            label: 'Try Again',
            icon: Icons.refresh,
            onPressed: () {
              Navigator.of(context).pop();
              _handlePayment();
            },
          ),
        ],
      ),
    );
  }

  String _getUserFriendlyError(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('canceled')) {
      return 'Payment was canceled. Please try again.';
    }
    if (errorString.contains('declined')) {
      return 'Card was declined. Please check your details or use a different card.';
    }
    if (errorString.contains('insufficient')) {
      return 'Insufficient funds. Please use a different card.';
    }
    if (errorString.contains('expired')) {
      return 'Card has expired. Please use a valid card.';
    }
    if (errorString.contains('timeout')) {
      return 'Payment timed out. Please check your connection and try again.';
    }

    return 'Payment failed: ${error.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingFlow = ref.watch(bookingFlowNotifierProvider);
    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: paymentState.paymentIntent == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: ResponsiveBuilder(
                  mobile: (context, constraints) => _buildMobileLayout(
                    bookingFlow,
                    paymentState,
                  ),
                  tablet: (context, constraints) => _buildMobileLayout(
                    bookingFlow,
                    paymentState,
                  ),
                  desktop: (context, constraints) => _buildDesktopLayout(
                    bookingFlow,
                    paymentState,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMobileLayout(
    BookingFlowState bookingFlow,
    PaymentState paymentState,
  ) {
    return Padding(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment amount header
          _buildPaymentAmountHeader(bookingFlow),

          const SizedBox(height: AppDimensions.spaceXL),

          // Payment card widget
          PremiumPaymentCard(
            onCardChanged: (card) {
              setState(() {
                _isCardComplete = card?.complete ?? false;
              });
            },
            enablePostalCode: true,
            countryCode: 'HR',
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Payment summary
          PremiumPaymentSummary(
            basePrice: bookingFlow.basePrice,
            serviceFee: bookingFlow.serviceFee,
            cleaningFee: bookingFlow.cleaningFee,
            totalAmount: bookingFlow.totalPrice,
            advancePercentage: 20.0,
            currencySymbol: '€',
          ),

          const SizedBox(height: AppDimensions.spaceXXL),

          // Pay button
          _buildPayButton(paymentState, bookingFlow),

          const SizedBox(height: AppDimensions.spaceXL),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BookingFlowState bookingFlow,
    PaymentState paymentState,
  ) {
    return MaxWidthContainer(
      maxWidth: AppDimensions.containerL,
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Payment form
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment amount header
                _buildPaymentAmountHeader(bookingFlow),

                const SizedBox(height: AppDimensions.spaceXL),

                // Payment card widget
                PremiumPaymentCard(
                  onCardChanged: (card) {
                    setState(() {
                      _isCardComplete = card?.complete ?? false;
                    });
                  },
                  enablePostalCode: true,
                  countryCode: 'HR',
                ),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Pay button
                _buildPayButton(paymentState, bookingFlow),
              ],
            ),
          ),

          const SizedBox(width: AppDimensions.spaceXXL),

          // Right column - Summary (sticky)
          SizedBox(
            width: 380,
            child: PremiumPaymentSummary(
              basePrice: bookingFlow.basePrice,
              serviceFee: bookingFlow.serviceFee,
              cleaningFee: bookingFlow.cleaningFee,
              totalAmount: bookingFlow.totalPrice,
              advancePercentage: 20.0,
              currencySymbol: '€',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAmountHeader(BookingFlowState bookingFlow) {
    return PremiumCard.elevated(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.withOpacity(AppColors.primary, AppColors.opacity10),
              AppColors.withOpacity(AppColors.secondary, AppColors.opacity10),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Text(
              'Amount to Pay',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              '€${bookingFlow.advanceAmount.toStringAsFixed(2)}',
              style: AppTypography.h1.copyWith(
                fontWeight: AppTypography.weightBold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              '(20% advance of total amount)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(
    PaymentState paymentState,
    BookingFlowState bookingFlow,
  ) {
    return PremiumButton.primary(
      label: paymentState.isProcessing
          ? 'Processing...'
          : 'Pay €${bookingFlow.advanceAmount.toStringAsFixed(2)}',
      icon: paymentState.isProcessing ? null : Icons.lock_outlined,
      isFullWidth: true,
      size: ButtonSize.large,
      onPressed:
          paymentState.isProcessing || !_isCardComplete ? null : _handlePayment,
      isLoading: paymentState.isProcessing,
    );
  }
}

// Backwards compatibility typedef
typedef PaymentScreen = PremiumPaymentScreen;
