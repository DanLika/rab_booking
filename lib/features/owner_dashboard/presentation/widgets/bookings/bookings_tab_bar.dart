import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/owner_bookings_provider.dart';

/// Horizontal tab bar for filtering bookings by status
///
/// Displays tabs for: All, Pending, Confirmed, Cancelled, Imported
/// Each tab shows a color indicator matching its status.
class BookingsTabBar extends ConsumerWidget {
  const BookingsTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(bookingsFiltersNotifierProvider);
    final l10n = AppLocalizations.of(context);

    // Map BookingStatus to L10n strings
    // null status = "All", special 'imported' marker for imported tab
    final tabs = <(Object?, String)>[
      (null, l10n.bookingsTabAll),
      (BookingStatus.pending, l10n.bookingsTabPending),
      (BookingStatus.confirmed, l10n.bookingsTabConfirmed),
      (BookingStatus.cancelled, l10n.bookingsTabCancelled),
      ('imported', l10n.bookingsTabImported), // Special marker for imported
    ];

    // F-63-04: Wrap allows tabs to flow to a second line under large-text
    // accessibility (system font_scale=2.0) and long HR translations
    // ("Otkazane" → "O…" clip already visible at 1.0× per audit/63).
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(tabs.length, (index) {
          final tabValue = tabs[index].$1;
          final label = tabs[index].$2;

          final bool isSelected;
          final BookingStatus? status;
          final bool isImportedTab = tabValue == 'imported';

          if (isImportedTab) {
            isSelected = filters.showImportedOnly;
            status = null;
          } else {
            status = tabValue as BookingStatus?;
            isSelected = !filters.showImportedOnly && filters.status == status;
          }

          return _TabButton(
            label: label,
            isSelected: isSelected,
            status: status,
            isImportedTab: isImportedTab,
            onTap: () {
              if (isImportedTab) {
                ref
                    .read(bookingsFiltersNotifierProvider.notifier)
                    .setShowImportedOnly(true);
              } else {
                ref
                    .read(bookingsFiltersNotifierProvider.notifier)
                    .setStatus(status);
              }
            },
          );
        }),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final BookingStatus? status;
  final bool isImportedTab;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.status,
    this.isImportedTab = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine color based on status, imported tab, or default primary
    final Color activeColor;
    if (isImportedTab) {
      activeColor = Colors.grey.shade600;
    } else {
      activeColor = status?.color ?? theme.colorScheme.primary;
    }

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
          // alignment removed: Container.alignment makes the box expand to fill
          // parent constraints. Inside Wrap (post-F-63-04) that meant each tab
          // grew to the parent column's full width and stacked vertically even
          // on desktop. Row(mainAxisSize.min) below already sizes correctly.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isImportedTab) ...[
                Icon(
                  Icons.cloud_download_outlined,
                  size: 14,
                  color: isSelected
                      ? activeColor
                      : activeColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
              ] else if (status != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : activeColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? (theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
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
