import 'package:flutter/material.dart';

import '../../../../../../core/design/tokens.dart';

/// Wizard Step Container - wraps each step content with consistent styling
/// Provides title, subtitle, and scrollable content area.
///
/// Premium pass (Wave 4): title/subtitle → [BBType], spacing → [BBSpace].
class WizardStepContainer extends StatelessWidget {
  final String title; // Step title (e.g., "Basic Info")
  final String? subtitle; // Optional subtitle/description
  final Widget child; // Step content
  final EdgeInsets? padding; // Custom padding (defaults to responsive)

  const WizardStepContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive padding
    final contentPadding =
        padding ?? EdgeInsets.all(isMobile ? BBSpace.sm : BBSpace.md);

    // Max content width (centered on desktop)
    final maxWidth = isMobile ? double.infinity : 800.0;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(title, style: BBType.h2(context)),

              // Subtitle (if provided)
              if (subtitle != null) ...[
                const SizedBox(height: BBSpace.xs),
                Text(
                  subtitle!,
                  style: BBType.bodyLg(
                    context,
                  ).copyWith(color: c.textSecondary),
                ),
              ],

              const SizedBox(height: BBSpace.md),

              // Step content
              child,
            ],
          ),
        ),
      ),
    );
  }
}
