import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../providers/additional_services_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../utils/snackbar_helper.dart';

class AdditionalServicesWidget extends ConsumerWidget {
  final String unitId;
  final int nights;
  final int guests;

  const AdditionalServicesWidget({
    super.key,
    required this.unitId,
    this.nights = 1,
    this.guests = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(unitAdditionalServicesProvider(unitId));
    final isDarkMode = ref.watch(themeProvider);

    // Helper function to get theme-aware colors
    Color getColor(Color light, Color dark) => isDarkMode ? dark : light;

    return servicesAsync.when(
      data: (services) {
        // Don't show widget at all if no services are available
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildServicesWidget(context, ref, services, isDarkMode, getColor);
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildServicesWidget(
    BuildContext context,
    WidgetRef ref,
    List<AdditionalServiceModel> services,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundPrimary,
          MinimalistColorsDark.backgroundPrimary,
        ),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
        boxShadow: isDarkMode
            ? MinimalistShadows.medium
            : MinimalistShadows.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle,
                color: getColor(
                  MinimalistColors.buttonPrimary,
                  MinimalistColorsDark.buttonPrimary,
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Additional Services',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeL,
                  fontWeight: FontWeight.bold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.m),
          Column(
            children: [
              ...services.map(
                (service) => _buildServiceItem(
                  context,
                  ref,
                  service,
                  isDarkMode,
                  getColor,
                ),
              ),
              const SizedBox(height: SpacingTokens.m),
              Divider(
                color: getColor(
                  MinimalistColors.borderDefault,
                  MinimalistColorsDark.borderDefault,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              _buildServicesTotal(ref, services, isDarkMode, getColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    WidgetRef ref,
    AdditionalServiceModel service,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final quantity = selectedServices[service.id] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.s),
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? getColor(
                  MinimalistColors.statusAvailableBorder,
                  MinimalistColorsDark.statusAvailableBorder,
                )
              : getColor(
                  MinimalistColors.borderDefault,
                  MinimalistColorsDark.borderDefault,
                ),
          width: isSelected ? BorderTokens.widthMedium : BorderTokens.widthThin,
        ),
        borderRadius: BorderTokens.circularSmall,
        color: isSelected
            ? getColor(
                MinimalistColors.statusAvailableBackground,
                MinimalistColorsDark.statusAvailableBackground,
              )
            : getColor(
                MinimalistColors.backgroundPrimary,
                MinimalistColorsDark.backgroundPrimary,
              ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              if (value == true) {
                ref.read(selectedAdditionalServicesProvider.notifier).update((
                  state,
                ) {
                  return {...state, service.id: 1};
                });
              } else {
                ref.read(selectedAdditionalServicesProvider.notifier).update((
                  state,
                ) {
                  final newState = Map<String, int>.from(state);
                  newState.remove(service.id);
                  return newState;
                });
              }
            },
          ),
          const SizedBox(width: SpacingTokens.xs),

          // Service details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                    fontFamily: 'Manrope',
                  ),
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: SpacingTokens.xxs),
                    child: Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeXS,
                        color: getColor(
                          MinimalistColors.textSecondary,
                          MinimalistColorsDark.textSecondary,
                        ),
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  service.formattedPrice,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: getColor(
                      MinimalistColors.statusAvailableBorder,
                      MinimalistColorsDark.statusAvailableBorder,
                    ),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),

          // Quantity selector (only show if service is selected)
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: getColor(
                    MinimalistColors.borderDefault,
                    MinimalistColorsDark.borderDefault,
                  ),
                ),
                borderRadius: BorderTokens.circularSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove,
                      size: 16,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                    onPressed: quantity > 1
                        ? () {
                            ref
                                .read(
                                  selectedAdditionalServicesProvider.notifier,
                                )
                                .update((state) {
                                  return {...state, service.id: quantity - 1};
                                });
                          }
                        : null,
                    padding: const EdgeInsets.all(SpacingTokens.xxs),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xs,
                    ),
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeS,
                        fontWeight: FontWeight.bold,
                        color: getColor(
                          MinimalistColors.textPrimary,
                          MinimalistColorsDark.textPrimary,
                        ),
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                    onPressed: () {
                      // Check max quantity
                      if (service.maxQuantity != null &&
                          quantity >= service.maxQuantity!) {
                        SnackBarHelper.showWarning(
                          context: context,
                          message: 'Maximum quantity: ${service.maxQuantity}',
                          isDarkMode: isDarkMode,
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }

                      ref
                          .read(selectedAdditionalServicesProvider.notifier)
                          .update((state) {
                            return {...state, service.id: quantity + 1};
                          });
                    },
                    padding: const EdgeInsets.all(SpacingTokens.xxs),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesTotal(
    WidgetRef ref,
    List<AdditionalServiceModel> services,
    bool isDarkMode,
    Color Function(Color, Color) getColor,
  ) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final total = ref.watch(
      additionalServicesTotalProvider((
        services,
        selectedServices,
        nights,
        guests,
      )),
    );

    if (selectedServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Services Total',
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            fontWeight: FontWeight.bold,
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          '€${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeL,
            fontWeight: FontWeight.bold,
            color: getColor(
              MinimalistColors.statusAvailableBorder,
              MinimalistColorsDark.statusAvailableBorder,
            ),
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
