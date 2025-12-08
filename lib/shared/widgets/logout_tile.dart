import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Specialized logout tile with error styling
/// Used in profile and settings screens
class LogoutTile extends StatefulWidget {
  final VoidCallback onLogout;
  final String title;
  final String subtitle;

  const LogoutTile({super.key, required this.onLogout, required this.title, required this.subtitle});

  @override
  State<LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<LogoutTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.error.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -1),
          contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 4 : 6),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.logout_rounded, color: AppColors.error, size: isMobile ? 18 : 20),
          ),
          title: Text(
            widget.title,
            style: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w600, color: AppColors.error),
          ),
          subtitle: Text(
            widget.subtitle,
            style: TextStyle(fontSize: isMobile ? 12 : 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.error.withValues(alpha: 0.7),
            size: isMobile ? 18 : 20,
          ),
          onTap: widget.onLogout,
        ),
      ),
    );
  }
}
