import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_button.dart';
import 'bb_icon.dart';

class BbEmptyStateBenefit {
  const BbEmptyStateBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });
  final String icon;
  final String title;
  final String body;
}

class BbEmptyStateAction {
  const BbEmptyStateAction({
    required this.label,
    this.onPressed,
    this.iconLeft,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? iconLeft;
}

/// Empty-state pattern (handoff [BBEmptyState]; iCal-import gold-standard).
class BbEmptyState extends StatelessWidget {
  const BbEmptyState({
    super.key,
    this.icon = 'inbox',
    this.illustration,
    required this.title,
    this.body,
    this.primary,
    this.secondary,
    this.benefits,
    this.compact = false,
  });

  final String icon;
  final Widget? illustration;
  final String title;
  final String? body;
  final BbEmptyStateAction? primary;
  final BbEmptyStateAction? secondary;
  final List<BbEmptyStateBenefit>? benefits;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final double pad = compact ? 32 : 56;
    final double iconBox = compact ? 72 : 96;
    final double iconSize = compact ? 36 : 48;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          illustration ??
              Container(
                width: iconBox,
                height: iconBox,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.06),
                  borderRadius: BBRadius.lgAll,
                ),
                child: Center(
                  child: BbIcon(name: icon, size: iconSize, color: c.primary),
                ),
              ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              title,
              style: BBType.h2(context),
              textAlign: TextAlign.center,
            ),
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: BBSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                body!,
                style: BBType.body(context).copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (primary != null || secondary != null) ...<Widget>[
            const SizedBox(height: BBSpace.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (primary != null)
                  BbButton(
                    label: primary!.label,
                    iconLeft: primary!.iconLeft,
                    onPressed: primary!.onPressed,
                  ),
                if (primary != null && secondary != null)
                  const SizedBox(width: BBSpace.xs),
                if (secondary != null)
                  BbButton(
                    label: secondary!.label,
                    variant: BbButtonVariant.secondary,
                    onPressed: secondary!.onPressed,
                  ),
              ],
            ),
          ],
          if (benefits != null && benefits!.isNotEmpty) ...<Widget>[
            const SizedBox(height: BBSpace.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: LayoutBuilder(
                builder: (BuildContext _, BoxConstraints cs) {
                  final int cols = cs.maxWidth < 480
                      ? 1
                      : benefits!.length.clamp(1, 3);
                  final double itemW = (cs.maxWidth - (cols - 1) * 16) / cols;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: benefits!
                        .map(
                          (BbEmptyStateBenefit b) => SizedBox(
                            width: itemW,
                            child: _BenefitCard(benefit: b, color: c),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit, required this.color});
  final BbEmptyStateBenefit benefit;
  final BBColorSet color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.surfaceVariant,
        borderRadius: BBRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: BbIcon(name: benefit.icon, color: color.primary),
            ),
          ),
          Text(benefit.title, style: BBType.label(context)),
          const SizedBox(height: 4),
          Text(
            benefit.body,
            style: BBType.caption(context).copyWith(color: color.textSecondary),
          ),
        ],
      ),
    );
  }
}
