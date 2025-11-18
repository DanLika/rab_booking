import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../providers/ical_sync_status_provider.dart';
import '../providers/additional_services_provider.dart';
import '../../domain/models/calendar_view_type.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/unit_model.dart';
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
import '../utils/form_validators.dart';
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

            // Bug Fix: Don't auto-show guest form from cache
            // User should explicitly select dates or click to open booking flow
            // Cached data is available but form stays hidden until user action
          }
        });

        LoggingService.log(
          '✅ Form data restored from cache',
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
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

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
      return Scaffold(
        backgroundColor: getColor(
          MinimalistColors.backgroundPrimary,
          MinimalistColorsDark.backgroundPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading booking widget...',
                style: TextStyle(
                  fontSize: 16,
                  color: getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen if validation failed
    if (_validationError != null) {
      return Scaffold(
        backgroundColor: getColor(
          MinimalistColors.backgroundPrimary,
          MinimalistColorsDark.backgroundPrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: getColor(
                    MinimalistColors.error,
                    MinimalistColorsDark.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Configuration Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _validationError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _validateUnitAndProperty,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getColor(
                      MinimalistColors.buttonPrimary,
                      MinimalistColorsDark.buttonPrimary,
                    ),
                    foregroundColor: getColor(
                      MinimalistColors.buttonPrimaryText,
                      MinimalistColorsDark.buttonPrimaryText,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

                      // Bug #67 Fix: iCal sync warning banner
                      _buildIcalSyncWarningInline(unitId, isDarkMode),

                      // Calendar - takes all available space
                      Expanded(
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
                                  });

                                  // Bug #53: Save form data after date selection
                                  _saveFormData();
                                },
                        ),
                      ),

                      // Contact pill card (calendar only mode - inline, below calendar)
                      if (widgetMode == WidgetMode.calendarOnly) ...[
                        const SizedBox(height: 12),
                        _buildContactPillCard(isDarkMode, screenWidth),
                        const SizedBox(height: 12),
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
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                // Floating draggable booking summary bar (booking modes - shown when dates selected)
                if (widgetMode != WidgetMode.calendarOnly &&
                    _checkIn != null &&
                    _checkOut != null)
                  _buildFloatingDraggablePillBar(
                    unitId,
                    constraints,
                    isDarkMode,
                  ),

                // Rotate device overlay - HIGHEST z-index, only for year view in portrait
                if (_shouldShowRotateOverlay(context))
                  _buildRotateDeviceOverlay(colors),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Bug #67 Fix: Build iCal sync warning banner (inline version for scrollable layout)
  /// Shows warning when external calendars (Airbnb/Booking.com) haven't been synced recently
  Widget _buildIcalSyncWarningInline(String unitId, bool isDarkMode) {
    final syncStatus = ref.watch(icalSyncStatusProvider(unitId));

    return syncStatus.when(
      data: (status) {
        // Don't show banner if no active feeds or recently synced (< 30 min)
        if (!status.hasActiveFeeds || !status.isStale) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? MinimalistColorsDark.statusPendingBackground
                    : MinimalistColors.statusPendingBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode
                      ? MinimalistColorsDark.statusPendingBorder
                      : MinimalistColors.statusPendingBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isDarkMode
                        ? MinimalistColorsDark.warning
                        : MinimalistColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status.displayText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? MinimalistColorsDark.statusPendingText
                            : MinimalistColors.statusPendingText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build contact info bar for calendar-only mode
  Widget _buildContactInfoBar(bool isDarkMode) {
    final contactOptions = _widgetSettings?.contactOptions;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? MinimalistColorsDark.backgroundPrimary
            : MinimalistColors.backgroundPrimary,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? MinimalistColorsDark.borderLight
                : MinimalistColors.borderLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom message
                  if (contactOptions?.customMessage != null &&
                      contactOptions!.customMessage!.isNotEmpty) ...[
                    Text(
                      contactOptions.customMessage!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? MinimalistColorsDark.textPrimary
                            : MinimalistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.m),
                  ],

                  // Contact methods heading
                  const Text(
                    'Contact us for booking:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MinimalistColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.s),

                  // Phone
                  if (contactOptions?.showPhone == true &&
                      contactOptions?.phoneNumber != null &&
                      contactOptions!.phoneNumber!.isNotEmpty)
                    _buildContactButton(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: contactOptions.phoneNumber!,
                      onTap: () =>
                          _launchUrl('tel:${contactOptions.phoneNumber}'),
                    ),

                  // Email
                  if (contactOptions?.showEmail == true &&
                      contactOptions?.emailAddress != null &&
                      contactOptions!.emailAddress!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.xs),
                      child: _buildContactButton(
                        icon: Icons.email,
                        label: 'Email',
                        value: contactOptions.emailAddress!,
                        onTap: () =>
                            _launchUrl('mailto:${contactOptions.emailAddress}'),
                      ),
                    ),

                  // WhatsApp
                  if (contactOptions?.showWhatsApp == true &&
                      contactOptions?.whatsAppNumber != null &&
                      contactOptions!.whatsAppNumber!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.xs),
                      child: _buildContactButton(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        value: contactOptions.whatsAppNumber!,
                        onTap: () => _launchUrl(
                          'https://wa.me/${contactOptions.whatsAppNumber}',
                        ),
                        color: const Color(0xFF25D366), // WhatsApp green
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build contact button with icon and value
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderTokens.circularMedium,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.s),
        decoration: BoxDecoration(
          border: Border.all(color: MinimalistColors.borderDefault),
          borderRadius: BorderTokens.circularMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? MinimalistColors.textPrimary, size: 24),
            const SizedBox(width: SpacingTokens.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MinimalistColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MinimalistColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: MinimalistColors.textSecondary,
            ),
          ],
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
    final isDesktop = screenWidth > 600;

    // Dynamic max width: 400px for desktop, 170px for mobile
    final maxWidth = isDesktop ? 400.0 : 170.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(8),
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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isDesktop
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
      children: [
        // Email
        if (hasEmail)
          Expanded(
            child: _buildContactItem(
              icon: Icons.email,
              value: contactOptions.emailAddress!,
              onTap: () => _launchUrl('mailto:${contactOptions.emailAddress}'),
              isDarkMode: isDarkMode,
            ),
          ),

        // Vertical divider
        if (hasEmail && hasPhone)
          Container(
            height: 40,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: isDarkMode
                ? MinimalistColorsDark.borderDefault
                : MinimalistColors.borderDefault,
          ),

        // Phone
        if (hasPhone)
          Expanded(
            child: _buildContactItem(
              icon: Icons.phone,
              value: contactOptions.phoneNumber!,
              onTap: () => _launchUrl('tel:${contactOptions.phoneNumber}'),
              isDarkMode: isDarkMode,
            ),
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
          _buildContactItem(
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
          _buildContactItem(
            icon: Icons.phone,
            value: contactOptions.phoneNumber!,
            onTap: () => _launchUrl('tel:${contactOptions.phoneNumber}'),
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  /// Contact item widget (clickable with icon and value)
  Widget _buildContactItem({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode
                  ? MinimalistColorsDark.buttonPrimary
                  : MinimalistColors.buttonPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? MinimalistColorsDark.textPrimary
                      : MinimalistColors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            behavior:
                HitTestBehavior.translucent, // Better hit test for dragging
            onPanStart: (_) {
              // Provide haptic feedback on drag start
              HapticFeedback.selectionClick();
            },
            onPanUpdate: (details) {
              setState(() {
                // Allow dragging beyond screen bounds - pill bar will hide if off-screen
                _pillBarPosition = Offset(
                  position.dx + details.delta.dx,
                  position.dy + details.delta.dy,
                );
              });
            },
            onPanEnd: (_) {
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
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: pillBarWidth,
                height: maxHeight, // Fixed height based on screen
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? MinimalistColorsDark.backgroundPrimary
                      : MinimalistColors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDarkMode
                        ? MinimalistColorsDark.borderLight
                        : MinimalistColors.borderLight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      // Bug #46: Add keyboard height to bottom padding
                      8 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _buildPillBarContent(calculation, isDarkMode),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Build the content of the pill bar (dates, price, buttons)
  Widget _buildPillBarContent(
    BookingPriceCalculation calculation,
    bool isDarkMode,
  ) {
    // Check screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 768;

    // If guest form is shown and screen is wide, show 2-column layout
    if (_showGuestForm && isWideScreen) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar with drag handle and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              // Drag handle indicator (centered)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MinimalistColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              // Close button (right)
              InkWell(
                onTap: () {
                  setState(() {
                    _checkIn = null;
                    _checkOut = null;
                    _showGuestForm = false;
                    _pillBarPosition = null;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: MinimalistColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MinimalistColors.borderLight),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: MinimalistColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-column layout: Guest info (left) | Payment options (right)
          ConstrainedBox(
            constraints: BoxConstraints(
              // Bug #46: Account for keyboard when calculating max height
              maxHeight:
                  (MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom) *
                  0.6,
            ),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Guest info + Additional Services (55%)
                  Expanded(
                    flex: 55,
                    child: Column(
                      children: [
                        _buildGuestInfoForm(calculation, showButton: false),
                        // Additional Services section (only show if services exist)
                        Consumer(
                          builder: (context, ref, child) {
                            final servicesAsync = ref.watch(
                              unitAdditionalServicesProvider(_unitId),
                            );
                            return servicesAsync.when(
                              data: (services) {
                                if (services.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    const SizedBox(height: SpacingTokens.m),
                                    AdditionalServicesWidget(
                                      unitId: _unitId,
                                      nights: _checkOut!
                                          .difference(_checkIn!)
                                          .inDays,
                                      guests: _adults + _children,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        // Tax/Legal Disclaimer section
                        TaxLegalDisclaimerWidget(
                          propertyId: _propertyId ?? '',
                          unitId: _unitId,
                          onAcceptedChanged: (accepted) {
                            setState(() => _taxLegalAccepted = accepted);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.m),
                  // Right column: Payment options + button (45%)
                  Expanded(flex: 45, child: _buildPaymentSection(calculation)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Default: show compact summary
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactPillSummary(calculation),
        // Show guest form if needed (mobile)
        if (_showGuestForm && !isWideScreen) ...[
          const SizedBox(height: 12),
          _buildGuestInfoForm(calculation, showButton: false),
          // Additional Services section - only show if services exist
          Consumer(
            builder: (context, ref, _) {
              final servicesAsync = ref.watch(
                unitAdditionalServicesProvider(_unitId),
              );
              return servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return const SizedBox.shrink();
                  }
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
                error: (_, stackTrace) => const SizedBox.shrink(),
              );
            },
          ),
          // Tax/Legal Disclaimer section
          TaxLegalDisclaimerWidget(
            propertyId: _propertyId ?? '',
            unitId: _unitId,
            onAcceptedChanged: (accepted) {
              setState(() => _taxLegalAccepted = accepted);
            },
          ),
          const SizedBox(height: SpacingTokens.m),
          _buildPaymentSection(calculation),
        ],
      ],
    );
  }

  /// Build compact pill summary (dates, price, buttons) - redesigned
  Widget _buildCompactPillSummary(BookingPriceCalculation calculation) {
    final nights = _checkOut!.difference(_checkIn!).inDays;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

    return Column(
      children: [
        // Close button at top
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _checkIn = null;
                  _checkOut = null;
                  _showGuestForm = false;
                  _pillBarPosition = null;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: getColor(
                    MinimalistColors.backgroundSecondary,
                    ColorTokens.pureWhite,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: getColor(
                      MinimalistColors.borderLight,
                      MinimalistColorsDark.borderLight,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: getColor(
                    MinimalistColors.textSecondary,
                    ColorTokens.pureBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Range info with nights badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: getColor(
              MinimalistColors.buttonPrimary,
              MinimalistColorsDark.buttonPrimary,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: getColor(
                MinimalistColors.buttonPrimary,
                MinimalistColorsDark.buttonPrimary,
              ).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month,
                size: 18,
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dateFormat.format(_checkIn!)} - ${dateFormat.format(_checkOut!)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: getColor(
                    MinimalistColors.buttonPrimary,
                    MinimalistColorsDark.buttonPrimary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$nights ${nights == 1 ? 'night' : 'nights'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: getColor(
                      MinimalistColors.buttonPrimaryText,
                      MinimalistColorsDark.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Price breakdown section
        _buildPriceBreakdown(calculation, isDarkMode, getColor),

        const SizedBox(height: 12),

        // Reserve button (only show when guest form is NOT visible)
        if (!_showGuestForm)
          InkWell(
            onTap: () {
              // Bug #64: Lock price when user starts booking process
              setState(() {
                _showGuestForm = true;
                _lockedPriceCalculation = calculation.copyWithLock();
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Reserve',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: getColor(
                    MinimalistColors.buttonPrimaryText,
                    MinimalistColorsDark.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build price breakdown (room + services + total + deposit)
  Widget _buildPriceBreakdown(
    BookingPriceCalculation calculation,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    // Calculate deposit percentage from amounts
    final depositPercentage = calculation.totalPrice > 0
        ? ((calculation.depositAmount / calculation.totalPrice) * 100).round()
        : 20;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
      ),
      child: Column(
        children: [
          // Room price
          _buildPriceRow(
            'Room (${calculation.nights} ${calculation.nights == 1 ? 'night' : 'nights'})',
            calculation.formattedRoomPrice,
            isDarkMode,
            getColor,
          ),

          // Additional services (only show if > 0)
          if (calculation.additionalServicesTotal > 0) ...[
            const SizedBox(height: SpacingTokens.s),
            _buildPriceRow(
              'Additional Services',
              calculation.formattedAdditionalServices,
              isDarkMode,
              getColor,
              color: getColor(
                MinimalistColors.statusAvailableBorder,
                MinimalistColorsDark.statusAvailableBorder,
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            child: Divider(
              height: 1,
              color: getColor(
                MinimalistColors.borderDefault,
                MinimalistColorsDark.borderDefault,
              ),
            ),
          ),

          // Total
          _buildPriceRow(
            'Total',
            calculation.formattedTotal,
            isDarkMode,
            getColor,
            isBold: true,
          ),

          // Deposit info
          const SizedBox(height: SpacingTokens.s),
          Text(
            'Deposit: ${calculation.formattedDeposit} ($depositPercentage%)',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXS,
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build price row
  Widget _buildPriceRow(
    String label,
    String amount,
    bool isDarkMode,
    Color Function(Color, Color) getColor, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold
                ? TypographyTokens.fontSizeM
                : TypographyTokens.fontSizeS,
            color:
                color ??
                getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold
                ? TypographyTokens.fontSizeL
                : TypographyTokens.fontSizeS,
            color:
                color ??
                getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  /// Build payment section (payment options + confirm button)
  Widget _buildPaymentSection(BookingPriceCalculation calculation) {
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

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
          Container(
            padding: const EdgeInsets.all(SpacingTokens.m),
            decoration: BoxDecoration(
              color: getColor(
                MinimalistColors.error,
                MinimalistColorsDark.error,
              ).withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(
                color: getColor(
                  MinimalistColors.error,
                  MinimalistColorsDark.error,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: getColor(
                    MinimalistColors.error,
                    MinimalistColorsDark.error,
                  ),
                  size: 24,
                ),
                const SizedBox(width: SpacingTokens.s),
                Expanded(
                  child: Text(
                    'No payment methods available. Please contact property owner.',
                    style: TextStyle(
                      fontSize: 14,
                      color: getColor(
                        MinimalistColors.error,
                        MinimalistColorsDark.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                return Container(
                  margin: const EdgeInsets.only(top: SpacingTokens.m),
                  padding: const EdgeInsets.all(SpacingTokens.m),
                  decoration: BoxDecoration(
                    color: getColor(
                      MinimalistColors.error.withValues(alpha: 0.1),
                      MinimalistColorsDark.error.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderTokens.circularMedium,
                    border: Border.all(
                      color: getColor(
                        MinimalistColors.error,
                        MinimalistColorsDark.error,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: getColor(
                          MinimalistColors.error,
                          MinimalistColorsDark.error,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.s),
                      Expanded(
                        child: Text(
                          'No payment methods are currently configured. Please contact the property owner to complete your booking.',
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeS,
                            color: getColor(
                              MinimalistColors.error,
                              MinimalistColorsDark.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
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
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.m),
                      decoration: BoxDecoration(
                        color: getColor(
                          MinimalistColors.backgroundSecondary,
                          MinimalistColorsDark.backgroundSecondary,
                        ),
                        borderRadius: BorderTokens.circularMedium,
                        border: Border.all(
                          color: getColor(
                            MinimalistColors.borderDefault,
                            MinimalistColorsDark.borderDefault,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            singleMethod == 'stripe'
                                ? Icons.credit_card
                                : singleMethod == 'bank_transfer'
                                ? Icons.account_balance
                                : Icons.home_outlined,
                            color: getColor(
                              MinimalistColors.textPrimary,
                              MinimalistColorsDark.textPrimary,
                            ),
                            size: 24,
                          ),
                          const SizedBox(width: SpacingTokens.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  singleMethodTitle!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: getColor(
                                      MinimalistColors.textPrimary,
                                      MinimalistColorsDark.textPrimary,
                                    ),
                                  ),
                                ),
                                if (singleMethodSubtitle != null)
                                  Text(
                                    singleMethodSubtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: getColor(
                                        MinimalistColors.textSecondary,
                                        MinimalistColorsDark.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    _buildPaymentOption(
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Instant confirmation via Stripe',
                      value: 'stripe',
                      depositAmount: calculation.formattedDeposit,
                    ),

                  // Bank Transfer option
                  if (isBankTransferEnabled)
                    Padding(
                      padding: EdgeInsets.only(
                        top: isStripeEnabled ? SpacingTokens.s : 0,
                      ),
                      child: _buildPaymentOption(
                        icon: Icons.account_balance,
                        title: 'Bank Transfer',
                        subtitle: 'Manual confirmation (3 business days)',
                        value: 'bank_transfer',
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
                      child: _buildPaymentOption(
                        icon: Icons.home_outlined,
                        title: 'Pay on Arrival',
                        subtitle: 'Pay at the property',
                        value: 'pay_on_arrival',
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.s,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: MinimalistColors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(color: MinimalistColors.borderDefault),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline,
                    color: MinimalistColors.textSecondary,
                    size: 16,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your booking will be pending until confirmed by the property owner',
                    style: TextStyle(
                      fontSize: 12,
                      color: MinimalistColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
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
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Name field
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  maxLength: 50, // Bug #60: Maximum field length validation
                  style: TextStyle(
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                  decoration: InputDecoration(
                    counterText: '', // Hide character counter
                    labelText: 'First Name *',
                    hintText: 'John',
                    labelStyle: TextStyle(
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                    hintStyle: TextStyle(
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
                    ),
                    filled: true,
                    fillColor: getColor(
                      MinimalistColors.backgroundSecondary,
                      MinimalistColorsDark.backgroundSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: BorderSide(
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: BorderSide(
                        color: getColor(
                          MinimalistColors.textSecondary,
                          MinimalistColorsDark.textSecondary,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: BorderSide(
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      height: 1.0,
                    ),
                    errorMaxLines: 1,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                  // Real-time validation
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: FirstNameValidator.validate,
                ),
              ),
              const SizedBox(width: SpacingTokens.m),
              // Last Name field
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  maxLength: 50, // Bug #60: Maximum field length validation
                  style: TextStyle(
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                  decoration: InputDecoration(
                    counterText: '', // Hide character counter
                    labelText: 'Last Name *',
                    hintText: 'Doe',
                    labelStyle: TextStyle(
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                    hintStyle: TextStyle(
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
                    ),
                    filled: true,
                    fillColor: getColor(
                      MinimalistColors.backgroundSecondary,
                      MinimalistColorsDark.backgroundSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: BorderSide(
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: BorderSide(
                        color: getColor(
                          MinimalistColors.textSecondary,
                          MinimalistColorsDark.textSecondary,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: BorderSide(
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      height: 1.0,
                    ),
                    errorMaxLines: 1,
                  ),
                  // Real-time validation
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: LastNameValidator.validate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email field with verification (if required)
          _buildEmailFieldWithVerification(isDarkMode),
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
                ).withValues(alpha: 0.3),
              ),
              const SizedBox(width: SpacingTokens.s),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  maxLength: 20, // Bug #60: Maximum field length validation
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    PhoneNumberFormatter(_selectedCountry.dialCode),
                  ],
                  style: TextStyle(
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                  decoration: InputDecoration(
                    counterText: '', // Hide character counter
                    labelText: 'Phone Number *',
                    hintText: '99 123 4567',
                    labelStyle: TextStyle(
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
                    ),
                    hintStyle: TextStyle(
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ).withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: getColor(
                      MinimalistColors.backgroundSecondary,
                      MinimalistColorsDark.backgroundSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderTokens.circularMedium,
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
                    ),
                  ),
                  // Real-time validation with country-specific rules
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    return PhoneValidator.validate(
                      value,
                      _selectedCountry.dialCode,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          // Special requests field
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 500,
            style: TextStyle(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
            decoration: InputDecoration(
              labelText: 'Special Requests (Optional)',
              hintText: 'Any special requirements or preferences...',
              labelStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
              hintStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ).withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: getColor(
                MinimalistColors.backgroundSecondary,
                MinimalistColorsDark.backgroundSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
              ),
              prefixIcon: Icon(
                Icons.notes,
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ), // Reduced by 10px total (5px top + 5px bottom)
            ),
          ),
          const SizedBox(height: SpacingTokens.m),

          // Guest count picker
          _buildGuestCountPicker(),
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

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    String? depositAmount, // Made nullable for "Pay on Arrival"
  }) {
    final isSelected = _selectedPaymentMethod == value;
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderTokens.circularMedium,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? getColor(
                    MinimalistColors.borderBlack,
                    MinimalistColorsDark.textPrimary,
                  )
                : getColor(
                    MinimalistColors.borderDefault,
                    MinimalistColorsDark.borderDefault,
                  ),
            width: isSelected
                ? BorderTokens.widthMedium
                : BorderTokens.widthThin,
          ),
          borderRadius: BorderTokens.circularMedium,
          color: isSelected
              ? getColor(
                  MinimalistColors.backgroundSecondary,
                  MinimalistColorsDark.backgroundSecondary,
                )
              : null,
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
                      ? getColor(
                          MinimalistColors.borderBlack,
                          MinimalistColorsDark.textPrimary,
                        )
                      : getColor(
                          MinimalistColors.textSecondary,
                          MinimalistColorsDark.textSecondary,
                        ),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: getColor(
                            MinimalistColors.buttonPrimary,
                            MinimalistColorsDark.buttonPrimary,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: SpacingTokens.s),

            // Icon
            Icon(
              icon,
              color: isSelected
                  ? getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    )
                  : getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
                    ),
              size: 28,
            ),
            const SizedBox(width: SpacingTokens.s),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    subtitle,
                    maxLines: 2,
                    minFontSize: 10,
                    maxFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Deposit amount (only show if not null)
            if (depositAmount != null)
              Text(
                depositAmount,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmBooking(
    BookingPriceCalculation calculation,
  ) async {
    final isDarkMode = ref.watch(themeProvider);

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate email verification if required
    final requireEmailVerification =
        _widgetSettings?.emailConfig.requireEmailVerification ?? false;
    if (requireEmailVerification && !_emailVerified) {
      SnackBarHelper.showError(
        context: context,
        message: 'Please verify your email before booking',
        isDarkMode: isDarkMode,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Bug #68: Validate Tax/Legal disclaimer acceptance if required
    final taxConfig = _widgetSettings?.taxLegalConfig;
    if (taxConfig != null && taxConfig.enabled && !_taxLegalAccepted) {
      SnackBarHelper.showError(
        context: context,
        message: 'Please accept the tax and legal obligations before booking',
        isDarkMode: isDarkMode,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // Bug #64: Check if price changed since user started booking
    if (_lockedPriceCalculation != null) {
      final priceDelta =
          calculation.totalPrice - _lockedPriceCalculation!.totalPrice;
      if (priceDelta.abs() > 0.01) {
        // 1 cent tolerance
        final priceIncreased = priceDelta > 0;
        final changeAmount = priceDelta.abs().toStringAsFixed(2);

        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                priceIncreased ? '⚠️ Price Increased' : 'ℹ️ Price Decreased',
                style: TextStyle(
                  color: priceIncreased ? Colors.orange : Colors.blue,
                ),
              ),
              content: Text(
                priceIncreased
                    ? 'The price has increased by €$changeAmount since you started booking.\n\n'
                          'Original: €${_lockedPriceCalculation!.totalPrice.toStringAsFixed(2)}\n'
                          'Current: €${calculation.totalPrice.toStringAsFixed(2)}\n\n'
                          'Do you want to proceed with the new price?'
                    : 'Good news! The price decreased by €$changeAmount.\n\n'
                          'Original: €${_lockedPriceCalculation!.totalPrice.toStringAsFixed(2)}\n'
                          'Current: €${calculation.totalPrice.toStringAsFixed(2)}\n\n'
                          'Proceed with the new price?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: priceIncreased
                        ? Colors.orange
                        : Colors.blue,
                  ),
                  child: const Text('Proceed'),
                ),
              ],
            ),
          );

          if (confirmed != true) {
            // User cancelled - update locked price to current
            setState(() {
              _lockedPriceCalculation = calculation.copyWithLock();
            });
            return;
          }

          // User confirmed - update locked price to current
          setState(() {
            _lockedPriceCalculation = calculation.copyWithLock();
          });
        }
      }
    }

    // CRITICAL: Validate dates (check-in must be before check-out)
    if (_checkIn == null || _checkOut == null) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Please select check-in and check-out dates.',
          isDarkMode: isDarkMode,
        );
      }
      return;
    }

    if (_checkOut!.isBefore(_checkIn!) ||
        _checkOut!.isAtSameMomentAs(_checkIn!)) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Check-out must be after check-in date.',
          isDarkMode: isDarkMode,
        );
      }
      return;
    }

    // BUG #22: Validate same-day check-in timing
    // If check-in is today, ensure current time is before standard check-in time (3 PM)
    // Bug #65 Fix: Use UTC for DST-safe date comparison
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final checkInDate = DateTime.utc(
      _checkIn!.year,
      _checkIn!.month,
      _checkIn!.day,
    );

    if (checkInDate.isAtSameMomentAs(today)) {
      // Standard check-in time: 3 PM (15:00)
      final checkInTimeHour = 15; // 3 PM

      // If current time is after check-in time, show warning
      if (now.hour >= checkInTimeHour) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context: context,
            message:
                'Same-day check-in: Property check-in time is $checkInTimeHour:00. '
                'Please note that you may not be able to check in until tomorrow.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 7),
          );
        }
        // Don't block the booking, just show warning
        // User might contact owner to arrange late check-in
      }
    }

    // Validate that we have propertyId and ownerId (should already be fetched in initState)
    if (_propertyId == null || _ownerId == null) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Property information not loaded. Please refresh the page.',
          isDarkMode: isDarkMode,
        );
      }
      return;
    }

    // Validate payment method for bookingInstant mode
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;
    if (widgetMode == WidgetMode.bookingInstant) {
      final isStripeEnabled = _widgetSettings?.stripeConfig?.enabled == true;
      final isBankTransferEnabled =
          _widgetSettings?.bankTransferConfig?.enabled == true;
      final isPayOnArrivalEnabled = _widgetSettings?.allowPayOnArrival == true;

      // Check if at least one payment method is enabled
      if (!isStripeEnabled &&
          !isBankTransferEnabled &&
          !isPayOnArrivalEnabled) {
        if (mounted) {
          SnackBarHelper.showError(
            context: context,
            message:
                'No payment methods are currently available. Please contact the property owner.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      // Check if selected payment method is valid
      if (_selectedPaymentMethod == 'stripe' && !isStripeEnabled) {
        if (mounted) {
          SnackBarHelper.showError(
            context: context,
            message:
                'Stripe payment is not available. Please select another payment method.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      if (_selectedPaymentMethod == 'bank_transfer' && !isBankTransferEnabled) {
        if (mounted) {
          SnackBarHelper.showError(
            context: context,
            message:
                'Bank transfer is not available. Please select another payment method.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      if (_selectedPaymentMethod == 'pay_on_arrival' &&
          !(_widgetSettings?.allowPayOnArrival ?? false)) {
        if (mounted) {
          SnackBarHelper.showError(
            context: context,
            message:
                'Pay on arrival is not available. Please select another payment method.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }
    }

    // Validate guest count against property capacity
    final totalGuests = _adults + _children;
    final maxGuests = _unit?.maxGuests ?? 10;
    if (totalGuests > maxGuests) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message:
              'Maximum $maxGuests ${maxGuests == 1 ? 'guest' : 'guests'} allowed for this property. You selected $totalGuests ${totalGuests == 1 ? 'guest' : 'guests'}.',
          isDarkMode: isDarkMode,
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    // Validate minimum 1 adult required
    if (_adults == 0) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'At least 1 adult is required for booking.',
          isDarkMode: isDarkMode,
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Race condition is handled atomically by createBookingAtomic Cloud Function
      // Client-side checks are unsafe due to TOCTOU (Time-of-check-to-time-of-use)

      final widgetMode =
          _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;
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

        // Send email notifications (if configured and enabled)
        final emailConfig = _widgetSettings?.emailConfig;
        if (emailConfig?.enabled == true && emailConfig?.isConfigured == true) {
          final emailService = EmailNotificationService();
          final bookingReference = booking.id.substring(0, 8).toUpperCase();
          final propertyName = _unit?.name ?? 'Vacation Rental';

          // Send booking confirmation to guest
          unawaited(
            emailService.sendBookingConfirmationEmail(
              booking: booking,
              emailConfig: _widgetSettings!.emailConfig,
              propertyName: propertyName,
              bookingReference: bookingReference,
              bankTransferConfig: _widgetSettings!.bankTransferConfig,
              allowGuestCancellation: _widgetSettings!.allowGuestCancellation,
              cancellationDeadlineHours:
                  _widgetSettings!.cancellationDeadlineHours,
              ownerEmail: _widgetSettings!.contactOptions.emailAddress,
              ownerPhone: _widgetSettings!.contactOptions.phoneNumber,
              customLogoUrl: _widgetSettings!.themeOptions?.customLogoUrl,
            ),
          );

          // Send owner notification (if owner email is available and configured)
          if (_widgetSettings!.emailConfig.sendOwnerNotification) {
            // Get owner email from property or use configured email
            final ownerEmail = _widgetSettings!.emailConfig.fromEmail;
            if (ownerEmail != null) {
              unawaited(
                emailService.sendOwnerNotificationEmail(
                  booking: booking,
                  emailConfig: _widgetSettings!.emailConfig,
                  propertyName: propertyName,
                  bookingReference: bookingReference,
                  ownerEmail: ownerEmail,
                  requiresApproval: true,
                  customLogoUrl: _widgetSettings!.themeOptions?.customLogoUrl,
                ),
              );
            }
          }

          emailService.dispose();
        }

        // Navigate to confirmation screen
        if (mounted) {
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
                paymentMethod: 'pending',
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
      final emailConfigInstant = _widgetSettings?.emailConfig;
      if (emailConfigInstant?.enabled == true &&
          emailConfigInstant?.isConfigured == true) {
        final emailService = EmailNotificationService();
        final bookingReference = booking.id.substring(0, 8).toUpperCase();
        final propertyName = _unit?.name ?? 'Vacation Rental';

        // Calculate payment deadline (default 3 days from now)
        final paymentDeadlineDays =
            _widgetSettings?.bankTransferConfig?.paymentDeadlineDays ?? 3;
        final paymentDeadline = DateTime.now().add(
          Duration(days: paymentDeadlineDays),
        );
        final dateFormat = DateFormat('dd.MM.yyyy');

        unawaited(
          emailService.sendBookingConfirmationEmail(
            booking: booking,
            emailConfig: _widgetSettings!.emailConfig,
            propertyName: propertyName,
            bookingReference: bookingReference,
            paymentDeadline: dateFormat.format(paymentDeadline),
            paymentMethod: _selectedPaymentMethod,
            bankTransferConfig: _widgetSettings!.bankTransferConfig,
            allowGuestCancellation: _widgetSettings!.allowGuestCancellation,
            cancellationDeadlineHours:
                _widgetSettings!.cancellationDeadlineHours,
            ownerEmail: _widgetSettings!.contactOptions.emailAddress,
            ownerPhone: _widgetSettings!.contactOptions.phoneNumber,
            customLogoUrl: _widgetSettings!.themeOptions?.customLogoUrl,
          ),
        );

        // Send owner notification
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
                requiresApproval:
                    _widgetSettings?.requireOwnerApproval ?? false,
                customLogoUrl: _widgetSettings!.themeOptions?.customLogoUrl,
              ),
            );
          }
        }

        emailService.dispose();
      }

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
        if (mounted) {
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
                paymentMethod: 'bank_transfer',
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
      } else if (_selectedPaymentMethod == 'pay_on_arrival') {
        // Pay on Arrival - navigate to confirmation screen
        if (mounted) {
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
                paymentMethod: 'pay_on_arrival',
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

  Widget _buildGuestCountPicker() {
    final maxGuests =
        _unit?.maxGuests ?? 10; // Default to 10 if unit not loaded
    final totalGuests = _adults + _children;
    final isAtCapacity = totalGuests >= maxGuests;
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of Guests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
              if (_unit != null)
                Text(
                  'Max: ${_unit!.maxGuests}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isAtCapacity
                        ? getColor(
                            MinimalistColors.error,
                            MinimalistColorsDark.error,
                          )
                        : getColor(
                            MinimalistColors.textSecondary,
                            MinimalistColorsDark.textSecondary,
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),

          // Adults
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Adults',
                    style: TextStyle(
                      fontSize: 14,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _adults > 1
                        ? () {
                            setState(() {
                              _adults--;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_adults',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: !isAtCapacity && _adults < maxGuests
                        ? () {
                            setState(() {
                              _adults++;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: isAtCapacity
                          ? getColor(
                              MinimalistColors.textSecondary,
                              MinimalistColorsDark.textSecondary,
                            ).withValues(alpha: 0.5)
                          : getColor(
                              MinimalistColors.textPrimary,
                              MinimalistColorsDark.textPrimary,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Children
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.child_care,
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Children',
                    style: TextStyle(
                      fontSize: 14,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _children > 0
                        ? () {
                            setState(() {
                              _children--;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_children',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: !isAtCapacity && _children < maxGuests
                        ? () {
                            setState(() {
                              _children++;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: isAtCapacity
                          ? getColor(
                              MinimalistColors.textSecondary,
                              MinimalistColorsDark.textSecondary,
                            ).withValues(alpha: 0.5)
                          : getColor(
                              MinimalistColors.textPrimary,
                              MinimalistColorsDark.textPrimary,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Total guests display with capacity warning
          if (isAtCapacity) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: getColor(
                  MinimalistColors.error.withValues(alpha: 0.1),
                  MinimalistColorsDark.error.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: getColor(
                    MinimalistColors.error,
                    MinimalistColorsDark.error,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    color: getColor(
                      MinimalistColors.error,
                      MinimalistColorsDark.error,
                    ),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Max capacity: $maxGuests guests',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: getColor(
                        MinimalistColors.error,
                        MinimalistColorsDark.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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

  /// Build rotate device overlay - prompts user to rotate to landscape
  Widget _buildRotateDeviceOverlay(WidgetColorScheme colors) {
    final isDarkMode = ref.watch(themeProvider);
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

    return Positioned.fill(
      child: Container(
        color: getColor(
          MinimalistColors.backgroundPrimary,
          MinimalistColorsDark.backgroundPrimary,
        ).withValues(alpha: 0.95),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation,
                  size: 80,
                  color: colors.textPrimary, // Black (light) / White (dark)
                ),
                const SizedBox(height: SpacingTokens.l),
                Text(
                  'Rotate Your Device',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXXL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.m),
                Text(
                  'For the best year view experience, please rotate your device to landscape mode.',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.xl),
                ElevatedButton(
                  onPressed: () {
                    // Switch to month view
                    ref.read(calendarViewProvider.notifier).state =
                        CalendarViewType.month;
                  },
                  style: ElevatedButton.styleFrom(
                    // Black button (light theme) / White button (dark theme)
                    backgroundColor: isDarkMode
                        ? ColorTokens.pureWhite
                        : ColorTokens.pureBlack,
                    foregroundColor: isDarkMode
                        ? ColorTokens.pureBlack
                        : ColorTokens.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xl,
                      vertical: SpacingTokens.m,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderTokens.circularMedium,
                    ),
                  ),
                  child: const Text(
                    'Switch to Month View',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeM,
                      fontWeight: TypographyTokens.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build email field with verification button (if required)
  Widget _buildEmailFieldWithVerification(bool isDarkMode) {
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;
    final requireVerification =
        _widgetSettings?.emailConfig.requireEmailVerification ?? false;

    if (!requireVerification) {
      // Standard email field without verification
      return TextFormField(
        controller: _emailController,
        maxLength: 100, // Bug #60: Maximum field length validation
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: getColor(
            MinimalistColors.textPrimary,
            MinimalistColorsDark.textPrimary,
          ),
        ),
        decoration: InputDecoration(
          counterText: '', // Hide character counter
          labelText: 'Email *',
          hintText: 'john@example.com',
          labelStyle: TextStyle(
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
          hintStyle: TextStyle(
            color: getColor(
              MinimalistColors.textSecondary,
              MinimalistColorsDark.textSecondary,
            ),
          ),
          filled: true,
          fillColor: getColor(
            MinimalistColors.backgroundSecondary,
            MinimalistColorsDark.backgroundSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: BorderSide(
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: BorderSide(
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: BorderSide(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            height: 1.0,
          ),
          errorMaxLines: 1,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: EmailValidator.validate,
        onChanged: (value) {
          // Reset verification when email changes
          if (_emailVerified) {
            setState(() {
              _emailVerified = false;
            });
          }
        },
      );
    }

    // Email field with verification button
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _emailController,
            maxLength: 100, // Bug #60: Maximum field length validation
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
            decoration: InputDecoration(
              counterText: '', // Hide character counter
              labelText: 'Email *',
              hintText: 'john@example.com',
              labelStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
              hintStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
              filled: true,
              fillColor: getColor(
                MinimalistColors.backgroundSecondary,
                MinimalistColorsDark.backgroundSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                height: 1.0,
              ),
              errorMaxLines: 1,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: EmailValidator.validate,
            onChanged: (value) {
              // Reset verification when email changes
              if (_emailVerified) {
                setState(() {
                  _emailVerified = false;
                });
              }
            },
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        // Verification status/button (only shown if required in settings)
        if (_widgetSettings?.emailConfig.requireEmailVerification ?? false) ...[
          if (_emailVerified)
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: MinimalistColors.success.withValues(alpha: 0.1),
                borderRadius: BorderTokens.circularMedium,
                border: Border.all(color: MinimalistColors.success, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.verified,
                  color: MinimalistColors.success,
                  size: 24,
                ),
              ),
            )
          else
            SizedBox(
              width: 100,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                  foregroundColor: getColor(
                    MinimalistColors.backgroundPrimary,
                    MinimalistColorsDark.backgroundPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderTokens.circularMedium,
                  ),
                ),
                child: const Text('Verify'),
              ),
            ),
        ],
      ],
    );
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
