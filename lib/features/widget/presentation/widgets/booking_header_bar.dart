import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/villa_jasko_colors.dart';
import '../theme/responsive_helper.dart';

/// Azure Blue header bar with date/guest selector
/// Responsive: Desktop (horizontal row), Mobile (vertical stack)
class BookingHeaderBar extends ConsumerWidget {
  final VoidCallback? onDateTap;
  final VoidCallback? onGuestTap;

  const BookingHeaderBar({
    super.key,
    this.onDateTap,
    this.onGuestTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);
    final adults = ref.watch(adultsCountProvider);
    final children = ref.watch(childrenCountProvider);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VillaJaskoColors.primary,
            Color(0xFF0052CC), // Darker Azure Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: VillaJaskoColors.shadowMedium,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateSelector(checkIn, checkOut, isMobile),
                const SizedBox(height: 12),
                _buildGuestSelector(adults, children, isMobile),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDateSelector(checkIn, checkOut, isMobile),
                const SizedBox(width: 20),
                _buildGuestSelector(adults, children, isMobile),
              ],
            ),
    );
  }

  Widget _buildDateSelector(DateTime? checkIn, DateTime? checkOut, bool isMobile) {
    return InkWell(
      onTap: onDateTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: VillaJaskoColors.backgroundSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: VillaJaskoColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: VillaJaskoColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              Icons.calendar_today,
              size: isMobile ? 18 : 20,
              color: VillaJaskoColors.primary,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                checkIn != null
                    ? DateFormat('E, dd MMM yyyy').format(checkIn)
                    : 'Check-in',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: checkIn != null
                      ? VillaJaskoColors.textPrimary
                      : VillaJaskoColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: isMobile ? 14 : 16,
                color: VillaJaskoColors.primary,
              ),
            ),
            Flexible(
              child: Text(
                checkOut != null
                    ? DateFormat('E, dd MMM yyyy').format(checkOut)
                    : 'Check-out',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: checkOut != null
                      ? VillaJaskoColors.textPrimary
                      : VillaJaskoColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelector(int adults, int children, bool isMobile) {
    return InkWell(
      onTap: onGuestTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: VillaJaskoColors.backgroundSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: VillaJaskoColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: VillaJaskoColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              Icons.people,
              size: isMobile ? 18 : 20,
              color: VillaJaskoColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '$adults ${adults == 1 ? 'adult' : 'adults'}',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: VillaJaskoColors.textPrimary,
              ),
            ),
            if (children > 0) ...[
              Text(
                ', ',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16,
                  color: VillaJaskoColors.textPrimary,
                ),
              ),
              Text(
                '$children ${children == 1 ? 'child' : 'children'}',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: VillaJaskoColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              size: 22,
              color: VillaJaskoColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
