import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';

/// Tax & Legal Disclaimer Settings Card
///
/// Extracted from widget_advanced_settings_screen.dart to reduce nesting.
/// Contains:
/// - Master toggle for enabling/disabling disclaimer
/// - Radio selection between default Croatian text and custom text
/// - Custom text editor (when custom is selected)
/// - Preview button to see disclaimer text
class TaxLegalDisclaimerCard extends StatelessWidget {
  final bool taxLegalEnabled;
  final bool useDefaultText;
  final TextEditingController customDisclaimerController;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onUseDefaultChanged;
  final VoidCallback onPreview;
  final String? Function(String?)? customTextValidator;
  final bool isMobile;

  const TaxLegalDisclaimerCard({
    super.key,
    required this.taxLegalEnabled,
    required this.useDefaultText,
    required this.customDisclaimerController,
    required this.onEnabledChanged,
    required this.onUseDefaultChanged,
    required this.onPreview,
    this.customTextValidator,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF1F1F1F),
                      Color(0xFF242424),
                      Color(0xFF292929),
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF0F0F0), // Lighter grey
                      Color(0xFFF2F2F2),
                      Color(0xFFF5F5F5),
                      Color(0xFFF8F8F8),
                      Color(0xFFFAFAFA), // Very light grey
                    ],
              stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: taxLegalEnabled,
            leading: _buildLeadingIcon(theme),
            title: Text(
              'Tax & Legal Disclaimer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              taxLegalEnabled ? 'Enabled' : 'Disabled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: taxLegalEnabled
                    ? AppColors.success
                    : context.textColorSecondary,
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master toggle
                    _buildMasterToggle(),

                    if (taxLegalEnabled) ...[
                      const Divider(height: 24),

                      // Disclaimer text source selector
                      _buildTextSourceSection(theme, context),

                      // Preview button
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onPreview,
                        icon: const Icon(Icons.preview),
                        label: const Text('Preview Disclaimer'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(
          (0.12 * 255).toInt(),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.gavel,
        color: theme.colorScheme.primary,
        size: 18,
      ),
    );
  }

  Widget _buildMasterToggle() {
    return SwitchListTile(
      value: taxLegalEnabled,
      onChanged: onEnabledChanged,
      title: const Text('Enable Tax/Legal Disclaimer'),
      subtitle: const Text(
        'Show disclaimer to guests during booking',
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTextSourceSection(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disclaimer Text Source',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Default text option
        RadioListTile<bool>(
          value: true,
          groupValue: useDefaultText,
          onChanged: (val) => onUseDefaultChanged(true),
          title: Text(
            'Use Default Croatian Text',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            'Standard legal text for Croatian properties',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.textColorSecondary,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),

        // Custom text option
        RadioListTile<bool>(
          value: false,
          groupValue: useDefaultText,
          onChanged: (val) => onUseDefaultChanged(false),
          title: Text(
            'Use Custom Text',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            'Provide your own legal text',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.textColorSecondary,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),

        // Custom text editor (shown when custom is selected)
        if (!useDefaultText) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: customDisclaimerController,
            decoration: const InputDecoration(
              labelText: 'Custom Disclaimer Text',
              border: OutlineInputBorder(),
              hintText: 'Enter your custom legal text...',
            ),
            maxLines: 10,
            maxLength: 2000,
            validator: customTextValidator,
          ),
        ],
      ],
    );
  }
}
