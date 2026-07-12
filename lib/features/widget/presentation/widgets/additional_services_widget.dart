import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../providers/additional_services_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design/tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
import '../l10n/widget_translations.dart';

class AdditionalServicesWidget extends ConsumerWidget {
  final String propertyId;
  final String unitId;
  final int nights;
  final int guests;

  /// Callback when service selection changes (for iframe height updates)
  final VoidCallback? onSelectionChanged;

  const AdditionalServicesWidget({
    super.key,
    required this.propertyId,
    required this.unitId,
    this.nights = 1,
    this.guests = 1,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(
      unitAdditionalServicesProvider((propertyId: propertyId, unitId: unitId)),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return servicesAsync.when(
      data: (services) {
        // Don't show widget at all if no services are available
        if (services.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildServicesWidget(
          context,
          ref,
          services,
          isDarkMode,
          colors,
          onSelectionChanged,
        );
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
    MinimalistColorSchemeAdapter colors,
    VoidCallback? onSelectionChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: const BorderRadius.all(
          Radius.circular(BBRadiusBridges.medium),
        ),
        border: Border.all(color: colors.borderDefault),
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
              Icon(Icons.add_circle, color: colors.buttonPrimary),
              const SizedBox(width: BBSpace.xxs),
              Text(
                WidgetTranslations.of(context, ref).additionalServices,
                style: TextStyle(
                  fontSize: BBTypeBridges.fontSizeL,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.sm),
          Column(
            children: [
              ...services.map(
                (service) => _buildServiceItem(
                  context,
                  ref,
                  service,
                  colors,
                  onSelectionChanged,
                ),
              ),
              const SizedBox(height: BBSpace.sm),
              Divider(color: colors.borderDefault),
              const SizedBox(height: BBSpace.xxs),
              _buildServicesTotal(context, ref, services, colors),
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
    MinimalistColorSchemeAdapter colors,
    VoidCallback? onSelectionChanged,
  ) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final quantity = selectedServices[service.id] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: BBSpace.xs),
      padding: const EdgeInsets.all(BBSpace.xs),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? colors.borderStrong : colors.borderDefault,
          width: isSelected ? BBBorderWidth.medium : BBBorderWidth.thin,
        ),
        borderRadius: BBRadius.xsAll,
        color: isSelected
            ? colors.backgroundSecondary
            : colors.backgroundPrimary,
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: isSelected,
            activeColor: colors.textPrimary,
            checkColor: colors.backgroundPrimary,
            side: BorderSide(color: colors.textSecondary),
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
              // Notify parent for iframe height update
              onSelectionChanged?.call();
            },
          ),
          const SizedBox(width: BBSpace.xxs),

          // Service details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  // Owner-entered, so arbitrarily long — cap it rather than let it
                  // push the price out of the row.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeM,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: BBSpaceBridges.xxs2),
                    child: Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: BBTypeBridges.fontSizeXS,
                        color: colors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                const SizedBox(height: BBSpaceBridges.xxs2),
                Text(
                  service.formattedPrice,
                  style: TextStyle(
                    fontSize: BBTypeBridges.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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
                border: Border.all(color: colors.borderDefault),
                borderRadius: BBRadius.xsAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove,
                      size: 16,
                      color: colors.textPrimary,
                    ),
                    tooltip: '${service.name} −',
                    onPressed: quantity > 1
                        ? () {
                            ref
                                .read(
                                  selectedAdditionalServicesProvider.notifier,
                                )
                                .update((state) {
                                  return {...state, service.id: quantity - 1};
                                });
                            onSelectionChanged?.call();
                          }
                        : null,
                    padding: const EdgeInsets.all(BBSpaceBridges.xxs2),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BBSpace.xxs,
                    ),
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontSize: BBTypeBridges.fontSizeS,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 16, color: colors.textPrimary),
                    tooltip: '${service.name} +',
                    onPressed: () {
                      // Check max quantity - use local variable to avoid null assertion
                      final maxQuantity = service.maxQuantity;
                      if (maxQuantity != null && quantity >= maxQuantity) {
                        SnackBarHelper.showWarning(
                          context: context,
                          message: WidgetTranslations.of(
                            context,
                            ref,
                          ).maxQuantityReached(maxQuantity),
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }

                      ref
                          .read(selectedAdditionalServicesProvider.notifier)
                          .update((state) {
                            return {...state, service.id: quantity + 1};
                          });
                      onSelectionChanged?.call();
                    },
                    padding: const EdgeInsets.all(BBSpaceBridges.xxs2),
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
    BuildContext context,
    WidgetRef ref,
    List<AdditionalServiceModel> services,
    MinimalistColorSchemeAdapter colors,
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
          WidgetTranslations.of(context, ref).servicesTotal,
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeM,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          // Bug Fix: Use localized currency symbol instead of hardcoded '€'
          '${WidgetTranslations.of(context, ref).currencySymbol}${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: BBTypeBridges.fontSizeL,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
