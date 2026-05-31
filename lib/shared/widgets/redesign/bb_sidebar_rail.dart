import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_icon.dart';
import 'bb_logo.dart';
import 'bb_sidebar.dart';

class BbSidebarRailItem {
  const BbSidebarRailItem({
    required this.id,
    required this.icon,
    required this.label,
    this.group,
    this.badge,
    this.badgeTone = BbSidebarBadgeTone.error,
  });
  final String id;
  final String icon;
  final String label;
  final String? group;
  final int? badge;
  final BbSidebarBadgeTone badgeTone;
}

/// 72px collapsed nav rail (handoff [BBSidebarRail]). Tablet variant.
class BbSidebarRail extends StatelessWidget {
  const BbSidebarRail({
    super.key,
    required this.items,
    required this.activeRoute,
    this.onNavigate,
    this.onLogout,
  });

  final List<BbSidebarRailItem> items;
  final String activeRoute;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onLogout;

  bool _isActive(BbSidebarRailItem it) =>
      activeRoute == it.id ||
      (it.group != null && activeRoute.startsWith(it.group!));

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        children: <Widget>[
          const BbLogo(size: 36),
          const SizedBox(height: 6),
          Container(width: 32, height: 1, color: c.border),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (BuildContext _, int i) {
                final BbSidebarRailItem it = items[i];
                final bool active = _isActive(it);
                return Center(
                  child: _RailButton(
                    item: it,
                    active: active,
                    onTap: () => onNavigate?.call(it.id),
                  ),
                );
              },
            ),
          ),
          if (onLogout != null)
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLogout,
                  borderRadius: BBRadius.smAll,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: BbIcon(name: 'logout', color: c.error, fill: 0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.item,
    required this.active,
    required this.onTap,
  });
  final BbSidebarRailItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BBRadius.smAll,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active
                      ? c.primary.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BBRadius.smAll,
                ),
                child: Center(
                  child: BbIcon(
                    name: item.icon,
                    size: 22,
                    fill: active ? 1 : 0,
                    color: active ? c.primary : c.textSecondary,
                  ),
                ),
              ),
              if (item.badge != null && item.badge! > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.badgeTone == BbSidebarBadgeTone.tertiary
                          ? c.tertiary
                          : c.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.surface, width: 2),
                    ),
                    child: Text(
                      '${item.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
