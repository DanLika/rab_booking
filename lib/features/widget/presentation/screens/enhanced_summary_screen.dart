import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/booking_price_provider.dart';
import '../theme/villa_jasko_colors.dart';
import '../theme/responsive_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/progress_indicator_widget.dart';

/// Enhanced Summary & Additional Services Screen (Step 1 of Flow B)
class EnhancedSummaryScreen extends ConsumerStatefulWidget {
  const EnhancedSummaryScreen({super.key});

  @override
  ConsumerState<EnhancedSummaryScreen> createState() =>
      _EnhancedSummaryScreenState();
}

class _EnhancedSummaryScreenState extends ConsumerState<EnhancedSummaryScreen> {
  // Additional services selection
  final Map<String, bool> _selectedServices = {};

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(selectedRoomProvider);
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);
    final adults = ref.watch(adultsCountProvider);
    final children = ref.watch(childrenCountProvider);

    // Redirect if required data is missing
    if (room == null || checkIn == null || checkOut == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookingStepProvider.notifier).state = 0;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: VillaJaskoColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: VillaJaskoColors.primary,
        foregroundColor: VillaJaskoColors.textOnPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(bookingStepProvider.notifier).state = 0;
          },
        ),
        title: Text(
          'Booking Summary',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          BookingProgressIndicator(
            currentStep: 2,
            onStepTapped: (step) {
              if (step == 1) {
                context.go('/rooms');
              }
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);

                if (isMobile) {
                  return _buildMobileLayout(room, checkIn, checkOut, adults, children);
                } else {
                  return _buildDesktopLayout(
                      room, checkIn, checkOut, adults, children);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // MOBILE LAYOUT
  // ===================================================================

  Widget _buildMobileLayout(
    dynamic room,
    DateTime checkIn,
    DateTime checkOut,
    int adults,
    int children,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressIndicator(1),
                const SizedBox(height: 32),

                // Booking details card
                _buildBookingDetailsCard(room, checkIn, checkOut, adults, children),
                const SizedBox(height: 24),

                // Additional services
                _buildAdditionalServicesSection(),
                const SizedBox(height: 24),

                // Price summary (mobile)
                _buildPriceSummaryCard(room.id, checkIn, checkOut),
              ],
            ),
          ),
        ),

        // Bottom buttons
        _buildBottomButtons(),
      ],
    );
  }

  // ===================================================================
  // DESKTOP LAYOUT
  // ===================================================================

  Widget _buildDesktopLayout(
    dynamic room,
    DateTime checkIn,
    DateTime checkOut,
    int adults,
    int children,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Main content (70%)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressIndicator(1),
                const SizedBox(height: 32),

                // Booking details card
                _buildBookingDetailsCard(
                    room, checkIn, checkOut, adults, children),
                const SizedBox(height: 32),

                // Additional services
                _buildAdditionalServicesSection(),
              ],
            ),
          ),
        ),

        // Sidebar (30%)
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: VillaJaskoColors.backgroundSidebar,
            border: Border(
              left: BorderSide(color: VillaJaskoColors.border),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildPriceSummaryCard(room.id, checkIn, checkOut),
                ),
              ),
              _buildBottomButtons(),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // SHARED COMPONENTS
  // ===================================================================

  Widget _buildProgressIndicator(int currentStep) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildProgressDot(1, 'Room', isActive: currentStep == 1, isCompleted: currentStep > 1),
          _buildProgressLine(isCompleted: currentStep > 1),
          _buildProgressDot(2, 'Details', isActive: currentStep == 2, isCompleted: currentStep > 2),
          _buildProgressLine(isCompleted: currentStep > 2),
          _buildProgressDot(3, 'Payment', isActive: currentStep == 3, isCompleted: currentStep > 3),
          _buildProgressLine(isCompleted: currentStep > 3),
          _buildProgressDot(4, 'Done', isActive: currentStep == 4, isCompleted: currentStep > 4),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int step, String label,
      {required bool isActive, required bool isCompleted}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? VillaJaskoColors.primary
                : VillaJaskoColors.dayDisabled,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: VillaJaskoColors.textOnPrimary, size: 20)
                : Text(
                    step.toString(),
                    style: GoogleFonts.inter(
                      color: isActive ? VillaJaskoColors.textOnPrimary : VillaJaskoColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isActive
                ? VillaJaskoColors.primary
                : VillaJaskoColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required bool isCompleted}) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: isCompleted
          ? VillaJaskoColors.primary
          : VillaJaskoColors.border,
    );
  }

  Widget _buildBookingDetailsCard(
    dynamic room,
    DateTime checkIn,
    DateTime checkOut,
    int adults,
    int children,
  ) {
    final nights = checkOut.difference(checkIn).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VillaJaskoColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VillaJaskoColors.border),
        boxShadow: const [
          BoxShadow(
            color: VillaJaskoColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Booking Details',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: VillaJaskoColors.textPrimary),
          ),
          const Divider(height: 24),

          // Room info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (room.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    room.images.first,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 90,
                        color: VillaJaskoColors.dayDisabled,
                        child: const Icon(Icons.hotel, size: 40, color: VillaJaskoColors.textSecondary),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: VillaJaskoColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 16,
                          color: VillaJaskoColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$adults adults${children > 0 ? ', $children children' : ''}',
                            style: GoogleFonts.inter(fontSize: 14, color: VillaJaskoColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.king_bed,
                          size: 16,
                          color: VillaJaskoColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${room.bedrooms} ${room.bedrooms == 1 ? 'bedroom' : 'bedrooms'}',
                            style: GoogleFonts.inter(fontSize: 14, color: VillaJaskoColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Dates
          Row(
            children: [
              Expanded(
                child: _buildDateInfoBox('Check-in', checkIn),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateInfoBox('Check-out', checkOut),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duration
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VillaJaskoColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.nightlight_round,
                  size: 20,
                  color: VillaJaskoColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$nights ${nights == 1 ? 'Night' : 'Nights'}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: VillaJaskoColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfoBox(String label, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VillaJaskoColors.backgroundSidebar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: VillaJaskoColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(date),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: VillaJaskoColors.textPrimary),
          ),
          Text(
            DateFormat('EEEE').format(date),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: VillaJaskoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalServicesSection() {
    // Demo additional services
    final services = [
      {
        'id': 'breakfast',
        'name': 'Breakfast',
        'description': 'Continental breakfast for all guests',
        'price': 15.0,
        'icon': Icons.free_breakfast,
      },
      {
        'id': 'parking',
        'name': 'Parking',
        'description': 'Secure parking space',
        'price': 10.0,
        'icon': Icons.local_parking,
      },
      {
        'id': 'transfer',
        'name': 'Airport Transfer',
        'description': 'Pick-up and drop-off service',
        'price': 40.0,
        'icon': Icons.local_taxi,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Services',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: VillaJaskoColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Enhance your stay with optional extras',
          style: GoogleFonts.inter(fontSize: 14, color: VillaJaskoColors.textSecondary),
        ),
        const SizedBox(height: 16),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected =
                _selectedServices[service['id'] as String] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? VillaJaskoColors.primary
                      : VillaJaskoColors.border,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? VillaJaskoColors.primarySurface
                    : VillaJaskoColors.backgroundSurface,
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedServices[service['id'] as String] = value ?? false;
                  });
                },
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VillaJaskoColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        service['icon'] as IconData,
                        size: 24,
                        color: VillaJaskoColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] as String,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: VillaJaskoColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            service['description'] as String,
                            style: GoogleFonts.inter(fontSize: 14, color: VillaJaskoColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 56, top: 4),
                  child: Text(
                    '+€${(service['price'] as double).toStringAsFixed(0)} per night',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VillaJaskoColors.primary,
                    ),
                  ),
                ),
                activeColor: VillaJaskoColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceSummaryCard(
      String unitId, DateTime checkIn, DateTime checkOut) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

    return priceCalc.when(
      data: (calculation) {
        if (calculation == null) {
          return const Center(child: Text('Error loading price'));
        }

        // Calculate additional services total
        double servicesTotal = 0;
        _selectedServices.forEach((key, value) {
          if (value) {
            if (key == 'breakfast') servicesTotal += 15.0 * calculation.nights;
            if (key == 'parking') servicesTotal += 10.0 * calculation.nights;
            if (key == 'transfer') servicesTotal += 40.0;
          }
        });

        final grandTotal = calculation.totalPrice + servicesTotal;
        final deposit = grandTotal * 0.2;
        final remaining = grandTotal - deposit;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VillaJaskoColors.backgroundSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VillaJaskoColors.border),
            boxShadow: const [
              BoxShadow(
                color: VillaJaskoColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Summary',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: VillaJaskoColors.textPrimary),
              ),
              const Divider(height: 24),

              _buildPriceRow(
                '${calculation.nights} nights',
                calculation.formattedTotal,
              ),

              if (servicesTotal > 0) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Additional services',
                  '€${servicesTotal.toStringAsFixed(0)}',
                  isHighlighted: true,
                ),
              ],

              const Divider(height: 24),

              _buildPriceRow(
                'Total',
                '€${grandTotal.toStringAsFixed(0)}',
                isBold: true,
              ),

              const SizedBox(height: 24),

              // Deposit breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VillaJaskoColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: VillaJaskoColors.primaryLight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deposit (20%)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: VillaJaskoColors.textPrimary,
                          ),
                        ),
                        Text(
                          '€${deposit.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VillaJaskoColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pay on arrival',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: VillaJaskoColors.textSecondary,
                          ),
                        ),
                        Text(
                          '€${remaining.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: VillaJaskoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading price',
          style: GoogleFonts.inter(color: VillaJaskoColors.error),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {bool isBold = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted
                  ? VillaJaskoColors.primary
                  : VillaJaskoColors.textPrimary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: isBold ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? VillaJaskoColors.primary
                  : VillaJaskoColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: VillaJaskoColors.backgroundSurface,
        border: Border(
          top: BorderSide(color: VillaJaskoColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: VillaJaskoColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingStepProvider.notifier).state = 0;
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: VillaJaskoColors.primary,
                  side: const BorderSide(color: VillaJaskoColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(bookingStepProvider.notifier).state = 2;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VillaJaskoColors.primary,
                  foregroundColor: VillaJaskoColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Continue to Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
