import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/booking_price_provider.dart';
import '../providers/theme_provider.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
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

  // Getter for colors based on current theme
  WidgetColorScheme get colors {
    final isDarkMode = ref.watch(themeProvider);
    return isDarkMode ? ColorTokens.dark : ColorTokens.light;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

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
      backgroundColor: colors.backgroundCard,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.backgroundCard,
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
            colors: colors,
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
                  return _buildMobileLayout(
                    colors,
                    room,
                    checkIn,
                    checkOut,
                    adults,
                    children,
                  );
                } else {
                  return _buildDesktopLayout(
                    colors,
                    room,
                    checkIn,
                    checkOut,
                    adults,
                    children,
                  );
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
    WidgetColorScheme colors,
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
                _buildProgressIndicator(colors, 1),
                const SizedBox(height: 32),

                // Booking details card
                _buildBookingDetailsCard(
                  colors,
                  room,
                  checkIn,
                  checkOut,
                  adults,
                  children,
                ),
                const SizedBox(height: 24),

                // Additional services
                _buildAdditionalServicesSection(colors),
                const SizedBox(height: 24),

                // Price summary (mobile)
                _buildPriceSummaryCard(colors, room.id, checkIn, checkOut),
              ],
            ),
          ),
        ),

        // Bottom buttons
        _buildBottomButtons(colors),
      ],
    );
  }

  // ===================================================================
  // DESKTOP LAYOUT
  // ===================================================================

  Widget _buildDesktopLayout(
    WidgetColorScheme colors,
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
                    _buildProgressIndicator(colors, 1),
                    const SizedBox(height: 32),

                    // Booking details card
                    _buildBookingDetailsCard(
                      colors,
                      room,
                      checkIn,
                      checkOut,
                      adults,
                      children,
                    ),
                    const SizedBox(height: 32),

                    // Additional services
                    _buildAdditionalServicesSection(colors),
                  ],
                ),
              ),
            ),

            // Sidebar (30%)
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: colors.backgroundPrimary,
                border: Border(left: BorderSide(color: colors.borderDefault)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildPriceSummaryCard(
                        colors,
                        room.id,
                        checkIn,
                        checkOut,
                      ),
                    ),
                  ),
                  _buildBottomButtons(colors),
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

  Widget _buildProgressIndicator(WidgetColorScheme colors, int currentStep) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildProgressDot(
            colors,
            1,
            'Room',
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
          ),
          _buildProgressLine(colors, isCompleted: currentStep > 1),
          _buildProgressDot(
            colors,
            2,
            'Details',
            isActive: currentStep == 2,
            isCompleted: currentStep > 2,
          ),
          _buildProgressLine(colors, isCompleted: currentStep > 2),
          _buildProgressDot(
            colors,
            3,
            'Payment',
            isActive: currentStep == 3,
            isCompleted: currentStep > 3,
          ),
          _buildProgressLine(colors, isCompleted: currentStep > 3),
          _buildProgressDot(
            colors,
            4,
            'Done',
            isActive: currentStep == 4,
            isCompleted: currentStep > 4,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(
    WidgetColorScheme colors,
    int step,
    String label, {
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? colors.primary
                : colors.borderDefault,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: colors.backgroundCard, size: 20)
                : Text(
                    step.toString(),
                    style: GoogleFonts.inter(
                      color: isActive
                          ? colors.backgroundCard
                          : colors.textSecondary,
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
            color: isActive ? colors.primary : colors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(
    WidgetColorScheme colors, {
    required bool isCompleted,
  }) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      color: isCompleted ? colors.primary : colors.borderDefault,
    );
  }

  Container _buildBookingDetailsCard(
    WidgetColorScheme colors,
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
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Booking Details',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
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
                        color: colors.borderDefault,
                        child: Icon(
                          Icons.hotel,
                          size: 40,
                          color: colors.textSecondary,
                        ),
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
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$adults adults${children > 0 ? ', $children children' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.king_bed,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${room.bedrooms} ${room.bedrooms == 1 ? 'bedroom' : 'bedrooms'}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
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
              Expanded(child: _buildDateInfoBox(colors, 'Check-in', checkIn)),
              const SizedBox(width: 16),
              Expanded(child: _buildDateInfoBox(colors, 'Check-out', checkOut)),
            ],
          ),

          const SizedBox(height: 16),

          // Duration
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nightlight_round, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  '$nights ${nights == 1 ? 'Night' : 'Nights'}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfoBox(
    WidgetColorScheme colors,
    String label,
    DateTime date,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(date),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          Text(
            DateFormat('EEEE').format(date),
            style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalServicesSection(colors) {
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
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enhance your stay with optional extras',
          style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
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
                  color: isSelected ? colors.primary : colors.borderDefault,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? colors.primarySurface
                    : colors.backgroundCard,
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
                        color: colors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        service['icon'] as IconData,
                        size: 24,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            service['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
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
                      color: colors.primary,
                    ),
                  ),
                ),
                activeColor: colors.primary,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceSummaryCard(
    WidgetColorScheme colors,
    String unitId,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    final priceCalc = ref.watch(
      bookingPriceProvider(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
      ),
    );

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
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).toInt()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Summary',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Divider(height: 24),

              _buildPriceRow(
                colors,
                '${calculation.nights} nights',
                calculation.formattedTotal,
              ),

              if (servicesTotal > 0) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  colors,
                  'Additional services',
                  '€${servicesTotal.toStringAsFixed(0)}',
                  isHighlighted: true,
                ),
              ],

              const Divider(height: 24),

              _buildPriceRow(
                colors,
                'Total',
                '€${grandTotal.toStringAsFixed(0)}',
                isBold: true,
              ),

              const SizedBox(height: 24),

              // Deposit breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primaryLight),
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
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '€${deposit.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
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
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '€${remaining.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
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
          style: GoogleFonts.inter(color: colors.error),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    WidgetColorScheme colors,
    String label,
    String amount, {
    bool isBold = false,
    bool isHighlighted = false,
  }) {
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
              color: isHighlighted ? colors.primary : colors.textPrimary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: isBold ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        border: Border(top: BorderSide(color: colors.borderDefault)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
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
                  backgroundColor: colors.primary,
                  foregroundColor: colors.backgroundCard,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue to Payment',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
