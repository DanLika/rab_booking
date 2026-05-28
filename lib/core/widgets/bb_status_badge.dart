import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Booking lifecycle status. Resolves to a colored pill with label.
enum BBStatus { confirmed, pending, cancelled, completed, imported }

class BBStatusBadge extends StatelessWidget {
  const BBStatusBadge({super.key, required this.status, this.label});

  final BBStatus status;

  /// Optional override label (e.g. localized). Defaults to enum name.
  final String? label;

  Color _color(BBColorSet c) {
    switch (status) {
      case BBStatus.confirmed:
        return c.statusConfirmed;
      case BBStatus.pending:
        return c.statusPending;
      case BBStatus.cancelled:
        return c.statusCancelled;
      case BBStatus.completed:
        return c.statusCompleted;
      case BBStatus.imported:
        return c.statusImported;
    }
  }

  String _defaultLabel() {
    switch (status) {
      case BBStatus.confirmed:
        return 'Potvrđeno';
      case BBStatus.pending:
        return 'Na čekanju';
      case BBStatus.cancelled:
        return 'Otkazano';
      case BBStatus.completed:
        return 'Završeno';
      case BBStatus.imported:
        return 'Uvezeno';
    }
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final Color base = _color(c);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.xs,
        vertical: BBSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BBRadius.fullAll,
      ),
      child: Text(
        label ?? _defaultLabel(),
        style: BBType.caption(
          context,
        ).copyWith(color: base, fontWeight: FontWeight.w600),
      ),
    );
  }
}
