import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/domain/models/widget_mode.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart'
    as widget_provider;
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/user_profile_provider.dart';

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

class _WidgetSettingsScreenState extends ConsumerState<WidgetSettingsScreen> {
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

  bool _payOnArrivalEnabled = false;

  // Booking Behavior
  bool _requireApproval = true;
  bool _allowCancellation = true;
  int _cancellationHours = 48;
  int _minNights = 1;

  // Contact Options
  bool _showPhone = true;
  final _phoneController = TextEditingController();
  bool _showEmail = true;
  final _emailController = TextEditingController();

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

      // Load company details for bank transfer validation
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final profileRepository = ref.read(userProfileRepositoryProvider);
        _companyDetails = await profileRepository.getCompanyDetails(userId);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom učitavanja postavki',
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

      // Pay on Arrival
      _payOnArrivalEnabled = settings.allowPayOnArrival;

      // Booking Behavior
      _requireApproval = settings.requireOwnerApproval;
      _allowCancellation = settings.allowGuestCancellation;
      _cancellationHours = settings.cancellationDeadlineHours ?? 48;
      _minNights = settings.minNights;

      // Contact Options
      _showPhone = settings.contactOptions.showPhone;
      _phoneController.text = settings.contactOptions.phoneNumber ?? '';
      _showEmail = settings.contactOptions.showEmail;
      _emailController.text = settings.contactOptions.emailAddress ?? '';

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
    if (val) {
      // Check if bank details exist in profile
      if (_companyDetails == null || !_companyDetails!.hasBankDetails) {
        // Show dialog to go to profile
        final goToProfile = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Bankovni podaci nisu uneseni'),
            content: const Text(
              'Da biste omogućili bankovnu uplatu, morate prvo unijeti '
              'bankovne podatke u svom profilu (naziv banke, IBAN, vlasnik računa).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Dodaj Bankovne Podatke'),
              ),
            ],
          ),
        );

        if (goToProfile == true && mounted) {
          // Navigate to edit profile and reload on return
          await context.push(OwnerRoutes.bankAccount);
          // Reload company details after returning from profile
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            final profileRepository = ref.read(userProfileRepositoryProvider);
            _companyDetails = await profileRepository.getCompanyDetails(userId);
            // If now has bank details, enable bank transfer
            if (_companyDetails?.hasBankDetails == true) {
              setState(() => _bankTransferEnabled = true);
            }
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
          color: theme.colorScheme.errorContainer.withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withAlpha((0.5 * 255).toInt()),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bankovni podaci nisu uneseni',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unesite bankovne podatke u Integracije → Plaćanja.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await context.push(OwnerRoutes.bankAccount);
                // Reload on return
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  final profileRepository = ref.read(userProfileRepositoryProvider);
                  final updatedCompany = await profileRepository.getCompanyDetails(userId);
                  if (mounted) {
                    setState(() => _companyDetails = updatedCompany);
                  }
                }
              },
              child: const Text('Uredi'),
            ),
          ],
        ),
      );
    }

    // Show bank details from profile
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bankovni podaci iz profila:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await context.push(OwnerRoutes.bankAccount);
                  // Reload on return
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    final profileRepository = ref.read(userProfileRepositoryProvider);
                    final updatedCompany = await profileRepository.getCompanyDetails(userId);
                    if (mounted) {
                      setState(() => _companyDetails = updatedCompany);
                    }
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Uredi'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBankDetailRow('Banka', company.bankName),
          _buildBankDetailRow('IBAN', company.bankAccountIban),
          _buildBankDetailRow('SWIFT/BIC', company.swift),
          _buildBankDetailRow('Vlasnik računa', company.accountHolder),
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
                color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
    if (!_formKey.currentState!.validate()) return;

    // Validation: At least one payment method must be enabled in bookingInstant mode
    // (No validation needed for bookingPending - payment methods are hidden)
    if (_selectedMode == WidgetMode.bookingInstant) {
      final hasPaymentMethod =
          _stripeEnabled || _bankTransferEnabled || _payOnArrivalEnabled;
      if (!hasPaymentMethod) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            Exception('Validation failed'),
            userMessage:
                'Mora biti uključen bar jedan način plaćanja u Instant Booking modu',
          );
        }
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(widgetSettingsRepositoryProvider);

      final settings = WidgetSettings(
        id: widget.unitId,
        propertyId: widget.propertyId,
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
        allowPayOnArrival: _payOnArrivalEnabled,
        // For bookingPending mode, approval is ALWAYS required (hardcoded true)
        // For bookingInstant mode, use the user's selection
        requireOwnerApproval: _selectedMode == WidgetMode.bookingPending
            ? true
            : _requireApproval,
        allowGuestCancellation: _allowCancellation,
        cancellationDeadlineHours: _cancellationHours,
        minNights: _minNights,
        contactOptions: ContactOptions(
          showPhone: _showPhone,
          phoneNumber: _phoneController.text.isEmpty
              ? null
              : _phoneController.text,
          showEmail: _showEmail,
          emailAddress: _emailController.text.isEmpty
              ? null
              : _emailController.text,
        ),
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
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Postavke uspješno sačuvane!',
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
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom čuvanja postavki',
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
    _phoneController.dispose();
    _emailController.dispose();
    _bookingComAccountIdController.dispose();
    _bookingComAccessTokenController.dispose();
    _airbnbAccountIdController.dispose();
    _airbnbAccessTokenController.dispose();
    _bankCustomNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentPadding = context.horizontalPadding;

    final bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
              key: _formKey,
              child: ListView(
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
                      title: 'Rezervacija bez plaćanja',
                      message:
                          'U ovom modu gosti mogu kreirati rezervaciju, ali NE mogu platiti online. '
                          'Plaćanje dogovarate privatno nakon što potvrdite rezervaciju.',
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(height: 24),

                    _buildBookingBehaviorSection(),
                    const SizedBox(height: 24),
                  ],

                  _buildContactOptionsSection(),

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
                                _isSaving ? 'Čuvanje...' : 'Sačuvaj Postavke',
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

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Postavke Widgeta',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: bodyContent,
    );
  }

  Widget _buildWidgetModeSection() {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : Colors.black.withAlpha((0.1 * 255).toInt()),
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
            gradient: context.gradients.sectionBackground,
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
                      color: theme.colorScheme.primary.withAlpha(
                        (0.12 * 255).toInt(),
                      ),
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
                    child: Text(
                      'Mod Widgeta',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Odaberite kako će widget funkcionirati:',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                                        .withAlpha((0.3 * 255).toInt()),
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
                                      .withAlpha((0.6 * 255).toInt()),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
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
                    color: theme.colorScheme.primary.withAlpha(
                      (0.12 * 255).toInt(),
                    ),
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
                  child: Text(
                    'Metode Plaćanja',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info text
            Text(
              'Odaberite metode plaćanja dostupne gostima:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 16),

            // Global Deposit Percentage Slider (applies to all payment methods)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withAlpha((0.3 * 255).toInt()),
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
                        'Iznos Avansa: $_globalDepositPercentage%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ovaj procenat se primjenjuje na sve metode plaćanja (Stripe, Bankovna uplata)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _globalDepositPercentage.toDouble(),
                    max: 100,
                    divisions: 20,
                    label: '$_globalDepositPercentage%',
                    onChanged: (value) {
                      setState(() => _globalDepositPercentage = value.round());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0% (Puna uplata)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface
                              .withAlpha((0.5 * 255).toInt()),
                        ),
                      ),
                      Text(
                        '100% (Puna uplata)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface
                              .withAlpha((0.5 * 255).toInt()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stripe Payment - Collapsible (no deposit slider)
            _buildPaymentMethodExpansionTile(
              icon: Icons.credit_card,
              title: 'Stripe Plaćanje',
              subtitle: 'Plaćanje karticom',
              enabled: _stripeEnabled,
              onToggle: (val) => setState(() => _stripeEnabled = val),
              child: const SizedBox.shrink(), // No additional settings needed
            ),

            const SizedBox(height: 12),

            // Bank Transfer - Collapsible with lazy validation
            _buildPaymentMethodExpansionTile(
              icon: Icons.account_balance,
              title: 'Bankovna Uplata',
              subtitle: 'Uplata na račun',
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
                  DropdownButtonFormField<int>(
                    initialValue: _bankPaymentDeadlineDays,
                    decoration: const InputDecoration(
                      labelText: 'Rok za uplatu (dana)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 dan')),
                      DropdownMenuItem(value: 3, child: Text('3 dana')),
                      DropdownMenuItem(value: 5, child: Text('5 dana')),
                      DropdownMenuItem(value: 7, child: Text('7 dana')),
                      DropdownMenuItem(value: 14, child: Text('14 dana')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _bankPaymentDeadlineDays = value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Additional options in responsive grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 600;

                      final qrSwitch = _buildCompactSwitchCard(
                        icon: Icons.qr_code,
                        label: 'Prikaži QR kod',
                        subtitle: 'EPC QR kod',
                        value: _bankEnableQrCode,
                        onChanged: (val) =>
                            setState(() => _bankEnableQrCode = val),
                      );

                      final customNotesSwitch = _buildCompactSwitchCard(
                        icon: Icons.edit_note,
                        label: 'Prilagođena napomena',
                        subtitle: 'Dodaj poruku',
                        value: _bankUseCustomNotes,
                        onChanged: (val) =>
                            setState(() => _bankUseCustomNotes = val),
                      );

                      if (isDesktop) {
                        // Desktop: 2 columns
                        return Row(
                          children: [
                            Expanded(child: qrSwitch),
                            const SizedBox(width: 12),
                            Expanded(child: customNotesSwitch),
                          ],
                        );
                      } else {
                        // Mobile: Vertical
                        return Column(
                          children: [
                            qrSwitch,
                            const SizedBox(height: 12),
                            customNotesSwitch,
                          ],
                        );
                      }
                    },
                  ),

                  // Custom notes text field (conditional)
                  if (_bankUseCustomNotes) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bankCustomNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Napomena (max 500 znakova)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        helperText:
                            'Prilagođena poruka koja će se prikazati gostima',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Pay on Arrival - Simple switch card (not collapsible since no options)
            Builder(
              builder: (context) {
                // Force Pay on Arrival if both Stripe and Bank Transfer are disabled
                final isForced = !_stripeEnabled && !_bankTransferEnabled;

                // Auto-enable if forced
                if (isForced && !_payOnArrivalEnabled) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _payOnArrivalEnabled = true);
                  });
                }

                return _buildCompactSwitchCard(
                  icon: Icons.payments,
                  label: 'Plaćanje po Dolasku',
                  subtitle: isForced
                      ? '⚠️ Obavezno (jer su ostale metode isključene)'
                      : 'Gost plaća prilikom prijave',
                  value: _payOnArrivalEnabled,
                  onChanged: isForced
                      ? null
                      : (val) => setState(() => _payOnArrivalEnabled = val),
                  isWarning: isForced,
                );
              },
            ),
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
              ).colorScheme.primaryContainer.withAlpha((0.2 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(
                (0.3 * 255).toInt(),
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
          width: enabled ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
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
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt()),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: enabled,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
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
              ).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt())
            : isWarning
            ? Theme.of(
                context,
              ).colorScheme.errorContainer.withAlpha((0.2 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(
                (0.3 * 255).toInt(),
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value && !isWarning
              ? Theme.of(context).colorScheme.primary
              : isWarning
              ? Theme.of(context).colorScheme.error
              : Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
                ? Theme.of(context).colorScheme.error
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
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isWarning
                        ? Theme.of(
                            context,
                          ).colorScheme.error.withAlpha((0.8 * 255).toInt())
                        : Theme.of(context).colorScheme.onSurfaceVariant
                              .withAlpha((0.7 * 255).toInt()),
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
            activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBehaviorSection() {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
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
                    color: theme.colorScheme.primary.withAlpha(
                      (0.12 * 255).toInt(),
                    ),
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
                  child: Text(
                    'Ponašanje Rezervacije',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Responsive Grid for Switches
            // Note: For bookingPending mode, approval is ALWAYS required (hidden toggle)
            // Only show approval toggle for bookingInstant mode
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;
                final isBookingPending = _selectedMode == WidgetMode.bookingPending;

                // Build cancellation card (always shown)
                final cancellationCard = _buildBehaviorSwitchCard(
                  icon: Icons.event_busy,
                  label: 'Dozvolite Otkazivanje',
                  subtitle: 'Gosti mogu otkazati',
                  value: _allowCancellation,
                  onChanged: (val) =>
                      setState(() => _allowCancellation = val),
                );

                // Build approval card (only for bookingInstant)
                final approvalCard = _buildBehaviorSwitchCard(
                  icon: Icons.approval,
                  label: 'Zahtijeva Odobrenje',
                  subtitle: 'Ručno odobravanje',
                  value: _requireApproval,
                  onChanged: (val) =>
                      setState(() => _requireApproval = val),
                );

                // For bookingPending: only show cancellation (approval is always true)
                if (isBookingPending) {
                  return Column(
                    children: [
                      // Info banner explaining approval is automatic
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withAlpha((0.3 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha((0.5 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'U "Rezervacija bez plaćanja" modu sve rezervacije uvijek zahtijevaju vaše odobrenje.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      cancellationCard,
                    ],
                  );
                }

                // For bookingInstant: show both cards
                if (isDesktop) {
                  // Desktop: 2 columns
                  return Row(
                    children: [
                      Expanded(child: approvalCard),
                      const SizedBox(width: 12),
                      Expanded(child: cancellationCard),
                    ],
                  );
                } else {
                  // Mobile: Vertical
                  return Column(
                    children: [
                      approvalCard,
                      const SizedBox(height: 12),
                      cancellationCard,
                    ],
                  );
                }
              },
            ),

            // Cancellation deadline slider (conditional)
            if (_allowCancellation) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withAlpha((0.3 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withAlpha((0.3 * 255).toInt()),
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rok za otkazivanje: $_cancellationHours sati prije prijave',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _cancellationHours.toDouble(),
                      max: 168, // 7 days
                      divisions: 28,
                      label: '$_cancellationHours h',
                      onChanged: (value) {
                        setState(() => _cancellationHours = value.round());
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Minimum nights slider (always shown)
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withAlpha((0.3 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withAlpha((0.3 * 255).toInt()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hotel,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Minimalni broj noćenja: $_minNights ${_minNights == 1
                            ? 'noć'
                            : _minNights >= 2 && _minNights <= 4
                            ? 'noći'
                            : 'noći'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _minNights.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: '$_minNights ${_minNights == 1 ? 'noć' : 'noći'}',
                    onChanged: (value) {
                      setState(() => _minNights = value.round());
                    },
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
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withAlpha((0.3 * 255).toInt())
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
                    ).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt()),
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
            activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOptionsSection() {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
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
                      color: theme.colorScheme.primary.withAlpha(
                        (0.12 * 255).toInt(),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.contact_phone,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kontakt Informacije',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kontakt opcije koje će biti prikazane u widgetu:',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                ),
              ),
              const SizedBox(height: 16),

              // Responsive Grid for Switches with input fields
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 600;

                  final phoneInput = TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Broj telefona',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  );

                  final emailInput = TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email adresa',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  );

                  if (isDesktop) {
                    // Desktop: 2 columns grid
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildContactSwitchCard(
                            icon: Icons.phone,
                            label: 'Telefon',
                            value: _showPhone,
                            onChanged: (val) => setState(() => _showPhone = val),
                            child: phoneInput,
                          ),
                        ),
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _buildContactSwitchCard(
                            icon: Icons.email,
                            label: 'Email',
                            value: _showEmail,
                            onChanged: (val) => setState(() => _showEmail = val),
                            child: emailInput,
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Mobile: Vertical column
                    return Column(
                      children: [
                        _buildContactSwitchCard(
                          icon: Icons.phone,
                          label: 'Telefon',
                          value: _showPhone,
                          onChanged: (val) => setState(() => _showPhone = val),
                          child: phoneInput,
                        ),
                        const SizedBox(height: 12),
                        _buildContactSwitchCard(
                          icon: Icons.email,
                          label: 'Email',
                          value: _showEmail,
                          onChanged: (val) => setState(() => _showEmail = val),
                          child: emailInput,
                        ),
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

  // Helper widget for contact switch cards
  Widget _buildContactSwitchCard({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withAlpha((0.3 * 255).toInt())
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(
                  context,
                ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
          width: value ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: value
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    color: value
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (value && child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withAlpha((0.1 * 255).toInt()),
                color.withAlpha((0.05 * 255).toInt()),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha((0.3 * 255).toInt())),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                      ),
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
}
