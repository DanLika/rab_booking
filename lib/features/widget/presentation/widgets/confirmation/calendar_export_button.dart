import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/services/ical_generator.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../utils/ics_download.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';

/// Button for adding booking to calendar via .ics file download.
///
/// Generates an iCal file and triggers download when pressed.
/// Shows loading state during generation.
///
/// Usage:
/// ```dart
/// CalendarExportButton(
///   booking: bookingModel,
///   unitName: 'Beach Villa',
///   bookingReference: 'ABC123',
///   colors: ColorTokens.light,
/// )
/// ```
class CalendarExportButton extends StatefulWidget {
  /// Booking model to generate calendar event from
  final BookingModel booking;

  /// Unit or property name for calendar event
  final String unitName;

  /// Booking reference for filename
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const CalendarExportButton({
    super.key,
    required this.booking,
    required this.unitName,
    required this.bookingReference,
    required this.colors,
  });

  @override
  State<CalendarExportButton> createState() => _CalendarExportButtonState();
}

class _CalendarExportButtonState extends State<CalendarExportButton> {
  bool _isGeneratingIcs = false;

  Future<void> _handleAddToCalendar() async {
    setState(() => _isGeneratingIcs = true);

    try {
      // Generate .ics content using IcalGenerator service
      final icsContent = IcalGenerator.generateBookingEvent(
        booking: widget.booking,
        unitName: widget.unitName,
      );

      // Download file (platform-specific)
      final filename = 'booking-${widget.bookingReference}.ics';
      await downloadIcsFile(icsContent, filename);

      // Success feedback
      if (mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Calendar event downloaded! Check your downloads folder.',
        );
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Failed to generate calendar file: $e',
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingIcs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.l),
      child: ElevatedButton.icon(
        onPressed: _isGeneratingIcs ? null : _handleAddToCalendar,
        icon: Icon(
          _isGeneratingIcs ? Icons.hourglass_empty : Icons.calendar_today,
        ),
        label: Text(
          _isGeneratingIcs ? 'Generating...' : 'Add to My Calendar',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.backgroundSecondary,
          foregroundColor: colors.textPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              BorderTokens.radiusMedium,
            ),
          ),
        ),
      ),
    );
  }
}
