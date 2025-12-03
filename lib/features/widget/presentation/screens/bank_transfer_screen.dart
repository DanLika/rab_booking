import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/booking_price_provider.dart';
import '../providers/owner_bank_details_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../shared/utils/ui/snackbar_helper.dart';
import '../widgets/common/detail_row_widget.dart';
import '../widgets/bank_transfer/qr_code_payment_section.dart';
import '../widgets/bank_transfer/bank_details_section.dart';
import '../widgets/bank_transfer/payment_warning_section.dart';
import '../widgets/bank_transfer/important_notes_section.dart';

/// Modern Bank Transfer Instructions Screen
/// Displays owner's actual bank details with responsive design
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
    final settingsAsync = ref
        .watch(widgetSettingsRepositoryProvider)
        .getWidgetSettings(propertyId: propertyId, unitId: unitId);

    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Uputstva za Uplatu',
          style: TextStyle(color: colors.textPrimary),
        ),
        backgroundColor: colors.backgroundSecondary,
        iconTheme: IconThemeData(color: colors.textPrimary),
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

          // Check if we should fetch bank details from owner's profile
          final ownerId = bankConfig?.ownerId;
          final shouldFetchFromOwner = ownerId != null && ownerId.isNotEmpty;

          // If ownerId exists, fetch CompanyDetails for bank info
          if (shouldFetchFromOwner) {
            final ownerBankAsync = ref.watch(ownerBankDetailsProvider(ownerId));

            return ownerBankAsync.when(
              data: (companyDetails) {
                // Create effective bank config with data from CompanyDetails
                final effectiveBankConfig = _createEffectiveBankConfig(
                  bankConfig!,
                  companyDetails,
                );

                return _buildWithBankConfig(
                  context,
                  ref,
                  colors,
                  effectiveBankConfig,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Greška pri učitavanju bankovnih podataka: $error',
                  style: TextStyle(color: colors.error),
                ),
              ),
            );
          }

          return _buildWithBankConfig(
            context,
            ref,
            colors,
            bankConfig,
          );
        },
      ),
    );
  }

  /// Create effective bank config by merging widget config with owner's CompanyDetails
  BankTransferConfig _createEffectiveBankConfig(
    BankTransferConfig widgetConfig,
    CompanyDetails? companyDetails,
  ) {
    if (companyDetails == null) {
      return widgetConfig;
    }

    return BankTransferConfig(
      enabled: widgetConfig.enabled,
      depositPercentage: widgetConfig.depositPercentage,
      ownerId: widgetConfig.ownerId,
      paymentDeadlineDays: widgetConfig.paymentDeadlineDays,
      enableQrCode: widgetConfig.enableQrCode,
      customNotes: widgetConfig.customNotes,
      useCustomNotes: widgetConfig.useCustomNotes,
      // Bank details from owner's CompanyDetails
      bankName: companyDetails.bankName.isNotEmpty
          ? companyDetails.bankName
          : widgetConfig.bankName,
      iban: companyDetails.bankAccountIban.isNotEmpty
          ? companyDetails.bankAccountIban
          : widgetConfig.iban,
      swift: companyDetails.swift.isNotEmpty
          ? companyDetails.swift
          : widgetConfig.swift,
      accountHolder: companyDetails.accountHolder.isNotEmpty
          ? companyDetails.accountHolder
          : widgetConfig.accountHolder,
      accountNumber: widgetConfig.accountNumber, // Keep legacy if exists
    );
  }

  /// Build the screen content with the given bank config
  Widget _buildWithBankConfig(
    BuildContext context,
    WidgetRef ref,
    MinimalistColorSchemeAdapter colors,
    BankTransferConfig? bankConfig,
  ) {
    final priceCalc = ref.watch(
      bookingPriceProvider(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
      ),
    );

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
        final paymentDeadline = DateTime.now().add(
          Duration(days: deadlineDays),
        );
        final formattedDeadline = DateFormat(
          'd. MMMM yyyy.',
        ).format(paymentDeadline);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final spacing = isDesktop ? SpacingTokens.m : SpacingTokens.l;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingTokens.m),
              child: isDesktop
                  ? _buildDesktopLayout(
                      context,
                      colors,
                      calculation,
                      bankConfig,
                      formattedDeadline,
                      spacing,
                    )
                  : _buildMobileLayout(
                      context,
                      colors,
                      calculation,
                      bankConfig,
                      formattedDeadline,
                      spacing,
                    ),
            );
          },
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
  }

  /// Build Desktop Layout (2 columns)
  Widget _buildDesktopLayout(
    BuildContext context,
    MinimalistColorSchemeAdapter colors,
    dynamic calculation,
    BankTransferConfig? bankConfig,
    String formattedDeadline,
    double spacing,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSuccessHeader(context, colors),
              SizedBox(height: spacing),
              _buildReferenceCard(context, colors),
              SizedBox(height: spacing),
              _buildBookingDetails(context, colors, calculation),
            ],
          ),
        ),
        const SizedBox(width: SpacingTokens.l),
        // Right Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentWarningSection(
                isDarkMode: colors.dark,
                depositAmount: calculation.formattedDeposit,
                deadline: formattedDeadline,
              ),
              SizedBox(height: spacing),
              if (bankConfig != null && bankConfig.hasCompleteDetails) ...[
                BankDetailsSection(
                  isDarkMode: colors.dark,
                  bankConfig: bankConfig,
                ),
                SizedBox(height: spacing),
              ],
              if (bankConfig != null &&
                  bankConfig.enableQrCode &&
                  bankConfig.iban != null) ...[
                QrCodePaymentSection(
                  isDarkMode: colors.dark,
                  bankConfig: bankConfig,
                  amount: calculation.depositAmount,
                  bookingReference: bookingReference,
                ),
                SizedBox(height: spacing),
              ],
              ImportantNotesSection(
                isDarkMode: colors.dark,
                bankConfig: bankConfig,
                remainingAmount: calculation.formattedRemaining,
              ),
              SizedBox(height: spacing),
              _buildDoneButton(context, colors),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Mobile Layout (stacked)
  Widget _buildMobileLayout(
    BuildContext context,
    MinimalistColorSchemeAdapter colors,
    dynamic calculation,
    BankTransferConfig? bankConfig,
    String formattedDeadline,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSuccessHeader(context, colors),
        SizedBox(height: spacing),
        _buildReferenceCard(context, colors),
        SizedBox(height: spacing),
        PaymentWarningSection(
          isDarkMode: colors.dark,
          depositAmount: calculation.formattedDeposit,
          deadline: formattedDeadline,
        ),
        SizedBox(height: spacing),
        _buildBookingDetails(context, colors, calculation),
        SizedBox(height: spacing),
        if (bankConfig != null && bankConfig.hasCompleteDetails) ...[
          BankDetailsSection(
            isDarkMode: colors.dark,
            bankConfig: bankConfig,
          ),
          SizedBox(height: spacing),
        ],
        if (bankConfig != null &&
            bankConfig.enableQrCode &&
            bankConfig.iban != null) ...[
          QrCodePaymentSection(
            isDarkMode: colors.dark,
            bankConfig: bankConfig,
            amount: calculation.depositAmount,
            bookingReference: bookingReference,
          ),
          SizedBox(height: spacing),
        ],
        ImportantNotesSection(
          isDarkMode: colors.dark,
          bankConfig: bankConfig,
          remainingAmount: calculation.formattedRemaining,
        ),
        const SizedBox(height: SpacingTokens.xl),
        _buildDoneButton(context, colors),
        const SizedBox(height: SpacingTokens.l),
      ],
    );
  }

  Widget _buildSuccessHeader(
    BuildContext context,
    MinimalistColorSchemeAdapter colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
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

  Widget _buildReferenceCard(
    BuildContext context,
    MinimalistColorSchemeAdapter colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: colors.buttonPrimary,
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
              color: colors.backgroundPrimary,
              borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
              border: Border.all(color: colors.borderMedium),
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
                  icon: Icon(Icons.content_copy, color: colors.buttonPrimary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: bookingReference));
                    SnackBarHelper.showSuccess(
                      context: context,
                      message: 'Referentni broj kopiran',
                      duration: const Duration(seconds: 2),
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

  Widget _buildBookingDetails(
    BuildContext context,
    MinimalistColorSchemeAdapter colors,
    dynamic calculation,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderDefault),
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
          DetailRowWidget(
            label: 'Dolazak',
            value: _formatDate(checkIn),
            isDarkMode: colors.dark,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: 'Odlazak',
            value: _formatDate(checkOut),
            isDarkMode: colors.dark,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: 'Noći',
            value: '${calculation.nights}',
            isDarkMode: colors.dark,
          ),
          Divider(height: SpacingTokens.l, color: colors.borderDefault),
          _buildPriceRow('Ukupna Cijena', calculation.formattedTotal, colors, false),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow(
            'Depozit (${calculation.totalPrice > 0 ? (calculation.depositAmount / calculation.totalPrice * 100).round() : 0}%)',
            calculation.formattedDeposit,
            colors,
            true,
          ),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow('Preostalo', calculation.formattedRemaining, colors, false),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    MinimalistColorSchemeAdapter colors,
    bool highlight,
  ) {
    return Container(
      padding: highlight ? const EdgeInsets.all(SpacingTokens.s) : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: colors.buttonPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
              border: Border.all(
                color: colors.buttonPrimary,
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
              color: highlight ? colors.buttonPrimary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(
    BuildContext context,
    MinimalistColorSchemeAdapter colors,
  ) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.buttonPrimary,
        foregroundColor: colors.buttonPrimaryText,
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderTokens.radiusRounded),
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
              color: colors.buttonPrimaryText,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Icon(Icons.check_circle_outline, color: colors.buttonPrimaryText),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d. MMMM yyyy.').format(date);
  }
}
