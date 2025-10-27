import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/booking_price_provider.dart';
import '../theme/bedbooking_theme.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: BedBookingColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(bookingStepProvider.notifier).state = 0;
          },
        ),
        title: const Text(
          'Booking Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout(room, checkIn, checkOut, adults, children);
          } else {
            return _buildDesktopLayout(
                room, checkIn, checkOut, adults, children);
          }
        },
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
    return Row(
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
          decoration: BoxDecoration(
            color: BedBookingColors.backgroundGrey,
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
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
    );
  }

  // ===================================================================
  // SHARED COMPONENTS
  // ===================================================================

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: [
        _buildProgressDot(1, 'Room', isActive: currentStep == 1, isCompleted: currentStep > 1),
        _buildProgressLine(isCompleted: currentStep > 1),
        _buildProgressDot(2, 'Details', isActive: currentStep == 2, isCompleted: currentStep > 2),
        _buildProgressLine(isCompleted: currentStep > 2),
        _buildProgressDot(3, 'Payment', isActive: currentStep == 3, isCompleted: currentStep > 3),
        _buildProgressLine(isCompleted: currentStep > 3),
        _buildProgressDot(4, 'Done', isActive: currentStep == 4, isCompleted: currentStep > 4),
      ],
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
                ? BedBookingColors.primaryGreen
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? BedBookingColors.primaryGreen
                : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted
            ? BedBookingColors.primaryGreen
            : Colors.grey.shade300,
      ),
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
      decoration: BedBookingCards.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Booking Details',
            style: BedBookingTextStyles.heading2,
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
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, size: 40),
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
                      style: BedBookingTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$adults adults' +
                              (children > 0 ? ', $children children' : ''),
                          style: BedBookingTextStyles.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.king_bed,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.bedrooms} ${room.bedrooms == 1 ? 'bedroom' : 'bedrooms'}',
                          style: BedBookingTextStyles.small,
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
              color: BedBookingColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.nightlight_round,
                  size: 20,
                  color: BedBookingColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  '$nights ${nights == 1 ? 'Night' : 'Nights'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BedBookingColors.primaryGreen,
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
        color: BedBookingColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: BedBookingTextStyles.small,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy').format(date),
            style: BedBookingTextStyles.bodyBold,
          ),
          Text(
            DateFormat('EEEE').format(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
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
        const Text(
          'Additional Services',
          style: BedBookingTextStyles.heading2,
        ),
        const SizedBox(height: 4),
        Text(
          'Enhance your stay with optional extras',
          style: BedBookingTextStyles.small,
        ),
        const SizedBox(height: 16),

        ...services.map((service) {
          final isSelected =
              _selectedServices[service['id'] as String] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? BedBookingColors.primaryGreen
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? BedBookingColors.primaryGreen.withOpacity(0.05)
                  : Colors.white,
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
                      color: BedBookingColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      size: 24,
                      color: BedBookingColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'] as String,
                          style: BedBookingTextStyles.bodyBold,
                        ),
                        Text(
                          service['description'] as String,
                          style: BedBookingTextStyles.small,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BedBookingColors.primaryGreen,
                  ),
                ),
              ),
              activeColor: BedBookingColors.primaryGreen,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }),
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
          decoration: BedBookingCards.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Summary',
                style: BedBookingTextStyles.heading3,
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
                  color: BedBookingColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BedBookingColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Deposit (20%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '€${deposit.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BedBookingColors.primaryGreen,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '€${remaining.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
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
          style: TextStyle(color: Colors.red.shade700),
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
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted
                  ? BedBookingColors.primaryGreen
                  : Colors.black87,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? BedBookingColors.primaryGreen
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                style: BedBookingButtons.secondaryButton,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(bookingStepProvider.notifier).state = 2;
                },
                style: BedBookingButtons.primaryButton,
                child: const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
