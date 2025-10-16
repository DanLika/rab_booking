import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    this.redirectTo,
    super.key,
  });

  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Prijava',
      description: redirectTo != null
          ? 'Prijavite se za nastavak'
          : 'Prijavite se na Rab Booking',
      icon: Icons.login,
    );
  }
}
