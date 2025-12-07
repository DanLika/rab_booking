import 'package:flutter/material.dart';
import '../../../../core/theme/gradient_extensions.dart';

/// Premium glass morphism card for auth screens
class GlassCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const GlassCard({super.key, required this.child, this.maxWidth = 460, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Responsive padding based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = padding ?? EdgeInsets.all(screenWidth < 400 ? 16 : (screenWidth < 600 ? 24 : 32));

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha((0.06 * 255).toInt()),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha((0.03 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground.withAlpha((0.97 * 255).toInt()),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()), width: 1),
          ),
          padding: responsivePadding,
          child: child,
        ),
      ),
    );
  }
}
