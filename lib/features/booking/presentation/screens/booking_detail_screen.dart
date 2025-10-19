import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/models/booking_status.dart';
import '../providers/user_bookings_provider.dart';
import '../../../property/data/repositories/reviews_repository.dart';
import '../../../../core/providers/auth_state_provider.dart';
import '../../../../l10n/app_localizations.dart';

// Standard check-in/check-out times (industry standard)
const String kDefaultCheckInTime = '14:00'; // 2:00 PM
const String kDefaultCheckOutTime = '11:00'; // 11:00 AM

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailsProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: bookingAsync.when(
        data: (booking) {
          final dateFormat = DateFormat('EEEE, MMM d, y');

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Property Image
                Image.network(
                  booking.propertyImage,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking.propertyName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          _buildStatusChip(context, booking.status),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            booking.propertyLocation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Booking Information
                      Text(
                        'Booking Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      _InfoRow(
                        icon: Icons.confirmation_number,
                        label: 'Booking ID',
                        value: booking.id.substring(0, 8).toUpperCase(),
                      ),
                      _InfoRow(
                        icon: Icons.event,
                        label: 'Booking Date',
                        value: dateFormat.format(booking.bookingDate),
                      ),

                      const Divider(height: 32),

                      // Stay Details
                      Text(
                        'Stay Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _DateCard(
                              label: 'Check-in',
                              date: booking.checkInDate,
                              time: kDefaultCheckInTime,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DateCard(
                              label: 'Check-out',
                              date: booking.checkOutDate,
                              time: kDefaultCheckOutTime,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _InfoRow(
                        icon: Icons.nights_stay,
                        label: 'Duration',
                        value: '${booking.nightsCount} night${booking.nightsCount != 1 ? 's' : ''}',
                      ),
                      _InfoRow(
                        icon: Icons.person,
                        label: 'Guests',
                        value: '${booking.guests} guest${booking.guests != 1 ? 's' : ''}',
                      ),

                      const Divider(height: 32),

                      // Payment Information
                      Text(
                        'Payment Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '\$${booking.totalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Cancellation Info
                      if (booking.isCancelled) ...[
                        const Divider(height: 32),
                        Text(
                          'Cancellation Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (booking.cancellationDate != null)
                                _InfoRow(
                                  icon: Icons.event,
                                  label: 'Cancelled On',
                                  value: dateFormat.format(booking.cancellationDate!),
                                  iconColor: Colors.red[700],
                                ),
                              if (booking.cancellationReason != null)
                                _InfoRow(
                                  icon: Icons.comment,
                                  label: 'Reason',
                                  value: booking.cancellationReason!,
                                  iconColor: Colors.red[700],
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (booking.canCancel) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(context, ref, booking.id),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Booking'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],

                      if (booking.status == BookingStatus.confirmed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/properties/${booking.propertyId}');
                            },
                            icon: const Icon(Icons.home),
                            label: const Text('View Property'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],

                      if (booking.status == BookingStatus.completed) ...[
                        const SizedBox(height: 12),
                        _WriteReviewButton(
                          bookingId: booking.id,
                          propertyId: booking.propertyId,
                          propertyName: booking.propertyName,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading booking: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(bookingDetailsProvider(bookingId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, BookingStatus status) {
    Color chipColor;
    Color textColor;

    switch (status) {
      case BookingStatus.confirmed:
        chipColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case BookingStatus.pending:
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      case BookingStatus.cancelled:
      case BookingStatus.refunded:
        chipColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      case BookingStatus.completed:
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case BookingStatus.blocked:
        chipColor = Colors.grey[300]!;
        textColor = Colors.grey[900]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String bookingId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Please provide a reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a cancellation reason'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ref
                    .read(userBookingsProvider.notifier)
                    .cancelBooking(bookingId, reasonController.text.trim());

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final String time;

  const _DateCard({
    required this.label,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(date),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }
}

class _WriteReviewButton extends ConsumerWidget {
  final String bookingId;
  final String propertyId;
  final String propertyName;

  const _WriteReviewButton({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateNotifierProvider).user?.id;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<PropertyReview?>(
      future: ref
          .read(reviewsRepositoryProvider)
          .getUserReviewForBooking(bookingId: bookingId, userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final localizations = AppLocalizations.of(context);
        final existingReview = snapshot.data;
        final hasReview = existingReview != null;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push(
                '/booking/$bookingId/review',
                extra: {
                  'propertyId': propertyId,
                  'propertyName': propertyName,
                  'existingReview': existingReview,
                },
              );

              // Refresh if review was submitted
              if (result == true) {
                ref.invalidate(bookingDetailsProvider(bookingId));
              }
            },
            icon: Icon(hasReview ? Icons.edit : Icons.rate_review),
            label: Text(
              hasReview
                  ? localizations.editReview
                  : localizations.writeReview,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  hasReview ? Colors.orange : Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}
