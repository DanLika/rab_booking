import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/utils/slug_utils.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../state/unit_wizard_provider.dart';

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
  void initState() {
    super.initState();
    // Add listeners in initState - they will be active for all user input
    _nameController.addListener(_onNameChanged);
    _slugController.addListener(_onSlugChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    _nameController.removeListener(_onNameChanged);
    _slugController.removeListener(_onSlugChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    // Remove listeners temporarily to avoid triggering provider updates during build
    _nameController.removeListener(_onNameChanged);
    _slugController.removeListener(_onSlugChanged);
    _descriptionController.removeListener(_onDescriptionChanged);

    // Set initial values
    _nameController.text = draft.name ?? '';
    _slugController.text = draft.slug ?? '';
    _descriptionController.text = draft.description ?? '';
    _isManualSlugEdit = draft.slug != null && draft.slug!.isNotEmpty;
    _isInitialized = true;

    // Re-attach listeners after setting initial values
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

        // Horizontal gradient (left → right) - matches footer gradient for seamless transition
        return Container(
          decoration: BoxDecoration(
            gradient: context.gradients.pageBackground,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Osnovne Informacije',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Unesite naziv i opis smještajne jedinice',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Unit Name & URL Slug Card - matching Cjenovnik styling
                Container(
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
                        // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
                        // Section cards: topRight → bottomLeft (tamniji desno 30%, svjetliji lijevo 70%)
                        gradient: context.gradients.sectionBackground,
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
                            // Header with icon - Minimalist
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      (0.12 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.meeting_room,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Informacije o Jedinici',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Naziv i URL slug jedinice za identifikaciju',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Responsive layout for Name and Slug fields
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Use same breakpoint as Cjenovnik (500px)
                                final isVerySmall = constraints.maxWidth < 500;

                                if (isVerySmall) {
                                  // Column layout for small screens
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Unit Name
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: 'Naziv Jedinice *',
                                          hintText: 'npr. Apartman Prizemlje',
                                          prefixIcon: const Icon(Icons.meeting_room),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Naziv je obavezan';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // URL Slug
                                      TextFormField(
                                        controller: _slugController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: 'URL Slug',
                                          hintText: 'apartman-prizemlje',
                                          prefixIcon: const Icon(Icons.link),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.refresh),
                                            tooltip: 'Regeneriši iz naziva',
                                            onPressed: _regenerateSlug,
                                          ),
                                          isMobile: isMobile,
                                          context: context,
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
                                    ],
                                  );
                                }

                                // Row layout for larger screens - use Expanded for maximum space
                                return Row(
                                  children: [
                                    // Unit Name - flexible width
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: 'Naziv Jedinice *',
                                          hintText: 'npr. Apartman Prizemlje',
                                          prefixIcon: const Icon(Icons.meeting_room),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Naziv je obavezan';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // URL Slug - flexible width
                                    Expanded(
                                      child: TextFormField(
                                        controller: _slugController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: 'URL Slug',
                                          hintText: 'apartman-prizemlje',
                                          prefixIcon: const Icon(Icons.link),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.refresh),
                                            tooltip: 'Regeneriši iz naziva',
                                            onPressed: _regenerateSlug,
                                          ),
                                          isMobile: isMobile,
                                          context: context,
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
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),

                // Description Card
                Container(
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
                        // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
                        // Section cards: topRight → bottomLeft (tamniji desno 30%, svjetliji lijevo 70%)
                        gradient: context.gradients.sectionBackground,
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
                            // Header with icon - Minimalist
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(
                                      (0.12 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.description,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Opis Jedinice',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dodatne informacije koje će biti vidljive gostima',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Description TextField - optional, max 500 characters
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecorationHelper.buildDecoration(
                                labelText: 'Opis (opcionalno)',
                                hintText: 'Kratki opis jedinice...',
                                isMobile: isMobile,
                                context: context,
                              ).copyWith(
                                counterText: '${_descriptionController.text.length}/500',
                              ),
                              minLines: 2,
                              maxLines: 4,
                              maxLength: 500,
                              textInputAction: TextInputAction.newline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
              ],
            ),
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
