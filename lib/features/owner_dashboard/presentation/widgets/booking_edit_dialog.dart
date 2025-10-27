import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Dialog za uređivanje rezervacije
class BookingEditDialog extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingEditDialog({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<BookingEditDialog> createState() => _BookingEditDialogState();
}

class _BookingEditDialogState extends ConsumerState<BookingEditDialog> {
  late TextEditingController _guestNameController;
  late TextEditingController _guestEmailController;
  late TextEditingController _guestPhoneController;
  late TextEditingController _guestCountController;
  late TextEditingController _totalPriceController;
  late TextEditingController _paidAmountController;
  late TextEditingController _notesController;
  late TextEditingController _cancellationReasonController;

  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late BookingStatus _status;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController(text: widget.booking.guestName);
    _guestEmailController = TextEditingController(text: widget.booking.guestEmail);
    _guestPhoneController = TextEditingController(text: widget.booking.guestPhone);
    _guestCountController = TextEditingController(text: widget.booking.guestCount.toString());
    _totalPriceController = TextEditingController(text: widget.booking.totalPrice.toStringAsFixed(2));
    _paidAmountController = TextEditingController(text: widget.booking.paidAmount.toStringAsFixed(2));
    _notesController = TextEditingController(text: widget.booking.notes);
    _cancellationReasonController = TextEditingController(text: widget.booking.cancellationReason);

    _checkInDate = widget.booking.checkIn;
    _checkOutDate = widget.booking.checkOut;
    _status = widget.booking.status;
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _guestCountController.dispose();
    _totalPriceController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _cancellationReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit),
          const SizedBox(width: 8),
          const Text('Uredi rezervaciju'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guest Information
              Text(
                'Informacije o gostu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _guestNameController,
                decoration: const InputDecoration(
                  labelText: 'Ime gosta *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _guestEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _guestPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Booking Dates
              Text(
                'Datumi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Check-in',
                      date: _checkInDate,
                      onTap: () => _selectCheckInDate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Check-out',
                      date: _checkOutDate,
                      onTap: () => _selectCheckOutDate(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Booking Details
              Text(
                'Detalji rezervacije',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _guestCountController,
                decoration: const InputDecoration(
                  labelText: 'Broj gostiju *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _totalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Ukupna cijena (€) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _paidAmountController,
                decoration: const InputDecoration(
                  labelText: 'Plaćeni iznos (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 24),

              // Status
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<BookingStatus>(
                value: _status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: BookingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Notes
              Text(
                'Napomene',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Interne napomene',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Npr. posebni zahtjevi...',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Cancellation reason (if cancelled)
              if (_status == BookingStatus.cancelled) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _cancellationReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Razlog otkazivanja',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cancel),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('d.M.yyyy').format(date),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _selectCheckInDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Izaberite datum check-in',
      cancelText: 'Otkaži',
      confirmText: 'Potvrdi',
    );

    if (selectedDate != null) {
      setState(() {
        _checkInDate = selectedDate;
        // Ensure check-out is after check-in
        if (_checkOutDate.isBefore(_checkInDate) || _checkOutDate.isAtSameMomentAs(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      helpText: 'Izaberite datum check-out',
      cancelText: 'Otkaži',
      confirmText: 'Potvrdi',
    );

    if (selectedDate != null) {
      setState(() {
        _checkOutDate = selectedDate;
      });
    }
  }

  Future<void> _saveBooking() async {
    // Validation
    final guestName = _guestNameController.text.trim();
    if (guestName.isEmpty) {
      _showError('Unesite ime gosta');
      return;
    }

    final guestEmail = _guestEmailController.text.trim();
    if (guestEmail.isNotEmpty && !_isValidEmail(guestEmail)) {
      _showError('Unesite validan email');
      return;
    }

    final guestCount = int.tryParse(_guestCountController.text.trim());
    if (guestCount == null || guestCount <= 0) {
      _showError('Broj gostiju mora biti veći od 0');
      return;
    }

    final totalPrice = double.tryParse(_totalPriceController.text.trim());
    if (totalPrice == null || totalPrice < 0) {
      _showError('Unesite validnu cijenu');
      return;
    }

    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    if (paidAmount < 0) {
      _showError('Plaćeni iznos ne može biti negativan');
      return;
    }

    if (_checkOutDate.isBefore(_checkInDate) || _checkOutDate.isAtSameMomentAs(_checkInDate)) {
      _showError('Check-out mora biti nakon check-in datuma');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(bookingRepositoryProvider);

      // Create updated booking
      final updatedBooking = widget.booking.copyWith(
        guestName: guestName,
        guestEmail: guestEmail.isEmpty ? null : guestEmail,
        guestPhone: _guestPhoneController.text.trim().isEmpty ? null : _guestPhoneController.text.trim(),
        checkIn: _checkInDate,
        checkOut: _checkOutDate,
        guestCount: guestCount,
        totalPrice: totalPrice,
        paidAmount: paidAmount,
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        cancellationReason: _status == BookingStatus.cancelled
            ? _cancellationReasonController.text.trim().isEmpty ? null : _cancellationReasonController.text.trim()
            : null,
        cancelledAt: _status == BookingStatus.cancelled && widget.booking.cancelledAt == null
            ? DateTime.now()
            : widget.booking.cancelledAt,
        updatedAt: DateTime.now(),
      );

      await repository.updateBooking(updatedBooking);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rezervacija uspješno ažurirana')),
        );
      }
    } catch (e) {
      _showError('Greška pri ažuriranju rezervacije: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
