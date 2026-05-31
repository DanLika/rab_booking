import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_avatar.dart';
import 'bb_icon.dart';
import 'bb_logo.dart';

class BbSidebarUser {
  const BbSidebarUser({required this.name, this.email, this.imageUrl});
  final String name;
  final String? email;
  final String? imageUrl;
}

class BbSidebarItem {
  const BbSidebarItem({
    required this.id,
    required this.icon,
    required this.label,
    this.badge,
    this.badgeTone = BbSidebarBadgeTone.error,
    this.children,
  });
  final String id;
  final String icon;
  final String label;
  final int? badge;
  final BbSidebarBadgeTone badgeTone;
  final List<BbSidebarSubItem>? children;
  bool get expandable => children != null && children!.isNotEmpty;
}

class BbSidebarSubItem {
  const BbSidebarSubItem({required this.id, required this.label});
  final String id;
  final String label;
}

class BbSidebarGroup {
  const BbSidebarGroup({required this.label, required this.items});
  final String label;
  final List<BbSidebarItem> items;
}

enum BbSidebarBadgeTone { error, tertiary }

/// 260px desktop sidebar (handoff [BBSidebar]).
///
/// - groups labeled UPPERCASE (Glavno / Upravljanje / Pomoć)
/// - each item = icon tile in pill; brand-gradient + purple glow when active
/// - bottom user-profile row (avatar · name · email)
/// - optional `⌘K` search affordance at top
class BbSidebar extends StatelessWidget {
  const BbSidebar({
    super.key,
    required this.groups,
    required this.activeRoute,
    this.user,
    this.onNavigate,
    this.onSearchTap,
    this.onCollapse,
    this.searchHint = 'Pretraži…',
  });

  final List<BbSidebarGroup> groups;
  final String activeRoute;
  final BbSidebarUser? user;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCollapse;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Brand row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              children: <Widget>[
                const BbLogo(size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'BookBed',
                    style: BBType.h3(context).copyWith(letterSpacing: -0.24),
                  ),
                ),
                _IconChevron(
                  icon: 'chevron_left',
                  label: 'Skupi izbornik',
                  onPressed: onCollapse,
                ),
              ],
            ),
          ),
          // Search affordance
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.only(left: 13, right: 8),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: <Widget>[
                    BbIcon(
                      name: 'search',
                      size: 18,
                      color: c.textTertiary,
                      fill: 0,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        searchHint,
                        style: BBType.body(
                          context,
                        ).copyWith(color: c.textTertiary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        '⌘K',
                        style: BBType.caption(context).copyWith(
                          color: c.textTertiary,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              children: <Widget>[
                for (final BbSidebarGroup g in groups) ...<Widget>[
                  _NavGroupLabel(g.label),
                  for (final BbSidebarItem it in g.items)
                    _SidebarItem(
                      item: it,
                      activeRoute: activeRoute,
                      onNavigate: onNavigate,
                    ),
                ],
              ],
            ),
          ),
          // User profile
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: _UserRow(
                user: user!,
                active: activeRoute == 'profil',
                onTap: () => onNavigate?.call('profil'),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavGroupLabel extends StatelessWidget {
  const _NavGroupLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 7),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: c.textTertiary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0.945, // 10.5 × 0.09em
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.activeRoute,
    required this.onNavigate,
  });
  final BbSidebarItem item;
  final String activeRoute;
  final ValueChanged<String>? onNavigate;

  bool get _isActive =>
      activeRoute == item.id ||
      (item.expandable && activeRoute.startsWith(item.id));

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool active = _isActive;

    final Widget tileIcon = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: active ? BBGradient.hero : null,
        color: active ? null : c.surfaceVariant,
        borderRadius: BorderRadius.circular(9),
        boxShadow: active ? BBShadow.purpleSm : const <BoxShadow>[],
        border: active ? null : Border.all(color: c.border),
      ),
      child: Center(
        child: BbIcon(
          name: item.icon,
          size: 18,
          fill: active ? 1 : 0,
          color: active ? Colors.white : c.textTertiary,
        ),
      ),
    );

    final Widget body = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? c.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? c.border : Colors.transparent),
        boxShadow: active
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0D101828),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x2914182D),
                  offset: Offset(0, 6),
                  blurRadius: 16,
                  spreadRadius: -6,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Row(
        children: <Widget>[
          tileIcon,
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: active ? c.textPrimary : c.textSecondary,
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                height: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.badge != null && item.badge! > 0) _Badge(item: item, c: c),
          if (item.expandable) ...<Widget>[
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: active ? 0.5 : 0,
              duration: BBMotion.adapt(context, BBMotion.fast),
              child: BbIcon(
                name: 'expand_more',
                size: 18,
                color: c.textTertiary,
                fill: 0,
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onNavigate?.call(item.id),
              borderRadius: BorderRadius.circular(12),
              child: body,
            ),
          ),
          if (item.expandable && active)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 2, 0, 2),
              child: Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: c.border, width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final BbSidebarSubItem sub in item.children!)
                      _SubItem(
                        sub: sub,
                        active: activeRoute == sub.id,
                        onTap: () => onNavigate?.call(sub.id),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.item, required this.c});
  final BbSidebarItem item;
  final BBColorSet c;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.badgeTone == BbSidebarBadgeTone.tertiary
            ? c.tertiary
            : c.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${item.badge}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SubItem extends StatelessWidget {
  const _SubItem({
    required this.sub,
    required this.active,
    required this.onTap,
  });
  final BbSidebarSubItem sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active
                ? c.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? c.primary : c.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sub.label,
                  style: TextStyle(
                    color: active ? c.primary : c.textSecondary,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.active,
    required this.onTap,
  });
  final BbSidebarUser user;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? c.border : Colors.transparent),
          ),
          child: Row(
            children: <Widget>[
              BbAvatar(name: user.name, imageUrl: user.imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      user.name,
                      style: BBType.label(context).copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: BBType.caption(
                          context,
                        ).copyWith(color: c.textTertiary),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              BbIcon(
                name: 'unfold_more',
                size: 18,
                color: c.textTertiary,
                fill: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChevron extends StatelessWidget {
  const _IconChevron({required this.icon, required this.label, this.onPressed});
  final String icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: c.border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: BbIcon(
                name: icon,
                size: 18,
                color: c.textTertiary,
                fill: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
