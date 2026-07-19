import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../shared/widgets/redesign.dart';

/// Shared section card for the Widget Settings page.
///
/// FLAT section look since CHANGELOG 7.23 (the TIP-1 diagonal gradient was
/// retired; `context.gradients.sectionBackground` renders as a SOLID fill) +
/// hairline `sectionBorder` + `BBShadow.elevated`, unified on `BBRadius.lg`.
/// Header = primary-tinted icon chip + `BBType.h3` title + optional
/// [trailing].
///
/// Replaces the per-section hand-rolled
/// `Container > ClipRRect > Container(color: cardBackground, circular(24))`
/// chrome that drifted across the legacy sections (flat `cardBackground`,
/// mixed 24/12 radius, hand-rolled shadows, raw `fontSize`).
class WidgetSettingsSection extends StatelessWidget {
  const WidgetSettingsSection({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    super.key,
  });

  /// Material Symbol name (e.g. `'widgets'`, `'code'`, `'palette'`).
  final String icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BBRadius.lgAll,
        border: Border.all(
          color: context.gradients.sectionBorder,
          width: BBBorderWidth.medium,
        ),
        boxShadow: BBShadow.elevated(context),
      ),
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(BBSpace.xs),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: BBOpacity.mediumOverlay),
                  borderRadius: BBRadius.smAll,
                ),
                child: BbIcon(name: icon, color: c.primary),
              ),
              const SizedBox(width: BBSpace.xs),
              Expanded(child: Text(title, style: BBType.h3(context))),
              if (trailing != null) ...[
                const SizedBox(width: BBSpace.xs),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: BBSpace.xs),
            Text(subtitle!, style: BBType.caption(context)),
          ],
          const SizedBox(height: BBSpace.sm),
          child,
        ],
      ),
    );
  }
}
