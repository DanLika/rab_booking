import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/guest_details.dart';
import '../../validators/booking_validators.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/widget_config_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../theme/responsive_helper.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Guest details form with validation
class GuestDetailsForm extends ConsumerStatefulWidget {
  final Function(GuestDetails)? onChanged;

  const GuestDetailsForm({super.key, this.onChanged});

  @override
  ConsumerState<GuestDetailsForm> createState() => _GuestDetailsFormState();
}

class _GuestDetailsFormState extends ConsumerState<GuestDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load existing guest details if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final guestDetails = ref.read(guestDetailsProvider);
      _nameController.text = guestDetails.name;
      _emailController.text = guestDetails.email;
      _phoneController.text = guestDetails.phone;
      _messageController.text = guestDetails.message;
    });

    // Update provider on text changes
    _nameController.addListener(_updateProvider);
    _emailController.addListener(_updateProvider);
    _phoneController.addListener(_updateProvider);
    _messageController.addListener(_updateProvider);
  }

  void _updateProvider() {
    final details = GuestDetails(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      message: _messageController.text,
    );

    ref.read(guestDetailsProvider.notifier).state = details;

    // Notify parent widget if callback provided
    widget.onChanged?.call(details);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your details (to reservation and payment)',
            style: GoogleFonts.inter(
              fontSize: isMobile ? TypographyTokens.fontSizeXL : TypographyTokens.fontSizeXXL,
              fontWeight: TypographyTokens.semiBold,
              color: ColorTokens.light.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.l),

          // Name and Email row (Desktop: Row, Mobile: Column)
          if (isMobile) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Name and surname',
              icon: Icons.person,
              hintText: 'John Doe',
              validator: BookingValidators.validateName,
            ),
            const SizedBox(height: SpacingTokens.m2),
            _buildTextField(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.email,
              hintText: 'john.doe@example.com',
              validator: BookingValidators.validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nameController,
                    label: 'Name and surname',
                    icon: Icons.person,
                    hintText: 'John Doe',
                    validator: BookingValidators.validateName,
                  ),
                ),
                const SizedBox(width: SpacingTokens.m2),
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email address',
                    icon: Icons.email,
                    hintText: 'john.doe@example.com',
                    validator: BookingValidators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          const SizedBox(height: SpacingTokens.m2),

          // Phone field
          _buildTextField(
            controller: _phoneController,
            label: 'Phone number',
            icon: Icons.phone,
            hintText: '+385951234567',
            validator: BookingValidators.validatePhone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: SpacingTokens.m2),

          // Message field (optional)
          _buildTextField(
            controller: _messageController,
            label: 'Message (optional)',
            icon: Icons.message,
            hintText: 'Any special requests?',
            validator: (value) => BookingValidators.validateMessage(value),
            maxLines: 3,
            maxLength: 255,
          ),

          // Tax/Legal Disclaimer
          Consumer(
            builder: (context, ref, _) {
              final widgetConfig = ref.watch(widgetConfigProvider);
              final propertyId = widgetConfig.propertyId;
              final unitId = widgetConfig.unitId;

              if (propertyId == null || unitId == null) {
                return const SizedBox.shrink();
              }

              final widgetSettingsAsync = ref.watch(widgetSettingsProvider((propertyId, unitId)));

              return widgetSettingsAsync.when(
                data: (widgetSettings) {
                  final disclaimerText = widgetSettings?.taxLegalConfig.disclaimerText ?? '';

                  if (disclaimerText.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const SizedBox(height: SpacingTokens.l),
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.m),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: SpacingTokens.s),
                                Text(
                                  'Važna Napomena',
                                  style: GoogleFonts.inter(
                                    fontSize: TypographyTokens.fontSizeM,
                                    fontWeight: TypographyTokens.semiBold,
                                    color: ColorTokens.light.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: SpacingTokens.s),
                            Text(
                              disclaimerText,
                              style: GoogleFonts.inter(
                                fontSize: TypographyTokens.fontSizeS,
                                color: ColorTokens.light.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.semiBold,
            color: ColorTokens.light.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.s),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: ColorTokens.light.backgroundCard,
            prefixIcon: Icon(
              icon,
              color: ColorTokens.light.primary,
              size: IconSizeTokens.medium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderTokens.circularMedium,
              borderSide: BorderSide(
                color: ColorTokens.light.borderDefault,
                width: BorderTokens.widthThin,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderTokens.circularMedium,
              borderSide: BorderSide(
                color: ColorTokens.light.borderDefault,
                width: BorderTokens.widthThin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderTokens.circularMedium,
              borderSide: BorderSide(
                color: ColorTokens.light.primary,
                width: BorderTokens.widthThick,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderTokens.circularMedium,
              borderSide: BorderSide(
                color: ColorTokens.light.error,
                width: BorderTokens.widthThin,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderTokens.circularMedium,
              borderSide: BorderSide(
                color: ColorTokens.light.error,
                width: BorderTokens.widthThick,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.m,
              vertical: SpacingTokens.m - 2,
            ),
            hintStyle: GoogleFonts.inter(
              fontSize: TypographyTokens.fontSizeM,
              color: ColorTokens.light.textSecondary,
            ),
            counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
            counterStyle: GoogleFonts.inter(
              fontSize: TypographyTokens.fontSizeS,
              color: ColorTokens.light.textSecondary,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeM,
            color: ColorTokens.light.textPrimary,
          ),
        ),
      ],
    );
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }
}
