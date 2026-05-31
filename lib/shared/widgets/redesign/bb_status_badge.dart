import 'package:flutter/material.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';

/// Booking lifecycle status (matches handoff [BBStatusBadge]).
enum BbBookingStatus { confirmed, pending, cancelled, completed, imported }

enum BbStatusBadgeSize { sm, md }

/// Pill with dot + label per handoff `--bb-status-*` token table.
/// Uses redesign deep colors (AA-safe pending darker than legacy bright amber).
class BbStatusBadge extends StatelessWidget {
  const BbStatusBadge({
    super.key,
    required this.status,
    this.label,
    this.dot = true,
    this.size = BbStatusBadgeSize.md,
  });

  final BbBookingStatus status;

  /// Override label (e.g. localized). Defaults to HR per `primitives.jsx:statusMap`.
  final String? label;

  final bool dot;
  final BbStatusBadgeSize size;

  ({Color fg, Color bg, Color dot, String label}) _resolve(
    BbRedesignTokens rd,
    BBColorSet c,
  ) {
    switch (status) {
      case BbBookingStatus.confirmed:
        return (
          fg: rd.statusConfirmedDeep,
          bg: rd.statusConfirmedTint,
          dot: rd.statusConfirmedDeep,
          label: 'Potvrđeno',
        );
      case BbBookingStatus.pending:
        return (
          fg: rd.statusPendingDeep,
          bg: rd.statusPendingTint,
          dot: c.tertiary,
          label: 'Na čekanju',
        );
      case BbBookingStatus.cancelled:
        return (
          fg: rd.statusCancelledDeep,
          bg: rd.statusCancelledTint,
          dot: c.textTertiary,
          label: 'Otkazano',
        );
      case BbBookingStatus.completed:
        return (
          fg: c.statusCompleted,
          bg: rd.statusCompletedTint,
          dot: c.statusCompleted,
          label: 'Završeno',
        );
      case BbBookingStatus.imported:
        return (
          fg: c.statusImported,
          bg: rd.statusImportedTint,
          dot: c.statusImported,
          label: 'Uvezeno',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final BbRedesignTokens rd = BbRedesignTokens.of(context);
    final BBColorSet c = BBColor.of(context);
    final ({Color fg, Color bg, Color dot, String label}) s = _resolve(rd, c);

    final double h = size == BbStatusBadgeSize.sm ? 22 : 26;
    return Container(
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: s.bg, borderRadius: BBRadius.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: s.dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label ?? s.label,
            style: TextStyle(
              color: s.fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.12,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
