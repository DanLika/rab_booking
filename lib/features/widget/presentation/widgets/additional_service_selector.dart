import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../providers/booking_flow_provider.dart';
import '../../../../core/design_tokens/design_tokens.dart';

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
      padding: const EdgeInsets.all(SpacingTokens.m),
      margin: const EdgeInsets.only(bottom: SpacingTokens.s),
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundCard,
        borderRadius: BorderTokens.circularSmall,
        border: Border.all(
          color: ColorTokens.light.borderDefault,
          width: BorderTokens.widthThin,
        ),
      ),
      child: Row(
        children: [
          // Service name and price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.light.textPrimary,
                    fontFamily: TypographyTokens.primaryFont,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  _getPriceText(),
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: ColorTokens.light.textSecondary,
                    fontFamily: TypographyTokens.primaryFont,
                  ),
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
                  width: ConstraintTokens.minTouchTarget,
                  height: ConstraintTokens.minTouchTarget,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: quantity > 0
                          ? ColorTokens.light.textPrimary
                          : ColorTokens.light.borderDefault,
                      width: BorderTokens.widthMedium,
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: TypographyTokens.fontSizeXXL,
                    color: quantity > 0
                        ? ColorTokens.light.textPrimary
                        : ColorTokens.light.textSecondary,
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
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.light.textPrimary,
                    fontFamily: TypographyTokens.primaryFont,
                  ),
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
                  width: ConstraintTokens.minTouchTarget,
                  height: ConstraintTokens.minTouchTarget,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorTokens.light.textPrimary,
                      width: BorderTokens.widthMedium,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: TypographyTokens.fontSizeXXL,
                    color: ColorTokens.light.textPrimary,
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
