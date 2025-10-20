import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/search_filters.dart';
import '../providers/saved_searches_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Dialog for saving a search with custom name
class SaveSearchDialog extends ConsumerStatefulWidget {
  const SaveSearchDialog({
    required this.filters,
    super.key,
  });

  final SearchFilters filters;

  @override
  ConsumerState<SaveSearchDialog> createState() => _SaveSearchDialogState();
}

class _SaveSearchDialogState extends ConsumerState<SaveSearchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _notificationEnabled = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Generate default name from filters
    _nameController.text = _generateDefaultName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _generateDefaultName() {
    final parts = <String>[];

    if (widget.filters.location != null && widget.filters.location!.isNotEmpty) {
      parts.add(widget.filters.location!);
    }

    if (widget.filters.guests > 0) {
      parts.add('${widget.filters.guests} ${widget.filters.guests == 1 ? 'gost' : 'gosta'}');
    }

    if (widget.filters.checkIn != null && widget.filters.checkOut != null) {
      final checkIn = widget.filters.checkIn!;
      final checkOut = widget.filters.checkOut!;
      parts.add('${checkIn.day}.${checkIn.month}. - ${checkOut.day}.${checkOut.month}.');
    }

    if (parts.isEmpty) {
      return 'Moja pretraga';
    }

    return parts.join(' • ');
  }

  Future<void> _saveSearch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(savedSearchesNotifierProvider.notifier).saveSearch(
            name: _nameController.text.trim(),
            filters: widget.filters,
            notificationEnabled: _notificationEnabled,
          );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.bookmark_add,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          const Expanded(
            child: Text('Sačuvaj pretragu'),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Description
            Text(
              'Sačuvajte ovu pretragu da biste je brzo pronašli kasnije.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Naziv pretrage',
                hintText: 'npr. Letovanje u Rabu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              maxLength: 50,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Unesite naziv pretrage';
                }
                if (value.trim().length < 3) {
                  return 'Naziv mora imati najmanje 3 karaktera';
                }
                return null;
              },
              autofocus: true,
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Notification toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SwitchListTile(
                value: _notificationEnabled,
                onChanged: (value) {
                  setState(() => _notificationEnabled = value);
                },
                title: const Text('Obavještenja'),
                subtitle: Text(
                  'Obavijestite me kada se pojave nove nekretnine',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                secondary: Icon(
                  _notificationEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: _notificationEnabled
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceXS,
                ),
              ),
            ),

            // Filter summary
            const SizedBox(height: AppDimensions.spaceL),
            _buildFilterSummary(),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppDimensions.spaceM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Otkaži'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveSearch,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Čuvam...' : 'Sačuvaj'),
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final filters = widget.filters;
    final activeFilters = <String>[];

    if (filters.location != null && filters.location!.isNotEmpty) {
      activeFilters.add('📍 ${filters.location}');
    }

    if (filters.checkIn != null && filters.checkOut != null) {
      activeFilters.add('📅 ${_formatDateRange(filters.checkIn!, filters.checkOut!)}');
    }

    if (filters.guests > 0) {
      activeFilters.add('👥 ${filters.guests} ${filters.guests == 1 ? 'gost' : 'gosta'}');
    }

    if (filters.minPrice != null || filters.maxPrice != null) {
      activeFilters.add('💰 ${_formatPriceRange(filters.minPrice, filters.maxPrice)}');
    }

    if (filters.propertyTypes.isNotEmpty) {
      activeFilters.add('🏠 ${filters.propertyTypes.length} ${filters.propertyTypes.length == 1 ? 'tip' : 'tipa'}');
    }

    if (filters.amenities.isNotEmpty) {
      activeFilters.add('✨ ${filters.amenities.length} ${filters.amenities.length == 1 ? 'sadržaj' : 'sadržaja'}');
    }

    if (filters.minBedrooms != null) {
      activeFilters.add('🛏️ ${filters.minBedrooms}+ sobe');
    }

    if (filters.minBathrooms != null) {
      activeFilters.add('🚿 ${filters.minBathrooms}+ kupatila');
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                'Aktivni filteri:',
                style: AppTypography.small.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Wrap(
            spacing: AppDimensions.spaceS,
            runSpacing: AppDimensions.spaceS,
            children: activeFilters.map((filter) {
              return Text(
                filter,
                style: AppTypography.small,
              );
            }).toList(),
          ),
        ],
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
    return 'Bilo koja cijena';
  }
}
