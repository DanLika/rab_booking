import 'package:flutter/material.dart';

import '../../../../../core/constants/enums.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../../data/firebase/firebase_owner_bookings_repository.dart'
    show OwnerBooking;
import '../../../domain/models/ical_feed.dart';

/// Lean premium bookings ledger — faithful port of
/// `design_handoff/source/rezervacije-premium.jsx` RZPLedger (lines 320-398),
/// RZPMobileRow (403-420) and RZPPayCell (301-318).
///
/// The ledger is intentionally READ-ONLY: rows tap through to the booking
/// detail screen. The daily-driver actions (approve/reject) live in the
/// pending-queue (`bookings_premium_header.dart`); confirmed complete/cancel
/// live in the detail screen. No inline action buttons here — this is the
/// scannable ledger surface, not the action surface.
///
/// Pure presentation: takes a normalized [BookingsLedgerEntry] list plus
/// callbacks and reads NO providers, so it is driveable from a widget test
/// (responsive overflow harness) without a ProviderScope.
class BookingsLedger extends StatelessWidget {
  const BookingsLedger({
    super.key,
    required this.tabBar,
    required this.entries,
    required this.onOpenDetail,
    this.bodyOverride,
    this.onFilters,
    this.footerLabel,
  });

  /// Status tabs widget (composed by the screen; usually `BookingsTabBar`).
  final Widget tabBar;

  /// Normalized rows. Ignored when [bodyOverride] is non-null.
  final List<BookingsLedgerEntry> entries;

  /// Tap handler for a navigable row (regular bookings only).
  final void Function(String bookingId) onOpenDetail;

  /// When set (loading / empty / error), replaces the table/rows body and the
  /// footer is hidden. Keeps the tabs header visible across all states.
  final Widget? bodyOverride;

  /// Opens the advanced filters dialog. Hidden when null.
  final VoidCallback? onFilters;

  /// Footer count line ("Prikazano X …"). Hidden when null or [bodyOverride].
  final String? footerLabel;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);

    return BbCard(
      padded: false,
      child: ClipRRect(
        borderRadius: BBRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _LedgerHeader(tabBar: tabBar, onFilters: onFilters),
            if (bodyOverride != null)
              bodyOverride!
            else
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool wide =
                      constraints.maxWidth >= _LedgerMetrics.tableMinWidth;
                  return wide
                      ? _LedgerTable(
                          entries: entries,
                          onOpenDetail: onOpenDetail,
                        )
                      : _LedgerCompactList(
                          entries: entries,
                          onOpenDetail: onOpenDetail,
                        );
                },
              ),
            if (bodyOverride == null && footerLabel != null)
              _LedgerFooter(label: footerLabel!, color: c),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Header — tabs (left) + Filteri button (right). Handoff RZPLedger 379-385.
// ───────────────────────────────────────────────────────────────────────────
class _LedgerHeader extends StatelessWidget {
  final Widget tabBar;
  final VoidCallback? onFilters;
  const _LedgerHeader({required this.tabBar, required this.onFilters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _LedgerMetrics.rowHPad,
        BBSpace.sm,
        _LedgerMetrics.rowHPad,
        BBSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: tabBar),
          if (onFilters != null) ...<Widget>[
            const SizedBox(width: BBSpace.xs),
            BbButton(
              label: 'Filteri',
              iconLeft: 'tune',
              variant: BbButtonVariant.secondary,
              size: BbButtonSize.sm,
              onPressed: onFilters,
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Desktop grid table — handoff RZP_GRID 7 columns.
// ───────────────────────────────────────────────────────────────────────────
class _LedgerTable extends StatelessWidget {
  final List<BookingsLedgerEntry> entries;
  final void Function(String bookingId) onOpenDetail;
  const _LedgerTable({required this.entries, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LedgerTableHeader(color: c),
        for (int i = 0; i < entries.length; i++)
          _LedgerTableRow(
            entry: entries[i],
            first: i == 0,
            onOpenDetail: onOpenDetail,
          ),
      ],
    );
  }
}

class _LedgerTableHeader extends StatelessWidget {
  final BBColorSet color;
  const _LedgerTableHeader({required this.color});

  @override
  Widget build(BuildContext context) {
    final TextStyle s = BBType.eyebrow(
      context,
    ).copyWith(color: color.textTertiary, fontSize: _LedgerMetrics.colHeadFont);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _LedgerMetrics.rowHPad,
        vertical: _LedgerMetrics.headVPad,
      ),
      decoration: BoxDecoration(
        color: color.surfaceVariant,
        border: Border(
          top: BorderSide(color: color.border),
          bottom: BorderSide(color: color.border),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: _LedgerMetrics.flexGuest,
            child: Text('GOST', style: s),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            flex: _LedgerMetrics.flexObject,
            child: Text('OBJEKT', style: s),
          ),
          const SizedBox(width: BBSpace.sm),
          SizedBox(
            width: _LedgerMetrics.colTermin,
            child: Text('TERMIN', style: s),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            flex: _LedgerMetrics.flexPay,
            child: Text('PLAĆANJE', style: s),
          ),
          const SizedBox(width: BBSpace.sm),
          SizedBox(
            width: _LedgerMetrics.colAmount,
            child: Text('IZNOS', style: s, textAlign: TextAlign.right),
          ),
          const SizedBox(width: BBSpace.sm),
          SizedBox(
            width: _LedgerMetrics.colStatus,
            child: Text('STATUS', style: s),
          ),
          const SizedBox(width: BBSpace.sm),
          const SizedBox(width: _LedgerMetrics.colChevron),
        ],
      ),
    );
  }
}

class _LedgerTableRow extends StatelessWidget {
  final BookingsLedgerEntry entry;
  final bool first;
  final void Function(String bookingId) onOpenDetail;
  const _LedgerTableRow({
    required this.entry,
    required this.first,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final String? navId = entry.detailBookingId;

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _LedgerMetrics.rowHPad,
        vertical: _LedgerMetrics.rowVPad,
      ),
      child: Row(
        children: <Widget>[
          // Gost
          Expanded(
            flex: _LedgerMetrics.flexGuest,
            child: Row(
              children: <Widget>[
                BbAvatar(name: entry.guestName, size: BbAvatarSize.sm),
                const SizedBox(width: _LedgerMetrics.avatarGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        entry.guestName,
                        style: BBType.label(context).copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        entry.reference,
                        style: BBType.mono(context).copyWith(
                          color: c.textTertiary,
                          fontSize: _LedgerMetrics.refFont,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          // Objekt
          Expanded(
            flex: _LedgerMetrics.flexObject,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.propertyName,
                  style: BBType.body(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.unitName.isNotEmpty)
                  Text(
                    entry.unitName,
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          // Termin
          SizedBox(
            width: _LedgerMetrics.colTermin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.range,
                  style: BBType.bodyNum(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.nights} ${_nightWord(entry.nights)} · ${entry.guests} ${_guestWord(entry.guests)}',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          // Plaćanje
          Expanded(
            flex: _LedgerMetrics.flexPay,
            child: _PaymentCell(entry: entry, color: c),
          ),
          const SizedBox(width: BBSpace.sm),
          // Iznos
          SizedBox(
            width: _LedgerMetrics.colAmount,
            child: Text(
              entry.amountLabel,
              textAlign: TextAlign.right,
              style: BBType.bodyNum(context).copyWith(
                color: entry.isCancelled ? c.textTertiary : c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: _LedgerMetrics.amountFont,
                decoration: entry.isCancelled
                    ? TextDecoration.lineThrough
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          // Status
          SizedBox(
            width: _LedgerMetrics.colStatus,
            child: Align(
              alignment: Alignment.centerLeft,
              child: BbStatusBadge(
                status: entry.status,
                size: BbStatusBadgeSize.sm,
              ),
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          // Chevron
          SizedBox(
            width: _LedgerMetrics.colChevron,
            child: navId == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerRight,
                    child: BbIcon(name: 'chevron_right', color: c.textTertiary),
                  ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: navId == null ? null : () => onOpenDetail(navId),
          hoverColor: c.primary.withValues(alpha: _LedgerMetrics.hoverAlpha),
          child: row,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Payment progress cell — handoff RZPPayCell 301-318.
// ───────────────────────────────────────────────────────────────────────────
class _PaymentCell extends StatelessWidget {
  final BookingsLedgerEntry entry;
  final BBColorSet color;
  const _PaymentCell({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    if (!entry.hasPayment) {
      return Text(
        '—',
        style: BBType.caption(context).copyWith(color: color.textTertiary),
      );
    }
    final int pct = entry.paymentPct;
    final bool full = entry.isFullyPaid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                full ? 'Plaćeno' : entry.paidLabel,
                style: BBType.caption(context).copyWith(
                  color: full ? color.success : color.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!full)
              Text(
                '$pct%',
                style: BBType.caption(context).copyWith(
                  color: color.textTertiary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: _LedgerMetrics.payGap),
        ClipRRect(
          borderRadius: BBRadius.fullAll,
          child: LinearProgressIndicator(
            value: (pct / 100.0).clamp(0.0, 1.0),
            minHeight: _LedgerMetrics.payBarH,
            backgroundColor: color.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color.success),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Mobile / tablet compact row — handoff RZPMobileRow 403-420.
// ───────────────────────────────────────────────────────────────────────────
class _LedgerCompactList extends StatelessWidget {
  final List<BookingsLedgerEntry> entries;
  final void Function(String bookingId) onOpenDetail;
  const _LedgerCompactList({required this.entries, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < entries.length; i++)
          _LedgerCompactRow(
            entry: entries[i],
            first: i == 0,
            onOpenDetail: onOpenDetail,
          ),
      ],
    );
  }
}

class _LedgerCompactRow extends StatelessWidget {
  final BookingsLedgerEntry entry;
  final bool first;
  final void Function(String bookingId) onOpenDetail;
  const _LedgerCompactRow({
    required this.entry,
    required this.first,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final String? navId = entry.detailBookingId;

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _LedgerMetrics.compactHPad,
        vertical: _LedgerMetrics.rowVPad,
      ),
      child: Row(
        children: <Widget>[
          BbAvatar(name: entry.guestName, size: BbAvatarSize.sm),
          const SizedBox(width: _LedgerMetrics.avatarGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.guestName,
                        style: BBType.label(context).copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: BBSpace.xs),
                    Text(
                      entry.amountLabel,
                      style: BBType.bodyNum(context).copyWith(
                        color: entry.isCancelled
                            ? c.textTertiary
                            : c.textPrimary,
                        fontWeight: FontWeight.w700,
                        decoration: entry.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _LedgerMetrics.payGap),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${entry.range} · ${entry.propertyName}',
                        style: BBType.caption(
                          context,
                        ).copyWith(color: c.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: BBSpace.xs),
                    BbStatusBadge(
                      status: entry.status,
                      size: BbStatusBadgeSize.sm,
                      dot: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: navId == null ? null : () => onOpenDetail(navId),
          hoverColor: c.primary.withValues(alpha: _LedgerMetrics.hoverAlpha),
          child: row,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Footer — "Prikazano X …" count line. Handoff RZPLedger 390-396.
// ───────────────────────────────────────────────────────────────────────────
class _LedgerFooter extends StatelessWidget {
  final String label;
  final BBColorSet color;
  const _LedgerFooter({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _LedgerMetrics.rowHPad,
        vertical: _LedgerMetrics.rowVPad,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: color.border)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.list_alt,
            size: _LedgerMetrics.footerIcon,
            color: color.textTertiary,
          ),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Text(
              label,
              style: BBType.caption(context).copyWith(
                color: color.textSecondary,
                fontWeight: FontWeight.w500,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _nightWord(int n) => n == 1 ? 'noć' : 'noći';
String _guestWord(int n) => n == 1 ? 'gost' : 'gosta';

// ───────────────────────────────────────────────────────────────────────────
// Off-grid tuned metrics (handoff-derived; named so the page stays free of
// raw layout literals). Values that match the BBSpace scale use the token.
// ───────────────────────────────────────────────────────────────────────────
abstract final class _LedgerMetrics {
  /// Below this body width we fall back to compact rows (tablet + phone),
  /// matching the handoff where only the 1440 desktop shows the grid table.
  static const double tableMinWidth = 820;

  static const double rowHPad = 20; // RZPLedgerRow padding-x
  static const double rowVPad = 14; // RZPLedgerRow padding-y
  static const double headVPad = 10; // RZPLedgerHeader padding-y
  static const double compactHPad =
      16; // RZPMobileRow padding-x (== BBSpace.sm)
  static const double avatarGap = 12; // avatar → text gap (handoff gap:12)

  static const double colTermin = 150;
  static const double colAmount = 92;
  static const double colStatus = 116;
  static const double colChevron = 40;

  static const int flexGuest = 34; // 1.7fr
  static const int flexObject = 23; // 1.15fr
  static const int flexPay = 20; // 1fr (min 110 honored by wide-only render)

  static const double colHeadFont = 10;
  static const double refFont = 11;
  static const double amountFont = 15;
  static const double payBarH = 6;
  static const double payGap = 5;
  static const double footerIcon = 14;
  static const double hoverAlpha = 0.06;
}

// ───────────────────────────────────────────────────────────────────────────
// Normalized view-model — insulates the ledger from booking-model + iCal-event
// shape differences (imported events carry no price/payment data).
// ───────────────────────────────────────────────────────────────────────────
@immutable
class BookingsLedgerEntry {
  final String? detailBookingId; // null → not navigable (imported iCal events)
  final String guestName;
  final String reference;
  final String propertyName;
  final String unitName;
  final String range;
  final int nights;
  final int guests;
  final BbBookingStatus status;
  final bool isCancelled;

  /// Whether a payment-progress cell should render (false for imported /
  /// cancelled / zero-total bookings → shows "—").
  final bool hasPayment;
  final double total;
  final double paid;

  const BookingsLedgerEntry({
    required this.detailBookingId,
    required this.guestName,
    required this.reference,
    required this.propertyName,
    required this.unitName,
    required this.range,
    required this.nights,
    required this.guests,
    required this.status,
    required this.isCancelled,
    required this.hasPayment,
    required this.total,
    required this.paid,
  });

  bool get isFullyPaid => total > 0 && paid >= total;
  int get paymentPct =>
      total > 0 ? ((paid / total) * 100).round().clamp(0, 100) : 0;
  String get paidLabel => '€${paid.toStringAsFixed(0)}';
  String get amountLabel => hasAmount ? '€${total.toStringAsFixed(0)}' : '—';
  bool get hasAmount => total > 0;

  factory BookingsLedgerEntry.fromOwnerBooking(OwnerBooking ob) {
    final BookingModel b = ob.booking;
    final bool cancelled = b.status == BookingStatus.cancelled;
    return BookingsLedgerEntry(
      detailBookingId: b.id,
      guestName: ob.guestName.isNotEmpty ? ob.guestName : (b.guestName ?? '—'),
      reference: '#${b.bookingReference ?? b.id}',
      propertyName: ob.property.name,
      unitName: ob.unit.name,
      range: _formatRange(b.checkIn, b.checkOut),
      nights: b.numberOfNights > 0 ? b.numberOfNights : 1,
      guests: b.guestCount,
      status: _toBbStatus(b.status),
      isCancelled: cancelled,
      hasPayment: !cancelled && b.totalPrice > 0,
      total: b.totalPrice,
      paid: b.paidAmount,
    );
  }

  factory BookingsLedgerEntry.fromImportedEvent(IcalEvent e) {
    final int nights = e.numberOfNights;
    return BookingsLedgerEntry(
      detailBookingId: null, // iCal events have no owner detail route
      guestName: e.guestName.isNotEmpty ? e.guestName : 'Gost',
      reference: '#${e.externalId.isNotEmpty ? e.externalId : e.id}',
      propertyName: IcalPlatform.fromString(e.source).displayName,
      unitName: 'Uvezena rezervacija',
      range: _formatRange(e.startDate, e.endDate),
      nights: nights > 0 ? nights : 1,
      guests: 0,
      status: BbBookingStatus.imported,
      isCancelled: false,
      hasPayment: false,
      total: 0,
      paid: 0,
    );
  }

  static BbBookingStatus _toBbStatus(BookingStatus s) {
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

  /// "18.–22. srp" — mirrors `bookings_premium_header.dart` _formatRange so the
  /// queue and ledger speak the same date language.
  static String _formatRange(DateTime a, DateTime b) {
    final String month = _hrShortMonths[(b.month - 1).clamp(0, 11)];
    return '${a.day}.–${b.day}. $month';
  }
}
