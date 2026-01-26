import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/domain/models/widget_mode.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart'
    as widget_provider;
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/user_profile_provider.dart';
import '../../../../shared/widgets/universal_loader.dart';

/// Widget Settings Screen - Configure embedded widget for each unit
class WidgetSettingsScreen extends ConsumerStatefulWidget {
  const WidgetSettingsScreen({
    required this.propertyId,
    required this.unitId,
    this.showAppBar = true,
    super.key,
  });

  final String propertyId;
  final String unitId;
  final bool showAppBar;

  @override
  ConsumerState<WidgetSettingsScreen> createState() =>
      _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends ConsumerState<WidgetSettingsScreen>
    with AndroidKeyboardDismissFixApproach1<WidgetSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Widget Mode
  WidgetMode _selectedMode = WidgetMode.calendarOnly;

  // Payment Methods
  int _globalDepositPercentage = 20; // Global deposit % for all payment methods

  bool _stripeEnabled = false;

  bool _bankTransferEnabled = false;
  // Bank details now read from CompanyDetails (profile), not stored per-unit
  int _bankPaymentDeadlineDays = 3;
  bool _bankEnableQrCode = true;
  final _bankCustomNotesController = TextEditingController();
  bool _bankUseCustomNotes = false;

  // Note: _payOnArrivalEnabled removed - logic simplified:
  // bookingPending = no payment (inherently pay on arrival)
  // bookingInstant = payment required (Stripe or Bank Transfer)

  // Booking Behavior
  bool _requireApproval = true;
  bool _allowCancellation = true;
  int _cancellationHours = 48;
  int _minDaysAdvance = 0;
  int _maxDaysAdvance = 365;

  // External Calendar Sync Options
  bool _externalCalendarEnabled = false;
  bool _syncBookingCom = false;
  final _bookingComAccountIdController = TextEditingController();
  final _bookingComAccessTokenController = TextEditingController();
  bool _syncAirbnb = false;
  final _airbnbAccountIdController = TextEditingController();
  final _airbnbAccessTokenController = TextEditingController();
  int _syncIntervalMinutes = 60;

  bool _isLoading = true;
  bool _isSaving = false;
  WidgetSettings? _existingSettings;
  CompanyDetails? _companyDetails;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(widgetSettingsRepositoryProvider);
      final settings = await repository.getWidgetSettings(
        propertyId: widget.propertyId,
        unitId: widget.unitId,
      );

      if (settings != null) {
        _existingSettings = settings;
        _applySettingsToForm(settings);
      }

      // OPTIMIZED: Company details loaded via companyDetailsProvider stream in build()
      // No manual fetch needed here - reduces 1 Firestore query
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.widgetSettingsLoadError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySettingsToForm(WidgetSettings settings) {
    setState(() {
      // Widget Mode
      _selectedMode = settings.widgetMode;

      // Global deposit percentage
      _globalDepositPercentage = settings.globalDepositPercentage;

      // Payment Methods - Stripe
      _stripeEnabled = settings.stripeConfig?.enabled ?? false;

      // Payment Methods - Bank Transfer (bank details now from profile)
      _bankTransferEnabled = settings.bankTransferConfig?.enabled ?? false;
      _bankPaymentDeadlineDays =
          settings.bankTransferConfig?.paymentDeadlineDays ?? 3;
      _bankEnableQrCode = settings.bankTransferConfig?.enableQrCode ?? true;
      _bankCustomNotesController.text =
          settings.bankTransferConfig?.customNotes ?? '';
      _bankUseCustomNotes =
          settings.bankTransferConfig?.useCustomNotes ?? false;

      // Note: allowPayOnArrival field no longer loaded - simplified logic

      // Booking Behavior
      _requireApproval = settings.requireOwnerApproval;
      _allowCancellation = settings.allowGuestCancellation;
      _cancellationHours = settings.cancellationDeadlineHours ?? 48;
      _minDaysAdvance = settings.minDaysAdvance;
      _maxDaysAdvance = settings.maxDaysAdvance;

      // External Calendar Sync Options
      _externalCalendarEnabled =
          settings.externalCalendarConfig?.enabled ?? false;
      _syncBookingCom =
          settings.externalCalendarConfig?.syncBookingCom ?? false;
      _bookingComAccountIdController.text =
          settings.externalCalendarConfig?.bookingComAccountId ?? '';
      _bookingComAccessTokenController.text =
          settings.externalCalendarConfig?.bookingComAccessToken ?? '';
      _syncAirbnb = settings.externalCalendarConfig?.syncAirbnb ?? false;
      _airbnbAccountIdController.text =
          settings.externalCalendarConfig?.airbnbAccountId ?? '';
      _airbnbAccessTokenController.text =
          settings.externalCalendarConfig?.airbnbAccessToken ?? '';
      _syncIntervalMinutes =
          settings.externalCalendarConfig?.syncIntervalMinutes ?? 60;
    });
  }

  /// Handle bank transfer toggle with lazy validation
  Future<void> _handleBankTransferToggle(bool val) async {
    final l10n = AppLocalizations.of(context);
    if (val) {
      // Check if bank details exist in profile
      if (_companyDetails == null || !_companyDetails!.hasBankDetails) {
        // Show dialog to go to profile
        final goToProfile = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              title: Text(
                l10n.widgetSettingsBankNotEntered,
                textAlign: TextAlign.center,
              ),
              content: Text(
                l10n.widgetSettingsBankNotEnteredDesc,
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cancel button - outlined style
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(height: 8),
                    // Add bank details button - filled style
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          l10n.widgetSettingsAddBankDetails,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );

        if (goToProfile == true && mounted) {
          // Navigate to edit profile
          await context.push(OwnerRoutes.bankAccount);
          // OPTIMIZED: Invalidate provider to trigger stream refresh
          // The build() watch will auto-update _companyDetails
          ref.invalidate(companyDetailsProvider);
          // Wait a frame for provider to update state
          await Future.delayed(const Duration(milliseconds: 100));
          // If now has bank details, enable bank transfer
          if (_companyDetails?.hasBankDetails == true) {
            setState(() => _bankTransferEnabled = true);
          }
        }
        return; // Don't enable if no bank details
      }
    }

    setState(() => _bankTransferEnabled = val);
  }

  /// Build read-only display of bank details from profile
  Widget _buildBankDetailsFromProfile() {
    final theme = Theme.of(context);
    final company = _companyDetails;

    if (company == null || !company.hasBankDetails) {
      // Show warning card
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.widgetSettingsBankNotEntered,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.widgetSettingsBankEnterDetails,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextButton(
                  onPressed: () async {
                    await context.push(OwnerRoutes.bankAccount);
                    // OPTIMIZED: Invalidate provider to trigger stream refresh
                    // The build() watch will auto-update _companyDetails
                    ref.invalidate(companyDetailsProvider);
                  },
                  child: Text(l10n.edit),
                );
              },
            ),
          ],
        ),
      );
    }

    // Show bank details from profile
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.sectionDividerDark.withValues(alpha: 0.5)
            : AppColors.sectionDividerLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.sectionDividerDark
              : AppColors.sectionDividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n.widgetSettingsBankFromProfile,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bank details
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                children: [
                  _buildBankDetailRow(
                    l10n.widgetSettingsBank,
                    company.bankName,
                  ),
                  _buildBankDetailRow('IBAN', company.bankAccountIban),
                  _buildBankDetailRow('SWIFT/BIC', company.swift),
                  _buildBankDetailRow(
                    l10n.widgetSettingsAccountHolder,
                    company.accountHolder,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Edit button - full width below details
          SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return OutlinedButton.icon(
                  onPressed: () async {
                    await context.push(OwnerRoutes.bankAccount);
                    // OPTIMIZED: Invalidate provider to trigger stream refresh
                    // The build() watch will auto-update _companyDetails
                    ref.invalidate(companyDetailsProvider);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(l10n.edit),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10n.widgetPleaseCheckFormErrors,
      );
      return;
    }

    // Validation: At least one ACTUAL payment method must be enabled in bookingInstant mode
    // Note: Pay on Arrival is NOT a payment method for bookingInstant - it collects no upfront payment
    // If owner wants pay on arrival, they should use bookingPending mode instead
    if (_selectedMode == WidgetMode.bookingInstant) {
      final hasPaymentMethod = _stripeEnabled || _bankTransferEnabled;
      if (!hasPaymentMethod) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            Exception('Validation failed'),
            userMessage: l10n.widgetSettingsPaymentValidation,
          );
        }
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(widgetSettingsRepositoryProvider);

      // Get current user ID for owner_id (required for Firestore security rules)
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final settings = WidgetSettings(
        id: widget.unitId,
        propertyId: widget.propertyId,
        // Ensure owner_id is set for legacy document migration
        ownerId: _existingSettings?.ownerId ?? currentUserId,
        widgetMode: _selectedMode,
        globalDepositPercentage: _globalDepositPercentage,
        stripeConfig: _stripeEnabled
            ? StripePaymentConfig(
                enabled: true,
                depositPercentage:
                    _globalDepositPercentage, // Use global deposit
              )
            : null,
        bankTransferConfig: _bankTransferEnabled
            ? BankTransferConfig(
                enabled: true,
                depositPercentage:
                    _globalDepositPercentage, // Use global deposit
                // Owner ID for fetching bank details from CompanyDetails
                ownerId: FirebaseAuth.instance.currentUser?.uid,
                // Bank details copied from CompanyDetails for backward compatibility
                // New widgets use ownerId to fetch fresh data from owner's profile
                bankName: _companyDetails?.bankName,
                iban: _companyDetails?.bankAccountIban,
                swift: _companyDetails?.swift,
                accountHolder: _companyDetails?.accountHolder,
                paymentDeadlineDays: _bankPaymentDeadlineDays,
                enableQrCode: _bankEnableQrCode,
                customNotes: _bankCustomNotesController.text.isEmpty
                    ? null
                    : _bankCustomNotesController.text,
                useCustomNotes: _bankUseCustomNotes,
              )
            : null,
        // Pay on Arrival toggle removed - logic simplified:
        // - bookingPending: No payment required (server allows paymentMethod='none')
        // - bookingInstant: Payment required (Stripe or Bank Transfer only)
        // Field kept for backward compatibility but always set to false
        allowPayOnArrival: false,
        // For bookingPending mode, approval is ALWAYS required (hardcoded true)
        // For bookingInstant mode, use the user's selection
        requireOwnerApproval: _selectedMode == WidgetMode.bookingPending
            ? true
            : _requireApproval,
        allowGuestCancellation: _allowCancellation,
        cancellationDeadlineHours: _cancellationHours,
        // Advance booking restrictions
        minDaysAdvance: _minDaysAdvance,
        maxDaysAdvance: _maxDaysAdvance,
        // Use minNights from unit settings (not widget settings)
        // This is configured in "Edit Unit" form, not here
        minNights: _existingSettings?.minNights ?? 1,
        // Contact options no longer displayed in widget - use default empty
        contactOptions: const ContactOptions(),
        emailConfig:
            _existingSettings?.emailConfig ?? const EmailNotificationConfig(),
        externalCalendarConfig: _externalCalendarEnabled
            ? ExternalCalendarConfig(
                enabled: true,
                syncBookingCom: _syncBookingCom,
                bookingComAccountId: _bookingComAccountIdController.text.isEmpty
                    ? null
                    : _bookingComAccountIdController.text,
                bookingComAccessToken:
                    _bookingComAccessTokenController.text.isEmpty
                    ? null
                    : _bookingComAccessTokenController.text,
                syncAirbnb: _syncAirbnb,
                airbnbAccountId: _airbnbAccountIdController.text.isEmpty
                    ? null
                    : _airbnbAccountIdController.text,
                airbnbAccessToken: _airbnbAccessTokenController.text.isEmpty
                    ? null
                    : _airbnbAccessTokenController.text,
                syncIntervalMinutes: _syncIntervalMinutes,
              )
            : null,
        taxLegalConfig:
            _existingSettings?.taxLegalConfig ??
            const TaxLegalConfig(enabled: false),
        themeOptions: _existingSettings?.themeOptions,
        createdAt: _existingSettings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.updateWidgetSettings(settings);

      // Invalidate provider cache to force refresh
      ref.invalidate(widget_provider.widgetSettingsStreamProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.widgetSettingsSaveSuccess,
        );
        // Only navigate back when used as standalone screen (with AppBar)
        // When embedded in tabs (showAppBar: false), stay on current tab
        if (widget.showAppBar) {
          // Navigate after frame completes to avoid Navigator lock assertion
          // caused by provider invalidation triggering rebuilds
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.widgetSettingsSaveError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _bookingComAccountIdController.dispose();
    _bookingComAccessTokenController.dispose();
    _airbnbAccountIdController.dispose();
    _airbnbAccessTokenController.dispose();
    _bankCustomNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZED: Sync company details from stream provider (reduces manual Firestore queries)
    // This replaces manual getCompanyDetails() calls and auto-updates on profile changes
    final companyDetailsAsync = ref.watch(companyDetailsProvider);
    companyDetailsAsync.whenData((data) {
      if (data != _companyDetails) {
        // Schedule state update for next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _companyDetails = data);
          }
        });
      }
    });

    final contentPadding = context.horizontalPadding;
    final l10n = AppLocalizations.of(context);

    final bodyContent = _isLoading
        ? UniversalLoader.forSection()
        : Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(contentPadding),
              children: [
                _buildWidgetModeSection(),

                const SizedBox(height: 24),

                // Payment Methods - ONLY for bookingInstant mode
                if (_selectedMode == WidgetMode.bookingInstant) ...[
                  _buildPaymentMethodsSection(),
                  const SizedBox(height: 24),

                  _buildBookingBehaviorSection(),
                  const SizedBox(height: 24),
                ],

                // Info card - ONLY for bookingPending mode
                if (_selectedMode == WidgetMode.bookingPending) ...[
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: l10n.widgetSettingsBookingWithoutPayment,
                    message: l10n.widgetSettingsBookingWithoutPaymentDesc,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  _buildBookingBehaviorSection(),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 32),

                // Gradient save button (uses brand gradient)
                Container(
                  decoration: BoxDecoration(
                    gradient: GradientTokens.brandPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _saveSettings,
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
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
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
                                  ? l10n.widgetSettingsSaving
                                  : l10n.widgetSettingsSave,
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
          // Handle browser back button on Chrome Android
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/properties');
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('widget_settings_screen_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CommonAppBar(
            title: l10n.widgetSettingsTitle,
            leadingIcon: Icons.arrow_back,
            onLeadingIconTap: (context) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/owner/properties');
              }
            },
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
  }

  Widget _buildWidgetModeSection() {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            // TIP 1: Simple diagonal gradient (2 colors, 2 stops)
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon - Minimalist style (matching euro icon from Cjenovnik)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.widgets_outlined,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.widgetSettingsWidgetMode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.widgetSettingsWidgetModeDesc,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              ...WidgetMode.values.map(
                (mode) => InkWell(
                  onTap: () {
                    setState(() => _selectedMode = mode);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Custom radio indicator to avoid deprecated API
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedMode == mode
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: _selectedMode == mode
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mode.displayName),
                              Text(
                                mode.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.widgetSettingsPaymentMethods,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info text
              Text(
                l10n.widgetSettingsPaymentMethodsDesc,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              // Global Deposit Percentage Slider (applies to all payment methods)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.percent,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.widgetSettingsDepositAmount(
                            _globalDepositPercentage,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.widgetSettingsDepositDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        overlayColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        valueIndicatorColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Slider(
                        value: _globalDepositPercentage.toDouble(),
                        max: 100,
                        divisions: 20,
                        label: '$_globalDepositPercentage%',
                        onChanged: (value) {
                          setState(
                            () => _globalDepositPercentage = value.round(),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0% (${l10n.widgetSettingsFullPayment})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          '100% (${l10n.widgetSettingsFullPayment})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stripe Payment - Collapsible with approval option
              _buildPaymentMethodExpansionTile(
                icon: Icons.credit_card,
                title: l10n.widgetSettingsStripePayment,
                subtitle: l10n.widgetSettingsCardPayment,
                enabled: _stripeEnabled,
                onToggle: (val) => setState(() => _stripeEnabled = val),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Require Approval switch - Only applies to Stripe
                    // Bank transfer and Pay on Arrival always require approval
                    Builder(
                      builder: (context) {
                        final l10nInner = AppLocalizations.of(context);
                        return _buildCompactSwitchCard(
                          icon: Icons.approval,
                          label: l10nInner.widgetSettingsRequireApproval,
                          subtitle: l10nInner.widgetSettingsStripeApprovalNote,
                          value: _requireApproval,
                          onChanged: (val) =>
                              setState(() => _requireApproval = val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Bank Transfer - Collapsible with lazy validation
              _buildPaymentMethodExpansionTile(
                icon: Icons.account_balance,
                title: l10n.widgetSettingsBankTransfer,
                subtitle: l10n.widgetSettingsBankPayment,
                enabled: _bankTransferEnabled,
                onToggle: _handleBankTransferToggle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Bank details from profile (read-only display)
                    _buildBankDetailsFromProfile(),

                    const SizedBox(height: 12),

                    // Payment deadline dropdown
                    Builder(
                      builder: (ctx) => DropdownButtonFormField<int>(
                        initialValue: _bankPaymentDeadlineDays,
                        dropdownColor: InputDecorationHelper.getDropdownColor(
                          ctx,
                        ),
                        decoration: InputDecorationHelper.buildDecoration(
                          labelText: l10n.widgetSettingsPaymentDeadline,
                          context: ctx,
                        ),
                        menuMaxHeight: 300,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              '1 ${l10n.widgetSettingsDay}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text(
                              '3 ${l10n.widgetSettingsDays}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(
                              '5 ${l10n.widgetSettingsDays}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text(
                              '7 ${l10n.widgetSettingsDays}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 14,
                            child: Text(
                              '14 ${l10n.widgetSettingsDays}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _bankPaymentDeadlineDays = value);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Custom notes switch
                    Builder(
                      builder: (context) {
                        final l10nInner = AppLocalizations.of(context);
                        return _buildCompactSwitchCard(
                          icon: Icons.edit_note,
                          label: l10nInner.widgetSettingsCustomNote,
                          subtitle: l10nInner.widgetSettingsAddMessage,
                          value: _bankUseCustomNotes,
                          onChanged: (val) =>
                              setState(() => _bankUseCustomNotes = val),
                        );
                      },
                    ),

                    // Custom notes text field (conditional)
                    if (_bankUseCustomNotes) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (ctx) => TextFormField(
                          controller: _bankCustomNotesController,
                          decoration: InputDecorationHelper.buildDecoration(
                            labelText: l10n.widgetSettingsNoteMaxChars,
                            helperText: l10n.widgetSettingsNoteHelper,
                            context: ctx,
                          ),
                          maxLines: 3,
                          maxLength: 500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Pay on Arrival toggle REMOVED - simplified logic:
              // - bookingPending mode: No payment, manual approval (inherently "pay on arrival")
              // - bookingInstant mode: Payment required (Stripe or Bank Transfer)
              // See: atomicBooking.ts validation for server-side enforcement
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Payment method expansion tile
  Widget _buildPaymentMethodExpansionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: enabled ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor: Theme.of(context).colorScheme.primary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: Icon(
            icon,
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),

          controlAffinity: ListTileControlAffinity.trailing,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Add switch as part of title row instead
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                inactiveThumbColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ],
          ),

          children: enabled ? [child] : [],
        ),
      ),
    );
  }

  // Helper: Compact switch card (for small options)
  Widget _buildCompactSwitchCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value && !isWarning
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : isWarning
            ? const Color(0xFFF3E8F5) // Cool lavender warning background
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value && !isWarning
              ? Theme.of(context).colorScheme.primary
              : isWarning
              ? const Color(0xFF9C7BA8) // Cool purple warning border
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: value || isWarning ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value && !isWarning
                ? Theme.of(context).colorScheme.primary
                : isWarning
                ? const Color(0xFF7B5A8C) // Cool purple warning icon
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                    color: value && !isWarning
                        ? Theme.of(context).colorScheme.onSurface
                        : isWarning
                        ? const Color(0xFF7B5A8C) // Cool purple warning text
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isWarning
                        ? const Color(
                            0xFF9C7BA8,
                          ) // Cool purple warning subtitle
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.5),
            inactiveThumbColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBehaviorSection() {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(sectionPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.widgetSettingsBookingBehavior,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Booking Behavior: Cancellation switch + deadline slider
              // Note: Require Approval is now in Stripe section (only applies to Stripe)
              // Bank transfer and Pay on Arrival always require approval
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 600;
                  final l10nInner = AppLocalizations.of(context);

                  // Build cancellation switch card
                  final cancellationCard = _buildBehaviorSwitchCard(
                    icon: Icons.event_busy,
                    label: l10nInner.widgetSettingsAllowCancellation,
                    subtitle: l10nInner.widgetSettingsGuestsCanCancel,
                    value: _allowCancellation,
                    onChanged: (val) =>
                        setState(() => _allowCancellation = val),
                  );

                  // Build cancellation deadline card (only shown when cancellation is enabled)
                  final deadlineCard = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _allowCancellation
                          ? Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.3)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _allowCancellation
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                        width: _allowCancellation ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 20,
                              color: _allowCancellation
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AutoSizeText(
                                l10nInner.widgetSettingsCancellationDeadline(
                                  _cancellationHours,
                                ),
                                maxLines: 1,
                                minFontSize: 12,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _allowCancellation
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _allowCancellation
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                            inactiveTrackColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            thumbColor: _allowCancellation
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            overlayColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            valueIndicatorColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Slider(
                            value: _cancellationHours.toDouble(),
                            max: 360, // 15 days
                            divisions: 60,
                            label: '$_cancellationHours h',
                            onChanged: _allowCancellation
                                ? (value) {
                                    setState(
                                      () => _cancellationHours = value.round(),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );

                  // Build advance booking card
                  final advanceBookingCard = _buildAdvanceBookingCard(
                    l10nInner,
                  );

                  // Desktop: cancellation switch left, deadline slider right
                  if (isDesktop) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cancellationCard),
                            const SizedBox(width: 12),
                            Expanded(child: deadlineCard),
                          ],
                        ),
                        const SizedBox(height: 12),
                        advanceBookingCard,
                      ],
                    );
                  } else {
                    // Mobile: Vertical layout
                    return Column(
                      children: [
                        cancellationCard,
                        const SizedBox(height: 12),
                        deadlineCard,
                        const SizedBox(height: 12),
                        advanceBookingCard,
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build advance booking restrictions card
  Widget _buildAdvanceBookingCard(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.date_range,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.widgetSettingsAdvanceBooking,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.widgetSettingsAdvanceBookingDesc,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Min/Max days advance inputs
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 400;
              final minDaysField = _buildDaysAdvanceField(
                label: l10n.widgetSettingsMinDaysAdvance,
                hint: l10n.widgetSettingsMinDaysAdvanceHint,
                value: _minDaysAdvance,
                onChanged: (val) => setState(() => _minDaysAdvance = val),
              );
              final maxDaysField = _buildDaysAdvanceField(
                label: l10n.widgetSettingsMaxDaysAdvance,
                hint: l10n.widgetSettingsMaxDaysAdvanceHint,
                value: _maxDaysAdvance,
                onChanged: (val) => setState(() => _maxDaysAdvance = val),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: minDaysField),
                    const SizedBox(width: 12),
                    Expanded(child: maxDaysField),
                  ],
                );
              } else {
                return Column(
                  children: [
                    minDaysField,
                    const SizedBox(height: 12),
                    maxDaysField,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build a days advance input field with helper text below
  Widget _buildDaysAdvanceField({
    required String label,
    required String hint,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration:
          InputDecorationHelper.buildDecoration(
            context: context,
            labelText: label,
            prefixIcon: const Icon(Icons.today),
          ).copyWith(
            // Show hint as helper text BELOW the field (stays visible while typing)
            helperText: hint,
            helperStyle: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      onChanged: (text) {
        final parsed = int.tryParse(text) ?? 0;
        onChanged(parsed.clamp(0, 730));
      },
    );
  }

  // Helper widget for behavior switch cards
  Widget _buildBehaviorSwitchCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Leading icon
          Icon(
            icon,
            color: value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 12),
          // Expanded title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: value
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Trailing switch
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.5),
            inactiveThumbColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }

  /// Build info card (used for bookingPending mode warning)
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
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
}
