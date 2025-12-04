import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart';
import '../widgets/advanced_settings/email_verification_card.dart';
import '../widgets/advanced_settings/tax_legal_disclaimer_card.dart';
import '../widgets/advanced_settings/ical_export_card.dart';

/// Widget Advanced Settings Screen
/// Contains Email Config and Tax/Legal Disclaimer config
class WidgetAdvancedSettingsScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;
  final bool showAppBar;

  const WidgetAdvancedSettingsScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
    this.showAppBar = true,
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
  bool _isInitialized = false;

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
    });
  }

  Future<void> _saveSettings(WidgetSettings currentSettings) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedSettings = currentSettings.copyWith(
        emailConfig: currentSettings.emailConfig.copyWith(
          requireEmailVerification: _requireEmailVerification,
        ),
        taxLegalConfig: currentSettings.taxLegalConfig.copyWith(
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

      // Generate or revoke iCal export URL if iCalExportEnabled changed
      if (_icalExportEnabled != currentSettings.icalExportEnabled) {
        if (_icalExportEnabled) {
          // Generate new iCal export URL and token
          await _generateIcalExportUrl(
            currentSettings.propertyId,
            currentSettings.id, // unitId is stored as 'id' field
          );
        } else {
          // Revoke existing iCal export URL
          await _revokeIcalExportUrl(
            currentSettings.propertyId,
            currentSettings.id, // unitId is stored as 'id' field
          );
        }
      }

      if (mounted) {
        setState(() => _isSaving = false);

        // Invalidate provider so Widget Settings screen re-fetches fresh data
        ref.invalidate(widgetSettingsProvider);

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

  Future<void> _generateIcalExportUrl(String propertyId, String unitId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateIcalExportUrl');
      await callable.call({
        'propertyId': propertyId,
        'unitId': unitId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _revokeIcalExportUrl(String propertyId, String unitId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('revokeIcalExportUrl');
      await callable.call({
        'propertyId': propertyId,
        'unitId': unitId,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(
      widgetSettingsProvider((widget.propertyId, widget.unitId)),
    );

    return settingsAsync.when(
      data: (settings) {
        if (settings == null) {
          const errorContent = Center(child: Text('Widget settings not found'));
          if (!widget.showAppBar) return errorContent;

          return Scaffold(
            appBar: AppBar(title: const Text('Advanced Settings')),
            body: errorContent,
          );
        }

        // Load settings once when screen opens (prevent reload loop during user edits)
        if (!_isInitialized && !_isSaving) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadSettings(settings);
              setState(() => _isInitialized = true);
            }
          });
        }

        // Determine if mobile layout
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final padding = context.horizontalPadding;
        final gap = isMobile ? 8.0 : 16.0;

        final bodyContent = Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Email Verification Section (first section)
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, gap),
                  child: EmailVerificationCard(
                    requireEmailVerification: _requireEmailVerification,
                    onChanged: (val) => setState(
                      () => _requireEmailVerification = val,
                    ),
                    isMobile: isMobile,
                  ),
                ),

                // Tax/Legal Disclaimer Section (middle section)
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, gap, padding, gap),
                  child: TaxLegalDisclaimerCard(
                    taxLegalEnabled: _taxLegalEnabled,
                    useDefaultText: _useDefaultText,
                    customDisclaimerController: _customDisclaimerController,
                    onEnabledChanged: (val) => setState(
                      () => _taxLegalEnabled = val,
                    ),
                    onUseDefaultChanged: (val) => setState(
                      () => _useDefaultText = val,
                    ),
                    onPreview: _showDisclaimerPreview,
                    customTextValidator: (value) {
                      if (!_useDefaultText &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter custom text or use default';
                      }
                      return null;
                    },
                    isMobile: isMobile,
                  ),
                ),

                // iCal Export Section (last section)
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, gap, padding, padding),
                  child: IcalExportCard(
                    propertyId: widget.propertyId,
                    unitId: widget.unitId,
                    settings: settings,
                    icalExportEnabled: _icalExportEnabled,
                    onEnabledChanged: (val) => setState(
                      () => _icalExportEnabled = val,
                    ),
                    isMobile: isMobile,
                  ),
                ),

                // Save Button (uses brand gradient)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: GradientTokens.brandPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : () => _saveSettings(settings),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isSaving
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
                                  : const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _isSaving ? 'Saving...' : 'Save Advanced Settings',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom spacing
                const SizedBox(height: 24),
              ],
            ),
          );

        // When showAppBar is false, return only content (for embedding in tabs)
        if (!widget.showAppBar) {
          return bodyContent;
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
          body: bodyContent,
        );
      },
      loading: () {
        const loadingContent = Center(child: CircularProgressIndicator());
        if (!widget.showAppBar) return loadingContent;

        return Scaffold(
          appBar: AppBar(title: const Text('Advanced Settings')),
          body: loadingContent,
        );
      },
      error: (error, stack) {
        final errorContent = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        );

        if (!widget.showAppBar) return errorContent;

        return Scaffold(
          appBar: AppBar(title: const Text('Advanced Settings')),
          body: errorContent,
        );
      },
    );
  }
}
