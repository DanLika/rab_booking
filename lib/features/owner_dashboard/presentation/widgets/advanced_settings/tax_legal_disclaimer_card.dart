import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

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

  const TaxLegalDisclaimerCard({
    super.key,
    required this.taxLegalEnabled,
    required this.useDefaultText,
    required this.customDisclaimerController,
    required this.onEnabledChanged,
    required this.onUseDefaultChanged,
    required this.onPreview,
    this.customTextValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: taxLegalEnabled,
        leading: _buildLeadingIcon(),
        title: const Text(
          'Tax & Legal Disclaimer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          taxLegalEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            fontSize: 13,
            color: taxLegalEnabled
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master toggle
                _buildMasterToggle(),

                if (taxLegalEnabled) ...[
                  const Divider(height: 24),

                  // Disclaimer text source selector
                  _buildTextSourceSection(),

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
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withAlpha((0.15 * 255).toInt()),
            AppColors.warning.withAlpha((0.08 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.gavel,
        color: AppColors.warning,
        size: 20,
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

  Widget _buildTextSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disclaimer Text Source',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Default text option
        RadioListTile<bool>(
          value: true,
          groupValue: useDefaultText,
          onChanged: (val) => onUseDefaultChanged(true),
          title: const Text('Use Default Croatian Text'),
          subtitle: const Text(
            'Standard legal text for Croatian properties',
          ),
          contentPadding: EdgeInsets.zero,
        ),

        // Custom text option
        RadioListTile<bool>(
          value: false,
          groupValue: useDefaultText,
          onChanged: (val) => onUseDefaultChanged(false),
          title: const Text('Use Custom Text'),
          subtitle: const Text('Provide your own legal text'),
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
