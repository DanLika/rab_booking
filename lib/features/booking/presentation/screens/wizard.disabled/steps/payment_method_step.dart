import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../providers/booking_flow_notifier.dart';
import '../../../providers/stripe_customer_provider.dart';
import '../../../data/services/stripe_customer_service.dart';

/// Step 4: Payment Method Selection
///
/// Features:
/// - Display payment amount (20% or full from review step)
/// - Show saved payment methods (if any)
/// - Add new card with Stripe Payment Sheet
/// - Apple Pay / Google Pay ready (coming soon)
class PaymentMethodStep extends ConsumerStatefulWidget {
  const PaymentMethodStep({super.key});

  @override
  ConsumerState<PaymentMethodStep> createState() => _PaymentMethodStepState();
}

class _PaymentMethodStepState extends ConsumerState<PaymentMethodStep> {
  String? _selectedPaymentMethodId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);
    final savedPaymentMethods = ref.watch(savedPaymentMethodsProvider);

    if (bookingState.bookingId == null) {
      return _buildErrorState('Booking ID not found');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Text(
                'Način plaćanja',
                style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'Odaberite način plaćanja ili dodajte novu karticu.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Payment Amount Display
              _buildPaymentAmountCard(bookingState),

              const SizedBox(height: AppDimensions.spaceL),

              // Saved Payment Methods
              savedPaymentMethods.when(
                data: (methods) => methods.isEmpty
                    ? _buildNoSavedCards()
                    : _buildSavedPaymentMethods(methods),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Add New Card Button
              _buildAddNewCardButton(),

              const SizedBox(height: AppDimensions.spaceL),

              // Digital Wallets (Coming Soon)
              _buildDigitalWallets(),

              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentAmountCard(BookingFlowState state) {
    final amountToPay = state.advancePaymentAmount;
    final isAdvancePayment = !state.isFullPaymentSelected;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.euro_outlined,
                color: Colors.white,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Iznos za plaćanje',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            '€${amountToPay.toStringAsFixed(2)}',
            style: AppTypography.h1.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.weightBold,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            isAdvancePayment
                ? '20% avans (ukupno: €${state.totalPrice.toStringAsFixed(2)})'
                : 'Plaćanje u cijelosti',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethods(List<PaymentMethodInfo> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sačuvane kartice',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: AppTypography.weightBold,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        ...methods.map((method) => _buildPaymentMethodCard(method)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodInfo method) {
    final isSelected = _selectedPaymentMethodId == method.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethodId = method.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppDimensions.spaceM),

            // Card icon
            _buildCardBrandIcon(method.brand),
            const SizedBox(width: AppDimensions.spaceM),

            // Card info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                  if (method.expirationDisplay != null) ...[
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      'Ističe: ${method.expirationDisplay}',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.errorLight,
              onPressed: () => _confirmDeletePaymentMethod(method),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBrandIcon(String? brand) {
    IconData icon;
    Color color;

    switch (brand?.toLowerCase()) {
      case 'visa':
        icon = Icons.credit_card;
        color = const Color(0xFF1A1F71);
      case 'mastercard':
        icon = Icons.credit_card;
        color = const Color(0xFFEB001B);
      case 'amex':
        icon = Icons.credit_card;
        color = const Color(0xFF006FCF);
      default:
        icon = Icons.credit_card;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(
        icon,
        color: color,
        size: AppDimensions.iconM,
      ),
    );
  }

  Widget _buildNoSavedCards() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.infoLight,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Text(
              'Nemate sačuvanih kartica. Dodajte novu karticu za plaćanje.',
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewCardButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isProcessing ? null : _handleAddNewCard,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_card),
        label: Text(_isProcessing ? 'Obrada...' : 'Dodaj novu karticu'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: AppDimensions.spaceM,
          ),
          side: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalWallets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Digitalni novčanici',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: AppTypography.weightBold,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Row(
          children: [
            Expanded(
              child: _buildDigitalWalletButton(
                icon: Icons.apple,
                label: 'Apple Pay',
                enabled: false, // TODO: Enable when credentials available
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: _buildDigitalWalletButton(
                icon: Icons.g_mobiledata,
                label: 'Google Pay',
                enabled: false, // TODO: Enable when credentials available
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitalWalletButton({
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    return OutlinedButton.icon(
      onPressed: enabled ? () {} : null,
      icon: Icon(icon),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (!enabled)
            Text(
              'Uskoro',
              style: AppTypography.small.copyWith(
                fontSize: 10,
              ),
            ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: AppDimensions.spaceM,
        ),
        side: BorderSide(
          color: enabled ? AppColors.borderLight : AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
        foregroundColor: enabled ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorLight,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Greška',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.errorLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.errorLight,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.errorLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddNewCard() async {
    setState(() => _isProcessing = true);

    try {
      final bookingState = ref.read(bookingFlowNotifierProvider);
      final bookingNotifier = ref.read(bookingFlowNotifierProvider.notifier);
      final paymentIntentCreator = ref.read(paymentIntentCreatorProvider.notifier);
      final stripeCustomerId = ref.read(stripeCustomerIdProvider.notifier);

      // Ensure we have a Stripe Customer ID
      String? customerId = await stripeCustomerId.future;
      if (customerId == null) {
        customerId = await stripeCustomerId.getOrCreate(
          email: bookingState.guestEmail!,
          firstName: bookingState.guestFirstName!,
          lastName: bookingState.guestLastName!,
          phone: bookingState.guestPhone,
        );
      }

      // Create Payment Intent
      final paymentIntentResult = await paymentIntentCreator.createPaymentIntent(
        bookingId: bookingState.bookingId!,
        totalAmount: bookingState.totalPrice,
        advancePaymentAmount: bookingState.advancePaymentAmount,
        isFullPayment: bookingState.isFullPaymentSelected,
      );

      // Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Rab Booking',
          paymentIntentClientSecret: paymentIntentResult.clientSecret,
          customerEphemeralKeySecret: paymentIntentResult.ephemeralKey,
          customerId: customerId,
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
        ),
      );

      // Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful!
      await paymentIntentCreator.confirmPayment(
        bookingId: bookingState.bookingId!,
        paymentIntentId: paymentIntentResult.paymentIntentId,
      );

      // Refresh saved payment methods
      await ref.read(savedPaymentMethodsProvider.notifier).refresh();

      // Move to success step
      if (mounted) {
        bookingNotifier.nextStep();
      }
    } on StripeException catch (e) {
      if (mounted) {
        _showError('Stripe greška: ${e.error.localizedMessage ?? e.error.message}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Greška pri plaćanju: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _confirmDeletePaymentMethod(PaymentMethodInfo method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje kartice'),
        content: Text(
          'Da li ste sigurni da želite obrisati ${method.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorLight,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(savedPaymentMethodsProvider.notifier).detachPaymentMethod(method.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kartica obrisana')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showError('Greška pri brisanju kartice: $e');
        }
      }
    }
  }

  void _showError(String message) {
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
