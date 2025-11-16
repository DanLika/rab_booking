import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../shared/providers/repository_providers.dart' as repos;
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart';

/// Widget Advanced Settings Screen
/// Contains Email Config and Tax/Legal Disclaimer config
class WidgetAdvancedSettingsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;

  const WidgetAdvancedSettingsScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
  });

  @override
  ConsumerState<WidgetAdvancedSettingsScreen> createState() =>
      _WidgetAdvancedSettingsScreenState();
}

class _WidgetAdvancedSettingsScreenState
    extends ConsumerState<WidgetAdvancedSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Email Config
  bool _requireEmailVerification = false;

  // Tax/Legal Config
  bool _taxLegalEnabled = true;
  bool _useDefaultText = true;
  final _customDisclaimerController = TextEditingController();

  // iCal Export Config
  bool _icalExportEnabled = false;

  bool _isSaving = false;
  bool _hasLoadedInitialData = false;

  @override
  void dispose() {
    _customDisclaimerController.dispose();
    super.dispose();
  }

  void _loadSettings(WidgetSettings settings) {
    final emailConfig = settings.emailConfig;
    final taxConfig = settings.taxLegalConfig;

    setState(() {
      // Email - Only load verification setting
      _requireEmailVerification = emailConfig.requireEmailVerification;

      // Tax/Legal
      _taxLegalEnabled = taxConfig.enabled;
      _useDefaultText = taxConfig.useDefaultText;
      _customDisclaimerController.text = taxConfig.customText ?? '';

      // iCal Export
      _icalExportEnabled = settings.icalExportEnabled;

      // Mark as loaded
      _hasLoadedInitialData = true;
    });
  }

  Future<void> _saveSettings(WidgetSettings currentSettings) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedSettings = currentSettings.copyWith(
        emailConfig: EmailNotificationConfig(
          requireEmailVerification: _requireEmailVerification, // User setting
          // All other email settings use defaults (always enabled)
        ),
        taxLegalConfig: TaxLegalConfig(
          enabled: _taxLegalEnabled,
          useDefaultText: _useDefaultText,
          customText: _customDisclaimerController.text.trim().isEmpty
              ? null
              : _customDisclaimerController.text.trim(),
        ),
        icalExportEnabled: _icalExportEnabled,
      );

      await ref
          .read(widgetSettingsRepositoryProvider)
          .updateWidgetSettings(updatedSettings);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advanced settings saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to save advanced settings',
        );
      }
    }
  }

  void _showDisclaimerPreview() {
    final text = _useDefaultText
        ? const TaxLegalConfig().disclaimerText
        : _customDisclaimerController.text.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disclaimer Preview'),
        content: SingleChildScrollView(
          child: Text(text.isEmpty ? 'No disclaimer text' : text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(
      widgetSettingsProvider((widget.propertyId, widget.unitId)),
    );
    final theme = Theme.of(context);

    return settingsAsync.when(
      data: (settings) {
        if (settings == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Advanced Settings')),
            body: const Center(child: Text('Widget settings not found')),
          );
        }

        // Load settings once (only first time)
        if (!_hasLoadedInitialData && !_isSaving) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadSettings(settings);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Advanced Settings'),
            actions: [
              if (_isSaving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveSettings(settings),
                  tooltip: 'Save',
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Email Notifications Section
                _buildEmailNotificationsSection(theme),
                const SizedBox(height: 24),

                // Tax/Legal Disclaimer Section
                _buildTaxLegalSection(theme),
                const SizedBox(height: 24),

                // iCal Export Section
                _buildIcalExportSection(theme, settings),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveSettings(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Save Advanced Settings'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Advanced Settings')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Advanced Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailNotificationsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha((0.15 * 255).toInt()),
                        AppColors.secondary.withAlpha((0.08 * 255).toInt()),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Verification',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configure guest email verification',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Verification toggle
            SwitchListTile(
              value: _requireEmailVerification,
              onChanged: (val) => setState(
                () => _requireEmailVerification = val,
              ),
              title: const Text('Require Email Verification'),
              subtitle: const Text(
                'Guest must verify their email address before completing booking',
              ),
              contentPadding: EdgeInsets.zero,
            ),
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _requireEmailVerification
                          ? 'Verification button will be shown in Step 2 of the booking flow. Guests cannot proceed without verifying their email.'
                          : 'Email verification is disabled. Guests can complete bookings without verifying their email address.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(
                          (0.7 * 255).toInt(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxLegalSection(ThemeData theme) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _taxLegalEnabled,
        leading: Container(
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
          child: const Icon(Icons.gavel, color: AppColors.warning, size: 20),
        ),
        title: const Text(
          'Tax & Legal Disclaimer',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _taxLegalEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            fontSize: 13,
            color: _taxLegalEnabled
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
                SwitchListTile(
                  value: _taxLegalEnabled,
                  onChanged: (val) => setState(() => _taxLegalEnabled = val),
                  title: const Text('Enable Tax/Legal Disclaimer'),
                  subtitle: const Text(
                    'Show disclaimer to guests during booking',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_taxLegalEnabled) ...[
                  const Divider(height: 24),
                  const Text(
                    'Disclaimer Text Source',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _useDefaultText,
                    onChanged: (val) => setState(() => _useDefaultText = true),
                    title: const Text('Use Default Croatian Text'),
                    subtitle: const Text(
                      'Standard legal text for Croatian properties',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _useDefaultText,
                    onChanged: (val) => setState(() => _useDefaultText = false),
                    title: const Text('Use Custom Text'),
                    subtitle: const Text('Provide your own legal text'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!_useDefaultText) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customDisclaimerController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Disclaimer Text',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your custom legal text...',
                      ),
                      maxLines: 10,
                      maxLength: 2000,
                      validator: (value) {
                        if (!_useDefaultText &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter custom text or use default';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showDisclaimerPreview,
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

  Widget _buildIcalExportSection(ThemeData theme, WidgetSettings settings) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _icalExportEnabled,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.info.withAlpha((0.15 * 255).toInt()),
                AppColors.info.withAlpha((0.08 * 255).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.calendar_today,
            color: AppColors.info,
            size: 20,
          ),
        ),
        title: const Text(
          'iCal Export',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _icalExportEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            fontSize: 13,
            color: _icalExportEnabled
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
                SwitchListTile(
                  value: _icalExportEnabled,
                  onChanged: (val) => setState(() => _icalExportEnabled = val),
                  title: const Text('Enable iCal Export'),
                  subtitle: const Text(
                    'Generate public iCal URL for external calendar sync',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_icalExportEnabled) ...[
                  const Divider(height: 24),
                  const Text(
                    'Export Information',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Export URL (if exists)
                  if (settings.icalExportUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(
                            (0.2 * 255).toInt(),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Export URL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settings.icalExportUrl!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(
                                (0.7 * 255).toInt(),
                              ),
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Last generated timestamp
                  if (settings.icalExportLastGenerated != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.update,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.6 * 255).toInt(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last generated: ${_formatLastGenerated(settings.icalExportLastGenerated!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.6 * 255).toInt(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Test iCal Export Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        // Load unit data from property's units subcollection
                        final units = await ref
                            .read(repos.unitRepositoryProvider)
                            .fetchUnitsByProperty(widget.propertyId);
                        final unit = units
                            .where((u) => u.id == widget.unitId)
                            .firstOrNull;

                        if (unit != null && mounted) {
                          await context.push(
                            OwnerRoutes.icalExport,
                            extra: {
                              'unit': unit,
                              'propertyId': widget.propertyId,
                            },
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ErrorDisplayUtils.showErrorSnackBar(
                            context,
                            e,
                            userMessage: 'Failed to load unit data',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.bug_report, size: 18),
                    label: const Text('Test iCal Export'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'iCal export will be auto-generated when bookings change. Use the generated URL to sync with external calendars.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withAlpha(
                                (0.7 * 255).toInt(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastGenerated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
