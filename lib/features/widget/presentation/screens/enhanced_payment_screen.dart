import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/services/logging_service.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/theme_provider.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../providers/booking_price_provider.dart';
import '../theme/responsive_helper.dart';
import '../widgets/progress_indicator_widget.dart';
import '../components/adaptive_glass_card.dart';

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

  // Getter for colors based on current theme
  WidgetColorScheme get colors {
    final isDarkMode = ref.watch(themeProvider);
    return isDarkMode ? ColorTokens.dark : ColorTokens.light;
  }

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
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AdaptiveBlurredAppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(bookingStepProvider.notifier).state = 1;
          },
        ),
        title: Text(
          'Guest Details & Payment',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          BookingProgressIndicator(
            colors: colors,
            currentStep: 3,
            onStepTapped: (step) {
              if (step == 1) context.go('/rooms');
              if (step == 2) context.go('/summary');
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveHelper.isMobile(context);

                if (isMobile) {
                  return _buildMobileLayout(room.id, checkIn, checkOut);
                } else {
                  return _buildDesktopLayout(room.id, checkIn, checkOut);
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
    String unitId,
    DateTime checkIn,
    DateTime checkOut,
  ) {
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
    String unitId,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
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

            // Sidebar (responsive width)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 300, maxWidth: 450),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.35,
                decoration: BoxDecoration(
                  color: colors.backgroundPrimary,
                  border: Border(left: BorderSide(color: colors.borderDefault)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildDetailedPriceSummary(
                          unitId,
                          checkIn,
                          checkOut,
                        ),
                      ),
                    ),
                    _buildBottomButton(unitId, checkIn, checkOut),
                  ],
                ),
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

  Widget _buildGuestDetailsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Guest Information',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge!.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // First Name & Last Name
          Row(
            children: [
              Flexible(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
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
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
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
                return 'Phone number is required';
              }
              final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
              if (!phoneRegex.hasMatch(value) ||
                  value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '').length < 8) {
                return 'Please enter a valid phone number';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.payment, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
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
          color: isSelected ? colors.primarySurface : colors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderDefault,
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
                  color: isSelected ? colors.primary : colors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.primary,
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
                    ? colors.primaryLight
                    : colors.backgroundPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.primary : colors.textSecondary,
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
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: badges
                        .map(
                          (badge) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primarySurface
                                  : colors.backgroundPrimary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        )
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
        if (calculation == null) return const SizedBox.shrink();

        final deposit = calculation.totalPrice * 0.2;
        final fullAmount = calculation.totalPrice;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AdaptiveGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.euro,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Payment Amount',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge!.color,
                    ),
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
          color: isSelected ? colors.primarySurface : colors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderDefault,
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
                  color: isSelected ? colors.primary : colors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.primary,
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
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colors.textPrimary
                              : colors.textSecondary,
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
                            color: colors.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colors.backgroundCard,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
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
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
                if (remaining > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+€${remaining.toStringAsFixed(0)} on arrival',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.textSecondary,
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
      activeColor: colors.primary,
      title: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),
          children: [
            const TextSpan(text: 'I agree to the '),
            TextSpan(
              text: 'Terms & Conditions',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Open Terms & Conditions
                  launchUrl(
                    Uri.parse('https://jasko-rab.com/terms'),
                    mode: LaunchMode.externalApplication,
                  );
                },
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Open Privacy Policy
                  launchUrl(
                    Uri.parse('https://jasko-rab.com/privacy'),
                    mode: LaunchMode.externalApplication,
                  );
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPriceSummary(
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
        if (calculation == null) return const SizedBox.shrink();

        final amount = _paymentOption == 'deposit'
            ? calculation.totalPrice * 0.2
            : calculation.totalPrice;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primaryLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount to Pay',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _paymentOption == 'deposit'
                        ? '20% Deposit'
                        : 'Full Payment',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '€${amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
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
        if (calculation == null) return const SizedBox.shrink();

        final deposit = calculation.totalPrice * 0.2;
        final amountToPay = _paymentOption == 'deposit'
            ? deposit
            : calculation.totalPrice;

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
                'Booking Summary',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Divider(height: 24, color: colors.borderDefault),

              _buildSummaryRow(
                '${calculation.nights} nights',
                calculation.formattedTotal,
              ),

              Divider(height: 24, color: colors.borderDefault),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primarySurface,
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
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '€${amountToPay.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            '€${(calculation.totalPrice - deposit).toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
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
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
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
                onPressed: _isProcessing
                    ? null
                    : () {
                        ref.read(bookingStepProvider.notifier).state = 1;
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.backgroundCard,
                      disabledBackgroundColor: colors.borderDefault,
                      disabledForegroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.backgroundCard,
                              ),
                            ),
                          )
                        : Text(
                            _paymentMethod == 'stripe'
                                ? 'Pay €${amount.toStringAsFixed(0)}'
                                : 'Confirm Booking',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_paymentMethod == 'stripe') {
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
            backgroundColor: Theme.of(context).colorScheme.error,
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

      // ✅ FIX: Fetch property to get actual owner ID
      LoggingService.logOperation('Fetching property details...');
      final propertyRepo = ref.read(propertyRepositoryProvider);
      final property = await propertyRepo.fetchPropertyById(room.propertyId);

      if (property == null) {
        throw Exception('Property not found');
      }

      final ownerId = property.ownerId;
      LoggingService.logSuccess('Owner ID: $ownerId');

      // Calculate total
      final priceCalc = await ref.read(
        bookingPriceProvider(
          unitId: room.id,
          checkIn: checkIn,
          checkOut: checkOut,
        ).future,
      );

      if (priceCalc == null) throw Exception('Price calculation failed');

      final totalPrice = priceCalc.totalPrice;

      // Step 1: Create booking
      LoggingService.logOperation('Creating booking...');
      final bookingService = ref.read(bookingServiceProvider);
      final booking = await bookingService.createBooking(
        unitId: room.id,
        propertyId: room.propertyId,
        ownerId: ownerId,
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: '${_firstNameController.text} ${_lastNameController.text}',
        guestEmail: _emailController.text,
        guestPhone: _phoneController.text,
        guestCount: adults + children,
        totalPrice: totalPrice,
        paymentOption: _paymentOption,
        paymentMethod: 'stripe',
        notes: _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
      );

      LoggingService.logSuccess('Booking created: ${booking.id}');

      // Step 2: Create Stripe session
      LoggingService.logOperation('Creating Stripe session...');
      final stripeService = ref.read(stripeServiceProvider);
      final checkoutResult = await stripeService.createCheckoutSession(
        bookingId: booking.id,
        returnUrl: 'https://rab-booking-248fc.web.app/booking',
      );

      LoggingService.logSuccess('Session created: ${checkoutResult.sessionId}');

      // Step 3: Redirect to Stripe
      final url = Uri.parse(checkoutResult.checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) ref.read(bookingStepProvider.notifier).state = 3;
      } else {
        throw Exception('Could not launch Stripe URL');
      }
    } catch (e) {
      await LoggingService.logError('Stripe error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: colors.error,
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

      // ✅ FIX: Fetch property to get actual owner ID
      LoggingService.logOperation('Fetching property details...');
      final propertyRepo = ref.read(propertyRepositoryProvider);
      final property = await propertyRepo.fetchPropertyById(room.propertyId);

      if (property == null) {
        throw Exception('Property not found');
      }

      final ownerId = property.ownerId;
      LoggingService.logSuccess('Owner ID: $ownerId');

      final priceCalc = await ref.read(
        bookingPriceProvider(
          unitId: room.id,
          checkIn: checkIn,
          checkOut: checkOut,
        ).future,
      );

      if (priceCalc == null) throw Exception('Price calculation failed');

      LoggingService.logOperation('Creating bank transfer booking...');
      final bookingService = ref.read(bookingServiceProvider);
      final booking = await bookingService.createBooking(
        unitId: room.id,
        propertyId: room.propertyId,
        ownerId: ownerId,
        checkIn: checkIn,
        checkOut: checkOut,
        guestName: '${_firstNameController.text} ${_lastNameController.text}',
        guestEmail: _emailController.text,
        guestPhone: _phoneController.text,
        guestCount: adults + children,
        totalPrice: priceCalc.totalPrice,
        paymentOption: _paymentOption,
        paymentMethod: 'bank_transfer',
        notes: _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
      );

      LoggingService.logSuccess('Bank transfer booking created: ${booking.id}');

      // Navigate to confirmation
      if (mounted) {
        ref.read(bookingStepProvider.notifier).state = 3;
      }
    } catch (e) {
      await LoggingService.logError('Bank transfer error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking error: $e'),
            backgroundColor: colors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    }
  }
}
