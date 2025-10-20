import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/calendar/availability_calendar_widget.dart';
import '../providers/unavailable_dates_provider.dart';

/// Premium booking widget for property details
/// Features: Real-time availability calendar, date selection, guest count, price calculation
class PremiumBookingWidget extends StatefulWidget {
  /// Property unit ID (for fetching unavailable dates)
  final String? unitId;

  /// Property price per night
  final double pricePerNight;

  /// Currency symbol
  final String currencySymbol;

  /// Minimum nights
  final int minNights;

  /// Maximum nights
  final int maxNights;

  /// Maximum guests
  final int maxGuests;

  /// Unavailable dates (deprecated - use unitId instead for real-time data)
  final List<DateTime> unavailableDates;

  /// Booking callback
  final Function({
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  })? onBook;

  /// Average rating
  final double? rating;

  /// Review count
  final int? reviewCount;

  const PremiumBookingWidget({
    super.key,
    this.unitId,
    required this.pricePerNight,
    this.currencySymbol = '\$',
    this.minNights = 1,
    this.maxNights = 30,
    this.maxGuests = 10,
    this.unavailableDates = const [],
    this.onBook,
    this.rating,
    this.reviewCount,
  });

  @override
  State<PremiumBookingWidget> createState() => _PremiumBookingWidgetState();
}

class _PremiumBookingWidgetState extends State<PremiumBookingWidget> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 2;

  int get _nightsCount {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double get _totalPrice {
    return _nightsCount * widget.pricePerNight;
  }

  double get _serviceFee {
    return _totalPrice * 0.12; // 12% service fee
  }

  double get _cleaningFee {
    return 50.0; // Fixed cleaning fee
  }

  double get _grandTotal {
    return _totalPrice + _serviceFee + _cleaningFee;
  }

  bool get _canBook {
    return _checkInDate != null &&
        _checkOutDate != null &&
        _nightsCount >= widget.minNights &&
        _nightsCount <= widget.maxNights;
  }

  /// Open calendar modal for date selection with real-time availability
  void _openCalendarModal() async {
    // Show loading if we need to fetch unavailable dates
    final List<DateTime> unavailableDates = widget.unavailableDates;

    // If unitId is provided, show modal with AsyncValue for real-time data
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Odaberite datum boravka',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Calendar widget
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: widget.unitId != null
                          ? Consumer(
                              builder: (context, ref, child) {
                                final unavailableDatesAsync = ref.watch(
                                  unitUnavailableDatesProvider(widget.unitId!),
                                );

                                return unavailableDatesAsync.when(
                                  data: (dates) {
                                    return AvailabilityCalendarWidget(
                                      unitId: widget.unitId!,
                                      checkInDate: _checkInDate,
                                      checkOutDate: _checkOutDate,
                                      unavailableDates: dates,
                                      minDate: DateTime.now(),
                                      maxDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      onDateRangeSelected: (checkIn, checkOut) {
                                        // Validate nights
                                        final nights = checkOut.difference(checkIn).inDays;
                                        if (nights < widget.minNights) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Minimum ${widget.minNights} noći potrebno',
                                              ),
                                              backgroundColor: AppColors.warning,
                                            ),
                                          );
                                          return;
                                        }
                                        if (nights > widget.maxNights) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Maksimum ${widget.maxNights} noći dozvoljeno',
                                              ),
                                              backgroundColor: AppColors.warning,
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          _checkInDate = checkIn;
                                          _checkOutDate = checkOut;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (error, stack) {
                                    return AvailabilityCalendarWidget(
                                      unitId: widget.unitId!,
                                      checkInDate: _checkInDate,
                                      checkOutDate: _checkOutDate,
                                      unavailableDates: widget.unavailableDates,
                                      minDate: DateTime.now(),
                                      maxDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      onDateRangeSelected: (checkIn, checkOut) {
                                        setState(() {
                                          _checkInDate = checkIn;
                                          _checkOutDate = checkOut;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                );
                              },
                            )
                          : AvailabilityCalendarWidget(
                              unitId: '',
                              checkInDate: _checkInDate,
                              checkOutDate: _checkOutDate,
                              unavailableDates: unavailableDates,
                              minDate: DateTime.now(),
                              maxDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              onDateRangeSelected: (checkIn, checkOut) {
                                setState(() {
                                  _checkInDate = checkIn;
                                  _checkOutDate = checkOut;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleBook() {
    if (_canBook && widget.onBook != null) {
      widget.onBook!(
        checkIn: _checkInDate!,
        checkOut: _checkOutDate!,
        guests: _guestCount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard.elevated(
      elevation: context.isDesktop ? 3 : 2,
      child: Padding(
        padding: EdgeInsets.all(
          context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with price and rating
            _buildHeader(),

            const SizedBox(height: AppDimensions.spaceL),

            // Date selection
            _buildDateSelection(),

            const SizedBox(height: AppDimensions.spaceM),

            // Guest count
            _buildGuestSelector(),

            // Price breakdown (if dates selected)
            if (_checkInDate != null && _checkOutDate != null) ...[
              const SizedBox(height: AppDimensions.spaceL),
              _buildPriceBreakdown(),
            ],

            const SizedBox(height: AppDimensions.spaceL),

            // Book button
            PremiumButton.primary(
              label: _canBook ? 'Reserve' : 'Select dates',
              icon: Icons.lock_outline,
              isFullWidth: true,
              size: ButtonSize.large,
              onPressed: _canBook ? _handleBook : null,
            ),

            if (_canBook) ...[
              const SizedBox(height: AppDimensions.spaceS),
              Center(
                child: Text(
                  'You won\'t be charged yet',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${widget.currencySymbol}${widget.pricePerNight.toStringAsFixed(0)}',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                TextSpan(
                  text: ' / night',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.rating != null && widget.reviewCount != null) ...[
          const Icon(
            Icons.star,
            size: AppDimensions.iconS,
            color: AppColors.star,
          ),
          const SizedBox(width: AppDimensions.spaceXXS),
          Text(
            '${widget.rating!.toStringAsFixed(1)} (${widget.reviewCount})',
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          // Check-in
          InkWell(
            onTap: _openCalendarModal,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusM),
              topRight: Radius.circular(AppDimensions.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHECK-IN',
                          style: AppTypography.small.copyWith(
                            fontWeight: AppTypography.weightBold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          _checkInDate != null
                              ? _formatDate(_checkInDate!)
                              : 'Add date',
                          style: _checkInDate != null
                              ? AppTypography.bodyMedium
                              : AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: AppDimensions.iconM,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Check-out
          InkWell(
            onTap: _openCalendarModal,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppDimensions.radiusM),
              bottomRight: Radius.circular(AppDimensions.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHECK-OUT',
                          style: AppTypography.small.copyWith(
                            fontWeight: AppTypography.weightBold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          _checkOutDate != null
                              ? _formatDate(_checkOutDate!)
                              : 'Add date',
                          style: _checkOutDate != null
                              ? AppTypography.bodyMedium
                              : AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: AppDimensions.iconM,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GUESTS',
                  style: AppTypography.small.copyWith(
                    fontWeight: AppTypography.weightBold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  '$_guestCount ${_guestCount == 1 ? 'guest' : 'guests'}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),

          // Guest counter
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                child: IconButton(
                  onPressed: _guestCount > 1
                      ? () {
                          setState(() {
                            _guestCount--;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: _guestCount > 1
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _guestCount.toString(),
                  style: AppTypography.h3.copyWith(
                    fontWeight: AppTypography.weightBold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                child: IconButton(
                  onPressed: _guestCount < widget.maxGuests
                      ? () {
                          setState(() {
                            _guestCount++;
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: _guestCount < widget.maxGuests
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Subtotal
        _buildPriceRow(
          '${widget.currencySymbol}${widget.pricePerNight.toStringAsFixed(0)} x $_nightsCount ${_nightsCount == 1 ? 'night' : 'nights'}',
          '${widget.currencySymbol}${_totalPrice.toStringAsFixed(2)}',
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Service fee
        _buildPriceRow(
          'Service fee',
          '${widget.currencySymbol}${_serviceFee.toStringAsFixed(2)}',
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Cleaning fee
        _buildPriceRow(
          'Cleaning fee',
          '${widget.currencySymbol}${_cleaningFee.toStringAsFixed(2)}',
        ),

        const SizedBox(height: AppDimensions.spaceM),

        Divider(
          thickness: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),

        const SizedBox(height: AppDimensions.spaceM),

        // Total
        _buildPriceRow(
          'Total',
          '${widget.currencySymbol}${_grandTotal.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightBold,
                )
              : AppTypography.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.primary,
                )
              : AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.weightMedium,
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Adapter widget with real data integration
class BookingWidget extends ConsumerWidget {
  final dynamic property;
  final dynamic unit;

  const BookingWidget({
    super.key,
    required this.property,
    required this.unit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extract price from unit
    final pricePerNight = (unit?.pricePerNight ?? property.pricePerNight ?? 0.0) as double;

    // Get property and unit IDs
    final propertyId = property.id as String;
    final unitId = unit?.id as String?;

    // Fetch unavailable dates if unit is selected
    final unavailableDatesAsync = unitId != null
        ? ref.watch(unitUnavailableDatesProvider(unitId))
        : const AsyncValue.data(<DateTime>[]);

    return unavailableDatesAsync.when(
      data: (unavailableDates) => PremiumBookingWidget(
        pricePerNight: pricePerNight,
        currencySymbol: '€',
        minNights: unit?.minStayNights ?? 1,
        maxNights: 30,
        maxGuests: property.maxGuests ?? 10,
        rating: property.rating,
        reviewCount: property.reviewCount,
        unavailableDates: unavailableDates,
        onBook: ({required checkIn, required checkOut, required guests}) {
          // Navigate to booking review screen
          if (unitId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a unit first')),
            );
            return;
          }

          // Calculate pricing
          final nights = checkOut.difference(checkIn).inDays;
          final subtotal = pricePerNight * nights;
          final serviceFee = subtotal * 0.12;
          final cleaningFee = 50.0;
          final total = subtotal + serviceFee + cleaningFee;

          // Navigate with all necessary data
          context.go(
            '/booking/review',
            extra: {
              'propertyId': propertyId,
              'propertyName': property.name,
              'unitId': unitId,
              'unitName': unit?.name ?? '',
              'checkIn': checkIn.toIso8601String(),
              'checkOut': checkOut.toIso8601String(),
              'guests': guests,
              'pricePerNight': pricePerNight,
              'nights': nights,
              'subtotal': subtotal,
              'serviceFee': serviceFee,
              'cleaningFee': cleaningFee,
              'totalPrice': total,
            },
          );
        },
      ),
      loading: () => PremiumBookingWidget(
        pricePerNight: pricePerNight,
        currencySymbol: '€',
        minNights: 1,
        maxNights: 30,
        maxGuests: property.maxGuests ?? 10,
        rating: property.rating,
        reviewCount: property.reviewCount,
        unavailableDates: const [],
        onBook: null, // Disable booking while loading
      ),
      error: (error, stack) => PremiumBookingWidget(
        pricePerNight: pricePerNight,
        currencySymbol: '€',
        minNights: 1,
        maxNights: 30,
        maxGuests: property.maxGuests ?? 10,
        rating: property.rating,
        reviewCount: property.reviewCount,
        unavailableDates: const [],
        onBook: ({required checkIn, required checkOut, required guests}) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading availability: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
