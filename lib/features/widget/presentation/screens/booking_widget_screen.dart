import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/web_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
// Cross-tab communication service (uses conditional import via web_utils)
import '../../../../core/services/tab_communication_service.dart';
import '../../services/form_persistence_service.dart';
import '../../state/booking_form_state.dart';
import '../widgets/calendar_view_switcher.dart';
import '../widgets/additional_services_widget.dart';
import '../widgets/tax_legal_disclaimer_widget.dart';
import '../providers/booking_price_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../providers/additional_services_provider.dart';
import '../providers/submit_booking_provider.dart';
import '../providers/subdomain_provider.dart';
import '../../domain/use_cases/submit_booking_use_case.dart';
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
// EmailNotificationService now used via EmailNotificationHelper
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/utils/validators/form_validators.dart';
import 'booking_confirmation_screen.dart';
import '../widgets/country_code_dropdown.dart';
import '../widgets/email_verification_dialog.dart';
import '../../data/services/email_verification_service.dart';
import '../widgets/common/rotate_device_overlay.dart';
import '../widgets/common/loading_screen.dart';
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
import '../widgets/booking/contact_pill_card_widget.dart';
// MinimalistColorSchemeAdapter is already imported via minimalist_colors.dart
import '../../../../shared/utils/ui/snackbar_helper.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../l10n/widget_translations.dart';

/// Main booking widget screen that shows responsive calendar
/// Automatically switches between year/month/week views based on screen size
///
/// Supports two URL formats:
/// 1. Query params: `?property=PROPERTY_ID&unit=UNIT_ID` (iframe embeds)
/// 2. Slug URL: `/apartman-6` with subdomain (standalone pages)
///
/// When [urlSlug] is provided, the screen resolves property from subdomain
/// and unit from slug. Otherwise, it uses query parameters.
class BookingWidgetScreen extends ConsumerStatefulWidget {
  const BookingWidgetScreen({
    super.key,
    this.urlSlug,
  });

  /// Optional URL slug for clean URL resolution.
  /// When provided, property is resolved from subdomain and unit from this slug.
  final String? urlSlug;

  @override
  ConsumerState<BookingWidgetScreen> createState() => _BookingWidgetScreenState();
}

class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
  // ============================================
  // URL SANITIZATION HELPER
  // ============================================
  /// Sanitize ID from URL - removes any path segments (e.g., /calendar suffix)
  /// This prevents Firestore "invalid document reference" errors
  static String? _sanitizeId(String? id) {
    if (id == null || id.isEmpty) return id;
    final slashIndex = id.indexOf('/');
    if (slashIndex > 0) {
      return id.substring(0, slashIndex);
    }
    return id;
  }

  // ============================================
  // UNIT & PROPERTY DATA
  // ============================================
  late String _unitId;
  String? _propertyId;
  String? _ownerId;
  UnitModel? _unit; // Store unit data for guest validation
  WidgetSettings? _widgetSettings; // Widget settings (loaded from Firestore)

  // ============================================
  // VALIDATION STATE
  // ============================================
  bool _isValidating = true;
  String? _validationError;

  // ============================================
  // FORM STATE (centralized in BookingFormState)
  // ============================================
  final _formState = BookingFormState();

  // Convenience getters for backward compatibility during refactoring
  DateTime? get _checkIn => _formState.checkIn;
  set _checkIn(DateTime? value) => _formState.checkIn = value;
  DateTime? get _checkOut => _formState.checkOut;
  set _checkOut(DateTime? value) => _formState.checkOut = value;
  GlobalKey<FormState> get _formKey => _formState.formKey;
  TextEditingController get _firstNameController => _formState.firstNameController;
  TextEditingController get _lastNameController => _formState.lastNameController;
  TextEditingController get _emailController => _formState.emailController;
  TextEditingController get _phoneController => _formState.phoneController;
  TextEditingController get _notesController => _formState.notesController;
  Country get _selectedCountry => _formState.selectedCountry;
  set _selectedCountry(Country value) => _formState.selectedCountry = value;
  int get _adults => _formState.adults;
  set _adults(int value) => _formState.adults = value;
  int get _children => _formState.children;
  set _children(int value) => _formState.children = value;
  bool get _showGuestForm => _formState.showGuestForm;
  set _showGuestForm(bool value) => _formState.showGuestForm = value;
  String get _selectedPaymentMethod => _formState.selectedPaymentMethod;
  set _selectedPaymentMethod(String value) => _formState.selectedPaymentMethod = value;
  String get _selectedPaymentOption => _formState.selectedPaymentOption;
  bool get _isProcessing => _formState.isProcessing;
  set _isProcessing(bool value) => _formState.isProcessing = value;
  bool get _emailVerified => _formState.emailVerified;
  set _emailVerified(bool value) => _formState.emailVerified = value;
  bool get _taxLegalAccepted => _formState.taxLegalAccepted;
  set _taxLegalAccepted(bool value) => _formState.taxLegalAccepted = value;
  BookingPriceCalculation? get _lockedPriceCalculation => _formState.lockedPriceCalculation;
  set _lockedPriceCalculation(BookingPriceCalculation? value) => _formState.lockedPriceCalculation = value;
  Offset? get _pillBarPosition => _formState.pillBarPosition;
  set _pillBarPosition(Offset? value) => _formState.pillBarPosition = value;
  bool get _pillBarDismissed => _formState.pillBarDismissed;
  set _pillBarDismissed(bool value) => _formState.pillBarDismissed = value;
  bool get _hasInteractedWithBookingFlow => _formState.hasInteractedWithBookingFlow;
  set _hasInteractedWithBookingFlow(bool value) => _formState.hasInteractedWithBookingFlow = value;

  // ============================================
  // THEME DETECTION
  // ============================================
  // Flag to track if system theme has been detected (prevents override after manual toggle)
  bool _hasDetectedSystemTheme = false;

  // ============================================
  // FORM PERSISTENCE (debounced to prevent race conditions)
  // ============================================
  Timer? _saveDebounce;
  bool _isDisposed = false;

  // ============================================
  // CROSS-TAB COMMUNICATION
  // ============================================
  // Cross-tab communication for Stripe payments
  // When payment completes in one tab, other tabs are notified to update UI
  TabCommunicationService? _tabCommunicationService;
  StreamSubscription<TabMessage>? _tabMessageSubscription;

  @override
  void initState() {
    super.initState();
    // Parse property and unit IDs from URL
    // Priority: 1. URL slug (clean URLs), 2. Query parameters (iframe embeds)
    final uri = Uri.base;

    // Check if using slug-based URL (will be resolved in _validateUnitAndProperty)
    if (widget.urlSlug != null && widget.urlSlug!.isNotEmpty) {
      // Slug URL: property resolved from subdomain, unit from slug
      // IDs will be set after async resolution in _validateUnitAndProperty
      _propertyId = null;
      _unitId = '';
    } else {
      // Query params URL: direct IDs from URL
      _propertyId = _sanitizeId(uri.queryParameters['property']);
      _unitId = _sanitizeId(uri.queryParameters['unit']) ?? '';
    }

    // Bug #53: Add listeners to text controllers for auto-save (debounced)
    _firstNameController.addListener(_saveFormDataDebounced);
    _lastNameController.addListener(_saveFormDataDebounced);
    _emailController.addListener(_saveFormDataDebounced);
    _phoneController.addListener(_saveFormDataDebounced);
    _notesController.addListener(_saveFormDataDebounced);

    // Initialize cross-tab communication for web platform
    _initTabCommunication();

    // Check for booking confirmation parameters (all payment types)
    final confirmationRef = uri.queryParameters['confirmation'];
    final confirmationEmail = uri.queryParameters['email'];
    final bookingId = uri.queryParameters['bookingId'];
    final paymentType = uri.queryParameters['payment'];
    final stripeStatus = uri.queryParameters['stripe_status'];
    final stripeSessionId = uri.queryParameters['session_id'];
    final bookingStatus = uri.queryParameters['booking_status'];

    // Check if this is a Stripe return (NEW FLOW - booking created by webhook)
    // URL has: stripe_status=success&session_id=cs_xxx but NO bookingId
    // We need to poll for booking using session_id
    final isStripeReturn = stripeStatus == 'success' && stripeSessionId != null;

    // Legacy Stripe return (old flow - booking created before checkout)
    final hasLegacyStripeParams =
        confirmationRef != null &&
        confirmationEmail != null &&
        bookingId != null &&
        (paymentType == 'stripe' || stripeStatus == 'success');

    // Check if this is a direct booking return (same tab - Pay on Arrival, Bank Transfer)
    final isDirectBookingReturn = bookingStatus == 'success' && confirmationRef != null && bookingId != null;

    // Validate unit and property immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // NEW: Stripe return with session_id (webhook creates booking)
      // This is the new flow where booking doesn't exist at checkout time
      if (isStripeReturn && !hasLegacyStripeParams) {
        // Clear any cached form data first (prevents conflict with booked dates)
        await _clearFormData();

        await _handleStripeReturnWithSessionId(stripeSessionId);
        return; // Don't continue with normal initialization
      }

      // Legacy Stripe return (old flow with bookingId in URL)
      if (hasLegacyStripeParams) {
        await _clearFormData();

        await _showConfirmationFromUrl(confirmationRef, confirmationEmail, bookingId);
        return; // Don't continue with normal initialization
      }

      // If this is a direct booking return (same tab), show confirmation
      if (isDirectBookingReturn) {
        await _showConfirmationFromUrl(
          confirmationRef,
          confirmationEmail ?? '',
          bookingId,
          paymentMethod: paymentType,
          isDirectBooking: true,
        );
        return; // Don't continue with normal initialization
      }

      // Normal initialization for fresh page load
      await _validateUnitAndProperty();

      // Bug #53: Load saved form data if page was refreshed
      await _loadFormData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect system theme on first load (only once to preserve manual toggle)
    if (!_hasDetectedSystemTheme) {
      _hasDetectedSystemTheme = true;
      final brightness = MediaQuery.of(context).platformBrightness;
      final isSystemDark = brightness == Brightness.dark;
      // Set theme provider to match system theme
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(themeProvider.notifier).state = isSystemDark;
        }
      });
    }
  }

  /// Initialize cross-tab communication service for Stripe payment notifications
  /// Only runs on web platform - uses BroadcastChannel API
  void _initTabCommunication() {
    if (!kIsWeb) return; // Only on web platform

    try {
      // LOW: Cancel any existing subscription to prevent memory leak
      // (safety measure in case this method is called multiple times)
      _tabMessageSubscription?.cancel();
      _tabCommunicationService?.dispose();

      // Create platform-appropriate service instance
      // (createTabCommunicationService uses conditional import)
      _tabCommunicationService = createTabCommunicationService();

      // Listen for messages from other tabs
      _tabMessageSubscription = _tabCommunicationService!.messageStream.listen(_handleTabMessage);

      LoggingService.log('[CrossTab] Initialized cross-tab communication listener', tag: 'TAB_COMM');
    } catch (e) {
      LoggingService.log('[CrossTab] Failed to initialize: $e', tag: 'TAB_COMM_ERROR');
    }
  }

  /// Handle messages received from other browser tabs
  /// When payment completes in Tab B, this tab (Tab A) receives the notification
  void _handleTabMessage(TabMessage message) {
    // SAFETY: Check mounted before handling tab messages
    // Stream may fire after widget disposal
    if (!mounted) return;

    LoggingService.log('[CrossTab] Received message: ${message.type}', tag: 'TAB_COMM');

    switch (message.type) {
      case TabMessageType.paymentComplete:
        _handlePaymentCompleteFromOtherTab(message);
        break;
      case TabMessageType.bookingCancelled:
        // Refresh calendar when booking is cancelled in another tab
        ref.invalidate(realtimeYearCalendarProvider);
        ref.invalidate(realtimeMonthCalendarProvider);
        break;
      case TabMessageType.calendarRefresh:
        // Refresh calendar data
        ref.invalidate(realtimeYearCalendarProvider);
        ref.invalidate(realtimeMonthCalendarProvider);
        break;
    }
  }

  /// Handle payment completion notification from another tab
  /// This is called when Tab B (Stripe return) broadcasts that payment is complete
  Future<void> _handlePaymentCompleteFromOtherTab(TabMessage message) async {
    final bookingId = message.bookingId;
    final bookingRef = message.bookingRef;
    final email = message.email;

    if (bookingId == null || bookingRef == null || email == null) {
      LoggingService.log('[CrossTab] Invalid payment complete message - missing params', tag: 'TAB_COMM_ERROR');
      return;
    }

    LoggingService.log('[CrossTab] Payment complete received for booking: $bookingRef', tag: 'TAB_COMM');

    // CRITICAL: Clear form data and reset state BEFORE showing confirmation
    // This prevents the bug where pressing "back" shows old form data
    await _clearFormData();
    _resetFormState();

    // Navigate to confirmation screen
    // Use the same method as URL-based confirmation
    // Pass fromOtherTab: true to prevent circular broadcasting
    if (mounted) {
      await _showConfirmationFromUrl(bookingRef, email, bookingId, fromOtherTab: true);
    }
  }

  /// Show dialog when Stripe payment succeeded but booking confirmation is delayed
  /// This provides clear instructions to the user instead of a dismissable snackbar
  Future<void> _showPaymentDelayedDialog() async {
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final dialogBg = isDarkMode ? ColorTokens.pureBlack : colors.backgroundPrimary;
    final tr = WidgetTranslations.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must acknowledge
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularLarge),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: colors.success, size: 28),
            const SizedBox(width: SpacingTokens.s),
            Expanded(
              child: Text(
                tr.paymentSuccessful,
                style: TextStyle(fontWeight: TypographyTokens.bold, color: colors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.paymentProcessedButDelayed,
              style: TextStyle(fontSize: TypographyTokens.fontSizeM, color: colors.textPrimary),
            ),
            const SizedBox(height: SpacingTokens.m),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.m),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderTokens.circularMedium,
                border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.whatToDoNext,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      fontWeight: TypographyTokens.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  _buildInstructionItem(tr.checkEmailForConfirmation, colors),
                  _buildInstructionItem(tr.checkSpamFolder, colors),
                  _buildInstructionItem(tr.contactOwnerIfNoEmail, colors),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonPrimary,
              foregroundColor: colors.buttonPrimaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
            ),
            child: Text(tr.iUnderstand),
          ),
        ],
      ),
    );
  }

  /// Helper to build instruction items for the payment delayed dialog
  Widget _buildInstructionItem(String text, WidgetColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.xs),
      child: Text(
        text,
        style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
      ),
    );
  }

  /// Clear booking-related URL params and reset to base URL
  void _clearBookingUrlParams() {
    if (!kIsWeb) return;

    try {
      final uri = Uri.base;
      // Keep only property and unit params
      final cleanParams = <String, String>{};
      if (uri.queryParameters.containsKey('property')) {
        cleanParams['property'] = uri.queryParameters['property']!;
      }
      if (uri.queryParameters.containsKey('unit')) {
        cleanParams['unit'] = uri.queryParameters['unit']!;
      }

      final newUri = uri.replace(queryParameters: cleanParams);
      replaceUrlState(newUri.toString());

      LoggingService.log('[URL] Cleared booking params, new URL: ${newUri.toString()}', tag: 'URL_PARAMS');
    } catch (e) {
      LoggingService.log('[URL] Failed to clear URL params: $e', tag: 'URL_PARAMS');
    }
  }

  /// Add booking confirmation params to URL (for browser history support)
  void _addBookingUrlParams({
    required String bookingRef,
    required String email,
    required String bookingId,
    required String paymentMethod,
  }) {
    if (!kIsWeb) return;

    try {
      final uri = Uri.base;
      final newParams = Map<String, String>.from(uri.queryParameters);

      // Add booking confirmation params
      newParams['booking_status'] = 'success';
      newParams['confirmation'] = bookingRef;
      newParams['email'] = email;
      newParams['bookingId'] = bookingId;
      newParams['payment'] = paymentMethod;

      final newUri = uri.replace(queryParameters: newParams);
      // Use pushState to add to browser history (back button works)
      pushUrlState(newUri.toString());

      LoggingService.log('[URL] Added booking params, new URL: ${newUri.toString()}', tag: 'URL_PARAMS');
    } catch (e) {
      LoggingService.log('[URL] Failed to add URL params: $e', tag: 'URL_PARAMS');
    }
  }

  /// Reset form state to initial values (clear all user input)
  void _resetFormState() {
    setState(_formState.resetState);

    // Reset selected additional services (provider-based)
    ref.invalidate(selectedAdditionalServicesProvider);

    // Invalidate calendar to refresh availability
    ref.invalidate(realtimeYearCalendarProvider);
    ref.invalidate(realtimeMonthCalendarProvider);

    LoggingService.log('[CrossTab] Form state reset after payment completion', tag: 'TAB_COMM');
  }

  /// Handle Stripe return when booking is created by webhook (NEW FLOW)
  /// URL has: stripe_status=success&session_id=cs_xxx but NO bookingId
  /// We need to poll Firestore until webhook creates the booking
  Future<void> _handleStripeReturnWithSessionId(String sessionId) async {
    LoggingService.log('[STRIPE_RETURN] Handling Stripe return with session_id: $sessionId', tag: 'STRIPE_SESSION');

    // Show loading state while we wait for webhook
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      BookingModel? booking;

      // Poll for booking created by webhook (max 30 seconds)
      // Webhook typically arrives within 1-5 seconds
      const maxAttempts = 15;
      const pollInterval = Duration(seconds: 2);

      for (var i = 0; i < maxAttempts; i++) {
        LoggingService.log(
          '[STRIPE_RETURN] Polling for booking (attempt ${i + 1}/$maxAttempts)...',
          tag: 'STRIPE_SESSION',
        );

        // Try to find booking by stripe_session_id
        booking = await bookingRepo.fetchBookingByStripeSessionId(sessionId);

        if (booking != null) {
          LoggingService.log(
            '[STRIPE_RETURN] ✅ Found booking: ${booking.id} (ref: ${booking.bookingReference})',
            tag: 'STRIPE_SESSION',
          );
          break;
        }

        // Not found yet, wait and try again
        if (i < maxAttempts - 1) {
          await Future.delayed(pollInterval);
          // CRITICAL: Check mounted after delay - widget may be disposed during polling
          if (!mounted) return;
        }
      }

      // Hide loading state
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }

      if (booking == null) {
        // Webhook didn't create booking in time - show prominent dialog
        LoggingService.log(
          '[STRIPE_RETURN] ❌ Booking not found after ${maxAttempts * pollInterval.inSeconds} seconds',
          tag: 'STRIPE_SESSION',
        );

        if (mounted) {
          // Show dialog with clear instructions instead of snackbar
          await _showPaymentDelayedDialog();

          // Clear URL params and show calendar
          _clearBookingUrlParams();
          await _validateUnitAndProperty();
        }
        return;
      }

      // Found booking! Load unit data if not already loaded
      if (_unit == null && _propertyId != null) {
        await _validateUnitAndProperty();
      }

      // Invalidate calendar cache
      ref.invalidate(realtimeYearCalendarProvider);
      ref.invalidate(realtimeMonthCalendarProvider);

      // Navigate to confirmation screen using Navigator.push
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingReference: booking!.bookingReference ?? booking.id,
              guestEmail: booking.guestEmail ?? '',
              guestName: booking.guestName ?? 'Guest',
              checkIn: booking.checkIn,
              checkOut: booking.checkOut,
              totalPrice: booking.totalPrice,
              nights: booking.checkOut.difference(booking.checkIn).inDays,
              guests: booking.guestCount,
              propertyName: _unit?.name ?? 'Property',
              unitName: _unit?.name,
              paymentMethod: 'stripe',
              booking: booking,
              emailConfig: _widgetSettings?.emailConfig,
              widgetSettings: _widgetSettings,
              propertyId: _propertyId,
              unitId: _unitId,
            ),
          ),
        );

        // After Navigator.pop (user closed confirmation), reset form state
        if (mounted) {
          _resetFormState();
          _clearBookingUrlParams();
        }
      }
    } catch (e) {
      LoggingService.log('[STRIPE_RETURN] ❌ Error: $e', tag: 'STRIPE_SESSION');

      if (mounted) {
        setState(() {
          _isValidating = false;
        });

        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context).errorLoadingBooking(e.toString()),
          duration: const Duration(seconds: 5),
        );

        // Show calendar anyway
        _clearBookingUrlParams();
        await _validateUnitAndProperty();
      }
    }
  }

  /// Validates that unit exists and fetches property/owner info
  ///
  /// Supports two URL resolution modes:
  /// 1. Slug URL: subdomain -> property, slug -> unit (clean URLs)
  /// 2. Query params: direct property and unit IDs (iframe embeds)
  Future<void> _validateUnitAndProperty() async {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      // MODE 1: Slug-based URL resolution (clean URLs for standalone pages)
      // URL format: https://jasko-rab.bookbed.io/apartman-6
      if (widget.urlSlug != null && widget.urlSlug!.isNotEmpty) {
        final slugContext = await ref.read(fullSlugContextProvider(widget.urlSlug).future);

        // No subdomain found - fallback error
        if (slugContext == null) {
          setState(() {
            _validationError = 'Unable to determine property.\n\nSubdomain not found in URL.';
            _isValidating = false;
          });
          return;
        }

        // Property not found for subdomain
        if (!slugContext.propertyFound) {
          setState(() {
            _validationError = 'Property not found.\n\nSubdomain: ${slugContext.subdomain}';
            _isValidating = false;
          });
          return;
        }

        // Unit not found for slug
        if (!slugContext.unitFound || slugContext.unitId == null) {
          setState(() {
            _validationError = 'Unit not found.\n\nSlug: ${widget.urlSlug}\nProperty: ${slugContext.displayName}';
            _isValidating = false;
          });
          return;
        }

        // Successfully resolved both property and unit from slug URL
        _propertyId = slugContext.propertyId;
        _unitId = slugContext.unitId!;

        // Continue with normal validation flow below...
      }

      // MODE 2: Query param validation (iframe embeds)
      // Check if both property and unit IDs are provided
      if (_propertyId == null || _propertyId!.isEmpty) {
        setState(() {
          _validationError = 'Missing property parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          _isValidating = false;
        });
        return;
      }

      if (_unitId.isEmpty) {
        setState(() {
          _validationError = 'Missing unit parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
          _isValidating = false;
        });
        return;
      }

      // Fetch property data first
      final property = await ref.read(propertyByIdProvider(_propertyId!).future);

      // HIGH: Check mounted after async operation before setState
      if (!mounted) return;

      if (property == null) {
        setState(() {
          _validationError = 'Property not found.\n\nProperty ID: $_propertyId';
          _isValidating = false;
        });
        return;
      }

      // Fetch unit data from the specific property
      final unit = await ref.read(unitByIdProvider(_propertyId!, _unitId).future);

      // HIGH: Check mounted after async operation before setState
      if (!mounted) return;

      if (unit == null) {
        setState(() {
          _validationError = 'Unit not found.\n\nUnit ID: $_unitId\nProperty ID: $_propertyId';
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

      // HIGH: Check mounted after async operation before setState
      if (!mounted) return;

      setState(() {
        _isValidating = false;
        _validationError = null;
      });
    } catch (e) {
      // HIGH: Check mounted in catch block before setState
      if (!mounted) return;
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
      final settings = await ref.read(widgetSettingsOrDefaultProvider((propertyId, unitId)).future);

      setState(() {
        _widgetSettings = settings;
        // Set default payment method based on what's enabled
        _setDefaultPaymentMethod();
      });
    } catch (e) {
      // If loading fails, use default settings
      final defaultSettings = ref.read(defaultWidgetSettingsProvider);
      setState(() {
        _widgetSettings = defaultSettings.copyWith(id: unitId, propertyId: propertyId);
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
    final isBankTransferEnabled = _widgetSettings?.bankTransferConfig?.enabled == true;
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

  // Bug #53: Form data persistence - delegates to FormPersistenceService

  /// Build PersistedFormData from current state
  PersistedFormData _buildPersistedFormData() {
    return PersistedFormData(
      unitId: _unitId,
      propertyId: _propertyId,
      checkIn: _checkIn,
      checkOut: _checkOut,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      countryCode: _selectedCountry.dialCode,
      adults: _adults,
      children: _children,
      notes: _notesController.text,
      paymentMethod: _selectedPaymentMethod,
      pillBarDismissed: _pillBarDismissed,
      hasInteractedWithBookingFlow: _hasInteractedWithBookingFlow,
      timestamp: DateTime.now(),
    );
  }

  /// Debounced save - prevents race conditions when user types quickly
  /// Called by text controller listeners
  void _saveFormDataDebounced() {
    if (_isDisposed) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed && mounted) {
        _saveFormData();
      }
    });
  }

  /// Save current form data to localStorage
  Future<void> _saveFormData() async {
    if (_isDisposed) return;
    await FormPersistenceService.saveFormData(_unitId, _buildPersistedFormData());
  }

  /// Load saved form data from localStorage
  Future<void> _loadFormData() async {
    final formData = await FormPersistenceService.loadFormData(_unitId);
    if (formData == null) return;

    // Restore form data
    if (mounted) {
      setState(() {
        _checkIn = formData.checkIn;
        _checkOut = formData.checkOut;
        _firstNameController.text = formData.firstName;
        _lastNameController.text = formData.lastName;
        _emailController.text = formData.email;
        _phoneController.text = formData.phone;
        _selectedCountry = formData.country;
        _adults = formData.adults;
        _children = formData.children;
        _notesController.text = formData.notes;
        _selectedPaymentMethod = formData.paymentMethod;
        _pillBarDismissed = formData.pillBarDismissed;
        _hasInteractedWithBookingFlow = formData.hasInteractedWithBookingFlow;
        // Bug Fix: Don't auto-show guest form from cache
        // User should explicitly select dates or click to open booking flow
      });
    }
  }

  /// Clear saved form data from localStorage
  Future<void> _clearFormData() async {
    await FormPersistenceService.clearFormData(_unitId);
  }

  @override
  void dispose() {
    // MEDIUM: Set disposed flag first to prevent async operations after dispose
    _isDisposed = true;

    // Cancel debounce timer to prevent saves after dispose
    _saveDebounce?.cancel();

    // Bug #53: Remove listeners before disposing
    _firstNameController.removeListener(_saveFormDataDebounced);
    _lastNameController.removeListener(_saveFormDataDebounced);
    _emailController.removeListener(_saveFormDataDebounced);
    _phoneController.removeListener(_saveFormDataDebounced);
    _notesController.removeListener(_saveFormDataDebounced);

    // Dispose all form controllers via centralized state
    _formState.dispose();

    // Dispose cross-tab communication resources
    _tabMessageSubscription?.cancel();
    _tabCommunicationService?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final minimalistColors = MinimalistColorSchemeAdapter(dark: isDarkMode);

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
      final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
      return Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colors.error),
                const SizedBox(height: 24),
                Text(
                  _validationError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: colors.textPrimary),
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final tr = WidgetTranslations.of(context);
                    return ElevatedButton.icon(
                      onPressed: _validateUnitAndProperty,
                      icon: const Icon(Icons.refresh),
                      label: Text(tr.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimary,
                        foregroundColor: colors.buttonPrimaryText,
                      ),
                    );
                  },
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
      backgroundColor: minimalistColors.backgroundPrimary,
      body: SafeArea(
        bottom: false, // No bottom padding - widget embedded in iframe, host handles safe area
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final forceMonthView = screenWidth < 1024; // Year view only on desktop

            // Responsive padding for iframe embedding
            final horizontalPadding = screenWidth < 600
                ? 12.0 // Mobile
                : screenWidth < 1024
                ? 16.0 // Tablet
                : 24.0; // Desktop

            final verticalPadding = horizontalPadding / 2; // Half of horizontal padding

            final topPadding = 0.0; // Minimal padding for maximum content space

            // Calculate available height for calendar
            // Subtract space for logo, title, and padding
            final screenHeight = constraints.maxHeight;
            double reservedHeight = topPadding + (verticalPadding * 2); // Include top + bottom padding

            // Add title height if present
            if (_widgetSettings?.themeOptions?.customTitle != null &&
                _widgetSettings!.themeOptions!.customTitle!.isNotEmpty) {
              reservedHeight += 60; // Approx title height (24px font + padding)
            }

            // Add iCal warning if present (will be checked later)
            reservedHeight += 16; // Buffer for potential warning banner

            // Add contact pill card height for calendar-only mode
            if (widgetMode == WidgetMode.calendarOnly) {
              reservedHeight += 70; // Contact pill card height (~50px content + 8px spacing + buffer)
            }

            // Calendar gets remaining height (ensure minimum of 400px)
            final calendarHeight = (screenHeight - reservedHeight).clamp(400.0, double.infinity);

            return Stack(
              children: [
                // No-scroll content (embedded widget - host site scrolls)
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: verticalPadding,
                    // No bottom padding - calendar/contact card goes to edge
                  ),
                  child: Column(
                    children: [
                      // Custom title header (if configured)
                      if (_widgetSettings?.themeOptions?.customTitle != null &&
                          _widgetSettings!.themeOptions!.customTitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _widgetSettings!.themeOptions!.customTitle!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: minimalistColors.textPrimary,
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
                                    // Use unit's minStayNights (source of truth), NOT widget_settings
                                    final minNights = _unit?.minStayNights ?? 1;
                                    final selectedNights = end.difference(start).inDays;

                                    if (selectedNights < minNights) {
                                      // Show error message
                                      final tr = WidgetTranslations.of(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(tr.minimumNightsRequired(minNights, selectedNights)),
                                          backgroundColor: minimalistColors.error,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  setState(() {
                                    _checkIn = start;
                                    _checkOut = end;
                                    _pillBarPosition = null; // Reset position when new dates selected
                                    // Bug Fix: Date selection IS interaction - show booking flow
                                    _hasInteractedWithBookingFlow = true;
                                    _pillBarDismissed = false; // Reset dismissed flag for new date selection
                                  });

                                  // Bug #53: Save form data after date selection
                                  _saveFormData();
                                },
                        ),
                      ),

                      // Contact pill card (calendar only mode - inline, below calendar)
                      if (widgetMode == WidgetMode.calendarOnly) ...[
                        const SizedBox(height: 8),
                        ContactPillCardWidget(
                          contactOptions: _widgetSettings?.contactOptions,
                          isDarkMode: isDarkMode,
                          screenWidth: screenWidth,
                        ),
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
                      child: Container(color: Colors.black.withValues(alpha: 0.5)),
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
                  _buildFloatingDraggablePillBar(unitId, constraints, isDarkMode),

                // Rotate device overlay - HIGHEST z-index, only for year view in portrait
                if (_shouldShowRotateOverlay(context))
                  RotateDeviceOverlay(
                    isDarkMode: isDarkMode,
                    colors: colors,
                    onSwitchToMonthView: () {
                      ref.read(calendarViewProvider.notifier).state = CalendarViewType.month;
                    },
                    translations: WidgetTranslations.of(context),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build floating draggable pill bar that overlays the calendar
  Widget _buildFloatingDraggablePillBar(String unitId, BoxConstraints constraints, bool isDarkMode) {
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
        final calculation = calculationBase.copyWithServices(servicesTotal, depositPercentage);

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
          maxHeight = 282.0; // Fixed height for compact view (increased by 12px)
        }

        // Center booking flow on screen (not calendar)
        final defaultPosition = Offset(
          (constraints.maxWidth / 2) - (pillBarWidth / 2), // Center horizontally
          (constraints.maxHeight / 2) - (maxHeight / 2), // Center vertically based on screen
        );

        final position = _pillBarPosition ?? defaultPosition;

        // Check if more than 50% of pill bar is off-screen (drag-to-dismiss)
        final isMoreThanHalfOffScreen =
            position.dx < -pillBarWidth / 2 || // >50% dragged left
            position.dy < -maxHeight / 2 || // >50% dragged up
            position.dx > constraints.maxWidth - pillBarWidth / 2 || // >50% dragged right
            position.dy > constraints.maxHeight - maxHeight / 2; // >50% dragged down

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
              _pillBarPosition = Offset(position.dx + delta.dx, position.dy + delta.dy);
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
                  error: (_, _) => const SizedBox.shrink(),
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
            translations: WidgetTranslations.of(context),
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
    final minimalistColors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Safety check: At least one payment method must be available
    final hasAnyPaymentMethod =
        (_widgetSettings?.stripeConfig?.enabled == true) ||
        (_widgetSettings?.bankTransferConfig?.enabled == true) ||
        (_widgetSettings?.allowPayOnArrival == true);

    // If no payment methods available, show error message
    if (_widgetSettings?.widgetMode == WidgetMode.bookingInstant && !hasAnyPaymentMethod) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoPaymentInfo(isDarkMode: isDarkMode, message: WidgetTranslations.of(context).noPaymentMethodsAvailable),
          const SizedBox(height: SpacingTokens.m),
          // Disabled confirm button
          Builder(
            builder: (context) {
              final tr = WidgetTranslations.of(context);
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null, // Disabled
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
                    shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularRounded),
                  ),
                  child: Text(
                    tr.bookingNotAvailable,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
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
              final isStripeEnabled = _widgetSettings?.stripeConfig?.enabled == true;
              final isBankTransferEnabled = _widgetSettings?.bankTransferConfig?.enabled == true;
              final isPayOnArrivalEnabled = _widgetSettings?.allowPayOnArrival == true;

              int enabledCount = 0;
              String? singleMethod;
              String? singleMethodTitle;
              String? singleMethodSubtitle;

              final tr = WidgetTranslations.of(context);

              if (isStripeEnabled) {
                enabledCount++;
                singleMethod = 'stripe';
                singleMethodTitle = tr.creditCard;
                singleMethodSubtitle = calculation.formattedDeposit;
              }
              if (isBankTransferEnabled) {
                enabledCount++;
                singleMethod = 'bank_transfer';
                singleMethodTitle = tr.bankTransfer;
                singleMethodSubtitle = calculation.formattedDeposit;
              }
              if (isPayOnArrivalEnabled) {
                enabledCount++;
                singleMethod = 'pay_on_arrival';
                singleMethodTitle = tr.payOnArrival;
                singleMethodSubtitle = tr.paymentAtProperty;
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
                      tr.payment,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: minimalistColors.textPrimary),
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
                    tr.paymentMethod,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: minimalistColors.textPrimary),
                  ),
                  const SizedBox(height: SpacingTokens.s),
                ],
              );
            },
          ),

          // Payment options - only show if multiple methods available
          Builder(
            builder: (context) {
              final isStripeEnabled = _widgetSettings?.stripeConfig?.enabled == true;
              final isBankTransferEnabled = _widgetSettings?.bankTransferConfig?.enabled == true;
              final isPayOnArrivalEnabled = _widgetSettings?.allowPayOnArrival == true;

              int enabledCount = 0;
              if (isStripeEnabled) enabledCount++;
              if (isBankTransferEnabled) enabledCount++;
              if (isPayOnArrivalEnabled) enabledCount++;

              // Only show payment selectors if multiple options
              if (enabledCount <= 1) {
                return const SizedBox.shrink(); // Hide payment options
              }

              // Multiple payment methods - show all options
              final tr = WidgetTranslations.of(context);
              return Column(
                children: [
                  // Stripe option - credit card + secure payment icons
                  if (isStripeEnabled)
                    PaymentOptionWidget(
                      icon: Icons.payment_rounded,
                      secondaryIcon: Icons.credit_card_rounded,
                      title: tr.creditCard,
                      subtitle: tr.instantConfirmationViaStripe,
                      isSelected: _selectedPaymentMethod == 'stripe',
                      onTap: () => setState(() => _selectedPaymentMethod = 'stripe'),
                      isDarkMode: isDarkMode,
                      depositAmount: calculation.formattedDeposit,
                    ),

                  // Bank Transfer option - bank building icon
                  if (isBankTransferEnabled)
                    Builder(
                      builder: (context) {
                        final tr = WidgetTranslations.of(context);
                        return Padding(
                          padding: EdgeInsets.only(top: isStripeEnabled ? SpacingTokens.s : 0),
                          child: PaymentOptionWidget(
                            icon: Icons.account_balance_rounded,
                            secondaryIcon: Icons.receipt_long_rounded,
                            title: tr.bankTransfer,
                            subtitle: tr.bankTransferSubtitle,
                            isSelected: _selectedPaymentMethod == 'bank_transfer',
                            onTap: () => setState(() => _selectedPaymentMethod = 'bank_transfer'),
                            isDarkMode: isDarkMode,
                            depositAmount: calculation.formattedDeposit,
                          ),
                        );
                      },
                    ),

                  // Pay on Arrival option - house + key icons
                  if (isPayOnArrivalEnabled)
                    Builder(
                      builder: (context) {
                        final tr = WidgetTranslations.of(context);
                        return Padding(
                          padding: EdgeInsets.only(
                            top: (isStripeEnabled || isBankTransferEnabled) ? SpacingTokens.s : 0,
                          ),
                          child: PaymentOptionWidget(
                            icon: Icons.villa_rounded,
                            secondaryIcon: Icons.key_rounded,
                            title: tr.payOnArrival,
                            subtitle: tr.payAtTheProperty,
                            isSelected: _selectedPaymentMethod == 'pay_on_arrival',
                            onTap: () => setState(() => _selectedPaymentMethod = 'pay_on_arrival'),
                            isDarkMode: isDarkMode,
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: SpacingTokens.m),
        ],

        // Info message for bookingPending mode
        if (_widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
          Builder(
            builder: (context) {
              final tr = WidgetTranslations.of(context);
              return InfoCardWidget(message: tr.bookingPendingUntilConfirmed, isDarkMode: isDarkMode);
            },
          ),
          const SizedBox(height: SpacingTokens.m),
        ],

        // Confirm button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _handleConfirmBooking(calculation),
            style: ElevatedButton.styleFrom(
              backgroundColor: minimalistColors.buttonPrimary,
              foregroundColor: minimalistColors.buttonPrimaryText,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
              shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(minimalistColors.buttonPrimaryText),
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
                        color: minimalistColors.buttonPrimaryText,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInfoForm(BookingPriceCalculation calculation, {bool showButton = true}) {
    final isDarkMode = ref.watch(themeProvider);
    final minimalistColors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            tr.guestInformation,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: minimalistColors.textPrimary),
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
            requireVerification: _widgetSettings?.emailConfig.requireEmailVerification ?? false,
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
              final validationError = EmailValidator.validate(email);
              if (validationError != null) {
                SnackBarHelper.showError(context: context, message: validationError);
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
                textColor: minimalistColors.textPrimary,
                backgroundColor: minimalistColors.backgroundSecondary,
                borderColor: minimalistColors.textSecondary.withValues(alpha: 0.3),
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
          NotesField(controller: _notesController, isDarkMode: isDarkMode),
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
                onPressed: _isProcessing ? null : () => _handleConfirmBooking(calculation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: minimalistColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
                  shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(minimalistColors.buttonPrimaryText),
                        ),
                      )
                    : Text(
                        _getConfirmButtonText(),
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
  String _getConfirmButtonText() {
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Calculate nights if dates are selected
    final tr = WidgetTranslations.of(context);
    String nightsText = '';
    if (_checkIn != null && _checkOut != null) {
      final nights = _checkOut!.difference(_checkIn!).inDays;
      nightsText = tr.nightsTextFormat(nights);
    }

    // bookingPending mode - no payment, just request
    if (widgetMode == WidgetMode.bookingPending) {
      return tr.sendBookingRequest(nightsText);
    }

    // bookingInstant mode - depends on selected payment method
    if (_selectedPaymentMethod == 'stripe') {
      return tr.payWithStripe(nightsText);
    } else if (_selectedPaymentMethod == 'bank_transfer') {
      return tr.continueToBankTransfer(nightsText);
    } else if (_selectedPaymentMethod == 'pay_on_arrival') {
      return tr.reserve + nightsText;
    }

    return tr.confirmBookingButton(nightsText);
  }

  Future<void> _handleConfirmBooking(BookingPriceCalculation calculation) async {
    final widgetMode = _widgetSettings?.widgetMode ?? WidgetMode.bookingInstant;

    // Run all blocking validations using BookingValidationService
    final validationResult = BookingValidationService.validateAllBlocking(
      formKey: _formKey,
      requireEmailVerification: _widgetSettings?.emailConfig.requireEmailVerification ?? false,
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
      final sameDayResult = BookingValidationService.checkSameDayCheckIn(checkIn: _checkIn!);
      if (sameDayResult.isWarning && sameDayResult.errorMessage != null && mounted) {
        SnackBarHelper.showWarning(
          context: context,
          message: sameDayResult.errorMessage!,
          duration: sameDayResult.snackBarDuration,
        );
      }
    }

    // ✨ FINAL SAFETY CHECK: Email verification still valid?
    // This catches expired verifications (e.g., user verified 31+ minutes ago)
    final emailVerificationValid = await _validateEmailVerificationBeforeBooking();
    if (!emailVerificationValid) {
      return; // Block booking - verification expired or check failed
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Submit booking via use case
      // Race condition is handled atomically by createBookingAtomic Cloud Function
      // Client-side checks are unsafe due to TOCTOU (Time-of-check-to-time-of-use)
      final submitBookingUseCase = ref.read(submitBookingUseCaseProvider);

      final params = SubmitBookingParams(
        unitId: _unitId,
        propertyId: _propertyId!,
        ownerId: _ownerId!,
        unit: _unit,
        widgetSettings: _widgetSettings,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneWithCountryCode: '${_selectedCountry.dialCode} ${_phoneController.text.trim()}',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        adults: _adults,
        children: _children,
        totalPrice: calculation.totalPrice,
        paymentMethod: widgetMode == WidgetMode.bookingPending ? 'none' : _selectedPaymentMethod,
        paymentOption: widgetMode == WidgetMode.bookingPending ? 'none' : _selectedPaymentOption,
        taxLegalAccepted: _taxLegalAccepted,
      );

      final result = await submitBookingUseCase.execute(params);

      // Handle Stripe flow: Redirect to checkout
      if (result.isStripeFlow) {
        await _handleStripePayment(bookingData: result.stripeBookingData!, guestEmail: _emailController.text.trim());
        // User redirected to Stripe - no further action here
        return;
      }

      // Handle non-Stripe flow: Navigate to confirmation
      final booking = result.booking;
      final paymentMethod = widgetMode == WidgetMode.bookingPending ? 'pending' : _selectedPaymentMethod;

      if (booking == null) {
        throw Exception('Booking creation failed - no booking returned');
      }

      await _navigateToConfirmationAndCleanup(booking: booking, paymentMethod: paymentMethod);
    } on BookingConflictException catch (e) {
      // Race condition - dates were booked by another user
      if (mounted) {
        SnackBarHelper.showError(context: context, message: e.message, duration: const Duration(seconds: 7));

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
          message: WidgetTranslations.of(context).errorCreatingBooking(e.toString()),
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

  /// Helper method to show confirmation screen for direct bookings
  /// Uses Navigator.push for proper back navigation and transition animation
  /// For pending/bank_transfer/pay_on_arrival modes
  Future<void> _navigateToConfirmationAndCleanup({required BookingModel booking, required String paymentMethod}) async {
    if (!mounted) return;

    // CRITICAL: Invalidate calendar cache BEFORE showing confirmation
    // This ensures the calendar will show newly booked dates when user returns
    ref.invalidate(realtimeYearCalendarProvider);
    ref.invalidate(realtimeMonthCalendarProvider);

    // Clear saved form data after successful booking
    await _clearFormData();

    // Check mounted after async gap
    if (!mounted) return;

    // Add URL params for browser history support (back button works)
    final bookingRef = booking.id.substring(0, 8).toUpperCase();
    _addBookingUrlParams(
      bookingRef: bookingRef,
      email: booking.guestEmail ?? '',
      bookingId: booking.id,
      paymentMethod: paymentMethod,
    );

    // Navigator.push for proper back navigation and transition animation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          bookingReference: bookingRef,
          guestEmail: booking.guestEmail ?? '',
          guestName: booking.guestName ?? 'Guest',
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
          propertyId: _propertyId,
          unitId: _unitId,
        ),
      ),
    );

    // After Navigator.pop (user closed confirmation), reset form state
    if (mounted) {
      _resetFormState();
      _clearBookingUrlParams();
    }

    LoggingService.log('[Navigation] Confirmation screen closed (payment: $paymentMethod)', tag: 'NAV');
  }

  /// Handle Stripe payment
  ///
  /// NEW FLOW (2025-12-02):
  /// - No booking created yet - only validation passed
  /// - Pass all booking data to Stripe checkout session
  /// - Booking will be created by webhook after payment succeeds
  Future<void> _handleStripePayment({required Map<String, dynamic> bookingData, required String guestEmail}) async {
    try {
      final stripeService = ref.read(stripeServiceProvider);

      // Build return URL for Stripe redirect
      // IMPORTANT: Flutter Web uses hash routing (e.g., /#/calendar)
      final baseUrl = Uri.base;
      final returnUrlWithoutHash = Uri(
        scheme: baseUrl.scheme,
        host: baseUrl.host,
        port: baseUrl.port,
        queryParameters: {...baseUrl.queryParameters, 'email': guestEmail, 'payment': 'stripe'},
      ).toString();
      // Append hash fragment for Flutter's hash-based routing
      final returnUrl = '$returnUrlWithoutHash#/calendar';

      // Create Stripe checkout session with ALL booking data
      // Booking will be created by webhook after successful payment
      final checkoutResult = await stripeService.createCheckoutSession(bookingData: bookingData, returnUrl: returnUrl);

      // CRITICAL: Clear form data BEFORE redirect
      // This prevents the bug where cached form data loads on return
      // with dates that are now booked, causing false "conflict" error
      await _clearFormData();

      // Redirect to Stripe Checkout in SAME TAB
      // This keeps everything in one tab - no cross-tab communication needed
      if (kIsWeb) {
        // Web: Use window.location.href for same-tab redirect
        navigateToUrl(checkoutResult.checkoutUrl);
      } else {
        // Mobile: Use url_launcher (will open in browser)
        final uri = Uri.parse(checkoutResult.checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          final tr = WidgetTranslations.of(context);
          throw tr.couldNotLaunchStripeCheckout;
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context).errorLaunchingStripe(e.toString()),
        );
      }
    }
  }

  /// Show confirmation screen after return (Stripe redirect or direct booking URL)
  /// Fetches booking from Firestore using booking ID and displays confirmation
  ///
  /// [fromOtherTab] - if true, this was triggered by cross-tab message, don't broadcast back
  /// [paymentMethod] - payment method used (stripe, pay_on_arrival, bank_transfer)
  /// [isDirectBooking] - if true, this is same-tab return (direct booking), show inline
  Future<void> _showConfirmationFromUrl(
    String bookingReference,
    String guestEmail,
    String bookingId, {
    bool fromOtherTab = false,
    String? paymentMethod,
    bool isDirectBooking = false,
  }) async {
    try {
      // Fetch booking from Firestore using booking ID
      final bookingRepo = ref.read(bookingRepositoryProvider);
      var booking = await bookingRepo.fetchBookingById(bookingId);

      if (booking == null) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context: context,
            message: WidgetTranslations.of(context).bookingNotFoundCheckEmail,
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      // Bug #40 Fix: Poll for webhook update if payment still pending
      // Stripe webhook may take a few seconds to process
      if (booking.paymentStatus == 'pending' || booking.status == BookingStatus.pending) {
        LoggingService.log(
          '⚠️ Payment status pending after Stripe return, polling for webhook update...',
          tag: 'STRIPE_WEBHOOK_FALLBACK',
        );

        // Poll up to 10 times with 2-second intervals (20 seconds total)
        for (var i = 0; i < 10; i++) {
          await Future.delayed(const Duration(seconds: 2));
          // CRITICAL: Check mounted after delay - widget may be disposed during polling
          if (!mounted) return;

          final updatedBooking = await bookingRepo.fetchBookingById(bookingId);
          if (updatedBooking == null) break;

          // Check if webhook has updated the booking
          if (updatedBooking.paymentStatus == 'paid' || updatedBooking.status == BookingStatus.confirmed) {
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
        if (booking?.paymentStatus == 'pending' || booking?.status == BookingStatus.pending) {
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

      // Broadcast to other tabs (in case user has multiple tabs open)
      // This is optional now since we redirect in same tab, but useful for edge cases
      if (!fromOtherTab && _tabCommunicationService != null) {
        _tabCommunicationService!.sendPaymentComplete(bookingId: bookingId, ref: bookingReference, email: guestEmail);
        LoggingService.log('[CrossTab] Broadcasted payment complete to other tabs', tag: 'TAB_COMM');
      }

      // CRITICAL: Invalidate calendar cache BEFORE showing confirmation
      // This ensures the calendar will show newly booked dates when user returns
      ref.invalidate(realtimeYearCalendarProvider);
      ref.invalidate(realtimeMonthCalendarProvider);

      // Clear saved form data after successful booking
      await _clearFormData();

      // Determine actual payment method
      final actualPaymentMethod = paymentMethod ?? confirmedBooking.paymentMethod ?? 'stripe';

      // Use Navigator.push for ALL booking confirmations
      // This provides proper back navigation and transition animation
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
              nights: confirmedBooking.checkOut.difference(confirmedBooking.checkIn).inDays,
              guests: confirmedBooking.guestCount,
              propertyName: _unit?.name ?? 'Property',
              unitName: _unit?.name,
              paymentMethod: actualPaymentMethod,
              booking: confirmedBooking,
              emailConfig: _widgetSettings?.emailConfig,
              widgetSettings: _widgetSettings,
              propertyId: _propertyId,
              unitId: _unitId,
            ),
          ),
        );

        // After Navigator.pop (user closed confirmation), reset form state
        if (mounted) {
          _resetFormState();
          _clearBookingUrlParams();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context).errorLoadingBooking(e.toString()),
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
    final isPortrait = orientation == Orientation.portrait || screenHeight > screenWidth;

    return isPortrait;
  }

  /// Safety check: Validate that email verification is still valid before booking
  ///
  /// Returns true if verification is valid (or not required).
  /// Returns false and shows error if verification expired.
  ///
  /// This is the FINAL check before booking submission to catch
  /// expired verifications (e.g., user verified 31 minutes ago).
  Future<bool> _validateEmailVerificationBeforeBooking() async {
    // Skip check if email verification is not required
    if (_widgetSettings?.emailConfig.requireEmailVerification != true) {
      return true; // No verification needed
    }

    // Skip check if email is not verified in UI state
    if (!_emailVerified) {
      // This shouldn't happen (button should be disabled), but safety check
      final tr = WidgetTranslations.of(context);
      SnackBarHelper.showError(context: context, message: tr.pleaseVerifyEmailBeforeBooking);
      return false;
    }

    try {
      LoggingService.logOperation('[BookingWidget] Final email verification check before booking');

      final email = _emailController.text.trim();
      final status = await EmailVerificationService.checkStatus(email);

      // Verification is still valid
      if (status.isValid) {
        LoggingService.logSuccess('[BookingWidget] Email verification valid (${status.remainingMinutes}min remaining)');
        return true;
      }

      // Verification expired between initial verification and booking submit
      if (status.expired) {
        LoggingService.logWarning('[BookingWidget] Email verification expired during booking flow');

        if (mounted) {
          setState(() {
            _emailVerified = false; // Reset UI state
          });

          SnackBarHelper.showError(
            context: context,
            message: WidgetTranslations.of(context).errorEmailVerificationExpired,
          );
        }

        return false;
      }

      // Email not verified (shouldn't happen, but safety check)
      LoggingService.logWarning('[BookingWidget] Email not verified at final check');

      if (mounted) {
        setState(() {
          _emailVerified = false;
        });

        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(context).errorEmailVerificationRequired,
        );
      }

      return false;
    } catch (e) {
      // Network error or Cloud Function failed
      await LoggingService.logError('[BookingWidget] Email verification check failed', e);

      // ⚠️ DECISION: Block booking on check failure (safer)
      if (mounted) {
        SnackBarHelper.showError(context: context, message: WidgetTranslations.of(context).errorUnableToVerifyEmail);
      }
      return false;

      // Alternative: Allow booking if check fails (better UX, less safe)
      // return true; // Fallback: Allow booking if check fails
    }
  }

  /// Open email verification dialog with pre-check logic
  ///
  /// PRE-CHECK FLOW:
  /// 1. Check if email is already verified (via Cloud Function)
  /// 2. If verified and NOT expired → Skip dialog, show success
  /// 3. If NOT verified or expired → Show verification dialog
  ///
  /// FALLBACK: If pre-check fails (network error), show dialog anyway
  Future<void> _openVerificationDialog() async {
    final email = _emailController.text.trim();
    final isDarkMode = ref.read(themeProvider);

    // ✨ PRE-CHECK: Da li je email već verifikovan?
    try {
      LoggingService.logOperation('[BookingWidget] Pre-checking email verification status');

      final status = await EmailVerificationService.checkStatus(email);

      // Email is already verified and NOT expired
      if (status.isValid) {
        LoggingService.logSuccess('[BookingWidget] Email already verified (expires in ${status.remainingMinutes}min)');

        if (mounted) {
          setState(() {
            _emailVerified = true;
          });

          SnackBarHelper.showSuccess(
            context: context,
            message: WidgetTranslations.of(context).emailAlreadyVerified(status.remainingMinutes),
          );
        }

        return; // ✅ Skip dialog - email already verified
      }

      // Email exists but expired
      if (status.exists && status.expired) {
        LoggingService.logWarning('[BookingWidget] Verification expired, sending new code');
      }

      // Email not verified or expired - show dialog normally
    } catch (e) {
      // Pre-check failed (network issue, etc.) - fallback to normal flow
      LoggingService.logWarning('[BookingWidget] Pre-check failed, showing dialog anyway: $e');
    }

    // Show verification dialog (either new verification or pre-check failed)
    if (!mounted) return;

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
