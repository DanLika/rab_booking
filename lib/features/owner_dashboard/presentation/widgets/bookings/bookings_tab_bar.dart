import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/redesign.dart';
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
    final Color dot = isImportedTab
        ? Colors.grey.shade600
        : (status?.color ?? theme.colorScheme.primary);

    return BbChip(
      label: label,
      selected: isSelected,
      onTap: onTap,
      iconLeft: isImportedTab ? 'cloud_download' : null,
      dotColor: isImportedTab ? null : (status != null ? dot : null),
    );
  }
}
