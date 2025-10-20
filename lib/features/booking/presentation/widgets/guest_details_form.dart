import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium guest details form
/// Features: Validation, country code selector, special requests
class GuestDetailsForm extends StatefulWidget {
  /// Initial first name
  final String? initialFirstName;

  /// Initial last name
  final String? initialLastName;

  /// Initial email
  final String? initialEmail;

  /// Initial phone
  final String? initialPhone;

  /// Initial country code
  final String? initialCountryCode;

  /// Initial special requests
  final String? initialSpecialRequests;

  /// On form submitted
  final Function({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String countryCode,
    String? specialRequests,
  })? onSubmit;

  /// Show save button
  final bool showSaveButton;

  const GuestDetailsForm({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhone,
    this.initialCountryCode,
    this.initialSpecialRequests,
    this.onSubmit,
    this.showSaveButton = true,
  });

  @override
  State<GuestDetailsForm> createState() => _GuestDetailsFormState();
}

class _GuestDetailsFormState extends State<GuestDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specialRequestsController;
  String _selectedCountryCode = '+1';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialFirstName);
    _lastNameController = TextEditingController(text: widget.initialLastName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _specialRequestsController =
        TextEditingController(text: widget.initialSpecialRequests);
    _selectedCountryCode = widget.initialCountryCode ?? '+1';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit?.call(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        countryCode: _selectedCountryCode,
        specialRequests: _specialRequestsController.text.trim().isEmpty
            ? null
            : _specialRequestsController.text.trim(),
      );
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.trim().length < 6) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Guest Details',
            style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
          ),

          const SizedBox(height: AppDimensions.spaceM),

          Text(
            'Please provide your contact information for booking confirmation',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Name fields
          context.isMobile
              ? Column(
                  children: [
                    _buildFirstNameField(),
                    const SizedBox(height: AppDimensions.spaceM),
                    _buildLastNameField(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildFirstNameField()),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(child: _buildLastNameField()),
                  ],
                ),

          const SizedBox(height: AppDimensions.spaceL),

          // Email field
          _buildEmailField(),

          const SizedBox(height: AppDimensions.spaceL),

          // Phone field with country code
          _buildPhoneField(),

          const SizedBox(height: AppDimensions.spaceL),

          // Special requests
          _buildSpecialRequestsField(),

          if (widget.showSaveButton) ...[
            const SizedBox(height: AppDimensions.spaceXL),
            PremiumButton.primary(
              label: 'Continue to Payment',
              icon: Icons.arrow_forward,
              iconPosition: IconPosition.right,
              isFullWidth: true,
              size: ButtonSize.large,
              onPressed: _handleSubmit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFirstNameField() {
    return PremiumTextField(
      controller: _firstNameController,
      label: 'First Name',
      prefixIcon: Icons.person_outline,
      validator: (value) => _validateRequired(value, 'First name'),
    );
  }

  Widget _buildLastNameField() {
    return PremiumTextField(
      controller: _lastNameController,
      label: 'Last Name',
      prefixIcon: Icons.person_outline,
      validator: (value) => _validateRequired(value, 'Last name'),
    );
  }

  Widget _buildEmailField() {
    return PremiumTextField(
      controller: _emailController,
      label: 'Email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      helperText: 'Booking confirmation will be sent to this email',
    );
  }

  Widget _buildPhoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country code selector
        SizedBox(
          width: 120,
          child: PremiumDropdown<String>(
            value: _selectedCountryCode,
            items: _countryCodeItems,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCountryCode = value;
                });
              }
            },
            label: 'Code',
          ),
        ),

        const SizedBox(width: AppDimensions.spaceM),

        // Phone number field
        Expanded(
          child: PremiumTextField(
            controller: _phoneController,
            label: 'Phone Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validatePhone,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRequestsField() {
    return PremiumTextField(
      controller: _specialRequestsController,
      label: 'Special Requests (Optional)',
      prefixIcon: Icons.notes_outlined,
      maxLines: 4,
      helperText: 'Any special requests or requirements',
    );
  }

  List<DropdownMenuItem<String>> get _countryCodeItems {
    return [
      const DropdownMenuItem(value: '+1', child: Text('+1 (US/CA)')),
      const DropdownMenuItem(value: '+44', child: Text('+44 (UK)')),
      const DropdownMenuItem(value: '+385', child: Text('+385 (HR)')),
      const DropdownMenuItem(value: '+49', child: Text('+49 (DE)')),
      const DropdownMenuItem(value: '+33', child: Text('+33 (FR)')),
      const DropdownMenuItem(value: '+39', child: Text('+39 (IT)')),
      const DropdownMenuItem(value: '+34', child: Text('+34 (ES)')),
      const DropdownMenuItem(value: '+91', child: Text('+91 (IN)')),
      const DropdownMenuItem(value: '+86', child: Text('+86 (CN)')),
      const DropdownMenuItem(value: '+81', child: Text('+81 (JP)')),
    ];
  }
}
