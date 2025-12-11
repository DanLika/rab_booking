import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/design_tokens/gradient_tokens.dart';

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
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.getElevation(
          1,
          isDark: theme.brightness == Brightness.dark,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: taxLegalEnabled,
              tilePadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 18,
                vertical: 8,
              ),
              childrenPadding: EdgeInsets.fromLTRB(
                isMobile ? 14 : 18,
                0,
                isMobile ? 14 : 18,
                isMobile ? 14 : 18,
              ),
              leading: _buildLeadingIcon(theme),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.taxLegalTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: GradientTokens.brandPrimary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  taxLegalEnabled
                      ? l10n.taxLegalEnabled
                      : l10n.taxLegalDisabled,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: taxLegalEnabled
                        ? AppColors.success
                        : context.textColorSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master toggle - compact
                    Row(
                      children: [
                        Icon(
                          Icons.toggle_on_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.taxLegalToggleTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                l10n.taxLegalToggleSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.textColorSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: taxLegalEnabled,
                          onChanged: onEnabledChanged,
                          activeThumbColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),

                    if (taxLegalEnabled) ...[
                      Divider(
                        height: 24,
                        color: theme.colorScheme.outline.withAlpha(
                          (0.2 * 255).toInt(),
                        ),
                      ),

                      // Disclaimer text source selector
                      _buildTextSourceSection(theme, context, l10n),

                      // Compact preview button
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onPreview,
                          icon: const Icon(Icons.preview, size: 18),
                          label: Text(l10n.taxLegalPreviewButton),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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

  Widget _buildTextSourceSection(
    ThemeData theme,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.taxLegalTextSource,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
                title: Text(
                  l10n.taxLegalDefaultTitle,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                subtitle: Text(
                  l10n.taxLegalDefaultSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                contentPadding: EdgeInsets.zero,
              ),

              // Custom text option
              RadioListTile<bool>(
                value: false,
                title: Text(
                  l10n.taxLegalCustomTitle,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                subtitle: Text(
                  l10n.taxLegalCustomSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),

        // Custom text editor (shown when custom is selected)
        if (!useDefaultText) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) => TextFormField(
              controller: customDisclaimerController,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.taxLegalCustomLabel,
                hintText: l10n.taxLegalCustomHint,
                context: ctx,
              ),
              maxLines: 10,
              maxLength: 2000,
              validator: customTextValidator,
            ),
          ),
        ],
      ],
    );
  }
}
