import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../core/services/logging_service.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/utils/keyboard_dismiss_fix_mixin.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../../../../../../shared/models/additional_service_model.dart';
import '../../../../../../shared/repositories/firebase/firebase_additional_services_repository.dart';
import '../../../widgets/wizard/additional_service_dialog.dart';
import '../state/unit_wizard_provider.dart';

/// Step 2: Capacity & Space - Bedrooms, Bathrooms, Max Guests, Area,
/// plus expandable sections for Extra Beds and Pets
class Step2Capacity extends ConsumerStatefulWidget {
  final String? unitId;

  const Step2Capacity({super.key, this.unitId});

  @override
  ConsumerState<Step2Capacity> createState() => _Step2CapacityState();
}

class _Step2CapacityState extends ConsumerState<Step2Capacity>
    with AndroidKeyboardDismissFix {
  // Capacity controllers
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _areaSqmController = TextEditingController();

  // Extra beds controllers
  final _extraBedsController = TextEditingController();
  final _extraBedFeeController = TextEditingController();

  // Pets controllers
  final _maxPetsController = TextEditingController();
  final _petFeeController = TextEditingController();

  // Additional Services state
  List<AdditionalServiceModel> _services = [];
  bool _servicesLoaded = false;
  bool _servicesLoading = false;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _bedroomsController.addListener(_onBedroomsChanged);
    _bathroomsController.addListener(_onBathroomsChanged);
    _maxGuestsController.addListener(_onMaxGuestsChanged);
    _areaSqmController.addListener(_onAreaChanged);
    _extraBedsController.addListener(_onExtraBedsChanged);
    _extraBedFeeController.addListener(_onExtraBedFeeChanged);
    _maxPetsController.addListener(_onMaxPetsChanged);
    _petFeeController.addListener(_onPetFeeChanged);
    _loadServices();
  }

  Future<void> _loadServices() async {
    if (_servicesLoaded || _servicesLoading) return;
    setState(() => _servicesLoading = true);
    try {
      final ownerId = FirebaseAuth.instance.currentUser?.uid;
      final unitId = widget.unitId;
      if (ownerId != null && unitId != null) {
        final repo = ref.read(additionalServicesRepositoryProvider);
        final services = await repo.fetchByUnit(unitId, ownerId);
        if (mounted) {
          setState(() {
            _services = services;
            _servicesLoaded = true;
            _servicesLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _servicesLoaded = true;
            _servicesLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _servicesLoaded = true;
          _servicesLoading = false;
        });
      }
    }
  }

  Future<void> _addService() async {
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    final unitId = widget.unitId;
    if (ownerId == null || unitId == null) return;

    final result = await showDialog<AdditionalServiceModel>(
      context: context,
      builder: (ctx) =>
          AdditionalServiceDialog(ownerId: ownerId, unitId: unitId),
    );

    if (result != null && mounted) {
      try {
        final repo = ref.read(additionalServicesRepositoryProvider);
        final created = await repo.create(result);
        if (mounted) {
          setState(() {
            _services.add(created);
          });
        }
      } catch (e, stackTrace) {
        await LoggingService.logError(
          'Step2: Failed to create additional service',
          e,
          stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).error),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editService(AdditionalServiceModel service) async {
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    final unitId = widget.unitId;
    if (ownerId == null || unitId == null) return;

    final result = await showDialog<AdditionalServiceModel>(
      context: context,
      builder: (ctx) => AdditionalServiceDialog(
        service: service,
        ownerId: ownerId,
        unitId: unitId,
      ),
    );

    if (result != null && mounted) {
      try {
        final repo = ref.read(additionalServicesRepositoryProvider);
        await repo.update(result);
        if (mounted) {
          setState(() {
            final idx = _services.indexWhere((s) => s.id == result.id);
            if (idx >= 0) _services[idx] = result;
          });
        }
      } catch (e, stackTrace) {
        await LoggingService.logError(
          'Step2: Failed to update additional service',
          e,
          stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).error),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteService(AdditionalServiceModel service) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.additionalServiceDeleteConfirm),
        content: Text(l10n.additionalServiceDeleteHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(additionalServicesRepositoryProvider);
        await repo.delete(service.id);
        if (mounted) {
          setState(() {
            _services.removeWhere((s) => s.id == service.id);
          });
        }
      } catch (e, stackTrace) {
        await LoggingService.logError(
          'Step2: Failed to delete additional service',
          e,
          stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).error),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _bedroomsController.removeListener(_onBedroomsChanged);
    _bathroomsController.removeListener(_onBathroomsChanged);
    _maxGuestsController.removeListener(_onMaxGuestsChanged);
    _areaSqmController.removeListener(_onAreaChanged);
    _extraBedsController.removeListener(_onExtraBedsChanged);
    _extraBedFeeController.removeListener(_onExtraBedFeeChanged);
    _maxPetsController.removeListener(_onMaxPetsChanged);
    _petFeeController.removeListener(_onPetFeeChanged);
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _maxGuestsController.dispose();
    _areaSqmController.dispose();
    _extraBedsController.dispose();
    _extraBedFeeController.dispose();
    _maxPetsController.dispose();
    _petFeeController.dispose();
    super.dispose();
  }

  void _removeAllListeners() {
    _bedroomsController.removeListener(_onBedroomsChanged);
    _bathroomsController.removeListener(_onBathroomsChanged);
    _maxGuestsController.removeListener(_onMaxGuestsChanged);
    _areaSqmController.removeListener(_onAreaChanged);
    _extraBedsController.removeListener(_onExtraBedsChanged);
    _extraBedFeeController.removeListener(_onExtraBedFeeChanged);
    _maxPetsController.removeListener(_onMaxPetsChanged);
    _petFeeController.removeListener(_onPetFeeChanged);
  }

  void _addAllListeners() {
    _bedroomsController.addListener(_onBedroomsChanged);
    _bathroomsController.addListener(_onBathroomsChanged);
    _maxGuestsController.addListener(_onMaxGuestsChanged);
    _areaSqmController.addListener(_onAreaChanged);
    _extraBedsController.addListener(_onExtraBedsChanged);
    _extraBedFeeController.addListener(_onExtraBedFeeChanged);
    _maxPetsController.addListener(_onMaxPetsChanged);
    _petFeeController.addListener(_onPetFeeChanged);
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    _removeAllListeners();

    // Base capacity fields
    _bedroomsController.text = draft.bedrooms?.toString() ?? '';
    _bathroomsController.text = draft.bathrooms?.toString() ?? '';
    _maxGuestsController.text = draft.maxGuests?.toString() ?? '';
    _areaSqmController.text = draft.areaSqm?.toString() ?? '';

    // Extra beds: convert maxTotalCapacity to extra beds count
    if (draft.maxTotalCapacity != null && draft.maxGuests != null) {
      final extraBeds = draft.maxTotalCapacity - draft.maxGuests;
      if (extraBeds > 0) {
        _extraBedsController.text = extraBeds.toString();
      }
    }
    _extraBedFeeController.text = draft.extraBedFee?.toString() ?? '';

    // Pets
    _maxPetsController.text = draft.maxPets?.toString() ?? '';
    _petFeeController.text = draft.petFee?.toString() ?? '';

    _isInitialized = true;

    _addAllListeners();
  }

  void _onBedroomsChanged() {
    final value = int.tryParse(_bedroomsController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('bedrooms', value);
  }

  void _onBathroomsChanged() {
    final value = int.tryParse(_bathroomsController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('bathrooms', value);
  }

  void _onMaxGuestsChanged() {
    final value = int.tryParse(_maxGuestsController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('maxGuests', value);

    // Recalculate maxTotalCapacity if extra beds are set
    final extraBeds = int.tryParse(_extraBedsController.text);
    if (value != null && extraBeds != null && extraBeds > 0) {
      ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('maxTotalCapacity', value + extraBeds);
    }
  }

  void _onAreaChanged() {
    final value = double.tryParse(_areaSqmController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('areaSqm', value);
  }

  void _onExtraBedsChanged() {
    final extraBeds = int.tryParse(_extraBedsController.text);
    final maxGuests = int.tryParse(_maxGuestsController.text) ?? 1;

    if (extraBeds != null && extraBeds > 0) {
      // Store as maxTotalCapacity = maxGuests + extraBeds
      ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('maxTotalCapacity', maxGuests + extraBeds);
    } else {
      // Clear maxTotalCapacity if extra beds is empty/zero
      ref
          .read(unitWizardNotifierProvider(widget.unitId).notifier)
          .updateField('maxTotalCapacity', null);
    }
  }

  void _onExtraBedFeeChanged() {
    final value = double.tryParse(_extraBedFeeController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('extraBedFee', value);
  }

  void _onMaxPetsChanged() {
    final value = int.tryParse(_maxPetsController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('maxPets', value);
  }

  void _onPetFeeChanged() {
    final value = double.tryParse(_petFeeController.text);
    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .updateField('petFee', value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        _loadData(draft);

        return KeyedSubtree(
          key: ValueKey('step2_capacity_$keyboardFixRebuildKey'),
          child: Container(
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        l10n.unitWizardStep2Title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        l10n.unitWizardStep2Subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Capacity Info Card
                      _buildCapacityCard(theme, l10n, isMobile),
                      const SizedBox(height: AppDimensions.spaceM),

                      // Extra Beds Expandable
                      _buildExpandableSection(
                        theme: theme,
                        icon: Icons.hotel,
                        title: l10n.unitWizardStep2ExtraBedsTitle,
                        subtitle: l10n.unitWizardStep2ExtraBedsDesc,
                        initiallyExpanded: _extraBedsController.text.isNotEmpty,
                        children: _buildFieldPair(
                          isMobile: isMobile,
                          first: TextFormField(
                            controller: _extraBedsController,
                            decoration: InputDecorationHelper.buildDecoration(
                              labelText: l10n.unitWizardStep2MaxExtraBeds,
                              hintText: l10n.unitWizardStep2MaxExtraBedsHint,
                              helperText:
                                  l10n.unitWizardStep2MaxExtraBedsHelper,
                              prefixIcon: const Icon(Icons.people_outline),
                              isMobile: isMobile,
                              context: context,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 1) {
                                return l10n.unitWizardStep2MaxExtraBedsInvalid;
                              }
                              return null;
                            },
                          ),
                          second: TextFormField(
                            controller: _extraBedFeeController,
                            decoration: InputDecorationHelper.buildDecoration(
                              labelText: l10n.unitWizardStep2ExtraBedFee,
                              hintText: l10n.unitWizardStep2ExtraBedFeeHint,
                              helperText: l10n.unitWizardStep2ExtraBedFeeHelper,
                              prefixIcon: const Icon(Icons.euro),
                              isMobile: isMobile,
                              context: context,
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
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final number = double.tryParse(value);
                              if (number == null || number <= 0) {
                                return l10n.unitWizardStep2ExtraBedFeeInvalid;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),

                      // Pets Expandable
                      _buildExpandableSection(
                        theme: theme,
                        icon: Icons.pets,
                        title: l10n.unitWizardStep2PetsTitle,
                        subtitle: l10n.unitWizardStep2PetsDesc,
                        initiallyExpanded:
                            _maxPetsController.text.isNotEmpty ||
                            _petFeeController.text.isNotEmpty,
                        children: _buildFieldPair(
                          isMobile: isMobile,
                          first: TextFormField(
                            controller: _maxPetsController,
                            decoration: InputDecorationHelper.buildDecoration(
                              labelText: l10n.unitWizardStep2MaxPets,
                              hintText: l10n.unitWizardStep2MaxPetsHint,
                              helperText: l10n.unitWizardStep2MaxPetsHelper,
                              prefixIcon: const Icon(Icons.pets),
                              isMobile: isMobile,
                              context: context,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 1) {
                                return l10n.unitWizardStep2MaxPetsInvalid;
                              }
                              return null;
                            },
                          ),
                          second: TextFormField(
                            controller: _petFeeController,
                            decoration: InputDecorationHelper.buildDecoration(
                              labelText: l10n.unitWizardStep2PetFee,
                              hintText: l10n.unitWizardStep2PetFeeHint,
                              helperText: l10n.unitWizardStep2PetFeeHelper,
                              prefixIcon: const Icon(Icons.euro),
                              isMobile: isMobile,
                              context: context,
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
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              final number = double.tryParse(value);
                              if (number == null || number <= 0) {
                                return l10n.unitWizardStep2PetFeeInvalid;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),

                      // Additional Services Expandable
                      _buildExpandableSection(
                        theme: theme,
                        icon: Icons.room_service,
                        title: l10n.additionalServicesTitle,
                        subtitle: l10n.additionalServicesSubtitle,
                        initiallyExpanded: _services.isNotEmpty,
                        children: [
                          if (_servicesLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_services.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Text(
                                    l10n.additionalServicesEmpty,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.additionalServicesEmptyHint,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._services.map(
                              (s) => _buildServiceTile(s, theme),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: widget.unitId != null
                                  ? _addService
                                  : null,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.additionalServiceAddTitle),
                            ),
                          ),
                          if (widget.unitId == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                l10n.additionalServiceSaveUnitFirst,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceL),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.tertiary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.unitWizardStep2InfoTip,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
    );
  }

  Widget _buildCapacityCard(
    ThemeData theme,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.home_work,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.unitWizardStep2UnitCapacity,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.unitWizardStep2UnitCapacityDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Bedrooms & Bathrooms
                ..._buildFieldPair(
                  isMobile: isMobile,
                  first: TextFormField(
                    controller: _bedroomsController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.unitWizardStep2Bedrooms,
                      hintText: '1',
                      prefixIcon: const Icon(Icons.bed),
                      isMobile: isMobile,
                      context: context,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.unitWizardStep2Required;
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 0) {
                        return l10n.unitWizardStep2InvalidNumber;
                      }
                      return null;
                    },
                  ),
                  second: TextFormField(
                    controller: _bathroomsController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.unitWizardStep2Bathrooms,
                      hintText: '1',
                      prefixIcon: const Icon(Icons.bathroom),
                      isMobile: isMobile,
                      context: context,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.unitWizardStep2Required;
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 0) {
                        return l10n.unitWizardStep2InvalidNumber;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Max Guests & Area
                ..._buildFieldPair(
                  isMobile: isMobile,
                  first: TextFormField(
                    controller: _maxGuestsController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.unitWizardStep2MaxGuests,
                      hintText: '2',
                      prefixIcon: const Icon(Icons.people),
                      isMobile: isMobile,
                      context: context,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.unitWizardStep2Required;
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 1) {
                        return l10n.unitWizardStep2MinGuest;
                      }
                      return null;
                    },
                  ),
                  second: TextFormField(
                    controller: _areaSqmController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: l10n.unitWizardStep2Area,
                      hintText: '50',
                      prefixIcon: const Icon(Icons.square_foot),
                      isMobile: isMobile,
                      context: context,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a list of widgets that layout two fields side-by-side on desktop
  /// or stacked vertically on mobile.
  List<Widget> _buildFieldPair({
    required bool isMobile,
    required Widget first,
    required Widget second,
  }) {
    if (isMobile) {
      return [first, const SizedBox(height: AppDimensions.spaceM), second];
    }
    return [
      Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(child: second),
        ],
      ),
    ];
  }

  /// Builds a styled expandable section matching the card design
  Widget _buildExpandableSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          child: Theme(
            // Remove default divider lines from ExpansionTile
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              title: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a tile for an individual additional service
  Widget _buildServiceTile(AdditionalServiceModel service, ThemeData theme) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.room_service,
          color: theme.colorScheme.secondary,
          size: 20,
        ),
      ),
      title: Text(service.name),
      subtitle: Text(
        '€${service.price.toStringAsFixed(2)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editService(service),
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
            onPressed: () => _deleteService(service),
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }
}
