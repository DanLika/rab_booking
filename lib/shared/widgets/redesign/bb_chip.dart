import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_icon.dart';

enum BbChipVariant { filter, tab }

enum BbChipSize { sm, md }

/// Filter / choice chip (handoff [BBChip]).
///
/// - selected (filter): brand fill, white text, purple glow
/// - selected (tab): white fill, brand border, brand text
/// - optional count badge, leading dot, leading/trailing icon
///
/// **A11y (audit sweep F2.3):** the chip announces as a button with its
/// selected state and label (count folded in); the tappable box is floored
/// to 44px while the visual pill keeps its 32/40px height. Text-scale
/// minHeight relaxation is deferred (would reshape the pill — needs its own
/// golden pass).
class BbChip extends StatelessWidget {
  const BbChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.iconLeft,
    this.iconRight,
    this.count,
    this.countColor,
    this.dotColor,
    this.variant = BbChipVariant.filter,
    this.size = BbChipSize.md,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final String? iconLeft;
  final String? iconRight;
  final int? count;
  final Color? countColor;
  final Color? dotColor;
  final BbChipVariant variant;
  final BbChipSize size;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final double h = size == BbChipSize.sm ? 32 : 40;
    final double hPad = size == BbChipSize.sm ? 12 : 14;

    final bool filterSelected = selected && variant == BbChipVariant.filter;
    final bool tabSelected = selected && variant == BbChipVariant.tab;

    final Color bg = filterSelected ? c.primary : c.surface;
    final Color fg = filterSelected
        ? Colors.white
        : tabSelected
        ? c.primary
        : c.textSecondary;
    final Color border = selected ? c.primary : c.border;

    final Widget pill = Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BBRadius.fullAll,
        border: Border.all(color: border),
        // Theme-aware glow — the static purpleSm is light-only and left
        // dark-mode selected chips glowless (audit F2.3).
        boxShadow: filterSelected
            ? BBShadow.purpleGlow(context)
            : const <BoxShadow>[],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dotColor != null) ...<Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (iconLeft != null) ...<Widget>[
            BbIcon(name: iconLeft!, size: 16, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              height: 1,
            ),
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filterSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (countColor ?? c.primary.withValues(alpha: 0.10)),
                borderRadius: BBRadius.fullAll,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: filterSelected
                      ? Colors.white
                      : (countColor != null ? Colors.white : c.primary),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
          if (iconRight != null) ...<Widget>[
            const SizedBox(width: 8),
            BbIcon(name: iconRight!, size: 16, color: fg),
          ],
        ],
      ),
    );

    // One merged semantics node: role + selected state + label (count folded
    // in) — the raw tree announced nothing (audit F2.3 ROOT, A11y 0/4).
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: count != null ? '$label, $count' : label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BBRadius.fullAll,
          focusColor: c.primary.withValues(alpha: 0.12),
          hoverColor: c.primary.withValues(alpha: 0.06),
          // Hit-area floor: 44px tap box, visual pill unchanged (32/40).
          child: SizedBox(
            height: _kMinTapSize,
            child: Center(widthFactor: 1, child: pill),
          ),
        ),
      ),
    );
  }

  /// WCAG 2.5.5 minimum touch target (same floor as BbButton F2.2).
  static const double _kMinTapSize = 44;
}
