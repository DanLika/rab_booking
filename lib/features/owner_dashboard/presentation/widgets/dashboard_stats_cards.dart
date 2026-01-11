import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../domain/models/unified_dashboard_data.dart';

class DashboardStatsCards extends StatelessWidget {
  final UnifiedDashboardData data;

  const DashboardStatsCards({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 10.0 : 12.0,
      runSpacing: isMobile ? 10.0 : 12.0,
      alignment: WrapAlignment.center,
      children: [
        _StatCard(
          title: l10n.ownerDashboardRevenue,
          value: '€${data.revenue.toStringAsFixed(0)}',
          icon: Icons.euro_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 3)),
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _StatCard(
          title: l10n.ownerDashboardBookings,
          value: '${data.bookings}',
          icon: Icons.calendar_today_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 4)),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 100,
        ),
        _StatCard(
          title: l10n.ownerUpcomingCheckIns,
          value: '${data.upcomingCheckIns}',
          icon: Icons.schedule_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 5)),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 200,
        ),
        _StatCard(
          title: l10n.ownerOccupancyRate,
          value: '${data.occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.analytics_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 2)),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 300,
        ),
      ],
    );
  }

  Color _getPurpleShade(BuildContext context, int level) => switch (level) {
        1 => const Color(0xFF4A3A8C),
        2 => const Color(0xFF5B4BA8),
        3 => const Color(0xFF6B4CE6),
        4 => const Color(0xFF8B6FF5),
        5 => const Color(0xFFA08BFF),
        6 => const Color(0xFFB8A8FF),
        _ => const Color(0xFF6B4CE6),
      };

  Gradient _createThemeGradient(BuildContext context, Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [baseColor, baseColor.withValues(alpha: 0.7)],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final bool isMobile;
  final bool isTablet;
  final int animationDelay;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.isMobile,
    required this.isTablet,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = isMobile ? 12.0 : 16.0;

    double cardWidth;
    if (isMobile) {
      cardWidth = (screenWidth - (spacing * 3 + 32)) / 2;
    } else if (isTablet) {
      cardWidth = (screenWidth - (spacing * 4 + 48)) / 3;
    } else {
      cardWidth = 280.0;
    }

    final accentColor = gradient.colors.isNotEmpty
        ? gradient.colors.first
        : Theme.of(context).colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3D3D4A) : const Color(0xFFE8E8F0);
    final valueColor = theme.colorScheme.onSurface;
    final titleColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + animationDelay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: isMobile ? 130 : 150,
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: isMobile ? 20 : 22),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    height: 1.0,
                    letterSpacing: 0,
                    fontSize: isMobile ? 24 : 28,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  fontSize: isMobile ? 11 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
