import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/models/saved_search.dart';
import '../providers/saved_searches_provider.dart';
import '../providers/search_state_provider.dart';

/// Screen for viewing and managing saved searches
class SavedSearchesScreen extends ConsumerWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSearchesAsync = ref.watch(savedSearchesNotifierProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sačuvane pretrage'),
        actions: [
          // Clear all button
          savedSearchesAsync.when(
            data: (searches) {
              if (searches.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearAllDialog(context, ref),
                tooltip: 'Obriši sve',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: savedSearchesAsync.when(
        data: (searches) {
          if (searches.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: EdgeInsets.all(
              isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
            ),
            itemCount: searches.length,
            itemBuilder: (context, index) {
              return _SavedSearchCard(
                savedSearch: searches[index],
                onLoad: () => _loadSearch(context, ref, searches[index]),
                onEdit: () => _editSearch(context, ref, searches[index]),
                onDelete: () => _deleteSearch(context, ref, searches[index]),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Text(
                'Greška pri učitavanju sačuvanih pretraga',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                error.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(savedSearchesNotifierProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Nemate sačuvanih pretraga',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'Sačuvajte pretrage da biste ih brzo pronašli kasnije. Koristite dugme "Sačuvaj pretragu" na stranici rezultata pretrage.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            FilledButton.icon(
              onPressed: () {
                context.push('/search');
              },
              icon: const Icon(Icons.search),
              label: const Text('Započni pretragu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSearch(
    BuildContext context,
    WidgetRef ref,
    SavedSearch savedSearch,
  ) async {
    // Apply the saved filters to the search state
    final notifier = ref.read(searchFiltersNotifierProvider.notifier);
    final filters = savedSearch.filters;

    if (filters.location != null) {
      notifier.updateLocation(filters.location);
    }

    if (filters.checkIn != null && filters.checkOut != null) {
      notifier.updateDates(filters.checkIn, filters.checkOut);
    }

    // guests has a default value, always non-null
    notifier.updateGuests(filters.guests);

    if (filters.minPrice != null || filters.maxPrice != null) {
      notifier.updatePriceRange(filters.minPrice, filters.maxPrice);
    }

    if (filters.propertyType != null) {
      notifier.updatePropertyType(filters.propertyType);
    }

    if (filters.minRating != null) {
      notifier.updateMinRating(filters.minRating);
    }

    // sortBy has a default value, always non-null
    notifier.updateSortBy(filters.sortBy);

    // Navigate to search results
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Učitana pretraga "${savedSearch.name}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.push('/search');
    }
  }

  Future<void> _editSearch(
    BuildContext context,
    WidgetRef ref,
    SavedSearch savedSearch,
  ) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (context) => _EditSearchDialog(savedSearch: savedSearch),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(savedSearchesNotifierProvider.notifier).updateSearch(
              searchId: savedSearch.id,
              name: result.name,
              notificationEnabled: result.notificationEnabled,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pretraga je ažurirana'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSearch(
    BuildContext context,
    WidgetRef ref,
    SavedSearch savedSearch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši sačuvanu pretragu'),
        content: Text(
          'Da li ste sigurni da želite da obrišete pretragu "${savedSearch.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(savedSearchesNotifierProvider.notifier)
            .deleteSearch(savedSearch.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pretraga je obrisana'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši sve pretrage'),
        content: const Text(
          'Da li ste sigurni da želite da obrišete sve sačuvane pretrage? Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Obriši sve'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(savedSearchesNotifierProvider.notifier).clearAll();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sve pretrage su obrisane'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

/// Card widget for displaying a saved search
class _SavedSearchCard extends StatelessWidget {
  const _SavedSearchCard({
    required this.savedSearch,
    required this.onLoad,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedSearch savedSearch;
  final VoidCallback onLoad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final filters = savedSearch.filters;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      child: InkWell(
        onTap: onLoad,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.bookmark, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: Text(
                      savedSearch.name,
                      style: AppTypography.h3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Izmeni',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Obriši',
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceM),

              // Filters summary
              Wrap(
                spacing: AppDimensions.spaceS,
                runSpacing: AppDimensions.spaceS,
                children: [
                  if (filters.location != null && filters.location!.isNotEmpty)
                    _FilterChip(
                      icon: Icons.location_on,
                      label: filters.location!,
                    ),
                  if (filters.checkIn != null && filters.checkOut != null)
                    _FilterChip(
                      icon: Icons.calendar_today,
                      label: _formatDateRange(filters.checkIn!, filters.checkOut!),
                    ),
                  if (filters.guests > 0)
                    _FilterChip(
                      icon: Icons.people,
                      label: '${filters.guests} ${filters.guests == 1 ? 'gost' : 'gosta'}',
                    ),
                  if (filters.minPrice != null || filters.maxPrice != null)
                    _FilterChip(
                      icon: Icons.euro,
                      label: _formatPriceRange(filters.minPrice, filters.maxPrice),
                    ),
                  if (filters.propertyType != null && filters.propertyType!.isNotEmpty)
                    _FilterChip(
                      icon: Icons.home,
                      label: filters.propertyType!,
                    ),
                  if (filters.minRating != null && filters.minRating! > 0)
                    _FilterChip(
                      icon: Icons.star,
                      label: 'Ocena ${filters.minRating}+',
                    ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceM),

              // Footer
              Row(
                children: [
                  if (savedSearch.notificationEnabled) ...[
                    const Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppDimensions.spaceXS),
                    Text(
                      'Notifikacije uključene',
                      style: AppTypography.small.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                  ],
                  Expanded(
                    child: Text(
                      'Sačuvano ${_formatDate(savedSearch.createdAt)}',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime checkIn, DateTime checkOut) {
    return '${checkIn.day}.${checkIn.month}. - ${checkOut.day}.${checkOut.month}.';
  }

  String _formatPriceRange(double? minPrice, double? maxPrice) {
    if (minPrice != null && maxPrice != null) {
      return '€${minPrice.toInt()} - €${maxPrice.toInt()}';
    } else if (minPrice != null) {
      return 'Od €${minPrice.toInt()}';
    } else if (maxPrice != null) {
      return 'Do €${maxPrice.toInt()}';
    }
    return 'Bilo koja cena';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'danas';
    } else if (difference.inDays == 1) {
      return 'juče';
    } else if (difference.inDays < 7) {
      return 'pre ${difference.inDays} dana';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'pre $weeks ${weeks == 1 ? 'nedelje' : 'nedelja'}';
    } else {
      return '${date.day}.${date.month}.${date.year}.';
    }
  }
}

/// Chip for displaying filter info
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppDimensions.spaceXS),
          Text(
            label,
            style: AppTypography.small,
          ),
        ],
      ),
    );
  }
}

/// Dialog for editing a saved search
class _EditSearchDialog extends StatefulWidget {
  const _EditSearchDialog({
    required this.savedSearch,
  });

  final SavedSearch savedSearch;

  @override
  State<_EditSearchDialog> createState() => _EditSearchDialogState();
}

class _EditSearchDialogState extends State<_EditSearchDialog> {
  late TextEditingController _nameController;
  late bool _notificationEnabled;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.savedSearch.name);
    _notificationEnabled = widget.savedSearch.notificationEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Izmeni pretragu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Unesite naziv';
                }
                if (value.trim().length < 3) {
                  return 'Naziv mora imati najmanje 3 karaktera';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spaceM),
            SwitchListTile(
              value: _notificationEnabled,
              onChanged: (value) {
                setState(() => _notificationEnabled = value);
              },
              title: const Text('Notifikacije'),
              subtitle: const Text('Obavesti me o novim rezultatima'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                _EditResult(
                  name: _nameController.text.trim(),
                  notificationEnabled: _notificationEnabled,
                ),
              );
            }
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}

/// Result from edit dialog
class _EditResult {
  const _EditResult({
    required this.name,
    required this.notificationEnabled,
  });

  final String name;
  final bool notificationEnabled;
}
