import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class PropertyManagementScreen extends StatelessWidget {
  const PropertyManagementScreen({
    required this.propertyId,
    super.key,
  });

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Upravljanje propertyem',
      description: 'Property ID: $propertyId',
      icon: Icons.edit,
    );
  }
}
