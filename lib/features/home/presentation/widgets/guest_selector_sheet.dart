import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/search_form_provider.dart';

/// Guest selector bottom sheet
class GuestSelectorSheet extends ConsumerWidget {
  const GuestSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(searchFormNotifierProvider);
    final formNotifier = ref.read(searchFormNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Gosti',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Max guests info
            Text(
              'Maksimalno 16 gostiju',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Adults selector
            _GuestRow(
              label: 'Odrasli',
              description: 'Osobe starije od 13 godina',
              count: formState.adults,
              onIncrement: formNotifier.incrementAdults,
              onDecrement: formNotifier.decrementAdults,
              minValue: 1,
              canIncrement: formState.totalGuests < 16,
            ),
            const Divider(height: 32),

            // Children selector
            _GuestRow(
              label: 'Djeca',
              description: 'Osobe od 2-12 godina',
              count: formState.children,
              onIncrement: formNotifier.incrementChildren,
              onDecrement: formNotifier.decrementChildren,
              minValue: 0,
              canIncrement: formState.totalGuests < 16,
            ),
            const Divider(height: 32),

            // Infants selector
            _GuestRow(
              label: 'Bebe',
              description: 'Osobe mlađe od 2 godine',
              count: formState.infants,
              onIncrement: formNotifier.incrementInfants,
              onDecrement: formNotifier.decrementInfants,
              minValue: 0,
              canIncrement: formState.totalGuests < 16,
            ),
            const SizedBox(height: 32),

            // Done button
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Gotovo (${formState.totalGuests} ${formState.totalGuests == 1 ? 'gost' : 'gosta'})',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show guest selector bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.scrim.withValues(alpha: 0.0),
      builder: (context) => const GuestSelectorSheet(),
    );
  }
}

/// Guest row widget with +/- controls
class _GuestRow extends StatelessWidget {
  const _GuestRow({
    required this.label,
    required this.description,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    required this.minValue,
    this.canIncrement = true,
  });

  final String label;
  final String description;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int minValue;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    final canDecrement = count > minValue;

    return Row(
      children: [
        // Label and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),

        // Controls
        Row(
          children: [
            // Decrement button
            IconButton(
              onPressed: canDecrement ? onDecrement : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: canDecrement
                  ? Theme.of(context).primaryColor
                  : context.colorScheme.outline.withValues(alpha: 0.3),
              iconSize: 32,
            ),

            // Count
            SizedBox(
              width: 40,
              child: Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // Increment button
            IconButton(
              onPressed: canIncrement ? onIncrement : null,
              icon: const Icon(Icons.add_circle_outline),
              color: canIncrement
                  ? Theme.of(context).primaryColor
                  : context.colorScheme.outline.withValues(alpha: 0.3),
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }
}
