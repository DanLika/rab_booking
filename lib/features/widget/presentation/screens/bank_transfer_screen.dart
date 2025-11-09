import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/booking_price_provider.dart';
import '../providers/theme_provider.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/design_tokens/design_tokens.dart';

/// Modern Bank Transfer Instructions Screen
/// Displays owner's actual bank details with glass morphism design
class BankTransferScreen extends ConsumerWidget {
  final String propertyId;
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String bookingReference;

  const BankTransferScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.bookingReference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

    final settingsAsync = ref.watch(widgetSettingsRepositoryProvider).getWidgetSettings(
      propertyId: propertyId,
      unitId: unitId,
    );

    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Uputstva za Uplatu'),
        backgroundColor: colors.backgroundSecondary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<WidgetSettings?>(
        future: settingsAsync,
        builder: (context, settingsSnapshot) {
          if (!settingsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsSnapshot.data;
          final bankConfig = settings?.bankTransferConfig;

          return priceCalc.when(
            data: (calculation) {
              if (calculation == null) {
                return Center(
                  child: Text(
                    'Greška pri učitavanju cijene',
                    style: TextStyle(color: colors.error),
                  ),
                );
              }

              // Calculate payment deadline
              final deadlineDays = bankConfig?.paymentDeadlineDays ?? 3;
              final paymentDeadline = DateTime.now().add(Duration(days: deadlineDays));
              final formattedDeadline = DateFormat('d. MMMM yyyy.').format(paymentDeadline);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Icon with Glass Container
                    _buildSuccessHeader(context, colors),

                    const SizedBox(height: SpacingTokens.l),

                    // Booking Reference Card
                    _buildReferenceCard(context, colors),

                    const SizedBox(height: SpacingTokens.l),

                    // Payment Deadline Warning
                    _buildPaymentWarning(
                      context,
                      colors,
                      calculation.formattedDeposit,
                      formattedDeadline,
                    ),

                    const SizedBox(height: SpacingTokens.l),

                    // Booking Details
                    _buildBookingDetails(context, colors, calculation),

                    const SizedBox(height: SpacingTokens.l),

                    // Bank Details Section
                    if (bankConfig != null && bankConfig.hasCompleteDetails) ...[
                      _buildBankDetails(context, colors, bankConfig),
                      const SizedBox(height: SpacingTokens.l),
                    ],

                    // QR Code Section (if enabled)
                    if (bankConfig != null &&
                        bankConfig.enableQrCode &&
                        bankConfig.iban != null) ...[
                      _buildQrCodeSection(
                        context,
                        colors,
                        bankConfig,
                        calculation.depositAmount,
                      ),
                      const SizedBox(height: SpacingTokens.l),
                    ],

                    // Important Notes
                    _buildImportantNotes(
                      context,
                      colors,
                      bankConfig,
                      calculation.formattedRemaining,
                    ),

                    const SizedBox(height: SpacingTokens.xl),

                    // Done Button
                    _buildDoneButton(context, colors),

                    const SizedBox(height: SpacingTokens.l),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Greška: $error',
                style: TextStyle(color: colors.error),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context, WidgetColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderTokens.card,
        boxShadow: colors.shadowMedium,
        border: Border.all(
          color: colors.borderLight,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.successBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.success,
                width: BorderTokens.widthMedium,
              ),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: colors.success,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Text(
            'Rezervacija Potvrđena!',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXXL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Molimo dovršite plaćanje kako biste osigurali rezervaciju',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(BuildContext context, WidgetColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderTokens.card,
        boxShadow: colors.shadowLight,
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: colors.primary,
                size: IconSizeTokens.medium,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Referentni Broj',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.semiBold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.backgroundSecondary,
              borderRadius: BorderTokens.button,
              border: Border.all(
                color: colors.borderMedium,
                width: BorderTokens.widthThin,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bookingReference,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeXL,
                      fontWeight: TypographyTokens.bold,
                      fontFamily: 'monospace',
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.content_copy,
                    color: colors.primary,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: bookingReference));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Referentni broj kopiran'),
                        backgroundColor: colors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Kopiraj',
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '⚠️ Obavezno navedite ovaj broj u opisu uplate',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: colors.warning,
              fontWeight: TypographyTokens.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentWarning(
    BuildContext context,
    WidgetColorScheme colors,
    String depositAmount,
    String deadline,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.warningBackground,
        borderRadius: BorderTokens.card,
        border: Border.all(
          color: colors.warning,
          width: BorderTokens.widthMedium,
        ),
        boxShadow: colors.shadowLight,
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: colors.warning,
            size: IconSizeTokens.large,
          ),
          const SizedBox(width: SpacingTokens.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uplata: $depositAmount',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  'Rok: $deadline',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(
    BuildContext context,
    WidgetColorScheme colors,
    dynamic calculation,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderTokens.card,
        boxShadow: colors.shadowLight,
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalji Rezervacije',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.semiBold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          _buildDetailRow('Dolazak', _formatDate(checkIn), colors),
          const SizedBox(height: SpacingTokens.s),
          _buildDetailRow('Odlazak', _formatDate(checkOut), colors),
          const SizedBox(height: SpacingTokens.s),
          _buildDetailRow('Noći', '${calculation.nights}', colors),
          const Divider(height: SpacingTokens.l),
          _buildPriceRow('Ukupna Cijena', calculation.formattedTotal, colors, false),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow('Depozit (${calculation.depositPercentage}%)', calculation.formattedDeposit, colors, true),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow('Preostalo', calculation.formattedRemaining, colors, false),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, WidgetColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.semiBold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    WidgetColorScheme colors,
    bool highlight,
  ) {
    return Container(
      padding: highlight
          ? const EdgeInsets.all(SpacingTokens.s)
          : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: colors.primarySurface,
              borderRadius: BorderTokens.button,
              border: Border.all(
                color: colors.primary,
                width: BorderTokens.widthMedium,
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: highlight ? TypographyTokens.fontSizeL : TypographyTokens.fontSizeM,
              fontWeight: highlight ? TypographyTokens.bold : TypographyTokens.medium,
              color: colors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? TypographyTokens.fontSizeXL : TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: highlight ? colors.primary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetails(
    BuildContext context,
    WidgetColorScheme colors,
    BankTransferConfig bankConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderTokens.card,
        boxShadow: colors.shadowMedium,
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance,
                color: colors.primary,
                size: IconSizeTokens.medium,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Podaci za Uplatu',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.semiBold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          if (bankConfig.accountHolder != null)
            _buildBankField(
              context,
              colors,
              'Vlasnik Računa',
              bankConfig.accountHolder!,
              Icons.person_outline,
            ),

          if (bankConfig.bankName != null) ...[
            const SizedBox(height: SpacingTokens.s),
            _buildBankField(
              context,
              colors,
              'Naziv Banke',
              bankConfig.bankName!,
              Icons.account_balance_outlined,
            ),
          ],

          if (bankConfig.iban != null) ...[
            const SizedBox(height: SpacingTokens.s),
            _buildBankField(
              context,
              colors,
              'IBAN',
              bankConfig.iban!,
              Icons.credit_card,
            ),
          ],

          if (bankConfig.swift != null) ...[
            const SizedBox(height: SpacingTokens.s),
            _buildBankField(
              context,
              colors,
              'SWIFT/BIC',
              bankConfig.swift!,
              Icons.language,
            ),
          ],

          if (bankConfig.accountNumber != null) ...[
            const SizedBox(height: SpacingTokens.s),
            _buildBankField(
              context,
              colors,
              'Broj Računa',
              bankConfig.accountNumber!,
              Icons.numbers,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankField(
    BuildContext context,
    WidgetColorScheme colors,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.input,
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.primary,
            size: IconSizeTokens.small,
          ),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: colors.textTertiary,
                    fontWeight: TypographyTokens.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.semiBold,
                    color: colors.textPrimary,
                    fontFamily: label.contains('IBAN') || label.contains('Broj') ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.content_copy,
              size: IconSizeTokens.small,
              color: colors.primary,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label kopiran'),
                  backgroundColor: colors.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Kopiraj',
          ),
        ],
      ),
    );
  }

  /// Build QR Code Section for EPC bank transfer
  Widget _buildQrCodeSection(
    BuildContext context,
    WidgetColorScheme colors,
    BankTransferConfig bankConfig,
    double amount,
  ) {
    final epcData = _generateEpcQrData(bankConfig, amount);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.card,
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthThin,
        ),
        boxShadow: colors.shadowLight,
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.s),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderTokens.circularSubtle,
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: colors.primary,
                  size: IconSizeTokens.medium,
                ),
              ),
              const SizedBox(width: SpacingTokens.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Kod za Uplatu',
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeL,
                        fontWeight: TypographyTokens.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xxs),
                    Text(
                      'Skenirajte sa mobilnom bankom',
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeS,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.l),

          // QR Code
          Container(
            padding: const EdgeInsets.all(SpacingTokens.m),
            decoration: BoxDecoration(
              color: ColorTokens.pureWhite,
              borderRadius: BorderTokens.card,
              border: Border.all(
                color: colors.borderDefault,
                width: BorderTokens.widthMedium,
              ),
            ),
            child: QrImageView(
              data: epcData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: ColorTokens.pureWhite,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

          const SizedBox(height: SpacingTokens.m),

          // Info text
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularSubtle,
              border: Border.all(
                color: colors.info.withValues(alpha: 0.3),
                width: BorderTokens.widthThin,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: IconSizeTokens.small,
                  color: colors.info,
                ),
                const SizedBox(width: SpacingTokens.s),
                Expanded(
                  child: Text(
                    'QR kod sadrži sve podatke o upl ati (IBAN, iznos, referenca). Skenirajte ga sa aplikacijom vaše banke.',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generate EPC QR Code data string
  /// Format: https://en.wikipedia.org/wiki/EPC_QR_code
  String _generateEpcQrData(BankTransferConfig bankConfig, double amount) {
    final String bic = bankConfig.swift ?? '';
    final String beneficiaryName = bankConfig.accountHolder ?? 'N/A';
    final String iban = bankConfig.iban!.replaceAll(' ', ''); // Remove spaces
    final String amountStr = amount.toStringAsFixed(2);
    final String reference = bookingReference;

    // EPC QR Code format (SEPA Credit Transfer)
    final epcData = [
      'BCD',                    // Service Tag
      '002',                    // Version
      '1',                      // Character Set (UTF-8)
      'SCT',                    // Identification (SEPA Credit Transfer)
      bic,                      // BIC
      beneficiaryName,          // Beneficiary Name
      iban,                     // Beneficiary Account (IBAN)
      'EUR$amountStr',          // Amount
      '',                       // Purpose (empty)
      reference,                // Structured Reference
      'Booking deposit',        // Unstructured Remittance
      '',                       // Beneficiary to Originator Information
    ].join('\n');

    return epcData;
  }

  Widget _buildImportantNotes(
    BuildContext context,
    WidgetColorScheme colors,
    BankTransferConfig? bankConfig,
    String remainingAmount,
  ) {
    // Determine which notes to show
    final bool useCustom = bankConfig?.useCustomNotes ?? false;
    final String? customNotes = bankConfig?.customNotes;

    final List<String> notes = [];

    if (useCustom && customNotes != null && customNotes.isNotEmpty) {
      // Show custom notes from owner
      notes.add(customNotes);
    } else {
      // Show default notes
      notes.addAll([
        'Obavezno navedite referentni broj u opisu uplate',
        'Primit ćete email potvrdu nakon što uplata bude zaprimljena',
        'Preostali iznos ($remainingAmount) plaća se po dolasku',
        'Politika otkazivanja: 7 dana prije dolaska za potpuni povrat',
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderTokens.card,
        boxShadow: colors.shadowLight,
        border: Border.all(
          color: colors.borderDefault,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colors.primary,
                size: IconSizeTokens.medium,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Važne Informacije',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.semiBold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),

          if (useCustom && customNotes != null && customNotes.isNotEmpty)
            // Custom notes - show as single block
            Text(
              customNotes,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textPrimary,
                height: 1.5,
              ),
            )
          else
            // Default notes - show as bullet list
            ...notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: SpacingTokens.s),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeM,
                        color: colors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context, WidgetColorScheme colors) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.buttonPrimary,
        foregroundColor: colors.buttonPrimaryText,
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
        shape: RoundedRectangleBorder(
          borderRadius: BorderTokens.button,
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Zatvori',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          const Icon(Icons.check_circle_outline),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d. MMMM yyyy.').format(date);
  }
}
