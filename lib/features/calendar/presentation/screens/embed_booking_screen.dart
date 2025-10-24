import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../booking/presentation/screens/simple_booking_screen.dart';

/// Embed Booking Screen - Wrapper for iframe embedding
/// Minimal UI without navigation bars
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
    return SimpleBookingScreen(
      unitId: unitId,
      selectedDates: selectedDates,
      totalPrice: totalPrice,
    );
  }
}
