import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/models/booking_model.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../widgets/booking_actions/booking_cancel_dialog.dart';
import '../widgets/booking_actions/booking_complete_dialog.dart';
import '../widgets/edit_booking_dialog.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/send_email_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────
// Layout constants — handoff booking-detail.jsx geometry, named so the magic
// numbers are greppable. `_kTabletGap` + cover heights sit off the BBSpace
// scale where the handoff itself is off-grid.
// ─────────────────────────────────────────────────────────────────────────
const double _kContentMaxWidth = 1100; // desktop centered column cap
const double _kSidebarWidth = 320; // handoff right rail (grid 1fr 320px)
const double _kKvLabelWidth = 124; // KeyValueRow label column
const double _kCoverHeightDesktop = 200;
const double _kCoverHeightTablet = 170;
const double _kCoverHeightMobile = 140;
const double _kTabletGap = 14; // handoff tablet gap (off BBSpace scale)
const double _kMobileGap = 12; // single-column (mobile) gap
// Tablet 2-col needs ≥~350px columns; below this the tablet range falls to the
// wide single column (the handoff's tablet artboard is 768).
const double _kTabletGridMinWidth = 720;

/// Full-route booking detail screen — premium composition per
/// `design_handoff/source/booking-detail.jsx` §201 BookingDetailDesktop /
/// `design_handoff/screens/07-owner.png`.
///
/// FROZEN scope guard: the WIDGET-side `Navigator.push → BookingConfirmationScreen`
/// (booking_widget_screen.dart:999, 3403, 3849) is untouched. This file lives
/// in the owner feature tree and uses approve/reject CF callables
/// (`approveBooking` / `rejectBooking`) — no navigation involved in the
/// confirmation paths. The legacy modal (`BookingDetailsDialogV2`) is kept
/// as-is for call sites that have not yet migrated.
///
/// Reads the booking via `ownerBookingByIdProvider(bookingId)` (defined at
/// the bottom of this file). Action buttons reuse the existing
/// repository CF wrappers.
class OwnerBookingDetailScreen extends ConsumerWidget {
  const OwnerBookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);
    final async = ref.watch(ownerBookingByIdProvider(bookingId));

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'bookings'),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(error: e, l10n: l10n, c: c),
          data: (ob) {
            if (ob == null) {
              return _ErrorState(
                error: l10n.ownerBookingsNotFound,
                l10n: l10n,
                c: c,
              );
            }
            return _BookingDetailBody(ownerBooking: ob);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Error state — used for both load-failure and missing-booking branches.
// ─────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final Object error;
  final AppLocalizations l10n;
  final BBColorSet c;
  const _ErrorState({required this.error, required this.l10n, required this.c});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpace.lg),
        child: BbEmptyState(
          icon: 'error_outline',
          title: l10n.ownerBookingsErrorLoading,
          body: error.toString(),
          compact: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Body — orchestrates the desktop 2-col grid / mobile single column,
// includes the AppBar and sticky-bottom action bar on mobile-pending.
// ─────────────────────────────────────────────────────────────────────────
class _BookingDetailBody extends ConsumerWidget {
  final OwnerBooking ownerBooking;
  const _BookingDetailBody({required this.ownerBooking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;
    final useTabletGrid = !isDesktop && width >= _kTabletGridMinWidth;
    final booking = ownerBooking.booking;
    final isPending = booking.status == BookingStatus.pending;
    final headerRef = booking.bookingReference ?? booking.id;

    return Column(
      children: [
        _DetailAppBar(reference: headerRef, isMobile: isMobile, l10n: l10n),
        Expanded(
          // No surface fill here: the Scaffold paints
          // `context.gradients.pageBackground` (flat #F0F1F5 light / OLED #000
          // dark post-audit/127). A shellBg Container used to cover it.
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : (isDesktop ? 32 : 24),
              isMobile ? 12 : 20,
              isMobile ? 12 : (isDesktop ? 32 : 24),
              isMobile ? 16 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
                child: isDesktop
                    ? _DesktopGrid(ownerBooking: ownerBooking)
                    : useTabletGrid
                    ? _TabletGrid(ownerBooking: ownerBooking)
                    : _SingleColumn(
                        ownerBooking: ownerBooking,
                        isMobile: isMobile,
                      ),
              ),
            ),
          ),
        ),
        if (isMobile && isPending)
          _MobileStickyActions(ownerBooking: ownerBooking),
      ],
    );
  }
}

/// Test seam — returns the responsive content widget (desktop grid / tablet
/// 2-col / mobile single column) for a given [width], mirroring the branch in
/// [_BookingDetailBody.build]. Lets `owner_booking_detail_layout_test` pump the
/// real layouts at every breakpoint and assert no overflow without standing up
/// Firebase (the action panel reads its repo only on tap, so a bare
/// ProviderScope suffices at pump time).
@visibleForTesting
Widget buildBookingDetailContentForTest(
  OwnerBooking ownerBooking,
  double width,
) {
  final isMobile = width < 600;
  final isDesktop = width >= 1024;
  final useTabletGrid = !isDesktop && width >= _kTabletGridMinWidth;
  return isDesktop
      ? _DesktopGrid(ownerBooking: ownerBooking)
      : useTabletGrid
      ? _TabletGrid(ownerBooking: ownerBooking)
      : _SingleColumn(ownerBooking: ownerBooking, isMobile: isMobile);
}

class _DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String reference;
  final bool isMobile;
  final AppLocalizations l10n;
  const _DetailAppBar({
    required this.reference,
    required this.isMobile,
    required this.l10n,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Material(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.border.withValues(alpha: 0.5)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/owner/bookings');
                  }
                },
                tooltip: l10n.back,
              ),
              Expanded(
                child: Text(
                  isMobile ? '#$reference' : 'Rezervacija #$reference',
                  style: BBType.h3(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              // Print / Share parking lot — surfaced in handoff §203 but not
              // wired to providers yet (no print-to-PDF / share-link
              // generator landed). Render only on non-mobile to match the
              // handoff hierarchy without claiming behavior we don't have.
              if (!isMobile) ...[
                const IconButton(
                  icon: Icon(Icons.print_outlined),
                  onPressed: null,
                  tooltip: 'Ispis',
                ),
                const IconButton(
                  icon: Icon(Icons.share_outlined),
                  onPressed: null,
                  tooltip: 'Podijeli',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopGrid extends StatelessWidget {
  final OwnerBooking ownerBooking;
  const _DesktopGrid({required this.ownerBooking});

  @override
  Widget build(BuildContext context) {
    final isPending = ownerBooking.booking.status == BookingStatus.pending;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BDCover(
                ownerBooking: ownerBooking,
                height: _kCoverHeightDesktop,
              ),
              const SizedBox(height: 16),
              if (isPending) ...[
                const _BDPendingAlert(),
                const SizedBox(height: 16),
              ],
              _BDGuestCard(ownerBooking: ownerBooking, compact: false),
              const SizedBox(height: 16),
              _BDStayCard(ownerBooking: ownerBooking),
              if ((ownerBooking.booking.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _BDNotesCard(notes: ownerBooking.booking.notes!),
              ],
            ],
          ),
        ),
        const SizedBox(width: BBSpace.md),
        SizedBox(
          width: _kSidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BDStatusActions(ownerBooking: ownerBooking, sidebar: true),
              const SizedBox(height: 16),
              _BDPriceCard(booking: ownerBooking.booking),
              const SizedBox(height: 16),
              _BDActivityCard(booking: ownerBooking.booking),
              const SizedBox(height: 16),
              _BDMetaCard(ownerBooking: ownerBooking),
            ],
          ),
        ),
      ],
    );
  }
}

class _SingleColumn extends StatelessWidget {
  final OwnerBooking ownerBooking;
  final bool isMobile;
  const _SingleColumn({required this.ownerBooking, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final isPending = ownerBooking.booking.status == BookingStatus.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BDCover(
          ownerBooking: ownerBooking,
          height: isMobile ? _kCoverHeightMobile : _kCoverHeightTablet,
        ),
        const SizedBox(height: _kMobileGap),
        if (isPending) ...[
          const _BDPendingAlert(),
          const SizedBox(height: _kMobileGap),
        ],
        _BDGuestCard(ownerBooking: ownerBooking, compact: isMobile),
        const SizedBox(height: _kMobileGap),
        // On non-pending statuses the actions panel is still useful for
        // Poruka / Uredi affordances — surface it on mobile via the card.
        if (!isPending || !isMobile) ...[
          _BDStatusActions(ownerBooking: ownerBooking, sidebar: false),
          const SizedBox(height: _kMobileGap),
        ],
        _BDStayCard(ownerBooking: ownerBooking),
        const SizedBox(height: _kMobileGap),
        _BDPriceCard(booking: ownerBooking.booking),
        if ((ownerBooking.booking.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: _kMobileGap),
          _BDNotesCard(notes: ownerBooking.booking.notes!),
        ],
        const SizedBox(height: _kMobileGap),
        _BDActivityCard(booking: ownerBooking.booking),
        const SizedBox(height: _kMobileGap),
        _BDMetaCard(ownerBooking: ownerBooking),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tablet grid (600–1023) — handoff BookingDetailTablet (booking-detail.jsx
// §222): full-width cover/pending/guest, then a 2-col grid. The handoff mock
// trims notes/activity/meta; we keep them (data over mock fidelity).
// ─────────────────────────────────────────────────────────────────────────
class _TabletGrid extends StatelessWidget {
  final OwnerBooking ownerBooking;
  const _TabletGrid({required this.ownerBooking});

  @override
  Widget build(BuildContext context) {
    final isPending = ownerBooking.booking.status == BookingStatus.pending;
    final notes = ownerBooking.booking.notes ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BDCover(ownerBooking: ownerBooking, height: _kCoverHeightTablet),
        const SizedBox(height: _kTabletGap),
        if (isPending) ...[
          const _BDPendingAlert(),
          const SizedBox(height: _kTabletGap),
        ],
        _BDGuestCard(ownerBooking: ownerBooking, compact: true),
        const SizedBox(height: _kTabletGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BDStayCard(ownerBooking: ownerBooking),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: _kTabletGap),
                    _BDNotesCard(notes: notes),
                  ],
                  const SizedBox(height: _kTabletGap),
                  _BDActivityCard(booking: ownerBooking.booking),
                ],
              ),
            ),
            const SizedBox(width: _kTabletGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BDStatusActions(ownerBooking: ownerBooking, sidebar: false),
                  const SizedBox(height: _kTabletGap),
                  _BDPriceCard(booking: ownerBooking.booking),
                  const SizedBox(height: _kTabletGap),
                  _BDMetaCard(ownerBooking: ownerBooking),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Cover — booking-detail.jsx §182 BDCover. Photo at top with gradient
// overlay carrying the property/unit identity.
// ─────────────────────────────────────────────────────────────────────────
class _BDCover extends StatelessWidget {
  final OwnerBooking ownerBooking;
  final double height;
  const _BDCover({required this.ownerBooking, required this.height});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final unit = ownerBooking.unit;
    final property = ownerBooking.property;
    final image = unit.primaryImage;

    return ClipRRect(
      borderRadius: BorderRadius.circular(BBRadius.md),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null && image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.surfaceVariant),
                errorWidget: (_, _, _) => Container(color: c.surfaceVariant),
              )
            else
              Container(
                color: c.surfaceVariant,
                alignment: Alignment.center,
                child: BbIcon(name: 'image', size: 40, color: c.textTertiary),
              ),
            // Gradient overlay carrying property/unit identity.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x9E10121C), Color(0x0010121C)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          property.name.toUpperCase(),
                          style: BBType.eyebrow(context).copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0x8CFFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          unit.name,
                          style: BBType.label(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Pending alert — booking-detail.jsx §172 BDPendingAlert. Accent-left
// tertiary tone, "Ova rezervacija čeka vaše odobrenje".
// ─────────────────────────────────────────────────────────────────────────
class _BDPendingAlert extends StatelessWidget {
  const _BDPendingAlert();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final rd = BbRedesignTokens.of(context);
    return BbCard(
      variant: BbCardVariant.accentLeft,
      child: Row(
        children: [
          BbIcon(
            name: 'pending_actions',
            size: 22,
            color: rd.statusPendingDeep,
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Text(
              'Ova rezervacija čeka vaše odobrenje',
              style: BBType.label(
                context,
              ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Guest card — booking-detail.jsx §47 BDGuestCard. Avatar + name +
// email · phone + secondary action icons for mail / call.
// ─────────────────────────────────────────────────────────────────────────
class _BDGuestCard extends StatelessWidget {
  final OwnerBooking ownerBooking;
  final bool compact;
  const _BDGuestCard({required this.ownerBooking, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final guest = ownerBooking.guestName;
    final email = ownerBooking.guestEmail;
    final phone = ownerBooking.guestPhone;

    return BbCard(
      child: Row(
        children: [
          BbAvatar(
            name: guest,
            size: compact ? BbAvatarSize.md : BbAvatarSize.lg,
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guest.isEmpty ? '—' : guest,
                  style: BBType.h3(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  phone != null && phone.isNotEmpty ? '$email · $phone' : email,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: BBSpace.xs),
          const _RoundIconButton(
            icon: 'mail',
            tooltip: 'Email',
            onPressed: null,
          ),
          const SizedBox(width: 6),
          const _RoundIconButton(
            icon: 'call',
            tooltip: 'Nazovi',
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(BBRadius.sm),
        ),
        alignment: Alignment.center,
        child: BbIcon(name: icon, size: 18, color: c.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stay card — booking-detail.jsx §63 BDStayCard. Key/value rows of the
// stay specifics (object, unit, dates, nights, guests, source).
// ─────────────────────────────────────────────────────────────────────────
class _BDStayCard extends StatelessWidget {
  final OwnerBooking ownerBooking;
  const _BDStayCard({required this.ownerBooking});

  @override
  Widget build(BuildContext context) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final checkInTime = booking.checkInTime ?? '14:00';
    final checkOutTime = booking.checkOutTime ?? '10:00';

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CardHeader(icon: 'event', title: 'Boravak'),
          const SizedBox(height: BBSpace.sm),
          _KvRow(label: 'Objekt', value: property.name),
          _KvRow(label: 'Jedinica', value: unit.name),
          _KvRow(
            label: 'Dolazak',
            value: '${_formatDate(booking.checkIn)} · $checkInTime',
          ),
          _KvRow(
            label: 'Odlazak',
            value: '${_formatDate(booking.checkOut)} · $checkOutTime',
          ),
          _KvRow(
            label: 'Trajanje',
            value:
                '${booking.numberOfNights} ${_nightLabel(booking.numberOfNights)}',
          ),
          _KvRow(
            label: 'Gosti',
            value: _guestLabel(booking.guestCount, booking.petCount),
          ),
          if (booking.source != null && booking.source!.isNotEmpty)
            _KvRow(label: 'Izvor', value: booking.source!, last: true),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}.';

  String _nightLabel(int n) {
    if (n == 1) return 'noć';
    if (n >= 2 && n <= 4) return 'noći';
    return 'noći';
  }

  String _guestLabel(int adults, int pets) {
    final adultLabel = adults == 1
        ? '1 odrasla osoba'
        : adults < 5
        ? '$adults odrasle osobe'
        : '$adults odraslih';
    if (pets > 0) {
      return '$adultLabel · $pets ${pets == 1 ? 'ljubimac' : 'ljubimaca'}';
    }
    return adultLabel;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Notes card — booking-detail.jsx §105 BDNotesCard.
// ─────────────────────────────────────────────────────────────────────────
class _BDNotesCard extends StatelessWidget {
  final String notes;
  const _BDNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CardHeader(icon: 'sticky_note_2', title: 'Napomena gosta'),
          const SizedBox(height: BBSpace.sm),
          Text(
            '„$notes"',
            style: BBType.body(
              context,
            ).copyWith(color: c.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Status + actions card — booking-detail.jsx §145 BDStatusActions. Status
// badge + relative time + primary Odobri/Odbij when pending; secondary
// Poruka / Uredi / Više on all statuses.
// ─────────────────────────────────────────────────────────────────────────
/// Pure gating for the detail action panel — single source of truth for which
/// actions render, consumed by [_BDStatusActionsState.build] and asserted by
/// `owner_booking_detail_actions_test.dart`. Guarantees no confirmed booking is
/// ever action-stranded (past → complete, upcoming → cancel, always msg/edit).
@visibleForTesting
({bool approveReject, bool complete, bool cancel, bool edit})
detailActionVisibility(BookingModel b) {
  final bool isPending = b.status == BookingStatus.pending;
  return (
    approveReject: isPending,
    complete: b.status == BookingStatus.confirmed && b.isPast,
    cancel: !isPending && b.canBeCancelled,
    edit: b.status != BookingStatus.cancelled,
  );
}

class _BDStatusActions extends ConsumerStatefulWidget {
  final OwnerBooking ownerBooking;
  final bool sidebar;
  const _BDStatusActions({required this.ownerBooking, required this.sidebar});

  @override
  ConsumerState<_BDStatusActions> createState() => _BDStatusActionsState();
}

class _BDStatusActionsState extends ConsumerState<_BDStatusActions> {
  bool _busy = false;

  Future<void> _approve() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerBookingsRepositoryProvider)
          .approveBooking(widget.ownerBooking.booking.id);
      if (!mounted) return;
      ErrorDisplayUtils.showSuccessSnackBar(context, 'Rezervacija odobrena');
      ref.invalidate(ownerBookingByIdProvider(widget.ownerBooking.booking.id));
    } catch (e) {
      if (!mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: 'Odobravanje nije uspjelo',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerBookingsRepositoryProvider)
          .rejectBooking(widget.ownerBooking.booking.id);
      if (!mounted) return;
      ErrorDisplayUtils.showSuccessSnackBar(context, 'Rezervacija odbijena');
      ref.invalidate(ownerBookingByIdProvider(widget.ownerBooking.booking.id));
    } catch (e) {
      if (!mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: 'Odbijanje nije uspjelo',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Mark a confirmed-past booking as completed. Mirrors the (now-removed)
  /// inline ledger action: reuses [BookingCompleteDialog] + repo.completeBooking.
  Future<void> _complete() async {
    if (_busy) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const BookingCompleteDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerBookingsRepositoryProvider)
          .completeBooking(widget.ownerBooking.booking.id);
      if (!mounted) return;
      ErrorDisplayUtils.showSuccessSnackBar(
        context,
        'Rezervacija označena kao završena',
      );
      ref.invalidate(ownerBookingByIdProvider(widget.ownerBooking.booking.id));
    } catch (e) {
      if (!mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: 'Označavanje nije uspjelo',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Cancel a cancellable booking. Mirrors the (now-removed) inline ledger
  /// action: reuses [BookingCancelDialog] (returns {reason, sendEmail}) +
  /// repo.cancelBooking.
  Future<void> _cancel() async {
    if (_busy) return;
    final Map<String, dynamic>? result =
        await showDialog<Map<String, dynamic>?>(
          context: context,
          builder: (BuildContext context) => const BookingCancelDialog(),
        );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerBookingsRepositoryProvider)
          .cancelBooking(
            widget.ownerBooking.booking.id,
            result['reason'] as String,
            sendEmail: result['sendEmail'] as bool,
          );
      if (!mounted) return;
      ErrorDisplayUtils.showWarningSnackBar(context, 'Rezervacija otkazana');
      ref.invalidate(ownerBookingByIdProvider(widget.ownerBooking.booking.id));
    } catch (e) {
      if (!mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: 'Otkazivanje nije uspjelo',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openEdit() {
    showEditBookingDialog(context, ref, widget.ownerBooking.booking);
  }

  void _openEmail() {
    showSendEmailDialog(context, ref, widget.ownerBooking.booking);
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final booking = widget.ownerBooking.booking;
    final vis = detailActionVisibility(booking);
    final relativeAgo = _relativeAgo(booking.createdAt);

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              BbStatusBadge(status: _toBbStatus(booking.status)),
              const Spacer(),
              Text(
                relativeAgo,
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          if (vis.approveReject) ...[
            BbButton(
              label: 'Odobri rezervaciju',
              iconLeft: 'check',
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : _approve,
            ),
            const SizedBox(height: 8),
            BbButton(
              label: 'Odbij',
              iconLeft: 'close',
              variant: BbButtonVariant.destructiveSoft,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : _reject,
            ),
            const SizedBox(height: BBSpace.sm),
            Divider(height: 1, color: c.border),
            const SizedBox(height: BBSpace.sm),
          ],
          Row(
            children: [
              Expanded(
                child: BbButton(
                  label: 'Poruka',
                  iconLeft: 'chat',
                  variant: BbButtonVariant.secondary,
                  size: BbButtonSize.sm,
                  onPressed: _openEmail,
                ),
              ),
              if (vis.edit) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: BbButton(
                    label: 'Uredi',
                    iconLeft: 'edit',
                    variant: BbButtonVariant.secondary,
                    size: BbButtonSize.sm,
                    onPressed: _openEdit,
                  ),
                ),
              ],
            ],
          ),
          // Complete / cancel — moved here from the (now-lean) ledger rows so
          // the confirmed-booking actions are not stranded. Status-gated to
          // match the old inline affordances.
          if (vis.complete) ...[
            const SizedBox(height: BBSpace.sm),
            BbButton(
              label: 'Označi kao završenu',
              iconLeft: 'done_all',
              variant: BbButtonVariant.success,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : _complete,
            ),
          ],
          if (vis.cancel) ...[
            const SizedBox(height: BBSpace.xs),
            BbButton(
              label: 'Otkaži rezervaciju',
              iconLeft: 'close',
              variant: BbButtonVariant.destructiveSoft,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy ? null : _cancel,
            ),
          ],
        ],
      ),
    );
  }

  String _relativeAgo(DateTime created) {
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 60) {
      return 'Primljeno prije ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Primljeno prije ${diff.inHours} h';
    }
    final days = diff.inDays;
    if (days == 1) return 'Primljeno prije 1 dana';
    return 'Primljeno prije $days dana';
  }

  BbBookingStatus _toBbStatus(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return BbBookingStatus.pending;
      case BookingStatus.confirmed:
        return BbBookingStatus.confirmed;
      case BookingStatus.cancelled:
        return BbBookingStatus.cancelled;
      case BookingStatus.completed:
        return BbBookingStatus.completed;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Mobile sticky-bottom Odobri/Odbij bar (pending only).
// ─────────────────────────────────────────────────────────────────────────
class _MobileStickyActions extends ConsumerStatefulWidget {
  final OwnerBooking ownerBooking;
  const _MobileStickyActions({required this.ownerBooking});

  @override
  ConsumerState<_MobileStickyActions> createState() =>
      _MobileStickyActionsState();
}

class _MobileStickyActionsState extends ConsumerState<_MobileStickyActions> {
  bool _busy = false;

  Future<void> _approve() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerBookingsRepositoryProvider)
          .approveBooking(widget.ownerBooking.booking.id);
      if (!mounted) return;
      ref.invalidate(ownerBookingByIdProvider(widget.ownerBooking.booking.id));
    } catch (e) {
      if (!mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: 'Odobravanje nije uspjelo',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(ownerBookingsRepositoryProvider)
          .rejectBooking(widget.ownerBooking.booking.id);
      if (!mounted) return;
      ref.invalidate(ownerBookingByIdProvider(widget.ownerBooking.booking.id));
    } catch (e) {
      if (!mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: 'Odbijanje nije uspjelo',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: BbButton(
              label: 'Odbij',
              iconLeft: 'close',
              variant: BbButtonVariant.destructiveSoft,
              loading: _busy,
              onPressed: _busy ? null : _reject,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: BbButton(
              label: 'Odobri',
              iconLeft: 'check',
              loading: _busy,
              onPressed: _busy ? null : _approve,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Price card — booking-detail.jsx §86 BDPriceCard. Money rows + total +
// 2-tile paid/remaining splash.
// ─────────────────────────────────────────────────────────────────────────
class _BDPriceCard extends StatelessWidget {
  final BookingModel booking;
  const _BDPriceCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final rd = BbRedesignTokens.of(context);
    final nights = booking.numberOfNights;
    final total = booking.totalPrice;
    final paid = booking.paidAmount;
    final remaining = (total - paid).clamp(0.0, double.infinity);

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CardHeader(icon: 'payments', title: 'Plaćanje'),
          const SizedBox(height: BBSpace.sm),
          _MoneyRow(
            label: 'Smještaj ($nights ${nights == 1 ? 'noć' : 'noći'})',
            value: _euro(total),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: c.border.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
          _MoneyRow(label: 'Ukupno', value: _euro(total), strong: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AmountTile(
                  label: 'PLAĆENO (POLOG)',
                  value: _euro(paid),
                  bg: rd.statusConfirmedTint,
                  fg: rd.statusConfirmedDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AmountTile(
                  label: 'PREOSTALO',
                  value: _euro(remaining),
                  bg: rd.statusPendingTint,
                  fg: rd.statusPendingDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _euro(num n) {
    final s = n.toStringAsFixed(2).replaceAll('.', ',');
    return '€$s';
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color fg;
  const _AmountTile({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BBRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: BBType.eyebrow(
              context,
            ).copyWith(color: c.textTertiary, fontSize: 10, letterSpacing: 0.4),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: BBType.h1Num(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: fg,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  const _MoneyRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: BBType.body(
                context,
              ).copyWith(color: c.textSecondary, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: BBType.h1Num(context).copyWith(
              fontSize: strong ? 18 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Activity card — booking-detail.jsx §114 BDActivityCard. Vertical
// timeline from createdAt + paid/approved/cancelled timestamps as
// available.
// ─────────────────────────────────────────────────────────────────────────
class _BDActivityCard extends StatelessWidget {
  final BookingModel booking;
  const _BDActivityCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    return BbCard(
      padded: false,
      child: Padding(
        padding: const EdgeInsets.all(BBSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CardHeader(icon: 'history', title: 'Aktivnost'),
            const SizedBox(height: BBSpace.sm),
            for (int i = 0; i < entries.length; i++)
              _TimelineRow(entry: entries[i], last: i == entries.length - 1),
          ],
        ),
      ),
    );
  }

  List<_ActivityEntry> _entries() {
    final list = <_ActivityEntry>[
      _ActivityEntry(
        icon: 'event_available',
        tone: _ActivityTone.pending,
        title: 'Rezervacija primljena',
        at: booking.createdAt,
      ),
    ];
    final paid = booking.paidAmount;
    if (paid > 0) {
      list.add(
        _ActivityEntry(
          icon: 'payments',
          tone: _ActivityTone.success,
          title:
              'Polog €${paid.toStringAsFixed(2).replaceAll('.', ',')} naplaćen',
          at: booking.updatedAt ?? booking.createdAt,
        ),
      );
    }
    final cancelledAt = booking.cancelledAt;
    if (cancelledAt != null) {
      list.add(
        _ActivityEntry(
          icon: 'event_busy',
          tone: _ActivityTone.error,
          title: 'Rezervacija otkazana',
          at: cancelledAt,
        ),
      );
    }
    return list;
  }
}

enum _ActivityTone { pending, success, info, error }

class _ActivityEntry {
  final String icon;
  final _ActivityTone tone;
  final String title;
  final DateTime at;
  const _ActivityEntry({
    required this.icon,
    required this.tone,
    required this.title,
    required this.at,
  });
}

class _TimelineRow extends StatelessWidget {
  final _ActivityEntry entry;
  final bool last;
  const _TimelineRow({required this.entry, required this.last});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final rd = BbRedesignTokens.of(context);
    final tone = _resolve(c, rd, entry.tone);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tone.bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: BbIcon(name: entry.icon, size: 16, color: tone.fg),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: c.border.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title,
                    style: BBType.label(context).copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _formatTime(entry.at),
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color fg}) _resolve(
    BBColorSet c,
    BbRedesignTokens rd,
    _ActivityTone tone,
  ) {
    switch (tone) {
      case _ActivityTone.pending:
        return (bg: rd.statusPendingTint, fg: rd.statusPendingDeep);
      case _ActivityTone.success:
        return (bg: rd.statusConfirmedTint, fg: rd.statusConfirmedDeep);
      case _ActivityTone.info:
        return (bg: c.info.withValues(alpha: 0.14), fg: c.info);
      case _ActivityTone.error:
        return (bg: c.error.withValues(alpha: 0.14), fg: c.error);
    }
  }

  String _formatTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}. ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────
// Meta card — booking-detail.jsx §164 BDMetaCard. Reference, created,
// channel.
// ─────────────────────────────────────────────────────────────────────────
class _BDMetaCard extends StatelessWidget {
  final OwnerBooking ownerBooking;
  const _BDMetaCard({required this.ownerBooking});

  @override
  Widget build(BuildContext context) {
    final booking = ownerBooking.booking;
    final reference = booking.bookingReference ?? booking.id;
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _KvRow(label: 'Broj rezervacije', value: '#$reference'),
          _KvRow(
            label: 'Kreirano',
            value:
                '${booking.createdAt.day.toString().padLeft(2, '0')}.${booking.createdAt.month.toString().padLeft(2, '0')}.${booking.createdAt.year}.',
          ),
          if (booking.source != null && booking.source!.isNotEmpty)
            _KvRow(label: 'Kanal', value: booking.source!, last: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared sub-components.
// ─────────────────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final String icon;
  final String title;
  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Row(
      children: [
        BbIcon(name: icon, size: 18, color: c.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: BBType.h3(
            context,
          ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _KvRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _kKvLabelWidth,
                child: Text(
                  label.toUpperCase(),
                  style: BBType.eyebrow(context).copyWith(
                    color: c.textTertiary,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: BBType.body(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (!last) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Provider — single OwnerBooking lookup. autoDispose so navigating away
// drops the subscription; family-keyed by bookingId.
// ─────────────────────────────────────────────────────────────────────────
final ownerBookingByIdProvider = FutureProvider.autoDispose
    .family<OwnerBooking?, String>((ref, bookingId) async {
      final repo = ref.watch(ownerBookingsRepositoryProvider);
      return repo.getOwnerBookingById(bookingId);
    });
