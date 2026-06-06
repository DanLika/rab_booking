import 'package:flutter/material.dart';

import '../../../../../core/design/tokens.dart';
import '../../../../../shared/widgets/redesign.dart';

/// Premium header for iCal Sync screen (audit/117 §B4 pattern, mirrors
/// handoff `ical.jsx` ICalDesktop top row).
///
/// Replaces the legacy saturated brand-primary hero card with the calm
/// Pregled-shaped premium chrome: eyebrow + display H1 + subtitle stats
/// + optional "Dodaj feed" CTA. Composes existing Bb* primitives — no new
/// design tokens or component variants.
class IcalSyncPremiumHeader extends StatelessWidget {
  const IcalSyncPremiumHeader({
    super.key,
    required this.totalFeeds,
    required this.activeFeeds,
    required this.errorFeeds,
    this.onAddFeed,
  });

  final int totalFeeds;
  final int activeFeeds;
  final int errorFeeds;
  final VoidCallback? onAddFeed;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;

    final String subtitle = totalFeeds == 0
        ? 'Dodajte vanjski iCal feed da sinkronizirate Booking.com, Airbnb i ostale platforme.'
        : '$activeFeeds aktivnih feedova · $totalFeeds ukupno'
              '${errorFeeds > 0 ? ' · $errorFeeds s greškom' : ''}';

    final Widget eyebrow = Text(
      'INTEGRACIJE · ICAL',
      style: BBType.eyebrow(context).copyWith(color: c.primary),
    );
    final Widget title = Text(
      'iCal feedovi',
      style: BBType.h1(context).copyWith(
        fontSize: isMobile ? 24 : 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
    );
    final Widget sub = Text(
      subtitle,
      style: BBType.body(context).copyWith(color: c.textTertiary),
    );
    final Widget? cta = onAddFeed == null
        ? null
        : BbButton(
            label: 'Dodaj feed',
            iconLeft: 'add_link',
            onPressed: onAddFeed,
            size: isMobile ? BbButtonSize.sm : BbButtonSize.md,
          );

    if (isMobile || cta == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          eyebrow,
          const SizedBox(height: 4),
          title,
          const SizedBox(height: 6),
          sub,
          if (cta != null) ...<Widget>[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: cta),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              eyebrow,
              const SizedBox(height: 4),
              title,
              const SizedBox(height: 6),
              sub,
            ],
          ),
        ),
        const SizedBox(width: 16),
        cta,
      ],
    );
  }
}
