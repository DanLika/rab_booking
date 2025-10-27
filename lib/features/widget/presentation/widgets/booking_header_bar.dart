import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Green header bar with date/guest selector (matching BedBooking screenshots)
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: BedBookingColors.primaryGreen,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Date range selector
          InkWell(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    checkIn != null
                        ? DateFormat('E, dd MMM yyyy').format(checkIn)
                        : 'Select check-in',
                    style: BedBookingTextStyles.bodyBold,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    checkOut != null
                        ? DateFormat('E, dd MMM yyyy').format(checkOut)
                        : 'Select check-out',
                    style: BedBookingTextStyles.bodyBold,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Guest selector
          InkWell(
            onTap: onGuestTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$adults ${adults == 1 ? 'adult' : 'adults'}',
                    style: BedBookingTextStyles.bodyBold,
                  ),
                  if (children > 0) ...[
                    const Text(', ', style: BedBookingTextStyles.body),
                    Text(
                      '$children ${children == 1 ? 'child' : 'children'}',
                      style: BedBookingTextStyles.bodyBold,
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
