import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../widget/domain/models/widget_mode.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/common_app_bar.dart';

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
  ConsumerState<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
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
  Color _primaryColor = const Color(0xFF1976D2);
  String _themeMode = 'system'; // 'light', 'dark', 'system'

  // Blur/Glassmorphism Options
  bool _blurEnabled = true;
  String _blurIntensity = 'medium'; // 'subtle', 'light', 'medium', 'strong', 'extra_strong'
  bool _enableCardBlur = true;
  bool _enableAppBarBlur = true;
  bool _enableModalBlur = true;
  bool _enableOverlayBlur = true;

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
      _bankDepositPercentage = settings.bankTransferConfig?.depositPercentage ?? 20;
      _bankNameController.text = settings.bankTransferConfig?.bankName ?? '';
      _ibanController.text = settings.bankTransferConfig?.iban ?? '';
      _swiftController.text = settings.bankTransferConfig?.swift ?? '';
      _accountHolderController.text = settings.bankTransferConfig?.accountHolder ?? '';

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
      _customMessageController.text = settings.contactOptions.customMessage ?? '';

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
    });
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF1976D2);
    }
  }

  String _colorToHex(Color color) {
    // Extract ARGB components without using deprecated .value
    final r = color.r.toInt();
    final g = color.g.toInt();
    final b = color.b.toInt();
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(widgetSettingsRepositoryProvider);

      final settings = WidgetSettings(
        id: widget.unitId,
        propertyId: widget.propertyId,
        widgetMode: _selectedMode,
        stripeConfig: _stripeEnabled ? StripePaymentConfig(
          enabled: true,
          depositPercentage: _stripeDepositPercentage,
        ) : null,
        bankTransferConfig: _bankTransferEnabled ? BankTransferConfig(
          enabled: true,
          depositPercentage: _bankDepositPercentage,
          bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
          iban: _ibanController.text.isEmpty ? null : _ibanController.text,
          swift: _swiftController.text.isEmpty ? null : _swiftController.text,
          accountHolder: _accountHolderController.text.isEmpty ? null : _accountHolderController.text,
        ) : null,
        allowPayOnArrival: _payOnArrivalEnabled,
        requireOwnerApproval: _requireApproval,
        allowGuestCancellation: _allowCancellation,
        cancellationDeadlineHours: _cancellationHours,
        contactOptions: ContactOptions(
          showPhone: _showPhone,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
          showEmail: _showEmail,
          emailAddress: _emailController.text.isEmpty ? null : _emailController.text,
          showWhatsApp: _showWhatsApp,
          whatsAppNumber: _whatsAppController.text.isEmpty ? null : _whatsAppController.text,
          customMessage: _customMessageController.text.isEmpty ? null : _customMessageController.text,
        ),
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

                  _buildSectionTitle('Kontakt Informacije', Icons.contact_phone),
                  _buildContactOptionsSection(),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Tema', Icons.palette),
                  _buildThemeSection(),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: AppColors.authPrimary,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sačuvaj Postavke', style: TextStyle(fontSize: 16)),
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
          Icon(icon, size: 24, color: AppColors.authPrimary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
            const Text(
              'Odaberite kako će widget funkcionirati:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...WidgetMode.values.map((mode) => InkWell(
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
                              : Colors.grey,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
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
            // Stripe Payment
            SwitchListTile(
              value: _stripeEnabled,
              onChanged: (value) => setState(() => _stripeEnabled = value),
              title: const Text('Stripe Plaćanje'),
              subtitle: const Text('Plaćanje karticom preko Stripe-a'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_stripeEnabled) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Depozit: $_stripeDepositPercentage%'),
                    Slider(
                      value: _stripeDepositPercentage.toDouble(),
                      min: 0,
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
            ],

            const Divider(),

            // Bank Transfer
            SwitchListTile(
              value: _bankTransferEnabled,
              onChanged: (value) => setState(() => _bankTransferEnabled = value),
              title: const Text('Bankovna Uplata'),
              subtitle: const Text('Uplata na bankovni račun'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_bankTransferEnabled) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Depozit: $_bankDepositPercentage%'),
                    Slider(
                      value: _bankDepositPercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$_bankDepositPercentage%',
                      onChanged: (value) {
                        setState(() => _bankDepositPercentage = value.round());
                      },
                    ),
                    const SizedBox(height: 12),
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
                ),
              ),
            ],

            const Divider(),

            // Pay on Arrival
            SwitchListTile(
              value: _payOnArrivalEnabled,
              onChanged: (value) => setState(() => _payOnArrivalEnabled = value),
              title: const Text('Plaćanje po Dolasku'),
              subtitle: const Text('Gost plaća prilikom prijave'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
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
            SwitchListTile(
              value: _requireApproval,
              onChanged: (value) => setState(() => _requireApproval = value),
              title: const Text('Zahtijeva Odobrenje'),
              subtitle: const Text('Morate ručno odobriti svaku rezervaciju'),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            SwitchListTile(
              value: _allowCancellation,
              onChanged: (value) => setState(() => _allowCancellation = value),
              title: const Text('Dozvolite Otkazivanje'),
              subtitle: const Text('Gosti mogu otkazati rezervaciju'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_allowCancellation) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Otkazivanje do: $_cancellationHours sati prije prijave'),
                    Slider(
                      value: _cancellationHours.toDouble(),
                      min: 0,
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

  Widget _buildContactOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kontakt opcije koje će biti prikazane u widgetu:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Phone
            SwitchListTile(
              value: _showPhone,
              onChanged: (value) => setState(() => _showPhone = value),
              title: const Text('Prikaži Telefon'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_showPhone) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Broj telefona',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Email
            SwitchListTile(
              value: _showEmail,
              onChanged: (value) => setState(() => _showEmail = value),
              title: const Text('Prikaži Email'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_showEmail) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email adresa',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // WhatsApp
            SwitchListTile(
              value: _showWhatsApp,
              onChanged: (value) => setState(() => _showWhatsApp = value),
              title: const Text('Prikaži WhatsApp'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_showWhatsApp) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: TextFormField(
                  controller: _whatsAppController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp broj',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.message),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
            const SizedBox(height: 16),

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

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prilagodite izgled widgeta:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Theme Mode Selector
            const Text(
              'Tema:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...['light', 'dark', 'system'].map((mode) => InkWell(
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
                              : Colors.grey,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                      color: Colors.grey,
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
            )),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Glassmorphism / Blur Effects Section
            const Text(
              'Glassmorphism Efekti:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Frosted glass efekti za moderan izgled',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Enable/Disable Blur
            SwitchListTile(
              value: _blurEnabled,
              onChanged: (value) => setState(() => _blurEnabled = value),
              title: const Text('Omogući Blur Efekte'),
              subtitle: const Text('Glassmorphism za kartice, modale i app bar'),
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
              ...['subtle', 'light', 'medium', 'strong', 'extra_strong'].map((intensity) => InkWell(
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
                                : Colors.grey,
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
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const Icon(
                        Icons.blur_on,
                        size: 20,
                        color: Colors.grey,
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
              )),

              const SizedBox(height: 16),
              const Text(
                'Gdje primijeniti blur:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // Card Blur
              CheckboxListTile(
                value: _enableCardBlur,
                onChanged: (value) => setState(() => _enableCardBlur = value ?? true),
                title: const Text('Kartice (Cards)'),
                subtitle: const Text('Blur za informacijske kartice'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // App Bar Blur
              CheckboxListTile(
                value: _enableAppBarBlur,
                onChanged: (value) => setState(() => _enableAppBarBlur = value ?? true),
                title: const Text('App Bar'),
                subtitle: const Text('Blur za gornji navigation bar'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Modal Blur
              CheckboxListTile(
                value: _enableModalBlur,
                onChanged: (value) => setState(() => _enableModalBlur = value ?? true),
                title: const Text('Modale i Dijalozi'),
                subtitle: const Text('Blur za pop-up prozore'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              // Overlay Blur
              CheckboxListTile(
                value: _enableOverlayBlur,
                onChanged: (value) => setState(() => _enableOverlayBlur = value ?? true),
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
                    border: Border.all(color: Colors.grey),
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
            children: [
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
            ].map((color) => GestureDetector(
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
                    color: _primaryColor == color ? Colors.black : Colors.grey,
                    width: _primaryColor == color ? 3 : 1,
                  ),
                ),
              ),
            )).toList(),
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
