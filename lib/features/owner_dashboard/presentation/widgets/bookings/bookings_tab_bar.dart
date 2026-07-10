import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/design/tokens.dart';
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
    // Handoff RZP tab order: Sve · Na čekanju · Potvrđene · Završene ·
    // Otkazane · Uvezene — each with a status-toned dot.
    final tabs = <(Object?, String)>[
      (null, l10n.bookingsTabAll),
      (BookingStatus.pending, l10n.bookingsTabPending),
      (BookingStatus.confirmed, l10n.bookingsTabConfirmed),
      (BookingStatus.completed, l10n.bookingsTabCompleted),
      (BookingStatus.cancelled, l10n.bookingsTabCancelled),
      ('imported', l10n.bookingsTabImported), // Special marker for imported
    ];

    // Handoff RZPTabs: a SINGLE horizontally-scrollable row of tabs (mobile
    // wraps them in `overflow-x: auto`), never a multi-line Wrap. The old Wrap
    // stacked the 6 chips into a vertical pile on the narrow mobile ledger
    // header (they share the row with the Filteri button) — the "ugly" look.
    // Horizontal scroll also handles large-text a11y (font_scale=2.0) + long HR
    // labels ("Otkazane") by scrolling, not clipping — supersedes F-63-04 Wrap.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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

          return Padding(
            padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
            child: _TabButton(
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
            ),
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
    // Handoff RZP tabs: every non-"Sve" tab carries a status-toned dot
    // (imported = info blue), theme-aware via colorOf / BBColor.
    final Color? dot = isImportedTab
        ? BBColor.of(context).statusImported
        : status?.colorOf(context);

    return BbChip(
      label: label,
      selected: isSelected,
      onTap: onTap,
      dotColor: dot,
    );
  }
}
