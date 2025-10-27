import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/year_grid_calendar_widget.dart';
import '../widgets/booking_summary_sidebar.dart';
import '../widgets/bank_transfer_instructions_widget.dart';
import '../widgets/guest_details_form.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/powered_by_badge.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../../domain/models/booking_request.dart';
import '../../domain/models/payment_option.dart';
import '../../domain/models/widget_config.dart';

/// Main booking widget screen with 3-step process
/// Integrates with existing website via iframe
class BookingWidgetMainScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String? propertyName;
  final WidgetConfig? config;

  const BookingWidgetMainScreen({
    super.key,
    required this.unitId,
    this.propertyName,
    this.config,
  });

  @override
  ConsumerState<BookingWidgetMainScreen> createState() =>
      _BookingWidgetMainScreenState();
}

class _BookingWidgetMainScreenState
    extends ConsumerState<BookingWidgetMainScreen> {
  int _currentStep = 1; // 1: Calendar, 2: Details, 3: Confirmation
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.bankTransfer;
  String? _bookingReference;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),

          // Main content
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E23), // Olive green like BedBooking
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepItem(1, 'THE OFFER', isActive: _currentStep == 1),
          const SizedBox(width: 16),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 16),
          _buildStepItem(2, 'DETAILS AND PAYMENT',
              isActive: _currentStep == 2),
          const SizedBox(width: 16),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 16),
          _buildStepItem(3, 'CONFIRMATION', isActive: _currentStep == 3),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, {required bool isActive}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF6B8E23)
                    : Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Calendar();
      case 2:
        return _buildStep2DetailsAndPayment();
      case 3:
        return _buildStep3Confirmation();
      default:
        return const SizedBox();
    }
  }

  /// Step 1: Calendar selection with date picker
  Widget _buildStep1Calendar() {
    return Row(
      children: [
        // Calendar
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Check-in',
                          date: _checkIn,
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.arrow_forward),
                      ),
                      Expanded(
                        child: _buildDateField(
                          label: 'Check-out',
                          date: _checkOut,
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildGuestSelector(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Year calendar
                SizedBox(
                  height: 600,
                  child: YearGridCalendarWidget(
                    unitId: widget.unitId,
                    onRangeSelected: (start, end) {
                      setState(() {
                        _checkIn = start;
                        _checkOut = end;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sidebar summary
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: _buildSidebarSummary(),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$_adults ${_adults == 1 ? 'adult' : 'adults'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSummary() {
    final canProceed = _checkIn != null && _checkOut != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.propertyName ?? 'Room',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (_checkIn != null && _checkOut != null) ...[
                  _buildSummaryRow('Check-in', '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}'),
                  _buildSummaryRow('Check-out', '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}'),
                  const Divider(height: 24),
                  _buildSummaryRow('Guests', '$_adults adults'),
                  const Divider(height: 24),

                  // Price calculation
                  const Text(
                    'Price breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // TODO: Fetch actual prices and calculate
                  _buildSummaryRow('Number of nights', '3'),
                  _buildSummaryRow('Price per night', '€120.00'),
                  const Divider(height: 24),
                  _buildSummaryRow('Total', '€360.00', isBold: true),
                ],
              ],
            ),
          ),
        ),

        // Reserve button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canProceed ? _goToStep2 : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8E23),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: Guest details and payment method
  Widget _buildStep2DetailsAndPayment() {
    return Row(
      children: [
        // Form section
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Guest details form
                GuestDetailsForm(
                  onChanged: (details) {
                    // Handle form changes
                  },
                ),

                const SizedBox(height: 32),

                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment method selector
                BankTransferOptionCard(
                  isSelected: _selectedPaymentMethod == PaymentMethod.bankTransfer,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = PaymentMethod.bankTransfer;
                    });
                  },
                  depositAmount: 72.0, // 20% of 360
                ),

                const SizedBox(height: 32),

                // Navigation buttons
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B8E23),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Sidebar summary
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: _buildSidebarSummary(),
        ),
      ],
    );
  }

  /// Step 3: Booking confirmation with bank transfer instructions
  Widget _buildStep3Confirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade600,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Rezervacija kreirana!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Vaša rezervacija je u statusu "Na čekanju" dok ne izvršite uplatu avansa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 32),

              // Bank transfer instructions
              BankTransferInstructionsWidget(
                depositAmount: 72.0, // 20% of total
                bookingReference: _bookingReference ?? 'BK123456789',
                propertyName: widget.propertyName,
              ),

              const SizedBox(height: 40),

              // Powered by BedBooking badge
              PoweredByBedBookingBadge(
                show: widget.config?.showPoweredByBadge ?? true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToStep2() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _confirmBooking() async {
    // TODO: Call Firebase Cloud Function to create booking
    // For now, simulate success
    setState(() {
      _bookingReference = 'BK${DateTime.now().millisecondsSinceEpoch}';
      _currentStep = 3;
    });
  }
}
