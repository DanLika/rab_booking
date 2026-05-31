import 'package:flutter/material.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import 'bb_app_bar.dart';
import 'bb_sidebar.dart';
import 'bb_sidebar_rail.dart';

/// Premium console scaffold (handoff `.bb-shell`).
///
/// Dissolved sidebar + floating content panel + 56px breadcrumb app bar.
/// Responsive:
/// - desktop (≥1024): [BbSidebar] (260) + floating panel (`panel-bg`, radius 20,
///   `panel-shadow`)
/// - tablet (600–1023): [BbSidebarRail] (72) + floating panel
/// - mobile (<600): `Drawer` (slide-in), app-bar hamburger; panel goes
///   edge-to-edge with no rounded corners
///
/// API mirrors a standard Material [Scaffold] where reasonable; consumers
/// pass the body widget plus navigation metadata.
class BbScaffold extends StatefulWidget {
  const BbScaffold({
    super.key,
    required this.body,
    required this.activeRoute,
    required this.sidebarGroups,
    this.sidebarRailItems,
    this.title,
    this.breadcrumb,
    this.appBarActions = const <BbAppBarAction>[],
    this.notifCount,
    this.user,
    this.onNavigate,
    this.onLogout,
    this.onSearchTap,
    this.floatingActionButton,
    this.overrideShellBg,
    this.panelPadding = const EdgeInsets.all(BBSpace.md),
    this.mobileBreakpoint = 600,
    this.desktopBreakpoint = 1024,
    this.collapseSidebar = false,
  });

  /// Main content (will be wrapped in the floating panel on tablet/desktop).
  final Widget body;

  /// Active route id (drives sidebar highlight). Use the same id you pass
  /// to [BbSidebarItem.id] / [BbSidebarSubItem.id].
  final String activeRoute;

  final List<BbSidebarGroup> sidebarGroups;

  /// Tablet rail items. Falls back to flattening [sidebarGroups] if null.
  final List<BbSidebarRailItem>? sidebarRailItems;

  final String? title;
  final List<BbBreadcrumbSegment>? breadcrumb;
  final List<BbAppBarAction> appBarActions;
  final int? notifCount;
  final BbSidebarUser? user;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onLogout;
  final VoidCallback? onSearchTap;
  final Widget? floatingActionButton;

  /// Override outer shell bg (e.g. widget surface uses mint shell).
  final Color? overrideShellBg;

  final EdgeInsetsGeometry panelPadding;

  final double mobileBreakpoint;
  final double desktopBreakpoint;

  /// If true, desktop renders the rail instead of full sidebar.
  final bool collapseSidebar;

  @override
  State<BbScaffold> createState() => _BbScaffoldState();
}

class _BbScaffoldState extends State<BbScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<BbSidebarRailItem> _railItemsFromGroups() {
    if (widget.sidebarRailItems != null) return widget.sidebarRailItems!;
    return <BbSidebarRailItem>[
      for (final BbSidebarGroup g in widget.sidebarGroups)
        for (final BbSidebarItem it in g.items)
          BbSidebarRailItem(
            id: it.id,
            icon: it.icon,
            label: it.label,
            badge: it.badge,
            badgeTone: it.badgeTone,
          ),
    ];
  }

  Widget _panel({required Widget child, required bool rounded}) {
    final BbRedesignTokens rd = BbRedesignTokens.of(context);
    final BoxDecoration deco = BoxDecoration(
      color: rd.panelBg,
      borderRadius: rounded ? BBRadius.mdAll : BorderRadius.zero,
      border: rounded ? Border.all(color: rd.panelBorder) : null,
      boxShadow: rounded ? BbRedesignTokens.of(context).panelShadow : null,
    );
    return Container(
      margin: rounded
          ? const EdgeInsets.fromLTRB(0, BBSpace.sm, BBSpace.sm, BBSpace.sm)
          : EdgeInsets.zero,
      decoration: deco,
      child: ClipRRect(
        borderRadius: rounded ? BBRadius.mdAll : BorderRadius.zero,
        child: Padding(padding: widget.panelPadding, child: widget.body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BbRedesignTokens rd = BbRedesignTokens.of(context);
    final Color shellBg = widget.overrideShellBg ?? rd.shellBg;

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints cs) {
        final double w = cs.maxWidth;
        final bool isMobile = w < widget.mobileBreakpoint;
        final bool isTablet = !isMobile && w < widget.desktopBreakpoint;
        final bool isDesktop = !isMobile && !isTablet;

        // --- Mobile: Drawer + full-bleed body
        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: shellBg,
            drawer: Drawer(
              backgroundColor: BBColor.of(context).surface,
              width: 280,
              child: BbSidebar(
                groups: widget.sidebarGroups,
                activeRoute: widget.activeRoute,
                user: widget.user,
                onNavigate: (String id) {
                  Navigator.of(context).maybePop();
                  widget.onNavigate?.call(id);
                },
                onSearchTap: widget.onSearchTap,
              ),
            ),
            appBar: BbAppBar(
              title: widget.title,
              showHamburger: true,
              onHamburger: () => _scaffoldKey.currentState?.openDrawer(),
              actions: widget.appBarActions,
              notifCount: widget.notifCount,
              surfaceColor: shellBg,
            ),
            body: _panel(child: widget.body, rounded: false),
            floatingActionButton: widget.floatingActionButton,
          );
        }

        // --- Tablet / Desktop: sidebar + floating panel
        final Widget sidebarPanel = (isDesktop && !widget.collapseSidebar)
            ? BbSidebar(
                groups: widget.sidebarGroups,
                activeRoute: widget.activeRoute,
                user: widget.user,
                onNavigate: widget.onNavigate,
                onSearchTap: widget.onSearchTap,
              )
            : BbSidebarRail(
                items: _railItemsFromGroups(),
                activeRoute: widget.activeRoute,
                onNavigate: widget.onNavigate,
                onLogout: widget.onLogout,
              );

        return Container(
          color: shellBg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              sidebarPanel,
              Expanded(
                child: Column(
                  children: <Widget>[
                    BbAppBar(
                      title: widget.title,
                      breadcrumb: widget.breadcrumb,
                      actions: widget.appBarActions,
                      notifCount: widget.notifCount,
                      surfaceColor: Colors.transparent,
                    ),
                    Expanded(child: _panel(child: widget.body, rounded: true)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
