import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../domain/models/overbooking_conflict.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/models/platform_connection.dart';
import '../providers/platform_connections_provider.dart';

/// Quick Action Buttons Widget
/// 
/// Displays action buttons for:
/// - Blocking dates on external platforms
/// - Viewing in app
/// - Resolving conflicts
class QuickActionButtons extends ConsumerWidget {
  final OverbookingConflict? conflict;
  final BookingModel? booking;
  final String? unitId;

  const QuickActionButtons({
    super.key,
    this.conflict,
    this.booking,
    this.unitId,
  }) : assert(
          conflict != null || booking != null,
          'Either conflict or booking must be provided',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveUnitId = conflict?.unitId ?? booking?.unitId ?? unitId;
    if (effectiveUnitId == null) {
      return const SizedBox.shrink();
    }

    // Get platform connections for this unit
    final connectionsAsync = ref.watch(platformConnectionsForUnitProvider(effectiveUnitId));

    if (connectionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final connections = connectionsAsync.valueOrNull ?? [];

    if (connections.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine dates to block
    DateTime? checkIn;
    DateTime? checkOut;

    if (conflict != null && conflict!.conflictDates.isNotEmpty) {
      checkIn = conflict!.conflictDates.first;
      checkOut = conflict!.conflictDates.last.add(const Duration(days: 1));
    } else if (booking != null) {
      checkIn = booking!.checkIn;
      checkOut = booking!.checkOut;
    }

    if (checkIn == null || checkOut == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Block on external platforms
        ...connections.map((connection) {
          if (connection.platform == PlatformType.bookingCom) {
            return _buildBlockButton(
              context,
              label: 'Block on Booking.com',
              icon: Icons.hotel,
              onTap: () => _handleBlockBookingCom(
                context,
                connection,
                checkIn!,
                checkOut!,
              ),
            );
          } else if (connection.platform == PlatformType.airbnb) {
            return _buildBlockButton(
              context,
              label: 'Block on Airbnb',
              icon: Icons.home,
              onTap: () => _handleBlockAirbnb(
                context,
                connection,
                checkIn!,
                checkOut!,
              ),
            );
          }
          return const SizedBox.shrink();
        }).whereType<Widget>().toList(),

        const SizedBox(height: 8),

        // View in app button
        _buildViewButton(context),
      ],
    );
  }

  Widget _buildBlockButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildViewButton(BuildContext context) {
    final effectiveUnitId = conflict?.unitId ?? booking?.unitId ?? unitId;
    final conflictId = conflict?.id;
    final bookingId = booking?.id;

    return OutlinedButton.icon(
      onPressed: () {
        if (conflictId != null) {
          Navigator.of(context).pushNamed(
            '/owner/bookings',
            arguments: {'conflict': conflictId},
          );
        } else if (bookingId != null) {
          Navigator.of(context).pushNamed(
            '/owner/bookings',
            arguments: {'booking': bookingId},
          );
        } else if (effectiveUnitId != null) {
          Navigator.of(context).pushNamed(
            '/owner/calendar',
            arguments: {'unit': effectiveUnitId},
          );
        }
      },
      icon: const Icon(Icons.visibility, size: 20),
      label: const Text('View in App'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _handleBlockBookingCom(
    BuildContext context,
    PlatformConnection connection,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    final url = DeepLinkService.generateBookingComBlockUrl(
      hotelId: connection.externalPropertyId,
      roomTypeId: connection.externalUnitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    await DeepLinkService().handleDeepLink(url, context);
  }

  Future<void> _handleBlockAirbnb(
    BuildContext context,
    PlatformConnection connection,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    final url = DeepLinkService.generateAirbnbBlockUrl(
      listingId: connection.externalPropertyId,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    await DeepLinkService().handleDeepLink(url, context);
  }
}

