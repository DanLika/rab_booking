import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/owner_bookings_provider.dart';

class BookingsTabBar extends ConsumerWidget {
  const BookingsTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(bookingsFiltersNotifierProvider);
    final l10n = AppLocalizations.of(context);

    // Map BookingStatus to L10n strings
    // We map null (All) separately
    final tabs = [
      (null, l10n.bookingsTabAll),
      (BookingStatus.pending, l10n.bookingsTabPending),
      (BookingStatus.confirmed, l10n.bookingsTabConfirmed),
      (BookingStatus.cancelled, l10n.bookingsTabCancelled),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final status = tabs[index].$1;
          final label = tabs[index].$2;
          final isSelected = filters.status == status;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _TabButton(
              label: label,
              isSelected: isSelected,
              status: status,
              onTap: () {
                 ref
                    .read(bookingsFiltersNotifierProvider.notifier)
                    .setStatus(status);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final BookingStatus? status; // for color
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine color based on status or default primary
    final activeColor = status?.color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != null) ...[
                 Container(
                   width: 8,
                   height: 8,
                   decoration: BoxDecoration(
                     color: isSelected ? activeColor : activeColor.withValues(alpha: 0.6),
                     shape: BoxShape.circle,
                   ),
                 ),
                 const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }
}
