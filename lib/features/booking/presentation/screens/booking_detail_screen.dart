import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/models/booking_status.dart';
import '../providers/user_bookings_provider.dart';
import '../../../../core/providers/auth_state_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/presentation/widgets/adaptive_scaffold.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final bookingAsync = ref.watch(bookingDetailsProvider(bookingId));

    return bookingAsync.when(
      data: (booking) => DetailPageScaffold(
        title: l10n.bookingDetails,
        body: _buildBookingDetails(context, ref, booking),
      ),
      loading: () => DetailPageScaffold(
        title: l10n.bookingDetails,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => DetailPageScaffold(
        title: l10n.bookingDetails,
        body: _buildErrorState(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildBookingDetails(BuildContext context, WidgetRef ref, dynamic booking) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('EEEE, MMM d, y');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Property Image
          CachedNetworkImage(
            imageUrl: booking.propertyImage,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 250,
              color: AppColors.surfaceVariantLight,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(
                Icons.villa_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        booking.propertyName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        minFontSize: 18,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    _buildStatusChip(context, booking.status),
                  ],
                ),
                SizedBox(height: AppDimensions.spaceXS),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: AppDimensions.spaceXXS),
                    Expanded(
                      child: AutoSizeText(
                        booking.propertyLocation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 2,
                        minFontSize: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                Divider(height: AppDimensions.spaceL),

                // Booking Information
                Text(
                  l10n.bookingInformation,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spaceS),

                _InfoRow(
                  icon: Icons.confirmation_number,
                  label: l10n.bookingId,
                  value: booking.id.substring(0, 8).toUpperCase(),
                ),
                _InfoRow(
                  icon: Icons.event,
                  label: l10n.bookingDate,
                  value: dateFormat.format(booking.bookingDate),
                ),

                Divider(height: AppDimensions.spaceL),

                // Stay Details
                Text(
                  l10n.stayDetails,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spaceS),

                Row(
                  children: [
                    Expanded(
                      child: _DateCard(
                        label: l10n.arrival,
                        date: booking.checkInDate,
                        time: kDefaultCheckInTime,
                      ),
                    ),
                    SizedBox(width: AppDimensions.spaceS),
                    Expanded(
                      child: _DateCard(
                        label: l10n.departure,
                        date: booking.checkOutDate,
                        time: kDefaultCheckOutTime,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppDimensions.spaceS),

                _InfoRow(
                  icon: Icons.nights_stay,
                  label: l10n.duration,
                  value: '${booking.nightsCount} ${booking.nightsCount == 1 ? l10n.night : l10n.nightsPlural}',
                ),
                _InfoRow(
                  icon: Icons.person,
                  label: l10n.guests,
                  value: '${booking.guests} ${booking.guests == 1 ? l10n.guest : l10n.guestsPlural}',
                ),

                Divider(height: AppDimensions.spaceL),

                // Payment Information
                Text(
                  l10n.paymentInformation,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spaceS),

                Container(
                  padding: EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.totalAmount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '€${booking.totalPrice.toStringAsFixed(2)}',
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
                  Divider(height: AppDimensions.spaceL),
                  Text(
                    l10n.cancellationDetails,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppDimensions.spaceS),
                  Container(
                    padding: EdgeInsets.all(AppDimensions.spaceS),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.cancellationDate != null)
                          _InfoRow(
                            icon: Icons.event,
                            label: l10n.cancelledOn,
                            value: dateFormat.format(booking.cancellationDate!),
                            iconColor: Colors.red[700],
                          ),
                        if (booking.cancellationReason != null)
                          _InfoRow(
                            icon: Icons.comment,
                            label: l10n.reason,
                            value: booking.cancellationReason!,
                            iconColor: Colors.red[700],
                          ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: AppDimensions.spaceM),

                // Action Buttons
                if (booking.canCancel) ...[
                  Semantics(
                    label: '${l10n.cancelBooking} - ${booking.propertyName}',
                    hint: 'Double tap to open cancellation dialog',
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(context, ref, booking.id),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(l10n.cancelBooking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ),
                ],

                if (booking.status == BookingStatus.confirmed) ...[
                  SizedBox(height: AppDimensions.spaceXS),
                  Semantics(
                    label: '${l10n.viewProperty} - ${booking.propertyName}',
                    hint: 'Double tap to view property page',
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/properties/${booking.propertyId}');
                        },
                        icon: const Icon(Icons.home),
                        label: Text(l10n.viewProperty),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ),
                ],
                // Reviews feature removed - not needed for MVP
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: AppDimensions.iconXL, color: Colors.red),
            SizedBox(height: AppDimensions.spaceS),
            AutoSizeText(
              l10n.errorLoadingBooking,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 16,
            ),
            SizedBox(height: AppDimensions.spaceXS),
            AutoSizeText(
              l10n.tryAgainOrContactSupport,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 12,
            ),
            SizedBox(height: AppDimensions.spaceM),
            Semantics(
              label: 'Retry loading booking',
              hint: 'Double tap to reload',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () => ref.invalidate(bookingDetailsProvider(bookingId)),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, BookingStatus status) {
    Color chipColor;
    Color textColor;

    switch (status) {
      case BookingStatus.confirmed:
        chipColor = AppColors.statusConfirmed.withValues(alpha: 0.1);
        textColor = AppColors.statusConfirmed;
        break;
      case BookingStatus.pending:
        chipColor = AppColors.statusPending.withValues(alpha: 0.1);
        textColor = AppColors.statusPending;
        break;
      case BookingStatus.cancelled:
      case BookingStatus.refunded:
        chipColor = AppColors.statusCancelled.withValues(alpha: 0.1);
        textColor = AppColors.statusCancelled;
        break;
      case BookingStatus.completed:
        chipColor = AppColors.statusCompleted.withValues(alpha: 0.1);
        textColor = AppColors.statusCompleted;
        break;
      case BookingStatus.blocked:
        chipColor = AppColors.textDisabled.withValues(alpha: 0.1);
        textColor = AppColors.textDisabled;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String bookingId) {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBookingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cancelBookingConfirmation),
            SizedBox(height: AppDimensions.spaceS),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.cancellationReason,
                hintText: l10n.cancellationReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.keepBooking),
          ),
          FilledButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.cancellationReasonRequired),
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
                    SnackBar(
                      content: Text(l10n.bookingCancelledSuccessfully),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.bookingCancellationFailed}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.cancelBooking),
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
      padding: EdgeInsets.only(bottom: AppDimensions.spaceXS),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
          SizedBox(width: AppDimensions.spaceXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 1,
                  minFontSize: 11,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppDimensions.spaceXXS),
                AutoSizeText(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  minFontSize: 12,
                  overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.all(AppDimensions.spaceS),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            maxLines: 1,
            minFontSize: 11,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDimensions.spaceXS),
          AutoSizeText(
            dateFormat.format(date),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            minFontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDimensions.spaceXXS),
          AutoSizeText(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
            maxLines: 1,
            minFontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
// _WriteReviewButton removed - Reviews feature not needed for MVP
