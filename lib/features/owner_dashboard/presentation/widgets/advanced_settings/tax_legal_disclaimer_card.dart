import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';

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
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // topRight → bottomLeft za section
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.gradients.sectionBorder, width: 1.5),
          ),
          child: ExpansionTile(
            initiallyExpanded: taxLegalEnabled,
            leading: _buildLeadingIcon(theme),
            title: Text(l10n.taxLegalTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(
              taxLegalEnabled ? l10n.taxLegalEnabled : l10n.taxLegalDisabled,
              style: theme.textTheme.bodySmall?.copyWith(
                color: taxLegalEnabled ? AppColors.success : context.textColorSecondary,
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master toggle
                    _buildMasterToggle(l10n),

                    if (taxLegalEnabled) ...[
                      const Divider(height: 24),

                      // Disclaimer text source selector
                      _buildTextSourceSection(theme, context, l10n),

                      // Preview button
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onPreview,
                        icon: const Icon(Icons.preview),
                        label: Text(l10n.taxLegalPreviewButton),
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
        color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.gavel, color: theme.colorScheme.primary, size: 18),
    );
  }

  Widget _buildMasterToggle(AppLocalizations l10n) {
    return SwitchListTile(
      value: taxLegalEnabled,
      onChanged: onEnabledChanged,
      title: Text(l10n.taxLegalToggleTitle),
      subtitle: Text(l10n.taxLegalToggleSubtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTextSourceSection(ThemeData theme, BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.taxLegalTextSource, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        // Radio group for text source selection
        RadioGroup<bool>(
          groupValue: useDefaultText,
          onChanged: (val) => onUseDefaultChanged(val ?? true),
          child: Column(
            children: [
              // Default text option
              RadioListTile<bool>(
                value: true,
                title: Text(l10n.taxLegalDefaultTitle, style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  l10n.taxLegalDefaultSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.textColorSecondary),
                ),
                contentPadding: EdgeInsets.zero,
              ),

              // Custom text option
              RadioListTile<bool>(
                value: false,
                title: Text(l10n.taxLegalCustomTitle, style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  l10n.taxLegalCustomSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: context.textColorSecondary),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),

        // Custom text editor (shown when custom is selected)
        if (!useDefaultText) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: customDisclaimerController,
            decoration: InputDecoration(
              labelText: l10n.taxLegalCustomLabel,
              border: const OutlineInputBorder(),
              hintText: l10n.taxLegalCustomHint,
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
