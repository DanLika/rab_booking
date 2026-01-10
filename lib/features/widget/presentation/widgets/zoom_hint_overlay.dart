import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/widget_translations.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';

class ZoomHintOverlay extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const ZoomHintOverlay({super.key, required this.onDismiss});

  @override
  ConsumerState<ZoomHintOverlay> createState() => _ZoomHintOverlayState();
}

class _ZoomHintOverlayState extends ConsumerState<ZoomHintOverlay> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            borderRadius: BorderTokens.circularMedium,
            boxShadow: ShadowTokens.strong,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.zoom_in),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tr.pinchToZoom,
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isVisible = false;
                  });
                  widget.onDismiss();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
