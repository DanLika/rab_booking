import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/booking_calendar.dart';
import '../providers/calendar_provider.dart';
import 'package:intl/intl.dart';

/// Owner calendar screen - allows owners to view bookings and block dates
class OwnerCalendarScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String propertyName;
  final String unitName;

  const OwnerCalendarScreen({
    super.key,
    required this.unitId,
    required this.propertyName,
    required this.unitName,
  });

  @override
  ConsumerState<OwnerCalendarScreen> createState() => _OwnerCalendarScreenState();
}

class _OwnerCalendarScreenState extends ConsumerState<OwnerCalendarScreen> {
  DateTime? _blockFromDate;
  DateTime? _blockToDate;

  @override
  Widget build(BuildContext context) {
    final blockedDates = ref.watch(blockedDatesProvider(widget.unitId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.propertyName),
            Text(
              widget.unitName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.block),
            tooltip: 'Block Dates',
            onPressed: () => _showBlockDatesDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Calendar Settings',
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats card
          _buildStatsCard(context),

          // Blocked dates list
          blockedDates.when(
            data: (blocks) {
              if (blocks.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildBlockedDatesList(context, blocks);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: BookingCalendar(
                unitId: widget.unitId,
                allowSelection: false, // Owner can't book - only view
                showLegend: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final calendarData = ref.watch(
      calendarDataProvider(
        unitId: widget.unitId,
        month: DateTime.now(),
      ),
    );

    return calendarData.when(
      data: (days) {
        final bookedDays = days.where((d) =>
          d.status == DayStatus.booked ||
          d.status == DayStatus.checkIn ||
          d.status == DayStatus.checkOut
        ).length;

        final blockedDays = days.where((d) => d.status == DayStatus.blocked).length;
        final availableDays = days.where((d) => d.status == DayStatus.available).length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Booked',
                value: '$bookedDays',
                icon: Icons.check_circle,
              ),
              _StatItem(
                label: 'Available',
                value: '$availableDays',
                icon: Icons.event_available,
              ),
              _StatItem(
                label: 'Blocked',
                value: '$blockedDays',
                icon: Icons.block,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBlockedDatesList(
    BuildContext context,
    List<CalendarAvailability> blocks,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blocked Dates',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...blocks.take(3).map((block) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(
                  '${DateFormat('MMM d').format(block.blockedFrom)} - ${DateFormat('MMM d, yyyy').format(block.blockedTo)}',
                ),
                subtitle: Text(block.reason),
                trailing: block.notes != null
                    ? const Icon(Icons.note, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showBlockDatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Dates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select date range to block for this unit',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Simple date range picker
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Select Dates'),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (range != null) {
                  setState(() {
                    _blockFromDate = range.start;
                    _blockToDate = range.end;
                  });
                }
              },
            ),
            if (_blockFromDate != null && _blockToDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '${DateFormat('MMM d').format(_blockFromDate!)} - ${DateFormat('MMM d, yyyy').format(_blockToDate!)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _blockFromDate != null && _blockToDate != null
                ? () => _confirmBlockDates(context)
                : null,
            child: const Text('Block Dates'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBlockDates(BuildContext context) async {
    if (_blockFromDate == null || _blockToDate == null) return;

    try {
      await ref.read(blockedDatesProvider(widget.unitId).notifier).blockDates(
            from: _blockFromDate!,
            to: _blockToDate!,
            reason: 'maintenance',
            notes: null,
          );

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dates blocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _blockFromDate = null;
        _blockToDate = null;
      });

      // Refresh calendar
      ref.invalidate(calendarDataProvider(
        unitId: widget.unitId,
        month: DateTime.now(),
      ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block dates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final settings = ref.read(calendarSettingsNotifierProvider(widget.unitId));

    settings.when(
      data: (data) {
        if (data == null) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Calendar Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingRow(
                  label: 'Check-in Time',
                  value: data.checkInTime,
                ),
                _SettingRow(
                  label: 'Check-out Time',
                  value: data.checkOutTime,
                ),
                _SettingRow(
                  label: 'Minimum Nights',
                  value: '${data.minNights}',
                ),
                _SettingRow(
                  label: 'Same-day Turnover',
                  value: data.allowSameDayTurnover ? 'Allowed' : 'Not Allowed',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to settings edit screen
                },
                child: const Text('Edit Settings'),
              ),
            ],
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
