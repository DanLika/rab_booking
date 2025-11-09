import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../widgets/price_list_calendar_widget.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/common_gradient_app_bar.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Gradient header
            CommonGradientAppBar(
              title: 'Cjenovnik',
              leadingIcon: Icons.arrow_back,
              onLeadingIconTap: (context) => Navigator.of(context).pop(),
            ),

            // Base price section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 20,
                  isMobile ? 16 : 24,
                  isMobile ? 8 : 12,
                ),
                child: _buildBasePriceSection(isMobile),
              ),
            ),

            // Calendar section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 8 : 12,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 20,
                ),
                child: PriceListCalendarWidget(unit: widget.unit),
              ),
            ),

            // Bottom spacing
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildBasePriceSection(bool isMobile) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      shadowColor: theme.colorScheme.shadow.withAlpha((0.05 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((0.1 * 255).toInt()),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon - Minimalist
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.euro_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Osnovna Cijena',
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ovo je default cijena po noćenju koja se koristi kada nema posebnih cijena.',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Price input and save button - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                // Use responsive breakpoint considering card padding and margins
                // Mobile/Small tablets: < 500px → Column (vertical stacking)
                // Desktop/Large tablets: >= 500px → Row (horizontal layout)
                final isVerySmall = constraints.maxWidth < 500;

                if (isVerySmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _basePriceController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          prefixText: '€ ',
                          prefixIcon: const Icon(Icons.euro_outlined, size: 20),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha((0.25 * 255).toInt()),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
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
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Sačuvaj Cijenu'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          prefixText: '€ ',
                          prefixIcon: const Icon(Icons.euro_outlined, size: 20),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha((0.25 * 255).toInt()),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
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
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Sačuvaj'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
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
