import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/advanced_settings/email_verification_card.dart';
import '../widgets/advanced_settings/tax_legal_disclaimer_card.dart';

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
    extends ConsumerState<WidgetAdvancedSettingsScreen>
    with AndroidKeyboardDismissFixApproach1<WidgetAdvancedSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Email Config
  bool _requireEmailVerification = false;

  // Tax/Legal Config
  bool _taxLegalEnabled = true;
  bool _useDefaultText = true;
  final _customDisclaimerController = TextEditingController();

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
    });
  }

  Future<void> _saveSettings(WidgetSettings currentSettings) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10n.widgetPleaseCheckFormErrors,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get current user ID for owner_id migration (legacy docs may not have it)
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final customTextValue = _customDisclaimerController.text.trim().isEmpty
          ? null
          : _customDisclaimerController.text.trim();

      final repository = ref.read(widgetSettingsRepositoryProvider);

      // Check if email verification setting changed
      final emailVerificationChanged =
          currentSettings.emailConfig.requireEmailVerification !=
          _requireEmailVerification;

      // Email verification is a PROPERTY-WIDE setting - update all units
      if (emailVerificationChanged) {
        await repository.updateEmailVerificationForAllUnits(
          propertyId: widget.propertyId,
          requireEmailVerification: _requireEmailVerification,
        );
      }

      // Update current unit's settings (for tax/legal config which is per-unit)
      final updatedSettings = currentSettings.copyWith(
        // Ensure owner_id is set for legacy document migration
        ownerId: currentSettings.ownerId ?? currentUserId,
        emailConfig: currentSettings.emailConfig.copyWith(
          requireEmailVerification: _requireEmailVerification,
        ),
        taxLegalConfig: currentSettings.taxLegalConfig.copyWith(
          enabled: _taxLegalEnabled,
          useDefaultText: _useDefaultText,
          customText: customTextValue,
        ),
      );

      await repository.updateWidgetSettings(updatedSettings);

      if (mounted) {
        setState(() => _isSaving = false);

        // Invalidate provider so Widget Settings screen re-fetches fresh data
        ref.invalidate(widgetSettingsProvider);
        // Also invalidate all property settings provider in case it's used elsewhere
        ref.invalidate(allPropertyWidgetSettingsProvider);

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.advancedSettingsSaveSuccess,
        );

        // Only pop if opened as standalone screen (with app bar)
        // When embedded in tab (showAppBar = false), don't navigate
        if (widget.showAppBar) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.advancedSettingsSaveError,
        );
      }
    }
  }

  void _showDisclaimerPreview() {
    final l10n = AppLocalizations.of(context);
    final text = _useDefaultText
        ? const TaxLegalConfig().disclaimerText
        : _customDisclaimerController.text.trim();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
        child: Container(
          width: isMobile ? screenWidth * 0.90 : 600,
          constraints: BoxConstraints(
            maxHeight:
                screenHeight *
                ResponsiveSpacingHelper.getDialogMaxHeightPercent(
                  dialogContext,
                ),
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with darker gradient
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6B46C1), const Color(0xFF553C9A)]
                        : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.preview,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.advancedSettingsDisclaimerPreview,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: l10n.close,
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Text(
                    text.isEmpty ? l10n.advancedSettingsNoDisclaimer : text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.close),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(
      widgetSettingsProvider((widget.propertyId, widget.unitId)),
    );
    final l10n = AppLocalizations.of(context);

    return settingsAsync.when(
      data: (settings) {
        if (settings == null) {
          final errorContent = Center(
            child: Text(l10n.advancedSettingsNotFound),
          );
          if (!widget.showAppBar) return errorContent;

          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(title: Text(l10n.advancedSettingsTitle)),
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.zero,
            children: [
              // Email Verification Section (first section)
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, gap),
                child: EmailVerificationCard(
                  requireEmailVerification: _requireEmailVerification,
                  onChanged: (val) =>
                      setState(() => _requireEmailVerification = val),
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
                  onEnabledChanged: (val) =>
                      setState(() => _taxLegalEnabled = val),
                  onUseDefaultChanged: (val) =>
                      setState(() => _useDefaultText = val),
                  onPreview: _showDisclaimerPreview,
                  customTextValidator: (value) {
                    if (!_useDefaultText &&
                        (value == null || value.trim().isEmpty)) {
                      return l10n.advancedSettingsCustomTextRequired;
                    }
                    return null;
                  },
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 15,
                        ),
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
                              _isSaving
                                  ? l10n.advancedSettingsSaving
                                  : l10n.advancedSettingsSave,
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

        return PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/owner/properties');
              }
            }
          },
          child: KeyedSubtree(
            key: ValueKey(
              'widget_advanced_settings_screen_$keyboardFixRebuildKey',
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                title: Text(l10n.advancedSettingsTitle),
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
                      tooltip: l10n.save,
                    ),
                ],
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Note: ListView handles keyboard spacing automatically when resizeToAvoidBottomInset is true
                    return bodyContent;
                  },
                ),
              ),
            ),
          ),
        );
      },
      loading: () {
        const loadingContent = Center(child: CircularProgressIndicator());
        if (!widget.showAppBar) return loadingContent;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(title: Text(l10n.advancedSettingsTitle)),
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
              Text('${l10n.error}: $error'),
            ],
          ),
        );

        if (!widget.showAppBar) return errorContent;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(title: Text(l10n.advancedSettingsTitle)),
          body: errorContent,
        );
      },
    );
  }
}
