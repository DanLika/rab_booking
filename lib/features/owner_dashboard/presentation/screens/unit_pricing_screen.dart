import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/price_list_calendar_widget.dart';

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
  final _monthPriceController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();
  bool _isUpdatingBasePrice = false;
  bool _isSettingMonthPrice = false;

  @override
  void initState() {
    super.initState();
    _basePriceController.text = widget.unit.pricePerNight.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _monthPriceController.dispose();
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
                    color: AppColors.textSecondaryLight,
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

  Widget _buildBulkMonthPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Postavi Cijene za Mjesec',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Postavite istu cijenu za sve dane u odabranom mjesecu.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 24),

            // Month selector
            InkWell(
              onTap: _selectMonth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM().format(_selectedMonth),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _monthPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          border: OutlineInputBorder(),
                          prefixText: '€ ',
                          hintText: 'Npr. 50',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isSettingMonthPrice ? null : _setMonthPrices,
                        icon: _isSettingMonthPrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Postavi Cijenu'),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _monthPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          border: OutlineInputBorder(),
                          prefixText: '€ ',
                          hintText: 'Npr. 50',
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
                        onPressed: _isSettingMonthPrice ? null : _setMonthPrices,
                        icon: _isSettingMonthPrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Postavi'),
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

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Kako funkcionira?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Osnovna cijena se koristi kao default za sve datume\n'
            '2. Možete postaviti cijenu za cijeli mjesec odjednom\n'
            '3. Možete kasnije individualno promijeniti cijenu za određene dane\n'
            '4. Sistem će uvijek provjeriti: custom cijena → osnovna cijena',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month, 1);
      });
    }
  }

  Future<void> _updateBasePrice() async {
    final priceText = _basePriceController.text.trim();
    if (priceText.isEmpty) {
      _showError('Unesite cijenu');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Cijena mora biti veća od 0');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Osnovna cijena uspješno ažurirana')),
        );
      }
    } catch (e) {
      _showError('Greška: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingBasePrice = false);
      }
    }
  }

  Future<void> _setMonthPrices() async {
    final priceText = _monthPriceController.text.trim();
    if (priceText.isEmpty) {
      _showError('Unesite cijenu');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Cijena mora biti veća od 0');
      return;
    }

    // Calculate first and last day of selected month
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda'),
        content: Text(
          'Postaviti cijenu od €$price za sve dane u mjesecu ${DateFormat.yMMMM().format(_selectedMonth)}?\n\n'
          'To je ukupno ${lastDay.day} dana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSettingMonthPrice = true);

    try {
      final repository = ref.read(dailyPriceRepositoryProvider);
      await repository.bulkUpdatePrices(
        unitId: widget.unit.id,
        startDate: firstDay,
        endDate: lastDay,
        price: price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uspješno postavljeno ${lastDay.day} cijena za ${DateFormat.yMMMM().format(_selectedMonth)}'),
          ),
        );
        _monthPriceController.clear();
      }
    } catch (e) {
      _showError('Greška: $e');
    } finally {
      if (mounted) {
        setState(() => _isSettingMonthPrice = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
