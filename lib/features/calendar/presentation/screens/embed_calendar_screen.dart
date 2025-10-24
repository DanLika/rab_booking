import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../properties/domain/models/unit.dart';
import '../../../properties/presentation/providers/units_provider.dart';
import '../widgets/grid_calendar_widget.dart';

/// Embed Calendar Screen - Standalone calendar for iframe embedding
/// Javni ekran bez authentifikacije za embedding na jasko-rab.com
class EmbedCalendarScreen extends ConsumerStatefulWidget {
  final String unitId;

  const EmbedCalendarScreen({
    super.key,
    required this.unitId,
  });

  @override
  ConsumerState<EmbedCalendarScreen> createState() =>
      _EmbedCalendarScreenState();
}

class _EmbedCalendarScreenState extends ConsumerState<EmbedCalendarScreen> {
  List<DateTime> _selectedDates = [];
  double _totalPrice = 0.0;

  @override
  Widget build(BuildContext context) {
    // Dohvatamo unit podatke
    final unitAsync = ref.watch(unitByIdProvider(widget.unitId));

    return Scaffold(
      // Minimal UI - nema AppBar za iframe embed
      body: SafeArea(
        child: unitAsync.when(
          data: (unit) {
            if (unit == null) {
              return _buildErrorState('Smještajna jedinica nije pronađena');
            }

            return Column(
              children: [
                // Minimal header sa nazivom jedinice
                _buildHeader(context, unit),

                // Kalendar
                Expanded(
                  child: GridCalendarWidget(
                    unitId: widget.unitId,
                    enableSelection: true,
                    onDatesSelected: (dates, price) {
                      setState(() {
                        _selectedDates = dates;
                        _totalPrice = price;
                      });
                    },
                  ),
                ),

                // Reserve button (prikazuje se samo kada su datumi selektirani)
                if (_selectedDates.isNotEmpty)
                  _buildReserveButton(context, unit),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Greška: $error'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Unit unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            unit.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (unit.description != null) ...[
            const SizedBox(height: 4),
            Text(
              unit.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Do ${unit.maxGuests} gostiju',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.euro, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Od ${unit.basePrice.toStringAsFixed(0)}€/noć',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReserveButton(BuildContext context, Unit unit) {
    final nights = _selectedDates.length;
    final advanceAmount = _totalPrice * 0.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nights ${nights == 1 ? 'noć' : nights < 5 ? 'noći' : 'noći'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Avans: ${advanceAmount.toStringAsFixed(0)}€',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              Text(
                '${_totalPrice.toStringAsFixed(0)}€',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reserve button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to booking form
                context.push(
                  '/embed/${widget.unitId}/booking',
                  extra: {
                    'unitId': widget.unitId,
                    'unitName': unit.name,
                    'selectedDates': _selectedDates,
                    'totalPrice': _totalPrice,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Rezerviraj sada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider za dohvatanje jedinice po ID-u (javno dostupno)
final unitByIdProvider =
    FutureProvider.family<Unit?, String>((ref, unitId) async {
  final repository = ref.watch(unitsRepositoryProvider);
  return repository.getUnitById(unitId);
});
