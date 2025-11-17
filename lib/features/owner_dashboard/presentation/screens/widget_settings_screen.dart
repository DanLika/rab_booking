import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/domain/models/widget_mode.dart';
import '../../../widget/presentation/providers/widget_settings_provider.dart' as widget_provider;
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import 'widget_advanced_settings_screen.dart';

/// Widget Settings Screen - Configure embedded widget for each unit
class WidgetSettingsScreen extends ConsumerStatefulWidget {
  const WidgetSettingsScreen({
    required this.propertyId,
    required this.unitId,
    super.key,
  });

  final String propertyId;
  final String unitId;

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
  final _bankNameController = TextEditingController();
  final _ibanController = TextEditingController();
  final _swiftController = TextEditingController();
  final _accountHolderController = TextEditingController();
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
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom učitavanja postavki',
        );
      }
    } finally {
      setState(() => _isLoading = false);
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

      // Payment Methods - Bank Transfer
      _bankTransferEnabled = settings.bankTransferConfig?.enabled ?? false;
      _bankNameController.text = settings.bankTransferConfig?.bankName ?? '';
      _ibanController.text = settings.bankTransferConfig?.iban ?? '';
      _swiftController.text = settings.bankTransferConfig?.swift ?? '';
      _accountHolderController.text =
          settings.bankTransferConfig?.accountHolder ?? '';
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
                depositPercentage: _globalDepositPercentage, // Use global deposit
              )
            : null,
        bankTransferConfig: _bankTransferEnabled
            ? BankTransferConfig(
                enabled: true,
                depositPercentage: _globalDepositPercentage, // Use global deposit
                bankName: _bankNameController.text.isEmpty
                    ? null
                    : _bankNameController.text,
                iban: _ibanController.text.isEmpty
                    ? null
                    : _ibanController.text,
                swift: _swiftController.text.isEmpty
                    ? null
                    : _swiftController.text,
                accountHolder: _accountHolderController.text.isEmpty
                    ? null
                    : _accountHolderController.text,
                paymentDeadlineDays: _bankPaymentDeadlineDays,
                enableQrCode: _bankEnableQrCode,
                customNotes: _bankCustomNotesController.text.isEmpty
                    ? null
                    : _bankCustomNotesController.text,
                useCustomNotes: _bankUseCustomNotes,
              )
            : null,
        allowPayOnArrival: _payOnArrivalEnabled,
        requireOwnerApproval: _requireApproval,
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
        blurConfig: _existingSettings?.blurConfig,
        createdAt: _existingSettings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.updateWidgetSettings(settings);

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Postavke uspješno sačuvane!',
        );
        Navigator.pop(context);
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
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _ibanController.dispose();
    _swiftController.dispose();
    _accountHolderController.dispose();
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
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Postavke Widgeta',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Mod Widgeta', Icons.widgets),
                  _buildWidgetModeSection(),

                  const SizedBox(height: 24),

                  // Payment Methods - ONLY for bookingInstant mode
                  if (_selectedMode == WidgetMode.bookingInstant) ...[
                    _buildSectionTitle('Metode Plaćanja', Icons.payment),
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Ponašanje Rezervacije', Icons.settings),
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

                    _buildSectionTitle('Ponašanje Rezervacije', Icons.settings),
                    _buildBookingBehaviorSection(),
                    const SizedBox(height: 24),
                  ],

                  _buildSectionTitle(
                    'Kontakt Informacije',
                    Icons.contact_phone,
                  ),
                  _buildContactOptionsSection(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Napredne Postavke',
                    Icons.settings_applications,
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.tune, color: context.primaryColor),
                      title: const Text('Email i Pravne Postavke'),
                      subtitle: const Text(
                        'Konfigurišite email notifikacije i pravne napomene',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WidgetAdvancedSettingsScreen(
                              propertyId: widget.propertyId,
                              unitId: widget.unitId,
                            ),
                          ),
                        );
                        // After returning from Advanced Settings, reload settings
                        // to ensure Widget Settings has fresh data from Firestore
                        if (mounted) {
                          ref.invalidate(widget_provider.widgetSettingsProvider);
                          await _loadSettings(); // Re-fetch and apply fresh settings
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(_isSaving ? 'Čuvanje...' : 'Sačuvaj Postavke'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  color: Theme.of(context).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
                      color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                        ),
                      ),
                      Text(
                        '100% (Puna uplata)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
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

            // Bank Transfer - Collapsible (no deposit slider)
            _buildPaymentMethodExpansionTile(
              icon: Icons.account_balance,
              title: 'Bankovna Uplata',
              subtitle: 'Uplata na račun',
              enabled: _bankTransferEnabled,
              onToggle: (val) => setState(() => _bankTransferEnabled = val),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Bank details in responsive grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 600;

                      if (isDesktop) {
                        // Desktop: 2 columns
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bankNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Naziv banke',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _accountHolderController,
                                    decoration: const InputDecoration(
                                      labelText: 'Vlasnik računa',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _ibanController,
                                    decoration: const InputDecoration(
                                      labelText: 'IBAN',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _swiftController,
                                    decoration: const InputDecoration(
                                      labelText: 'SWIFT/BIC',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Mobile: Vertical
                        return Column(
                          children: [
                            TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'Naziv banke',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _ibanController,
                              decoration: const InputDecoration(
                                labelText: 'IBAN',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _swiftController,
                              decoration: const InputDecoration(
                                labelText: 'SWIFT/BIC',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _accountHolderController,
                              decoration: const InputDecoration(
                                labelText: 'Vlasnik računa',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),

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
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBehaviorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Grid for Switches
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;

                if (isDesktop) {
                  // Desktop: 2 columns
                  return Row(
                    children: [
                      Expanded(
                        child: _buildBehaviorSwitchCard(
                          icon: Icons.approval,
                          label: 'Zahtijeva Odobrenje',
                          subtitle: 'Ručno odobravanje',
                          value: _requireApproval,
                          onChanged: (val) =>
                              setState(() => _requireApproval = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBehaviorSwitchCard(
                          icon: Icons.event_busy,
                          label: 'Dozvolite Otkazivanje',
                          subtitle: 'Gosti mogu otkazati',
                          value: _allowCancellation,
                          onChanged: (val) =>
                              setState(() => _allowCancellation = val),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile: Vertical
                  return Column(
                    children: [
                      _buildBehaviorSwitchCard(
                        icon: Icons.approval,
                        label: 'Zahtijeva Odobrenje',
                        subtitle: 'Ručno odobravanje',
                        value: _requireApproval,
                        onChanged: (val) =>
                            setState(() => _requireApproval = val),
                      ),
                      const SizedBox(height: 12),
                      _buildBehaviorSwitchCard(
                        icon: Icons.event_busy,
                        label: 'Dozvolite Otkazivanje',
                        subtitle: 'Gosti mogu otkazati',
                        value: _allowCancellation,
                        onChanged: (val) =>
                            setState(() => _allowCancellation = val),
                      ),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
                        Text(
                          'Rok za otkazivanje: $_cancellationHours sati prije prijave',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
              ).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(
                (0.3 * 255).toInt(),
              ),
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
                size: 24,
              ),
              const Spacer(),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildContactOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Responsive Grid for Switches
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;

                if (isDesktop) {
                  // Desktop: 2 columns grid
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Row 1
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _buildContactSwitchCard(
                          icon: Icons.phone,
                          label: 'Telefon',
                          value: _showPhone,
                          onChanged: (val) => setState(() => _showPhone = val),
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _buildContactSwitchCard(
                          icon: Icons.email,
                          label: 'Email',
                          value: _showEmail,
                          onChanged: (val) => setState(() => _showEmail = val),
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
                      ),
                      const SizedBox(height: 12),
                      _buildContactSwitchCard(
                        icon: Icons.email,
                        label: 'Email',
                        value: _showEmail,
                        onChanged: (val) => setState(() => _showEmail = val),
                      ),
                    ],
                  );
                }
              },
            ),

            // Input Fields (conditional based on enabled switches)
            const SizedBox(height: 20),

            if (_showPhone) ...[
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Broj telefona',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
            ],

            if (_showEmail) ...[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email adresa',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
            ],
          ],
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(
                (0.3 * 255).toInt(),
              ),
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
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withAlpha((0.1 * 255).toInt()),
              color.withAlpha((0.05 * 255).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha((0.3 * 255).toInt()),
          ),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha((0.7 * 255).toInt()),
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
