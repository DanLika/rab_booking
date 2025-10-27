import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/unit_model.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Booking summary sidebar (sticky on desktop, collapsible on mobile)
class BookingSummarySidebar extends ConsumerWidget {
  final VoidCallback? onReserve;
  final bool showReserveButton;

  const BookingSummarySidebar({
    super.key,
    this.onReserve,
    this.showReserveButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(selectedRoomProvider);
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);
    final adults = ref.watch(adultsCountProvider);
    final children = ref.watch(childrenCountProvider);
    final nights = ref.watch(numberOfNightsProvider);
    final selectedServices = ref.watch(selectedServicesProvider);
    final total = ref.watch(bookingTotalProvider);

    if (room == null) {
      return const SizedBox.shrink();
    }

    // Calculate services total
    double servicesTotal = 0;
    selectedServices.forEach((serviceId, quantity) {
      servicesTotal += 10.0 * quantity; // Simplified, should fetch actual price
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BedBookingCards.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Room name dropdown (placeholder for now)
          Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: BedBookingTextStyles.heading3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 24),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: BedBookingColors.borderGrey),
          const SizedBox(height: 16),

          // Check-in
          if (checkIn != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: BedBookingColors.textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('E, dd MMM yyyy').format(checkIn),
                        style: BedBookingTextStyles.bodyBold,
                      ),
                      const Text(
                        'from 14:00',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Check-out
          if (checkOut != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: BedBookingColors.textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('E, dd MMM yyyy').format(checkOut),
                        style: BedBookingTextStyles.bodyBold,
                      ),
                      const Text(
                        'to 10:00',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Guests
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: BedBookingColors.textGrey),
              const SizedBox(width: 8),
              Text(
                '$adults ${adults == 1 ? 'adult' : 'adults'}',
                style: BedBookingTextStyles.body,
              ),
              if (children > 0) ...[
                const Text(', ', style: BedBookingTextStyles.body),
                Text(
                  '$children ${children == 1 ? 'child' : 'children'}',
                  style: BedBookingTextStyles.body,
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: BedBookingColors.borderGrey),
          const SizedBox(height: 16),

          // Pricing breakdown
          _buildPriceRow('Number of rooms', '1'),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Price per day',
            '\$${room.pricePerNight.toStringAsFixed(2)} USD',
          ),
          const SizedBox(height: 8),
          _buildPriceRow('Number of nights', '$nights'),

          if (servicesTotal > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Additional services',
              '${servicesTotal.toStringAsFixed(0)} USD',
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: BedBookingColors.borderGrey),
          const SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: BedBookingTextStyles.heading3,
              ),
              Text(
                '\$${total.toStringAsFixed(2)} USD',
                style: BedBookingTextStyles.price,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Secure shopping badge
          Row(
            children: [
              const Icon(
                Icons.lock,
                size: 16,
                color: BedBookingColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Secure shopping (SSL)',
                style: BedBookingTextStyles.small.copyWith(
                  color: BedBookingColors.success,
                ),
              ),
            ],
          ),

          if (showReserveButton && onReserve != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReserve,
                style: BedBookingButtons.primaryButton,
                child: const Text('Reserve'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: BedBookingTextStyles.body),
        Text(value, style: BedBookingTextStyles.bodyBold),
      ],
    );
  }
}
