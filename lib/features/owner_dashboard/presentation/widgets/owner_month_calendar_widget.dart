import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/unit_model.dart';
import '../providers/owner_calendar_provider.dart';
import '../../../widget/presentation/widgets/month_calendar_widget.dart';

/// Owner month calendar widget
/// Displays monthly calendar view with unit selection
class OwnerMonthCalendarWidget extends ConsumerStatefulWidget {
  const OwnerMonthCalendarWidget({super.key});

  @override
  ConsumerState<OwnerMonthCalendarWidget> createState() =>
      _OwnerMonthCalendarWidgetState();
}

class _OwnerMonthCalendarWidgetState
    extends ConsumerState<OwnerMonthCalendarWidget> {
  String? _selectedUnitId;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _hasAutoSelected = false; // Flag to prevent auto-select loop

  // Min/max date boundaries for navigation
  late final DateTime _minDate;
  late final DateTime _maxDate;

  @override
  void initState() {
    super.initState();
    // Set reasonable boundaries: 2 years back, 5 years forward
    final now = DateTime.now();
    _minDate = DateTime(now.year - 2); // January of 2 years ago
    _maxDate = DateTime(now.year + 5, 12); // December of 5 years from now
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Auto-select first unit on first build only
    if (!_hasAutoSelected && _selectedUnitId == null) {
      final unitsAsync = ref.read(allOwnerUnitsProvider);
      unitsAsync.whenData((units) {
        if (units.isNotEmpty && mounted) {
          // Set flag immediately to prevent multiple callbacks
          _hasAutoSelected = true;

          // Schedule setState for next frame to avoid calling during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedUnitId == null) {
              setState(() {
                _selectedUnitId = units.first.id;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return const Center(child: Text('Nema jedinica za prikaz'));
        }

        return Column(
          children: [
            // Unit selector and month navigation
            _buildHeader(units),
            const SizedBox(height: 16),

            // Month calendar for selected unit
            if (_selectedUnitId != null)
              Expanded(child: MonthCalendarWidget(unitId: _selectedUnitId!))
            else
              const Expanded(child: Center(child: Text('Odaberite jedinicu'))),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Greška: $error')),
    );
  }

  /// Build header with unit selector and month navigation
  Widget _buildHeader(List<UnitModel> units) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Unit selector dropdown
            Expanded(
              child: DropdownButton<String>(
                value: _selectedUnitId,
                hint: const Text('Odaberi jedinicu'),
                isExpanded: true,
                items: units.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit.id,
                    child: Text(unit.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),

            // Month navigation
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _canNavigateToPrevMonth()
                      ? () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month - 1,
                            );
                          });
                        }
                      : null, // Disable button if at minimum
                  tooltip: 'Prethodni mjesec',
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _canNavigateToNextMonth()
                      ? () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month + 1,
                            );
                          });
                        }
                      : null, // Disable button if at maximum
                  tooltip: 'Sledeći mjesec',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Check if can navigate to previous month
  bool _canNavigateToPrevMonth() {
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    return !prevMonth.isBefore(_minDate);
  }

  /// Check if can navigate to next month
  bool _canNavigateToNextMonth() {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    return !nextMonth.isAfter(_maxDate);
  }
}
