import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({
    this.bookingId,
    super.key,
  });

  final String? bookingId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Potvrda plaćanja',
      description: bookingId != null ? 'Booking ID: $bookingId' : null,
      icon: Icons.check_circle,
    );
  }
}
