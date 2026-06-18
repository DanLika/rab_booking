import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/design/tokens.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../../domain/models/unified_dashboard_data.dart';
import '../../providers/unified_dashboard_provider.dart';

/// Premium KPI strip above the month calendar grid (audit/117 §B2.4).
///
/// Mirrors handoff `screens/04-owner.png`: 4 stat tiles —
/// Popunjenost (%) · Rezervacije (count) · Dolasci (upcoming) · Slobodne noći.
/// Chrome only — calendar cell dimensions stay FROZEN.
class MonthCalendarKpiStrip extends ConsumerWidget {
  const MonthCalendarKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BBColorSet c = BBColor.of(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final AsyncValue<UnifiedDashboardData> dashboard = ref.watch(
      unifiedDashboardNotifierProvider,
    );

    final UnifiedDashboardData data = dashboard.maybeWhen(
      data: (d) => d,
      orElse: () => const UnifiedDashboardData(
        revenue: 0,
        bookings: 0,
        upcomingCheckIns: 0,
        occupancyRate: 0,
        revenueHistory: <RevenueDataPoint>[],
        bookingHistory: <BookingDataPoint>[],
      ),
    );

    // Free-nights estimate: 30 (default window) minus the occupied days. We
    // don't have a server-side `freeNights` yet — derived locally with the
    // same 30-day window the dashboard uses.
    const int windowDays = 30;
    final int occupiedDays = (windowDays * (data.occupancyRate / 100.0))
        .round();
    final int freeNights = (windowDays - occupiedDays).clamp(0, windowDays);

    final tiles = <Widget>[
      _Tile(
        icon: 'donut_small',
        label: 'Popunjenost',
        value: '${data.occupancyRate.toStringAsFixed(0)}%',
        tone: c.primary,
        isMobile: isMobile,
      ),
      _Tile(
        icon: 'receipt_long',
        label: 'Rezervacije',
        value: '${data.bookings}',
        tone: c.success,
        isMobile: isMobile,
      ),
      _Tile(
        icon: 'login',
        label: 'Dolasci · 7d',
        value: '${data.upcomingCheckIns}',
        tone: c.info,
        isMobile: isMobile,
      ),
      _Tile(
        icon: 'hotel',
        label: 'Slobodne noći',
        value: '$freeNights',
        tone: c.tertiary,
        isMobile: isMobile,
      ),
    ];

    final EdgeInsets padding = EdgeInsets.fromLTRB(
      isMobile ? 12 : 20,
      isMobile ? 12 : 16,
      isMobile ? 12 : 20,
      isMobile ? 8 : 12,
    );

    if (isMobile) {
      return Padding(
        padding: padding,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: tiles[0]),
                const SizedBox(width: 10),
                Expanded(child: tiles[1]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: tiles[2]),
                const SizedBox(width: 10),
                Expanded(child: tiles[3]),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color tone;
  final bool isMobile;

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    // Handoff per-tone tile tints (calendar-month.jsx): primary uses the
    // soft primary-tint-bg (6%), tertiary 16%, success/info 12%.
    final double tintAlpha = tone == c.primary
        ? 0.06
        : (tone == c.tertiary ? 0.16 : 0.12);
    return BbCard(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: <Widget>[
          Container(
            width: isMobile ? 28 : 32,
            height: isMobile ? 28 : 32,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: tintAlpha),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: BbIcon(name: icon, size: isMobile ? 15 : 17, color: tone),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: BBType.caption(context).copyWith(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: BBType.bodyLgNum(context).copyWith(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
