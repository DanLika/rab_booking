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
import '../providers/owner_calendar_provider.dart';
import '../../utils/booking_overlap_detector.dart';

/// Quick Booking Creation Dialog
/// Simplified version with only essential fields for fast booking entry
class BookingQuickCreateDialog extends ConsumerStatefulWidget {
  final String? unitId;
  final DateTime? initialCheckIn;

  const BookingQuickCreateDialog({super.key, this.unitId, this.initialCheckIn});

  @override
  ConsumerState<BookingQuickCreateDialog> createState() =>
      _BookingQuickCreateDialogState();
}

class _BookingQuickCreateDialogState
    extends ConsumerState<BookingQuickCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _guestNameController;
  late TextEditingController _guestCountController;
  late TextEditingController _totalPriceController;

  String? _selectedUnitId;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;

  bool _isCalculatingPrice = false;
  bool _isSaving = false;
  double? _calculatedPrice;

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController();
    _guestCountController = TextEditingController(text: '2');
    _totalPriceController = TextEditingController();

    _selectedUnitId = widget.unitId;
    _checkInDate = widget.initialCheckIn ?? DateTime.now();
    _checkOutDate = _checkInDate.add(
      const Duration(days: 3),
    ); // Default 3 nights

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
    _guestCountController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final nights = _checkOutDate.difference(_checkInDate).inDays;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brza rezervacija',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Samo najvažniji podaci',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Unit Selection
                unitsAsync.when(
                  data: (units) {
                    if (units.isEmpty) {
                      return const Text('Nema dostupnih jedinica');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedUnitId,
                      decoration: const InputDecoration(
                        labelText: 'Jedinica *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bed_outlined),
                        hintText: 'Odaberi',
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
                          return 'Odaberi jedinicu';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Text(
                    'Greška: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

                const SizedBox(height: 16),

                // Dates Row
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickDateField(
                        label: 'Check-in *',
                        date: _checkInDate,
                        icon: Icons.login,
                        onTap: _selectCheckInDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickDateField(
                        label: 'Check-out *',
                        date: _checkOutDate,
                        icon: Icons.logout,
                        onTap: _selectCheckOutDate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Nights Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.nights_stay,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$nights noć${nights != 1 ? 'i' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Guest Name
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
                      return 'Unesi ime';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Guest Count and Price Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guestCountController,
                        decoration: const InputDecoration(
                          labelText: 'Gosti *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Unesi broj';
                          }
                          final count = int.tryParse(value.trim());
                          if (count == null || count <= 0) {
                            return 'Min 1';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _totalPriceController,
                        decoration: InputDecoration(
                          labelText: 'Cijena (€) *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.euro),
                          suffixIcon: _isCalculatingPrice
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (_calculatedPrice != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 20,
                                        ),
                                        onPressed: _calculatePrice,
                                        tooltip: 'Ponovo izračunaj',
                                      )
                                    : null),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Unesi cijenu';
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null || price <= 0) {
                            return 'Nevažeća cijena';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Odustani'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveBooking,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving ? 'Spremam...' : 'Spremi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build quick date field (compact version)
  Widget _buildQuickDateField({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        child: Text(
          DateFormat('d.M.yy').format(date),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  /// Calculate price automatically - simplified version
  Future<void> _calculatePrice() async {
    if (_selectedUnitId == null) return;

    setState(() {
      _isCalculatingPrice = true;
    });

    try {
      // For quick booking, just estimate based on nights
      // User can override manually
      final nights = _checkOutDate.difference(_checkInDate).inDays;
      final estimatedPrice = nights * 100.0; // Simple €100/night estimate

      setState(() {
        _calculatedPrice = estimatedPrice;
        if (_totalPriceController.text.isEmpty) {
          _totalPriceController.text = estimatedPrice.toStringAsFixed(0);
        }
      });
    } catch (e) {
      // Silent fail - user can enter price manually
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingPrice = false;
        });
      }
    }
  }

  /// Select check-in date
  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null && mounted) {
      setState(() {
        _checkInDate = picked;

        // Auto-adjust check-out if needed
        if (_checkOutDate.isBefore(_checkInDate) ||
            _checkOutDate.isAtSameMomentAs(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });

      _calculatePrice();
    }
  }

  /// Select check-out date
  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null && mounted) {
      setState(() {
        _checkOutDate = picked;
      });

      _calculatePrice();
    }
  }

  /// Save booking
  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final authState = ref.read(enhancedAuthProvider);

      if (authState.firebaseUser == null) {
        throw Exception('Korisnik nije prijavljen');
      }

      // Check for overlaps
      final allBookingsMap = await ref.read(calendarBookingsProvider.future);

      final conflicts = BookingOverlapDetector.getConflictingBookings(
        unitId: _selectedUnitId!,
        newCheckIn: _checkInDate,
        newCheckOut: _checkOutDate,
        bookingIdToExclude: null,
        allBookings: allBookingsMap,
      );

      if (conflicts.isNotEmpty) {
        throw Exception('Preklapanje s postojećom rezervacijom za ove datume');
      }

      // Create booking
      final booking = BookingModel(
        id: '', // Firestore will generate
        unitId: _selectedUnitId!,
        ownerId: authState.firebaseUser?.uid,
        guestName: _guestNameController.text.trim(),
        guestEmail: 'quick@booking.com', // Auto-generated for quick mode
        guestCount: int.parse(_guestCountController.text.trim()),
        checkIn: _checkInDate,
        checkOut: _checkOutDate,
        status: BookingStatus.confirmed,
        source: 'admin',
        totalPrice: double.parse(_totalPriceController.text.trim()),
        paymentMethod: 'cash',
        paymentStatus: 'pending',
        notes: 'Brza rezervacija',
        createdAt: DateTime.now(),
      );

      await bookingRepo.createBooking(booking);

      if (mounted) {
        Navigator.pop(context, true);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Rezervacija uspješno kreirana!',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri kreiranju rezervacije',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
