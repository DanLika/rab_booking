import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/year_grid_calendar_widget.dart';
import '../providers/embed_booking_provider.dart';
import '../components/adaptive_glass_card.dart';

/// Embedded calendar screen - public view for guests
/// URL: /embed/units/:unitId
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
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;

  @override
  Widget build(BuildContext context) {
    // Watch booking state for future use
    ref.watch(embedBookingProvider(widget.unitId));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AdaptiveBlurredAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 24,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Book Your Stay'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Year Grid Calendar (31 days × 12 months)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: YearGridCalendarWidget(
                  unitId: widget.unitId,
                  onRangeSelected: (start, end) {
                    setState(() {
                      _selectedCheckIn = start;
                      _selectedCheckOut = end;
                    });
                  },
                ),
              ),
            ),

            // Selection Summary
            if (_selectedCheckIn != null && _selectedCheckOut != null)
              _buildSelectionSummary(),

            // Reserve Button
            if (_selectedCheckIn != null && _selectedCheckOut != null)
              _buildReserveButton(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary() {
    // Watch booking state for future use
    ref.watch(embedBookingProvider(widget.unitId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nights = _selectedCheckOut!.difference(_selectedCheckIn!).inDays;

    // Calculate total price from provider
    double totalPrice = 0.0;
    DateTime current = _selectedCheckIn!;
    while (current.isBefore(_selectedCheckOut!)) {
      final price = ref
          .read(embedBookingProvider(widget.unitId).notifier)
          .getPriceForDate(current);
      if (price != null) {
        totalPrice += price;
      }
      current = current.add(const Duration(days: 1));
    }

    return AdaptiveGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Selection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Check-in
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 16,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CHECK-IN',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_selectedCheckIn!.day}/${_selectedCheckIn!.month}/${_selectedCheckIn!.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              // Check-out
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'CHECK-OUT',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_selectedCheckOut!.day}/${_selectedCheckOut!.month}/${_selectedCheckOut!.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.nights_stay_rounded,
                    size: 20,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$nights ${nights == 1 ? 'night' : 'nights'}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.euro_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    totalPrice.toStringAsFixed(2),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReserveButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 500,
          ),
          child: SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to enhanced booking flow (guest info is in EnhancedPaymentScreen)
                // Full flow: EnhancedRoomSelectionScreen → EnhancedSummaryScreen → EnhancedPaymentScreen → EnhancedConfirmationScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to booking flow...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // NOTE: Implement navigation to /booking route with selected dates
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text(
                'Continue to Guest Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
