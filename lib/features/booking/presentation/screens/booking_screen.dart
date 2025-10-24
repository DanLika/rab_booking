import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../property/domain/models/property_unit.dart';
import '../../../property/presentation/providers/property_details_provider.dart';
import '../providers/booking_flow_notifier.dart';
import '../widgets/booking_calendar_widget.dart';

/// Booking screen - Select dates and guests for a unit
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({
    required this.unitId,
    super.key,
  });

  final String unitId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;
  int _guests = 2;

  @override
  Widget build(BuildContext context) {
    final unitAsync = ref.watch(unitDetailsProvider(widget.unitId));

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text('Rezervacija'),
        elevation: 0,
      ),
      body: unitAsync.when(
        data: (unit) {
          if (unit == null) {
            return const Center(
              child: ErrorStateWidget(
                message: 'Ova jedinica nije dostupna ili ne postoji.',
              ),
            );
          }

          return _buildContent(unit);
        },
        loading: () => _buildSkeletonLoader(),
        error: (error, stack) => Center(
          child: ErrorStateWidget(
            message: 'Greška pri učitavanju: ${error.toString()}',
            onRetry: () => ref.invalidate(unitDetailsProvider(widget.unitId)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PropertyUnit unit) {
    // Fetch property details to get property name and image
    final propertyAsync = ref.watch(propertyDetailsProvider(unit.propertyId));

    final hasSelectedDates = _selectedCheckIn != null && _selectedCheckOut != null;
    final nights = hasSelectedDates
        ? _selectedCheckOut!.difference(_selectedCheckIn!).inDays
        : 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unit header card
          _buildUnitHeader(unit, propertyAsync.valueOrNull),

          const SizedBox(height: 24),

          // Calendar section
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            padding: EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
              border: Border.all(color: context.borderColor),
              // Removed boxShadow for modern flat design (matches Home/Property pages)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Odaberite datume',
                  style: AppTypography.h2.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                BookingCalendarWidget(
                  unitId: widget.unitId,
                  minStayNights: unit.minStayNights,
                  onDatesSelected: (checkIn, checkOut) {
                    setState(() {
                      _selectedCheckIn = checkIn;
                      _selectedCheckOut = checkOut;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Guests selector
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            padding: EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broj gostiju',
                      style: AppTypography.h3.copyWith(
                        color: context.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maksimalno ${unit.maxGuests} gostiju',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textColorSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _guests > 1
                          ? () => setState(() => _guests--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _guests > 1
                          ? context.primaryColor
                          : context.textColorTertiary,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8),
                      ),
                      child: Text(
                        '$_guests',
                        style: AppTypography.h2.copyWith(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _guests < unit.maxGuests
                          ? () => setState(() => _guests++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: _guests < unit.maxGuests
                          ? context.primaryColor
                          : context.textColorTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Price breakdown (shown when dates are selected)
          if (hasSelectedDates) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              padding: EdgeInsets.all(AppDimensions.spaceM),
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalji cijene',
                    style: AppTypography.h3.copyWith(
                      color: context.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow(
                    '${unit.pricePerNight.toStringAsFixed(0)}€ × $nights ${nights == 1 ? 'noć' : 'noći'}',
                    '${(unit.pricePerNight * nights).toStringAsFixed(2)}€',
                  ),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Naknada za uslugu (10%)',
                    '${(unit.pricePerNight * nights * 0.10).toStringAsFixed(2)}€',
                  ),
                  _buildPriceRow(
                    'Naknada za čišćenje',
                    '50.00€',
                  ),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Ukupno',
                    '${(unit.pricePerNight * nights * 1.10 + 50).toStringAsFixed(2)}€',
                    isTotal: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    'Avansno plaćanje (20%)',
                    '${((unit.pricePerNight * nights * 1.10 + 50) * 0.20).toStringAsFixed(2)}€',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Continue button
          Padding(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Semantics(
              label: hasSelectedDates
                  ? 'Nastavi na pregled rezervacije za $nights ${nights == 1 ? 'noć' : 'noći'}, €${(unit.pricePerNight * nights * 1.10 + 50).toStringAsFixed(2)} ukupno'
                  : 'Prvo odaberite datume za nastavak',
              hint: hasSelectedDates
                  ? 'Dvostruki dodir za nastavak na detalje gostiju i plaćanje'
                  : 'Dugme je onemogućeno dok ne odaberete datume',
              button: true,
              enabled: hasSelectedDates,
              child: ElevatedButton(
                onPressed: hasSelectedDates
                    ? () => _proceedToReview(unit)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48), // AAA touch target
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px for buttons
                  ),
                  elevation: 0, // Flat design (matches Home/Property pages)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasSelectedDates
                          ? 'Nastavi na pregled'
                          : 'Odaberite datume za nastavak',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasSelectedDates) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUnitHeader(PropertyUnit unit, dynamic property) {
    return Container(
      margin: EdgeInsets.all(context.horizontalPadding),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
        border: Border.all(color: context.borderColor),
        // Removed boxShadow for modern flat design (matches Home/Property pages)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit image
          if (unit.coverImage != null || unit.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusM), // 20px to match card
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: unit.coverImage ?? unit.images.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.surfaceVariantColor,
                    child: const Center(
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.surfaceVariantColor,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: context.textColorTertiary,
                    ),
                  ),
                ),
              ),
            ),

          // Unit details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit name
                Text(
                  unit.name,
                  style: AppTypography.h1.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Property name (if available)
                if (property != null)
                  Text(
                    property.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: context.textColorSecondary,
                    ),
                  ),

                const SizedBox(height: 16),

                // Unit specs
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildSpec(Icons.people_outline, '${unit.maxGuests} gostiju'),
                    _buildSpec(Icons.bed_outlined, '${unit.bedrooms} ${unit.bedrooms == 1 ? 'soba' : 'sobe'}'),
                    _buildSpec(Icons.bathroom_outlined, '${unit.bathrooms} ${unit.bathrooms == 1 ? 'kupatilo' : 'kupatila'}'),
                    _buildSpec(Icons.square_foot, '${unit.area.toStringAsFixed(0)} m²'),
                  ],
                ),

                const SizedBox(height: 16),

                // Price per night
                Row(
                  children: [
                    Text(
                      '${unit.pricePerNight.toStringAsFixed(0)}€',
                      style: AppTypography.h2.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / noć',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textColorSecondary,
                      ),
                    ),
                  ],
                ),

                // Min stay nights
                if (unit.minStayNights > 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXS), // 6px modern radius,
                    ),
                    child: Text(
                      'Minimalno ${unit.minStayNights} ${unit.minStayNights == 1 ? 'noć' : 'noći'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpec(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: context.textColorSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal || isHighlighted
                    ? AppTypography.bodyLarge
                    : AppTypography.bodyMedium)
                .copyWith(
              color: isHighlighted
                  ? context.primaryColor
                  : context.textColor,
              fontWeight: (isTotal || isHighlighted)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: (isTotal || isHighlighted
                    ? AppTypography.h3
                    : AppTypography.bodyMedium)
                .copyWith(
              color: isHighlighted
                  ? context.primaryColor
                  : context.textColor,
              fontWeight: (isTotal || isHighlighted)
                  ? FontWeight.bold
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToReview(PropertyUnit unit) async {
    if (_selectedCheckIn == null || _selectedCheckOut == null) {
      return;
    }

    // Fetch property details
    final property = await ref.read(propertyDetailsProvider(unit.propertyId).future);

    if (property == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Greška pri učitavanju podataka o smještaju'),
            backgroundColor: context.errorColor,
          ),
        );
      }
      return;
    }

    // Initialize booking flow
    final bookingFlow = ref.read(bookingFlowNotifierProvider.notifier);

    final success = await bookingFlow.initializeBooking(
      property: property,
      unit: unit,
      checkIn: _selectedCheckIn!,
      checkOut: _selectedCheckOut!,
      guests: _guests,
    );

    if (!success) {
      if (mounted) {
        final error = ref.read(bookingFlowNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Greška pri inicijalizaciji rezervacije'),
            backgroundColor: context.errorColor,
          ),
        );
      }
      return;
    }

    // Navigate to review screen
    if (mounted) {
      context.push(Routes.bookingReview);
    }
  }

  /// Skeleton loader for initial loading state
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit header skeleton
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                children: [
                  // Image skeleton
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: SkeletonLoader(
                      borderRadius: 12,
                    ),
                  ),
                  // Details skeleton
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(width: 200, height: 28),
                        SizedBox(height: 8),
                        SkeletonLoader(width: 150, height: 18),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            SkeletonLoader(width: 80, height: 16),
                            SizedBox(width: 16),
                            SkeletonLoader(width: 80, height: 16),
                          ],
                        ),
                        SizedBox(height: 16),
                        SkeletonLoader(width: 100, height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Calendar skeleton
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 180, height: 24),
                  SizedBox(height: 16),
                  SkeletonLoader(width: double.infinity, height: 300),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Guests selector skeleton
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 120, height: 20),
                      SizedBox(height: 4),
                      SkeletonLoader(width: 150, height: 16),
                    ],
                  ),
                  SkeletonLoader(width: 150, height: 48),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Button skeleton
            const SkeletonLoader(
              width: double.infinity,
              height: 52,
              borderRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
