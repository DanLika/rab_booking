import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../calendar/presentation/widgets/animated_calendar_grid.dart';
import '../../../calendar/presentation/providers/booking_flow_provider.dart';
import '../../../calendar/domain/models/calendar_day.dart';
import '../../../calendar/domain/models/calendar_permissions.dart';
import '../../../property/domain/models/property_unit.dart';
import '../../../../shared/models/property_model.dart';
import '../providers/owner_calendar_provider.dart';
import '../../../property/presentation/providers/property_details_provider.dart';

/// Modern Owner Calendar Management Screen
/// Integrates with the new AnimatedCalendarGrid and real-time system
class OwnerCalendarManagementScreen extends ConsumerStatefulWidget {
  const OwnerCalendarManagementScreen({super.key});

  @override
  ConsumerState<OwnerCalendarManagementScreen> createState() =>
      _OwnerCalendarManagementScreenState();
}

class _OwnerCalendarManagementScreenState
    extends ConsumerState<OwnerCalendarManagementScreen> {
  String? _selectedPropertyId;
  String? _selectedUnitId;
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh calendar data
              ref.invalidate(ownerPropertiesProvider);
              if (_selectedPropertyId != null) {
                ref.invalidate(propertyUnitsProvider(_selectedPropertyId!));
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Filters Section
              _buildFiltersSection(properties),

              const Divider(height: 1),

              // Calendar Section
              Expanded(
                child: _selectedUnitId != null
                    ? _buildCalendarSection()
                    : _buildSelectUnitPrompt(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading properties: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(ownerPropertiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Properties Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first property to start managing bookings',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Navigate to property creation
              Navigator.pushNamed(context, '/owner/property/create');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Property'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(List<PropertyModel> properties) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Property & Unit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Property Selector
            DropdownButtonFormField<String>(
              value: _selectedPropertyId,
              decoration: const InputDecoration(
                labelText: 'Property',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              items: properties.map((property) {
                return DropdownMenuItem(
                  value: property.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        property.location,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPropertyId = value;
                  _selectedUnitId = null; // Reset unit selection
                });
              },
            ),

            if (_selectedPropertyId != null) ...[
              const SizedBox(height: 16),

              // Unit Selector
              Consumer(
                builder: (context, ref, child) {
                  final unitsAsync = ref.watch(
                    propertyUnitsProvider(_selectedPropertyId!),
                  );

                  return unitsAsync.when(
                    data: (units) {
                      if (units.isEmpty) {
                        return Card(
                          color: Colors.orange.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This property has no units. Create units to manage bookings.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedUnitId,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.bed),
                          border: OutlineInputBorder(),
                        ),
                        items: units.map((unit) {
                          return DropdownMenuItem(
                            value: unit.id,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(unit.name),
                                ),
                                Text(
                                  '${unit.bedrooms} bed • ${unit.bathrooms} bath',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnitId = value;
                          });
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Text(
                      'Error loading units: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectUnitPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Select a Unit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a property and unit to view and manage the calendar',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final blockingFlowState = ref.watch(
      blockingFlowProvider(_selectedUnitId!),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Calendar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                          );
                        });
                      },
                      tooltip: 'Previous Month',
                    ),
                    Text(
                      _getMonthYearDisplay(_currentMonth),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                          );
                        });
                      },
                      tooltip: 'Next Month',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Calendar Grid
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedCalendarGrid(
                  unitId: _selectedUnitId!,
                  month: _currentMonth,
                  enableAnimations: true,
                  showNotifications: true,
                  // Override permissions for owner
                  permissionsOverride: CalendarPermissions.owner(),
                  onDateTap: (date, dayData) {
                    _handleOwnerDateTap(date, dayData);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date Blocking Section
            if (blockingFlowState.hasDatesSelected)
              _buildBlockingPanel(blockingFlowState),

            const SizedBox(height: 16),

            // Legend
            _buildLegend(),

            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockingPanel(BlockingFlowState state) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block),
                const SizedBox(width: 8),
                Text(
                  'Block Dates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(blockingFlowProvider(_selectedUnitId!).notifier).clearDates();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Selected: ${_formatDate(state.startDate!)} - ${_formatDate(state.endDate!)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '${state.nights} night${state.nights != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason for blocking (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Maintenance, Personal use',
              ),
              maxLines: 2,
              onChanged: (value) {
                ref.read(blockingFlowProvider(_selectedUnitId!).notifier).setReason(
                      value.isEmpty ? 'Owner blocked' : value,
                    );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.canProceed
                    ? () async {
                        try {
                          await ref
                              .read(blockingFlowProvider(_selectedUnitId!).notifier)
                              .completeBlocking();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dates blocked successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: state.isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.block),
                label: Text(state.isProcessing ? 'Blocking...' : 'Block Dates'),
              ),
            ),
          ],
        ),
      ),
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
              'Legend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _LegendItem(
                  color: DayStatus.available.color,
                  label: 'Available',
                ),
                _LegendItem(
                  color: DayStatus.booked.color,
                  label: 'Booked',
                ),
                _LegendItem(
                  color: DayStatus.blocked.color,
                  label: 'Blocked',
                ),
                _LegendItem(
                  color: DayStatus.checkIn.color,
                  label: 'Check-in',
                ),
                _LegendItem(
                  color: DayStatus.checkOut.color,
                  label: 'Check-out',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to bookings list
                    Navigator.pushNamed(context, '/owner/bookings');
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View All Bookings'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to unit management
                    Navigator.pushNamed(
                      context,
                      '/owner/units',
                      arguments: _selectedPropertyId,
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Units'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to analytics
                    Navigator.pushNamed(
                      context,
                      '/owner/analytics',
                      arguments: _selectedPropertyId,
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('View Analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleOwnerDateTap(DateTime date, CalendarDay dayData) {
    // Show booking details if day is booked
    if (dayData.status == DayStatus.booked ||
        dayData.status == DayStatus.checkIn ||
        dayData.status == DayStatus.checkOut) {
      _showBookingDetails(dayData);
      return;
    }

    // Show block details if day is blocked
    if (dayData.status == DayStatus.blocked) {
      _showBlockedDateDetails(dayData);
      return;
    }

    // For available dates, allow blocking by selecting date range
    // The BlockingFlow provider handles the date selection
    final blockingFlow = ref.read(blockingFlowProvider(_selectedUnitId!).notifier);

    if (!blockingFlow.state.hasDatesSelected) {
      blockingFlow.selectStartDate(date);
    } else if (blockingFlow.state.endDate == null) {
      blockingFlow.selectEndDate(date);
    } else {
      // Reset and start new selection
      blockingFlow.clearDates();
      blockingFlow.selectStartDate(date);
    }
  }

  void _showBookingDetails(CalendarDay dayData) {
    // TODO: Fetch and show full booking details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${dayData.status.name}'),
            if (dayData.bookingId != null)
              Text('Booking ID: ${dayData.bookingId}'),
            // Add more booking details here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (dayData.bookingId != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/owner/booking/${dayData.bookingId}',
                );
              },
              child: const Text('View Full Details'),
            ),
        ],
      ),
    );
  }

  void _showBlockedDateDetails(CalendarDay dayData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This date is blocked.'),
            // Add blocked date details here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Unblock date
              Navigator.pop(context);
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  String _getMonthYearDisplay(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

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
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
