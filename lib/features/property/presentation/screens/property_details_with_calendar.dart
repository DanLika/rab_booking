import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../calendar/presentation/widgets/animated_calendar_grid.dart';
import '../../../calendar/presentation/providers/booking_flow_provider.dart';
import '../../../calendar/domain/models/calendar_permissions.dart';
import '../../../calendar/domain/models/calendar_day.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/adaptive_spacing.dart';
import '../../domain/models/property_unit.dart';
import '../providers/property_details_provider.dart';

/// Property details screen with integrated calendar for booking
class PropertyDetailsWithCalendar extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailsWithCalendar({
    required this.propertyId,
    super.key,
  });

  @override
  ConsumerState<PropertyDetailsWithCalendar> createState() =>
      _PropertyDetailsWithCalendarState();
}

class _PropertyDetailsWithCalendarState
    extends ConsumerState<PropertyDetailsWithCalendar> {
  int _selectedUnitIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Fetch property data
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final unitsAsync = ref.watch(propertyUnitsProvider(widget.propertyId));

    return Scaffold(
      body: propertyAsync.when(
        data: (property) {
          if (property == null) {
            return const Center(child: Text('Property not found'));
          }
          return unitsAsync.when(
            data: (units) => _buildContent(property, units),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading units: ${error.toString()}'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildContent(PropertyModel property, List<PropertyUnit> units) {
    // If no units, show error
    if (units.isEmpty) {
      return const Center(child: Text('No units available'));
    }

    // Ensure selected index is valid
    if (_selectedUnitIndex >= units.length) {
      _selectedUnitIndex = 0;
    }

    final selectedUnit = units[_selectedUnitIndex];

    return CustomScrollView(
      slivers: [
        // Property header with images
        _buildPropertyHeader(property),

        // Property info section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.horizontalPadding,
              vertical: context.spacing.verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property title
                Text(
                  property.name,
                  style: context.typography.title,
                ),
                SizedBox(height: context.spacing.elementSpacing),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: context.spacing.smallIconSize,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(width: context.spacing.responsive(mobile: 4, tablet: 6, desktop: 8)),
                    Expanded(
                      child: Text(
                        property.location,
                        style: context.typography.body.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.elementSpacing),

                // Rating
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: context.spacing.iconSize,
                    ),
                    SizedBox(width: context.spacing.responsive(mobile: 4, tablet: 6, desktop: 8)),
                    Text(
                      '${property.rating.toStringAsFixed(1)} (${property.reviewCount} reviews)',
                      style: context.typography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.sectionSpacing),

                // Description
                Text(
                  'About this property',
                  style: context.typography.subtitle,
                ),
                SizedBox(height: context.spacing.elementSpacing),
                Text(
                  property.description,
                  style: context.typography.body,
                  maxLines: AppBreakpoints.isSmallPhone(context) ? 3 : null,
                ),
                SizedBox(height: context.spacing.sectionSpacing),

                // Amenities
                if (property.amenities.isNotEmpty) ...[
                  Text(
                    'Amenities',
                    style: context.typography.subtitle,
                  ),
                  SizedBox(height: context.spacing.elementSpacing),
                  Wrap(
                    spacing: context.spacing.responsive(mobile: 6, tablet: 8, desktop: 10),
                    runSpacing: context.spacing.responsive(mobile: 6, tablet: 8, desktop: 10),
                    children: property.amenities.map((amenity) {
                      return Chip(
                        label: Text(
                          amenity.displayName,
                          style: context.typography.caption,
                        ),
                        avatar: Icon(
                          _getAmenityIconFromEnum(amenity),
                          size: context.spacing.smallIconSize,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.responsive(mobile: 6, tablet: 8, desktop: 10),
                          vertical: context.spacing.responsive(mobile: 4, tablet: 6, desktop: 6),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: context.spacing.sectionSpacing),
                ],

                // Unit selector (if multiple units)
                if (units.length > 1) ...[
                  Text(
                    'Select Unit',
                    style: context.typography.subtitle,
                  ),
                  SizedBox(height: context.spacing.elementSpacing),
                  SizedBox(
                    height: context.spacing.responsive(
                      mobile: 100,  // iPhone SE - compact cards
                      tablet: 120,
                      desktop: 140,
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: units.length,
                      separatorBuilder: (context, index) => SizedBox(
                        width: context.spacing.responsive(mobile: 8, tablet: 12, desktop: 16),
                      ),
                      itemBuilder: (context, index) {
                        final unit = units[index];
                        final isSelected = index == _selectedUnitIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedUnitIndex = index);
                          },
                          child: Container(
                            width: context.spacing.responsive(
                              mobile: 160,  // iPhone SE - narrower cards
                              tablet: 200,
                              desktop: 240,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(context.spacing.borderRadius),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: EdgeInsets.all(context.spacing.cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  unit.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.spacing.responsive(
                                      mobile: 14,
                                      tablet: 15,
                                      desktop: 16,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(
                                  height: context.spacing.responsive(mobile: 4, tablet: 6, desktop: 8),
                                ),
                                Text(
                                  '${unit.bedrooms} bed • ${unit.bathrooms} bath',
                                  style: context.typography.caption,
                                ),
                                const Spacer(),
                                Text(
                                  '€${unit.pricePerNight}/night',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.spacing.responsive(
                                      mobile: 14,
                                      tablet: 15,
                                      desktop: 16,
                                    ),
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.spacing.sectionSpacing),
                ],

                // CALENDAR SECTION
                Text(
                  'Select Your Dates',
                  style: context.typography.subtitle,
                ),
                SizedBox(height: context.spacing.elementSpacing),
                Text(
                  'Tap check-in and check-out dates to see availability',
                  style: context.typography.caption,
                ),
                SizedBox(height: context.spacing.elementSpacing),

                // Calendar with real-time updates
                Card(
                  elevation: context.spacing.responsive(mobile: 2, tablet: 3, desktop: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.spacing.borderRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing.cardPadding),
                    child: AnimatedCalendarGrid(
                      unitId: selectedUnit.id,
                      month: DateTime.now(),
                      enableAnimations: !AppBreakpoints.isSmallPhone(context), // Disable on small phones for performance
                      showNotifications: true,
                      onDateTap: (date, dayData) {
                        _handleDateSelection(
                          date,
                          dayData,
                          selectedUnit.id,
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: context.spacing.sectionSpacing),

                // Booking summary section (shown when dates selected)
                _buildBookingSummarySection(selectedUnit),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyHeader(PropertyModel property) {
    return SliverAppBar(
      // Adaptive expanded height
      expandedHeight: context.spacing.responsive(
        mobile: 250,   // iPhone SE - smaller height
        tablet: 350,   // iPad
        desktop: 450,  // Mac/Desktop
      ),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (property.images.isNotEmpty)
              PageView.builder(
                itemCount: property.images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    property.images[index],
                    fit: BoxFit.cover,
                  );
                },
              )
            else
              Container(
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.image,
                  size: context.spacing.responsive(
                    mobile: 48,
                    tablet: 56,
                    desktop: 64,
                  ),
                ),
              ),

            // Gradient overlay - adaptive height
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: context.spacing.responsive(
                  mobile: 60,  // iPhone SE - smaller gradient
                  tablet: 80,
                  desktop: 100,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummarySection(PropertyUnit unit) {
    final bookingFlow = ref.watch(
      bookingFlowProvider(widget.propertyId, unit.id),
    );

    if (!bookingFlow.hasDatesSelected) {
      return const SizedBox.shrink();
    }

    final summary = ref.watch(
      bookingSummaryNotifierProvider(widget.propertyId, unit.id),
    );

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: context.spacing.responsive(mobile: 2, tablet: 3, desktop: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.spacing.borderRadius),
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Summary',
                  style: context.typography.subtitle,
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(bookingFlowProvider(widget.propertyId, unit.id).notifier)
                        .clearDates();
                  },
                  child: Text(
                    'Clear',
                    style: context.typography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.elementSpacing),

            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in',
                        style: context.typography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        summary.checkInDisplay,
                        style: context.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: context.spacing.smallIconSize,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-out',
                        style: context.typography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        summary.checkOutDisplay,
                        style: context.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.spacing.elementSpacing),

            // Price breakdown
            _PriceSummaryRow(
              label: '€${summary.pricePerNight.toStringAsFixed(0)} x ${summary.nights} nights',
              value: summary.formatAmount(summary.subtotal),
            ),
            _PriceSummaryRow(
              label: 'Service fee',
              value: summary.formatAmount(summary.serviceFee),
            ),
            _PriceSummaryRow(
              label: 'Cleaning fee',
              value: summary.formatAmount(summary.cleaningFee),
            ),

            const Divider(height: 24),

            _PriceSummaryRow(
              label: 'Total',
              value: summary.formatAmount(summary.total),
              isTotal: true,
            ),

            SizedBox(height: context.spacing.elementSpacing),

            // Book button
            SizedBox(
              width: double.infinity,
              height: context.spacing.buttonHeight,
              child: FilledButton(
                onPressed: () async {
                  // Check if user is authenticated
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;

                  if (user == null) {
                    // User not logged in - show login prompt
                    final shouldLogin = await _showLoginPrompt(context);
                    if (shouldLogin != true) return;

                    // Navigate to login
                    // TODO: Update with actual login route
                    if (!mounted) return;
                    Navigator.pushNamed(
                      context,
                      '/login',
                      arguments: {
                        'returnTo': '/property/${widget.propertyId}',
                      },
                    );
                    return;
                  }

                  // User is authenticated - proceed to booking flow
                  if (!mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/booking-flow',
                    arguments: {
                      'propertyId': widget.propertyId,
                      'unitId': unit.id,
                    },
                  );
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.spacing.borderRadius),
                  ),
                ),
                child: Text(
                  'Reserve',
                  style: context.typography.button,
                ),
              ),
            ),

            SizedBox(height: context.spacing.elementSpacing),

            // "You won't be charged yet" message
            Center(
              child: Text(
                'You won\'t be charged yet',
                style: context.typography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateSelection(DateTime date, CalendarDay dayData, String unitId) {
    // Check permissions with guest support
    final permissionsAsync = ref.read(
      calendarPermissionsProvider(widget.propertyId),
    );

    permissionsAsync.when(
      data: (permissions) {
        // Check if user can select this date (guests can select available dates)
        if (!permissions.canSelectDate(dayData)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getUnavailableReason(dayData.status)),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }

        // Date selection will be handled by the calendar widget
        // The booking flow provider will be updated automatically
      },
      loading: () {
        // While loading permissions, allow selection for available dates
        // (guest-friendly default behavior)
        if (dayData.status == DayStatus.available) {
          // Calendar widget will handle the selection
        }
      },
      error: (error, stack) {
        // On error, default to guest behavior: allow available dates only
        if (dayData.status == DayStatus.available) {
          // Calendar widget will handle the selection
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getUnavailableReason(dayData.status)),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
    );
  }

  String _getUnavailableReason(DayStatus status) {
    switch (status) {
      case DayStatus.booked:
        return 'This date is already booked';
      case DayStatus.blocked:
        return 'This date is blocked';
      case DayStatus.checkIn:
      case DayStatus.checkOut:
        return 'This date is part of an existing booking';
      default:
        return 'This date is not available';
    }
  }

  IconData _getAmenityIconFromEnum(PropertyAmenity amenity) {
    // TODO: Add icons for all amenity types
    return Icons.check_circle;
  }

  /// Show login prompt dialog for unauthenticated users
  Future<bool?> _showLoginPrompt(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Required',
          style: context.typography.subtitle,
        ),
        content: Text(
          'You need to be logged in to make a reservation. '
          'Would you like to login or create an account?',
          style: context.typography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: context.typography.button.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.spacing.borderRadius),
              ),
            ),
            child: Text(
              'Login / Sign Up',
              style: context.typography.button,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.spacing.responsive(mobile: 4, tablet: 6, desktop: 6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: context.typography.body.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: context.typography.body.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
