import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../providers/owner_calendar_provider.dart';

/// Bottom sheet with quick actions for a booking
/// Shown on short tap of a booking block
class BookingActionBottomSheet extends ConsumerWidget {
  final BookingModel booking;

  const BookingActionBottomSheet({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Booking info header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.guestName ?? 'Nepoznati gost',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Edit action
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'Uredi rezervaciju',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Promijeni detalje rezervacije'),
              onTap: () {
                Navigator.pop(context, 'edit');
              },
            ),

            // Change status action
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sync_alt,
                  color: AppColors.info,
                ),
              ),
              title: const Text(
                'Promijeni status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Confirmed, Pending, Cancelled...'),
              onTap: () {
                Navigator.pop(context, 'status');
              },
            ),

            // Delete action
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
              ),
              title: const Text(
                'Obriši rezervaciju',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Trajno ukloni rezervaciju'),
              onTap: () {
                Navigator.pop(context, 'delete');
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

/// Bottom sheet for moving booking to another unit
/// Shown on long press of a booking block
class BookingMoveToUnitMenu extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingMoveToUnitMenu({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<BookingMoveToUnitMenu> createState() => _BookingMoveToUnitMenuState();
}

class _BookingMoveToUnitMenuState extends ConsumerState<BookingMoveToUnitMenu> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prebaci rezervaciju u:',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking.guestName ?? 'Nepoznati gost',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Units list
            unitsAsync.when(
              data: (units) {
                // Filter out current unit
                final otherUnits = units.where((u) => u.id != widget.booking.unitId).toList();

                if (otherUnits.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nema drugih dostupnih jedinica'),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: otherUnits.length,
                    itemBuilder: (context, index) {
                      final unit = otherUnits[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getUnitIcon(unit),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          unit.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${unit.maxGuests} gostiju • ${unit.bedrooms} spavaće sobe',
                        ),
                        enabled: !_isProcessing,
                        onTap: _isProcessing
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _moveBookingToUnit(context, unit);
                              },
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Greška: $error'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getUnitIcon(UnitModel unit) {
    if (unit.bedrooms >= 3) return Icons.house;
    if (unit.bedrooms == 2) return Icons.apartment;
    return Icons.hotel;
  }

  Future<void> _moveBookingToUnit(
    BuildContext context,
    UnitModel targetUnit,
  ) async {
    if (_isProcessing) return; // Prevent double-tap

    setState(() => _isProcessing = true);

    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Prebacivanje rezervacije...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Update booking with new unit
      final updatedBooking = widget.booking.copyWith(unitId: targetUnit.id);
      final bookingRepo = ref.read(bookingRepositoryProvider);
      await bookingRepo.updateBooking(updatedBooking);

      // Refresh calendar
      ref.invalidate(calendarBookingsProvider);

      // Show success
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rezervacija prebačena u ${targetUnit.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
