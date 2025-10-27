import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Additional service selector with quantity counter
class AdditionalServiceSelector extends ConsumerWidget {
  final AdditionalServiceModel service;

  const AdditionalServiceSelector({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServices = ref.watch(selectedServicesProvider);
    final quantity = selectedServices[service.id] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BedBookingCards.borderedCard,
      child: Row(
        children: [
          // Service name and price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: BedBookingTextStyles.bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  _getPriceText(),
                  style: BedBookingTextStyles.small,
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              // Minus button
              IconButton(
                onPressed: quantity > 0
                    ? () {
                        final updated = Map<String, int>.from(selectedServices);
                        if (quantity == 1) {
                          updated.remove(service.id);
                        } else {
                          updated[service.id] = quantity - 1;
                        }
                        ref.read(selectedServicesProvider.notifier).state = updated;
                      }
                    : null,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: quantity > 0
                          ? BedBookingColors.textDark
                          : BedBookingColors.borderGrey,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 20,
                    color: quantity > 0
                        ? BedBookingColors.textDark
                        : BedBookingColors.textGrey,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),

              // Quantity display
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: BedBookingTextStyles.bodyBold,
                ),
              ),

              // Plus button
              IconButton(
                onPressed: () {
                  final updated = Map<String, int>.from(selectedServices);
                  updated[service.id] = quantity + 1;
                  ref.read(selectedServicesProvider.notifier).state = updated;
                },
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BedBookingColors.textDark,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: BedBookingColors.textDark,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPriceText() {
    // Use the model's formatted price
    return service.formattedPrice.replaceAll('€', '\$').replaceAll('EUR', 'USD');
  }
}
