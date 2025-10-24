import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../booking/presentation/screens/booking_form_screen.dart';

/// Embed Booking Screen - Wrapper oko BookingFormScreen za iframe
/// Minimalni UI bez navigation bars
class EmbedBookingScreen extends ConsumerWidget {
  final String unitId;
  final String unitName;
  final List<DateTime> selectedDates;
  final double totalPrice;

  const EmbedBookingScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    required this.selectedDates,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BookingFormScreen(
      unitId: unitId,
      unitName: unitName,
      selectedDates: selectedDates,
      totalPrice: totalPrice,
    );
  }
}
