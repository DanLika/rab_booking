import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/owner_calendar_provider.dart';

/// Calendar search dialog
/// Allows searching bookings by guest name, booking ID, unit name, or dates
class CalendarSearchDialog extends ConsumerStatefulWidget {
  const CalendarSearchDialog({super.key});

  @override
  ConsumerState<CalendarSearchDialog> createState() =>
      _CalendarSearchDialogState();
}

class _CalendarSearchDialogState extends ConsumerState<CalendarSearchDialog> {
  final _searchController = TextEditingController();
  List<BookingModel> _searchResults = [];
  Map<String, UnitModel> _unitsMap = {};
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load units for displaying unit names in results
  Future<void> _loadUnits() async {
    final unitsAsync = ref.read(allOwnerUnitsProvider);
    unitsAsync.when(
      data: (units) {
        if (mounted) {
          setState(() {
            _unitsMap = {for (var unit in units) unit.id: unit};
          });
        }
      },
      loading: () {},
      error: (error, stackTrace) {
        // Silently fail - unit names will just show as IDs
        debugPrint('Failed to load units for search: $error');
      },
    );
  }

  /// Perform search across all bookings
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query.toLowerCase().trim();
    });

    try {
      final bookingsAsync = ref.read(calendarBookingsProvider);
      await bookingsAsync.when(
        data: (bookingsMap) async {
          final allBookings = bookingsMap.values.expand((list) => list).toList();

          // Filter bookings based on search query
          final results = allBookings.where((booking) {
            final guestName = booking.guestName?.toLowerCase() ?? '';
            final guestEmail = booking.guestEmail?.toLowerCase() ?? '';
            final bookingId = booking.id.toLowerCase();
            final unitName = _unitsMap[booking.unitId]?.name.toLowerCase() ?? '';

            return guestName.contains(_searchQuery) ||
                guestEmail.contains(_searchQuery) ||
                bookingId.contains(_searchQuery) ||
                unitName.contains(_searchQuery);
          }).toList();

          // Sort by check-in date (most recent first)
          results.sort((a, b) => b.checkIn.compareTo(a.checkIn));

          setState(() {
            _searchResults = results;
          });
        },
        loading: () {},
        error: (error, stack) {
          _showError('Greška pri pretrazi: $error');
        },
      );
    } catch (e) {
      _showError('Greška pri pretrazi: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.authPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Pretraga rezervacija',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Pretražite po imenu gosta, email-u, ID-u ili jedinici...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  _performSearch(value);
                },
              ),
            ),

            // Search info
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Pronađeno ${_searchResults.length} rezultata',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

            const Divider(),

            // Results list
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build search results list
  Widget _buildResultsList() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Unesite termin za pretragu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pretražite po imenu gosta, email-u, ID-u ili jedinici',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Nema rezultata',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pokušajte sa drugim terminom pretrage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final booking = _searchResults[index];
        final unit = _unitsMap[booking.unitId];
        return _buildResultCard(booking, unit);
      },
    );
  }

  /// Build result card
  Widget _buildResultCard(BookingModel booking, UnitModel? unit) {
    final dateFormat = DateFormat('d.M.yyyy', 'hr_HR');
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(booking),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: booking.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.guestName ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    booking.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: booking.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Unit name
              if (unit != null) ...[
                Row(
                  children: [
                    const Icon(Icons.bed_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      unit.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Dates
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(booking.checkIn)} - ${dateFormat.format(booking.checkOut)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.authPrimary.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$nights noć${nights > 1 ? 'i' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.authPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Email
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.guestEmail ?? 'N/A',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Price
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.euro, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.totalPrice.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
