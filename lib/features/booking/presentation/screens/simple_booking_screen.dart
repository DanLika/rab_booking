import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/simple_booking_provider.dart';
import '../../../properties/domain/models/unit.dart';
import '../../../properties/presentation/providers/units_provider.dart';

/// Simple booking screen - Minimal MVP version
/// Just contact info + dates from calendar
class SimpleBookingScreen extends ConsumerStatefulWidget {
  final String unitId;
  final List<DateTime> selectedDates;
  final double totalPrice;

  const SimpleBookingScreen({
    super.key,
    required this.unitId,
    required this.selectedDates,
    required this.totalPrice,
  });

  @override
  ConsumerState<SimpleBookingScreen> createState() => _SimpleBookingScreenState();
}

class _SimpleBookingScreenState extends ConsumerState<SimpleBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  int _numberOfGuests = 2;
  String _specialRequests = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitAsync = ref.watch(unitByIdProvider(widget.unitId));
    final bookingState = ref.watch(simpleBookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrda rezervacije'),
      ),
      body: unitAsync.when(
        data: (unit) {
          if (unit == null) {
            return const Center(child: Text('Jedinica nije pronađena'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unit info
                  _buildUnitInfo(unit),
                  const SizedBox(height: 24),

                  // Booking summary
                  _buildBookingSummary(),
                  const SizedBox(height: 24),

                  // Guest details form
                  Text(
                    'Podaci o gostu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // First name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ime *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Molimo unesite ime';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Last name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prezime *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Molimo unesite prezime';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Molimo unesite email';
                      }
                      if (!value.contains('@')) {
                        return 'Neispravan email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Molimo unesite telefon';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Number of guests
                  DropdownButtonFormField<int>(
                    value: _numberOfGuests,
                    decoration: const InputDecoration(
                      labelText: 'Broj gostiju *',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      unit.maxGuests,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1} ${index == 0 ? 'gost' : 'gostiju'}'),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _numberOfGuests = value ?? 2;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Special requests
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Posebni zahtjevi (opciono)',
                      border: OutlineInputBorder(),
                      hintText: 'Upišite eventualne posebne zahtjeve...',
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _specialRequests = value;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  ElevatedButton(
                    onPressed: bookingState.isLoading
                        ? null
                        : () => _submitBooking(unit),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: bookingState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Potvrdi rezervaciju',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  if (bookingState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bookingState.error!,
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Greška: $error')),
      ),
    );
  }

  Widget _buildUnitInfo(Unit unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unit.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (unit.description != null) ...[
              const SizedBox(height: 8),
              Text(
                unit.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Do ${unit.maxGuests} gostiju'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    final nights = widget.selectedDates.length;
    final checkIn = widget.selectedDates.first;
    final checkOut = widget.selectedDates.last.add(const Duration(days: 1));
    final advanceAmount = widget.totalPrice * 0.2; // 20% avans

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pregled rezervacije',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Check-in:'),
                Text(
                  DateFormat('dd.MM.yyyy').format(checkIn),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Check-out:'),
                Text(
                  DateFormat('dd.MM.yyyy').format(checkOut),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Broj noćenja:'),
                Text(
                  '$nights ${nights == 1 ? 'noć' : nights < 5 ? 'noći' : 'noći'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ukupna cijena:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '€${widget.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avans (20%):',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '€${advanceAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking(Unit unit) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final checkIn = widget.selectedDates.first;
    final checkOut = widget.selectedDates.last.add(const Duration(days: 1));

    final success = await ref.read(simpleBookingProvider.notifier).createBooking(
          unitId: widget.unitId,
          unitName: unit.name,
          guestFirstName: _firstNameController.text,
          guestLastName: _lastNameController.text,
          guestEmail: _emailController.text,
          guestPhone: _phoneController.text,
          numberOfGuests: _numberOfGuests,
          checkIn: checkIn,
          checkOut: checkOut,
          totalPrice: widget.totalPrice,
          specialRequests: _specialRequests.isEmpty ? null : _specialRequests,
        );

    if (success && mounted) {
      // Navigate to payment instructions screen
      Navigator.of(context).pushReplacementNamed(
        '/booking/payment-instructions',
        arguments: {
          'bookingId': ref.read(simpleBookingProvider).bookingId,
          'totalPrice': widget.totalPrice,
          'guestEmail': _emailController.text,
        },
      );
    }
  }
}

/// Provider for getting unit by ID (public access for embed)
final unitByIdProvider = FutureProvider.family<Unit?, String>((ref, unitId) async {
  final repository = ref.watch(unitsRepositoryProvider);
  return repository.getUnitById(unitId);
});
