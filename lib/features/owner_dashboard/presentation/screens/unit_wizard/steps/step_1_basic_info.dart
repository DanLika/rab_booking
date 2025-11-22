import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/utils/slug_utils.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';
import '../widgets/wizard_step_container.dart';

/// Step 1: Basic Info - Name, Property, Description, Slug
class Step1BasicInfo extends ConsumerStatefulWidget {
  final String? unitId;

  const Step1BasicInfo({super.key, this.unitId});

  @override
  ConsumerState<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends ConsumerState<Step1BasicInfo> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isManualSlugEdit = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    _nameController.text = draft.name ?? '';
    _slugController.text = draft.slug ?? '';
    _descriptionController.text = draft.description ?? '';
    _isManualSlugEdit = draft.slug != null && draft.slug!.isNotEmpty;
    _isInitialized = true;

    // Add listeners after loading data
    _nameController.addListener(_onNameChanged);
    _slugController.addListener(_onSlugChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onNameChanged() {
    final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
    notifier.updateField('name', _nameController.text);

    // Auto-generate slug if not manually edited
    if (!_isManualSlugEdit && _nameController.text.isNotEmpty) {
      final generatedSlug = generateSlug(_nameController.text);
      _slugController.text = generatedSlug;
      notifier.updateField('slug', generatedSlug);
    }
  }

  void _onSlugChanged() {
    final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
    notifier.updateField('slug', _slugController.text);

    if (_slugController.text.isNotEmpty) {
      setState(() => _isManualSlugEdit = true);
    }
  }

  void _onDescriptionChanged() {
    final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
    notifier.updateField('description', _descriptionController.text);
  }

  void _regenerateSlug() {
    setState(() => _isManualSlugEdit = false);
    if (_nameController.text.isNotEmpty) {
      final generatedSlug = generateSlug(_nameController.text);
      _slugController.text = generatedSlug;
      final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
      notifier.updateField('slug', generatedSlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        _loadData(draft);

        return WizardStepContainer(
          title: 'Osnovne Informacije',
          subtitle: 'Unesite naziv i opis smještajne jedinice',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecorationHelper.buildDecoration(
                  context,
                  labelText: 'Naziv Jedinice *',
                  hintText: 'npr. Apartman Prizemlje',
                  prefixIcon: const Icon(Icons.meeting_room),
                  isMobile: isMobile,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Naziv je obavezan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spaceM),

              // URL Slug
              TextFormField(
                controller: _slugController,
                decoration: InputDecorationHelper.buildDecoration(
                  context,
                  labelText: 'URL Slug',
                  hintText: 'apartman-prizemlje',
                  helperText: 'SEO-friendly URL: /booking/{slug}',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Regeneriši iz naziva',
                    onPressed: _regenerateSlug,
                  ),
                  isMobile: isMobile,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Slug je obavezan';
                  }
                  if (!isValidSlug(value)) {
                    return 'Slug može sadržavati samo mala slova, brojeve i crtice';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spaceM),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecorationHelper.buildDecoration(
                  context,
                  labelText: 'Opis',
                  hintText: 'Dodatne informacije o jedinici...',
                  prefixIcon: const Icon(Icons.description),
                  isMobile: isMobile,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // TODO: Property Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Property selector će biti dodat u Phase 3',
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
