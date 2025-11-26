import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/booking_price_provider.dart';
import '../providers/owner_bank_details_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../widget/domain/models/widget_settings.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/common/detail_row_widget.dart';
import '../widgets/common/copyable_text_field.dart';
import '../widgets/common/theme_colors_helper.dart';

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

    // Helper function to get theme-aware colors
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Scaffold(
      backgroundColor: getColor(
        MinimalistColors.backgroundPrimary,
        MinimalistColorsDark.backgroundPrimary,
      ),
      appBar: AppBar(
        title: Text(
          'Uputstva za Uplatu',
          style: TextStyle(
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
        ),
        backgroundColor: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        iconTheme: IconThemeData(
          color: getColor(
            MinimalistColors.textPrimary,
            MinimalistColorsDark.textPrimary,
          ),
        ),
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
                  isDarkMode,
                  getColor,
                  effectiveBankConfig,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Greška pri učitavanju bankovnih podataka: $error',
                  style: TextStyle(
                    color: getColor(
                      MinimalistColors.error,
                      MinimalistColorsDark.error,
                    ),
                  ),
                ),
              ),
            );
          }

          return _buildWithBankConfig(
            context,
            ref,
            isDarkMode,
            getColor,
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
    bool isDarkMode,
    Color Function(Color, Color) getColor,
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
              style: TextStyle(
                color: getColor(
                  MinimalistColors.error,
                  MinimalistColorsDark.error,
                ),
              ),
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
                      isDarkMode,
                      getColor,
                      calculation,
                      bankConfig,
                      formattedDeadline,
                      spacing,
                    )
                  : _buildMobileLayout(
                      context,
                      isDarkMode,
                      getColor,
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
          style: TextStyle(
            color: getColor(
              MinimalistColors.error,
              MinimalistColorsDark.error,
            ),
          ),
        ),
      ),
    );
  }

  /// Build Desktop Layout (2 columns)
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
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
              _buildSuccessHeader(context, isDarkMode, getColor),
              SizedBox(height: spacing),
              _buildReferenceCard(context, isDarkMode, getColor),
              SizedBox(height: spacing),
              _buildBookingDetails(context, isDarkMode, getColor, calculation),
            ],
          ),
        ),
        const SizedBox(width: SpacingTokens.l),
        // Right Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPaymentWarning(
                context,
                isDarkMode,
                getColor,
                calculation.formattedDeposit,
                formattedDeadline,
              ),
              SizedBox(height: spacing),
              if (bankConfig != null && bankConfig.hasCompleteDetails) ...[
                _buildBankDetails(context, isDarkMode, getColor, bankConfig),
                SizedBox(height: spacing),
              ],
              if (bankConfig != null &&
                  bankConfig.enableQrCode &&
                  bankConfig.iban != null) ...[
                _buildQrCodeSection(
                  context,
                  isDarkMode,
                  getColor,
                  bankConfig,
                  calculation.depositAmount,
                ),
                SizedBox(height: spacing),
              ],
              _buildImportantNotes(
                context,
                isDarkMode,
                getColor,
                bankConfig,
                calculation.formattedRemaining,
              ),
              SizedBox(height: spacing),
              _buildDoneButton(context, isDarkMode, getColor),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Mobile Layout (stacked)
  Widget _buildMobileLayout(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    dynamic calculation,
    BankTransferConfig? bankConfig,
    String formattedDeadline,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSuccessHeader(context, isDarkMode, getColor),
        SizedBox(height: spacing),
        _buildReferenceCard(context, isDarkMode, getColor),
        SizedBox(height: spacing),
        _buildPaymentWarning(
          context,
          isDarkMode,
          getColor,
          calculation.formattedDeposit,
          formattedDeadline,
        ),
        SizedBox(height: spacing),
        _buildBookingDetails(context, isDarkMode, getColor, calculation),
        SizedBox(height: spacing),
        if (bankConfig != null && bankConfig.hasCompleteDetails) ...[
          _buildBankDetails(context, isDarkMode, getColor, bankConfig),
          SizedBox(height: spacing),
        ],
        if (bankConfig != null &&
            bankConfig.enableQrCode &&
            bankConfig.iban != null) ...[
          _buildQrCodeSection(
            context,
            isDarkMode,
            getColor,
            bankConfig,
            calculation.depositAmount,
          ),
          SizedBox(height: spacing),
        ],
        _buildImportantNotes(
          context,
          isDarkMode,
          getColor,
          bankConfig,
          calculation.formattedRemaining,
        ),
        const SizedBox(height: SpacingTokens.xl),
        _buildDoneButton(context, isDarkMode, getColor),
        const SizedBox(height: SpacingTokens.l),
      ],
    );
  }

  Widget _buildSuccessHeader(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderLight,
            MinimalistColorsDark.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: getColor(
                MinimalistColors.success,
                MinimalistColorsDark.success,
              ).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: getColor(
                  MinimalistColors.success,
                  MinimalistColorsDark.success,
                ),
                width: BorderTokens.widthMedium,
              ),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: getColor(
                MinimalistColors.success,
                MinimalistColorsDark.success,
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Text(
            'Rezervacija Potvrđena!',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXXL,
              fontWeight: TypographyTokens.bold,
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Molimo dovršite plaćanje kako biste osigurali rezervaciju',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
                size: IconSizeTokens.medium,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Referentni Broj',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.semiBold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: getColor(
                MinimalistColors.backgroundPrimary,
                MinimalistColorsDark.backgroundPrimary,
              ),
              borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
              border: Border.all(
                color: getColor(
                  MinimalistColors.borderMedium,
                  MinimalistColorsDark.borderMedium,
                ),
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
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.content_copy,
                    color: getColor(
                      MinimalistColors.buttonPrimary,
                      MinimalistColorsDark.buttonPrimary,
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: bookingReference));
                    SnackBarHelper.showSuccess(
                      context: context,
                      message: 'Referentni broj kopiran',
                      isDarkMode: isDarkMode,
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
              color: getColor(
                MinimalistColors.warning,
                MinimalistColorsDark.warning,
              ),
              fontWeight: TypographyTokens.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentWarning(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    String depositAmount,
    String deadline,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.warning,
          MinimalistColorsDark.warning,
        ).withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.warning,
            MinimalistColorsDark.warning,
          ),
          width: BorderTokens.widthMedium,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: getColor(
              MinimalistColors.warning,
              MinimalistColorsDark.warning,
            ),
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
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  'Rok: $deadline',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    color: getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
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

  Widget _buildBookingDetails(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    dynamic calculation,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
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
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          DetailRowWidget(
            label: 'Dolazak',
            value: _formatDate(checkIn),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: 'Odlazak',
            value: _formatDate(checkOut),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: 'Noći',
            value: '${calculation.nights}',
            isDarkMode: isDarkMode,
          ),
          Divider(
            height: SpacingTokens.l,
            color: getColor(
              MinimalistColors.borderDefault,
              MinimalistColorsDark.borderDefault,
            ),
          ),
          _buildPriceRow(
            'Ukupna Cijena',
            calculation.formattedTotal,
            isDarkMode,
            getColor,
            false,
          ),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow(
            'Depozit (${calculation.totalPrice > 0 ? (calculation.depositAmount / calculation.totalPrice * 100).round() : 0}%)',
            calculation.formattedDeposit,
            isDarkMode,
            getColor,
            true,
          ),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow(
            'Preostalo',
            calculation.formattedRemaining,
            isDarkMode,
            getColor,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    bool highlight,
  ) {
    return Container(
      padding: highlight
          ? const EdgeInsets.all(SpacingTokens.s)
          : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: getColor(
                MinimalistColors.buttonPrimary,
                MinimalistColorsDark.buttonPrimary,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
              border: Border.all(
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
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
              fontSize: highlight
                  ? TypographyTokens.fontSizeL
                  : TypographyTokens.fontSizeM,
              fontWeight: highlight
                  ? TypographyTokens.bold
                  : TypographyTokens.medium,
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight
                  ? TypographyTokens.fontSizeXL
                  : TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: highlight
                  ? getColor(
                      MinimalistColors.buttonPrimary,
                      MinimalistColorsDark.buttonPrimary,
                    )
                  : getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetails(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    BankTransferConfig bankConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance,
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
                size: IconSizeTokens.medium,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Podaci za Uplatu',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.semiBold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),
          if (bankConfig.accountHolder != null)
            CopyableTextField(
              label: 'Vlasnik Računa',
              value: bankConfig.accountHolder!,
              icon: Icons.person_outline,
              isDarkMode: isDarkMode,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: bankConfig.accountHolder!));
                SnackBarHelper.showSuccess(
                  context: context,
                  message: 'Vlasnik Računa kopiran',
                  isDarkMode: isDarkMode,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          if (bankConfig.bankName != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'Naziv Banke',
              value: bankConfig.bankName!,
              icon: Icons.account_balance_outlined,
              isDarkMode: isDarkMode,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: bankConfig.bankName!));
                SnackBarHelper.showSuccess(
                  context: context,
                  message: 'Naziv Banke kopiran',
                  isDarkMode: isDarkMode,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
          if (bankConfig.iban != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'IBAN',
              value: bankConfig.iban!,
              icon: Icons.credit_card,
              isDarkMode: isDarkMode,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: bankConfig.iban!));
                SnackBarHelper.showSuccess(
                  context: context,
                  message: 'IBAN kopiran',
                  isDarkMode: isDarkMode,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
          if (bankConfig.swift != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'SWIFT/BIC',
              value: bankConfig.swift!,
              icon: Icons.language,
              isDarkMode: isDarkMode,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: bankConfig.swift!));
                SnackBarHelper.showSuccess(
                  context: context,
                  message: 'SWIFT/BIC kopiran',
                  isDarkMode: isDarkMode,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
          if (bankConfig.accountNumber != null) ...[
            const SizedBox(height: SpacingTokens.s),
            CopyableTextField(
              label: 'Broj Računa',
              value: bankConfig.accountNumber!,
              icon: Icons.numbers,
              isDarkMode: isDarkMode,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: bankConfig.accountNumber!));
                SnackBarHelper.showSuccess(
                  context: context,
                  message: 'Broj Računa kopiran',
                  isDarkMode: isDarkMode,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    BankTransferConfig bankConfig,
    double amount,
  ) {
    final epcData = _generateEpcQrData(bankConfig, amount);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.l),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.s),
                decoration: BoxDecoration(
                  color: getColor(
                    MinimalistColors.buttonPrimary,
                    MinimalistColorsDark.buttonPrimary,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    BorderTokens.radiusSubtle,
                  ),
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: getColor(
                    MinimalistColors.buttonPrimary,
                    MinimalistColorsDark.buttonPrimary,
                  ),
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
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xxs),
                    Text(
                      'Skenirajte sa mobilnom bankom',
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeS,
                        color: getColor(
                          MinimalistColors.textSecondary,
                          MinimalistColorsDark.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.l),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.m),
            decoration: BoxDecoration(
              color: ColorTokens.pureWhite,
              borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
              border: Border.all(
                color: getColor(
                  MinimalistColors.borderDefault,
                  MinimalistColorsDark.borderDefault,
                ),
                width: BorderTokens.widthMedium,
              ),
            ),
            child: QrImageView(
              data: epcData,
              size: 200.0,
              backgroundColor: ColorTokens.pureWhite,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: getColor(
                MinimalistColors.buttonPrimary,
                MinimalistColorsDark.buttonPrimary,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderTokens.radiusSubtle),
              border: Border.all(
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: IconSizeTokens.small,
                  color: getColor(
                    MinimalistColors.buttonPrimary,
                    MinimalistColorsDark.buttonPrimary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.s),
                Expanded(
                  child: Text(
                    'QR kod sadrži sve podatke o uplati (IBAN, iznos, referenca). Skenirajte ga sa aplikacijom vaše banke.',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
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

  String _generateEpcQrData(BankTransferConfig bankConfig, double amount) {
    final String bic = bankConfig.swift ?? '';
    final String beneficiaryName = bankConfig.accountHolder ?? 'N/A';
    final String iban = bankConfig.iban!.replaceAll(' ', '');
    final String amountStr = amount.toStringAsFixed(2);
    final String reference = bookingReference;

    final epcData = [
      'BCD',
      '002',
      '1',
      'SCT',
      bic,
      beneficiaryName,
      iban,
      'EUR$amountStr',
      '',
      reference,
      'Booking deposit',
      '',
    ].join('\n');

    return epcData;
  }

  Widget _buildImportantNotes(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
    BankTransferConfig? bankConfig,
    String remainingAmount,
  ) {
    final bool useCustom = bankConfig?.useCustomNotes ?? false;
    final String? customNotes = bankConfig?.customNotes;

    final List<String> notes = [];

    if (useCustom && customNotes != null && customNotes.isNotEmpty) {
      notes.add(customNotes);
    } else {
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
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
                size: IconSizeTokens.medium,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Važne Informacije',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: TypographyTokens.semiBold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),
          if (useCustom && customNotes != null && customNotes.isNotEmpty)
            Text(
              customNotes,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
                height: 1.5,
              ),
            )
          else
            ...notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(
                        top: 8,
                        right: SpacingTokens.s,
                      ),
                      decoration: BoxDecoration(
                        color: getColor(
                          MinimalistColors.buttonPrimary,
                          MinimalistColorsDark.buttonPrimary,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: TypographyTokens.fontSizeM,
                          color: getColor(
                            MinimalistColors.textPrimary,
                            MinimalistColorsDark.textPrimary,
                          ),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(
    BuildContext context,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: getColor(
          MinimalistColors.buttonPrimary,
          MinimalistColorsDark.buttonPrimary,
        ),
        foregroundColor: getColor(
          MinimalistColors.buttonPrimaryText,
          MinimalistColorsDark.buttonPrimaryText,
        ),
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
              color: getColor(
                MinimalistColors.buttonPrimaryText,
                MinimalistColorsDark.buttonPrimaryText,
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          Icon(
            Icons.check_circle_outline,
            color: getColor(
              MinimalistColors.buttonPrimaryText,
              MinimalistColorsDark.buttonPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d. MMMM yyyy.').format(date);
  }
}
