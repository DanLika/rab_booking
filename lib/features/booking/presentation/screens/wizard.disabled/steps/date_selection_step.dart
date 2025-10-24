import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../providers/booking_flow_notifier.dart';
import '../../../widgets/booking_calendar_widget.dart';

/// Step 2: Date Selection
///
/// Real-time calendar for selecting check-in and check-out dates.
/// Features:
/// - Two-month view (desktop) / Single month (mobile)
/// - Real-time unavailable dates from Supabase
/// - Minimum stay validation
/// - Guest count selector
class DateSelectionStep extends ConsumerWidget {
  const DateSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);
    final bookingNotifier = ref.read(bookingFlowNotifierProvider.notifier);

    if (bookingState.selectedUnit == null) {
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
                'Nema odabrane jedinice',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'Molimo vratite se nazad i odaberite smještaj.',
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Text(
                'Odaberite datume',
                style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                'Odaberite datum dolaska i odlaska. Zeleni datumi su dostupni, sivi su zauzeti.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Guest Count Selector
              _buildGuestCountSelector(context, bookingState, bookingNotifier),

              const SizedBox(height: AppDimensions.spaceXL),

              // Calendar Widget
              BookingCalendarWidget(
                unitId: bookingState.selectedUnit!.id,
                minStayNights: 1,
                onDatesSelected: (checkIn, checkOut) {
                  if (checkIn != null && checkOut != null) {
                    // Note: initializeBooking will validate dates against unavailable dates
                    // and automatically calculate prices
                    bookingNotifier.initializeBooking(
                      property: bookingState.property!,
                      unit: bookingState.selectedUnit!,
                      checkIn: checkIn,
                      checkOut: checkOut,
                      guests: bookingState.numberOfGuests,
                    );
                  }
                },
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Selected dates summary (if dates are selected)
              if (bookingState.checkInDate != null &&
                  bookingState.checkOutDate != null)
                _buildDatesSummary(context, bookingState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCountSelector(
    BuildContext context,
    BookingFlowState state,
    BookingFlowNotifier notifier,
  ) {
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
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: AppColors.primary,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broj gostiju',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Cijena po osobi/noć: €${state.selectedUnit?.pricePerNight.toStringAsFixed(2) ?? '0.00'}',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          // Minus button
          IconButton(
            onPressed: state.numberOfGuests > 1
                ? () => notifier.updateNumberOfGuests(state.numberOfGuests - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
            iconSize: AppDimensions.iconL,
          ),
          // Guest count
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Text(
              '${state.numberOfGuests}',
              style: AppTypography.h3.copyWith(
                color: AppColors.primary,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ),
          // Plus button
          IconButton(
            onPressed: state.numberOfGuests < 10
                ? () => notifier.updateNumberOfGuests(state.numberOfGuests + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
            iconSize: AppDimensions.iconL,
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSummary(BuildContext context, BookingFlowState state) {
    final nights = state.checkOutDate!.difference(state.checkInDate!).inDays;

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
                Icons.check_circle_outline,
                color: Colors.white,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Datumi odabrani',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: AppTypography.weightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Divider(color: Colors.white.withOpacity(0.3), height: 1),
          const SizedBox(height: AppDimensions.spaceM),
          _buildDateRow(
            'Dolazak',
            state.checkInDate!,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          _buildDateRow(
            'Odlazak',
            state.checkOutDate!,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            children: [
              Icon(
                Icons.nightlight_outlined,
                color: Colors.white.withOpacity(0.9),
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Text(
                '$nights ${nights == 1 ? 'noć' : 'noći'}',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime date) {
    final formattedDate =
        '${date.day}.${date.month}.${date.year}.';

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          color: Colors.white.withOpacity(0.9),
          size: AppDimensions.iconM,
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Text(
          '$label:',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Text(
          formattedDate,
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.weightSemibold,
          ),
        ),
      ],
    );
  }
}
