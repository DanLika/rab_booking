import 'package:flutter/material.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';

/// Room row header widget
/// Shows room/unit information in the left column of calendar grid
class RoomRowHeader extends StatelessWidget {
  final UnitModel unit;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool isCompact;
  final List<BookingModel>? bookings; // Bookings for this unit

  const RoomRowHeader({
    super.key,
    required this.unit,
    required this.width,
    required this.height,
    this.onTap,
    this.isCompact = false,
    this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            right: BorderSide(color: theme.dividerColor),
            bottom: BorderSide(color: theme.dividerColor.withAlpha((0.3 * 255).toInt())),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: 8,
        ),
        child: isCompact ? _buildCompactContent(theme) : _buildFullContent(theme),
      ),
    );
  }

  Widget _buildCompactContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room name with status dots
        Row(
          children: [
            Expanded(
              child: Text(
                unit.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (bookings != null && bookings!.isNotEmpty) ...[
              const SizedBox(width: 2),
              _buildStatusDots(),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bed,
              size: 16,
              color: theme.textTheme.bodySmall?.color?.withAlpha((0.7 * 255).toInt()),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.person,
              size: 16,
              color: theme.textTheme.bodySmall?.color?.withAlpha((0.7 * 255).toInt()),
            ),
            const SizedBox(width: 2),
            Text(
              '${unit.maxGuests}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullContent(ThemeData theme) {
    return Row(
      children: [
        // Bed icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bed,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),

        // Unit info
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room name with status dots
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bookings != null && bookings!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _buildStatusDots(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.maxGuests} guests',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build status dots based on booking statuses
  Widget _buildStatusDots() {
    if (bookings == null || bookings!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Count bookings by status
    final statusCounts = <BookingStatus, int>{};
    for (final booking in bookings!) {
      statusCounts[booking.status] = (statusCounts[booking.status] ?? 0) + 1;
    }

    // Determine which dots to show (max 3)
    final List<Color> dotColors = [];

    // Priority: pending > confirmed > in_progress > blocked > completed > cancelled
    if (statusCounts[BookingStatus.pending] != null && statusCounts[BookingStatus.pending]! > 0) {
      dotColors.add(AppColors.warning); // Orange - waiting approval
    }
    if (statusCounts[BookingStatus.confirmed] != null && statusCounts[BookingStatus.confirmed]! > 0) {
      dotColors.add(AppColors.error); // Red - booked
    }
    if (statusCounts[BookingStatus.inProgress] != null && statusCounts[BookingStatus.inProgress]! > 0) {
      dotColors.add(AppColors.info); // Blue - in progress
    }
    if (statusCounts[BookingStatus.blocked] != null && statusCounts[BookingStatus.blocked]! > 0) {
      dotColors.add(AppColors.textSecondary); // Gray - disabled/blocked
    }

    // Limit to 3 dots
    final displayDots = dotColors.take(3).toList();

    if (displayDots.isEmpty) {
      // No active bookings, show green dot (available)
      return const _StatusDot(color: AppColors.success); // Green - free
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: displayDots
          .map((color) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: _StatusDot(color: color),
              ))
          .toList(),
    );
  }
}

/// Status dot widget
class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.3 * 255).toInt()),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
