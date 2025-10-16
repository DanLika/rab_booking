import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({
    required this.unitId,
    super.key,
  });

  final String unitId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Rezervacija',
      description: 'Unit ID: $unitId',
      icon: Icons.calendar_month,
    );
  }
}
