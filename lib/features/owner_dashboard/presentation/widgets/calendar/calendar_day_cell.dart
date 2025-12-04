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
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    final regularPrice = priceData?.price;
    final weekendPrice = priceData?.weekendPrice;
    final hasPrice = regularPrice != null;
    final isAvailable = priceData?.available ?? true;

    final price = (isWeekend && weekendPrice != null)
        ? weekendPrice
        : (regularPrice ?? basePrice);

    final hasWeekendPrice = weekendPrice != null;
    final blockCheckIn = priceData?.blockCheckIn ?? false;
    final blockCheckOut = priceData?.blockCheckOut ?? false;
    final hasRestrictions = blockCheckIn ||
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
            _buildPrice(context, price, isAvailable, hasWeekendPrice, isWeekend, hasPrice),
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
