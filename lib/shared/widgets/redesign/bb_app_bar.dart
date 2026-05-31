import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_icon.dart';

class BbAppBarAction {
  const BbAppBarAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.badge,
    this.badgeTone = BbAppBarBadgeTone.error,
  });
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final int? badge;
  final BbAppBarBadgeTone badgeTone;
}

enum BbAppBarBadgeTone { error, tertiary }

class BbBreadcrumbSegment {
  const BbBreadcrumbSegment({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
}

/// 56px transparent app bar (handoff [BBAppBar]).
///
/// - desktop: breadcrumb
/// - mobile: title + optional hamburger
/// - actions: rounded-square icon buttons with optional badge
class BbAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BbAppBar({
    super.key,
    this.title,
    this.breadcrumb,
    this.showHamburger = false,
    this.showBack = false,
    this.onHamburger,
    this.onBack,
    this.actions = const <BbAppBarAction>[],
    this.notifCount,
    this.surfaceColor,
  });

  final String? title;
  final List<BbBreadcrumbSegment>? breadcrumb;
  final bool showHamburger;
  final bool showBack;
  final VoidCallback? onHamburger;
  final VoidCallback? onBack;
  final List<BbAppBarAction> actions;
  final int? notifCount;

  /// Override surface (e.g. `Colors.transparent` for floating-panel embed).
  final Color? surfaceColor;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final Color bg = surfaceColor ?? c.surface;

    Widget centerSlot;
    if (breadcrumb != null && breadcrumb!.isNotEmpty) {
      centerSlot = _Breadcrumb(segments: breadcrumb!, color: c);
    } else if (title != null) {
      centerSlot = Text(
        title!,
        style: BBType.h2(context),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      centerSlot = const SizedBox.shrink();
    }

    final List<BbAppBarAction> resolvedActions = notifCount != null
        ? <BbAppBarAction>[
            ...actions,
            BbAppBarAction(
              icon: 'notifications',
              label: 'Obavijesti ($notifCount)',
              badge: notifCount,
            ),
          ]
        : actions;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: <Widget>[
          if (showHamburger) ...<Widget>[
            _RoundedIconBtn(
              icon: 'menu',
              label: 'Otvori izbornik',
              onPressed: onHamburger,
            ),
            const SizedBox(width: 12),
          ],
          if (showBack) ...<Widget>[
            _RoundedIconBtn(
              icon: 'arrow_back',
              label: 'Natrag',
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: centerSlot),
          for (final BbAppBarAction a in resolvedActions) ...<Widget>[
            const SizedBox(width: 8),
            _RoundedIconBtn(
              icon: a.icon,
              label: a.label,
              onPressed: a.onPressed,
              badge: a.badge,
              badgeTone: a.badgeTone,
            ),
          ],
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments, required this.color});
  final List<BbBreadcrumbSegment> segments;
  final BBColorSet color;

  @override
  Widget build(BuildContext context) {
    final List<Widget> kids = <Widget>[];
    for (int i = 0; i < segments.length; i++) {
      final bool isLast = i == segments.length - 1;
      final BbBreadcrumbSegment seg = segments[i];
      if (i > 0) {
        kids.add(const SizedBox(width: 5));
        kids.add(
          BbIcon(name: 'chevron_right', size: 16, color: color.textTertiary),
        );
        kids.add(const SizedBox(width: 5));
      }
      kids.add(
        InkWell(
          onTap: isLast ? null : seg.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              seg.label,
              style: TextStyle(
                color: isLast ? color.textPrimary : color.textTertiary,
                fontSize: 13.5,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                height: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: kids);
  }
}

class _RoundedIconBtn extends StatelessWidget {
  const _RoundedIconBtn({
    required this.icon,
    required this.label,
    this.onPressed,
    this.badge,
    this.badgeTone = BbAppBarBadgeTone.error,
  });
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final int? badge;
  final BbAppBarBadgeTone badgeTone;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BBRadius.smAll,
              side: BorderSide(color: c.border),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BBRadius.smAll,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: BbIcon(name: icon, fill: 0, color: c.textSecondary),
                ),
              ),
            ),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeTone == BbAppBarBadgeTone.tertiary
                      ? c.tertiary
                      : c.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
