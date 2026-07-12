import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/domain/models/widget_mode.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart'
    as widget_provider;
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../providers/user_profile_provider.dart';
import '../../../../shared/widgets/universal_loader.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/config/environment.dart';
import '../widgets/widget_settings_section.dart';
import '../widgets/widget_embed_code_section.dart';
import '../widgets/widget_platform_install_section.dart';
import '../widgets/widget_live_preview_section.dart';
import '../widgets/widget_appearance_section.dart';
import '../../../subscription/providers/trial_status_provider.dart';

part 'widget_settings_behavior_sections.dart';
part 'widget_settings_payment_sections.dart';

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

/// Shared mutable state for `_WidgetSettingsScreenState` and its section
/// mixins (`_PaymentSectionsMixin`, `_BehaviorSectionsMixin`). Split into
/// `part` files on 2026-07-11 — every method moved VERBATIM; runtime class
/// unchanged (incl. the Android keyboard-dismiss fix mixin on this base).
abstract class _WidgetSettingsScreenStateBase
    extends ConsumerState<WidgetSettingsScreen>
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

  // Appearance (Izgled) — accent/theme/radius/show-prices/branding. Persisted
  // via the existing widget_settings write (theme_options sub-map; no frozen
  // widget_secrets write is touched).
  ThemeOptions _themeOptions = const ThemeOptions();
}

class _WidgetSettingsScreenState extends _WidgetSettingsScreenStateBase
    with _PaymentSectionsMixin, _BehaviorSectionsMixin {
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

      // Appearance options (Izgled) — accent/theme/radius/prices/branding
      _themeOptions = settings.themeOptions ?? const ThemeOptions();

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
        themeOptions: _themeOptions,
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

    final accentHex = _themeOptions.primaryColor ?? '#6B4CE6';
    final previewUrl =
        '${EnvironmentConfig.widgetBaseUrl}/?property=${widget.propertyId}'
        '&unit=${widget.unitId}';

    final bodyContent = _isLoading
        ? UniversalLoader.forSection()
        : Container(
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: Center(
              child: ConstrainedBox(
                // Desktop readable-width clamp (was edge-to-edge full-bleed).
                constraints: const BoxConstraints(
                  maxWidth: BBConstraint.maxNarrowContentWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.all(contentPadding),
                    children: [
                      // H1 header
                      _buildHeader(),

                      const SizedBox(height: BBSpace.lg),

                      _buildWidgetModeSection(),

                      const SizedBox(height: BBSpace.lg),

                      // H5 Appearance (Izgled) — accent / theme / radius /
                      // show-prices / powered-by, all via ThemeOptions.copyWith
                      // into the existing save path.
                      WidgetAppearanceSection(
                        options: _themeOptions,
                        onChanged: (o) => setState(() => _themeOptions = o),
                        // branding-removal stays Pro-gated (locked + PRO pill).
                        isPro: ref.watch(hasFullAccessProvider),
                      ),

                      const SizedBox(height: BBSpace.lg),

                      // Payment Methods - ONLY for bookingInstant mode
                      if (_selectedMode == WidgetMode.bookingInstant) ...[
                        _buildPaymentMethodsSection(),
                        const SizedBox(height: BBSpace.lg),

                        _buildBookingBehaviorSection(),
                        const SizedBox(height: BBSpace.lg),
                      ],

                      // Info card - ONLY for bookingPending mode
                      if (_selectedMode == WidgetMode.bookingPending) ...[
                        _buildInfoCard(
                          icon: Icons.info_outline,
                          title: l10n.widgetSettingsBookingWithoutPayment,
                          message: l10n.widgetSettingsBookingWithoutPaymentDesc,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: BBSpace.lg),

                        _buildBookingBehaviorSection(),
                        const SizedBox(height: BBSpace.lg),
                      ],

                      // H2 embed code + H3 platform install + H4 live preview
                      WidgetEmbedCodeSection(
                        propertyId: widget.propertyId,
                        unitId: widget.unitId,
                        accentHex: accentHex,
                      ),
                      const SizedBox(height: BBSpace.lg),
                      const WidgetPlatformInstallSection(),
                      const SizedBox(height: BBSpace.lg),
                      WidgetLivePreviewSection(
                        accentHex: accentHex,
                        previewUrl: previewUrl,
                      ),

                      const SizedBox(height: BBSpace.lg),

                      // Primary save CTA via `BbButton`.
                      BbButton(
                        label: _isSaving
                            ? l10n.widgetSettingsSaving
                            : l10n.widgetSettingsSave,
                        iconLeft: _isSaving ? null : 'check',
                        size: BbButtonSize.lg,
                        fullWidth: true,
                        loading: _isSaving,
                        onPressed: _isSaving ? null : _saveSettings,
                      ),
                    ],
                  ),
                ),
              ),
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

  /// Page header (H1) — handoff `embed.jsx` EmbHeader: title + subtitle +
  /// "Active" status badge.
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.widgetSettingsHeaderTitle, style: BBType.h1(context)),
              const SizedBox(height: BBSpace.xxs),
              Text(
                l10n.widgetSettingsHeaderSubtitle,
                style: BBType.caption(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: BBSpace.sm),
        BbStatusBadge(
          status: BbBookingStatus.confirmed,
          label: l10n.widgetSettingsStatusActive,
        ),
      ],
    );
  }

  Widget _buildWidgetModeSection() {
    final l10n = AppLocalizations.of(context);
    return WidgetSettingsSection(
      icon: 'widgets',
      title: l10n.widgetSettingsWidgetMode,
      subtitle: l10n.widgetSettingsWidgetModeDesc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...WidgetMode.values.map(
            (mode) => BbRadio<WidgetMode>(
              value: mode,
              groupValue: _selectedMode,
              onChanged: (m) => setState(() => _selectedMode = m),
              label: mode.displayName,
              subtitle: mode.description,
            ),
          ),
        ],
      ),
    );
  }
}
