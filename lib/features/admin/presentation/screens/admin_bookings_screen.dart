import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/admin_providers.dart';
import '../../data/repositories/admin_repository.dart';

/// Admin Booking Management Screen
class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsProvider);
    final filters = ref.watch(adminBookingFiltersProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminBookingsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: EdgeInsets.all(isMobile ? AppDimensions.spaceM : AppDimensions.spaceL),
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(label: 'All', value: 'all', selected: filters.status == 'all', onTap: () => ref.read(adminBookingFiltersProvider.notifier).setStatus('all')),
                  _StatusChip(label: 'Pending', value: 'pending', selected: filters.status == 'pending', onTap: () => ref.read(adminBookingFiltersProvider.notifier).setStatus('pending')),
                  _StatusChip(label: 'Confirmed', value: 'confirmed', selected: filters.status == 'confirmed', onTap: () => ref.read(adminBookingFiltersProvider.notifier).setStatus('confirmed')),
                  _StatusChip(label: 'Completed', value: 'completed', selected: filters.status == 'completed', onTap: () => ref.read(adminBookingFiltersProvider.notifier).setStatus('completed')),
                  _StatusChip(label: 'Cancelled', value: 'cancelled', selected: filters.status == 'cancelled', onTap: () => ref.read(adminBookingFiltersProvider.notifier).setStatus('cancelled')),
                ],
              ),
            ),
          ),
          // Bookings List
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) return const Center(child: Text('No bookings found'));
                return ListView.separated(
                  padding: EdgeInsets.all(isMobile ? AppDimensions.spaceM : AppDimensions.spaceL),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceM),
                  itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorStateWidget(message: 'Failed to load bookings', onRetry: () => ref.invalidate(adminBookingsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spaceS),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final dynamic booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Booking #${booking.id.substring(0, 8)}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                _StatusBadge(status: booking.status),
              ],
            ),
            const Divider(height: AppDimensions.spaceL),
            _InfoRow(icon: Icons.person, label: 'Guest', value: booking.userName ?? 'N/A'),
            _InfoRow(icon: Icons.home, label: 'Property', value: booking.propertyName ?? 'N/A'),
            _InfoRow(icon: Icons.calendar_today, label: 'Check-in', value: _formatDate(booking.checkIn)),
            _InfoRow(icon: Icons.calendar_today, label: 'Check-out', value: _formatDate(booking.checkOut)),
            _InfoRow(icon: Icons.euro, label: 'Total', value: '€${booking.totalPrice.toStringAsFixed(2)}'),
            if (booking.status != 'cancelled') ...[
              const SizedBox(height: AppDimensions.spaceM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(context, ref, booking),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel Booking'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, dynamic booking) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this booking?'),
            const SizedBox(height: AppDimensions.spaceM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Cancellation Reason', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                return;
              }
              await ref.read(adminRepositoryProvider).cancelBooking(booking.id, reasonController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(adminBookingsProvider);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'confirmed': color = AppColors.success; break;
      case 'completed': color = AppColors.info; break;
      case 'cancelled': color = AppColors.error; break;
      case 'pending': color = AppColors.warning; break;
      default: color = AppColors.textSecondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceS, vertical: AppDimensions.spaceXXS),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS), border: Border.all(color: color)),
      child: Text(status.toUpperCase(), style: AppTypography.small.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppDimensions.spaceS),
          Text('$label:', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(child: Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
