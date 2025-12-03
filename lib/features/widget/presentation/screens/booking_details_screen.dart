import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/theme_provider.dart';
import '../mixins/theme_detection_mixin.dart';
import '../../domain/models/booking_details_model.dart';
import '../../domain/models/widget_settings.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
import '../widgets/details/booking_status_banner.dart';
import '../widgets/details/details_reference_card.dart';
import '../widgets/details/property_info_card.dart';
import '../widgets/details/booking_dates_card.dart';
import '../widgets/details/payment_info_card.dart';
import '../widgets/details/contact_owner_card.dart';
import '../widgets/details/cancellation_policy_card.dart';
import '../widgets/details/booking_notes_card.dart';
import '../widgets/details/cancel_confirmation_dialog.dart';

/// Booking Details Screen
/// Displays complete booking information for guest (accessed from email link)
///
/// This screen is separate from BookingConfirmationScreen which shows
/// immediately after booking is created. This screen is for guests
/// returning to view/manage their booking.
class BookingDetailsScreen extends ConsumerStatefulWidget {
  final BookingDetailsModel booking;
  final WidgetSettings? widgetSettings;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
    this.widgetSettings,
  });

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen>
    with SingleTickerProviderStateMixin, ThemeDetectionMixin {
  bool _isCancelling = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Local state for booking status (updated after cancellation)
  // This allows UI to reflect cancelled state without refetching from Firestore
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    // Initialize local status from widget (allows UI update after cancellation)
    _currentStatus = widget.booking.status;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
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

  /// Check if booking can be cancelled based on cancellation deadline
  bool _canCancelBooking() {
    // Only confirmed, approved, or pending bookings can be cancelled
    // Use local _currentStatus which updates after cancellation
    final status = _currentStatus.toLowerCase();
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
      return false;
    }

    // If widget settings not available, allow cancellation (owner can decide)
    if (widget.widgetSettings == null) {
      return true;
    }

    // Check if guest cancellation is enabled
    if (!widget.widgetSettings!.allowGuestCancellation) {
      return false;
    }

    // Check cancellation deadline with safe date parsing
    final deadlineHours =
        widget.widgetSettings!.cancellationDeadlineHours ?? 48;
    try {
      final checkInDate = DateTime.parse(widget.booking.checkIn);
      final now = DateTime.now();
      final hoursUntilCheckIn = checkInDate.difference(now).inHours;
      return hoursUntilCheckIn >= deadlineHours;
    } catch (e) {
      // If date parsing fails, allow cancellation (owner can decide)
      debugPrint('[BookingDetails] Failed to parse checkIn date: $e');
      return true;
    }
  }

  /// Get reason why booking cannot be cancelled (for tooltip)
  String? _getCancelDisabledReason() {
    // Use local _currentStatus which updates after cancellation
    final status = _currentStatus.toLowerCase();
    if (status == 'cancelled') {
      return 'This booking is already cancelled';
    }
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
      return 'This booking cannot be cancelled';
    }

    if (widget.widgetSettings != null &&
        !widget.widgetSettings!.allowGuestCancellation) {
      return 'Guest cancellation is not enabled for this property';
    }

    final deadlineHours =
        widget.widgetSettings?.cancellationDeadlineHours ?? 48;

    // Safe date parsing with try-catch
    try {
      final checkInDate = DateTime.parse(widget.booking.checkIn);
      final now = DateTime.now();
      final hoursUntilCheckIn = checkInDate.difference(now).inHours;

      if (hoursUntilCheckIn < deadlineHours) {
        return 'Cancellation deadline has passed ($deadlineHours hours before check-in)';
      }
    } catch (e) {
      // If date parsing fails, don't block cancellation
      debugPrint('[BookingDetails] Failed to parse checkIn date for tooltip: $e');
    }

    return null;
  }

  /// Handle booking cancellation
  Future<void> _handleCancelBooking() async {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CancelConfirmationDialog(
        bookingReference: widget.booking.bookingReference,
        colors: colors,
        isDarkMode: isDarkMode,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      // Call Cloud Function to cancel booking
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('guestCancelBooking');

      final result = await callable.call({
        'booking_id': widget.booking.bookingId,
        'booking_reference': widget.booking.bookingReference,
        'guest_email': widget.booking.guestEmail,
      });

      if (mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: result.data['message'] ??
              'Booking cancelled successfully. You will receive a confirmation email.',
          duration: const Duration(seconds: 5),
        );

        // Update local state to reflect cancellation
        // This immediately updates UI without needing to refetch from Firestore
        setState(() {
          _currentStatus = 'cancelled';
          _isCancelling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        SnackBarHelper.showError(
          context: context,
          message: 'Failed to cancel booking: ${e.toString()}',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Use pure black background for dark theme in widget
    final backgroundColor =
        isDarkMode ? ColorTokens.pureBlack : colors.backgroundPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Custom header with centered title (no back button)
              _buildHeader(colors),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(SpacingTokens.l),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status banner - full width
                          // Uses _currentStatus which updates after cancellation
                          BookingStatusBanner(
                            status: _currentStatus,
                            colors: colors,
                          ),

                          const SizedBox(height: SpacingTokens.l),

                          // Booking reference - full width, prominent
                          DetailsReferenceCard(
                            bookingReference: widget.booking.bookingReference,
                            colors: colors,
                          ),

                          const SizedBox(height: SpacingTokens.l),

                          // Single column layout
                          _buildContentCards(colors, isDarkMode),

                          const SizedBox(height: SpacingTokens.xl),

                          // Action buttons - full width
                          _buildActionButtons(colors, isDarkMode),

                          const SizedBox(height: SpacingTokens.m),

                          // Help text
                          Text(
                            'Need help? Contact the property owner using the information above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: TypographyTokens.fontSizeS,
                              color: colors.textTertiary,
                            ),
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

  /// Custom header with centered title (no back button for email link access)
  Widget _buildHeader(WidgetColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.m,
        vertical: SpacingTokens.s,
      ),
      child: Center(
        child: Text(
          'My Booking',
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeXL,
            fontWeight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Single column content cards
  Widget _buildContentCards(WidgetColorScheme colors, bool isDarkMode) {
    return Column(
      children: [
        PropertyInfoCard(
          propertyName: widget.booking.propertyName,
          unitName: widget.booking.unitName,
          colors: colors,
        ),
        const SizedBox(height: SpacingTokens.m),
        BookingDatesCard(
          checkIn: widget.booking.checkIn,
          checkOut: widget.booking.checkOut,
          nights: widget.booking.nights,
          adults: widget.booking.guestCount.adults,
          children: widget.booking.guestCount.children,
          colors: colors,
        ),
        const SizedBox(height: SpacingTokens.m),
        PaymentInfoCard(
          totalPrice: widget.booking.totalPrice,
          depositAmount: widget.booking.depositAmount,
          paidAmount: widget.booking.paidAmount,
          remainingAmount: widget.booking.remainingAmount,
          paymentStatus: widget.booking.paymentStatus,
          paymentMethod: widget.booking.paymentMethod,
          paymentDeadline: widget.booking.paymentDeadline,
          colors: colors,
        ),
        // Contact info
        if (widget.booking.ownerEmail != null ||
            widget.booking.ownerPhone != null) ...[
          const SizedBox(height: SpacingTokens.m),
          ContactOwnerCard(
            ownerEmail: widget.booking.ownerEmail,
            ownerPhone: widget.booking.ownerPhone,
            colors: colors,
          ),
        ],
        // Cancellation policy
        if (widget.widgetSettings != null &&
            widget.widgetSettings!.allowGuestCancellation) ...[
          const SizedBox(height: SpacingTokens.m),
          CancellationPolicyCard(
            deadlineHours:
                widget.widgetSettings!.cancellationDeadlineHours ?? 48,
            checkIn: widget.booking.checkIn,
            colors: colors,
          ),
        ],
        // Notes
        if (widget.booking.notes != null &&
            widget.booking.notes!.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.m),
          BookingNotesCard(
            notes: widget.booking.notes!,
            colors: colors,
          ),
        ],
      ],
    );
  }

  /// Action buttons (Cancel booking if allowed)
  Widget _buildActionButtons(WidgetColorScheme colors, bool isDarkMode) {
    final canCancel = _canCancelBooking();
    final cancelReason = _getCancelDisabledReason();
    // Use _currentStatus which updates after cancellation
    final status = _currentStatus.toLowerCase();
    final isCancelled = status == 'cancelled';

    // Cancel button colors based on theme (from ColorTokens)
    final cancelBg = colors.statusCancelledBackground;
    final cancelText = isDarkMode ? ColorTokens.pureWhite : ColorTokens.pureBlack;

    // If booking is cancelled, don't show cancel button
    if (isCancelled) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: cancelReason ?? '',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canCancel && !_isCancelling ? _handleCancelBooking : null,
          icon: _isCancelling
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cancelText,
                  ),
                )
              : Icon(
                  Icons.cancel_outlined,
                  color: canCancel ? cancelText : colors.textTertiary,
                ),
          label: Text(
            _isCancelling ? 'Cancelling...' : 'Cancel Booking',
            style: const TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canCancel ? cancelBg : colors.buttonDisabled,
            foregroundColor: canCancel ? cancelText : colors.textTertiary,
            disabledBackgroundColor: colors.buttonDisabled,
            disabledForegroundColor: colors.textTertiary,
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
            shape: RoundedRectangleBorder(
              borderRadius: BorderTokens.circularRounded,
            ),
          ),
        ),
      ),
    );
  }
}
