import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/price_list_provider.dart';
import '../providers/owner_calendar_provider.dart';

/// Dialog za kreiranje nove rezervacije
class BookingCreateDialog extends ConsumerStatefulWidget {
  final String? unitId;
  final DateTime? initialCheckIn;

  const BookingCreateDialog({
    super.key,
    this.unitId,
    this.initialCheckIn,
  });

  @override
  ConsumerState<BookingCreateDialog> createState() => _BookingCreateDialogState();
}

class _BookingCreateDialogState extends ConsumerState<BookingCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _guestNameController;
  late TextEditingController _guestEmailController;
  late TextEditingController _guestPhoneController;
  late TextEditingController _guestCountController;
  late TextEditingController _totalPriceController;
  late TextEditingController _notesController;

  String? _selectedUnitId;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  BookingStatus _status = BookingStatus.confirmed;
  String _paymentMethod = 'cash';

  bool _isCalculatingPrice = false;
  bool _isSaving = false;
  double? _calculatedPrice;

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController();
    _guestEmailController = TextEditingController();
    _guestPhoneController = TextEditingController();
    _guestCountController = TextEditingController(text: '1');
    _totalPriceController = TextEditingController();
    _notesController = TextEditingController();

    _selectedUnitId = widget.unitId;
    _checkInDate = widget.initialCheckIn ?? DateTime.now();
    _checkOutDate = _checkInDate.add(const Duration(days: 1));

    // Auto-calculate price if unit is pre-selected
    if (_selectedUnitId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatePrice();
      });
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _guestCountController.dispose();
    _totalPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(ownerUnitsProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_circle, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Nova rezervacija'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unit Selection
                Text(
                  'Jedinica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                unitsAsync.when(
                  data: (units) {
                    if (units.isEmpty) {
                      return const Text('Nema dostupnih jedinica');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedUnitId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bed_outlined),
                        hintText: 'Odaberite jedinicu',
                      ),
                      items: units.map((unit) {
                        return DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitId = value;
                        });
                        if (value != null) {
                          _calculatePrice();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Odaberite jedinicu';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Greška: $error'),
                ),

                const SizedBox(height: 24),

                // Dates
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

                const SizedBox(height: 12),

                // Nights display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nights_stay, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '${_checkOutDate.difference(_checkInDate).inDays} noć${_checkOutDate.difference(_checkInDate).inDays > 1 ? 'i' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Guest Information
                Text(
                  'Informacije o gostu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _guestNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ime gosta *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesite ime gosta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _guestEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesite email';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'Unesite validan email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _guestPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
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

                TextFormField(
                  controller: _guestCountController,
                  decoration: const InputDecoration(
                    labelText: 'Broj gostiju *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesite broj gostiju';
                    }
                    final count = int.tryParse(value.trim());
                    if (count == null || count <= 0) {
                      return 'Broj gostiju mora biti veći od 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _totalPriceController,
                        decoration: InputDecoration(
                          labelText: 'Ukupna cijena (€) *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.euro),
                          suffixIcon: _isCalculatingPrice
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Unesite cijenu';
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null || price < 0) {
                            return 'Unesite validnu cijenu';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedUnitId != null ? _calculatePrice : null,
                        icon: const Icon(Icons.calculate, size: 18),
                        label: const Text('Auto'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_calculatedPrice != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Kalkulirana cijena: €${_calculatedPrice!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BookingStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: [
                          BookingStatus.confirmed,
                          BookingStatus.pending,
                          BookingStatus.blocked,
                        ].map((status) {
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Plaćanje',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Gotovina')),
                          DropdownMenuItem(value: 'bank_transfer', child: Text('Bankovni transfer')),
                          DropdownMenuItem(value: 'card', child: Text('Kartica')),
                          DropdownMenuItem(value: 'other', child: Text('Ostalo')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _paymentMethod = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
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

                TextFormField(
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _createBooking,
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
              : const Text('Kreiraj'),
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

      // Recalculate price if unit is selected
      if (_selectedUnitId != null) {
        _calculatePrice();
      }
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

      // Recalculate price if unit is selected
      if (_selectedUnitId != null) {
        _calculatePrice();
      }
    }
  }

  Future<void> _calculatePrice() async {
    if (_selectedUnitId == null) return;

    setState(() {
      _isCalculatingPrice = true;
      _calculatedPrice = null;
    });

    try {
      double totalPrice = 0.0;
      DateTime currentDate = _checkInDate;

      // Fetch prices for each night
      while (currentDate.isBefore(_checkOutDate)) {
        final monthStart = DateTime(currentDate.year, currentDate.month, 1);

        // Fetch prices for the month
        final monthlyPrices = await ref.read(monthlyPricesProvider(MonthlyPricesParams(
          unitId: _selectedUnitId!,
          month: monthStart,
        )).future);

        final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final priceData = monthlyPrices[dateKey];

        // Get unit base price
        final unitsAsync = await ref.read(ownerUnitsProvider.future);
        final unit = unitsAsync.firstWhere((u) => u.id == _selectedUnitId);

        // Use daily price or base price
        final nightPrice = priceData?.price ?? unit.pricePerNight;
        totalPrice += nightPrice;

        currentDate = currentDate.add(const Duration(days: 1));
      }

      setState(() {
        _calculatedPrice = totalPrice;
        _totalPriceController.text = totalPrice.toStringAsFixed(2);
      });
    } catch (e) {
      if (mounted) {
        _showError('Greška pri kalkulaciji cijene: $e');
      }
    } finally {
      setState(() {
        _isCalculatingPrice = false;
      });
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUnitId == null) {
      _showError('Odaberite jedinicu');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final authState = ref.read(enhancedAuthProvider);

      // FIXED: Validate booking overlap before creating
      final bookingsMap = await ref.read(calendarBookingsProvider.future);
      final unitBookings = bookingsMap[_selectedUnitId!] ?? [];

      // Check for overlapping bookings
      bool hasOverlap = false;
      for (final existingBooking in unitBookings) {
        // Check if dates overlap
        if (_checkInDate.isBefore(existingBooking.checkOut) &&
            _checkOutDate.isAfter(existingBooking.checkIn)) {
          hasOverlap = true;
          break;
        }
      }

      if (hasOverlap) {
        setState(() => _isSaving = false);
        _showError('Izabrani datumi se preklapaju s postojećom rezervacijom');
        return;
      }

      final totalPrice = double.parse(_totalPriceController.text.trim());
      final guestCount = int.parse(_guestCountController.text.trim());

      // Create booking
      final booking = BookingModel(
        id: '', // Will be generated by Firestore
        unitId: _selectedUnitId!,
        ownerId: authState.firebaseUser?.uid,
        guestName: _guestNameController.text.trim(),
        guestEmail: _guestEmailController.text.trim(),
        guestPhone: _guestPhoneController.text.trim().isEmpty
            ? null
            : _guestPhoneController.text.trim(),
        checkIn: _checkInDate,
        checkOut: _checkOutDate,
        guestCount: guestCount,
        totalPrice: totalPrice,
        paidAmount: 0.0,
        paymentMethod: _paymentMethod,
        paymentStatus: 'pending',
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        source: 'admin',
        createdAt: DateTime.now(),
      );

      await repository.createBooking(booking);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Rezervacija uspješno kreirana',
        );
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri kreiranju rezervacije',
        );
      }
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
