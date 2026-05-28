import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'bb_button.dart';

/// Empty-state slot. Use for "no bookings yet", "no iCal feeds connected", etc.
///
/// Highest-ROI component per audit/71 — empty states are where users drop off
/// or pick up a feature. Pattern:
///   icon/illustration ▸ headline ▸ body ▸ primary CTA ▸ optional secondary CTA
///   ▸ optional benefits row (3 inline value-prop bullets).
class BBEmptyState extends StatelessWidget {
  const BBEmptyState({
    super.key,
    required this.headline,
    this.body,
    this.icon,
    this.illustration,
    this.primaryCtaLabel,
    this.onPrimaryCta,
    this.secondaryCtaLabel,
    this.onSecondaryCta,
    this.benefits = const <BBEmptyStateBenefit>[],
  });

  final String headline;
  final String? body;
  final IconData? icon;

  /// Custom illustration. Takes precedence over [icon] when both supplied.
  final Widget? illustration;

  final String? primaryCtaLabel;
  final VoidCallback? onPrimaryCta;
  final String? secondaryCtaLabel;
  final VoidCallback? onSecondaryCta;

  /// Optional inline value-prop row (≤3 recommended). Renders below CTAs.
  final List<BBEmptyStateBenefit> benefits;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);

    Widget? hero;
    if (illustration != null) {
      hero = illustration;
    } else if (icon != null) {
      hero = Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: c.primaryLight.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 40, color: c.primary),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: BBSpace.md,
        vertical: BBSpace.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (hero != null) ...<Widget>[
            hero,
            const SizedBox(height: BBSpace.md),
          ],
          Text(
            headline,
            style: BBType.h2(context),
            textAlign: TextAlign.center,
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: BBSpace.xs),
            Text(
              body!,
              style: BBType.body(context).copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (primaryCtaLabel != null) ...<Widget>[
            const SizedBox(height: BBSpace.md),
            BBButton(label: primaryCtaLabel!, onPressed: onPrimaryCta),
          ],
          if (secondaryCtaLabel != null) ...<Widget>[
            const SizedBox(height: BBSpace.xs),
            BBButton(
              label: secondaryCtaLabel!,
              onPressed: onSecondaryCta,
              variant: BBButtonVariant.tertiary,
            ),
          ],
          if (benefits.isNotEmpty) ...<Widget>[
            const SizedBox(height: BBSpace.md),
            Wrap(
              spacing: BBSpace.md,
              runSpacing: BBSpace.xs,
              children: benefits.map(_BenefitItem.new).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

@immutable
class BBEmptyStateBenefit {
  const BBEmptyStateBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem(this.b);
  final BBEmptyStateBenefit b;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(b.icon, size: 16, color: c.success),
        const SizedBox(width: BBSpace.xs),
        Text(b.label, style: BBType.caption(context)),
      ],
    );
  }
}
