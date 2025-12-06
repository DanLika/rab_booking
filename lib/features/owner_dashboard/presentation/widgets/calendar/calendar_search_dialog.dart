import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/owner_calendar_provider.dart';

/// Calendar search dialog
/// Allows searching bookings by guest name, booking ID, unit name, or dates
class CalendarSearchDialog extends ConsumerStatefulWidget {
  const CalendarSearchDialog({super.key});

  @override
  ConsumerState<CalendarSearchDialog> createState() => _CalendarSearchDialogState();
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: screenWidth * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: BoxConstraints(maxWidth: 800, maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.calendarSearchTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
              padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
              child: Builder(
                builder: (ctx) => TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration:
                      InputDecorationHelper.buildDecoration(
                        labelText: l10n.calendarSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        context: ctx,
                      ).copyWith(
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                      ),
                  onChanged: _performSearch,
                ),
              ),
            ),

            // Search info
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth < 400 ? 12 : 16),
                child: Row(
                  children: [
                    Text(
                      l10n.calendarSearchResultsCount(_searchResults.length),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

            Divider(color: context.gradients.sectionBorder.withAlpha((0.3 * 255).toInt())),

            // Results list
            Expanded(child: _buildResultsList()),
          ],
        ),
      ),
    );
  }

  /// Build search results list
  Widget _buildResultsList() {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              l10n.calendarSearchEnterTerm,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.calendarSearchDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).disabledColor),
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
            Icon(Icons.search_off, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              l10n.calendarSearchNoResults,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.calendarSearchTryAnother,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).disabledColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
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
                    decoration: BoxDecoration(color: booking.status.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.guestName ?? 'N/A',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    booking.status.displayName,
                    style: TextStyle(fontSize: 12, color: booking.status.color, fontWeight: FontWeight.w600),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
                      color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$nights noć${nights > 1 ? 'i' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.tertiary,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    }
  }
}
