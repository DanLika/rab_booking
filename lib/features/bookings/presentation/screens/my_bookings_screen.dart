import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Moje rezervacije',
      description: 'Vaše nadolazeće i prošle rezervacije',
      icon: Icons.calendar_today,
    );
  }
}
