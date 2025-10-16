import 'package:flutter/material.dart';
import '../../../../shared/presentation/screens/placeholder_screen.dart';

class PropertyDetailsScreen extends StatelessWidget {
  const PropertyDetailsScreen({
    required this.propertyId,
    super.key,
  });

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Detalji propertya',
      description: 'Property ID: $propertyId',
      icon: Icons.apartment,
    );
  }
}
