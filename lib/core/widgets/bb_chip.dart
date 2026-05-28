import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Filter / choice chip.
///
/// Critical: callers MUST wrap a row of chips in [Wrap] (not horizontal scroll
/// or fixed Row) so large font scale doesn't push them off-screen. See
/// audit/63 F-63-04 — filter chip rows overflow at 200% font scale.
class BBChip extends StatelessWidget {
  const BBChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool disabled = onTap == null;

    final Color bg = selected ? c.primary : c.surface;
    final Color fg = selected
        ? Colors.white
        : (disabled ? c.textTertiary : c.textPrimary);
    final Color borderColor = selected ? c.primary : c.border;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BBRadius.smAll,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: BBSpace.sm,
              vertical: BBSpace.xs,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BBRadius.smAll,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: BBSpace.xs),
                ],
                Text(label, style: BBType.label(context).copyWith(color: fg)),
                if (count != null) ...<Widget>[
                  const SizedBox(width: BBSpace.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BBSpace.xxs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.2)
                          : c.surfaceVariant,
                      borderRadius: BBRadius.fullAll,
                    ),
                    child: Text(
                      '$count',
                      style: BBType.caption(context).copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
