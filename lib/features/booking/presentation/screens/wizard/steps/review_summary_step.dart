import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../providers/booking_flow_notifier.dart';
import '../../../widgets/booking_summary_card.dart';
import '../../../widgets/cancellation_policy_widget.dart';

/// Step 3: Review Summary
///
/// Review all booking details before payment:
/// - Property and dates summary
/// - Guest details
/// - Price breakdown with tax
/// - Refund/cancellation policy
/// - Advance payment vs full payment selection
class ReviewSummaryStep extends ConsumerWidget {
  const ReviewSummaryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);
    final bookingNotifier = ref.read(bookingFlowNotifierProvider.notifier);

    if (bookingState.selectedUnit == null ||
        bookingState.property == null ||
        bookingState.checkInDate == null ||
        bookingState.checkOutDate == null) {
      return _buildErrorState();
    }

    final nights =
        bookingState.checkOutDate!.difference(bookingState.checkInDate!).inDays;

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Text(
                'Pregled rezervacije',
                style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'Pregledajte sve detalje prije nastavka na plaćanje.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Booking Summary Card
              BookingSummaryCard(
                propertyName: bookingState.property!.name,
                propertyImage: bookingState.property!.imageUrl,
                propertyLocation:
                    '${bookingState.property!.city}, ${bookingState.property!.country}',
                checkIn: bookingState.checkInDate!,
                checkOut: bookingState.checkOutDate!,
                guests: bookingState.numberOfGuests,
                nights: nights,
                pricePerNight: bookingState.selectedUnit!.pricePerNight,
                serviceFee: bookingState.serviceFee,
                cleaningFee: bookingState.cleaningFee,
                taxes: bookingState.taxAmount,
                showEditButton: false,
              ),

              const SizedBox(height: AppDimensions.spaceL),

              // Guest Details Summary
              _buildGuestDetailsSummary(bookingState),

              const SizedBox(height: AppDimensions.spaceL),

              // Payment Amount Selection (20% vs Full)
              _buildPaymentAmountSelector(context, bookingState, bookingNotifier),

              const SizedBox(height: AppDimensions.spaceL),

              // Cancellation Policy
              if (bookingState.currentRefundPolicy != null)
                _buildCancellationPolicy(bookingState),

              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
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
              'Nema podataka za rezervaciju',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Molimo vratite se nazad i popunite sve podatke.',
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

  Widget _buildGuestDetailsSummary(BookingFlowState state) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Podaci gosta',
                style: AppTypography.h3,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: AppDimensions.spaceM),
          _buildDetailRow('Ime i prezime',
              '${state.guestFirstName ?? ''} ${state.guestLastName ?? ''}'),
          const SizedBox(height: AppDimensions.spaceS),
          _buildDetailRow('Email', state.guestEmail ?? ''),
          const SizedBox(height: AppDimensions.spaceS),
          _buildDetailRow('Telefon', state.guestPhone ?? ''),
          if (state.specialRequests != null &&
              state.specialRequests!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'Posebni zahtjevi:',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              state.specialRequests!,
              style: AppTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentAmountSelector(
    BuildContext context,
    BookingFlowState state,
    BookingFlowNotifier notifier,
  ) {
    final advanceAmount = state.totalPrice * 0.20;
    final fullAmount = state.totalPrice;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
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
                Icons.payment_outlined,
                color: Colors.white,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Iznos plaćanja',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'Odaberite koliko želite platiti sada:',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // 20% Advance Payment Option
          _buildPaymentOption(
            isSelected: !state.isFullPaymentSelected,
            title: '20% avansom (preporučeno)',
            amount: advanceAmount,
            description:
                'Platite samo 20% sada, ostatak na dan dolaska.',
            onTap: () => notifier.toggleFullPayment(false),
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // Full Payment Option
          _buildPaymentOption(
            isSelected: state.isFullPaymentSelected,
            title: 'Plaćanje u cijelosti',
            amount: fullAmount,
            description: 'Platite sve odmah i završite rezervaciju.',
            onTap: () => notifier.toggleFullPayment(true),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required bool isSelected,
    required String title,
    required double amount,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color:
                isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.white,
              size: AppDimensions.iconL,
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: AppTypography.weightBold,
                      color:
                          isSelected ? AppColors.textPrimaryLight : Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    description,
                    style: AppTypography.small.copyWith(
                      color: isSelected
                          ? AppColors.textSecondaryLight
                          : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Text(
              '€${amount.toStringAsFixed(2)}',
              style: AppTypography.h3.copyWith(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationPolicy(BookingFlowState state) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.warningLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.warningLight,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Politika otkazivanja',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            state.currentRefundPolicy!.displayDescription,
            style: AppTypography.bodyMedium,
          ),
          if (!state.canCancelBooking) ...[
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Napomena: Otkazivanje nije moguće unutar 7 dana prije dolaska.',
              style: AppTypography.small.copyWith(
                color: AppColors.errorLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
