import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens.dart';
import '../l10n/widget_translations.dart';
import '../theme/minimalist_colors.dart';

/// Compact zoom control buttons (Google Maps style)
/// Small +/- icons positioned in bottom right corner
class ZoomControlButtons extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
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
            semanticLabel: tr.zoomIn,
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
            semanticLabel: tr.zoomOut,
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
  final String semanticLabel;
  final VoidCallback? onPressed;
  final MinimalistColorSchemeAdapter colors;

  const _ZoomButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        enabled: !isDisabled,
        label: semanticLabel,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BBRadius.xsAll,
          // The visible chip stays 32dp; the tappable box is padded out to the
          // 48dp minimum (WCAG 2.5.5), which matters on the phone where these
          // are the only way to zoom the calendar.
          child: Container(
            constraints: const BoxConstraints(
              minWidth: kMinInteractiveDimension,
              minHeight: kMinInteractiveDimension,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.backgroundPrimary,
                borderRadius: BBRadius.xsAll,
                border: Border.all(color: colors.borderDefault),
                boxShadow: BBShadow.sm,
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
        ),
      ),
    );
  }
}
