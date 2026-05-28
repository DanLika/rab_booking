import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design/tokens.dart';
import '../../l10n/widget_translations.dart';
import '../../theme/minimalist_colors.dart';
import '../../../utils/date_normalizer.dart';
import 'price_breakdown_widget.dart';

/// Compact summary displayed in the pill bar showing dates, price, and reserve button.
///
/// Shows date range, nights badge, price breakdown, and optional reserve button.
class CompactPillSummary extends StatelessWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final String formattedRoomPrice;
  final double additionalServicesTotal;
  final String formattedAdditionalServices;
  final double extraGuestFees;
  final String? formattedExtraGuestFees;
  final double petFees;
  final String? formattedPetFees;
  final String formattedTotal;
  final String formattedDeposit;
  final int depositPercentage;
  final bool isDarkMode;
  final bool showDeposit;
  final bool showReserveButton;
  final VoidCallback onClose;
  final VoidCallback onReserve;
  final WidgetTranslations translations;

  const CompactPillSummary({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.formattedRoomPrice,
    required this.additionalServicesTotal,
    required this.formattedAdditionalServices,
    this.extraGuestFees = 0,
    this.formattedExtraGuestFees,
    this.petFees = 0,
    this.formattedPetFees,
    required this.formattedTotal,
    required this.formattedDeposit,
    required this.depositPercentage,
    required this.isDarkMode,
    this.showDeposit = true,
    required this.showReserveButton,
    required this.onClose,
    required this.onReserve,
    required this.translations,
  });

  // Layout breakpoint
  static const _columnLayoutBreakpoint = 280.0;

  // Close button
  static const _closeButtonPadding = 5.0;
  static const _closeButtonRadius = 16.0;
  static const _closeIconSize = 16.0;

  // Badge styling
  static const _badgeFontSize = 11.0;
  static const _badgeRadius = 12.0;

  // Reserve button
  static const _reserveButtonRadius = 20.0;
  static const _reserveFontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      children: [
        _CloseButton(onTap: onClose, isDarkMode: isDarkMode, colors: colors),
        const SizedBox(height: BBSpace.xs),
        _DateRangeSection(
          checkIn: checkIn,
          checkOut: checkOut,
          nights: nights,
          translations: translations,
          isDarkMode: isDarkMode,
          colors: colors,
        ),
        const SizedBox(height: BBSpace.sm),
        PriceBreakdownWidget(
          isDarkMode: isDarkMode,
          nights: nights,
          formattedRoomPrice: formattedRoomPrice,
          additionalServicesTotal: additionalServicesTotal,
          formattedAdditionalServices: formattedAdditionalServices,
          extraGuestFees: extraGuestFees,
          formattedExtraGuestFees: formattedExtraGuestFees,
          petFees: petFees,
          formattedPetFees: formattedPetFees,
          formattedTotal: formattedTotal,
          formattedDeposit: formattedDeposit,
          depositPercentage: depositPercentage,
          showDeposit: showDeposit,
          translations: translations,
        ),
        const SizedBox(height: BBSpace.sm),
        if (showReserveButton)
          _ReserveButton(
            onTap: onReserve,
            label: translations.reserve,
            colors: colors,
          ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final MinimalistColorSchemeAdapter colors;

  const _CloseButton({
    required this.onTap,
    required this.isDarkMode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            CompactPillSummary._closeButtonRadius,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              CompactPillSummary._closeButtonPadding,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white : colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(
                CompactPillSummary._closeButtonRadius,
              ),
              border: Border.all(color: colors.borderLight),
            ),
            child: Icon(
              Icons.close,
              size: CompactPillSummary._closeIconSize,
              color: isDarkMode ? Colors.black : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRangeSection extends StatelessWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final WidgetTranslations translations;
  final bool isDarkMode;
  final MinimalistColorSchemeAdapter colors;

  const _DateRangeSection({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.translations,
    required this.isDarkMode,
    required this.colors,
  });

  // audit/32 N1: locale must be passed at DateFormat construction time —
  // DateFormat captures locale once and ignores subsequent Intl.defaultLocale
  // changes, so a static formatter would lock the date-range pill to system
  // default (en_US) regardless of ?lang=. Construct per call with the active
  // widget locale.
  String _formatDate(DateTime date) {
    final formatter = DateFormat(
      'MMM dd, yyyy',
      translations.locale.languageCode,
    );

    try {
      // Bug #39 Fix: Normalize date first (remove time components)
      final normalized = DateNormalizer.normalize(date);

      // Bug #39 Fix: Convert to local time if in UTC for display
      // DateFormat.format() uses local time, so we need to ensure
      // the date is in local timezone to avoid timezone conversion issues
      final localDate = normalized.isUtc ? normalized.toLocal() : normalized;

      return formatter.format(localDate);
    } catch (e) {
      // Fallback to simple format if DateFormat.format() fails
      // This prevents app crashes from invalid DateTime or formatting errors
      debugPrint('Error formatting date: $date, error: $e');

      // Bug #39 Fix: Also normalize and convert to local for fallback format
      final normalized = DateNormalizer.normalize(date);
      final localDate = normalized.isUtc ? normalized.toLocal() : normalized;

      return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumnLayout =
            constraints.maxWidth < CompactPillSummary._columnLayoutBreakpoint;
        final dateText = '${_formatDate(checkIn)} - ${_formatDate(checkOut)}';

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.sm,
            vertical: BBSpace.xs,
          ),
          decoration: BoxDecoration(
            color: colors.buttonPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BBSpace.sm),
            border: Border.all(
              color: colors.buttonPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: useColumnLayout
              ? _buildColumnLayout(dateText)
              : _buildRowLayout(dateText),
        );
      },
    );
  }

  Widget _buildColumnLayout(String dateText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDateRow(dateText),
        const SizedBox(height: BBSpace.xxs),
        _NightsBadge(
          nights: nights,
          translations: translations,
          isDarkMode: isDarkMode,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildRowLayout(String dateText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDateRow(dateText),
        const SizedBox(width: BBSpace.xs),
        _NightsBadge(
          nights: nights,
          translations: translations,
          isDarkMode: isDarkMode,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildDateRow(String dateText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_month, size: 16, color: colors.buttonPrimary),
        const SizedBox(width: BBSpace.xxs),
        Flexible(
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NightsBadge extends StatelessWidget {
  final int nights;
  final WidgetTranslations translations;
  final bool isDarkMode;
  final MinimalistColorSchemeAdapter colors;

  const _NightsBadge({
    required this.nights,
    required this.translations,
    required this.isDarkMode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BBSpace.xs, vertical: 2),
      decoration: BoxDecoration(
        color: colors.statusAvailableBackground,
        borderRadius: BorderRadius.circular(CompactPillSummary._badgeRadius),
      ),
      child: Text(
        translations.nightCount(nights),
        style: TextStyle(
          fontSize: CompactPillSummary._badgeFontSize,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _ReserveButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final MinimalistColorSchemeAdapter colors;

  const _ReserveButton({
    required this.onTap,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        CompactPillSummary._reserveButtonRadius,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: colors.buttonPrimary,
          borderRadius: BorderRadius.circular(
            CompactPillSummary._reserveButtonRadius,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: CompactPillSummary._reserveFontSize,
            fontWeight: FontWeight.bold,
            color: colors.buttonPrimaryText,
          ),
        ),
      ),
    );
  }
}
