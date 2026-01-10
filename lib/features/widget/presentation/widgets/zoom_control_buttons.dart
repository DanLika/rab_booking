import 'package:flutter/material.dart';

import '../../../../core/design_tokens/design_tokens.dart';
import '../theme/minimalist_colors.dart';

/// Compact zoom control buttons (Google Maps style)
/// Small +/- icons positioned in bottom right corner
class ZoomControlButtons extends StatelessWidget {
  final double currentScale;
  final double minScale;
  final double maxScale;
  final ValueChanged<double> onScaleChanged;

  const ZoomControlButtons({
    super.key,
    required this.currentScale,
    this.minScale = 1.0,
    this.maxScale = 3.0,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In (+)
          _ZoomButton(
            icon: Icons.add,
            onPressed: currentScale < maxScale
                ? () => onScaleChanged(
                    (currentScale + 0.5).clamp(minScale, maxScale),
                  )
                : null,
            colors: colors,
          ),
          const SizedBox(height: 4),
          // Zoom Out (-)
          _ZoomButton(
            icon: Icons.remove,
            onPressed: currentScale > minScale
                ? () => onScaleChanged(
                    (currentScale - 0.5).clamp(minScale, maxScale),
                  )
                : null,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final MinimalistColorSchemeAdapter colors;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderTokens.circularSmall,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            borderRadius: BorderTokens.circularSmall,
            border: Border.all(color: colors.borderDefault, width: 1),
            boxShadow: ShadowTokens.light,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDisabled
                ? colors.textSecondary.withValues(alpha: 0.5)
                : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
