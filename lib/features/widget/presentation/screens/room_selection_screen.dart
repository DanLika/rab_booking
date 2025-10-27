import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';
import '../widgets/booking_header_bar.dart';
import '../widgets/booking_summary_sidebar.dart';
import '../widgets/room_card.dart';

/// Step 0: Room selection screen
class RoomSelectionScreen extends ConsumerWidget {
  final String unitId;

  const RoomSelectionScreen({
    super.key,
    required this.unitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSummary = ref.watch(showSummaryProvider);
    final selectedRoom = ref.watch(selectedRoomProvider);

    return Scaffold(
      backgroundColor: BedBookingColors.backgroundGrey,
      body: Column(
        children: [
          // Green header bar
          BookingHeaderBar(
            onDateTap: () {
              // TODO: Show calendar modal
              debugPrint('Open date picker');
            },
            onGuestTap: () {
              // TODO: Show guest selector modal
              debugPrint('Open guest selector');
            },
          ),

          // Main content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;

                if (isMobile) {
                  return _buildMobileLayout(context, ref);
                } else {
                  return _buildDesktopLayout(context, ref, showSummary, selectedRoom);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final showSummary = ref.watch(showSummaryProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRoomsList(context, ref),
          if (showSummary) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: BookingSummarySidebar(
                onReserve: () => _onReserve(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    bool showSummary,
    dynamic selectedRoom,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rooms list
        Expanded(
          child: SingleChildScrollView(
            child: _buildRoomsList(context, ref),
          ),
        ),

        // Sidebar (sticky)
        if (showSummary && selectedRoom != null)
          Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            child: BookingSummarySidebar(
              onReserve: () => _onReserve(context, ref),
            ),
          ),
      ],
    );
  }

  Widget _buildRoomsList(BuildContext context, WidgetRef ref) {
    // For demo, fetch units from current property
    // In real app, filter by selected dates & guests
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
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('Error loading rooms: ${snapshot.error}'),
            ),
          );
        }

        final properties = snapshot.data ?? [];
        if (properties.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No properties available'),
            ),
          );
        }

        // Get first property's units
        final property = properties.first;

        return FutureBuilder<List<UnitModel>>(
          future: ref.watch(unitRepositoryProvider).fetchUnitsByProperty(property.id),
          builder: (context, unitsSnapshot) {
            if (unitsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final units = unitsSnapshot.data ?? <UnitModel>[];

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number of offers
                  Text(
                    'Number of offers: ${units.length}',
                    style: BedBookingTextStyles.heading3,
                  ),
                  const SizedBox(height: 20),

                  // Room cards
                  ...units.map((unit) {
                    // Determine badge based on unit name
                    String? badge;
                    if (unit.name.toLowerCase().contains('premium')) {
                      badge = 'PRIVATE TERRACE';
                    } else if (unit.name.toLowerCase().contains('family')) {
                      badge = 'RECOMMENDED FOR FAMILIES';
                    }

                    return RoomCard(
                      room: unit,
                      badge: badge,
                      onSelect: () {
                        // Set selected room and show summary
                        ref.read(selectedRoomProvider.notifier).state = unit;
                        ref.read(showSummaryProvider.notifier).state = true;
                      },
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onReserve(BuildContext context, WidgetRef ref) {
    // Navigate to step 1 (summary & additional services)
    ref.read(bookingStepProvider.notifier).state = 1;
  }
}
