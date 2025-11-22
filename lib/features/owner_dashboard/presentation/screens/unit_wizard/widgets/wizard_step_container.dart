import 'package:flutter/material.dart';

/// Wizard Step Container - wraps each step content with consistent styling
/// Provides title, subtitle, and scrollable content area
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive padding
    final contentPadding = padding ??
        EdgeInsets.all(isMobile ? 16 : 24);

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
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              // Subtitle (if provided)
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Step content
              child,
            ],
          ),
        ),
      ),
    );
  }
}
