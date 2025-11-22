import 'package:flutter/material.dart';
import '../../../../../shared/models/property_model.dart';
import '../../../../../shared/models/unit_model.dart';

/// Property and unit information section for booking card
///
/// Displays property name and unit name with home icon
class BookingCardPropertyInfo extends StatelessWidget {
  final PropertyModel property;
  final UnitModel unit;
  final bool isMobile;

  const BookingCardPropertyInfo({
    super.key,
    required this.property,
    required this.unit,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.home_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property name
              Text(
                property.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // Unit name
              Text(
                unit.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.6 * 255).toInt(),
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
