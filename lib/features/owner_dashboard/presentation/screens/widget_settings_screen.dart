import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/domain/models/widget_mode.dart';
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
  bool _stripeEnabled = false;
  int _stripeDepositPercentage = 20;

  bool _bankTransferEnabled = false;
  int _bankDepositPercentage = 20;
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

  // Contact Options
  bool _showPhone = true;
  final _phoneController = TextEditingController();
  bool _showEmail = true;
  final _emailController = TextEditingController();
  bool _showWhatsApp = false;
  final _whatsAppController = TextEditingController();
  final _customMessageController = TextEditingController();

  // Theme Options
  bool _showBranding = true;
  Color _primaryColor = AppColors.primary;
  String _themeMode = 'system'; // 'light', 'dark', 'system'

  // Blur/Glassmorphism Options
  bool _blurEnabled = true;
  String _blurIntensity =
      'medium'; // 'subtle', 'light', 'medium', 'strong', 'extra_strong'
  bool _enableCardBlur = true;
  bool _enableAppBarBlur = true;
  bool _enableModalBlur = true;
  bool _enableOverlayBlur = true;

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

      // Payment Methods - Stripe
      _stripeEnabled = settings.stripeConfig?.enabled ?? false;
      _stripeDepositPercentage = settings.stripeConfig?.depositPercentage ?? 20;

      // Payment Methods - Bank Transfer
      _bankTransferEnabled = settings.bankTransferConfig?.enabled ?? false;
      _bankDepositPercentage =
          settings.bankTransferConfig?.depositPercentage ?? 20;
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

      // Contact Options
      _showPhone = settings.contactOptions.showPhone;
      _phoneController.text = settings.contactOptions.phoneNumber ?? '';
      _showEmail = settings.contactOptions.showEmail;
      _emailController.text = settings.contactOptions.emailAddress ?? '';
      _showWhatsApp = settings.contactOptions.showWhatsApp;
      _whatsAppController.text = settings.contactOptions.whatsAppNumber ?? '';
      _customMessageController.text =
          settings.contactOptions.customMessage ?? '';

      // Theme Options
      _showBranding = settings.themeOptions?.showBranding ?? true;
      _themeMode = settings.themeOptions?.themeMode ?? 'system';
      if (settings.themeOptions?.primaryColor != null) {
        _primaryColor = _parseColor(settings.themeOptions!.primaryColor!);
      }

      // Blur Options
      _blurEnabled = settings.blurConfig?.enabled ?? true;
      _blurIntensity = settings.blurConfig?.intensity ?? 'medium';
      _enableCardBlur = settings.blurConfig?.enableCardBlur ?? true;
      _enableAppBarBlur = settings.blurConfig?.enableAppBarBlur ?? true;
      _enableModalBlur = settings.blurConfig?.enableModalBlur ?? true;
      _enableOverlayBlur = settings.blurConfig?.enableOverlayBlur ?? true;

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

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  String _colorToHex(Color color) {
    // Extract ARGB components without using deprecated .value
    final r = color.r.toInt();
    final g = color.g.toInt();
    final b = color.b.toInt();
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: At least one payment method must be enabled in bookingInstant mode
    if (_selectedMode == WidgetMode.bookingInstant) {
      final hasPaymentMethod = _stripeEnabled || _bankTransferEnabled || _payOnArrivalEnabled;
      if (!hasPaymentMethod) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            Exception('Validation failed'),
            userMessage: 'Mora biti uključen bar jedan način plaćanja u Instant Booking modu',
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
        stripeConfig: _stripeEnabled
            ? StripePaymentConfig(
                enabled: true,
                depositPercentage: _stripeDepositPercentage,
              )
            : null,
        bankTransferConfig: _bankTransferEnabled
            ? BankTransferConfig(
                enabled: true,
                depositPercentage: _bankDepositPercentage,
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
        contactOptions: ContactOptions(
          showPhone: _showPhone,
          phoneNumber: _phoneController.text.isEmpty
              ? null
              : _phoneController.text,
          showEmail: _showEmail,
          emailAddress: _emailController.text.isEmpty
              ? null
              : _emailController.text,
          showWhatsApp: _showWhatsApp,
          whatsAppNumber: _whatsAppController.text.isEmpty
              ? null
              : _whatsAppController.text,
          customMessage: _customMessageController.text.isEmpty
              ? null
              : _customMessageController.text,
        ),
        emailConfig: _existingSettings?.emailConfig ??
            const EmailNotificationConfig(),
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
        taxLegalConfig: _existingSettings?.taxLegalConfig ??
            const TaxLegalConfig(enabled: false),
        themeOptions: ThemeOptions(
          primaryColor: _colorToHex(_primaryColor),
          showBranding: _showBranding,
          themeMode: _themeMode,
        ),
        blurConfig: BlurConfig(
          enabled: _blurEnabled,
          intensity: _blurIntensity,
          enableCardBlur: _enableCardBlur,
          enableAppBarBlur: _enableAppBarBlur,
          enableModalBlur: _enableModalBlur,
          enableOverlayBlur: _enableOverlayBlur,
        ),
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
    _whatsAppController.dispose();
    _customMessageController.dispose();
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

                  if (_selectedMode != WidgetMode.calendarOnly) ...[
                    _buildSectionTitle('Metode Plaćanja', Icons.payment),
                    _buildPaymentMethodsSection(),
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

                  _buildSectionTitle('Eksterni Kalendari', Icons.sync),
                  _buildExternalCalendarSection(),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Napredne Postavke', Icons.settings_applications),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.tune, color: context.primaryColor),
                      title: const Text('Email i Pravne Postavke'),
                      subtitle: const Text('Konfigurišite email notifikacije i pravne napomene'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WidgetAdvancedSettingsScreen(
                              propertyId: widget.propertyId,
                              unitId: widget.unitId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Tema', Icons.palette),
                  _buildThemeSection(),

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
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 16),

            // Stripe Payment - Collapsible
            _buildPaymentMethodExpansionTile(
              icon: Icons.credit_card,
              title: 'Stripe Plaćanje',
              subtitle: 'Plaćanje karticom',
              enabled: _stripeEnabled,
              onToggle: (val) => setState(() => _stripeEnabled = val),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.percent, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Depozit: $_stripeDepositPercentage%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: _stripeDepositPercentage.toDouble(),
                    max: 100,
                    divisions: 20,
                    label: '$_stripeDepositPercentage%',
                    onChanged: (value) {
                      setState(() => _stripeDepositPercentage = value.round());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bank Transfer - Collapsible
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

                  // Deposit percentage
                  Row(
                    children: [
                      Icon(Icons.percent, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Depozit: $_bankDepositPercentage%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: _bankDepositPercentage.toDouble(),
                    max: 100,
                    divisions: 20,
                    label: '$_bankDepositPercentage%',
                    onChanged: (value) {
                      setState(() => _bankDepositPercentage = value.round());
                    },
                  ),
                  const SizedBox(height: 16),

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
                        onChanged: (val) => setState(() => _bankEnableQrCode = val),
                      );

                      final customNotesSwitch = _buildCompactSwitchCard(
                        icon: Icons.edit_note,
                        label: 'Prilagođena napomena',
                        subtitle: 'Dodaj poruku',
                        value: _bankUseCustomNotes,
                        onChanged: (val) => setState(() => _bankUseCustomNotes = val),
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
                        helperText: 'Prilagođena poruka koja će se prikazati gostima',
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
                  onChanged: isForced ? null : (val) => setState(() => _payOnArrivalEnabled = val),
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
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha((0.2 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
          width: enabled ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt()),
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
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt())
            : isWarning
            ? Theme.of(context).colorScheme.errorContainer.withAlpha((0.2 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value && !isWarning
              ? Theme.of(context).colorScheme.primary
              : isWarning
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
                        ? Theme.of(context).colorScheme.error.withAlpha((0.8 * 255).toInt())
                        : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt()),
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
                          onChanged: (val) => setState(() => _requireApproval = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBehaviorSwitchCard(
                          icon: Icons.event_busy,
                          label: 'Dozvolite Otkazivanje',
                          subtitle: 'Gosti mogu otkazati',
                          value: _allowCancellation,
                          onChanged: (val) => setState(() => _allowCancellation = val),
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
                        onChanged: (val) => setState(() => _requireApproval = val),
                      ),
                      const SizedBox(height: 12),
                      _buildBehaviorSwitchCard(
                        icon: Icons.event_busy,
                        label: 'Dozvolite Otkazivanje',
                        subtitle: 'Gosti mogu otkazati',
                        value: _allowCancellation,
                        onChanged: (val) => setState(() => _allowCancellation = val),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
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
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).toInt()),
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
                      // Row 2
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _buildContactSwitchCard(
                          icon: Icons.message,
                          label: 'WhatsApp',
                          value: _showWhatsApp,
                          onChanged: (val) => setState(() => _showWhatsApp = val),
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
                      const SizedBox(height: 12),
                      _buildContactSwitchCard(
                        icon: Icons.message,
                        label: 'WhatsApp',
                        value: _showWhatsApp,
                        onChanged: (val) => setState(() => _showWhatsApp = val),
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

            if (_showWhatsApp) ...[
              TextFormField(
                controller: _whatsAppController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp broj',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.message),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
            ],

            // Custom Message
            TextFormField(
              controller: _customMessageController,
              decoration: const InputDecoration(
                labelText: 'Prilagođena Poruka',
                hintText: 'Kontaktirajte nas za rezervaciju!',
                border: OutlineInputBorder(),
                helperText: 'Poruka koja će biti prikazana gostima',
              ),
              maxLines: 3,
            ),
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
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt())
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withAlpha((0.3 * 255).toInt()),
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

  Widget _buildExternalCalendarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sinhronizujte rezervacije sa eksternim platformama:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 12),

            // Master Enable Toggle
            SwitchListTile(
              value: _externalCalendarEnabled,
              onChanged: (value) =>
                  setState(() => _externalCalendarEnabled = value),
              title: const Text('Omogući Eksternu Sinhronizaciju'),
              subtitle: const Text('Uvezi rezervacije sa Booking.com i Airbnb'),
              contentPadding: EdgeInsets.zero,
            ),

            if (_externalCalendarEnabled) ...[
              const Divider(height: 32),

              // Booking.com Section
              const Text(
                'Booking.com:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                value: _syncBookingCom,
                onChanged: (value) => setState(() => _syncBookingCom = value),
                title: const Text('Sinhronizuj sa Booking.com'),
                contentPadding: EdgeInsets.zero,
              ),

              if (_syncBookingCom) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bookingComAccountIdController,
                  decoration: const InputDecoration(
                    labelText: 'Booking.com ID Objekta',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.home),
                    helperText: 'ID vašeg objekta na Booking.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bookingComAccessTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Booking.com Access Token',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.vpn_key),
                    helperText: 'OAuth token za pristup',
                  ),
                  obscureText: true,
                ),
              ],

              const Divider(height: 32),

              // Airbnb Section
              const Text(
                'Airbnb:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                value: _syncAirbnb,
                onChanged: (value) => setState(() => _syncAirbnb = value),
                title: const Text('Sinhronizuj sa Airbnb'),
                contentPadding: EdgeInsets.zero,
              ),

              if (_syncAirbnb) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _airbnbAccountIdController,
                  decoration: const InputDecoration(
                    labelText: 'Airbnb Listing ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.home),
                    helperText: 'ID vašeg smještaja na Airbnb',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _airbnbAccessTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Airbnb Access Token',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.vpn_key),
                    helperText: 'OAuth token za pristup',
                  ),
                  obscureText: true,
                ),
              ],

              const Divider(height: 32),

              // Sync Interval
              const Text(
                'Interval Sinhronizacije:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _syncIntervalMinutes,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.schedule),
                  helperText: 'Koliko često provjeravati nove rezervacije',
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('Svakih 15 minuta')),
                  DropdownMenuItem(value: 30, child: Text('Svakih 30 minuta')),
                  DropdownMenuItem(
                    value: 60,
                    child: Text('Svakih 60 minuta (1 sat)'),
                  ),
                  DropdownMenuItem(
                    value: 120,
                    child: Text('Svakih 120 minuta (2 sata)'),
                  ),
                  DropdownMenuItem(value: 360, child: Text('Svakih 6 sati')),
                  DropdownMenuItem(value: 1440, child: Text('Jednom dnevno')),
                ],
                onChanged: (value) =>
                    setState(() => _syncIntervalMinutes = value!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prilagodite izgled widgeta:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 12),

            // Theme Mode Selector
            const Text(
              'Tema:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...['light', 'dark', 'system'].map(
              (mode) => InkWell(
                onTap: () => setState(() => _themeMode = mode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _themeMode == mode
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withAlpha((0.3 * 255).toInt()),
                            width: 2,
                          ),
                        ),
                        child: _themeMode == mode
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
                      Icon(
                        mode == 'light'
                            ? Icons.light_mode
                            : mode == 'dark'
                            ? Icons.dark_mode
                            : Icons.settings_brightness,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode == 'light'
                            ? 'Svijetla Tema'
                            : mode == 'dark'
                            ? 'Tamna Tema (OLED Optimizovana)'
                            : 'Sistem (Auto)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Glassmorphism / Blur Effects Section
            const Text(
              'Glassmorphism Efekti:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Frosted glass efekti za moderan izgled',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 12),

            // Enable/Disable Blur
            SwitchListTile(
              value: _blurEnabled,
              onChanged: (value) => setState(() => _blurEnabled = value),
              title: const Text('Omogući Blur Efekte'),
              subtitle: const Text(
                'Glassmorphism za kartice, modale i app bar',
              ),
              contentPadding: EdgeInsets.zero,
            ),

            // Blur Intensity Selector
            if (_blurEnabled) ...[
              const SizedBox(height: 12),
              const Text(
                'Intenzitet Blur-a:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...['subtle', 'light', 'medium', 'strong', 'extra_strong'].map(
                (intensity) => InkWell(
                  onTap: () => setState(() => _blurIntensity = intensity),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _blurIntensity == intensity
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface
                                        .withAlpha((0.3 * 255).toInt()),
                              width: 2,
                            ),
                          ),
                          child: _blurIntensity == intensity
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
                        Icon(
                          Icons.blur_on,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface
                              .withAlpha((0.6 * 255).toInt()),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          intensity == 'subtle'
                              ? 'Suptilan (Barely visible)'
                              : intensity == 'light'
                              ? 'Lagan (Light frosted)'
                              : intensity == 'medium'
                              ? 'Srednji (Standard glass)'
                              : intensity == 'strong'
                              ? 'Jak (Prominent glass)'
                              : 'Ekstra Jak (Maximum blur)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Gdje primijeniti blur:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // Card Blur
              CheckboxListTile(
                value: _enableCardBlur,
                onChanged: (value) =>
                    setState(() => _enableCardBlur = value ?? true),
                title: const Text('Kartice (Cards)'),
                subtitle: const Text('Blur za informacijske kartice'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // App Bar Blur
              CheckboxListTile(
                value: _enableAppBarBlur,
                onChanged: (value) =>
                    setState(() => _enableAppBarBlur = value ?? true),
                title: const Text('App Bar'),
                subtitle: const Text('Blur za gornji navigation bar'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Modal Blur
              CheckboxListTile(
                value: _enableModalBlur,
                onChanged: (value) =>
                    setState(() => _enableModalBlur = value ?? true),
                title: const Text('Modale i Dijalozi'),
                subtitle: const Text('Blur za pop-up prozore'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Overlay Blur
              CheckboxListTile(
                value: _enableOverlayBlur,
                onChanged: (value) =>
                    setState(() => _enableOverlayBlur = value ?? true),
                title: const Text('Overlay Pozadine'),
                subtitle: const Text('Blur za pozadinske overlaye'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primarna Boja'),
              trailing: GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                ),
              ),
            ),

            const Divider(),

            SwitchListTile(
              value: _showBranding,
              onChanged: (value) => setState(() => _showBranding = value),
              title: const Text('Prikaži Branding'),
              subtitle: const Text('"Powered by BedBooking" badge'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odaberite Boju'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.teal,
                      Colors.indigo,
                      Colors.pink,
                      Colors.amber,
                      Colors.cyan,
                    ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          setState(() => _primaryColor = color);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _primaryColor == color
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface
                                        .withAlpha((0.3 * 255).toInt()),
                              width: _primaryColor == color ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }
}
