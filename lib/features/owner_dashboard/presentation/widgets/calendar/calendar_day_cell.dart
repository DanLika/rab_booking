import 'package:flutter/material.dart';
import '../../../../../shared/models/daily_price_model.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Individual calendar day cell widget
/// Extracted to reduce nesting in main calendar widget
class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final DailyPriceModel? priceData;
  final double basePrice;
  final bool isSelected;
  final bool isBulkEditMode;
  final VoidCallback onTap;
  final bool isMobile;
  final bool isSmallMobile;

  /// Days considered as weekend for pricing purposes.
  /// Uses ISO weekday format: 1=Monday, 5=Friday, 6=Saturday, 7=Sunday.
  /// Default: [5, 6] (Friday, Saturday nights for hotel pricing)
  final List<int>? weekendDays;

  /// Unit's default weekend base price (fallback when no custom daily price).
  /// Used when the day is a weekend and no custom price is set in daily_prices.
  final double? weekendBasePrice;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.priceData,
    required this.basePrice,
    required this.isSelected,
    required this.isBulkEditMode,
    required this.onTap,
    required this.isMobile,
    required this.isSmallMobile,
    this.weekendDays,
    this.weekendBasePrice,
  });

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    // Use configurable weekend days (default: Fri=5, Sat=6 for hotel pricing)
    final effectiveWeekendDays = weekendDays ?? const [5, 6];
    final isWeekend = effectiveWeekendDays.contains(date.weekday);

    final regularPrice = priceData?.price;
    final weekendPrice = priceData?.weekendPrice;
    final hasPrice = regularPrice != null;
    final isAvailable = priceData?.available ?? true;

    // Price hierarchy:
    // 1. Custom weekend price from daily_prices (per-day override)
    // 2. Unit's default weekend base price (if it's a weekend day)
    // 3. Custom regular price from daily_prices (per-day override)
    // 4. Unit's base price (fallback)
    final double price;
    if (isWeekend && weekendPrice != null) {
      price = weekendPrice;
    } else if (isWeekend && weekendBasePrice != null && regularPrice == null) {
      price = weekendBasePrice!;
    } else {
      price = regularPrice ?? basePrice;
    }

    // Check if this day uses weekend pricing (custom or unit default)
    final hasWeekendPrice =
        weekendPrice != null ||
        (isWeekend && weekendBasePrice != null && regularPrice == null);
    final blockCheckIn = priceData?.blockCheckIn ?? false;
    final blockCheckOut = priceData?.blockCheckOut ?? false;
    final hasRestrictions =
        blockCheckIn ||
        blockCheckOut ||
        (priceData?.minNightsOnArrival != null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: _getCellBackgroundColor(
            context,
            isAvailable,
            hasWeekendPrice,
            isWeekend,
            hasPrice,
            hasRestrictions,
          ),
          border: Border.all(
            color: isSelected
                ? context.primaryColor
                : isToday
                ? context.primaryColor.withValues(alpha: 0.5)
                : hasRestrictions
                ? context.warningColor.withValues(alpha: 0.6)
                : context.borderColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(isSmallMobile ? 4 : (isMobile ? 6 : 8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDayNumber(context, isToday, isAvailable),
            _buildPrice(
              context,
              price,
              isAvailable,
              hasWeekendPrice,
              isWeekend,
              hasPrice,
            ),
            if (blockCheckIn || blockCheckOut)
              _buildStatusIndicators(context, blockCheckIn, blockCheckOut),
          ],
        ),
      ),
    );
  }

  Color? _getCellBackgroundColor(
    BuildContext context,
    bool isAvailable,
    bool hasWeekendPrice,
    bool isWeekend,
    bool hasPrice,
    bool hasRestrictions,
  ) {
    // Cell opacity increased from 8% to 15% for better visibility
    if (isSelected) {
      return context.primaryColor.withValues(alpha: 0.25); // Was 0.2
    }
    if (!isAvailable) {
      return context.surfaceVariantColor.withValues(alpha: 0.5);
    }
    if (hasWeekendPrice && isWeekend) {
      return context.secondaryColor.withValues(alpha: 0.15); // Was 0.1
    }
    if (hasPrice) {
      return context.primaryColor.withValues(alpha: 0.15); // Was 0.08
    }
    if (hasRestrictions) {
      return context.warningColor.withValues(alpha: 0.15); // Was 0.1
    }
    return null;
  }

  Widget _buildDayNumber(BuildContext context, bool isToday, bool isAvailable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSmallMobile ? 9 : (isMobile ? 10 : null),
                  color: !isAvailable ? context.textColorTertiary : null,
                ),
              ),
            ),
          ),
        ),
        if (isBulkEditMode && isSelected)
          Icon(
            Icons.check_circle,
            size: isSmallMobile ? 12 : (isMobile ? 14 : 16),
            color: context.primaryColor,
          ),
      ],
    );
  }

  Widget _buildPrice(
    BuildContext context,
    double price,
    bool isAvailable,
    bool hasWeekendPrice,
    bool isWeekend,
    bool hasPrice,
  ) {
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '€${price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallMobile ? 11 : (isMobile ? 12 : null),
                  color: !isAvailable
                      ? context.textColorTertiary
                      : hasWeekendPrice && isWeekend
                      ? context.secondaryColor
                      : hasPrice
                      ? context.primaryColor
                      : context.textColorSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              if (!hasPrice && isAvailable && !isSmallMobile)
                Text(
                  'base',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: isMobile ? 7 : 8,
                    color: context.textColorTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(
    BuildContext context,
    bool blockCheckIn,
    bool blockCheckOut,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (blockCheckIn)
          Icon(
            Icons.login,
            size: isSmallMobile ? 10 : (isMobile ? 12 : 14),
            color: context.errorColor,
          ),
        if (blockCheckOut)
          Icon(
            Icons.logout,
            size: isSmallMobile ? 10 : (isMobile ? 12 : 14),
            color: context.errorColor,
          ),
      ],
    );
  }
}
