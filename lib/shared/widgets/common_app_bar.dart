import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Reusable standard AppBar (non-sliver) for screens using Scaffold.
///
/// Renders as a thin pass-through over the MaterialApp `AppBarTheme`
/// (premium flat surface — see `audit/116-premium-spec.md §3.1 / §AppBar-resolution`).
/// No background gradient or color overrides — theme drives bg, elevation,
/// scrolled-under divider, title style, icon theme, and system overlay style.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final void Function(BuildContext)? onLeadingIconTap;
  final List<Widget>? actions;

  /// When false, the AppBar renders no title (leading + actions stay). Default
  /// true → all existing call sites unchanged. Premium screens that carry their
  /// title in an in-body header pass `showTitle: false` to avoid the
  /// double-header (see audit/126 §2A).
  final bool showTitle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onLeadingIconTap,
    this.actions,
    this.showTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final titlePadding = screenWidth > 600 ? 4.0 : 0.0;

    return AppBar(
      title: showTitle
          ? Padding(
              padding: EdgeInsets.only(left: titlePadding),
              child: AutoSizeText(
                title,
                maxLines: 1,
                minFontSize: 14,
                style: theme.appBarTheme.titleTextStyle,
              ),
            )
          : null,
      leading: leadingIcon != null && onLeadingIconTap != null
          ? IconButton(
              icon: Icon(leadingIcon),
              onPressed: () => onLeadingIconTap!(context),
              tooltip: 'Menu',
            )
          : null,
      automaticallyImplyLeading: false,
      actions: actions,
    );
  }
}
