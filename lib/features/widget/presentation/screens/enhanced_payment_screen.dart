import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/stripe_service.dart';
import '../../../../core/services/booking_service.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/booking_price_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Enhanced Payment Screen (Step 2 of Flow B)
/// Guest Details + Payment Method Selection
class EnhancedPaymentScreen extends ConsumerStatefulWidget {
  const EnhancedPaymentScreen({super.key});

  @override
  ConsumerState<EnhancedPaymentScreen> createState() =>
      _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends ConsumerState<EnhancedPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Guest details
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  // Payment options
  String _paymentMethod = 'stripe'; // 'stripe' or 'bank_transfer'
  String _paymentOption = 'deposit'; // 'deposit' (20%) or 'full' (100%)

  bool _agreedToTerms = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(selectedRoomProvider);
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);

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
            ref.read(bookingStepProvider.notifier).state = 1;
          },
        ),
        title: const Text(
          'Guest Details & Payment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout(room.id, checkIn, checkOut);
          } else {
            return _buildDesktopLayout(room.id, checkIn, checkOut);
          }
        },
      ),
    );
  }

  // ===================================================================
  // MOBILE LAYOUT
  // ===================================================================

  Widget _buildMobileLayout(
      String unitId, DateTime checkIn, DateTime checkOut) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(2),
                  const SizedBox(height: 32),

                  // Guest details section
                  _buildGuestDetailsSection(),
                  const SizedBox(height: 32),

                  // Payment method section
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 32),

                  // Payment option section
                  _buildPaymentOptionSection(unitId, checkIn, checkOut),
                  const SizedBox(height: 32),

                  // Terms and conditions
                  _buildTermsCheckbox(),
                  const SizedBox(height: 24),

                  // Price summary
                  _buildCompactPriceSummary(unitId, checkIn, checkOut),
                ],
              ),
            ),
          ),
        ),

        // Bottom button
        _buildBottomButton(unitId, checkIn, checkOut),
      ],
    );
  }

  // ===================================================================
  // DESKTOP LAYOUT
  // ===================================================================

  Widget _buildDesktopLayout(
      String unitId, DateTime checkIn, DateTime checkOut) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content (65%)
        Expanded(
          flex: 65,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(2),
                  const SizedBox(height: 32),

                  // Guest details section
                  _buildGuestDetailsSection(),
                  const SizedBox(height: 32),

                  // Payment method section
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 32),

                  // Payment option section
                  _buildPaymentOptionSection(unitId, checkIn, checkOut),
                  const SizedBox(height: 32),

                  // Terms and conditions
                  _buildTermsCheckbox(),
                ],
              ),
            ),
          ),
        ),

        // Sidebar (35%)
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
                  child: _buildDetailedPriceSummary(unitId, checkIn, checkOut),
                ),
              ),
              _buildBottomButton(unitId, checkIn, checkOut),
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
        _buildProgressDot(1, 'Room',
            isActive: false, isCompleted: currentStep > 1),
        _buildProgressLine(isCompleted: currentStep > 1),
        _buildProgressDot(2, 'Details',
            isActive: currentStep == 2, isCompleted: currentStep > 2),
        _buildProgressLine(isCompleted: currentStep > 2),
        _buildProgressDot(3, 'Payment',
            isActive: currentStep == 3, isCompleted: currentStep > 3),
        _buildProgressLine(isCompleted: currentStep > 3),
        _buildProgressDot(4, 'Done',
            isActive: currentStep == 4, isCompleted: currentStep > 4),
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
            color:
                isActive ? BedBookingColors.primaryGreen : Colors.grey.shade600,
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
        color:
            isCompleted ? BedBookingColors.primaryGreen : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildGuestDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BedBookingCards.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BedBookingColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: BedBookingColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Guest Information',
                style: BedBookingTextStyles.heading2,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // First Name & Last Name
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Phone
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Special Requests
          _buildTextField(
            controller: _specialRequestsController,
            label: 'Special Requests (Optional)',
            icon: Icons.notes,
            maxLines: 3,
            validator: null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: BedBookingColors.primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: BedBookingColors.primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BedBookingColors.error),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BedBookingCards.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BedBookingColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment,
                  color: BedBookingColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Method',
                style: BedBookingTextStyles.heading2,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stripe option
          _buildPaymentMethodCard(
            method: 'stripe',
            title: 'Credit/Debit Card',
            subtitle: 'Pay securely with Stripe',
            icon: Icons.credit_card,
            badges: ['Instant Confirmation', 'Secure'],
          ),

          const SizedBox(height: 12),

          // Bank Transfer option
          _buildPaymentMethodCard(
            method: 'bank_transfer',
            title: 'Bank Transfer',
            subtitle: 'Pay via bank transfer',
            icon: Icons.account_balance,
            badges: ['Manual Approval Required'],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> badges,
  }) {
    final isSelected = _paymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? BedBookingColors.primaryGreen.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BedBookingColors.primaryGreen
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? BedBookingColors.primaryGreen
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: BedBookingColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? BedBookingColors.primaryGreen.withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? BedBookingColors.primaryGreen
                    : Colors.grey.shade600,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black87 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: badges
                        .map((badge) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BedBookingColors.primaryGreen
                                        .withOpacity(0.1)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? BedBookingColors.primaryGreen
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionSection(
      String unitId, DateTime checkIn, DateTime checkOut) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

    return priceCalc.when(
      data: (calculation) {
        if (calculation == null) return const SizedBox.shrink();

        final deposit = calculation.totalPrice * 0.2;
        final fullAmount = calculation.totalPrice;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BedBookingCards.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BedBookingColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.euro,
                      color: BedBookingColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Amount',
                    style: BedBookingTextStyles.heading2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Deposit option (20%)
              _buildPaymentOptionCard(
                option: 'deposit',
                title: 'Pay 20% Now',
                subtitle: 'Secure your booking with a deposit',
                amount: deposit,
                remaining: fullAmount - deposit,
                recommended: true,
              ),

              const SizedBox(height: 12),

              // Full payment option (100%)
              _buildPaymentOptionCard(
                option: 'full',
                title: 'Pay Full Amount',
                subtitle: 'Complete payment now',
                amount: fullAmount,
                remaining: 0,
                recommended: false,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildPaymentOptionCard({
    required String option,
    required String title,
    required String subtitle,
    required double amount,
    required double remaining,
    required bool recommended,
  }) {
    final isSelected = _paymentOption == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentOption = option;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? BedBookingColors.primaryGreen.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BedBookingColors.primaryGreen
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? BedBookingColors.primaryGreen
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: BedBookingColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black87 : Colors.black54,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BedBookingColors.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? BedBookingColors.primaryGreen
                        : Colors.black87,
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+€${remaining.toStringAsFixed(0)} on arrival',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: _agreedToTerms,
      onChanged: (value) {
        setState(() {
          _agreedToTerms = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: BedBookingColors.primaryGreen,
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            const TextSpan(text: 'I agree to the '),
            TextSpan(
              text: 'Terms & Conditions',
              style: TextStyle(
                color: BedBookingColors.primaryGreen,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: BedBookingColors.primaryGreen,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPriceSummary(
      String unitId, DateTime checkIn, DateTime checkOut) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

    return priceCalc.when(
      data: (calculation) {
        if (calculation == null) return const SizedBox.shrink();

        final amount = _paymentOption == 'deposit'
            ? calculation.totalPrice * 0.2
            : calculation.totalPrice;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BedBookingColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BedBookingColors.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount to Pay',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _paymentOption == 'deposit'
                        ? '20% Deposit'
                        : 'Full Payment',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '€${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: BedBookingColors.primaryGreen,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildDetailedPriceSummary(
      String unitId, DateTime checkIn, DateTime checkOut) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

    return priceCalc.when(
      data: (calculation) {
        if (calculation == null) return const SizedBox.shrink();

        final deposit = calculation.totalPrice * 0.2;
        final amountToPay = _paymentOption == 'deposit'
            ? deposit
            : calculation.totalPrice;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BedBookingCards.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Summary',
                style: BedBookingTextStyles.heading3,
              ),
              const Divider(height: 24),

              _buildSummaryRow(
                '${calculation.nights} nights',
                calculation.formattedTotal,
              ),

              const Divider(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BedBookingColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _paymentOption == 'deposit'
                              ? 'Pay Now (20%)'
                              : 'Pay Now (100%)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '€${amountToPay.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BedBookingColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    if (_paymentOption == 'deposit') ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pay on Arrival',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '€${(calculation.totalPrice - deposit).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BedBookingTextStyles.body),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
      String unitId, DateTime checkIn, DateTime checkOut) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

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
                onPressed: _isProcessing
                    ? null
                    : () {
                        ref.read(bookingStepProvider.notifier).state = 1;
                      },
                style: BedBookingButtons.secondaryButton,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: priceCalc.when(
                data: (calculation) {
                  if (calculation == null) {
                    return const SizedBox.shrink();
                  }

                  final amount = _paymentOption == 'deposit'
                      ? calculation.totalPrice * 0.2
                      : calculation.totalPrice;

                  return ElevatedButton(
                    onPressed: _isProcessing || !_agreedToTerms
                        ? null
                        : () => _handlePayment(amount),
                    style: BedBookingButtons.primaryButton,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _paymentMethod == 'stripe'
                                ? 'Pay €${amount.toStringAsFixed(0)}'
                                : 'Confirm Booking',
                            style: const TextStyle(fontSize: 16),
                          ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // PAYMENT HANDLING
  // ===================================================================

  Future<void> _handlePayment(double amount) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: BedBookingColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_paymentMethod == 'stripe') {
        // TODO: Implement Stripe Checkout
        await _handleStripePayment(amount);
      } else {
        // Bank Transfer
        await _handleBankTransferBooking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: BedBookingColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleStripePayment(double amount) async {
    try {
      // Get booking data
      final room = ref.read(selectedRoomProvider);
      final checkIn = ref.read(checkInDateProvider);
      final checkOut = ref.read(checkOutDateProvider);
      final adults = ref.read(adultsCountProvider);
      final children = ref.read(childrenCountProvider);

      if (room == null || checkIn == null || checkOut == null) {
        throw Exception('Missing booking data');
      }

      // Calculate total
      final priceCalc = await ref.read(bookingPriceProvider(
        unitId: room.id,
        checkIn: checkIn,
        checkOut: checkOut,
      ).future);

      if (priceCalc == null) throw Exception('Price calculation failed');

      final totalPrice = priceCalc.totalPrice;

      // Step 1: Create booking
      debugPrint('🔵 Creating booking...');
      final bookingService = BookingService();
      final booking = await bookingService.createBooking(
        unitId: room.id,
        propertyId: room.propertyId,
        ownerId: room.propertyId,
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: '${_firstNameController.text} ${_lastNameController.text}',
        guestEmail: _emailController.text,
        guestPhone: _phoneController.text,
        guestCount: adults + children,
        totalPrice: totalPrice,
        paymentOption: _paymentOption,
        paymentMethod: 'stripe',
        notes: _specialRequestsController.text.isNotEmpty ? _specialRequestsController.text : null,
      );

      debugPrint('✅ Booking created: ${booking.id}');

      // Step 2: Create Stripe session
      debugPrint('🔵 Creating Stripe session...');
      final stripeService = StripeService();
      final checkoutResult = await stripeService.createCheckoutSession(
        bookingId: booking.id,
        returnUrl: 'https://rab-booking-248fc.web.app/booking',
      );

      debugPrint('✅ Session created: ${checkoutResult.sessionId}');

      // Step 3: Redirect to Stripe
      final url = Uri.parse(checkoutResult.checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) ref.read(bookingStepProvider.notifier).state = 3;
      } else {
        throw Exception('Could not launch Stripe URL');
      }
    } catch (e) {
      debugPrint('❌ Stripe error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: BedBookingColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _handleBankTransferBooking() async {
    try {
      final room = ref.read(selectedRoomProvider);
      final checkIn = ref.read(checkInDateProvider);
      final checkOut = ref.read(checkOutDateProvider);
      final adults = ref.read(adultsCountProvider);
      final children = ref.read(childrenCountProvider);

      if (room == null || checkIn == null || checkOut == null) {
        throw Exception('Missing booking data');
      }

      final priceCalc = await ref.read(bookingPriceProvider(
        unitId: room.id,
        checkIn: checkIn,
        checkOut: checkOut,
      ).future);

      if (priceCalc == null) throw Exception('Price calculation failed');

      debugPrint('🔵 Creating bank transfer booking...');
      final bookingService = BookingService();
      final booking = await bookingService.createBooking(
        unitId: room.id,
        propertyId: room.propertyId,
        ownerId: room.propertyId,
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: '${_firstNameController.text} ${_lastNameController.text}',
        guestEmail: _emailController.text,
        guestPhone: _phoneController.text,
        guestCount: adults + children,
        totalPrice: priceCalc.totalPrice,
        paymentOption: _paymentOption,
        paymentMethod: 'bank_transfer',
        notes: _specialRequestsController.text.isNotEmpty ? _specialRequestsController.text : null,
      );

      debugPrint('✅ Bank transfer booking created: ${booking.id}');

      // Navigate to confirmation
      if (mounted) {
        ref.read(bookingStepProvider.notifier).state = 3;
      }
    } catch (e) {
      debugPrint('❌ Bank transfer error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking error: $e'),
            backgroundColor: BedBookingColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    }
  }
}
