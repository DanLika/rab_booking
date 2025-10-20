import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium payment method selector
/// Features: Credit card form, PayPal, validation, secure badge
class PaymentMethodSelector extends StatefulWidget {
  /// On payment method selected
  final Function({
    required PaymentMethod method,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
  })? onPaymentMethodSelected;

  /// Show submit button
  final bool showSubmitButton;

  const PaymentMethodSelector({
    super.key,
    this.onPaymentMethodSelected,
    this.showSubmitButton = true,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  final _formKey = GlobalKey<FormState>();
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;

  // Card form controllers
  late TextEditingController _cardNumberController;
  late TextEditingController _cardHolderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _cardHolderController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_selectedMethod == PaymentMethod.creditCard) {
      if (_formKey.currentState?.validate() ?? false) {
        widget.onPaymentMethodSelected?.call(
          method: _selectedMethod,
          cardNumber: _cardNumberController.text.replaceAll(' ', ''),
          cardHolderName: _cardHolderController.text.trim(),
          expiryDate: _expiryController.text.trim(),
          cvv: _cvvController.text.trim(),
        );
      }
    } else {
      widget.onPaymentMethodSelected?.call(method: _selectedMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Payment Method',
          style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
        ),

        const SizedBox(height: AppDimensions.spaceM),

        // Secure payment badge
        _buildSecureBadge(),

        const SizedBox(height: AppDimensions.spaceXL),

        // Payment method options
        _buildPaymentMethodOptions(),

        const SizedBox(height: AppDimensions.spaceXL),

        // Payment form (conditional based on selected method)
        if (_selectedMethod == PaymentMethod.creditCard)
          _buildCreditCardForm()
        else if (_selectedMethod == PaymentMethod.paypal)
          _buildPayPalInfo()
        else
          _buildOtherPaymentInfo(),

        if (widget.showSubmitButton) ...[
          const SizedBox(height: AppDimensions.spaceXL),
          PremiumButton.primary(
            label: 'Continue to Review',
            icon: Icons.arrow_forward,
            iconPosition: IconPosition.right,
            isFullWidth: true,
            size: ButtonSize.large,
            onPressed: _handleSubmit,
          ),
        ],
      ],
    );
  }

  Widget _buildSecureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.success, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outlined,
            size: AppDimensions.iconM,
            color: AppColors.success,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Text(
            'Secure payment processing',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOptions() {
    return Column(
      children: [
        _buildPaymentOption(
          PaymentMethod.creditCard,
          'Credit / Debit Card',
          Icons.credit_card,
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildPaymentOption(
          PaymentMethod.paypal,
          'PayPal',
          Icons.payment,
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildPaymentOption(
          PaymentMethod.other,
          'Other Payment Methods',
          Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
      PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          color: isSelected
              ? AppColors.withOpacity(AppColors.primary, AppColors.opacity10)
              : null,
          boxShadow: isSelected ? AppShadows.glowPrimary : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppColors.primaryGradient : null,
                color: !isSelected
                    ? (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight)
                    : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: isSelected
                      ? AppTypography.weightSemibold
                      : AppTypography.weightRegular,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppDimensions.iconM,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Card number
          PremiumTextField(
            controller: _cardNumberController,
            label: 'Card Number',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
              LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
            ],
            validator: _validateCardNumber,
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Card holder name
          PremiumTextField(
            controller: _cardHolderController,
            label: 'Cardholder Name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Cardholder name is required';
              }
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Expiry and CVV
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: _expiryController,
                  label: 'Expiry (MM/YY)',
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateFormatter(),
                    LengthLimitingTextInputFormatter(5), // MM/YY
                  ],
                  validator: _validateExpiry,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: PremiumTextField(
                  controller: _cvvController,
                  label: 'CVV',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: _validateCVV,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // Card logos
          _buildCardLogos(),
        ],
      ),
    );
  }

  Widget _buildCardLogos() {
    return Row(
      children: [
        Text(
          'We accept:',
          style: AppTypography.small.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        ...['VISA', 'MC', 'AMEX', 'DISC'].map(
          (card) => Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spaceS),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceS,
                vertical: AppDimensions.spaceXXS,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                card,
                style: AppTypography.small.copyWith(
                  fontWeight: AppTypography.weightBold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayPalInfo() {
    return PremiumCard.elevated(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          children: [
            const Icon(
              Icons.payment,
              size: AppDimensions.iconXL,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'You will be redirected to PayPal to complete your payment',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherPaymentInfo() {
    return PremiumCard.elevated(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Text(
          'Additional payment methods will be available during checkout',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Broj kartice je obavezan';
    }
    final digits = value.replaceAll(' ', '');
    if (digits.length < 13 || digits.length > 19) {
      return 'Unesite važeći broj kartice';
    }

    // Luhn algorithm validation
    if (!_isValidLuhn(digits)) {
      return 'Broj kartice nije važeći';
    }

    return null;
  }

  /// Luhn algorithm for credit card validation
  /// https://en.wikipedia.org/wiki/Luhn_algorithm
  bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    // Start from the rightmost digit
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Datum isteka je obavezan';
    }
    if (value.length != 5) {
      return 'Format: MM/GG';
    }
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Format: MM/GG';
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return 'Nevažeći mjesec';
    }

    if (year == null) {
      return 'Nevažeća godina';
    }

    // Check if card is expired
    final now = DateTime.now();
    final currentYear = now.year % 100; // Get last 2 digits
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Kartica je istekla';
    }

    // Check if expiry is too far in the future (more than 10 years)
    if (year > currentYear + 10) {
      return 'Datum isteka nije važeći';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV je obavezan';
    }
    if (value.length < 3 || value.length > 4) {
      return 'Nevažeći CVV';
    }

    // Ensure CVV contains only digits (extra safety check)
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'CVV mora sadržavati samo brojeve';
    }

    return null;
  }
}

/// Payment method enum
enum PaymentMethod {
  creditCard,
  paypal,
  other,
}

/// Card number formatter (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Expiry date formatter (adds slash after month)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.length >= 2) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(
          offset: text.length >= 2 ? text.length + 1 : text.length,
        ),
      );
    }

    return newValue;
  }
}
