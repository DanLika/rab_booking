import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../mixins/theme_detection_mixin.dart';
import '../../domain/models/booking_details_model.dart';
import '../../domain/models/widget_settings.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
import '../widgets/details/booking_status_banner.dart';
import '../widgets/details/details_reference_card.dart';
import '../widgets/details/property_info_card.dart';
import '../widgets/details/guest_info_card.dart';
import '../widgets/details/booking_dates_card.dart';
import '../widgets/details/payment_info_card.dart';
import '../widgets/details/contact_owner_card.dart';
import '../widgets/details/cancellation_policy_card.dart';
import '../widgets/details/booking_notes_card.dart';
import '../widgets/details/cancel_confirmation_dialog.dart';
import '../widgets/details/bank_transfer_details_card.dart';
import '../l10n/widget_translations.dart';

/// Booking Details Screen
/// Displays complete booking information for guest (accessed from email link)
///
/// This screen is separate from BookingConfirmationScreen which shows
/// immediately after booking is created. This screen is for guests
/// returning to view/manage their booking.
class BookingDetailsScreen extends ConsumerStatefulWidget {
  final BookingDetailsModel booking;
  final WidgetSettings? widgetSettings;

  const BookingDetailsScreen({super.key, required this.booking, this.widgetSettings});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen>
    with SingleTickerProviderStateMixin, ThemeDetectionMixin {
  bool _isCancelling = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Local state for booking status (updated after cancellation)
  // This allows UI to reflect cancelled state without refetching from Firestore
  late String _currentStatus;

  /// Safely convert error to string, handling null and edge cases
  /// Prevents "Null check operator used on a null value" errors
  static String _safeErrorToString(dynamic error) {
    if (error == null) {
      return 'Unknown error';
    }
    try {
      return error.toString();
    } catch (e) {
      // If toString() itself throws, return a safe fallback
      return 'Error: Unable to display error details';
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize local status from widget (allows UI update after cancellation)
    // Note: status is already a String in BookingDetailsModel
    _currentStatus = widget.booking.status;

    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

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

  /// Safely parse check-in date and calculate hours until check-in
  /// Returns null if parsing fails
  ///
  /// Normalizes both dates to UTC before calculation to ensure accurate
  /// hours calculation regardless of user timezone. Cloud Function returns
  /// checkIn as ISO 8601 string in UTC format (e.g., "2024-01-15T10:00:00.000Z").
  int? _getHoursUntilCheckIn() {
    try {
      final checkInDate = DateTime.parse(widget.booking.checkIn);
      // Cloud Function returns ISO 8601 string in UTC format (with 'Z' suffix)
      // DateTime.parse() preserves timezone, so checkInDate is already UTC
      // Normalize to UTC to be safe (handles edge cases where string might not have 'Z')
      final checkInUtc = checkInDate.isUtc ? checkInDate : checkInDate.toUtc();

      // Use UTC for current time to ensure consistent comparison
      final nowUtc = DateTime.now().toUtc();

      return checkInUtc.difference(nowUtc).inHours;
    } catch (e) {
      return null;
    }
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
    if (widget.widgetSettings?.allowGuestCancellation != true) {
      return false;
    }

    // Check cancellation deadline with safe date parsing
    final deadlineHours = widget.widgetSettings?.cancellationDeadlineHours ?? 48;

    final hoursUntilCheckIn = _getHoursUntilCheckIn();
    // If date parsing fails (null), allow cancellation (owner can decide)
    if (hoursUntilCheckIn == null) return true;

    return hoursUntilCheckIn >= deadlineHours;
  }

  /// Get reason why booking cannot be cancelled (for tooltip)
  String? _getCancelDisabledReason(WidgetTranslations tr) {
    // Use local _currentStatus which updates after cancellation
    final status = _currentStatus.toLowerCase();
    if (status == 'cancelled') {
      return tr.bookingAlreadyCancelled;
    }
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
      return tr.bookingCannotBeCancelled;
    }

    if (widget.widgetSettings?.allowGuestCancellation != true) {
      return tr.guestCancellationNotEnabled;
    }

    final deadlineHours = widget.widgetSettings?.cancellationDeadlineHours ?? 48;

    // Safe date parsing with helper method
    final hoursUntilCheckIn = _getHoursUntilCheckIn();

    // If date parsing fails (null), don't block cancellation
    if (hoursUntilCheckIn == null) return null;

    if (hoursUntilCheckIn < deadlineHours) {
      return tr.cancellationDeadlinePassed(deadlineHours);
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
        final tr = WidgetTranslations.of(context, ref);
        SnackBarHelper.showSuccess(
          context: context,
          message: result.data['message'] ?? tr.bookingCancelledSuccessfully,
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
        final tr = WidgetTranslations.of(context, ref);
        setState(() => _isCancelling = false);
        // Safely convert error to string
        final errorMessage = _safeErrorToString(e);
        SnackBarHelper.showError(
          context: context,
          message: tr.failedToCancelBooking(errorMessage),
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
              // Custom header with centered title (no back button)
              _buildHeader(colors),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
              // Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive padding - smaller on mobile
                    final screenWidth = constraints.maxWidth;
                    final horizontalPadding = screenWidth < 600 ? SpacingTokens.m : SpacingTokens.l;
                    final verticalPadding = SpacingTokens.l;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          // On mobile (<600px), use full width; on desktop, limit to 600px
                          constraints: BoxConstraints(
                            maxWidth: screenWidth < 600 ? double.infinity : 600,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Status banner - full width
                              // Uses _currentStatus which updates after cancellation
                              BookingStatusBanner(status: _currentStatus, colors: colors),

                              const SizedBox(height: SpacingTokens.l),

                              // Booking reference - full width, prominent
                              DetailsReferenceCard(bookingReference: widget.booking.bookingReference, colors: colors),

                              const SizedBox(height: SpacingTokens.l),

                              // Single column layout
                              _buildContentCards(colors, isDarkMode),

                              const SizedBox(height: SpacingTokens.xl),

                              // Action buttons - full width
                              _buildActionButtons(colors, isDarkMode),

                              const SizedBox(height: SpacingTokens.m),

                              // Help text
                              Builder(
                                builder: (context) {
                                  final tr = WidgetTranslations.of(context, ref);
                                  return Text(
                                    tr.needHelpContactOwner,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textTertiary),
                                  );
                                },
                              ),

                              // Extra bottom padding for safe area
                              const SizedBox(height: SpacingTokens.xl),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom header with centered title and theme/language switchers
  Widget _buildHeader(WidgetColorScheme colors) {
    final tr = WidgetTranslations.of(context, ref);
    final isDarkMode = ref.watch(themeProvider);

    // Icon size for theme/language buttons (larger for better tap targets)
    const double iconSize = 28;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.m, vertical: SpacingTokens.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Theme toggle button (left side for symmetry)
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: colors.textPrimary,
              size: iconSize,
            ),
            onPressed: () => ref.read(themeProvider.notifier).state = !isDarkMode,
            tooltip: isDarkMode ? tr.tooltipSwitchToLightMode : tr.tooltipSwitchToDarkMode,
          ),
          const SizedBox(width: SpacingTokens.s),
          // Title (centered)
          Text(
            tr.myBooking,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: SpacingTokens.s),
          // Language switcher button (right side)
          IconButton(
            icon: Icon(Icons.language, color: colors.textPrimary, size: iconSize),
            onPressed: () => _showLanguageDialog(colors),
            tooltip: tr.tooltipChangeLanguage,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(WidgetColorScheme colors) {
    final tr = WidgetTranslations.of(context, ref);
    final currentLang = ref.watch(languageProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.backgroundPrimary,
        title: Text(tr.selectLanguage, style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('hr', 'Hrvatski', currentLang, colors),
            _buildLanguageOption('en', 'English', currentLang, colors),
            _buildLanguageOption('de', 'Deutsch', currentLang, colors),
            _buildLanguageOption('it', 'Italiano', currentLang, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String current, WidgetColorScheme colors) {
    final isSelected = current == code;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(color: colors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
      trailing: isSelected ? Icon(Icons.check, color: colors.primary) : null,
      onTap: () {
        ref.read(languageProvider.notifier).state = code;
        Navigator.of(context).pop();
      },
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
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: SpacingTokens.l),
        GuestInfoCard(
          guestName: widget.booking.guestName,
          guestEmail: widget.booking.guestEmail,
          guestPhone: widget.booking.guestPhone,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: SpacingTokens.l),
        BookingDatesCard(
          checkIn: widget.booking.checkIn,
          checkOut: widget.booking.checkOut,
          nights: widget.booking.nights,
          adults: widget.booking.guestCount.adults,
          children: widget.booking.guestCount.children,
          colors: colors,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: SpacingTokens.l),
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
        // Bank transfer details (only shown when payment method is bank_transfer and details are available)
        if (widget.booking.paymentMethod == 'bank_transfer' &&
            widget.booking.bankDetails != null &&
            widget.booking.remainingAmount > 0) ...[
          const SizedBox(height: SpacingTokens.l),
          BankTransferDetailsCard(
            bankDetails: widget.booking.bankDetails!,
            bookingReference: widget.booking.bookingReference,
            amount: widget.booking.remainingAmount,
            colors: colors,
          ),
        ],
        // Contact info
        if (widget.booking.ownerEmail != null || widget.booking.ownerPhone != null) ...[
          const SizedBox(height: SpacingTokens.l),
          ContactOwnerCard(
            ownerEmail: widget.booking.ownerEmail,
            ownerPhone: widget.booking.ownerPhone,
            colors: colors,
          ),
        ],
        // Cancellation policy
        if (widget.widgetSettings?.allowGuestCancellation == true) ...[
          const SizedBox(height: SpacingTokens.l),
          CancellationPolicyCard(
            deadlineHours: widget.widgetSettings?.cancellationDeadlineHours ?? 48,
            checkIn: widget.booking.checkIn,
            colors: colors,
          ),
        ],
        // Notes
        if (widget.booking.notes != null && widget.booking.notes!.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.l),
          BookingNotesCard(notes: widget.booking.notes!, colors: colors),
        ],
      ],
    );
  }

  /// Action buttons (Cancel booking if allowed)
  Widget _buildActionButtons(WidgetColorScheme colors, bool isDarkMode) {
    final tr = WidgetTranslations.of(context, ref);
    final canCancel = _canCancelBooking();
    final cancelReason = _getCancelDisabledReason(tr);
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
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cancelText))
              : Icon(Icons.cancel_outlined, color: canCancel ? cancelText : colors.textTertiary),
          label: Text(
            _isCancelling ? tr.cancelling : tr.cancelBooking,
            style: const TextStyle(fontSize: TypographyTokens.fontSizeL, fontWeight: TypographyTokens.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canCancel ? cancelBg : colors.buttonDisabled,
            foregroundColor: canCancel ? cancelText : colors.textTertiary,
            disabledBackgroundColor: colors.buttonDisabled,
            disabledForegroundColor: colors.textTertiary,
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
            shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularRounded),
          ),
        ),
      ),
    );
  }
}
