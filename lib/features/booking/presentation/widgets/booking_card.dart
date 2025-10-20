import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_booking.dart';
import '../../domain/models/booking_status.dart';

class BookingCard extends StatelessWidget {
  final UserBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancelRequested;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancelRequested,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');

    // Build semantic summary for screen readers
    final semanticLabel = 'Rezervacija za ${booking.propertyName} u ${booking.propertyLocation}. '
        'Check-in ${dateFormat.format(booking.checkInDate)}, '
        'Check-out ${dateFormat.format(booking.checkOutDate)}. '
        '${booking.nightsCount} ${booking.nightsCount == 1 ? 'noć' : 'noći'}, '
        '${booking.guests} ${booking.guests == 1 ? 'gost' : 'gostiju'}. '
        'Ukupno €${booking.totalPrice.toStringAsFixed(2)}. '
        'Status: ${booking.status.displayName}.';

    return Semantics(
      label: semanticLabel,
      hint: 'Dvostruki dodir za pregled detalja rezervacije',
      button: true,
      child: Card(
        margin: EdgeInsets.only(bottom: AppDimensions.spaceS),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 12)
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.spaceS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8)
                      child: CachedNetworkImage(
                        imageUrl: booking.propertyImage,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 100,
                          color: AppColors.surfaceVariantLight,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: const Icon(
                            Icons.villa_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                booking.propertyName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusChip(context),
                          ],
                        ),
                        SizedBox(height: AppDimensions.spaceXXS),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: AppDimensions.spaceXXS),
                            Expanded(
                              child: Text(
                                booking.propertyLocation,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: AppDimensions.spaceM),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          dateFormat.format(booking.checkInDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 20, color: Colors.grey[400]),
                  SizedBox(width: AppDimensions.spaceXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-out',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          dateFormat.format(booking.checkOutDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spaceXS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.nights_stay,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: AppDimensions.spaceXXS),
                      Text(
                        '${booking.nightsCount} ${_getNightsLabel(booking.nightsCount)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(width: AppDimensions.spaceS),
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: AppDimensions.spaceXXS),
                      Text(
                        '${booking.guests} ${_getGuestsLabel(booking.guests)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    '€${booking.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              if (booking.isCancelled && booking.cancellationReason != null) ...[
                SizedBox(height: AppDimensions.spaceXS),
                Container(
                  padding: EdgeInsets.all(AppDimensions.spaceXS),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS), // 6px modern radius (upgraded from 4)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                      SizedBox(width: AppDimensions.spaceXS),
                      Expanded(
                        child: Text(
                          'Reason: ${booking.cancellationReason}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Cancel button (only for upcoming confirmed bookings)
              if (booking.canCancel && onCancelRequested != null) ...[
                SizedBox(height: AppDimensions.spaceXS),
                const Divider(height: 1),
                SizedBox(height: AppDimensions.spaceXS),
                Semantics(
                  label: 'Otkaži rezervaciju za ${booking.propertyName}',
                  hint: 'Dvostruki dodir za otkazivanje ove rezervacije',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCancelRequested,
                      icon: Icon(Icons.cancel_outlined, size: 18, color: Colors.red[700]),
                      label: Text(
                        'Otkaži Rezervaciju',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[300]!),
                        padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    Color textColor;

    switch (booking.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
      ),
      child: Text(
        booking.status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getNightsLabel(int count) {
    if (count == 1) return 'noć';
    if (count >= 2 && count <= 4) return 'noći';
    return 'noći';
  }

  String _getGuestsLabel(int count) {
    if (count == 1) return 'gost';
    return 'gostiju';
  }
}
