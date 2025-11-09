import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Legenda',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
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
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _LegendItem(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFFFFFFF),
                    label: 'Osnovna',
                    borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: AppColors.authSecondary.withAlpha((0.1 * 255).toInt()),
                    label: 'Custom',
                    borderColor: AppColors.authSecondary.withAlpha((0.5 * 255).toInt()),
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: AppColors.primaryLight.withAlpha((0.1 * 255).toInt()),
                    label: 'Vikend',
                    borderColor: AppColors.primaryLight,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: AppColors.warning.withAlpha((0.1 * 255).toInt()),
                    label: 'Restrikcije',
                    borderColor: AppColors.warning,
                    isCompact: isCompact,
                  ),
                  _LegendItem(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.disabled,
                    label: 'Nedostupno',
                    borderColor: isDark ? AppColors.borderDark : AppColors.textDisabled,
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
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
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
                    color: AppColors.success,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.person,
                    label: 'Manualno',
                    color: AppColors.textSecondary,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.sync,
                    label: 'iCal sync',
                    color: AppColors.authSecondary,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.public,
                    label: 'Booking.com',
                    color: AppColors.warning,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.home,
                    label: 'Airbnb',
                    color: AppColors.error,
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
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
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
                    color: AppColors.authSecondary,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.login,
                    label: 'Blokiraj check-in',
                    color: AppColors.errorDark,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.logout,
                    label: 'Blokiraj check-out',
                    color: AppColors.errorDark,
                    isCompact: isCompact,
                  ),
                  _IconLegendItem(
                    icon: Icons.notes,
                    label: 'Napomene',
                    color: AppColors.warningDark,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
