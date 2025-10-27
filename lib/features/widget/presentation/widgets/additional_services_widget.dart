import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../providers/additional_services_provider.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Additional Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          servicesAsync.when(
            data: (services) {
              if (services.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No additional services available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  ...services.map((service) => _buildServiceItem(context, ref, service)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildServicesTotal(ref, services),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading services: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, WidgetRef ref, AdditionalServiceModel service) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final quantity = selectedServices[service.id] ?? 0;
    final isSelected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.blue[50] : Colors.white,
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              if (value == true) {
                ref.read(selectedAdditionalServicesProvider.notifier).update((state) {
                  return {...state, service.id: 1};
                });
              } else {
                ref.read(selectedAdditionalServicesProvider.notifier).update((state) {
                  final newState = Map<String, int>.from(state);
                  newState.remove(service.id);
                  return newState;
                });
              }
            },
          ),
          const SizedBox(width: 8),

          // Service details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (service.description != null && service.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  service.formattedPrice,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),

          // Quantity selector (only show if service is selected)
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: quantity > 1
                        ? () {
                            ref.read(selectedAdditionalServicesProvider.notifier).update((state) {
                              return {...state, service.id: quantity - 1};
                            });
                          }
                        : null,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () {
                      // Check max quantity
                      if (service.maxQuantity != null && quantity >= service.maxQuantity!) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Maximum quantity: ${service.maxQuantity}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      ref.read(selectedAdditionalServicesProvider.notifier).update((state) {
                        return {...state, service.id: quantity + 1};
                      });
                    },
                    padding: const EdgeInsets.all(4),
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

  Widget _buildServicesTotal(WidgetRef ref, List<AdditionalServiceModel> services) {
    final selectedServices = ref.watch(selectedAdditionalServicesProvider);
    final total = ref.watch(additionalServicesTotalProvider((services, selectedServices, nights, guests)));

    if (selectedServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Services Total',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '€${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }
}
