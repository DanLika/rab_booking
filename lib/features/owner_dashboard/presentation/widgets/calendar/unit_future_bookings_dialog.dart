import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';

/// Dialog showing all future bookings for a specific unit
class UnitFutureBookingsDialog extends StatelessWidget {
  final UnitModel unit;
  final List<BookingModel> bookings;
  final Function(BookingModel) onBookingTap;

  const UnitFutureBookingsDialog({
    required this.unit,
    required this.bookings,
    required this.onBookingTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppDimensions.mobile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: isMobile ? screenWidth * 0.90 : 600,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
        ),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.gradients.sectionBorder.withAlpha(
              (0.5 * 255).toInt(),
            ),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient (matching CommonAppBar)
            Container(
              padding: EdgeInsets.all(
                isMobile ? AppDimensions.spaceS : AppDimensions.spaceM,
              ),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: AutoSizeText(
                      l10n.futureBookingsTitle(unit.name),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    tooltip: l10n.futureBookingsClose,
                  ),
                ],
              ),
            ),

            // Bookings list
            Flexible(
              child: bookings.isEmpty
                  ? _buildEmptyState(context, l10n)
                  : ListView.separated(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      itemCount: bookings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildBookingTile(
                          context,
                          booking,
                          isMobile,
                          l10n,
                        );
                      },
                    ),
            ),

            // Footer with styled background
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dialogFooterDark
                    : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.sectionDividerDark
                        : AppColors.sectionDividerLight,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Booking count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(
                        (0.1 * 255).toInt(),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.futureBookingsCount(bookings.length),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(l10n.futureBookingsClose),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              l10n.futureBookingsEmpty,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(
              l10n.futureBookingsEmptySubtitle(unit.name),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTile(
    BuildContext context,
    BookingModel booking,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isInProgress =
        booking.checkIn.isBefore(now) && booking.checkOut.isAfter(now);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onBookingTap(booking);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252330) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with gradient background
              Container(
                width: isMobile ? 44 : 48,
                height: isMobile ? 44 : 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      booking.status.color.withAlpha((0.2 * 255).toInt()),
                      booking.status.color.withAlpha((0.1 * 255).toInt()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: booking.status.color.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: Icon(
                  isInProgress ? Icons.person : Icons.person_outline,
                  color: booking.status.color,
                  size: isMobile ? 22 : 24,
                ),
              ),
              const SizedBox(width: 12),

              // Booking info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guest name
                    AutoSizeText(
                      booking.guestName ?? l10n.futureBookingsUnknownGuest,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),

                    // Check-in with icon badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(
                              (0.15 * 255).toInt(),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.login,
                            size: 12,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoSizeText(
                            l10n.futureBookingsCheckIn(
                              '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            minFontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Check-out with icon badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(
                              (0.15 * 255).toInt(),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.logout,
                            size: 12,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AutoSizeText(
                            l10n.futureBookingsCheckOut(
                              '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            minFontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Guest count and nights in badges
                    Row(
                      children: [
                        _buildInfoBadge(
                          Icons.people_outline,
                          '${booking.guestCount}',
                          theme,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoBadge(
                          Icons.nights_stay_outlined,
                          '$nights',
                          theme,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status chip - compact
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: booking.status.color.withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: booking.status.color.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: Text(
                  booking.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: booking.status.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(
    IconData icon,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D3A) : const Color(0xFFF5F5FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
