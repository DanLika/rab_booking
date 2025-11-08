import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';

/// Reusable Calendar Legend Widget
/// Shows color explanations and icon meanings for calendars
class CalendarLegendWidget extends StatelessWidget {
  final bool showStatusColors;
  final bool showPriceColors;
  final bool showIcons;
  final bool showSources;
  final bool isCompact;

  const CalendarLegendWidget({
    super.key,
    this.showStatusColors = true,
    this.showPriceColors = false,
    this.showIcons = true,
    this.showSources = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isCompact ? 14 : 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Legenda',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 6 : 8),

            if (showStatusColors) ...[
              Text(
                'Statusi rezervacija:',
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _LegendItem(
                    color: BookingStatus.confirmed.color,
                    label: 'Potvrđeno',
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: BookingStatus.pending.color,
                    label: 'Na čekanju',
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: BookingStatus.inProgress.color,
                    label: 'U toku',
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: BookingStatus.cancelled.color,
                    label: 'Otkazano',
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: BookingStatus.completed.color,
                    label: 'Završeno',
                    isCompact: isCompact,
                  ),
                ],
              ),
            ],

            if (showStatusColors && showPriceColors)
              SizedBox(height: isCompact ? 8 : 12),

            if (showPriceColors) ...[
              Text(
                'Tipovi cena:',
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _LegendItem(
                    color: Colors.white,
                    label: 'Osnovna',
                    borderColor: Colors.grey[300]!,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: Colors.blue[50]!,
                    label: 'Custom',
                    borderColor: Colors.blue[300]!,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: Colors.purple[50]!,
                    label: 'Vikend',
                    borderColor: Colors.purple[300]!,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: Colors.orange[50]!,
                    label: 'Restrikcije',
                    borderColor: Colors.orange[300]!,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: Colors.grey[300]!,
                    label: 'Nedostupno',
                    borderColor: Colors.grey[600]!,
                    isCompact: isCompact,
                  ),
                ],
              ),
            ],

            if ((showStatusColors || showPriceColors) && showSources)
              SizedBox(height: isCompact ? 8 : 12),

            if (showSources) ...[
              Text(
                'Izvori rezervacija:',
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: isCompact ? 8 : 12,
                runSpacing: 6,
                children: [
                  _IconLegendItem(
                    icon: Icons.web,
                    label: 'Widget',
                    color: Colors.green,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.person,
                    label: 'Manualno',
                    color: Colors.grey,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.sync,
                    label: 'iCal sync',
                    color: Colors.blue,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.public,
                    label: 'Booking.com',
                    color: Colors.orange,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.home,
                    label: 'Airbnb',
                    color: Colors.red,
                    isCompact: isCompact,
                  ),
                ],
              ),
            ],

            if ((showStatusColors || showPriceColors || showSources) && showIcons)
              SizedBox(height: isCompact ? 8 : 12),

            if (showIcons) ...[
              Text(
                'Ikone:',
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: isCompact ? 8 : 12,
                runSpacing: 6,
                children: [
                  _IconLegendItem(
                    icon: Icons.sync,
                    label: 'iCal',
                    color: Colors.blue[700]!,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.login,
                    label: 'Blokiraj check-in',
                    color: Colors.red[700]!,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.logout,
                    label: 'Blokiraj check-out',
                    color: Colors.red[700]!,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.notes,
                    label: 'Napomene',
                    color: Colors.orange[700]!,
                    isCompact: isCompact,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single legend item with color square
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color? borderColor;
  final bool isCompact;

  const _LegendItem({
    required this.color,
    required this.label,
    this.borderColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 12 : 14,
          height: isCompact ? 12 : 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: borderColor ?? color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

/// Single legend item with icon
class _IconLegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isCompact;

  const _IconLegendItem({
    required this.icon,
    required this.label,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isCompact ? 12 : 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
