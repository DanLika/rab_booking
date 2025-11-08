import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../widgets/price_list_calendar_widget.dart';
import '../../../../core/utils/error_display_utils.dart';

/// Screen for managing unit pricing (base price and bulk month pricing)
class UnitPricingScreen extends ConsumerStatefulWidget {
  final UnitModel unit;

  const UnitPricingScreen({
    super.key,
    required this.unit,
  });

  @override
  ConsumerState<UnitPricingScreen> createState() => _UnitPricingScreenState();
}

class _UnitPricingScreenState extends ConsumerState<UnitPricingScreen> {
  final _basePriceController = TextEditingController();
  bool _isUpdatingBasePrice = false;

  @override
  void initState() {
    super.initState();
    _basePriceController.text = widget.unit.pricePerNight.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cijene - ${widget.unit.name}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Base price section (compact)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBasePriceSection(),
          ),

          const Divider(),

          // BedBooking-style Price List Calendar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PriceListCalendarWidget(unit: widget.unit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasePriceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.euro, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Osnovna Cijena',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ovo je default cijena po noćenju koja se koristi kada nema posebnih cijena.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textColorSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _basePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          border: OutlineInputBorder(),
                          prefixText: '€ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isUpdatingBasePrice ? null : _updateBasePrice,
                        icon: _isUpdatingBasePrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Sačuvaj Cijenu'),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _basePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          border: OutlineInputBorder(),
                          prefixText: '€ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isUpdatingBasePrice ? null : _updateBasePrice,
                        icon: _isUpdatingBasePrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Sačuvaj'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBasePrice() async {
    final priceText = _basePriceController.text.trim();
    if (priceText.isEmpty) {
      ErrorDisplayUtils.showWarningSnackBar(context, 'Unesite cijenu');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ErrorDisplayUtils.showWarningSnackBar(context, 'Cijena mora biti veća od 0');
      return;
    }

    setState(() => _isUpdatingBasePrice = true);

    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);
      await repository.updateUnit(
        propertyId: widget.unit.propertyId,
        unitId: widget.unit.id,
        basePrice: price,
      );

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Osnovna cijena uspješno ažurirana',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri ažuriranju cijene',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingBasePrice = false);
      }
    }
  }
}
