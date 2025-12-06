import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradient_extensions.dart';

/// Custom Date Range Picker Widget
/// Uses brand colors instead of Material default pink/red
/// Compact design with max 500px width
Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) => _CustomDateRangePickerDialog(
      initialDateRange: initialDateRange,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
    ),
  );
}

class _CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDateRangePickerDialog({this.initialDateRange, required this.firstDate, required this.lastDate});

  @override
  State<_CustomDateRangePickerDialog> createState() => _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState extends State<_CustomDateRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingEnd = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
    _focusedMonth = _startDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isMobile ? double.infinity : 450,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E28) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with brand gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AutoSizeText(
                      'Odaberi raspon',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Zatvori',
                  ),
                ],
              ),
            ),

            // Selected range display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateDisplay(
                      label: 'Od',
                      date: _startDate,
                      isActive: !_selectingEnd,
                      onTap: () => setState(() => _selectingEnd = false),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: _buildDateDisplay(
                      label: 'Do',
                      date: _endDate,
                      isActive: _selectingEnd,
                      onTap: () => setState(() => _selectingEnd = true),
                    ),
                  ),
                ],
              ),
            ),

            // Calendar
            Flexible(
              child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildCalendar(theme)),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Otkaži')),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: (_startDate != null && _endDate != null) ? context.gradients.brandPrimary : null,
                      color: (_startDate == null || _endDate == null)
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                          : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (_startDate != null && _endDate != null)
                            ? () {
                                Navigator.of(context).pop(DateTimeRange(start: _startDate!, end: _endDate!));
                              }
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Text(
                            'Spremi',
                            style: TextStyle(
                              color: (_startDate != null && _endDate != null)
                                  ? Colors.white
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDateDisplay({
    required String label,
    required DateTime? date,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d. MMM yyyy', 'hr_HR');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? dateFormat.format(date) : 'Odaberi',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: date != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy', 'hr_HR').format(_focusedMonth),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Weekday headers
        Row(
          children: ['P', 'U', 'S', 'Č', 'P', 'S', 'N']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        _buildMonthGrid(theme),
      ],
    );
  }

  Widget _buildMonthGrid(ThemeData theme) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Monday = 1, Sunday = 7
    final startWeekday = firstDayOfMonth.weekday;
    // Adjust to Monday start (0-indexed)
    final leadingEmptyDays = startWeekday - 1;

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = leadingEmptyDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final dayNumber = cellIndex - leadingEmptyDays + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
            return Expanded(child: _buildDayCell(date, theme));
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime date, ThemeData theme) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

    final isSelected =
        _startDate != null && _endDate != null && !date.isBefore(_startDate!) && !date.isAfter(_endDate!);

    final isStart = _startDate != null && _isSameDay(date, _startDate!);
    final isEnd = _endDate != null && _isSameDay(date, _endDate!);
    final isInRange = isSelected && !isStart && !isEnd;

    final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

    final isWeekend = date.weekday == 6 || date.weekday == 7;

    return GestureDetector(
      onTap: isDisabled ? null : () => _onDaySelected(date),
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isInRange ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
          borderRadius: isStart
              ? const BorderRadius.horizontal(left: Radius.circular(22))
              : isEnd
              ? const BorderRadius.horizontal(right: Radius.circular(22))
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: (isStart || isEnd) ? theme.colorScheme.primary : null,
            shape: BoxShape.circle,
            border: isToday && !isStart && !isEnd ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isDisabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : (isStart || isEnd)
                    ? Colors.white
                    : isWeekend
                    ? theme.colorScheme.error.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface,
                fontWeight: (isStart || isEnd || isToday) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      if (!_selectingEnd || _startDate == null) {
        // Selecting start date
        _startDate = date;
        _endDate = null;
        _selectingEnd = true;
      } else {
        // Selecting end date
        if (date.isBefore(_startDate!)) {
          // If selected date is before start, swap them
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
        _selectingEnd = false;
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
