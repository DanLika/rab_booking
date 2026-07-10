part of 'booking_widget_screen.dart';

/// Cross-tab / postMessage / PaymentBridge plumbing for the booking widget.
///
/// Extracted verbatim from `_BookingWidgetScreenState` (file split only —
/// zero behavior change). Handles BroadcastChannel messages from other tabs,
/// postMessage from Stripe popup windows, and the PaymentBridge JS-interop
/// listener used in iframe embeds.
mixin _CrossTabMixin
    on _BookingWidgetScreenStateBase, _DataLoadingMixin, _PaymentFlowMixin {
  /// Initialize cross-tab communication service for Stripe payment notifications
  /// Only runs on web platform - uses BroadcastChannel API
  void _initTabCommunication() {
    if (!kIsWeb) return; // Only on web platform

    try {
      // LOW: Cancel any existing subscription to prevent memory leak
      // (safety measure in case this method is called multiple times)
      _tabMessageSubscription?.cancel();
      _tabCommunicationService?.dispose();
      _postMessageListenerCleanup?.call();

      // Create platform-appropriate service instance
      // (createTabCommunicationService uses conditional import)
      _tabCommunicationService = createTabCommunicationService();

      // Listen for messages from other tabs
      _tabMessageSubscription = _tabCommunicationService!.messageStream.listen(
        _handleTabMessage,
      );

      // If in iframe, also listen for postMessage from popup windows
      if (isInIframe) {
        _postMessageListenerCleanup = listenToParentMessages(
          _handlePostMessage,
        );
        LoggingService.log(
          '[PostMessage] Initialized listener for popup communication',
          tag: 'POSTMESSAGE',
        );

        // Also setup PaymentBridge listener for payment completion
        if (kIsWeb) {
          _setupPaymentBridgeListener();
        }
      }

      LoggingService.log(
        '[CrossTab] Initialized cross-tab communication listener',
        tag: 'TAB_COMM',
      );
    } catch (e) {
      unawaited(LoggingService.logError('[CrossTab] Failed to initialize', e));
    }
  }

  /// Setup PaymentBridge listener for payment completion
  void _setupPaymentBridgeListener() {
    if (!kIsWeb) return;

    try {
      // Setup listener using JS interop
      // PaymentBridge will call this callback when payment completes
      // Wrap Dart function in JS interop
      void callback(String resultJson) {
        try {
          final result = jsonDecode(resultJson) as Map<String, dynamic>;
          final type = result['type'] as String?;

          if (type == 'PAYMENT_COMPLETE') {
            final sessionId = result['sessionId'] as String?;
            final status = result['status'] as String?;

            if (sessionId != null && status == 'success') {
              LoggingService.log(
                '[PaymentBridge] Payment complete received, sessionId: $sessionId',
                tag: 'STRIPE',
              );

              // CRITICAL: Cancel timeout since we received the message
              if (_paymentCompletionTimeout != null) {
                _paymentCompletionTimeout!.cancel();
                _paymentCompletionTimeout = null;

                LoggingService.log(
                  '[PaymentBridge] Payment completion timeout cancelled (message received)',
                  tag: 'STRIPE',
                );
              }

              // Handle payment completion by polling for booking
              // This is called when payment completes in popup and sends message to iframe
              if (mounted) {
                // Reset processing state FIRST (before any async operations)
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                }

                LoggingService.log(
                  '[PaymentBridge] Loading state reset (message received)',
                  tag: 'STRIPE',
                );

                // Handle Stripe return with session ID (same as URL-based flow)
                _handleStripeReturnWithSessionId(sessionId);
              }
            }
          }
        } catch (e) {
          LoggingService.log(
            '[PaymentBridge] Error handling payment result: $e',
            tag: 'STRIPE',
          );
          // On error, still reset processing state
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }

      setupPaymentResultListener(callback);

      LoggingService.log(
        '[PaymentBridge] Listener setup complete',
        tag: 'STRIPE',
      );
    } catch (e) {
      LoggingService.log(
        '[PaymentBridge] Failed to setup listener: $e',
        tag: 'STRIPE',
      );
    }
  }

  /// Handle postMessage from popup window (Stripe checkout return)
  /// This is called when payment completes in popup and sends message to iframe parent
  /// Also handles BroadcastChannel messages from new tabs (when popup is blocked)
  void _handlePostMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final type = message['type'] as String?;
    final source = message['source'] as String?;

    // Only handle messages from our widget
    if (source != 'bookbed-widget' || type == null) return;

    LoggingService.log('[PostMessage] Received: $type', tag: 'POSTMESSAGE');

    switch (type) {
      case 'stripe-payment-complete':
        final bookingId = message['bookingId'] as String?;
        final bookingRef = message['bookingRef'] as String?;
        final sessionId = message['sessionId'] as String?;

        // NOTE: Email is NOT required - booking is fetched by sessionId or bookingId
        if (bookingId != null && bookingRef != null) {
          LoggingService.log(
            '[PostMessage] Payment complete, showing confirmation',
            tag: 'POSTMESSAGE',
          );

          // CRITICAL: Cancel timeout since we received the message
          if (_paymentCompletionTimeout != null) {
            _paymentCompletionTimeout!.cancel();
            _paymentCompletionTimeout = null;
            LoggingService.log(
              '[PostMessage] Payment completion timeout cancelled (message received)',
              tag: 'POSTMESSAGE',
            );
          }

          // CRITICAL: Reset processing state FIRST (before any async operations)
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            LoggingService.log(
              '[PostMessage] Loading state reset (message received)',
              tag: 'POSTMESSAGE',
            );
          }

          // Prefer sessionId for lookup (avoids documentId collection group query bug)
          if (sessionId != null && sessionId.isNotEmpty) {
            LoggingService.log(
              '[PostMessage] Using sessionId for lookup: $sessionId',
              tag: 'POSTMESSAGE',
            );
            _clearFormData().then((_) {
              if (mounted) {
                _handleStripeReturnWithSessionId(sessionId);
              }
            });
          } else {
            // Fallback to bookingId lookup (may fail with collection group query)
            LoggingService.log(
              '[PostMessage] No sessionId, falling back to bookingId lookup',
              tag: 'POSTMESSAGE',
            );
            _clearFormData().then((_) {
              if (mounted) {
                _showConfirmationFromUrl(
                  bookingRef,
                  bookingId,
                  fromOtherTab: true,
                );
              }
            });
          }
        } else {
          LoggingService.log(
            '[PostMessage] Invalid payment complete message - missing bookingId or bookingRef',
            tag: 'POSTMESSAGE',
          );
          // Still reset processing state even if message is invalid
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
        break;
      case 'stripe-popup-close':
        // User wants to close popup - reset processing state
        LoggingService.log(
          '[PostMessage] Popup close requested',
          tag: 'POSTMESSAGE',
        );

        // Cancel timeout since popup was closed
        _paymentCompletionTimeout?.cancel();
        _paymentCompletionTimeout = null;

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        break;
    }
  }

  // REMOVED: _monitorStripePopup - no longer needed since Stripe redirects in same tab
  // (consistent with other payment methods: Bank Transfer, Pay on Arrival, etc.)

  /// Handle messages received from other browser tabs
  /// When payment completes in Tab B, this tab (Tab A) receives the notification
  void _handleTabMessage(TabMessage message) {
    // SAFETY: Check mounted before handling tab messages
    // Stream may fire after widget disposal
    if (!mounted) return;

    LoggingService.log(
      '[CrossTab] Received message: ${message.type}',
      tag: 'TAB_COMM',
    );

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
  /// This handles the case when popup is blocked and Stripe opens in new tab
  /// NOTE: Email is NOT required - booking is fetched by bookingId
  Future<void> _handlePaymentCompleteFromOtherTab(TabMessage message) async {
    final bookingId = message.bookingId;
    final bookingRef = message.bookingRef;
    final sessionId = message.sessionId;

    if (bookingId == null || bookingRef == null) {
      LoggingService.log(
        '[CrossTab] Invalid payment complete message - missing params',
        tag: 'TAB_COMM_ERROR',
      );
      // Still reset processing state even if message is invalid
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    LoggingService.log(
      '[CrossTab] Payment complete received for booking: $bookingRef, sessionId: ${sessionId ?? "N/A"}',
      tag: 'TAB_COMM',
    );

    // CRITICAL: Cancel timeout since we received the message
    if (_paymentCompletionTimeout != null) {
      _paymentCompletionTimeout!.cancel();
      _paymentCompletionTimeout = null;
      LoggingService.log(
        '[CrossTab] Payment completion timeout cancelled (message received)',
        tag: 'TAB_COMM',
      );
    }

    // CRITICAL: Reset processing state FIRST (before any async operations)
    // This is important for iframe loading state - must happen immediately
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      LoggingService.log(
        '[CrossTab] Loading state reset (message received)',
        tag: 'TAB_COMM',
      );
    }

    // Track payment completion with analytics (from other tab/popup)
    final browser = BrowserDetection.getBrowserName();
    final deviceType = BrowserDetection.getDeviceType();
    unawaited(
      AnalyticsService.instance.logStripePaymentCompleted(
        sessionId: bookingId, // Use bookingId as session identifier
        method: 'popup', // This came from popup/new tab
        browser: browser,
        deviceType: deviceType,
        timeToCompleteSeconds:
            0, // Time tracking not available for cross-tab messages
      ),
    );

    // CRITICAL: Clear form data and reset state BEFORE showing confirmation
    // This prevents the bug where pressing "back" shows old form data
    await _clearFormData();
    _resetFormState();

    // Navigate to confirmation screen
    // Prefer sessionId for lookup (avoids documentId collection group query bug)
    if (mounted) {
      if (sessionId != null && sessionId.isNotEmpty) {
        LoggingService.log(
          '[CrossTab] Using sessionId for lookup: $sessionId',
          tag: 'TAB_COMM',
        );
        await _handleStripeReturnWithSessionId(sessionId);
      } else {
        // Fallback to bookingId lookup (may fail with collection group query)
        LoggingService.log(
          '[CrossTab] No sessionId, falling back to bookingId lookup',
          tag: 'TAB_COMM',
        );
        await _showConfirmationFromUrl(
          bookingRef,
          bookingId,
          fromOtherTab: true,
        );
      }
    }
  }
}
