import 'package:flutter/material.dart';
import '../../core/theme/gradient_extensions.dart';

/// Reusable filter chip component with consistent styling across the app
///
/// Features:
/// - Selected state with primary color background and white text
/// - Unselected state with card background
/// - Hover effect
/// - Check icon when selected
/// - Smooth animations
///
/// Usage:
/// ```dart
/// AppFilterChip(
///   label: 'Filter Option',
///   selected: isSelected,
///   onSelected: () => setState(() => isSelected = !isSelected),
/// )
/// ```
class AppFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  const AppFilterChip({super.key, required this.label, required this.selected, required this.onSelected, this.icon});

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Colors based on state
    final bgColor = widget.selected
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : context.gradients.cardBackground;

    final borderColor = widget.selected
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : context.gradients.sectionBorder;

    final textColor = widget.selected ? Colors.white : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: widget.icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 16, color: textColor),
                    const SizedBox(width: 6),
                    Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                )
              : Text(widget.label, overflow: TextOverflow.ellipsis, maxLines: 1),
          selected: widget.selected,
          onSelected: (_) => widget.onSelected(),
          selectedColor: bgColor,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor, width: 1.5),
          labelStyle: TextStyle(
            color: textColor,
            fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          checkmarkColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: widget.selected ? 2 : 0,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
