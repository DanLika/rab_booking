part of 'booking_widget_screen.dart';

/// Stripe payment lifecycle for the booking widget: checkout launch
/// (popup / redirect / mobile), return-with-session polling, payment
/// completion timeout, delayed-payment dialog, and confirmation-screen
/// navigation.
///
/// Extracted verbatim from `_BookingWidgetScreenState` (file split only —
/// zero behavior change).
mixin _PaymentFlowMixin on _BookingWidgetScreenStateBase, _DataLoadingMixin {
  /// Show dialog when Stripe payment succeeded but booking confirmation is delayed
  /// This provides clear instructions to the user instead of a dismissable snackbar
  Future<void> _showPaymentDelayedDialog() async {
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final dialogBg = isDarkMode ? Colors.black : colors.backgroundPrimary;
    final tr = WidgetTranslations.of(context, ref);

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must acknowledge
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(BBRadiusBridges.large),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: colors.success, size: 28),
            const SizedBox(width: BBSpace.xs),
            Expanded(
              child: Text(
                tr.paymentSuccessful,
                style: TextStyle(
                  fontWeight: BBTypeBridges.weightBold,
                  color: colors.textPrimary,
                ),
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
              style: TextStyle(
                fontSize: BBTypeBridges.fontSizeM,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: BBSpace.sm),
            Container(
              padding: const EdgeInsets.all(BBSpace.sm),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(
                  Radius.circular(BBRadiusBridges.medium),
                ),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.whatToDoNext,
                    style: TextStyle(
                      fontSize: BBTypeBridges.fontSizeS,
                      fontWeight: BBTypeBridges.weightBold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BBSpace.xxs),
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
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(BBRadiusBridges.medium),
                ),
              ),
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
      padding: const EdgeInsets.only(top: BBSpace.xxs),
      child: Text(
        text,
        style: TextStyle(
          fontSize: BBTypeBridges.fontSizeS,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  /// Start timeout timer for payment completion
  /// If payment completion message doesn't arrive within timeout period,
  /// reset loading state to prevent infinite loading
  void _startPaymentCompletionTimeout() {
    // Cancel any existing timeout
    _paymentCompletionTimeout?.cancel();

    LoggingService.log(
      '[PaymentTimeout] Starting 30-second timeout timer for payment completion',
      tag: 'STRIPE_TIMEOUT',
    );

    // Set timeout to 30 seconds
    // This gives enough time for webhook to process and message to arrive
    _paymentCompletionTimeout = Timer(const Duration(seconds: 30), () {
      if (!mounted) {
        LoggingService.log(
          '[PaymentTimeout] Widget disposed, timeout cancelled',
          tag: 'STRIPE_TIMEOUT',
        );
        return;
      }

      LoggingService.log(
        '[PaymentTimeout] ⚠️ Payment completion message not received within 30 seconds, resetting loading state',
        tag: 'STRIPE_TIMEOUT',
      );

      // Reset processing state to prevent infinite loading
      if (mounted) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _showGuestForm = false;
          });
        }
        _resetFormState();

        LoggingService.log(
          '[PaymentTimeout] Loading state reset due to timeout',
          tag: 'STRIPE_TIMEOUT',
        );
      }

      _paymentCompletionTimeout = null;
    });
  }

  /// Handle Stripe return when booking is created by webhook (NEW FLOW)
  /// URL has: stripe_status=success&session_id=cs_xxx but NO bookingId
  /// We need to poll Firestore until webhook creates the booking
  Future<void> _handleStripeReturnWithSessionId(String sessionId) async {
    LoggingService.log(
      '[STRIPE_RETURN] Handling Stripe return with session_id: $sessionId',
      tag: 'STRIPE_SESSION',
    );

    // CRITICAL: Cancel timeout since we're handling the return (payment completed)
    _paymentCompletionTimeout?.cancel();
    _paymentCompletionTimeout = null;
    LoggingService.log(
      '[STRIPE_RETURN] Payment completion timeout cancelled',
      tag: 'STRIPE_SESSION',
    );

    // Track payment completion start time for analytics
    final paymentStartTime = DateTime.now().toUtc();

    // Clear any previous error
    if (mounted) {
      setState(() {
        _validationError = null;
      });
    }

    try {
      // T11-hotfix-partial: route through getBookingByStripeSession callable
      // instead of direct Firestore CG read on `stripe_session_id` (rule clause
      // removed from firestore.rules). CF uses Admin SDK + IP rate limiting.
      final lookupService = ref.read(bookingLookupServiceProvider);
      BookingDetailsModel? details;

      // Poll until webhook flips placeholder to status == 'confirmed' (max 30s).
      // 'not-found' from the CF is treated as "webhook in flight" → retry.
      const maxAttempts = 15;
      const pollInterval = Duration(seconds: 2);

      for (var i = 0; i < maxAttempts; i++) {
        LoggingService.log(
          '[STRIPE_RETURN] Polling for booking (attempt ${i + 1}/$maxAttempts)...',
          tag: 'STRIPE_SESSION',
        );

        final fetched = await lookupService.getBookingByStripeSession(
          sessionId,
        );

        if (fetched != null && fetched.status == 'confirmed') {
          details = fetched;
          LoggingService.log(
            '[STRIPE_RETURN] ✅ Found booking: ${fetched.bookingId} (ref: ${fetched.bookingReference})',
            tag: 'STRIPE_SESSION',
          );

          final timeToComplete = DateTime.now()
              .toUtc()
              .difference(paymentStartTime)
              .inSeconds;
          final browser = BrowserDetection.getBrowserName();
          final deviceType = BrowserDetection.getDeviceType();
          unawaited(
            AnalyticsService.instance.logStripePaymentCompleted(
              sessionId: sessionId,
              method: 'redirect',
              browser: browser,
              deviceType: deviceType,
              timeToCompleteSeconds: timeToComplete,
            ),
          );

          break;
        }

        if (i < maxAttempts - 1) {
          await Future.delayed(pollInterval);
          if (!mounted) return;
        }
      }

      if (details == null) {
        LoggingService.log(
          '[STRIPE_RETURN] ❌ Booking not confirmed after ${maxAttempts * pollInterval.inSeconds} seconds',
          tag: 'STRIPE_SESSION',
        );

        if (mounted) {
          await _showPaymentDelayedDialog();
          BookingUrlStateService.clearBookingParams();
          await _validateUnitAndProperty();
        }
        return;
      }

      // Found booking — make sure unit/property data is loaded for downstream UI.
      if (_unit == null && _propertyId != null) {
        await _validateUnitAndProperty();
      }

      // NOTE: DO NOT send payment completion notification here!
      // This function is called AS A RESPONSE to receiving a payment-complete message
      // (from BookingConfirmationScreen or from URL params after Stripe redirect).
      // Sending another message here creates an INFINITE LOOP because:
      // 1. BookingConfirmationScreen sends paymentComplete via BroadcastChannel
      // 2. This widget receives it and calls _handleStripeReturnWithSessionId()
      // 3. If we send paymentComplete again here, BookingConfirmationScreen receives it
      // 4. This triggers another round of processing -> INFINITE LOOP
      //
      // The BookingConfirmationScreen already handles all notification methods:
      // - BroadcastChannel (same-origin tabs)
      // - postMessage (iframe/popup communication)
      // - PaymentBridge (legacy support)

      // Invalidate calendar cache
      ref.invalidate(realtimeYearCalendarProvider);
      ref.invalidate(realtimeMonthCalendarProvider);

      // Navigate to confirmation screen using Navigator.push.
      // `details` (BookingDetailsModel) is the CF-sanitized projection of the
      // booking — we no longer pass a full BookingModel here (was used for
      // popup-window paymentComplete notification, which doesn't apply to the
      // same-tab redirect path).
      final confirmed = details;
      final checkInDt = DateTime.parse(confirmed.checkIn);
      final checkOutDt = DateTime.parse(confirmed.checkOut);
      final totalGuests =
          confirmed.guestCount.adults + confirmed.guestCount.children;
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              bookingReference: confirmed.bookingReference,
              guestEmail: confirmed.guestEmail,
              guestName: confirmed.guestName,
              checkIn: checkInDt,
              checkOut: checkOutDt,
              totalPrice: confirmed.totalPrice,
              roomPrice:
                  _lockedPriceCalculation?.roomPrice ?? confirmed.roomPrice,
              extraGuestFees:
                  _lockedPriceCalculation?.extraGuestFees ??
                  confirmed.extraGuestFees,
              petFees: _lockedPriceCalculation?.petFees ?? confirmed.petFees,
              additionalServicesTotal:
                  _lockedPriceCalculation?.additionalServicesTotal ??
                  confirmed.servicesTotal,
              nights: confirmed.nights,
              guests: totalGuests,
              propertyName: confirmed.propertyName,
              unitName: confirmed.unitName,
              paymentMethod: 'stripe',
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
          BookingUrlStateService.clearBookingParams();
        }
      }
    } catch (e, stackTrace) {
      // Post-payment path: the guest may already be charged at this point, so
      // a failure to surface the confirmed booking must reach Sentry.
      await LoggingService.logError(
        '[STRIPE_RETURN] Failed to load confirmed booking after redirect',
        e,
        stackTrace,
      );

      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(
            context,
            ref,
          ).errorLoadingBooking(safeErrorToString(e)),
          duration: const Duration(seconds: 5),
        );

        // Show calendar anyway
        BookingUrlStateService.clearBookingParams();
        await _validateUnitAndProperty();
      }
    }
  }

  /// Helper method to show confirmation screen for direct bookings
  /// Uses Navigator.push for proper back navigation and transition animation
  /// For pending/bank_transfer/pay_on_arrival modes
  Future<void> _navigateToConfirmationAndCleanup({
    required BookingModel booking,
    required String paymentMethod,
  }) async {
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
    // NOTE: Email is NOT included in URL for security/privacy
    // Use server-generated booking reference (BK-XXXXXXXXXXXX format)
    // to match what's stored in Firestore for resend email lookup
    final bookingRef =
        booking.bookingReference ?? booking.id.substring(0, 8).toUpperCase();
    BookingUrlStateService.addConfirmationParams(
      bookingRef: bookingRef,
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
          roomPrice: _lockedPriceCalculation?.roomPrice,
          extraGuestFees: _lockedPriceCalculation?.extraGuestFees,
          petFees: _lockedPriceCalculation?.petFees,
          additionalServicesTotal:
              _lockedPriceCalculation?.additionalServicesTotal,
          nights: booking.numberOfNights,
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
      BookingUrlStateService.clearBookingParams();
    }

    LoggingService.log(
      '[Navigation] Confirmation screen closed (payment: $paymentMethod)',
      tag: 'NAV',
    );
  }

  /// Handle Stripe payment
  ///
  /// NEW FLOW (2025-12-02):
  /// - No booking created yet - only validation passed
  /// - Pass all booking data to Stripe checkout session
  /// - Booking will be created by webhook after payment succeeds
  ///
  /// Uses PaymentBridge for popup handling in iframe context:
  /// 1. Pre-open popup synchronously on user click (avoids popup blocking)
  /// 2. Create checkout session (async)
  /// 3. Update popup URL with checkout URL
  Future<void> _handleStripePayment({
    required Map<String, dynamic> bookingData,
    required String guestEmail,
  }) async {
    String? popupResult;

    try {
      final stripeService = ref.read(stripeServiceProvider);

      // Build return URL for Stripe redirect
      // IMPORTANT: Flutter Web uses hash routing (e.g., /#/calendar)
      // NOTE: Email is NOT included in URL for security/privacy
      final baseUrl = Uri.base;

      // Validate base URL components
      if (baseUrl.scheme.isEmpty || baseUrl.host.isEmpty) {
        throw Exception('Invalid base URL: scheme or host is empty');
      }

      // CRITICAL: Rewrite the bare marketing domain onto the widget host so
      // the popup/redirect opens where the widget actually runs.
      String returnHost = baseUrl.host;
      if (EnvironmentConfig.isMarketingHost(returnHost)) {
        returnHost = EnvironmentConfig.widgetHost;
      }

      final returnUrlWithoutHash = Uri(
        scheme: baseUrl.scheme,
        host: returnHost,
        port: baseUrl.port,
        queryParameters: {...baseUrl.queryParameters, 'payment': 'stripe'},
      ).toString();

      // Append hash fragment for Flutter's hash-based routing
      final returnUrl = '$returnUrlWithoutHash#/calendar';

      // Validate return URL format
      try {
        final returnUri = Uri.parse(returnUrl);
        if (returnUri.scheme.isEmpty || returnUri.host.isEmpty) {
          throw Exception('Invalid return URL format: scheme or host is empty');
        }
        LoggingService.log(
          '[Stripe] Return URL validated: $returnUrl',
          tag: 'STRIPE',
        );
      } catch (e) {
        unawaited(
          LoggingService.logError(
            '[Stripe] Invalid return URL format: $returnUrl',
            e,
          ),
        );
        throw Exception('Failed to build valid return URL: $e');
      }

      // CRITICAL: Pre-open popup SYNCHRONOUSLY on user click (before async operations)
      // This prevents popup blockers from blocking the window
      if (kIsWeb && isInIframe) {
        // Save booking state before opening popup
        saveBookingStateForPayment(jsonEncode(bookingData));

        // Pre-open popup with placeholder URL (synchronous - must be on user gesture)
        popupResult = preOpenPaymentPopup();
        LoggingService.log(
          '[Stripe] Pre-opened popup, result: $popupResult',
          tag: 'STRIPE',
        );

        // Track payment initiation with analytics
        final browser = BrowserDetection.getBrowserName();
        final deviceType = BrowserDetection.getDeviceType();
        unawaited(
          AnalyticsService.instance.logStripePaymentInitiated(
            method: popupResult,
            browser: browser,
            deviceType: deviceType,
            isInIframe: true,
          ),
        );

        if (popupResult == 'blocked') {
          // Popup blocked - track and show fallback UI
          unawaited(
            AnalyticsService.instance.logStripePopupBlocked(
              browser: browser,
              deviceType: deviceType,
            ),
          );

          if (mounted) {
            setState(() {
              _isProcessing = false;
            });

            // Store checkout URL for dialog (will be set after session creation)
            // For now, show dialog placeholder - will be updated after checkout session is created
            // We need to wait for checkout URL before showing dialog
          }
          // Don't return here - continue to create checkout session
          // Dialog will be shown after checkout URL is available
        } else if (popupResult == 'redirect') {
          // Mobile Safari or mobile device - will redirect after session creation
          LoggingService.log(
            '[Stripe] Will redirect (mobile device)',
            tag: 'STRIPE',
          );
        }
      }

      // Create Stripe checkout session with ALL booking data (async operation)
      // Booking will be created by webhook after successful payment
      LoggingService.logOperation('[Stripe] Creating checkout session...');
      final checkoutResult = await stripeService.createCheckoutSession(
        bookingData: bookingData,
        returnUrl: returnUrl,
      );

      if (checkoutResult.checkoutUrl.isEmpty) {
        throw Exception('Stripe checkout URL is empty');
      }

      LoggingService.logSuccess(
        '[Stripe] Checkout session created: ${checkoutResult.checkoutUrl}',
      );

      // CRITICAL: Clear form data BEFORE redirect/popup
      // This prevents the bug where cached form data loads on return
      // with dates that are now booked, causing false "conflict" error
      await _clearFormData();

      // Handle Stripe Checkout based on context
      if (kIsWeb) {
        if (isInIframe) {
          // CRITICAL: In iframe, NEVER use navigateToUrl() - Stripe blocks nested iframes
          if (popupResult == 'popup') {
            // Iframe + popup opened: update popup URL
            final updated = updatePaymentPopupUrl(checkoutResult.checkoutUrl);
            if (!updated) {
              // Failed to update popup - redirect top-level window (not iframe)
              LoggingService.log(
                '[Stripe] Failed to update popup, redirecting top-level window',
                tag: 'STRIPE',
              );
              redirectTopLevelWindow(checkoutResult.checkoutUrl);

              // Refresh widget: close loading/shimmer and show calendar
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                  _showGuestForm = false;
                });
                _resetFormState();
              }
            } else {
              LoggingService.log(
                '[Stripe] Popup URL updated successfully',
                tag: 'STRIPE',
              );

              // Refresh widget: close loading/shimmer and show calendar (popup is open in separate window)
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                  _showGuestForm = false;
                });
                _resetFormState();
              }

              // CRITICAL: Start timeout timer to reset loading state if payment completion message doesn't arrive
              // This prevents infinite loading if cross-tab communication fails
              LoggingService.log(
                '[Stripe] Starting payment completion timeout (30s)',
                tag: 'STRIPE',
              );

              _startPaymentCompletionTimeout();
            }
          } else if (popupResult == 'redirect') {
            // Iframe + mobile: redirect top-level window (not iframe)
            // NOTE: In redirect scenario, we reset _isProcessing immediately because
            // the page will navigate away. Timeout is not needed here.
            LoggingService.log(
              '[Stripe] Redirecting top-level window (mobile/iframe)',
              tag: 'STRIPE',
            );
            redirectTopLevelWindow(checkoutResult.checkoutUrl);

            // Refresh widget: close loading/shimmer and show calendar
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _showGuestForm = false;
              });
              _resetFormState();
            }
            LoggingService.log(
              '[Stripe] Loading state reset after redirect',
              tag: 'STRIPE',
            );
          } else if (popupResult == 'blocked') {
            // Popup was blocked - automatically redirect (better UX than showing dialog)
            // This eliminates the extra click required to open payment page
            LoggingService.log(
              '[Stripe] Popup blocked - auto-redirecting to top-level window',
              tag: 'STRIPE',
            );

            redirectTopLevelWindow(checkoutResult.checkoutUrl);

            // Reset form state after redirect
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _showGuestForm = false;
              });
              _resetFormState();
            }
            LoggingService.log(
              '[Stripe] Loading state reset after blocked popup redirect',
              tag: 'STRIPE',
            );
            return; // Redirect initiated, don't continue
          } else {
            // Unexpected popupResult value (null, 'error', etc.) - fallback to redirect
            LoggingService.log(
              '[Stripe] Unexpected popupResult: $popupResult, falling back to redirect',
              tag: 'STRIPE',
            );
            redirectTopLevelWindow(checkoutResult.checkoutUrl);

            // Refresh widget: close loading/shimmer and show calendar
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _showGuestForm = false;
              });
              _resetFormState();
            }
          }
        } else {
          // Standalone page (not in iframe): safe to use same-tab redirect
          LoggingService.log(
            '[Stripe] Redirecting in same tab (standalone page)',
            tag: 'STRIPE',
          );
          navigateToUrl(checkoutResult.checkoutUrl);
        }
      } else {
        // Mobile: Use url_launcher (will open in browser)
        final uri = Uri.parse(checkoutResult.checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          final tr = WidgetTranslations.of(context, ref);
          throw tr.couldNotLaunchStripeCheckout;
        }
      }
    } catch (e) {
      unawaited(LoggingService.logError('[Stripe] Error in payment flow', e));
      if (mounted) {
        // Reset processing state on error so user can try again
        setState(() {
          _isProcessing = false;
        });
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(
            context,
            ref,
          ).errorLaunchingStripe(safeErrorToString(e)),
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
  ///
  /// NOTE: Email is NOT required - booking is fetched by bookingId and email is already verified in form
  Future<void> _showConfirmationFromUrl(
    String bookingReference,
    String bookingId, {
    bool fromOtherTab = false,
    String? paymentMethod,
    bool isDirectBooking = false,
  }) async {
    try {
      // Fetch booking from Firestore using booking ID
      final bookingRepo = ref.read(bookingRepositoryProvider);
      var booking = await bookingRepo.fetchBookingById(
        bookingId,
        unitId: _unitId,
      );

      if (booking == null) {
        if (mounted) {
          SnackBarHelper.showWarning(
            context: context,
            message: WidgetTranslations.of(
              context,
              ref,
            ).bookingNotFoundCheckEmail,
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
          // CRITICAL: Check mounted after delay - widget may be disposed during polling
          if (!mounted) return;

          final updatedBooking = await bookingRepo.fetchBookingById(
            bookingId,
            unitId: _unitId,
          );
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

      // Broadcast to other tabs (in case user has multiple tabs open)
      // This is optional now since we redirect in same tab, but useful for edge cases
      if (!fromOtherTab && _tabCommunicationService != null) {
        _tabCommunicationService!.sendPaymentComplete(
          bookingId: bookingId,
          ref: bookingReference,
          sessionId: confirmedBooking.stripeSessionId,
        );
        LoggingService.log(
          '[CrossTab] Broadcasted payment complete to other tabs',
          tag: 'TAB_COMM',
        );
      }

      // CRITICAL: Invalidate calendar cache BEFORE showing confirmation
      // This ensures the calendar will show newly booked dates when user returns
      ref.invalidate(realtimeYearCalendarProvider);
      ref.invalidate(realtimeMonthCalendarProvider);

      // Clear saved form data after successful booking
      await _clearFormData();

      // Determine actual payment method
      final actualPaymentMethod =
          paymentMethod ?? confirmedBooking.paymentMethod ?? 'stripe';

      // Use Navigator.push for ALL booking confirmations
      // This provides proper back navigation and transition animation
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              // Prefer Firestore value over URL-stored reference
              // URL may have old truncated format from before fix
              bookingReference:
                  confirmedBooking.bookingReference ?? bookingReference,
              guestEmail: confirmedBooking.guestEmail ?? '',
              guestName: confirmedBooking.guestName ?? 'Guest',
              checkIn: confirmedBooking.checkIn,
              checkOut: confirmedBooking.checkOut,
              totalPrice: confirmedBooking.totalPrice,
              roomPrice: _lockedPriceCalculation?.roomPrice,
              extraGuestFees: _lockedPriceCalculation?.extraGuestFees,
              petFees: _lockedPriceCalculation?.petFees,
              additionalServicesTotal:
                  _lockedPriceCalculation?.additionalServicesTotal,
              nights: confirmedBooking.checkOut
                  .difference(confirmedBooking.checkIn)
                  .inDays,
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
          BookingUrlStateService.clearBookingParams();
        }
      }
    } catch (e) {
      unawaited(
        LoggingService.logError('Failed to load booking for confirmation', e),
      );
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: WidgetTranslations.of(
            context,
            ref,
          ).errorLoadingBooking(safeErrorToString(e)),
          duration: const Duration(seconds: 5),
        );
      }
    }
  }
}
