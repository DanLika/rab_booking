import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/enums.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../../data/firebase/firebase_owner_bookings_repository.dart'
    show OwnerBooking;
import '../../../domain/models/unified_dashboard_data.dart';
import '../../../domain/models/windowed_bookings_state.dart';
import '../../providers/owner_bookings_provider.dart';
import '../../providers/unified_dashboard_provider.dart';

/// Premium header for the Rezervacije screen (audit/116 §7 Phase C / audit/117 §B2).
///
/// Mirrors the Pregled premium composition: eyebrow date + H1 title + KPI strip
/// + AI nudge banner (feature-gated) + pending priority queue ("Zahtijeva vašu
/// pažnju"). Designed to live ABOVE the existing filters/tabbar/list — the
/// existing list+table view stays as the system-of-record under the premium
/// hero. Hidden entirely when a status filter is active so filtered views don't
/// double-render the priority queue.
class BookingsPremiumHeader extends ConsumerWidget {
  final bool hasActiveFilter;
  final EdgeInsetsGeometry padding;

  const BookingsPremiumHeader({
    super.key,
    required this.hasActiveFilter,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Premium header is suppressed when the user has narrowed the view —
    // priority queue + KPI strip describe the FULL state, not the slice.
    if (hasActiveFilter) return const SizedBox.shrink();

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final BBColorSet c = BBColor.of(context);
    final AsyncValue<UnifiedDashboardData> dashboard = ref.watch(
      unifiedDashboardNotifierProvider,
    );
    final WindowedBookingsState bookingsState = ref.watch(
      windowedBookingsNotifierProvider,
    );

    final List<_PendingPreview> pendingPreview = _pendingPreviews(
      bookingsState,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PremiumHeaderRow(isMobile: isMobile),
          SizedBox(height: isMobile ? 14 : 18),
          _RezKpiStrip(
            isMobile: isMobile,
            dashboard: dashboard,
            pendingCount: pendingPreview.length,
          ),
          SizedBox(height: isMobile ? 14 : 18),
          if (_RezAINudge.shouldShow(pendingPreview)) ...<Widget>[
            _RezAINudge(
              isMobile: isMobile,
              oldestWaitHours: pendingPreview.isEmpty
                  ? 0
                  : pendingPreview.first.waitHours,
              guestFirstName: pendingPreview.isEmpty
                  ? null
                  : pendingPreview.first.guestFirstName,
            ),
            SizedBox(height: isMobile ? 14 : 18),
          ],
          if (pendingPreview.isNotEmpty) ...<Widget>[
            _RezPendingQueue(
              previews: pendingPreview,
              isMobile: isMobile,
              accent: c.tertiary,
            ),
            SizedBox(height: isMobile ? 14 : 18),
          ],
        ],
      ),
    );
  }

  static List<_PendingPreview> _pendingPreviews(WindowedBookingsState s) {
    return s.visibleBookings
        .where((b) => b.booking.status == BookingStatus.pending)
        .take(4)
        .map(_PendingPreview.fromBooking)
        .toList(growable: false);
  }
}

/// Premium ledger section header — eyebrow + H3 + count (audit/117 §B2-Δb).
///
/// Sits between the premium hero (KPI + AI + queue) and the existing
/// tabs + cards/table list. Gives the bottom half ledger-shaped framing
/// without touching the sliding-window / sort / filter internals.
class BookingsPremiumLedgerHeader extends ConsumerWidget {
  final bool hasActiveFilter;
  final EdgeInsetsGeometry padding;

  const BookingsPremiumLedgerHeader({
    super.key,
    required this.hasActiveFilter,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BBColor.of(context);
    final WindowedBookingsState s = ref.watch(windowedBookingsNotifierProvider);
    final int visible = s.visibleBookings.length;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  hasActiveFilter
                      ? 'FILTRIRANE REZERVACIJE'
                      : 'PREGLED SVIH REZERVACIJA',
                  style: BBType.eyebrow(context).copyWith(color: c.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  hasActiveFilter
                      ? 'Suženo na trenutni filter'
                      : 'Najnovije rezervacije na vrhu',
                  style: BBType.caption(context).copyWith(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (visible > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$visible',
                style: BBType.caption(context).copyWith(
                  color: c.primary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium ledger footer — "Prikazano X od Y rezervacija" pagination hint
/// (audit/117 §B2-Δb). Renders below the existing list/table so the bottom
/// of the ledger matches the handoff RZPLedger footer surface.
class BookingsPremiumLedgerFooter extends ConsumerWidget {
  final EdgeInsetsGeometry padding;

  const BookingsPremiumLedgerFooter({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 20),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BBColor.of(context);
    final WindowedBookingsState s = ref.watch(windowedBookingsNotifierProvider);
    final int visible = s.visibleBookings.length;
    if (visible == 0) return const SizedBox.shrink();

    final String label = s.hasMoreBottom
        ? 'Prikazano $visible · listanjem se učitavaju nove'
        : 'Prikazano svih $visible rezervacija';

    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surfaceVariant.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(BBRadius.sm),
          border: Border.all(color: c.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.list_alt, size: 14, color: c.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: BBType.caption(context).copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumHeaderRow extends StatelessWidget {
  final bool isMobile;

  const _PremiumHeaderRow({required this.isMobile});

  static const List<String> _hrMonths = <String>[
    'siječnja',
    'veljače',
    'ožujka',
    'travnja',
    'svibnja',
    'lipnja',
    'srpnja',
    'kolovoza',
    'rujna',
    'listopada',
    'studenoga',
    'prosinca',
  ];
  static const List<String> _hrDays = <String>[
    'Ponedjeljak',
    'Utorak',
    'Srijeda',
    'Četvrtak',
    'Petak',
    'Subota',
    'Nedjelja',
  ];

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final DateTime now = DateTime.now();
    final String eyebrow =
        '${_hrDays[(now.weekday - 1).clamp(0, 6)]} · ${now.day}. ${_hrMonths[(now.month - 1).clamp(0, 11)]} ${now.year}';
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                eyebrow.toUpperCase(),
                style: BBType.eyebrow(context).copyWith(color: c.primary),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.ownerBookingsTitle,
                style: BBType.h1(context).copyWith(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 4-tile KPI strip: pending count / confirmed count / monthly revenue /
/// upcoming check-ins. Mirrors handoff RZPStatStrip.
class _RezKpiStrip extends StatelessWidget {
  final bool isMobile;
  final AsyncValue<UnifiedDashboardData> dashboard;
  final int pendingCount;

  const _RezKpiStrip({
    required this.isMobile,
    required this.dashboard,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
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

    final List<double> bookingsSpark = data.bookingHistory
        .map((p) => p.count.toDouble())
        .toList(growable: false);
    final List<double> revenueSpark = data.revenueHistory
        .map((p) => p.amount)
        .toList(growable: false);

    final tiles = <Widget>[
      _RezStatTile(
        icon: 'pending_actions',
        label: 'Na čekanju',
        value: '$pendingCount',
        sub: pendingCount > 0 ? 'čeka odgovor' : null,
        tone: c.tertiary,
        isMobile: isMobile,
      ),
      _RezStatTile(
        icon: 'event_available',
        label: 'Potvrđeno (mj.)',
        value: '${data.bookings}',
        spark: bookingsSpark,
        tone: c.success,
        isMobile: isMobile,
      ),
      _RezStatTile(
        icon: 'payments',
        label: 'Zarada (mj.)',
        value: '€${data.revenue.toStringAsFixed(0)}',
        spark: revenueSpark,
        tone: c.primary,
        isMobile: isMobile,
      ),
      _RezStatTile(
        icon: 'login',
        label: 'Nadolazeći',
        value: '${data.upcomingCheckIns}',
        sub: 'sljedećih 7 dana',
        tone: c.info,
        isMobile: isMobile,
      ),
    ];

    if (isMobile) {
      return Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: tiles[0]),
              const SizedBox(width: 12),
              Expanded(child: tiles[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: tiles[2]),
              const SizedBox(width: 12),
              Expanded(child: tiles[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _RezStatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? sub;
  final List<double>? spark;
  final Color tone;
  final bool isMobile;

  const _RezStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.isMobile,
    this.sub,
    this.spark,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final bool hasSpark = spark != null && spark!.length >= 2;

    return BbCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: isMobile ? 32 : 36,
            height: isMobile ? 32 : 36,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: BbIcon(name: icon, size: isMobile ? 17 : 19, color: tone),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            label.toUpperCase(),
            style: BBType.caption(context).copyWith(
              color: c.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  style: BBType.displayNum(context).copyWith(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.0,
                  ),
                ),
              ),
              if (hasSpark)
                BbSparkline(
                  data: spark!,
                  color: tone,
                  width: isMobile ? 52 : 80,
                  height: isMobile ? 24 : 30,
                ),
            ],
          ),
          if (sub != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              sub!,
              style: BBType.caption(context).copyWith(color: c.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// AI nudge banner — amber/purple/teal tri-stop gradient (handoff RZPAINudge).
/// Gated by the same flag class as Pregled's AI insight; surfaces only when
/// there is at least one pending booking AND the user has the flag on.
class _RezAINudge extends StatelessWidget {
  final bool isMobile;
  final int oldestWaitHours;
  final String? guestFirstName;

  const _RezAINudge({
    required this.isMobile,
    required this.oldestWaitHours,
    this.guestFirstName,
  });

  static const bool _enabled = bool.fromEnvironment('PREGLED_AI_INSIGHT');

  static bool shouldShow(List<_PendingPreview> pending) {
    if (!_enabled && !kDebugMode) return false;
    if (pending.isEmpty) return false;
    return pending.first.waitHours >= 6;
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final String waitLabel = oldestWaitHours >= 24
        ? '${(oldestWaitHours / 24).floor()} dana'
        : '$oldestWaitHours sati';
    final String guestLead = guestFirstName == null
        ? 'Najstarija rezervacija'
        : '${guestFirstName!}eva rezervacija';

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            c.tertiary.withValues(alpha: 0.12),
            c.primary.withValues(alpha: 0.06),
            const Color(0xFF3DD9B0).withValues(alpha: 0.07),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(BBRadius.md),
        border: Border.all(color: c.tertiary.withValues(alpha: 0.30)),
        boxShadow: BBShadow.cardElevated,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: isMobile ? 42 : 46,
            height: isMobile ? 42 : 46,
            decoration: BoxDecoration(
              gradient: BBGradient.hero,
              borderRadius: BorderRadius.circular(12),
              boxShadow: BBShadow.purpleGlow(context),
            ),
            alignment: Alignment.center,
            child: const BbIcon(
              name: 'auto_awesome',
              size: 22,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BookBed AI',
                        style: BBType.caption(context).copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prioritet danas',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: BBType.body(context).copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    children: <InlineSpan>[
                      TextSpan(text: '$guestLead čeka odgovor '),
                      TextSpan(
                        text: waitLabel,
                        style: TextStyle(color: c.tertiary),
                      ),
                      const TextSpan(
                        text:
                            '. Gosti s odgovorom unutar sat vremena potvrde 30% češće — odgovorite sada.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Kasnije',
                        style: BBType.label(context).copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Odgovori',
                        style: BBType.label(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Priority queue section (handoff RZPPendingQueue).
class _RezPendingQueue extends ConsumerWidget {
  final List<_PendingPreview> previews;
  final bool isMobile;
  final Color accent;

  const _RezPendingQueue({
    required this.previews,
    required this.isMobile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BBColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              'Zahtijeva vašu pažnju',
              style: BBType.h2(context).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${previews.length}',
                style: BBType.caption(context).copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isMobile)
          Column(
            children: <Widget>[
              for (int i = 0; i < previews.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 12),
                _RezPendingCard(preview: previews[i]),
              ],
            ],
          )
        else
          // Desktop: 2-up grid.
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              for (final _PendingPreview p in previews)
                SizedBox(
                  width: (MediaQuery.of(context).size.width / 2) - 80,
                  child: _RezPendingCard(preview: p),
                ),
            ],
          ),
      ],
    );
  }
}

class _RezPendingCard extends ConsumerStatefulWidget {
  final _PendingPreview preview;

  const _RezPendingCard({required this.preview});

  @override
  ConsumerState<_RezPendingCard> createState() => _RezPendingCardState();
}

class _RezPendingCardState extends ConsumerState<_RezPendingCard> {
  bool _busy = false;

  Future<void> _run({required bool approve}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    try {
      final repo = ref.read(ownerBookingsRepositoryProvider);
      if (approve) {
        await repo.approveBooking(widget.preview.id);
      } else {
        await repo.rejectBooking(widget.preview.id);
      }
      // F-T3-Notif-01: refresh() is best-effort. The success-critical write
      // (approve/reject CF) already committed; the windowed-bookings stream
      // listener picks up the status flip on the next tick and the card
      // vanishes anyway. A transient refresh() failure (rules-deny on a
      // sibling doc, network blip) must NOT poison the success toast.
      try {
        await ref.read(windowedBookingsNotifierProvider.notifier).refresh();
      } catch (e) {
        debugPrint(
          '[premium-header] post-action refresh best-effort failed: $e',
        );
      }
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? l10n.notificationApproveSuccess
                : l10n.notificationRejectSuccess,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? l10n.notificationApproveError
                : l10n.notificationRejectError,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final p = widget.preview;
    final int pct = p.total > 0 ? ((p.paid / p.total) * 100).round() : 0;
    final String waitLabel = p.waitHours >= 24
        ? 'prije ${(p.waitHours / 24).floor()} d'
        : 'prije ${p.waitHours} h';

    return BbCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Amber priority rail header (handoff: 4px gradient).
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[c.tertiary, const Color(0xFFFFD08A)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BBRadius.md),
                topRight: Radius.circular(BBRadius.md),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BBSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const BbStatusBadge(
                      status: BbBookingStatus.pending,
                      size: BbStatusBadgeSize.sm,
                    ),
                    Row(
                      children: <Widget>[
                        Icon(Icons.schedule, size: 15, color: c.tertiary),
                        const SizedBox(width: 5),
                        Text(
                          waitLabel,
                          style: BBType.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: BBSpace.sm),
                Row(
                  children: <Widget>[
                    BbAvatar(name: p.fullName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            p.fullName,
                            style: BBType.h3(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.guestEmail} · #${p.reference}',
                            style: BBType.caption(
                              context,
                            ).copyWith(color: c.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BBSpace.sm),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: <Widget>[
                    _Fact(
                      icon: Icons.apartment,
                      text: '${p.propertyName} · ${p.unitName}',
                    ),
                    _Fact(icon: Icons.event, text: p.range),
                    _Fact(
                      icon: Icons.group,
                      text: '${p.guests} gosta · ${p.nights} noći',
                    ),
                    if (p.source != null)
                      _Fact(icon: Icons.sell, text: p.source!),
                  ],
                ),
                const SizedBox(height: BBSpace.sm),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BBRadius.sm),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'POLOG PLAĆEN',
                            style: BBType.caption(context).copyWith(
                              color: c.textTertiary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontSize: 10,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              style: BBType.bodyNum(
                                context,
                              ).copyWith(fontWeight: FontWeight.w700),
                              children: <InlineSpan>[
                                TextSpan(text: '€${p.paid.toStringAsFixed(0)}'),
                                TextSpan(
                                  text: ' / €${p.total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: c.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          minHeight: 8,
                          backgroundColor: c.border,
                          valueColor: AlwaysStoppedAnimation<Color>(c.success),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Preostalo na dolasku',
                            style: BBType.caption(
                              context,
                            ).copyWith(color: c.textTertiary),
                          ),
                          Text(
                            '€${(p.total - p.paid).toStringAsFixed(0)}',
                            style: BBType.caption(context).copyWith(
                              color: c.tertiary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BBSpace.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: BbButton(
                        label: AppLocalizations.of(
                          context,
                        ).notificationActionApprove,
                        loading: _busy,
                        iconLeft: 'check',
                        onPressed: () => _run(approve: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BbButton(
                        label: AppLocalizations.of(
                          context,
                        ).notificationActionReject,
                        variant: BbButtonVariant.destructiveSoft,
                        iconLeft: 'close',
                        onPressed: _busy ? null : () => _run(approve: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: c.textTertiary),
        const SizedBox(width: 6),
        Text(
          text,
          style: BBType.body(
            context,
          ).copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Projection of a Booking for the priority queue. Pulls only the fields we
/// need to render — keeps the queue insulated from booking model evolution.
@immutable
class _PendingPreview {
  final String id;
  final String reference;
  final String fullName;
  final String guestEmail;
  final String propertyName;
  final String unitName;
  final String range;
  final int nights;
  final int guests;
  final double total;
  final double paid;
  final int waitHours;
  final String? source;

  String get guestFirstName => fullName.split(' ').first;

  const _PendingPreview({
    required this.id,
    required this.reference,
    required this.fullName,
    required this.guestEmail,
    required this.propertyName,
    required this.unitName,
    required this.range,
    required this.nights,
    required this.guests,
    required this.total,
    required this.paid,
    required this.waitHours,
    this.source,
  });

  factory _PendingPreview.fromBooking(OwnerBooking ownerBooking) {
    final BookingModel b = ownerBooking.booking;
    final DateTime now = DateTime.now();
    final int waitHours = now.difference(b.createdAt).inHours;
    final String range = _formatRange(b.checkIn, b.checkOut);
    final int nights = b.checkOut.difference(b.checkIn).inDays;

    return _PendingPreview(
      id: b.id,
      reference: b.bookingReference ?? '—',
      fullName: ownerBooking.guestName,
      guestEmail: ownerBooking.guestEmail,
      propertyName: ownerBooking.property.name,
      unitName: ownerBooking.unit.name,
      range: range,
      nights: nights > 0 ? nights : 1,
      guests: b.guestCount,
      total: b.totalPrice,
      paid: b.paidAmount,
      waitHours: waitHours.clamp(0, 9999),
      source: b.source,
    );
  }

  static const List<String> _hrShortMonths = <String>[
    'sij',
    'velj',
    'ožu',
    'tra',
    'svi',
    'lip',
    'srp',
    'kol',
    'ruj',
    'lis',
    'stu',
    'pro',
  ];

  static String _formatRange(DateTime a, DateTime b) {
    final String aDay = '${a.day}.';
    final String bDay = '${b.day}.';
    final String month = _hrShortMonths[(b.month - 1).clamp(0, 11)];
    return '$aDay–$bDay $month';
  }
}
