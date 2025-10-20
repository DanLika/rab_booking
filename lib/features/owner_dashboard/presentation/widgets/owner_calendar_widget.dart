import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../booking/domain/models/booking_status.dart';
import '../providers/owner_calendar_provider.dart';
import '../../data/owner_bookings_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// Owner calendar widget with month view and color-coded bookings
class OwnerCalendarWidget extends ConsumerStatefulWidget {
  const OwnerCalendarWidget({super.key});

  @override
  ConsumerState<OwnerCalendarWidget> createState() => _OwnerCalendarWidgetState();
}

class _OwnerCalendarWidgetState extends ConsumerState<OwnerCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final unitsAsync = ref.watch(selectedPropertyUnitsProvider);
    final bookingsAsync = ref.watch(calendarBookingsProvider);

    // Enable realtime subscription for automatic updates
    ref.watch(ownerCalendarRealtimeManagerProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with filters
          _buildFiltersSection(propertiesAsync, unitsAsync),

          const SizedBox(height: 24),

          // Calendar
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: bookingsAsync.when(
                  data: (bookingsByUnit) => _buildCalendar(bookingsByUnit),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading bookings: $error'),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(
    AsyncValue<List<dynamic>> propertiesAsync,
    AsyncValue<List<dynamic>> unitsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Switch to column layout on smaller screens
        final isNarrow = constraints.maxWidth < 900;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Property selector
              propertiesAsync.when(
                data: (properties) {
                  final filters = ref.read(calendarFiltersNotifierProvider);
                  return DropdownButtonFormField<String?>(
                    key: ValueKey(filters.selectedPropertyId),
                    decoration: const InputDecoration(
                      labelText: 'Odaberi objekt',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    initialValue: filters.selectedPropertyId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Svi objekti'),
                      ),
                      ...properties.map((property) {
                        return DropdownMenuItem(
                          value: property.id,
                          child: Text(property.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      ref.read(calendarFiltersNotifierProvider.notifier).selectProperty(value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => const Text('Error loading properties'),
              ),

              const SizedBox(height: 16),

              // Unit selector
              unitsAsync.when(
                data: (units) {
                  final filters = ref.read(calendarFiltersNotifierProvider);
                  return DropdownButtonFormField<String?>(
                    key: ValueKey(filters.selectedUnitId),
                    decoration: const InputDecoration(
                      labelText: 'Odaberi jedinicu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bed_outlined),
                    ),
                    initialValue: filters.selectedUnitId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sve jedinice'),
                      ),
                      ...units.map((unit) {
                        return DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.name),
                        );
                      }),
                    ],
                    onChanged: filters.selectedPropertyId != null
                        ? (value) {
                            ref.read(calendarFiltersNotifierProvider.notifier).selectUnit(value);
                          }
                        : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => const Text('Error loading units'),
              ),

              const SizedBox(height: 16),

              // Block dates button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _rangeStart != null && _rangeEnd != null
                      ? () => _showBlockDatesDialog()
                      : null,
                  icon: const Icon(Icons.block),
                  label: const Text('Blokiraj datume'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ),
            ],
          );
        }

        // Wide screen - use Row layout
        return Row(
          children: [
            // Property selector
            Expanded(
              child: propertiesAsync.when(
                data: (properties) {
                  final filters = ref.read(calendarFiltersNotifierProvider);
                  return DropdownButtonFormField<String?>(
                    key: ValueKey(filters.selectedPropertyId),
                    decoration: const InputDecoration(
                      labelText: 'Odaberi objekt',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    initialValue: filters.selectedPropertyId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Svi objekti'),
                      ),
                      ...properties.map((property) {
                        return DropdownMenuItem(
                          value: property.id,
                          child: Text(property.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      ref.read(calendarFiltersNotifierProvider.notifier).selectProperty(value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => const Text('Error loading properties'),
              ),
            ),

            const SizedBox(width: 16),

            // Unit selector
            Expanded(
              child: unitsAsync.when(
                data: (units) {
                  final filters = ref.read(calendarFiltersNotifierProvider);
                  return DropdownButtonFormField<String?>(
                    key: ValueKey(filters.selectedUnitId),
                    decoration: const InputDecoration(
                      labelText: 'Odaberi jedinicu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bed_outlined),
                    ),
                    initialValue: filters.selectedUnitId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sve jedinice'),
                      ),
                      ...units.map((unit) {
                        return DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.name),
                        );
                      }),
                    ],
                    onChanged: filters.selectedPropertyId != null
                        ? (value) {
                            ref.read(calendarFiltersNotifierProvider.notifier).selectUnit(value);
                          }
                        : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => const Text('Error loading units'),
              ),
            ),

            const SizedBox(width: 16),

            // Block dates button
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _rangeStart != null && _rangeEnd != null
                    ? () => _showBlockDatesDialog()
                    : null,
                icon: const Icon(Icons.block),
                label: const Text('Blokiraj datume'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendar(Map<String, List<BookingModel>> bookingsByUnit) {
    return TableCalendar<BookingModel>(
      firstDay: DateTime(DateTime.now().year - 1),
      lastDay: DateTime(DateTime.now().year + 2),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      rangeSelectionMode: _rangeSelectionMode,
      eventLoader: (day) => _getBookingsForDay(day, bookingsByUnit),
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha:0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: Theme.of(context).primaryColor.withValues(alpha:0.2),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders<BookingModel>(
        markerBuilder: (context, day, bookings) {
          if (bookings.isEmpty) return null;

          // Get unique statuses for this day
          final statuses = bookings.map((b) => b.status).toSet().toList();

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: statuses.take(3).map((status) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status.color,
                ),
              );
            }).toList(),
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        if (_rangeSelectionMode == RangeSelectionMode.toggledOn) {
          // Range selection mode
          if (_rangeStart == null) {
            setState(() {
              _rangeStart = selectedDay;
              _rangeEnd = null;
              _focusedDay = focusedDay;
            });
          } else if (_rangeEnd == null) {
            setState(() {
              _rangeEnd = selectedDay;
              _focusedDay = focusedDay;
            });
          } else {
            setState(() {
              _rangeStart = selectedDay;
              _rangeEnd = null;
              _focusedDay = focusedDay;
            });
          }
        } else {
          // Single day selection - show bookings
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          final bookings = _getBookingsForDay(selectedDay, bookingsByUnit);
          if (bookings.isNotEmpty) {
            _showBookingsDialog(selectedDay, bookings);
          }
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        ref.read(calendarFiltersNotifierProvider.notifier).setFocusedMonth(focusedDay);
      },
      onRangeSelected: (start, end, focusedDay) {
        setState(() {
          _rangeStart = start;
          _rangeEnd = end;
          _focusedDay = focusedDay;
          _selectedDay = null;
        });
      },
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legenda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _LegendItem(
                  color: BookingStatus.confirmed.color,
                  label: 'Potvrđeno',
                ),
                _LegendItem(
                  color: BookingStatus.pending.color,
                  label: 'Na čekanju',
                ),
                _LegendItem(
                  color: BookingStatus.cancelled.color,
                  label: 'Otkazano',
                ),
                _LegendItem(
                  color: BookingStatus.blocked.color,
                  label: 'Blokirano',
                ),
                _LegendItem(
                  color: BookingStatus.completed.color,
                  label: 'Završeno',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rangeSelectionMode = _rangeSelectionMode == RangeSelectionMode.toggledOn
                          ? RangeSelectionMode.toggledOff
                          : RangeSelectionMode.toggledOn;
                      _rangeStart = null;
                      _rangeEnd = null;
                    });
                  },
                  icon: Icon(
                    _rangeSelectionMode == RangeSelectionMode.toggledOn
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  label: const Text('Odaberi raspon datuma'),
                ),
                const SizedBox(width: 16),
                Text(
                  _rangeSelectionMode == RangeSelectionMode.toggledOn
                      ? 'Klikni na dva datuma za odabir raspona'
                      : 'Klikni na datum za pregled rezervacija',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BookingModel> _getBookingsForDay(
    DateTime day,
    Map<String, List<BookingModel>> bookingsByUnit,
  ) {
    final allBookings = bookingsByUnit.values.expand((list) => list).toList();

    return allBookings.where((booking) {
      return day.isAfter(booking.checkIn.subtract(const Duration(days: 1))) &&
          day.isBefore(booking.checkOut.add(const Duration(days: 1)));
    }).toList();
  }

  void _showBookingsDialog(DateTime day, List<BookingModel> bookings) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 400.0 : screenWidth * 0.9;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rezervacije - ${day.day}.${day.month}.${day.year}.'),
        content: SizedBox(
          width: dialogWidth,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: booking.status.color,
                  child: Text(
                    booking.guestCount.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(booking.status.displayName),
                subtitle: Text(
                  '${booking.checkIn.day}.${booking.checkIn.month}. - ${booking.checkOut.day}.${booking.checkOut.month}.\n'
                  '${booking.guestCount} ${booking.guestCount == 1 ? 'gost' : 'gostiju'}',
                ),
                trailing: Text(
                  booking.formattedTotalPrice,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  void _showBlockDatesDialog() {
    final filters = ref.read(calendarFiltersNotifierProvider);

    if (filters.selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite jedinicu prije blokiranja datuma'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blokiraj datume'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blokiraj od ${_rangeStart!.day}.${_rangeStart!.month}. '
              'do ${_rangeEnd!.day}.${_rangeEnd!.month}.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog (opcionalno)',
                border: OutlineInputBorder(),
                hintText: 'Npr. Održavanje, Privatna upotreba...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final repository = ref.read(ownerBookingsRepositoryProvider);
                await repository.blockDates(
                  unitId: filters.selectedUnitId!,
                  checkIn: _rangeStart!,
                  checkOut: _rangeEnd!,
                  reason: reasonController.text.isEmpty ? null : reasonController.text,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Datumi su uspješno blokirani'),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  // Reset selection
                  setState(() {
                    _rangeStart = null;
                    _rangeEnd = null;
                    _rangeSelectionMode = RangeSelectionMode.toggledOff;
                  });

                  // Refresh bookings
                  ref.invalidate(calendarBookingsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Greška: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Blokiraj'),
          ),
        ],
      ),
    );
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
