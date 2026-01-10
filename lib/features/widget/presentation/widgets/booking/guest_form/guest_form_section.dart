import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../providers/theme_provider.dart';
import '../../../providers/widget_context_provider.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

import '../../../../state/booking_form_state.dart';
import '../../country_code_dropdown.dart';
import 'guest_count_picker.dart';
import 'email_field_with_verification.dart';
import 'phone_field.dart';
import 'guest_name_fields.dart';
import 'notes_field.dart';
import '../../../../domain/models/widget_settings.dart';
import '../../../../shared/models/unit_model.dart';
import '../../providers/booking_price_provider.dart';

/// Deferred component for the guest information form.
/// This widget contains all the heavy form fields and logic for the guest info section.
/// By splitting this out, we can defer loading of:
/// - GuestCountPicker
/// - EmailFieldWithVerification
/// - PhoneField
/// - GuestNameFields
/// - NotesField
class GuestFormSection extends ConsumerWidget {
  final BookingFormState formState;
  final WidgetSettings? widgetSettings;
  final UnitModel? unit;
  final BookingPriceCalculation calculation;
  final VoidCallback onConfirm;
  final VoidCallback onVerifyEmail;
  final Function(Country) onCountryChanged;
  final Function(int) onAdultsChanged;
  final Function(int) onChildrenChanged;
  final VoidCallback onEmailChanged;
  final bool showButton;

  const GuestFormSection({
    super.key,
    required this.formState,
    required this.widgetSettings,
    required this.unit,
    required this.calculation,
    required this.onConfirm,
    required this.onVerifyEmail,
    required this.onCountryChanged,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
    required this.onEmailChanged,
    this.showButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final minimalistColors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return Form(
      key: formState.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            tr.guestInformation,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: minimalistColors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Name fields (First Name + Last Name in a Row)
          GuestNameFields(
            firstNameController: formState.firstNameController,
            lastNameController: formState.lastNameController,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),

          // Email field with verification (if required)
          EmailFieldWithVerification(
            controller: formState.emailController,
            isDarkMode: isDarkMode,
            requireVerification:
                widgetSettings?.emailConfig.requireEmailVerification ?? false,
            emailVerified: formState.emailVerified,
            isLoading: formState.isVerifyingEmail,
            onEmailChanged: (value) => onEmailChanged(),
            onVerifyPressed: () {
              final email = formState.emailController.text.trim();
              final validationError = EmailValidator.validate(email);
              if (validationError != null) {
                SnackBarHelper.showError(
                  context: context,
                  message: validationError,
                );
                return;
              }
              onVerifyEmail();
            },
          ),
          const SizedBox(height: 12),

          // Phone field with country code dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country code dropdown
              CountryCodeDropdown(
                selectedCountry: formState.selectedCountry,
                onChanged: onCountryChanged,
                textColor: minimalistColors.textPrimary,
                backgroundColor: minimalistColors.backgroundSecondary,
                borderColor: minimalistColors.textSecondary.withValues(
                  alpha: 0.3,
                ),
              ),
              const SizedBox(width: SpacingTokens.s),
              // Phone number input
              Expanded(
                child: PhoneField(
                  controller: formState.phoneController,
                  isDarkMode: isDarkMode,
                  dialCode: formState.selectedCountry.dialCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          // Special requests field
          NotesField(
              controller: formState.notesController, isDarkMode: isDarkMode),
          const SizedBox(height: SpacingTokens.m),

          // Guest count picker
          GuestCountPicker(
            adults: formState.adults,
            children: formState.children,
            maxGuests: unit?.maxGuests ?? 10,
            isDarkMode: ref.watch(themeProvider),
            onAdultsChanged: onAdultsChanged,
            onChildrenChanged: onChildrenChanged,
          ),
          const SizedBox(height: SpacingTokens.s),

          // Confirm booking button (only show if showButton parameter is true)
          if (showButton)
            SizedBox(
              width: double.infinity,
              height: 54, // Increased by 10px (was 44)
              child: ElevatedButton(
                onPressed: formState.isProcessing ? () {} : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: minimalistColors.buttonPrimary,
                  foregroundColor: minimalistColors.buttonPrimaryText,
                  disabledBackgroundColor: minimalistColors.buttonPrimary,
                  disabledForegroundColor: minimalistColors.buttonPrimaryText,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.m,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderTokens.circularMedium,
                  ),
                ),
                child: formState.isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                minimalistColors.buttonPrimaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _getConfirmButtonText(
                                  context, ref, widgetSettings, formState),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: minimalistColors.buttonPrimaryText,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _getConfirmButtonText(
                            context, ref, widgetSettings, formState),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: minimalistColors.buttonPrimaryText,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get confirm button text based on widget mode and payment method
  String _getConfirmButtonText(
    BuildContext context,
    WidgetRef ref,
    WidgetSettings? widgetSettings,
    BookingFormState formState,
  ) {
    final widgetMode = widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;
    final tr = WidgetTranslations.of(context, ref);

    // Calculate nights if dates are selected
    String nightsText = '';
    final checkIn = formState.checkIn;
    final checkOut = formState.checkOut;
    if (checkIn != null && checkOut != null) {
      final nights = checkOut.difference(checkIn).inDays;
      nightsText = tr.nightsTextFormat(nights);
    }

    // bookingPending mode - no payment, just request
    if (widgetMode == WidgetMode.bookingPending) {
      return tr.sendBookingRequest(nightsText);
    }

    // bookingInstant mode - depends on selected payment method
    if (formState.selectedPaymentMethod == 'stripe') {
      return tr.payWithStripe(nightsText);
    } else if (formState.selectedPaymentMethod == 'bank_transfer') {
      return tr.continueToBankTransfer(nightsText);
    } else if (formState.selectedPaymentMethod == 'pay_on_arrival') {
      return tr.reserve + nightsText;
    }

    return tr.confirmBookingButton(nightsText);
  }
}
