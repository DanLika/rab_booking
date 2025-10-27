import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';
import '../widgets/year_grid_calendar_widget.dart';

// Using providers from booking_flow_provider.dart:
// - checkInDateProvider
// - checkOutDateProvider
// - adultsCountProvider
// - childrenCountProvider

/// Enhanced Room Selection Screen (Step 0 of Flow B)
/// Shows integrated calendar + available rooms
class EnhancedRoomSelectionScreen extends ConsumerStatefulWidget {
  final String? propertyId;

  const EnhancedRoomSelectionScreen({
    super.key,
    this.propertyId,
  });

  @override
  ConsumerState<EnhancedRoomSelectionScreen> createState() =>
      _EnhancedRoomSelectionScreenState();
}

class _EnhancedRoomSelectionScreenState
    extends ConsumerState<EnhancedRoomSelectionScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  String? _selectedUnitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: BedBookingColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Book Your Stay',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  // ===================================================================
  // MOBILE LAYOUT
  // ===================================================================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date selection header
          _buildDateSelectionHeader(),

          // Calendar section
          if (_selectedUnitId != null) ...[
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select your dates',
                style: BedBookingTextStyles.heading2,
              ),
            ),
            SizedBox(
              height: 500,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: YearGridCalendarWidget(
                  unitId: _selectedUnitId!,
                  onRangeSelected: (start, end) {
                    setState(() {
                      _checkIn = start;
                      _checkOut = end;
                    });
                  },
                ),
              ),
            ),
          ],

          // Room selection
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your room',
                  style: BedBookingTextStyles.heading2,
                ),
                const SizedBox(height: 16),
                _buildRoomsList(),
              ],
            ),
          ),

          // Continue button
          if (_checkIn != null && _checkOut != null && _selectedUnitId != null)
            _buildContinueButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===================================================================
  // DESKTOP LAYOUT
  // ===================================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Room list (30%)
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: BedBookingColors.backgroundGrey,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose your room',
                    style: BedBookingTextStyles.heading2,
                  ),
                  const SizedBox(height: 20),
                  _buildRoomsList(),
                ],
              ),
            ),
          ),
        ),

        // Right: Calendar (70%)
        Expanded(
          flex: 7,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Date selection header
                _buildDateSelectionHeader(),

                // Calendar
                if (_selectedUnitId != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: YearGridCalendarWidget(
                        unitId: _selectedUnitId!,
                        onRangeSelected: (start, end) {
                          setState(() {
                            _checkIn = start;
                            _checkOut = end;
                          });
                        },
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hotel_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a room to view availability',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Continue button
                if (_checkIn != null &&
                    _checkOut != null &&
                    _selectedUnitId != null)
                  _buildContinueButton(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // SHARED COMPONENTS
  // ===================================================================

  Widget _buildDateSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Guest selector
          Row(
            children: [
              Expanded(
                child: _buildGuestSelector(
                  icon: Icons.person,
                  label: 'Adults',
                  count: _adults,
                  onIncrement: () => setState(() => _adults++),
                  onDecrement: () =>
                      setState(() => _adults = (_adults - 1).clamp(1, 10)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGuestSelector(
                  icon: Icons.child_care,
                  label: 'Children',
                  count: _children,
                  onIncrement: () => setState(() => _children++),
                  onDecrement: () =>
                      setState(() => _children = (_children - 1).clamp(0, 10)),
                ),
              ),
            ],
          ),

          // Selected dates display
          if (_checkIn != null && _checkOut != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BedBookingColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BedBookingColors.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateDisplay('Check-in', _checkIn!),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: BedBookingColors.primaryGreen,
                  ),
                  Expanded(
                    child: _buildDateDisplay('Check-out', _checkOut!),
                  ),
                  Text(
                    '${_checkOut!.difference(_checkIn!).inDays} nights',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestSelector({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BedBookingColors.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BedBookingColors.textGrey),
          const SizedBox(width: 8),
          Text(label, style: BedBookingTextStyles.small),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: count > (label == 'Adults' ? 1 : 0) ? onDecrement : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              count.toString(),
              style: BedBookingTextStyles.bodyBold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(date),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsList() {
    final propertyRepo = ref.watch(propertyRepositoryProvider);

    return FutureBuilder(
      future: propertyRepo.fetchProperties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading properties: ${snapshot.error}',
              style: const TextStyle(color: BedBookingColors.error),
            ),
          );
        }

        final properties = snapshot.data ?? [];
        if (properties.isEmpty) {
          return const Center(
            child: Text('No properties available'),
          );
        }

        // Get first property (or use propertyId if provided)
        final property = properties.first;

        return FutureBuilder<List<UnitModel>>(
          future:
              ref.watch(unitRepositoryProvider).fetchUnitsByProperty(property.id),
          builder: (context, unitsSnapshot) {
            if (unitsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final units = unitsSnapshot.data ?? <UnitModel>[];

            if (units.isEmpty) {
              return const Center(child: Text('No rooms available'));
            }

            return Column(
              children: units.map((unit) => _buildRoomCard(unit)).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildRoomCard(UnitModel unit) {
    final isSelected = _selectedUnitId == unit.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUnitId = unit.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BedBookingColors.primaryGreen
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BedBookingColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Room image
            if (unit.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  unit.images.first,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.hotel, size: 40),
                    );
                  },
                ),
              ),
            const SizedBox(width: 16),

            // Room details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: BedBookingTextStyles.heading3,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.maxGuests} guests',
                        style: BedBookingTextStyles.small,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.king_bed,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.bedrooms} ${unit.bedrooms == 1 ? 'bedroom' : 'bedrooms'}',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                  if (unit.description != null && unit.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      unit.description!,
                      style: BedBookingTextStyles.small,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BedBookingColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final nights = _checkOut!.difference(_checkIn!).inDays;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleContinue(),
            style: BedBookingButtons.primaryButton.copyWith(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            child: Text(
              'Continue - $nights ${nights == 1 ? 'night' : 'nights'}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    // Store selected data in booking flow state
    ref.read(checkInDateProvider.notifier).state = _checkIn;
    ref.read(checkOutDateProvider.notifier).state = _checkOut;
    ref.read(adultsCountProvider.notifier).state = _adults;
    ref.read(childrenCountProvider.notifier).state = _children;

    // Find and store selected unit
    final unitRepo = ref.read(unitRepositoryProvider);
    unitRepo.fetchUnitById(_selectedUnitId!).then((unit) {
      if (unit != null) {
        ref.read(selectedRoomProvider.notifier).state = unit;
      }
    });

    // Navigate to Step 1
    ref.read(bookingStepProvider.notifier).state = 1;
  }
}

