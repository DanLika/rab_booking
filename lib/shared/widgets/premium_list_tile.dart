import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/design_tokens/border_tokens.dart';

/// Reusable premium-styled list tile with hover effects
/// Used in profile screens and settings pages
class PremiumListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final dynamic subtitle;
  final VoidCallback? onTap;
  final bool isLast;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const PremiumListTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.isLast = false,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  State<PremiumListTile> createState() => _PremiumListTileState();
}

class _PremiumListTileState extends State<PremiumListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final effectiveIconColor = widget.iconColor ?? AppColors.primary;
    final effectiveIconBgColor = widget.iconBackgroundColor ?? AppColors.primary.withValues(alpha: 0.1);

    return MouseRegion(
      onEnter: (_) => !isDisabled ? setState(() => _isHovered = true) : null,
      onExit: (_) => !isDisabled ? setState(() => _isHovered = false) : null,
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered && !isDisabled ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: widget.isLast
              ? BorderTokens.onlyBottom(12.0)
              : BorderRadius.zero,
        ),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -1),
            contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 4 : 6),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: effectiveIconBgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.icon, color: effectiveIconColor, size: isMobile ? 18 : 20),
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: widget.subtitle is String
                ? Text(
                    widget.subtitle as String,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  )
                : widget.subtitle as Widget?,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: isMobile ? 18 : 20,
            ),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
