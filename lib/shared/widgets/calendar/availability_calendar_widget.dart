import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Premium availability calendar widget with real-time booking status
/// Shows which dates are available, booked, or selected
class AvailabilityCalendarWidget extends ConsumerStatefulWidget {
  const AvailabilityCalendarWidget({
    super.key,
    required this.unitId,
    this.checkInDate,
    this.checkOutDate,
    required this.onDateRangeSelected,
    this.unavailableDates = const [],
    this.minDate,
    this.maxDate,
  });

  /// Property unit ID for fetching unavailable dates
  final String unitId;

  /// Currently selected check-in date
  final DateTime? checkInDate;

  /// Currently selected check-out date
  final DateTime? checkOutDate;

  /// Callback when date range is selected
  final Function(DateTime checkIn, DateTime checkOut) onDateRangeSelected;

  /// List of unavailable dates (pre-fetched or from provider)
  final List<DateTime> unavailableDates;

  /// Minimum selectable date (default: today)
  final DateTime? minDate;

  /// Maximum selectable date (default: 1 year from now)
  final DateTime? maxDate;

  @override
  ConsumerState<AvailabilityCalendarWidget> createState() =>
      _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState
    extends ConsumerState<AvailabilityCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.checkInDate ?? DateTime.now();
    _rangeStart = widget.checkInDate;
    _rangeEnd = widget.checkOutDate;
  }

  @override
  Widget build(BuildContext context) {
    final minDate = widget.minDate ?? DateTime.now();
    final maxDate =
        widget.maxDate ?? DateTime.now().add(const Duration(days: 365));

    return Column(
      children: [
        // Calendar header with legend
        _buildHeader(),
        const SizedBox(height: 16),

        // Calendar widget
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: minDate,
            lastDay: maxDate,
            focusedDay: _focusedDay,
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: _rangeSelectionMode,

            // Calendar format
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,

            // Header configuration
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: AppColors.primary,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ),

            // Day of week styling
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Calendar styling
            calendarStyle: CalendarStyle(
              // Default day
              defaultTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),

              // Weekend day
              weekendTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),

              // Today
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              todayTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),

              // Selected day
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),

              // Range start/end
              rangeStartDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              rangeStartTextStyle: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              rangeEndTextStyle: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),

              // Range highlight
              rangeHighlightColor: AppColors.primary.withValues(alpha: 0.2),
              withinRangeTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),

              // Outside days
              outsideTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),

              // Disabled days
              disabledTextStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textDisabled,
                decoration: TextDecoration.lineThrough,
              ),
            ),

            // Determine which days should be disabled
            enabledDayPredicate: (day) {
              // Disable dates before minDate
              if (day.isBefore(minDate)) {
                return false;
              }

              // Disable dates after maxDate
              if (day.isAfter(maxDate)) {
                return false;
              }

              // Disable unavailable dates
              final isUnavailable = widget.unavailableDates.any((unavailable) =>
                  isSameDay(unavailable, day));

              return !isUnavailable;
            },

            // Custom day builder for unavailable dates
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, isUnavailable: false);
              },
              disabledBuilder: (context, day, focusedDay) {
                final isUnavailable = widget.unavailableDates.any(
                    (unavailable) => isSameDay(unavailable, day));

                if (isUnavailable) {
                  return _buildDayCell(day, isUnavailable: true);
                }

                return null; // Use default disabled styling
              },
            ),

            // Handle day selection
            onDaySelected: (selectedDay, focusedDay) {
              // Don't allow selection of unavailable dates
              final isUnavailable = widget.unavailableDates.any(
                  (unavailable) => isSameDay(unavailable, selectedDay));

              if (isUnavailable) {
                _showUnavailableSnackBar(context);
                return;
              }

              setState(() {
                _focusedDay = focusedDay;
              });
            },

            // Handle range selection
            onRangeSelected: (start, end, focusedDay) {
              if (start == null) return;

              // Check if range contains any unavailable dates
              if (end != null) {
                final hasUnavailableDates = _hasUnavailableDatesInRange(
                  start,
                  end,
                );

                if (hasUnavailableDates) {
                  _showRangeUnavailableSnackBar(context);
                  return;
                }
              }

              setState(() {
                _focusedDay = focusedDay;
                _rangeStart = start;
                _rangeEnd = end;
              });

              // Notify parent if full range selected (start is guaranteed non-null here)
              if (end != null) {
                widget.onDateRangeSelected(start, end);
              }
            },

            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Selected date range display
        if (_rangeStart != null)
          _buildSelectedRangeDisplay(),
      ],
    );
  }

  /// Build custom day cell with availability indicator
  Widget _buildDayCell(DateTime day, {required bool isUnavailable}) {
    final isToday = isSameDay(day, DateTime.now());
    final isSelected = isSameDay(day, _rangeStart) || isSameDay(day, _rangeEnd);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isUnavailable
            ? AppColors.error.withValues(alpha: 0.1)
            : isSelected
                ? AppColors.primary
                : isToday
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : null,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppTypography.bodyMedium.copyWith(
                color: isUnavailable
                    ? AppColors.error
                    : isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                decoration: isUnavailable
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (isUnavailable)
              const Positioned(
                bottom: 2,
                child: Icon(
                  Icons.block,
                  size: 8,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build calendar header with legend
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            color: AppColors.success,
            label: 'Dostupno',
            icon: Icons.check_circle_outline,
          ),
          _buildLegendItem(
            color: AppColors.error,
            label: 'Zauzeto',
            icon: Icons.block,
          ),
          _buildLegendItem(
            color: AppColors.primary,
            label: 'Odabrano',
            icon: Icons.event,
          ),
        ],
      ),
    );
  }

  /// Build legend item
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build selected range display
  Widget _buildSelectedRangeDisplay() {
    final formatter = DateFormat('dd MMM yyyy');
    final checkIn = _rangeStart != null ? formatter.format(_rangeStart!) : '—';
    final checkOut = _rangeEnd != null ? formatter.format(_rangeEnd!) : '—';

    final nights = _rangeStart != null && _rangeEnd != null
        ? _rangeEnd!.difference(_rangeStart!).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-in',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  checkIn,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (nights > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
              ),
              child: Text(
                '$nights ${nights == 1 ? 'noć' : 'noći'}',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Check-out',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  checkOut,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if range contains unavailable dates
  bool _hasUnavailableDatesInRange(DateTime start, DateTime end) {
    final range = end.difference(start).inDays;

    for (var i = 0; i <= range; i++) {
      final date = start.add(Duration(days: i));
      final isUnavailable = widget.unavailableDates.any(
        (unavailable) => isSameDay(unavailable, date),
      );

      if (isUnavailable) {
        return true;
      }
    }

    return false;
  }

  /// Show snackbar for unavailable date selection
  void _showUnavailableSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.block, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Ovaj datum je već zauzet. Molimo odaberite drugi datum.'),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8)
        ),
      ),
    );
  }

  /// Show snackbar for range with unavailable dates
  void _showRangeUnavailableSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Odabrani period sadrži zauzete datume. Molimo odaberite drugi period.'),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8)
        ),
      ),
    );
  }
}
