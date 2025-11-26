import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../widgets/calendar_view_switcher.dart';
import '../widgets/additional_services_widget.dart';
import '../widgets/tax_legal_disclaimer_widget.dart';
import '../providers/booking_price_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../providers/additional_services_provider.dart';
import '../../domain/models/calendar_view_type.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../domain/services/booking_validation_service.dart';
import '../../domain/services/price_lock_service.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../owner_dashboard/presentation/providers/owner_properties_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/services/email_notification_service.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/constants/enums.dart';
import 'booking_confirmation_screen.dart';
import '../widgets/country_code_dropdown.dart';
import '../widgets/email_verification_dialog.dart';
import '../widgets/common/rotate_device_overlay.dart';
import '../widgets/common/loading_screen.dart';
import '../widgets/common/error_screen.dart';
import '../widgets/common/contact/contact_item_widget.dart';
import '../widgets/booking/payment/payment_option_widget.dart';
import '../widgets/booking/guest_form/guest_count_picker.dart';
import '../widgets/common/info_card_widget.dart';
import '../widgets/booking/guest_form/email_field_with_verification.dart';
import '../widgets/booking/guest_form/phone_field.dart';
import '../widgets/booking/guest_form/guest_name_fields.dart';
import '../widgets/booking/guest_form/notes_field.dart';
import '../widgets/booking/payment/no_payment_info.dart';
import '../widgets/booking/payment/payment_method_card.dart';
import '../widgets/booking/pill_bar_content.dart';
import '../widgets/booking/booking_pill_bar.dart';
import '../widgets/common/theme_colors_helper.dart';
import '../utils/snackbar_helper.dart';
import '../../../../core/errors/app_exceptions.dart';

/// Main booking widget screen that shows responsive calendar
/// Automatically switches between year/month/week views based on screen size
class BookingWidgetScreen extends ConsumerStatefulWidget {
  const BookingWidgetScreen({super.key});

  @override
  ConsumerState<BookingWidgetScreen> createState() =>
      _BookingWidgetScreenState();
}

class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  late String _unitId;
  String? _propertyId;
  String? _ownerId;
  UnitModel? _unit; // Store unit data for guest validation

  // Widget settings (loaded from Firestore)
  WidgetSettings? _widgetSettings;

  // Validation state
  bool _isValidating = true;
  String? _validationError;

  // Guest info form
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController(); // Special requests
  Country _selectedCountry = defaultCountry; // Default to Croatia

  // Guest count
  int _adults = 2;
  int _children = 0;

  // UI state
  bool _showGuestForm = false;
  String _selectedPaymentMethod = 'stripe'; // 'stripe' or 'bank_transfer'
  final String _selectedPaymentOption =
      'deposit'; // 'deposit' or 'full' - Bug #12: Made mutable so users can choose
  bool _isProcessing = false;
  bool _emailVerified = false; // Email verification status (OTP)
  bool _taxLegalAccepted = false; // Bug #68: Tax/Legal disclaimer acceptance

  // Bug #64: Price locking to prevent payment mismatches
  BookingPriceCalculation? _lockedPriceCalculation;

  // Draggable pill bar state
  Offset? _pillBarPosition; // null = default bottom center position

  // Bug Fix: Pill bar dismissed state (auto-open fix)
  bool _pillBarDismissed = false; // Track if user clicked X to close pill bar
  bool _hasInteractedWithBookingFlow = false; // Track if user clicked Reserve button

  @override
  void initState() {
    super.initState();
    // Parse property and unit IDs from URL
    final uri = Uri.base;
    _propertyId = uri.queryParameters['property'];
    _unitId = uri.queryParameters['unit'] ?? '';

    // Bug #53: Add listeners to text controllers for auto-save
    _firstNameController.addListener(_saveFormData);
    _lastNameController.addListener(_saveFormData);
    _emailController.addListener(_saveFormData);
    _phoneController.addListener(_saveFormData);
    _notesController.addListener(_saveFormData);

    // Check for Stripe return with confirmation parameters
    final confirmationRef = uri.queryParameters['confirmation'];
    final confirmationEmail = uri.queryParameters['email'];
    final bookingId = uri.queryParameters['bookingId'];
    final paymentType = uri.queryParameters['payment'];

    // Validate unit and property immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _validateUnitAndProperty();

      // Bug #53: Load saved form data if page was refreshed
      await _loadFormData();

      // If we have confirmation parameters, show confirmation screen
      if (confirmationRef != null &&
          confirmationEmail != null &&
          bookingId != null &&
          paymentType == 'stripe') {
        await _showConfirmationFromUrl(
          confirmationRef,
          confirmationEmail,
          bookingId,
        );
      }
    });
  }

  /// Validates that unit exists and fetches property/owner info
  Future<void> _validateUnitAndProperty() async {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      // Check if both property and unit IDs are provided
      if (_propertyId == null || _propertyId!.isEmpty) {
        setState(() {
          _validationError =
              'Missing property parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          _isValidating = false;
        });
        return;
      }

      if (_unitId.isEmpty) {
        setState(() {
          _validationError =
              'Missing unit parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          _isValidating = false;
        });
        return;
      }

      // Fetch property data first
      final property = await ref.read(
        propertyByIdProvider(_propertyId!).future,
      );

      if (property == null) {
        setState(() {
          _validationError = 'Property not found.\n\nProperty ID: $_propertyId';
          _isValidating = false;
        });
        return;
      }

      // Fetch unit data from the specific property
      final unit = await ref.read(
        unitByIdProvider(_propertyId!, _unitId).future,
      );

      if (unit == null) {
        setState(() {
          _validationError =
              'Unit not found.\n\nUnit ID: $_unitId\nProperty ID: $_propertyId';
          _isValidating = false;
        });
        return;
      }

      // Store owner and unit data for later use
      setState(() {
        _ownerId = property.ownerId;
        _unit = unit; // Store unit for guest capacity validation

        // Adjust default guest count to respect property capacity
        final totalGuests = _adults + _children;
        if (totalGuests > unit.maxGuests) {
          // If default exceeds capacity, set to max allowed
          _adults = unit.maxGuests.clamp(1, unit.maxGuests); // At least 1 adult
          _children = 0; // Reset children to 0
        }
      });

      // Load widget settings
      await _loadWidgetSettings(unit.propertyId, unit.id);

      setState(() {
        _isValidating = false;
        _validationError = null;
      });
    } catch (e) {
      setState(() {
        _validationError = 'Error loading unit data:\n\n$e';
        _isValidating = false;
      });
    }
  }

  /// Load widget settings from Firestore
  Future<void> _loadWidgetSettings(String propertyId, String unitId) async {
    try {
      // Try to load custom settings
      final settings = await ref.read(
        widgetSettingsOrDefaultProvider((propertyId, unitId)).future,
      );

      setState(() {
        _widgetSettings = settings;
        // Set default payment method based on what's enabled
        _setDefaultPaymentMethod();
      });
    } catch (e) {
      // If loading fails, use default settings
      final defaultSettings = ref.read(defaultWidgetSettingsProvider);
      setState(() {
        _widgetSettings = defaultSettings.copyWith(
          id: unitId,
          propertyId: propertyId,
        );
        // Set default payment method based on what's enabled
        _setDefaultPaymentMethod();
      });
    }
  }

  /// Set default payment method based on enabled payment options
  /// Priority: Stripe > Bank Transfer > Pay on Arrival
  void _setDefaultPaymentMethod() {
    // Only for bookingInstant mode (bookingPending has no payment)
    if (_widgetSettings?.widgetMode != WidgetMode.bookingInstant) {
      return;
    }

    // Check which payment methods are enabled
    final isStripeEnabled = _widgetSettings?.stripeConfig?.enabled == true;
    final isBankTransferEnabled =
        _widgetSettings?.bankTransferConfig?.enabled == true;
    final isPayOnArrivalEnabled = _widgetSettings?.allowPayOnArrival == true;

    // If current selection is valid, keep it
    if (_selectedPaymentMethod == 'stripe' && isStripeEnabled) return;
    if (_selectedPaymentMethod == 'bank_transfer' && isBankTransferEnabled) {
      return;
    }
    if (_selectedPaymentMethod == 'pay_on_arrival' && isPayOnArrivalEnabled) {
      return;
    }

    // Current selection is invalid - set first available (priority order)
    if (isStripeEnabled) {
      _selectedPaymentMethod = 'stripe';
    } else if (isBankTransferEnabled) {
      _selectedPaymentMethod = 'bank_transfer';
    } else if (isPayOnArrivalEnabled) {
      _selectedPaymentMethod = 'pay_on_arrival';
    } else {
      // Edge case: No payment methods enabled
      // Don't set any payment method - submit validation will block the booking
      _selectedPaymentMethod = '';
    }
  }

  // Bug #53: Form data persistence methods
  static const String _formDataKey = 'booking_widget_form_data';

  /// Save current form data to localStorage
  Future<void> _saveFormData() async {
    if (_unitId.isEmpty) return; // Don't save if no unit selected

    try {
      final prefs = await SharedPreferences.getInstance();
      final formData = {
        'unitId': _unitId,
        'propertyId': _propertyId,
        'checkIn': _checkIn?.toIso8601String(),
        'checkOut': _checkOut?.toIso8601String(),
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'countryCode': _selectedCountry.dialCode,
        'adults': _adults,
        'children': _children,
        'notes': _notesController.text,
        'paymentMethod': _selectedPaymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
        // Bug Fix: Auto-open fix - track dismissed and interaction state
        'pillBarDismissed': _pillBarDismissed,
        'hasInteractedWithBookingFlow': _hasInteractedWithBookingFlow,
      };

      await prefs.setString('${_formDataKey}_$_unitId', jsonEncode(formData));
    } catch (e) {
      // Silent fail - persistence is not critical
      LoggingService.log(
        'Failed to save form data: $e',
        tag: 'FORM_PERSISTENCE',
      );
    }
  }

  /// Load saved form data from localStorage
  Future<void> _loadFormData() async {
    if (_unitId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('${_formDataKey}_$_unitId');

      if (savedData == null) return;

      final formData = jsonDecode(savedData) as Map<String, dynamic>;

      // Check if data is not too old (max 24 hours)
      final timestamp = DateTime.parse(formData['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inHours > 24) {
        await _clearFormData(); // Clear old data
        return;
      }

      // Restore form data
      if (mounted) {
        setState(() {
          // Only restore if same unit
          if (formData['unitId'] == _unitId) {
            if (formData['checkIn'] != null) {
              _checkIn = DateTime.parse(formData['checkIn'] as String);
            }
            if (formData['checkOut'] != null) {
              _checkOut = DateTime.parse(formData['checkOut'] as String);
            }

            _firstNameController.text = formData['firstName'] as String? ?? '';
            _lastNameController.text = formData['lastName'] as String? ?? '';
            _emailController.text = formData['email'] as String? ?? '';
            _phoneController.text = formData['phone'] as String? ?? '';

            // Restore country code
            final savedCountryCode = formData['countryCode'] as String?;
            if (savedCountryCode != null) {
              final country = countries.firstWhere(
                (c) => c.dialCode == savedCountryCode,
                orElse: () => defaultCountry,
              );
              _selectedCountry = country;
            }

            _adults = formData['adults'] as int? ?? 2;
            _children = formData['children'] as int? ?? 0;
            _notesController.text = formData['notes'] as String? ?? '';

            // Restore payment method if valid
            final savedPayment = formData['paymentMethod'] as String?;
            if (savedPayment != null) {
              _selectedPaymentMethod = savedPayment;
            }

            // Bug Fix: Restore dismissed and interaction state
            _pillBarDismissed = formData['pillBarDismissed'] as bool? ?? false;
            _hasInteractedWithBookingFlow = formData['hasInteractedWithBookingFlow'] as bool? ?? false;

            // Bug Fix: Don't auto-show guest form from cache
            // User should explicitly select dates or click to open booking flow
            // Cached data is available but form stays hidden until user action
          }
        });

        LoggingService.log(
          '✅ Form data restored from cache (dismissed: $_pillBarDismissed, interacted: $_hasInteractedWithBookingFlow)',
          tag: 'FORM_PERSISTENCE',
        );
      }
    } catch (e) {
      // Silent fail - just log
      LoggingService.log(
        'Failed to load form data: $e',
        tag: 'FORM_PERSISTENCE',
      );
    }
  }

  /// Clear saved form data from localStorage
  Future<void> _clearFormData() async {
    if (_unitId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_formDataKey}_$_unitId');
      LoggingService.log('🗑️ Form data cleared', tag: 'FORM_PERSISTENCE');
    } catch (e) {
      // Silent fail
      LoggingService.log(
        'Failed to clear form data: $e',
        tag: 'FORM_PERSISTENCE',
      );
    }
  }

  @override
  void dispose() {
    // Bug #53: Remove listeners before disposing
    _firstNameController.removeListener(_saveFormData);
    _lastNameController.removeListener(_saveFormData);
    _emailController.removeListener(_saveFormData);
    _phoneController.removeListener(_saveFormData);
    _notesController.removeListener(_saveFormData);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Helper function to get theme-aware colors
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    // Bug #73: Listen for price calculation errors (dates no longer available)
    // Only listen if dates are selected to avoid unnecessary provider calls
    if (_checkIn != null && _checkOut != null) {
      ref.listen(
        bookingPriceProvider(
          unitId: _unitId,
          checkIn: _checkIn,
          checkOut: _checkOut,
          depositPercentage: _widgetSettings?.globalDepositPercentage ?? 20,
        ),
        (previous, next) {
          next.whenOrNull(
            error: (error, stack) {
              // Check if error is DatesNotAvailableException
              if (error is DatesNotAvailableException) {
                // Clear selected dates
                setState(() {
                  _checkIn = null;
                  _checkOut = null;
                  _showGuestForm = false;
                  _pillBarPosition = null;
                });

                // Show user-friendly error message
                if (mounted) {
                  SnackBarHelper.showError(
                    context: context,
                    message: error.getUserMessage(),
                    isDarkMode: isDarkMode,
                    duration: const Duration(seconds: 5),
                  );
                }
              }
            },
          );
        },
      );
    }

    // Show loading screen during validation
    if (_isValidating) {
      return WidgetLoadingScreen(isDarkMode: isDarkMode);
    }

    // Show error screen if validation failed
    if (_validationError != null) {
      return WidgetErrorScreen(
        isDarkMode: isDarkMode,
        errorMessage: _validationError!,
        onRetry: _validateUnitAndProperty,
      );
    }

    final unitId = _unitId;
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Bug #46: Resize when keyboard appears
      backgroundColor: getColor(
        MinimalistColors.backgroundPrimary,
        MinimalistColorsDark.backgroundPrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final forceMonthView =
                screenWidth < 1024; // Year view only on desktop

            // Responsive padding for iframe embedding
            final horizontalPadding = screenWidth < 600
                ? 12.0 // Mobile
                : screenWidth < 1024
                ? 16.0 // Tablet
                : 24.0; // Desktop

            final verticalPadding =
                horizontalPadding / 2; // Half of horizontal padding

            final topPadding = 0.0; // Minimal padding for maximum content space

            // Calculate available height for calendar
            // Subtract space for logo, title, and padding
            final screenHeight = constraints.maxHeight;
            double reservedHeight =
                topPadding +
                (verticalPadding * 2); // Include top + bottom padding

            // Add title height if present
            if (_widgetSettings?.themeOptions?.customTitle != null &&
                _widgetSettings!.themeOptions!.customTitle!.isNotEmpty) {
              reservedHeight += 60; // Approx title height (24px font + padding)
            }

            // Add iCal warning if present (will be checked later)
            reservedHeight += 16; // Buffer for potential warning banner

            // Add contact pill card height for calendar-only mode
            if (widgetMode == WidgetMode.calendarOnly) {
              reservedHeight +=
                  180; // Contact pill card height (header + subtitle + pill + spacing)
            }

            // Calendar gets remaining height (ensure minimum of 400px)
            final calendarHeight = (screenHeight - reservedHeight).clamp(
              400.0,
              double.infinity,
            );

            return Stack(
              children: [
                // No-scroll content (embedded widget - host site scrolls)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    children: [
                      // Custom title header (if configured)
                      if (_widgetSettings?.themeOptions?.customTitle != null &&
                          _widgetSettings!
                              .themeOptions!
                              .customTitle!
                              .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _widgetSettings!.themeOptions!.customTitle!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? MinimalistColorsDark.textPrimary
                                  : MinimalistColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // NOTE: iCal sync warning banner removed from guest widget
                      // This is owner-only information - guests don't need to see sync status
                      // Owners can monitor sync status in their dashboard

                      // Calendar with calculated height (respects minimum 400px constraint)
                      SizedBox(
                        height: calendarHeight,
                        child: CalendarViewSwitcher(
                          propertyId: _propertyId ?? '',
                          unitId: unitId,
                          forceMonthView: forceMonthView,
                          // Disable date selection in calendar_only mode
                          onRangeSelected: widgetMode == WidgetMode.calendarOnly
                              ? null
                              : (start, end) {
                                  // Validate minimum nights requirement
                                  if (start != null && end != null) {
                                    final minNights =
                                        _widgetSettings?.minNights ?? 1;
                                    final selectedNights = end
                                        .difference(start)
                                        .inDays;

                                    if (selectedNights < minNights) {
                                      // Show error message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Minimum $minNights ${minNights == 1 ? 'night' : 'nights'} required. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
                                          ),
                                          backgroundColor:
                                              MinimalistColors.error,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  setState(() {
                                    _checkIn = start;
                                    _checkOut = end;
                                    _pillBarPosition =
                                        null; // Reset position when new dates selected
                                    // Bug Fix: Date selection IS interaction - show booking flow
                                    _hasInteractedWithBookingFlow = true;
                                    _pillBarDismissed =
                                        false; // Reset dismissed flag for new date selection
                                  });

                                  // Bug #53: Save form data after date selection
                                  _saveFormData();
                                },
                        ),
                      ),

                      // Contact pill card (calendar only mode - inline, below calendar)
                      if (widgetMode == WidgetMode.calendarOnly) ...[
                        const SizedBox(height: 8),
                        _buildContactPillCard(isDarkMode, screenWidth),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

                // Full-screen backdrop overlay when guest form is shown
                if (_showGuestForm)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showGuestForm = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),

                // Floating draggable booking summary bar (booking modes - shown when dates selected)
                // Bug Fix: Only show pill bar if user interacted with booking flow (clicked Reserve)
                // AND pill bar wasn't dismissed (user clicked X button)
                if (widgetMode != WidgetMode.calendarOnly &&
                    _checkIn != null &&
                    _checkOut != null &&
                    _hasInteractedWithBookingFlow &&
                    !_pillBarDismissed)
                  _buildFloatingDraggablePillBar(
                    unitId,
                    constraints,
                    isDarkMode,
                  ),

                // Rotate device overlay - HIGHEST z-index, only for year view in portrait
                if (_shouldShowRotateOverlay(context))
                  RotateDeviceOverlay(
                    isDarkMode: isDarkMode,
                    colors: colors,
                    onSwitchToMonthView: () {
                      ref.read(calendarViewProvider.notifier).state =
                          CalendarViewType.month;
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Helper to launch URLs (phone, email, WhatsApp)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Build contact pill card for calendar-only mode (inline, below calendar)
  Widget _buildContactPillCard(bool isDarkMode, double screenWidth) {
    final contactOptions = _widgetSettings?.contactOptions;
    // Only use column layout on very small screens (< 350px)
    final useRowLayout = screenWidth >= 350;

    // Dynamic max width: allow row layout on most screens
    final maxWidth = useRowLayout ? 500.0 : 200.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? MinimalistColorsDark.backgroundSecondary
                : MinimalistColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12), // Pill style
            border: Border.all(
              color: isDarkMode
                  ? MinimalistColorsDark.borderDefault
                  : MinimalistColors.borderDefault,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: useRowLayout
              ? _buildDesktopContactRow(contactOptions, isDarkMode)
              : _buildMobileContactColumn(contactOptions, isDarkMode),
        ),
      ),
    );
  }

  /// Desktop layout: email + phone in same row with divider
  Widget _buildDesktopContactRow(
    ContactOptions? contactOptions,
    bool isDarkMode,
  ) {
    final hasEmail =
        contactOptions?.showEmail == true &&
        contactOptions?.emailAddress != null &&
        contactOptions!.emailAddress!.isNotEmpty;

    final hasPhone =
        contactOptions?.showPhone == true &&
        contactOptions?.phoneNumber != null &&
        contactOptions!.phoneNumber!.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Email
        if (hasEmail)
          ContactItemWidget(
            icon: Icons.email,
            value: contactOptions.emailAddress!,
            onTap: () => _launchUrl('mailto:${contactOptions.emailAddress}'),
            isDarkMode: isDarkMode,
          ),

        // Vertical divider
        if (hasEmail && hasPhone)
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: isDarkMode
                ? MinimalistColorsDark.borderDefault
                : MinimalistColors.borderDefault,
          ),

        // Phone
        if (hasPhone)
          ContactItemWidget(
            icon: Icons.phone,
            value: contactOptions.phoneNumber!,
            onTap: () => _launchUrl('tel:${contactOptions.phoneNumber}'),
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  /// Mobile layout: email and phone stacked vertically
  Widget _buildMobileContactColumn(
    ContactOptions? contactOptions,
    bool isDarkMode,
  ) {
    final hasEmail =
        contactOptions?.showEmail == true &&
        contactOptions?.emailAddress != null &&
        contactOptions!.emailAddress!.isNotEmpty;

    final hasPhone =
        contactOptions?.showPhone == true &&
        contactOptions?.phoneNumber != null &&
        contactOptions!.phoneNumber!.isNotEmpty;

    return Column(
      children: [
        // Email
        if (hasEmail)
          ContactItemWidget(
            icon: Icons.email,
            value: contactOptions.emailAddress!,
            onTap: () => _launchUrl('mailto:${contactOptions.emailAddress}'),
            isDarkMode: isDarkMode,
          ),

        // Horizontal divider between email and phone
        if (hasEmail && hasPhone)
          Divider(
            color: isDarkMode
                ? MinimalistColorsDark.borderDefault
                : MinimalistColors.borderDefault,
            height: 12,
            thickness: 1,
          ),

        // Phone
        if (hasPhone)
          ContactItemWidget(
            icon: Icons.phone,
            value: contactOptions.phoneNumber!,
            onTap: () => _launchUrl('tel:${contactOptions.phoneNumber}'),
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  /// Build floating draggable pill bar that overlays the calendar
  Widget _buildFloatingDraggablePillBar(
    String unitId,
    BoxConstraints constraints,
    bool isDarkMode,
  ) {
    // Watch price calculation with global deposit percentage (applies to all payment methods)
    final depositPercentage = _widgetSettings?.globalDepositPercentage ?? 20;
    final priceCalc = ref.watch(
      bookingPriceProvider(
        unitId: unitId,
        checkIn: _checkIn,
        checkOut: _checkOut,
        depositPercentage: depositPercentage,
      ),
    );

    return priceCalc.when(
      data: (calculationBase) {
        if (calculationBase == null) {
          return const SizedBox.shrink();
        }

        // Watch additional services selection
        final servicesAsync = ref.watch(unitAdditionalServicesProvider(unitId));
        final selectedServices = ref.watch(selectedAdditionalServicesProvider);

        // Calculate additional services total
        double servicesTotal = 0.0;
        servicesAsync.whenData((services) {
          if (services.isNotEmpty && selectedServices.isNotEmpty) {
            servicesTotal = ref.read(
              additionalServicesTotalProvider((
                services,
                selectedServices,
                _checkOut!.difference(_checkIn!).inDays,
                _adults + _children,
              )),
            );
          }
        });

        // Update calculation with additional services
        final calculation = calculationBase.copyWithServices(
          servicesTotal,
          depositPercentage,
        );

        // Calculate responsive width and height based on screen size
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        double pillBarWidth;
        double maxHeight;

        // Different widths for step 1 (compact) vs step 2 (form)
        if (_showGuestForm) {
          // Step 2: Full form - responsive based on device
          if (screenWidth < 600) {
            // Mobile
            pillBarWidth = screenWidth * 0.95; // 95% width
            maxHeight = screenHeight * 0.9; // 90% height
          } else if (screenWidth < 1024) {
            // Tablet
            pillBarWidth = screenWidth * 0.8; // 80% width
            maxHeight = screenHeight * 0.8; // 80% height
          } else {
            // Desktop
            pillBarWidth = screenWidth * 0.7; // 70% width
            maxHeight = screenHeight * 0.7; // 70% height
          }
        } else {
          // Step 1: Compact pill bar
          if (screenWidth < 600) {
            pillBarWidth = 350.0; // Mobile: fixed 350px
          } else {
            pillBarWidth = 400.0; // Desktop/Tablet: fixed 400px
          }
          maxHeight =
              282.0; // Fixed height for compact view (increased by 12px)
        }

        // Center booking flow on screen (not calendar)
        final defaultPosition = Offset(
          (constraints.maxWidth / 2) -
              (pillBarWidth / 2), // Center horizontally
          (constraints.maxHeight / 2) -
              (maxHeight / 2), // Center vertically based on screen
        );

        final position = _pillBarPosition ?? defaultPosition;

        // Check if more than 50% of pill bar is off-screen (drag-to-dismiss)
        final isMoreThanHalfOffScreen =
            position.dx < -pillBarWidth / 2 || // >50% dragged left
            position.dy < -maxHeight / 2 || // >50% dragged up
            position.dx >
                constraints.maxWidth - pillBarWidth / 2 || // >50% dragged right
            position.dy >
                constraints.maxHeight - maxHeight / 2; // >50% dragged down

        // Check if pill bar is completely off-screen (dragged beyond bounds)
        final isCompletelyOffScreen =
            position.dx + pillBarWidth < 0 || // Dragged left off-screen
            position.dy + maxHeight < 0 || // Dragged up off-screen
            position.dx > constraints.maxWidth || // Dragged right off-screen
            position.dy > constraints.maxHeight; // Dragged down off-screen

        // If completely off-screen, hide the pill bar
        if (isCompletelyOffScreen) {
          return const SizedBox.shrink();
        }

        return BookingPillBar(
          position: position,
          width: pillBarWidth,
          maxHeight: maxHeight,
          isDarkMode: isDarkMode,
          keyboardInset: MediaQuery.of(context).viewInsets.bottom,
          onDragStart: () {
            // Haptic feedback handled in widget
          },
          onDragUpdate: (delta) {
            setState(() {
              // Allow dragging beyond screen bounds - pill bar will hide if off-screen
              _pillBarPosition = Offset(
                position.dx + delta.dx,
                position.dy + delta.dy,
              );
            });
          },
          onDragEnd: () {
            // Drag-to-dismiss: If >50% of pill bar is off-screen, close it
            if (isMoreThanHalfOffScreen) {
              setState(() {
                _checkIn = null;
                _checkOut = null;
                _showGuestForm = false;
                _pillBarPosition = null;
              });
            } else if (isCompletelyOffScreen) {
              // If completely off-screen (but <50%), reset to default position
              setState(() {
                _pillBarPosition = null; // Reset to center
              });
            }
          },
          child: PillBarContent(
                      checkIn: _checkIn!,
                      checkOut: _checkOut!,
                      nights: _checkOut!.difference(_checkIn!).inDays,
                      formattedRoomPrice: calculation.formattedRoomPrice,
                      additionalServicesTotal: calculation.additionalServicesTotal,
                      formattedAdditionalServices: calculation.formattedAdditionalServices,
                      formattedTotal: calculation.formattedTotal,
                      formattedDeposit: calculation.formattedDeposit,
                      depositPercentage: calculation.totalPrice > 0
                          ? ((calculation.depositAmount / calculation.totalPrice) * 100).round()
                          : 20,
                      isDarkMode: isDarkMode,
                      showGuestForm: _showGuestForm,
                      isWideScreen: MediaQuery.of(context).size.width >= 768,
                      onClose: () {
                        // Bug Fix: Set dismissed flag instead of clearing dates
                        setState(() {
                          _pillBarDismissed = true;
                          _showGuestForm = false;
                          _pillBarPosition = null;
                        });
                        _saveFormData();
                      },
                      onReserve: () {
                        // Bug #64: Lock price when user starts booking process
                        setState(() {
                          _showGuestForm = true;
                          _hasInteractedWithBookingFlow = true;
                          _lockedPriceCalculation = calculation.copyWithLock();
                        });
                        _saveFormData();
                      },
                      guestFormBuilder: () => _buildGuestInfoForm(calculation, showButton: false),
                      paymentSectionBuilder: () => _buildPaymentSection(calculation),
                      additionalServicesBuilder: () => Consumer(
                        builder: (context, ref, _) {
                          final servicesAsync = ref.watch(unitAdditionalServicesProvider(_unitId));
                          return servicesAsync.when(
                            data: (services) {
                              if (services.isEmpty) return const SizedBox.shrink();
                              return Column(
                                children: [
                                  const SizedBox(height: SpacingTokens.m),
                                  AdditionalServicesWidget(
                                    unitId: _unitId,
                                    nights: _checkOut!.difference(_checkIn!).inDays,
                                    guests: _adults + _children,
                                  ),
                                  const SizedBox(height: SpacingTokens.m),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      taxLegalBuilder: () => TaxLegalDisclaimerWidget(
                        propertyId: _propertyId ?? '',
                        unitId: _unitId,
                        onAcceptedChanged: (accepted) {
                          setState(() => _taxLegalAccepted = accepted);
                        },
                      ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Build payment section (payment options + confirm button)
  Widget _buildPaymentSection(BookingPriceCalculation calculation) {
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    // Safety check: At least one payment method must be available
    final hasAnyPaymentMethod =
        (_widgetSettings?.stripeConfig?.enabled == true) ||
        (_widgetSettings?.bankTransferConfig?.enabled == true) ||
        (_widgetSettings?.allowPayOnArrival == true);

    // If no payment methods available, show error message
    if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant &&
        !hasAnyPaymentMethod) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoPaymentInfo(
            isDarkMode: isDarkMode,
            message: 'No payment methods available. Please contact property owner.',
          ),
          const SizedBox(height: SpacingTokens.m),
          // Disabled confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // Disabled
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderTokens.circularRounded,
                ),
              ),
              child: const Text(
                'Booking Not Available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment method section (only for bookingInstant mode)
        if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant) ...[
          // Count enabled payment methods
          Builder(
            builder: (context) {
              final isStripeEnabled =
                  _widgetSettings?.stripeConfig?.enabled == true;
              final isBankTransferEnabled =
                  _widgetSettings?.bankTransferConfig?.enabled == true;
              final isPayOnArrivalEnabled =
                  _widgetSettings?.allowPayOnArrival == true;

              int enabledCount = 0;
              String? singleMethod;
              String? singleMethodTitle;
              String? singleMethodSubtitle;

              if (isStripeEnabled) {
                enabledCount++;
                singleMethod = 'stripe';
                singleMethodTitle = 'Credit/Debit Card via Stripe';
                singleMethodSubtitle = calculation.formattedDeposit;
              }
              if (isBankTransferEnabled) {
                enabledCount++;
                singleMethod = 'bank_transfer';
                singleMethodTitle = 'Bank Transfer';
                singleMethodSubtitle = calculation.formattedDeposit;
              }
              if (isPayOnArrivalEnabled) {
                enabledCount++;
                singleMethod = 'pay_on_arrival';
                singleMethodTitle = 'Pay on Arrival';
                singleMethodSubtitle = 'Payment at property';
              }

              // If no payment methods enabled, show error
              if (enabledCount == 0) {
                return NoPaymentInfo(isDarkMode: isDarkMode);
              }

              // If only one method, auto-select and show simplified UI
              if (enabledCount == 1) {
                // Auto-select the single method
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_selectedPaymentMethod != singleMethod) {
                    setState(() {
                      _selectedPaymentMethod = singleMethod!;
                    });
                  }
                });

                // Show simplified payment info (no selector)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.s),
                    PaymentMethodCard(
                      icon: singleMethod == 'stripe'
                          ? Icons.credit_card
                          : singleMethod == 'bank_transfer'
                              ? Icons.account_balance
                              : Icons.home_outlined,
                      title: singleMethodTitle!,
                      subtitle: singleMethodSubtitle,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: SpacingTokens.m),
                  ],
                );
              }

              // Multiple methods - show normal payment selector
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.s),
                ],
              );
            },
          ),

          // Payment options - only show if multiple methods available
          Builder(
            builder: (context) {
              final isStripeEnabled =
                  _widgetSettings?.stripeConfig?.enabled == true;
              final isBankTransferEnabled =
                  _widgetSettings?.bankTransferConfig?.enabled == true;
              final isPayOnArrivalEnabled =
                  _widgetSettings?.allowPayOnArrival == true;

              int enabledCount = 0;
              if (isStripeEnabled) enabledCount++;
              if (isBankTransferEnabled) enabledCount++;
              if (isPayOnArrivalEnabled) enabledCount++;

              // Only show payment selectors if multiple options
              if (enabledCount <= 1) {
                return const SizedBox.shrink(); // Hide payment options
              }

              // Multiple payment methods - show all options
              return Column(
                children: [
                  // Stripe option
                  if (isStripeEnabled)
                    PaymentOptionWidget(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Instant confirmation via Stripe',
                      isSelected: _selectedPaymentMethod == 'stripe',
                      onTap: () => setState(() => _selectedPaymentMethod = 'stripe'),
                      isDarkMode: isDarkMode,
                      depositAmount: calculation.formattedDeposit,
                    ),

                  // Bank Transfer option
                  if (isBankTransferEnabled)
                    Padding(
                      padding: EdgeInsets.only(
                        top: isStripeEnabled ? SpacingTokens.s : 0,
                      ),
                      child: PaymentOptionWidget(
                        icon: Icons.account_balance,
                        title: 'Bank Transfer',
                        subtitle: 'Manual confirmation (3 business days)',
                        isSelected: _selectedPaymentMethod == 'bank_transfer',
                        onTap: () => setState(() => _selectedPaymentMethod = 'bank_transfer'),
                        isDarkMode: isDarkMode,
                        depositAmount: calculation.formattedDeposit,
                      ),
                    ),

                  // Pay on Arrival option
                  if (isPayOnArrivalEnabled)
                    Padding(
                      padding: EdgeInsets.only(
                        top: (isStripeEnabled || isBankTransferEnabled)
                            ? SpacingTokens.s
                            : 0,
                      ),
                      child: PaymentOptionWidget(
                        icon: Icons.home_outlined,
                        title: 'Pay on Arrival',
                        subtitle: 'Pay at the property',
                        isSelected: _selectedPaymentMethod == 'pay_on_arrival',
                        onTap: () => setState(() => _selectedPaymentMethod = 'pay_on_arrival'),
                        isDarkMode: isDarkMode,
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: SpacingTokens.m),
        ],

        // Info message for bookingPending mode
        if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
          InfoCardWidget(
            message:
                'Your booking will be pending until confirmed by the property owner',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: SpacingTokens.m),
        ],

        // Confirm button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _handleConfirmBooking(calculation),
            style: ElevatedButton.styleFrom(
              backgroundColor: getColor(
                MinimalistColors.buttonPrimary,
                MinimalistColorsDark.buttonPrimary,
              ),
              foregroundColor: getColor(
                MinimalistColors.buttonPrimaryText,
                MinimalistColorsDark.buttonPrimaryText,
              ),
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderTokens.circularMedium,
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getColor(
                          MinimalistColors.buttonPrimaryText,
                          MinimalistColorsDark.buttonPrimaryText,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AutoSizeText(
                      _getConfirmButtonText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getColor(
                          MinimalistColors.buttonPrimaryText,
                          MinimalistColorsDark.buttonPrimaryText,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInfoForm(
    BookingPriceCalculation calculation, {
    bool showButton = true,
  }) {
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Guest Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Name fields (First Name + Last Name in a Row)
          GuestNameFields(
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),

          // Email field with verification (if required)
          EmailFieldWithVerification(
            controller: _emailController,
            isDarkMode: isDarkMode,
            requireVerification:
                _widgetSettings?.emailConfig.requireEmailVerification ?? false,
            emailVerified: _emailVerified,
            onEmailChanged: (value) {
              // Reset verification when email changes
              if (_emailVerified) {
                setState(() {
                  _emailVerified = false;
                });
              }
            },
            onVerifyPressed: () {
              final email = _emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                SnackBarHelper.showError(
                  context: context,
                  message: 'Please enter a valid email first',
                  isDarkMode: isDarkMode,
                );
                return;
              }
              _openVerificationDialog();
            },
          ),
          const SizedBox(height: 12),

          // Phone field with country code dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country code dropdown
              CountryCodeDropdown(
                selectedCountry: _selectedCountry,
                onChanged: (country) {
                  setState(() {
                    _selectedCountry = country;
                    // Re-validate phone number with new country
                    _formKey.currentState?.validate();
                  });
                },
                textColor: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
                backgroundColor: getColor(
                  MinimalistColors.backgroundSecondary,
                  MinimalistColorsDark.backgroundSecondary,
                ),
                borderColor: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ).withOpacity(0.3),
              ),
              const SizedBox(width: SpacingTokens.s),
              // Phone number input
              Expanded(
                child: PhoneField(
                  controller: _phoneController,
                  isDarkMode: isDarkMode,
                  dialCode: _selectedCountry.dialCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          // Special requests field
          NotesField(
            controller: _notesController,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: SpacingTokens.m),

          // Guest count picker
          GuestCountPicker(
            adults: _adults,
            children: _children,
            maxGuests: _unit?.maxGuests ?? 10,
            isDarkMode: ref.watch(themeProvider),
            onAdultsChanged: (value) => setState(() => _adults = value),
            onChildrenChanged: (value) => setState(() => _children = value),
          ),
          const SizedBox(height: SpacingTokens.s),

          // Confirm booking button (only show if showButton parameter is true)
          if (showButton)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _handleConfirmBooking(calculation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MinimalistColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.m,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderTokens.circularMedium,
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _getConfirmButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Get confirm button text based on widget mode and payment method
  String _getConfirmButtonText() {
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Calculate nights if dates are selected
    String nightsText = '';
    if (_checkIn != null && _checkOut != null) {
      final nights = _checkOut!.difference(_checkIn!).inDays;
      nightsText = ' - $nights ${nights == 1 ? 'night' : 'nights'}';
    }

    // bookingPending mode - no payment, just request
    if (widgetMode == WidgetMode.bookingPending) {
      return 'Send Booking Request$nightsText';
    }

    // bookingInstant mode - depends on selected payment method
    if (_selectedPaymentMethod == 'stripe') {
      return 'Pay with Stripe$nightsText';
    } else if (_selectedPaymentMethod == 'bank_transfer') {
      return 'Continue to Bank Transfer$nightsText';
    } else if (_selectedPaymentMethod == 'pay_on_arrival') {
      return 'Rezervisi$nightsText'; // Reserve in Serbian
    }

    return 'Confirm Booking$nightsText';
  }

  Future<void> _handleConfirmBooking(
    BookingPriceCalculation calculation,
  ) async {
    final isDarkMode = ref.watch(themeProvider);
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Run all blocking validations using BookingValidationService
    final validationResult = BookingValidationService.validateAllBlocking(
      formKey: _formKey,
      requireEmailVerification:
          _widgetSettings?.emailConfig.requireEmailVerification ?? false,
      emailVerified: _emailVerified,
      taxConfig: _widgetSettings?.taxLegalConfig,
      taxLegalAccepted: _taxLegalAccepted,
      checkIn: _checkIn,
      checkOut: _checkOut,
      propertyId: _propertyId,
      ownerId: _ownerId,
      widgetMode: widgetMode,
      selectedPaymentMethod: _selectedPaymentMethod,
      widgetSettings: _widgetSettings,
      adults: _adults,
      children: _children,
      maxGuests: _unit?.maxGuests ?? 10,
    );

    if (!validationResult.isValid) {
      if (validationResult.errorMessage != null && mounted) {
        SnackBarHelper.showError(
          context: context,
          message: validationResult.errorMessage!,
          isDarkMode: isDarkMode,
          duration: validationResult.snackBarDuration,
        );
      }
      return;
    }

    // Bug #64: Check if price changed since user started booking
    if (mounted) {
      final priceLockResult = await PriceLockService.checkAndConfirmPriceChange(
        context: context,
        currentCalculation: calculation,
        lockedCalculation: _lockedPriceCalculation,
        onLockUpdated: () {
          setState(() {
            _lockedPriceCalculation = calculation.copyWithLock();
          });
        },
      );

      if (priceLockResult == PriceLockResult.cancelled) {
        return;
      }
    }

    // Check same-day check-in warning (non-blocking)
    if (_checkIn != null) {
      final sameDayResult = BookingValidationService.checkSameDayCheckIn(
        checkIn: _checkIn!,
      );
      if (sameDayResult.isWarning && sameDayResult.errorMessage != null && mounted) {
        SnackBarHelper.showWarning(
          context: context,
          message: sameDayResult.errorMessage!,
          isDarkMode: isDarkMode,
          duration: sameDayResult.snackBarDuration,
        );
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Race condition is handled atomically by createBookingAtomic Cloud Function
      // Client-side checks are unsafe due to TOCTOU (Time-of-check-to-time-of-use)

      final bookingService = ref.read(bookingServiceProvider);

      // For bookingPending mode - create booking without payment
      if (widgetMode == WidgetMode.bookingPending) {
        final booking = await bookingService.createBooking(
          unitId: _unitId,
          propertyId: _propertyId!,
          ownerId: _ownerId!,
          checkIn: _checkIn!,
          checkOut: _checkOut!,
          guestName:
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                  .trim(),
          guestEmail: _emailController.text.trim(),
          guestPhone:
              '${_selectedCountry.dialCode} ${_phoneController.text.trim()}',
          guestCount: _adults + _children,
          totalPrice: calculation.totalPrice,
          paymentOption: 'none', // No payment for pending bookings
          paymentMethod: 'none',
          requireOwnerApproval:
              true, // Always requires approval in bookingPending mode
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          taxLegalAccepted:
              _widgetSettings?.taxLegalConfig != null &&
                  _widgetSettings!.taxLegalConfig.enabled
              ? _taxLegalAccepted
              : null,
        );

        // Send email notifications
        _sendBookingEmails(
          booking: booking,
          requiresApproval: true,
        );

        // Navigate to confirmation screen and cleanup
        await _navigateToConfirmationAndCleanup(
          booking: booking,
          paymentMethod: 'pending',
        );
        return;
      }

      // For bookingInstant mode - create booking with payment
      final booking = await bookingService.createBooking(
        unitId: _unitId,
        propertyId: _propertyId!,
        ownerId: _ownerId!,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        guestName:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        guestEmail: _emailController.text.trim(),
        guestPhone:
            '${_selectedCountry.dialCode} ${_phoneController.text.trim()}',
        guestCount: _adults + _children,
        totalPrice: calculation.totalPrice,
        paymentOption: _selectedPaymentOption, // 'deposit' or 'full'
        paymentMethod: _selectedPaymentMethod, // 'stripe' or 'bank_transfer'
        requireOwnerApproval: _widgetSettings?.requireOwnerApproval ?? false,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        taxLegalAccepted:
            _widgetSettings?.taxLegalConfig != null &&
                _widgetSettings!.taxLegalConfig.enabled
            ? _taxLegalAccepted
            : null,
      );

      // Send booking confirmation email (pre-payment)
      // Calculate payment deadline for bank transfer (default 3 days)
      final paymentDeadlineDays =
          _widgetSettings?.bankTransferConfig?.paymentDeadlineDays ?? 3;
      final paymentDeadline = DateTime.now().add(
        Duration(days: paymentDeadlineDays),
      );
      final dateFormat = DateFormat('dd.MM.yyyy');

      _sendBookingEmails(
        booking: booking,
        requiresApproval: _widgetSettings?.requireOwnerApproval ?? false,
        paymentMethod: _selectedPaymentMethod,
        paymentDeadline: dateFormat.format(paymentDeadline),
      );

      if (_selectedPaymentMethod == 'stripe') {
        // Stripe payment - redirect to checkout
        // Pass booking details for return URL construction
        await _handleStripePayment(
          bookingId: booking.id,
          bookingReference: booking.id.substring(0, 8).toUpperCase(),
          guestEmail: booking.guestEmail!,
        );
      } else if (_selectedPaymentMethod == 'bank_transfer') {
        // Bank transfer - navigate to confirmation screen
        await _navigateToConfirmationAndCleanup(
          booking: booking,
          paymentMethod: 'bank_transfer',
        );
      } else if (_selectedPaymentMethod == 'pay_on_arrival') {
        // Pay on Arrival - navigate to confirmation screen
        await _navigateToConfirmationAndCleanup(
          booking: booking,
          paymentMethod: 'pay_on_arrival',
        );
      }
    } on BookingConflictException catch (e) {
      // Race condition - dates were booked by another user
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: e.message,
          isDarkMode: isDarkMode,
          duration: const Duration(seconds: 7),
        );

        // Reset selection so user can pick new dates
        setState(() {
          _checkIn = null;
          _checkOut = null;
          _showGuestForm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Error creating booking: $e',
          isDarkMode: isDarkMode,
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

  /// Helper method to navigate to confirmation screen and cleanup form
  /// Reduces ~120 lines of duplicated code for pending/bank_transfer/pay_on_arrival
  Future<void> _navigateToConfirmationAndCleanup({
    required BookingModel booking,
    required String paymentMethod,
  }) async {
    if (!mounted) return;

    // Reset form before navigation
    setState(() {
      _checkIn = null;
      _checkOut = null;
      _showGuestForm = false;
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _adults = 2;
      _children = 0;
    });

    // Navigate to confirmation screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          bookingReference: booking.id.substring(0, 8).toUpperCase(),
          guestEmail: booking.guestEmail!,
          guestName: booking.guestName!,
          checkIn: booking.checkIn,
          checkOut: booking.checkOut,
          totalPrice: booking.totalPrice,
          nights: booking.checkOut.difference(booking.checkIn).inDays,
          guests: booking.guestCount,
          propertyName: _unit?.name ?? 'Property',
          unitName: _unit?.name,
          paymentMethod: paymentMethod,
          booking: booking,
          emailConfig: _widgetSettings?.emailConfig,
          widgetSettings: _widgetSettings,
        ),
      ),
    );

    // CRITICAL: Invalidate calendar cache after booking
    // This ensures the calendar refreshes and shows newly booked dates
    if (mounted) {
      ref.invalidate(realtimeYearCalendarProvider);
      ref.invalidate(realtimeMonthCalendarProvider);

      // Bug #53: Clear saved form data after successful booking
      await _clearFormData();
    }
  }

  /// Helper method to send booking confirmation emails
  /// Reduces ~100 lines of duplicated code between pending/instant modes
  void _sendBookingEmails({
    required BookingModel booking,
    required bool requiresApproval,
    String? paymentMethod,
    String? paymentDeadline,
  }) {
    final emailConfig = _widgetSettings?.emailConfig;
    if (emailConfig?.enabled != true || emailConfig?.isConfigured != true) {
      return;
    }

    final emailService = EmailNotificationService();
    final bookingReference = booking.id.substring(0, 8).toUpperCase();
    final propertyName = _unit?.name ?? 'Vacation Rental';

    // Send guest confirmation email
    unawaited(
      emailService.sendBookingConfirmationEmail(
        booking: booking,
        emailConfig: _widgetSettings!.emailConfig,
        propertyName: propertyName,
        bookingReference: bookingReference,
        paymentDeadline: paymentDeadline,
        paymentMethod: paymentMethod,
        bankTransferConfig: _widgetSettings!.bankTransferConfig,
        allowGuestCancellation: _widgetSettings!.allowGuestCancellation,
        cancellationDeadlineHours: _widgetSettings!.cancellationDeadlineHours,
        ownerEmail: _widgetSettings!.contactOptions.emailAddress,
        ownerPhone: _widgetSettings!.contactOptions.phoneNumber,
        customLogoUrl: _widgetSettings!.themeOptions?.customLogoUrl,
      ),
    );

    // Send owner notification (if enabled)
    if (_widgetSettings!.emailConfig.sendOwnerNotification) {
      final ownerEmail = _widgetSettings!.emailConfig.fromEmail;
      if (ownerEmail != null) {
        unawaited(
          emailService.sendOwnerNotificationEmail(
            booking: booking,
            emailConfig: _widgetSettings!.emailConfig,
            propertyName: propertyName,
            bookingReference: bookingReference,
            ownerEmail: ownerEmail,
            requiresApproval: requiresApproval,
            customLogoUrl: _widgetSettings!.themeOptions?.customLogoUrl,
          ),
        );
      }
    }

    emailService.dispose();
  }

  Future<void> _handleStripePayment({
    required String bookingId,
    required String bookingReference,
    required String guestEmail,
  }) async {
    final isDarkMode = ref.watch(themeProvider);

    try {
      final stripeService = ref.read(stripeServiceProvider);

      // Build return URL with confirmation parameters
      // Include full booking ID to fetch from Firestore after Stripe return
      final baseUrl = Uri.base;
      final returnUrl = Uri(
        scheme: baseUrl.scheme,
        host: baseUrl.host,
        port: baseUrl.port,
        path: baseUrl.path,
        queryParameters: {
          ...baseUrl.queryParameters,
          'confirmation': bookingReference,
          'bookingId': bookingId, // Full booking ID for Firestore fetch
          'email': guestEmail,
          'payment': 'stripe',
        },
      ).toString();

      final checkoutResult = await stripeService.createCheckoutSession(
        bookingId: bookingId,
        returnUrl: returnUrl,
      );

      // Redirect to Stripe Checkout
      final uri = Uri.parse(checkoutResult.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Stripe Checkout';
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Error launching Stripe: $e',
          isDarkMode: isDarkMode,
        );
      }
    }
  }

  /// Show confirmation screen after Stripe return
  /// Fetches booking from Firestore using booking ID and displays confirmation
  Future<void> _showConfirmationFromUrl(
    String bookingReference,
    String guestEmail,
    String bookingId,
  ) async {
    final isDarkMode = ref.watch(themeProvider);

    try {
      // Fetch booking from Firestore using booking ID
      final bookingRepo = ref.read(bookingRepositoryProvider);
      var booking = await bookingRepo.fetchBookingById(bookingId);

      if (booking == null) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context: context,
            message:
                'Booking not found. Please check your email for confirmation.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      // Bug #40 Fix: Poll for webhook update if payment still pending
      // Stripe webhook may take a few seconds to process
      if (booking.paymentStatus == 'pending' ||
          booking.status == BookingStatus.pending) {
        LoggingService.log(
          '⚠️ Payment status pending after Stripe return, polling for webhook update...',
          tag: 'STRIPE_WEBHOOK_FALLBACK',
        );

        // Poll up to 10 times with 2-second intervals (20 seconds total)
        for (var i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 2));

          final updatedBooking = await bookingRepo.fetchBookingById(bookingId);
          if (updatedBooking == null) break;

          // Check if webhook has updated the booking
          if (updatedBooking.paymentStatus == 'paid' ||
              updatedBooking.status == BookingStatus.confirmed) {
            LoggingService.log(
              '✅ Webhook update detected after ${(i + 1) * 2} seconds',
              tag: 'STRIPE_WEBHOOK_FALLBACK',
            );
            booking = updatedBooking;
            break;
          }

          // Still pending, continue polling
          booking = updatedBooking;
        }

        // If still pending after polling, log warning but proceed
        if (booking?.paymentStatus == 'pending' ||
            booking?.status == BookingStatus.pending) {
          LoggingService.log(
            '⚠️ Webhook not received after 20 seconds. Showing confirmation with pending status.',
            tag: 'STRIPE_WEBHOOK_FALLBACK',
          );
        }
      }

      // Final null check (should never happen, but satisfies flow analysis)
      if (booking == null) return;

      // Create local non-null variable for use in closure
      final confirmedBooking = booking;

      // Navigate to confirmation screen
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingReference: bookingReference,
              guestEmail: confirmedBooking.guestEmail ?? guestEmail,
              guestName: confirmedBooking.guestName ?? 'Guest',
              checkIn: confirmedBooking.checkIn,
              checkOut: confirmedBooking.checkOut,
              totalPrice: confirmedBooking.totalPrice,
              nights: confirmedBooking.checkOut
                  .difference(confirmedBooking.checkIn)
                  .inDays,
              guests: confirmedBooking.guestCount,
              propertyName: _unit?.name ?? 'Property',
              unitName: _unit?.name,
              paymentMethod: 'stripe',
              booking: confirmedBooking,
              emailConfig: _widgetSettings?.emailConfig,
              widgetSettings: _widgetSettings,
            ),
          ),
        );

        // CRITICAL: Invalidate calendar cache after Stripe return
        // This ensures the calendar refreshes and shows newly booked dates
        ref.invalidate(realtimeYearCalendarProvider);
        ref.invalidate(realtimeMonthCalendarProvider);

        // Bug #53: Clear saved form data after successful booking
        await _clearFormData();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Error loading booking: $e',
          isDarkMode: isDarkMode,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// Check if rotate device overlay should be shown
  /// Returns true only when: year view + portrait orientation + narrow screen
  bool _shouldShowRotateOverlay(BuildContext context) {
    final currentView = ref.watch(calendarViewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    // Show only in year view
    if (currentView != CalendarViewType.year) return false;

    // Show only on narrow screens (mobile/tablet portrait)
    if (screenWidth >= 768) return false;

    // Show only in portrait mode (aspect ratio + orientation)
    // Use both orientation enum AND aspect ratio for iframe compatibility
    final isPortrait =
        orientation == Orientation.portrait || screenHeight > screenWidth;

    return isPortrait;
  }

  /// Open email verification dialog
  Future<void> _openVerificationDialog() async {
    final email = _emailController.text.trim();
    final isDarkMode = ref.read(themeProvider);

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailVerificationDialog(
        email: email,
        colors: MinimalistColorSchemeAdapter(dark: isDarkMode),
      ),
    );

    if (verified == true && mounted) {
      setState(() {
        _emailVerified = true;
      });
    }
  }
}
