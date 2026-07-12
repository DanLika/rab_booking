import 'dart:async' show unawaited, Timer, StreamSubscription;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/utils/web_utils.dart';
import '../../../../core/utils/browser_detection.dart';
import '../../../../core/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
// Cross-tab communication service (uses conditional import via web_utils)
import '../../../../core/services/tab_communication_service.dart';
import '../../services/form_persistence_service.dart';
import '../../state/booking_form_state.dart';
import '../../utils/date_normalizer.dart';
import '../widgets/lazy_calendar_container.dart';
import '../widgets/additional_services_widget.dart';
import '../widgets/tax_legal_disclaimer_widget.dart';
import '../providers/booking_price_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/owner_gate_status_provider.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../providers/additional_services_provider.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../providers/submit_booking_provider.dart';
import '../providers/subdomain_provider.dart';
import '../providers/widget_context_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../providers/booking_lookup_provider.dart';
import '../../domain/models/booking_details_model.dart';
import '../../domain/use_cases/submit_booking_use_case.dart';
import '../../domain/models/calendar_view_type.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../domain/models/booking_submission_result.dart';
import '../../domain/services/booking_url_state_service.dart';
import '../../domain/services/booking_validation_service.dart';
import '../../domain/services/price_lock_service.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/booking_model.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/design/tokens.dart';
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
import '../widgets/zoom_control_buttons.dart';
import '../widgets/powered_by_badge.dart';
// HYBRID LOADING: loading_screen.dart import removed - UI shows immediately
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
// MinimalistColorSchemeAdapter is already imported via minimalist_colors.dart
import '../../../../shared/utils/ui/snackbar_helper.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../l10n/widget_translations.dart';
import '../helpers/booking_widget_url_helpers.dart';
import '../helpers/booking_widget_url_intent.dart';
import '../helpers/iframe_height_reporter.dart';
import '../helpers/zoom_control_state.dart';

part 'booking_widget_screen_cross_tab.dart';
part 'booking_widget_screen_data_loading.dart';
part 'booking_widget_screen_form_ui.dart';
part 'booking_widget_screen_payment_flow.dart';
part 'booking_widget_screen_submit.dart';

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
  const BookingWidgetScreen({super.key, this.urlSlug});

  /// Optional URL slug for clean URL resolution.
  /// When provided, property is resolved from subdomain and unit from this slug.
  final String? urlSlug;

  @override
  ConsumerState<BookingWidgetScreen> createState() =>
      _BookingWidgetScreenState();
}

/// Shared mutable state for `_BookingWidgetScreenState` and its concern
/// mixins (`_CrossTabMixin`, `_PaymentFlowMixin`, `_DataLoadingMixin`,
/// `_BookingSubmitMixin`, `_BookingFormUiMixin`).
///
/// The 4.2k-line God-state was split into `part` files on 2026-07-10 —
/// every method moved VERBATIM; the runtime class is unchanged (same
/// members, same linearization). Fields live here so all mixins can
/// reach them through the superclass constraint.
abstract class _BookingWidgetScreenStateBase
    extends ConsumerState<BookingWidgetScreen> {
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
  /// HYBRID LOADING: _isValidating removed - UI shows immediately
  /// Error state is still tracked for failed data fetches
  String? _validationError;

  // ============================================
  // CALENDAR REFRESH KEY
  // ============================================
  /// Incremented after returning from booking confirmation to force calendar rebuild.
  /// Fixes bug where CustomPaint doesn't repaint after Navigator.pop().
  int _calendarRefreshKey = 0;

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
  TextEditingController get _firstNameController =>
      _formState.firstNameController;
  TextEditingController get _lastNameController =>
      _formState.lastNameController;
  TextEditingController get _emailController => _formState.emailController;
  TextEditingController get _phoneController => _formState.phoneController;
  TextEditingController get _notesController => _formState.notesController;
  Country get _selectedCountry => _formState.selectedCountry;
  set _selectedCountry(Country value) => _formState.selectedCountry = value;
  int get _adults => _formState.adults;
  set _adults(int value) => _formState.adults = value;
  int get _children => _formState.children;
  set _children(int value) => _formState.children = value;
  int get _pets => _formState.pets;
  set _pets(int value) => _formState.pets = value;
  bool get _showGuestForm => _formState.showGuestForm;
  set _showGuestForm(bool value) => _formState.showGuestForm = value;
  String get _selectedPaymentMethod => _formState.selectedPaymentMethod;
  set _selectedPaymentMethod(String value) =>
      _formState.selectedPaymentMethod = value;
  String get _selectedPaymentOption => _formState.selectedPaymentOption;
  bool get _isProcessing => _formState.isProcessing;
  set _isProcessing(bool value) => _formState.isProcessing = value;
  bool get _isVerifyingEmail => _formState.isVerifyingEmail;
  set _isVerifyingEmail(bool value) => _formState.isVerifyingEmail = value;
  bool get _emailVerified => _formState.emailVerified;
  set _emailVerified(bool value) => _formState.emailVerified = value;
  bool get _taxLegalAccepted => _formState.taxLegalAccepted;
  set _taxLegalAccepted(bool value) => _formState.taxLegalAccepted = value;
  BookingPriceCalculation? get _lockedPriceCalculation =>
      _formState.lockedPriceCalculation;
  set _lockedPriceCalculation(BookingPriceCalculation? value) =>
      _formState.lockedPriceCalculation = value;
  bool get _pillBarDismissed => _formState.pillBarDismissed;
  set _pillBarDismissed(bool value) => _formState.pillBarDismissed = value;
  bool get _hasInteractedWithBookingFlow =>
      _formState.hasInteractedWithBookingFlow;
  set _hasInteractedWithBookingFlow(bool value) =>
      _formState.hasInteractedWithBookingFlow = value;

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
  /// Timer for payment completion timeout (resets loading state if message doesn't arrive)
  Timer? _paymentCompletionTimeout;
  // Cross-tab communication for Stripe payments
  // When payment completes in one tab, other tabs are notified to update UI
  TabCommunicationService? _tabCommunicationService;
  StreamSubscription<TabMessage>? _tabMessageSubscription;

  // PostMessage listener for popup window communication (iframe context)
  void Function()? _postMessageListenerCleanup;

  // ============================================
  // IFRAME HEIGHT AUTO-RESIZE
  // ============================================
  final _heightReporter = IframeHeightReporter();

  // ============================================
  // ZOOM SCALE (for zoom control buttons)
  // ============================================
  final _zoom = ZoomControlState();

  /// Reset form state to initial values (clear all user input)
  void _resetFormState() {
    if (mounted) {
      setState(() {
        _formState.resetState();
        // Increment refresh key to force calendar widget tree rebuild
        // This fixes CustomPaint not repainting after Navigator.pop()
        _calendarRefreshKey++;
      });
    }

    // Reset selected additional services (provider-based)
    ref.invalidate(selectedAdditionalServicesProvider);

    // Invalidate calendar to refresh availability
    ref.invalidate(realtimeYearCalendarProvider);
    ref.invalidate(realtimeMonthCalendarProvider);

    LoggingService.log(
      '[CrossTab] Form state reset after payment completion',
      tag: 'TAB_COMM',
    );
  }
}

class _BookingWidgetScreenState extends _BookingWidgetScreenStateBase
    with
        _DataLoadingMixin,
        _PaymentFlowMixin,
        _CrossTabMixin,
        _BookingSubmitMixin,
        _BookingFormUiMixin {
  @override
  void initState() {
    super.initState();
    // Parse property and unit IDs from URL
    // Priority: 1. URL slug (clean URLs), 2. Query parameters (iframe embeds)
    final uri = Uri.base;

    // DEBUG: Log full URI to diagnose Stripe return detection
    LoggingService.log('[INIT] Uri.base: $uri', tag: 'STRIPE_RETURN_DEBUG');
    LoggingService.log(
      '[INIT] Uri.base.toString(): ${uri.toString()}',
      tag: 'STRIPE_RETURN_DEBUG',
    );
    LoggingService.log(
      '[INIT] Uri.base.query: ${uri.query}',
      tag: 'STRIPE_RETURN_DEBUG',
    );
    LoggingService.log(
      '[INIT] Uri.base.fragment: ${uri.fragment}',
      tag: 'STRIPE_RETURN_DEBUG',
    );
    LoggingService.log(
      '[INIT] Query params: ${uri.queryParameters}',
      tag: 'STRIPE_RETURN_DEBUG',
    );
    LoggingService.log(
      '[INIT] stripe_status: ${uri.queryParameters['stripe_status']}, session_id: ${uri.queryParameters['session_id']}',
      tag: 'STRIPE_RETURN_DEBUG',
    );
    // Check if params are in fragment instead of query (hash routing issue)
    if (uri.fragment.contains('stripe_status') ||
        uri.fragment.contains('session_id')) {
      LoggingService.log(
        '[INIT] ⚠️ STRIPE PARAMS IN FRAGMENT! This is the bug.',
        tag: 'STRIPE_RETURN_DEBUG',
      );
    }

    // Check if using slug-based URL (will be resolved in _validateUnitAndProperty)
    if (widget.urlSlug != null && widget.urlSlug!.isNotEmpty) {
      // Slug URL: property resolved from subdomain, unit from slug
      // IDs will be set after async resolution in _validateUnitAndProperty
      _propertyId = null;
      _unitId = '';
    } else {
      // Query params URL: direct IDs from URL
      _propertyId = sanitizeId(uri.queryParameters['property']);
      _unitId = sanitizeId(uri.queryParameters['unit']) ?? '';
    }

    // Bug #53: Add listeners to text controllers for auto-save (debounced)
    _firstNameController.addListener(_saveFormDataDebounced);
    _lastNameController.addListener(_saveFormDataDebounced);
    _emailController.addListener(_saveFormDataDebounced);
    _phoneController.addListener(_saveFormDataDebounced);
    _notesController.addListener(_saveFormDataDebounced);

    // Initialize cross-tab communication for web platform
    _initTabCommunication();

    // Setup iframe scroll capture to prevent parent page scrolling
    setupIframeScrollCapture();

    final intent = parseInitialUrlIntent(uri);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      switch (intent) {
        case StripeReturnSession(:final sessionId):
          await _clearFormData();
          await _handleStripeReturnWithSessionId(sessionId);
          return;
        case LegacyStripeReturn(:final confirmationRef, :final bookingId):
          await _clearFormData();
          await _showConfirmationFromUrl(confirmationRef, bookingId);
          return;
        case DirectBookingReturn(
          :final confirmationRef,
          :final bookingId,
          :final paymentType,
        ):
          await _showConfirmationFromUrl(
            confirmationRef,
            bookingId,
            paymentMethod: paymentType,
            isDirectBooking: true,
          );
          return;
        case FreshLoad():
          await _validateUnitAndProperty();
          await _loadFormData();
      }
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

  // NOTE: _updateProgress removed - no longer using BookBed Loader
  // UI shows immediately with skeleton calendar instead

  @override
  void dispose() {
    // MEDIUM: Set disposed flag first to prevent async operations after dispose
    _isDisposed = true;

    // Cancel debounce timer to prevent saves after dispose
    _saveDebounce?.cancel();

    // Bug #53: Remove listeners before disposing
    // Defensive: Wrap in try-catch to handle cases where listener might not be added
    // or controller might already be disposed
    try {
      _firstNameController.removeListener(_saveFormDataDebounced);
    } catch (e) {
      // Ignore - listener might not be added or controller already disposed
    }
    try {
      _lastNameController.removeListener(_saveFormDataDebounced);
    } catch (e) {
      // Ignore - listener might not be added or controller already disposed
    }
    try {
      _emailController.removeListener(_saveFormDataDebounced);
    } catch (e) {
      // Ignore - listener might not be added or controller already disposed
    }
    try {
      _phoneController.removeListener(_saveFormDataDebounced);
    } catch (e) {
      // Ignore - listener might not be added or controller already disposed
    }
    try {
      _notesController.removeListener(_saveFormDataDebounced);
    } catch (e) {
      // Ignore - listener might not be added or controller already disposed
    }

    // Dispose all form controllers via centralized state
    // Defensive: Wrap in try-catch to handle edge cases
    try {
      _formState.dispose();
    } catch (e) {
      // Ignore - formState might already be disposed
    }

    // Dispose cross-tab communication resources
    try {
      _tabMessageSubscription?.cancel();
    } catch (e) {
      // Ignore - subscription might already be cancelled
    }
    try {
      _tabCommunicationService?.dispose();
    } catch (e) {
      // Ignore - service might already be disposed
    }
    try {
      _postMessageListenerCleanup?.call();
    } catch (e) {
      // Ignore - cleanup might already be called or throw
    }

    // Cancel payment completion timeout

    _paymentCompletionTimeout?.cancel();
    _paymentCompletionTimeout = null;

    _heightReporter.dispose();
    _zoom.dispose();

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
          propertyId: _propertyId, // OPTIMIZED: enables cache reuse
          depositPercentage: _widgetSettings?.globalDepositPercentage ?? 20,
          // NOTE: guestCount/petCount NOT passed here — fees calculated locally
          // to avoid async re-fetch flicker when user changes guest/pet count
        ),
        (previous, next) {
          // Defensive check: ensure widget is still mounted
          if (!mounted) return;

          try {
            next.whenOrNull(
              error: (error, stack) {
                // Defensive check: ensure widget is still mounted
                if (!mounted) return;

                // Check if error is DatesNotAvailableException
                if (error is DatesNotAvailableException) {
                  // Defensive check: ensure widget is still mounted before setState
                  if (!mounted) return;

                  try {
                    // Clear selected dates
                    if (mounted) {
                      setState(() {
                        _checkIn = null;
                        _checkOut = null;
                        _showGuestForm = false;
                      });
                    }

                    // Show user-friendly error message
                    if (mounted) {
                      // Safely get error message
                      String errorMessage;
                      try {
                        errorMessage = error.getUserMessage();
                      } catch (e) {
                        errorMessage = 'Selected dates are no longer available';
                      }

                      // Defensive check: ensure context is still valid
                      try {
                        SnackBarHelper.showError(
                          context: context,
                          message: errorMessage,
                          duration: const Duration(seconds: 5),
                        );
                      } catch (e) {
                        // Ignore errors if context is no longer valid
                      }
                    }
                  } catch (e) {
                    // Ignore errors if widget is disposed during setState
                  }
                }
              },
            );
          } catch (e) {
            // Ignore errors if provider value is invalid or widget is disposed
          }
        },
      );
    }

    // HYBRID LOADING: BookBed Loader removed - UI shows immediately with skeleton calendar
    // Calendar data loads in background via _validateUnitAndProperty()
    // _isValidating is now always false initially to enable instant UI rendering

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
                    final tr = WidgetTranslations.of(context, ref);
                    return ElevatedButton.icon(
                      onPressed: _retryValidation,
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

    // Send iframe height to parent for auto-resize (web only, in iframe only)
    _heightReporter.send();

    return Scaffold(
      // In iframe: false (host site handles keyboard resize)
      // In standalone: true (browser handles keyboard resize, prevents black space)
      resizeToAvoidBottomInset: !isInIframe,
      // In iframe: transparent so parent website background shows through
      // Standalone: use theme background (white/black)
      backgroundColor: isInIframe
          ? Colors.transparent
          : minimalistColors.backgroundPrimary,

      // Support Icon - Bottom Left FAB (Micro Size)
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // Icon-only support button, present on every widget page. #892 gave it an
      // accessible name (it announced nothing before).
      //
      // Its hit box is 24dp — below the 48dp minimum (WCAG 2.5.5). Known and
      // deliberate: it is a micro-FAB, and the two ways to grow the target both
      // cost more than they buy. Enlarging the RawMaterialButton also enlarges
      // what it paints (it carries the fill and border), changing the design;
      // and swapping it for an opaque 48dp GestureDetector around a plain
      // container was tried and REVERTED — a semantics dump of the running app
      // showed it silently dropped the accessible name, trading a size miss for
      // a worse one. Revisit only with a change that keeps the label.
      floatingActionButton: Semantics(
        button: true,
        label: WidgetTranslations.of(context, ref).contactSupport,
        child: SizedBox(
          width: 24,
          height: 24,
          child: RawMaterialButton(
            onPressed: () {
              // Launch email client
              launchUrl(
                Uri.parse('mailto:dusko@book-bed.com'),
                // mode: LaunchMode.externalApplication, // Causes "invalid address" on Safari Web
              );
            },
            fillColor: minimalistColors.backgroundTertiary,
            // Use textPrimary for automatic theme adaptation (Black in Light, White in Dark)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: minimalistColors.borderDefault),
            ),
            child: Icon(
              Icons.headset_mic,
              size: 16,
              color: minimalistColors.textPrimary,
            ),
          ),
        ),
      ),

      body: SafeArea(
        bottom:
            false, // No bottom padding - widget embedded in iframe, host handles safe area
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Defensive check: ensure constraints are bounded and finite
            final screenWidth =
                constraints.maxWidth.isFinite &&
                    constraints.maxWidth != double.infinity
                ? constraints.maxWidth
                : 1200.0; // Fallback to reasonable default
            final forceMonthView =
                screenWidth < 1024; // Year view only on desktop

            // Watch calendar view to determine max content width for centering
            final currentCalendarView = ref.watch(calendarViewProvider);
            final maxContentWidth = currentCalendarView == CalendarViewType.year
                ? 1400.0
                : 1000.0;
            final isLargeScreen = screenWidth > maxContentWidth;

            // Responsive padding for iframe embedding
            // On large screens, use symmetric padding (same horizontal and vertical)
            final basePadding = screenWidth < 600
                ? 12.0 // Mobile
                : screenWidth < 1024
                ? 12.0 // Tablet (same as mobile for better space utilization)
                : isLargeScreen
                ? 24.0 // Large screen
                : 16.0; // Desktop

            final horizontalPadding = basePadding;
            final verticalPadding = isLargeScreen
                ? basePadding
                : basePadding / 2; // Symmetric on large screens

            // In iframe mode: let content determine height (for auto-resize)
            // In standalone mode: ensure content fills viewport (for centering)
            // Outer Stack: pill bar OUTSIDE scroll area for proper viewport centering
            return Stack(
              children: [
                // Scrollable calendar content
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Always use full viewport height to enable vertical centering
                      // Defensive check: ensure maxHeight is finite
                      minHeight:
                          constraints.maxHeight.isFinite &&
                              constraints.maxHeight != double.infinity
                          ? constraints.maxHeight
                          : 800.0, // Fallback to reasonable default
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Vertically center content
                      children: [
                        // No-scroll content (embedded widget - host site scrolls)
                        // On large screens, center content with max-width constraint
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isLargeScreen
                                  ? maxContentWidth
                                  : double.infinity,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              child: Column(
                                key: _heightReporter
                                    .contentKey, // For iframe height measurement
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Custom title header (if configured)
                                  ...() {
                                    final customTitle = _widgetSettings
                                        ?.themeOptions
                                        ?.customTitle;
                                    if (customTitle != null &&
                                        customTitle.isNotEmpty) {
                                      return [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: Text(
                                            customTitle,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  minimalistColors.textPrimary,
                                              fontFamily: 'Manrope',
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ];
                                    }
                                    return <Widget>[];
                                  }(),

                                  // NOTE: iCal sync warning banner removed from guest widget
                                  // This is owner-only information - guests don't need to see sync status
                                  // Owners can monitor sync status in their dashboard

                                  // Calendar-only mode banner - explain view-only nature
                                  // Spacing matches header-to-legend: 24px desktop, 16px mobile
                                  if (widgetMode == WidgetMode.calendarOnly)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: screenWidth >= 1024 ? 24 : 16,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          // Consistent styling with contact pill bar
                                          color: minimalistColors
                                              .backgroundTertiary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                minimalistColors.borderDefault,
                                          ),
                                          // Subtle elevation - matches contact pill bar
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: minimalistColors
                                                  .buttonPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                WidgetTranslations.of(
                                                  context,
                                                  ref,
                                                ).calendarOnlyBanner,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: minimalistColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // SF-079 owner-gate banner: surfaces a guest-facing
                                  // "unavailable for new bookings" notice when the unit's
                                  // owner is trial_expired / suspended. CF returns
                                  // `failed-precondition`; the streaming availability
                                  // repo yields `[]` to fail-OPEN on transient errors —
                                  // a one-shot probe via [ownerGateStatusProvider]
                                  // discriminates the permanent gate.
                                  if (_propertyId != null &&
                                      _propertyId!.isNotEmpty &&
                                      unitId.isNotEmpty)
                                    Consumer(
                                      builder: (ctx, ref2, _) {
                                        final gate = ref2.watch(
                                          ownerGateStatusProvider(
                                            _propertyId!,
                                            unitId,
                                          ),
                                        );
                                        if (gate.valueOrNull !=
                                            OwnerGateStatus.blocked) {
                                          return const SizedBox.shrink();
                                        }
                                        final tr = WidgetTranslations.of(
                                          ctx,
                                          ref2,
                                        );
                                        final isDark = ref2.watch(
                                          themeProvider,
                                        );
                                        final warnBg = isDark
                                            ? const Color(0x33F87171)
                                            : const Color(0x1AEF4444);
                                        final warnFg = isDark
                                            ? const Color(0xFFF87171)
                                            : const Color(0xFFEF4444);
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            top: 8,
                                            bottom: screenWidth >= 1024
                                                ? 24
                                                : 16,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: warnBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: warnFg.withValues(
                                                  alpha: 0.6,
                                                ),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 20,
                                                  color: warnFg,
                                                ),
                                                const SizedBox(width: 10),
                                                Flexible(
                                                  child: Text(
                                                    tr.propertyUnavailableForBookingsBanner,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: warnFg,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                  // Calendar with lazy loading - shows skeleton first for faster perceived load
                                  // Wrapped in InteractiveViewer for zoom control (mobile web)
                                  // InteractiveViewer allows both zoom and pan/scroll
                                  // Listener captures scroll wheel events for desktop pan support
                                  Listener(
                                    onPointerSignal: (event) {
                                      if (event is PointerScrollEvent) {
                                        _zoom.panByScroll(event.scrollDelta);
                                      }
                                    },
                                    child: InteractiveViewer(
                                      key: _zoom.interactiveViewerKey,
                                      transformationController:
                                          _zoom.controller,
                                      boundaryMargin: const EdgeInsets.all(
                                        double.infinity,
                                      ),
                                      minScale: 1.0,
                                      maxScale: 3.0,
                                      panEnabled: _zoom
                                          .isZoomed, // Pan only when zoomed
                                      scaleEnabled:
                                          false, // Disable pinch - use buttons only
                                      child: LazyCalendarContainer(
                                        // Key forces widget rebuild when returning from confirmation
                                        // Fixes CustomPaint not repainting after Navigator.pop()
                                        key: ValueKey(
                                          'calendar_$_calendarRefreshKey',
                                        ),
                                        propertyId: _propertyId ?? '',
                                        unitId: unitId,
                                        forceMonthView: forceMonthView,
                                        focusedDate: _formState.checkIn,
                                        // Disable date selection in calendar_only mode
                                        onRangeSelected:
                                            widgetMode ==
                                                WidgetMode.calendarOnly
                                            ? null
                                            : (start, end) {
                                                // Validate minimum nights requirement
                                                if (start != null &&
                                                    end != null) {
                                                  // Use unit's minStayNights (source of truth), NOT widget_settings
                                                  final minNights =
                                                      _unit?.minStayNights ?? 1;
                                                  final selectedNights = end
                                                      .difference(start)
                                                      .inDays;

                                                  if (selectedNights <
                                                      minNights) {
                                                    // Show error message
                                                    final tr =
                                                        WidgetTranslations.of(
                                                          context,
                                                          ref,
                                                        );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          tr.minimumNightsRequired(
                                                            minNights,
                                                            selectedNights,
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            minimalistColors
                                                                .error,
                                                        duration:
                                                            const Duration(
                                                              seconds: 3,
                                                            ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                }

                                                if (mounted) {
                                                  setState(() {
                                                    _checkIn = start;
                                                    _checkOut = end;
                                                    // Bug Fix: Date selection IS interaction - show booking flow
                                                    _hasInteractedWithBookingFlow =
                                                        true;
                                                    _pillBarDismissed =
                                                        false; // Reset dismissed flag for new date selection
                                                  });
                                                }

                                                // Bug #53: Save form data after date selection
                                                _saveFormData();
                                              },
                                      ),
                                    ),
                                  ),

                                  // Contact info removed from calendar-only mode
                                  // Host website handles its own contact information

                                  // "Powered by BookBed" branding footer
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      bottom: 4,
                                    ),
                                    child: PoweredByBadge(
                                      text: WidgetTranslations.of(
                                        context,
                                        ref,
                                      ).poweredByBookBed,
                                      color: minimalistColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // OVERLAYS - Outside scroll area for proper viewport positioning

                // Rotate device overlay - full-screen overlay when screen too small for year view
                if (_shouldShowRotateOverlay(context))
                  Positioned.fill(
                    child: RotateDeviceOverlay(
                      isDarkMode: isDarkMode,
                      colors: colors,
                      onSwitchToMonthView: () {
                        ref.read(calendarViewProvider.notifier).state =
                            CalendarViewType.month;
                      },
                      translations: WidgetTranslations.of(context, ref),
                    ),
                  ),

                // Full-screen backdrop overlay when guest form is shown
                if (_showGuestForm)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _showGuestForm = false;
                          });
                        }
                      },
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                // Floating booking summary bar - OUTSIDE scroll for proper centering
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

                // Zoom control buttons (Web only)
                if (kIsWeb)
                  ZoomControlButtons(
                    currentScale: _zoom.scale,
                    onScaleChanged: (newScale) {
                      if (mounted) {
                        setState(() {
                          _zoom.applyCenteredZoom(newScale);
                        });
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
