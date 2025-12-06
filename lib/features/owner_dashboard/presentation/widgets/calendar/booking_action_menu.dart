import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../providers/owner_calendar_provider.dart';

/// Bottom sheet with quick actions for a booking
/// Shown on short tap of a booking block
class BookingActionBottomSheet extends ConsumerWidget {
  final BookingModel booking;

  const BookingActionBottomSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Gradient header with booking info
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Guest name and status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.guestName ?? l10n.bookingActionUnknownGuest,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                              style: TextStyle(fontSize: 14, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: booking.status.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              booking.status.displayName,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: booking.status.color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Info row: nights, guests, price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(Icons.nights_stay, '$nights ${nights == 1 ? 'noć' : 'noći'}'),
                      _buildInfoChip(
                        Icons.people_outline,
                        '${booking.guestCount} gost${booking.guestCount > 1 ? 'a' : ''}',
                      ),
                      _buildInfoChip(Icons.euro, '${booking.totalPrice.toStringAsFixed(0)} €'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Edit action
                  _buildActionTile(
                    context,
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.primary,
                    title: l10n.bookingActionEditTitle,
                    subtitle: l10n.bookingActionEditSubtitle,
                    onTap: () => Navigator.pop(context, 'edit'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  // Change status action
                  _buildActionTile(
                    context,
                    icon: Icons.sync_alt,
                    iconColor: AppColors.info,
                    title: l10n.bookingActionStatusTitle,
                    subtitle: l10n.bookingActionStatusSubtitle,
                    onTap: () => Navigator.pop(context, 'status'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  // Delete action
                  _buildActionTile(
                    context,
                    icon: Icons.delete_outline,
                    iconColor: AppColors.error,
                    title: l10n.bookingActionDeleteTitle,
                    subtitle: l10n.bookingActionDeleteSubtitle,
                    onTap: () => Navigator.pop(context, 'delete'),
                    isDark: isDark,
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252530) : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withAlpha((0.3 * 255).toInt())
                  : (isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? AppColors.error : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
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

  const BookingMoveToUnitMenu({super.key, required this.booking});

  @override
  ConsumerState<BookingMoveToUnitMenu> createState() => _BookingMoveToUnitMenuState();
}

class _BookingMoveToUnitMenuState extends ConsumerState<BookingMoveToUnitMenu> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Gradient header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bookingActionMoveTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.booking.guestName ?? l10n.bookingActionUnknownGuest,
                          style: TextStyle(fontSize: 14, color: Colors.white.withAlpha((0.9 * 255).toInt())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Units list
            unitsAsync.when(
              data: (units) {
                // Filter out current unit
                final otherUnits = units.where((u) => u.id != widget.booking.unitId).toList();

                if (otherUnits.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          l10n.bookingActionNoOtherUnits,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: otherUnits.length,
                    itemBuilder: (context, index) {
                      final unit = otherUnits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isProcessing
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    await _moveBookingToUnit(context, unit, l10n);
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF252530) : const Color(0xFFF8F8FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha((0.15 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_getUnitIcon(unit), color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unit.name,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.bookingActionGuestsRooms(unit.maxGuests, unit.bedrooms),
                                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) =>
                  Padding(padding: const EdgeInsets.all(24), child: Text(l10n.bookingActionError(error.toString()))),
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

  Future<void> _moveBookingToUnit(BuildContext context, UnitModel targetUnit, AppLocalizations l10n) async {
    if (_isProcessing) return; // Prevent double-tap

    setState(() => _isProcessing = true);

    try {
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              ),
              const SizedBox(width: 12),
              Text(l10n.bookingActionMoving),
            ],
          ),
          duration: const Duration(seconds: 2),
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
        SnackBar(content: Text(l10n.bookingActionMovedTo(targetUnit.name)), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bookingActionError(e.toString())), backgroundColor: AppColors.error));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
