import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Home',
      description: 'Početna stranica sa featured properties',
      icon: Icons.home,
    );
  }
}
