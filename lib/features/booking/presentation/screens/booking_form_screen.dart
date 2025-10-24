import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/models/booking.dart';
import '../providers/booking_provider.dart';

/// Booking Form Screen - Gost unosi svoje podatke
/// Nakon što je odabrao datume u kalendaru
class BookingFormScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String unitName;
  final List<DateTime> selectedDates;
  final double totalPrice;

  const BookingFormScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    required this.selectedDates,
    required this.totalPrice,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  int _guestCount = 1;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nights = widget.selectedDates.length;
    final advanceAmount = widget.totalPrice * 0.2; // 20%
    final remainingAmount = widget.totalPrice - advanceAmount;

    final checkIn = widget.selectedDates.first;
    final checkOut = widget.selectedDates.last.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrda rezervacije'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Booking Summary Card
              _buildBookingSummaryCard(
                context,
                checkIn,
                checkOut,
                nights,
                advanceAmount,
                remainingAmount,
              ),

              const SizedBox(height: 24),

              // Guest Information Section
              Text(
                'Vaši podaci',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Ime i prezime
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ime i prezime *',
                  hintText: 'Marko Marković',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Molimo unesite ime i prezime';
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
                  hintText: 'marko@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Molimo unesite email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Molimo unesite validan email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon *',
                  hintText: '+385 91 234 5678',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Molimo unesite broj telefona';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Broj gostiju
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Broj gostiju',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _guestCount > 1
                        ? () {
                            setState(() {
                              _guestCount--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    '$_guestCount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _guestCount++;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Napomene (optional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Napomene (opcionalno)',
                  hintText: 'Posebni zahtjevi ili pitanja...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Potvrdi rezervaciju',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Info text
              Text(
                'Nakon potvrde, dobit ćete instrukcije za plaćanje avansa.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard(
    BuildContext context,
    DateTime checkIn,
    DateTime checkOut,
    int nights,
    double advanceAmount,
    double remainingAmount,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'hr');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.unitName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              icon: Icons.calendar_today,
              label: 'Dolazak',
              value: dateFormat.format(checkIn),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              icon: Icons.calendar_today,
              label: 'Odlazak',
              value: dateFormat.format(checkOut),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              icon: Icons.nights_stay,
              label: 'Broj noćenja',
              value: '$nights ${nights == 1 ? 'noć' : nights < 5 ? 'noći' : 'noći'}',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              context,
              icon: Icons.euro,
              label: 'Ukupna cijena',
              value: '${widget.totalPrice.toStringAsFixed(0)}€',
              isHighlighted: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              icon: Icons.payment,
              label: 'Avans (20%)',
              value: '${advanceAmount.toStringAsFixed(0)}€',
              valueColor: Colors.orange,
            ),
            const SizedBox(height: 4),
            _buildSummaryRow(
              context,
              icon: Icons.money_off,
              label: 'Ostatak (po dolasku)',
              value: '${remainingAmount.toStringAsFixed(0)}€',
              valueColor: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : null,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: valueColor ??
                    (isHighlighted ? Theme.of(context).primaryColor : null),
              ),
        ),
      ],
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final checkIn = widget.selectedDates.first;
      final checkOut = widget.selectedDates.last.add(const Duration(days: 1));
      final advanceAmount = widget.totalPrice * 0.2;

      // Create booking object
      final booking = Booking(
        id: '', // Will be generated by Supabase
        unitId: widget.unitId,
        userId: null, // Guest booking (no userId)
        guestName: _nameController.text.trim(),
        guestEmail: _emailController.text.trim(),
        guestPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        checkIn: checkIn,
        checkOut: checkOut,
        status: 'pending', // Initial status
        totalPrice: widget.totalPrice,
        paidAmount: 0.0,
        guestCount: _guestCount,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentStatus: 'awaiting_advance',
        advanceAmount: advanceAmount,
        source: 'direct',
      );

      // Create booking via provider
      final createdBooking =
          await ref.read(bookingNotifierProvider.notifier).createBooking(booking);

      if (mounted) {
        // Navigate to payment info screen
        context.go(
          '/booking/payment/${createdBooking.id}',
          extra: {
            'booking': createdBooking,
            'unitName': widget.unitName,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri kreiranju rezervacije: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
