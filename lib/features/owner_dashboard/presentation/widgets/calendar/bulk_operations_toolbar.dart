import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/multi_select_provider.dart';

/// Bulk Operations Toolbar
/// Shows at bottom of screen when multi-select mode is active
class BulkOperationsToolbar extends ConsumerWidget {
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onBulkDelete;
  final VoidCallback? onBulkChangeStatus;
  final VoidCallback? onBulkExport;
  final VoidCallback? onClose;

  const BulkOperationsToolbar({
    super.key,
    this.onSelectAll,
    this.onClearSelection,
    this.onBulkDelete,
    this.onBulkChangeStatus,
    this.onBulkExport,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiSelectState = ref.watch(multiSelectProvider);

    if (!multiSelectState.isEnabled) {
      return const SizedBox.shrink();
    }

    final selectionCount = multiSelectState.selectionCount;
    final hasSelection = multiSelectState.hasSelection;

    return Material(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.borderDark)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Close button
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Zatvori multi-select',
                onPressed: onClose,
                color: Colors.white,
              ),

              const SizedBox(width: 8),

              // Selection count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$selectionCount ${selectionCount == 1 ? 'odabrana' : 'odabrano'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Select All button
              TextButton.icon(
                icon: const Icon(Icons.select_all, size: 18),
                label: const Text('Odaberi sve'),
                onPressed: onSelectAll,
                style: TextButton.styleFrom(foregroundColor: AppColors.info),
              ),

              // Clear Selection button
              if (hasSelection)
                TextButton.icon(
                  icon: const Icon(Icons.deselect, size: 18),
                  label: const Text('Poništi'),
                  onPressed: onClearSelection,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),

              const Spacer(),

              // Bulk action buttons (only if has selection)
              if (hasSelection) ...[
                // Bulk Export
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Izvezi ($selectionCount)',
                  onPressed: onBulkExport,
                  color: AppColors.success,
                ),

                const SizedBox(width: 8),

                // Bulk Change Status
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Promijeni status'),
                  onPressed: onBulkChangeStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Bulk Delete
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Obriši'),
                  onPressed: onBulkDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
