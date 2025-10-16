import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    this.redirectTo,
    super.key,
  });

  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Registracija',
      description: 'Kreirajte novi račun',
      icon: Icons.person_add,
    );
  }
}
