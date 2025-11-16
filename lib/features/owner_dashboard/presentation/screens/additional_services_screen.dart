import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../../../../shared/repositories/firebase/firebase_additional_services_repository.dart';

/// Additional Services Management Screen
/// Owner can create, edit, delete and reorder additional services
class AdditionalServicesScreen extends ConsumerStatefulWidget {
  const AdditionalServicesScreen({super.key});

  @override
  ConsumerState<AdditionalServicesScreen> createState() =>
      _AdditionalServicesScreenState();
}

class _AdditionalServicesScreenState
    extends ConsumerState<AdditionalServicesScreen> {
  Future<void> _showAddServiceDialog() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) =>
          _AddEditServiceDialog(ownerId: userId, onSave: _reloadServices),
    );
  }

  Future<void> _showEditServiceDialog(AdditionalServiceModel service) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AddEditServiceDialog(
        service: service,
        ownerId: service.ownerId,
        onSave: _reloadServices,
      ),
    );
  }

  Future<void> _deleteService(AdditionalServiceModel service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting service...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await ref.read(additionalServicesRepositoryProvider).delete(service.id);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to delete service',
        );
      }
    }
  }

  Future<void> _toggleServiceAvailability(
    AdditionalServiceModel service,
    bool isAvailable,
  ) async {
    try {
      await ref
          .read(additionalServicesRepositoryProvider)
          .update(
            service.copyWith(
              isAvailable: isAvailable,
              updatedAt: DateTime.now(),
            ),
          );
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to update service',
        );
      }
    }
  }

  void _reloadServices() {
    // Services are automatically reloaded via StreamProvider
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Additional Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Info',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServiceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<AdditionalServiceModel>>(
        stream: ref
            .read(additionalServicesRepositoryProvider)
            .watchByOwner(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading services',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return _buildEmptyState(theme, isDark);
          }

          return RefreshIndicator(
            onRefresh: () async => _reloadServices(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceCard(context, theme, isDark, service);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha((0.15 * 255).toInt()),
                  AppColors.secondary.withAlpha((0.08 * 255).toInt()),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Services Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first additional service to offer\nyour guests extra amenities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AdditionalServiceModel service,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: service.isAvailable
                          ? [
                              AppColors.primary.withAlpha((0.15 * 255).toInt()),
                              AppColors.secondary.withAlpha(
                                (0.08 * 255).toInt(),
                              ),
                            ]
                          : [
                              AppColors.textSecondary.withAlpha(
                                (0.1 * 255).toInt(),
                              ),
                              AppColors.textSecondary.withAlpha(
                                (0.05 * 255).toInt(),
                              ),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconData(service.iconName ?? service.defaultIconName),
                    color: service.isAvailable
                        ? AppColors.primary
                        : AppColors.textDisabled,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (service.description != null &&
                          service.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Available toggle
                Switch(
                  value: service.isAvailable,
                  onChanged: (value) =>
                      _toggleServiceAvailability(service, value),
                  activeThumbColor: AppColors.primary,
                ),
                // More menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditServiceDialog(service);
                        break;
                      case 'delete':
                        _deleteService(service);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppColors.error),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Price & Details
            Row(
              children: [
                _buildDetailChip(
                  icon: Icons.euro,
                  label: service.formattedPrice,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Icons.label_outline,
                  label: service.serviceTypeDisplayName,
                  theme: theme,
                ),
                if (service.maxQuantity != null) ...[
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Max: ${service.maxQuantity}',
                    theme: theme,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Convert icon name string to IconData
    switch (iconName) {
      case 'local_parking':
        return Icons.local_parking;
      case 'restaurant':
        return Icons.restaurant;
      case 'access_time':
        return Icons.access_time;
      case 'exit_to_app':
        return Icons.exit_to_app;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'child_care':
        return Icons.child_care;
      case 'pets':
        return Icons.pets;
      case 'local_taxi':
        return Icons.local_taxi;
      default:
        return Icons.add_circle;
    }
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Additional Services'),
        content: const Text(
          'Additional services allow you to offer extra amenities to your guests, such as:\n\n'
          '• Airport transfers\n'
          '• Early check-in / Late checkout\n'
          '• Parking\n'
          '• Breakfast\n'
          '• Pet fees\n'
          '• And more...\n\n'
          'You can customize pricing based on per booking, per night, or per person.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Add/Edit Service Dialog
class _AddEditServiceDialog extends ConsumerStatefulWidget {
  final AdditionalServiceModel? service;
  final String ownerId;
  final VoidCallback onSave;

  const _AddEditServiceDialog({
    this.service,
    required this.ownerId,
    required this.onSave,
  });

  @override
  ConsumerState<_AddEditServiceDialog> createState() =>
      _AddEditServiceDialogState();
}

class _AddEditServiceDialogState extends ConsumerState<_AddEditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _descriptionEnController;
  late final TextEditingController _priceController;
  late final TextEditingController _maxQuantityController;

  String _selectedServiceType = 'other';
  String _selectedPricingUnit = 'per_booking';
  String? _selectedIcon;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final service = widget.service;

    _nameController = TextEditingController(text: service?.name ?? '');
    _nameEnController = TextEditingController(text: service?.nameEn ?? '');
    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    _descriptionEnController = TextEditingController(
      text: service?.descriptionEn ?? '',
    );
    _priceController = TextEditingController(
      text: service != null ? service.price.toStringAsFixed(2) : '',
    );
    _maxQuantityController = TextEditingController(
      text: service?.maxQuantity?.toString() ?? '',
    );

    _selectedServiceType = service?.serviceType ?? 'other';
    _selectedPricingUnit = service?.pricingUnit ?? 'per_booking';
    _selectedIcon = service?.iconName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _descriptionEnController.dispose();
    _priceController.dispose();
    _maxQuantityController.dispose();
    super.dispose();
  }

  /// Get available pricing units based on service type
  /// This ensures logical consistency between service type and pricing model
  List<DropdownMenuItem<String>> _getAvailablePricingUnits() {
    switch (_selectedServiceType) {
      case 'parking':
        // Parking is typically per booking or per night
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
          DropdownMenuItem(value: 'per_night', child: Text('Per Night')),
        ];
      case 'breakfast':
        // Breakfast is typically per person per night or per person
        return const [
          DropdownMenuItem(value: 'per_person', child: Text('Per Person')),
          DropdownMenuItem(
            value: 'per_night',
            child: Text('Per Night (total)'),
          ),
        ];
      case 'late_checkin':
      case 'early_checkout':
        // Check-in/out modifications are one-time fees
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
        ];
      case 'transfer':
        // Transfers are typically per booking
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
        ];
      case 'cleaning':
        // Cleaning can be per booking or per night (daily cleaning)
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
          DropdownMenuItem(value: 'per_night', child: Text('Per Night')),
        ];
      case 'baby_cot':
        // Baby cot is typically per item per night or per booking
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
          DropdownMenuItem(value: 'per_night', child: Text('Per Night')),
          DropdownMenuItem(value: 'per_item', child: Text('Per Item')),
        ];
      case 'pet_fee':
        // Pet fee can be per booking or per pet
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
          DropdownMenuItem(value: 'per_item', child: Text('Per Pet')),
        ];
      case 'other':
      default:
        // For other services, allow all options
        return const [
          DropdownMenuItem(value: 'per_booking', child: Text('Per Booking')),
          DropdownMenuItem(value: 'per_night', child: Text('Per Night')),
          DropdownMenuItem(value: 'per_person', child: Text('Per Person')),
          DropdownMenuItem(value: 'per_item', child: Text('Per Item')),
        ];
    }
  }

  /// Validate and adjust pricing unit when service type changes
  void _onServiceTypeChanged(String? newServiceType) {
    if (newServiceType == null) return;

    setState(() {
      _selectedServiceType = newServiceType;

      // Check if current pricing unit is valid for new service type
      final availableUnits = _getAvailablePricingUnits();
      final isCurrentUnitAvailable = availableUnits
          .any((item) => item.value == _selectedPricingUnit);

      // If current pricing unit is not available, reset to first available
      if (!isCurrentUnitAvailable) {
        _selectedPricingUnit = availableUnits.first.value!;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = AdditionalServiceModel(
        id: widget.service?.id ?? const Uuid().v4(),
        ownerId: widget.ownerId,
        name: _nameController.text.trim(),
        nameEn: _nameEnController.text.trim().isEmpty
            ? null
            : _nameEnController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim().isEmpty
            ? null
            : _descriptionEnController.text.trim(),
        serviceType: _selectedServiceType,
        price: double.parse(_priceController.text),
        pricingUnit: _selectedPricingUnit,
        isAvailable: widget.service?.isAvailable ?? true,
        maxQuantity: _maxQuantityController.text.isEmpty
            ? null
            : int.parse(_maxQuantityController.text),
        iconName: _selectedIcon,
        sortOrder: widget.service?.sortOrder ?? 0,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.service == null) {
        await ref.read(additionalServicesRepositoryProvider).create(service);
      } else {
        await ref.read(additionalServicesRepositoryProvider).update(service);
      }

      if (mounted) {
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service == null
                  ? 'Service created successfully'
                  : 'Service updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to save service',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.service == null ? 'Add Service' : 'Edit Service',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Name (Croatian)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (Croatian) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter service name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Name (English)
                TextFormField(
                  controller: _nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'Name (English)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),
                // Description (Croatian)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Croatian)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Description (English)
                TextFormField(
                  controller: _descriptionEnController,
                  decoration: const InputDecoration(
                    labelText: 'Description (English)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Service Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedServiceType,
                  decoration: const InputDecoration(
                    labelText: 'Service Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'parking', child: Text('Parking')),
                    DropdownMenuItem(
                      value: 'breakfast',
                      child: Text('Breakfast'),
                    ),
                    DropdownMenuItem(
                      value: 'late_checkin',
                      child: Text('Late Check-in'),
                    ),
                    DropdownMenuItem(
                      value: 'early_checkout',
                      child: Text('Early Check-out'),
                    ),
                    DropdownMenuItem(
                      value: 'cleaning',
                      child: Text('Cleaning'),
                    ),
                    DropdownMenuItem(
                      value: 'baby_cot',
                      child: Text('Baby Cot'),
                    ),
                    DropdownMenuItem(value: 'pet_fee', child: Text('Pet Fee')),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Airport Transfer'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: _onServiceTypeChanged,
                ),
                const SizedBox(height: 16),
                // Icon Selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedIcon ?? 'add_circle',
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.palette),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'local_parking',
                      child: Row(
                        children: [
                          Icon(Icons.local_parking, size: 20),
                          SizedBox(width: 8),
                          Text('Parking'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'restaurant',
                      child: Row(
                        children: [
                          Icon(Icons.restaurant, size: 20),
                          SizedBox(width: 8),
                          Text('Restaurant'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'access_time',
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 20),
                          SizedBox(width: 8),
                          Text('Clock'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'exit_to_app',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, size: 20),
                          SizedBox(width: 8),
                          Text('Exit'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cleaning_services',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services, size: 20),
                          SizedBox(width: 8),
                          Text('Cleaning'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'child_care',
                      child: Row(
                        children: [
                          Icon(Icons.child_care, size: 20),
                          SizedBox(width: 8),
                          Text('Baby Cot'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'pets',
                      child: Row(
                        children: [
                          Icon(Icons.pets, size: 20),
                          SizedBox(width: 8),
                          Text('Pets'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'local_taxi',
                      child: Row(
                        children: [
                          Icon(Icons.local_taxi, size: 20),
                          SizedBox(width: 8),
                          Text('Taxi/Transfer'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'add_circle',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Default'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedIcon = value);
                  },
                ),
                const SizedBox(height: 16),
                // Price & Pricing Unit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (€) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter price';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPricingUnit,
                        decoration: const InputDecoration(
                          labelText: 'Pricing Unit *',
                          border: OutlineInputBorder(),
                        ),
                        items: _getAvailablePricingUnits(),
                        onChanged: (value) {
                          setState(() => _selectedPricingUnit = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Max Quantity
                TextFormField(
                  controller: _maxQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Max Quantity (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shopping_cart),
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    // Allow empty (optional field)
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final qty = int.tryParse(value);
                    // Validate > 0
                    if (qty == null || qty <= 0) {
                      return 'Max quantity must be greater than 0';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(widget.service == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
