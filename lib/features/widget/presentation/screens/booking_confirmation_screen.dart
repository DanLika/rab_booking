import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../mixins/theme_detection_mixin.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/utils/web_utils.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/models/widget_settings.dart';
import '../widgets/common/info_card_widget.dart';
import '../widgets/confirmation/confirmation_header.dart';
import '../widgets/confirmation/booking_reference_card.dart';
import '../widgets/confirmation/email_spam_warning_card.dart';
import '../widgets/confirmation/booking_summary_card.dart';
import '../widgets/confirmation/calendar_export_button.dart';
import '../widgets/confirmation/bank_transfer_instructions_card.dart';
import '../widgets/confirmation/email_confirmation_card.dart';
import '../widgets/confirmation/cancellation_policy_section.dart';
import '../widgets/confirmation/next_steps_section.dart';
import '../l10n/widget_translations.dart';

/// Simplified Booking Confirmation Screen for Embedded Widget
/// Shows booking confirmation with reference number and details
/// Can be accessed via URL: ?confirmation=BOOKING_REF&email=USER_EMAIL
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingReference;
  final String guestEmail;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final int nights;
  final int guests;
  final String propertyName;
  final String? unitName;
  final String paymentMethod;
  final BookingModel? booking;
  final EmailNotificationConfig? emailConfig;
  final WidgetSettings? widgetSettings;

  /// Property ID for clean URL redirect when closing confirmation
  final String? propertyId;

  /// Unit ID for clean URL redirect when closing confirmation
  final String? unitId;

  /// Optional callback for state-based close (direct bookings)
  /// If provided, this is called instead of URL navigation
  final VoidCallback? onClose;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingReference,
    required this.guestEmail,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.nights,
    required this.guests,
    required this.propertyName,
    this.unitName,
    required this.paymentMethod,
    this.booking,
    this.emailConfig,
    this.widgetSettings,
    this.propertyId,
    this.unitId,
    this.onClose,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin, ThemeDetectionMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    // If in popup window (opened from iframe), send message to parent
    if (kIsWeb && isPopupWindow && widget.booking != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyParentOfPaymentComplete();
      });
    }
  }

  /// Notify parent window (iframe) that payment is complete
  /// Uses multiple methods for reliability:
  /// 1. BroadcastChannel (works for same-origin tabs/windows - most reliable)
  /// 2. postMessage (works for iframe/popup communication)
  /// 3. Auto-close popup (only if opened as popup)
  void _notifyParentOfPaymentComplete() {
    final booking = widget.booking;
    if (booking == null) {
      LoggingService.log('[PaymentComplete] Cannot notify - booking is null', tag: 'STRIPE');
      return;
    }

    final bookingId = booking.id;
    final bookingRef = widget.bookingReference;

    if (bookingId.isEmpty || bookingRef.isEmpty) {
      LoggingService.log('[PaymentComplete] Cannot notify - missing bookingId or bookingRef', tag: 'STRIPE');
      return;
    }

    // Extract session ID from URL if available (for PaymentBridge)
    final uri = Uri.base;
    final sessionId = uri.queryParameters['session_id'] ?? uri.queryParameters['stripe_session_id'] ?? '';

    final message = {
      'type': 'stripe-payment-complete',
      'source': 'bookbed-widget',
      'bookingId': bookingId,
      'bookingRef': bookingRef,
      if (sessionId.isNotEmpty) 'sessionId': sessionId,
    };

    LoggingService.log(
      '[PaymentComplete] Notifying parent with bookingId: $bookingId, bookingRef: $bookingRef, sessionId: ${sessionId.isNotEmpty ? sessionId : "N/A"}',
      tag: 'STRIPE',
    );

    // Method 1: PaymentBridge.notifyComplete (most reliable for popup scenarios)
    // This handles BroadcastChannel, postMessage, and localStorage fallbacks
    if (kIsWeb) {
      try {
        if (sessionId.isNotEmpty) {
          notifyPaymentComplete(sessionId, 'success');
          LoggingService.log('[PaymentComplete] Sent via PaymentBridge with sessionId: $sessionId', tag: 'STRIPE');
        } else {
          LoggingService.log('[PaymentComplete] PaymentBridge skipped - no sessionId in URL', tag: 'STRIPE');
        }
      } catch (e) {
        LoggingService.log('[PaymentComplete] PaymentBridge failed: $e', tag: 'STRIPE');
      }
    }

    // Method 2: BroadcastChannel (works for same-origin tabs/windows)
    // This is the most reliable method when popup is blocked and opens in new tab
    if (kIsWeb) {
      try {
        final tabService = createTabCommunicationService();
        tabService.sendPaymentComplete(bookingId: bookingId, ref: bookingRef);
        LoggingService.log('[PaymentComplete] Sent via BroadcastChannel', tag: 'STRIPE');
        // Dispose after sending (one-time use) - delay to ensure message is sent
        Future.delayed(const Duration(seconds: 2), () {
          try {
            tabService.dispose();
          } catch (_) {
            // Ignore disposal errors
          }
        });
      } catch (e) {
        LoggingService.log('[PaymentComplete] BroadcastChannel failed: $e', tag: 'STRIPE');
        // Retry once after short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final retryTabService = createTabCommunicationService();
            retryTabService.sendPaymentComplete(bookingId: bookingId, ref: bookingRef);
            LoggingService.log('[PaymentComplete] Retry sent via BroadcastChannel', tag: 'STRIPE');
            Future.delayed(const Duration(seconds: 2), () {
              try {
                retryTabService.dispose();
              } catch (_) {
                // Ignore disposal errors
              }
            });
          } catch (retryError) {
            LoggingService.log('[PaymentComplete] BroadcastChannel retry failed: $retryError', tag: 'STRIPE');
          }
        });
      }
    }

    // Method 3: postMessage (works for iframe/popup communication)
    // Only works if opened as popup (window.opener exists)
    if (kIsWeb && isPopupWindow) {
      try {
        sendMessageToParent(message);
        LoggingService.log('[PaymentComplete] Sent via postMessage', tag: 'STRIPE');
        // Retry postMessage once after short delay for reliability
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            sendMessageToParent(message);
            LoggingService.log('[PaymentComplete] Retry sent via postMessage', tag: 'STRIPE');
          } catch (e) {
            LoggingService.log('[PaymentComplete] postMessage retry failed: $e', tag: 'STRIPE');
          }
        });
      } catch (e) {
        LoggingService.log('[PaymentComplete] postMessage failed: $e', tag: 'STRIPE');
      }
    }

    // Method 4: Close popup after short delay (allows message to be received)
    // Only close if we're in a popup window (opened from iframe)
    if (kIsWeb && isPopupWindow) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
          final closed = closePopupWindow();
          if (closed) {
            LoggingService.log('[PaymentComplete] Popup window closed', tag: 'STRIPE');
          } else {
            LoggingService.log(
              '[PaymentComplete] Popup could not be auto-closed (user can close manually)',
              tag: 'STRIPE',
            );
          }
        } catch (e) {
          LoggingService.log('[PaymentComplete] Error closing popup: $e', tag: 'STRIPE');
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect system theme on first load (only once to preserve manual toggle)
    detectSystemTheme();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate back to calendar
  /// Uses Navigator.pop() which works for:
  /// - Direct bookings (Pay on Arrival, Bank Transfer) - pushed via Navigator
  /// - Stripe returns - also pushed via Navigator
  /// The parent widget handles form reset and URL cleanup after pop
  void _navigateToCleanCalendar() {
    // If in popup window (opened from iframe), close the popup
    if (kIsWeb && isPopupWindow) {
      sendMessageToParent({'type': 'stripe-popup-close', 'source': 'bookbed-widget'});
      // Try to close popup window
      Future.delayed(const Duration(milliseconds: 100), closePopupWindow);
      return;
    }

    // If in new tab (not popup), don't navigate - just show message
    // User should manually close the tab
    if (kIsWeb && !isPopupWindow && widget.paymentMethod == 'stripe') {
      // In new tab, we can't navigate back to iframe
      // Just show a message or do nothing
      LoggingService.log(
        '[NavigateBack] Cannot navigate back from new tab - user should close tab manually',
        tag: 'STRIPE',
      );
      return;
    }

    // Priority 1: Custom close callback (if provided)
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }

    // Priority 2: Navigator.pop() - works for all Navigator.push scenarios
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Check if we should show navigation buttons
  /// Hide them if we're in a new tab (not popup) after Stripe payment
  bool get _shouldShowNavigationButtons {
    if (!kIsWeb) return true;

    // If in new tab (not popup) and this is a Stripe payment, hide buttons
    // User should manually close the tab
    if (!isPopupWindow && widget.paymentMethod == 'stripe') {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final tr = WidgetTranslations.of(context, ref);

    // Extract widget settings values safely to avoid null check operator errors
    final widgetSettings = widget.widgetSettings;
    final bankConfig = widgetSettings?.bankTransferConfig;
    final hasBankTransferDetails = bankConfig?.hasCompleteDetails == true;
    final cancellationDeadlineHours = widgetSettings?.cancellationDeadlineHours;
    final allowGuestCancellation = widgetSettings?.allowGuestCancellation == true;

    // Use pure black background for dark theme in widget
    final backgroundColor = isDarkMode ? ColorTokens.pureBlack : colors.backgroundPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          left: false,
          right: false,
          child: Column(
            children: [
              // Custom header with centered title and back button
              _buildHeader(colors),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(SpacingTokens.l),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Animated header with icon and message
                          ConfirmationHeader(
                            paymentMethod: widget.paymentMethod,
                            colors: colors,
                            scaleAnimation: _scaleAnimation,
                            customLogoUrl: widget.widgetSettings?.themeOptions?.customLogoUrl,
                          ),

                          const SizedBox(height: SpacingTokens.m),

                          // Payment verification warning (Stripe pending)
                          if (_shouldShowPaymentVerificationWarning)
                            Padding(
                              padding: const EdgeInsets.only(bottom: SpacingTokens.m),
                              child: InfoCardWidget(
                                title: tr.paymentVerificationInProgress,
                                message: tr.paymentVerificationMessage,
                                isDarkMode: isDarkMode,
                              ),
                            ),

                          // Booking reference card
                          BookingReferenceCard(bookingReference: widget.bookingReference, colors: colors),

                          const SizedBox(height: SpacingTokens.m),

                          // Email spam folder warning
                          EmailSpamWarningCard(colors: colors),

                          const SizedBox(height: SpacingTokens.l),

                          // Booking summary card
                          BookingSummaryCard(
                            propertyName: widget.propertyName,
                            unitName: widget.unitName,
                            guestName: widget.guestName,
                            guestEmail: widget.guestEmail,
                            checkIn: widget.checkIn,
                            checkOut: widget.checkOut,
                            nights: widget.nights,
                            guests: widget.guests,
                            totalPrice: widget.totalPrice,
                            isDarkMode: isDarkMode,
                            colors: colors,
                          ),

                          const SizedBox(height: SpacingTokens.l),

                          // Calendar export button (always enabled)
                          if (widget.booking != null)
                            CalendarExportButton(
                              booking: widget.booking!,
                              unitName: widget.unitName ?? widget.propertyName,
                              bookingReference: widget.bookingReference,
                              colors: colors,
                            ),

                          // Bank transfer instructions
                          if (widget.paymentMethod == 'bank_transfer' && hasBankTransferDetails && bankConfig != null)
                            BankTransferInstructionsCard(
                              bankConfig: bankConfig,
                              bookingReference: widget.bookingReference,
                              colors: colors,
                            ),

                          // Email confirmation with resend option
                          EmailConfirmationCard(
                            guestEmail: widget.guestEmail,
                            colors: colors,
                            booking: widget.booking,
                            emailConfig: widget.emailConfig,
                            widgetSettings: widget.widgetSettings,
                            propertyName: widget.propertyName,
                            bookingReference: widget.bookingReference,
                          ),

                          // Cancellation policy
                          if (allowGuestCancellation && cancellationDeadlineHours != null)
                            CancellationPolicySection(
                              isDarkMode: isDarkMode,
                              deadlineHours: cancellationDeadlineHours,
                              bookingReference: widget.bookingReference,
                              fromEmail: widget.emailConfig?.fromEmail,
                            ),

                          // Next steps section
                          NextStepsSection(isDarkMode: isDarkMode, paymentMethod: widget.paymentMethod),

                          const SizedBox(height: SpacingTokens.xl),

                          const SizedBox(height: SpacingTokens.m),

                          // Close button with extra bottom padding (only show if navigation is allowed)
                          if (_shouldShowNavigationButtons) ...[
                            _buildCloseButton(colors, isDark: isDarkMode),
                            const SizedBox(height: SpacingTokens.xl),
                          ] else ...[
                            // Show message for new tab scenario
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
                              child: Text(
                                tr.bookingConfirmedCloseTab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeM,
                                  color: colors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.xl),
                          ],

                          // Helpful info
                          Text(
                            tr.saveBookingReference,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _shouldShowPaymentVerificationWarning {
    final booking = widget.booking;
    if (widget.paymentMethod != 'stripe' || booking == null) {
      return false;
    }
    // Defensive null checks for payment status and booking status
    final paymentStatus = booking.paymentStatus;
    // Note: status.value is non-nullable String, but add defensive check for paymentStatus
    final bookingStatus = booking.status.value;
    return paymentStatus == 'pending' || bookingStatus == 'pending';
  }

  Widget _buildHeader(WidgetColorScheme colors) {
    final tr = WidgetTranslations.of(context, ref);
    final showNavButtons = _shouldShowNavigationButtons;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.m, vertical: SpacingTokens.s),
      child: Row(
        children: [
          if (showNavButtons)
            IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: _navigateToCleanCalendar,
            )
          else
            const SizedBox(width: 48), // Spacer when button is hidden
          Expanded(
            child: Center(
              child: Text(
                tr.bookingConfirmation,
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeXL,
                  fontWeight: TypographyTokens.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance back button
        ],
      ),
    );
  }

  Widget _buildCloseButton(WidgetColorScheme colors, {required bool isDark}) {
    final tr = WidgetTranslations.of(context, ref);
    // Use white button with black text for dark theme
    final buttonBg = isDark ? ColorTokens.pureWhite : colors.buttonPrimary;
    final buttonText = isDark ? ColorTokens.pureBlack : colors.buttonPrimaryText;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToCleanCalendar,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: buttonText,
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
          shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularRounded),
        ),
        child: Text(
          tr.close,
          style: const TextStyle(fontSize: TypographyTokens.fontSizeL, fontWeight: TypographyTokens.bold),
        ),
      ),
    );
  }
}
