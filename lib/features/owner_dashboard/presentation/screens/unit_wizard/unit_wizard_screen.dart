import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/utils/error_display_utils.dart';
import '../../../../../../shared/models/unit_model.dart';
import '../../../../../../shared/providers/repository_providers.dart';
import '../../providers/owner_properties_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import 'state/unit_wizard_provider.dart';
import 'widgets/wizard_progress_bar.dart';
import 'widgets/wizard_navigation_buttons.dart';
import 'steps/step_1_basic_info.dart';
import 'steps/step_2_capacity.dart';
import 'steps/step_3_pricing.dart';
import 'steps/step_4_review.dart';

/// Unit Wizard Screen - Multi-step wizard for creating/editing units
///
/// Features:
/// - 4-step wizard flow (Basic Info → Capacity → Pricing → Review & Publish)
/// - Responsive design (mobile + desktop)
/// - Pre-select property when creating from property context
/// - Duplicate existing unit with pre-filled data
class UnitWizardScreen extends ConsumerStatefulWidget {
  final String? unitId; // null = new unit, non-null = edit existing
  final String? propertyId; // Pre-select property when creating new unit
  final String? duplicateFromId; // ID of unit to duplicate (pre-fill data)

  const UnitWizardScreen({
    super.key,
    this.unitId,
    this.propertyId,
    this.duplicateFromId,
  });

  @override
  ConsumerState<UnitWizardScreen> createState() => _UnitWizardScreenState();
}

class _UnitWizardScreenState extends ConsumerState<UnitWizardScreen>
    with AndroidKeyboardDismissFixApproach1<UnitWizardScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWizard();
    });
  }

  /// Initialize wizard with appropriate data
  Future<void> _initializeWizard() async {
    final notifier = ref.read(
      unitWizardNotifierProvider(widget.unitId).notifier,
    );

    // Case 1: Duplicate existing unit
    if (widget.duplicateFromId != null && widget.unitId == null) {
      await _loadDuplicateData(notifier);
      return;
    }

    // Case 2: Create new unit with pre-selected property
    if (widget.propertyId != null && widget.unitId == null) {
      notifier.updateField('propertyId', widget.propertyId);
    }
  }

  /// Load data from existing unit for duplication
  Future<void> _loadDuplicateData(UnitWizardNotifier notifier) async {
    try {
      final unitRepository = ref.read(unitRepositoryProvider);
      final sourceUnit = await unitRepository.fetchUnitById(
        widget.duplicateFromId!,
      );

      if (sourceUnit != null) {
        // Pre-fill all fields from source unit (except id and name)
        notifier.updateField('propertyId', sourceUnit.propertyId);
        notifier.updateField('name', '${sourceUnit.name} (kopija)');
        notifier.updateField('description', sourceUnit.description);
        notifier.updateField('pricePerNight', sourceUnit.pricePerNight);
        notifier.updateField('weekendBasePrice', sourceUnit.weekendBasePrice);
        notifier.updateField('weekendDays', sourceUnit.weekendDays);
        notifier.updateField('maxGuests', sourceUnit.maxGuests);
        notifier.updateField('bedrooms', sourceUnit.bedrooms);
        notifier.updateField('bathrooms', sourceUnit.bathrooms);
        notifier.updateField('areaSqm', sourceUnit.areaSqm);
        notifier.updateField('minStayNights', sourceUnit.minStayNights);
        notifier.updateField('maxStayNights', sourceUnit.maxStayNights);
        // Note: Images are not copied - owner should upload new ones
      }
    } catch (e) {
      // If loading fails, continue with empty wizard
      debugPrint('Failed to load unit for duplication: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle step navigation
  Future<void> _goToStep(int step) async {
    if (step < 1 || step > 4) return;

    await _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    ref
        .read(unitWizardNotifierProvider(widget.unitId).notifier)
        .jumpToStep(step);
  }

  /// Handle next button
  Future<void> _handleNext() async {
    final notifier = ref.read(
      unitWizardNotifierProvider(widget.unitId).notifier,
    );
    final currentState = ref
        .read(unitWizardNotifierProvider(widget.unitId))
        .value;

    if (currentState == null) return;

    final currentStep = currentState.currentStep;

    // Validate current step before proceeding
    if (!_validateStep(currentStep, currentState)) {
      _showValidationError(currentStep);
      return;
    }

    // Mark step as completed
    notifier.markStepCompleted(currentStep);

    // Move to next step
    if (currentStep < 4) {
      notifier.goToNextStep();
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      // Final step - publish unit
      await _publishUnit();
    }
  }

  /// Handle back button
  void _handleBack() {
    final notifier = ref.read(
      unitWizardNotifierProvider(widget.unitId).notifier,
    );
    notifier.goToPreviousStep();

    unawaited(
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Validate step data
  bool _validateStep(int step, dynamic state) {
    switch (step) {
      case 1: // Basic Info - only validate name and slug (propertyId will be added in Phase 3)
        return state.name != null &&
            state.name!.isNotEmpty &&
            state.slug != null &&
            state.slug!.isNotEmpty;
      case 2: // Capacity & Space
        return state.bedrooms != null &&
            state.bathrooms != null &&
            state.maxGuests != null;
      case 3: // Pricing & Availability
        return state.pricePerNight != null && state.minStayNights != null;
      case 4: // Review & Publish
        return _validateAllRequiredSteps(state);
      default:
        return true;
    }
  }

  /// Validate all required steps are complete
  /// Note: propertyId validation temporarily disabled until Phase 3 (Property Selector)
  bool _validateAllRequiredSteps(dynamic state) {
    return state.name != null &&
        state.name!.isNotEmpty &&
        state.slug != null &&
        state.slug!.isNotEmpty &&
        state.bedrooms != null &&
        state.bathrooms != null &&
        state.maxGuests != null &&
        state.pricePerNight != null &&
        state.minStayNights != null;
  }

  /// Show validation error
  void _showValidationError(int step) {
    final l10n = AppLocalizations.of(context);
    String message;
    switch (step) {
      case 1:
        message = l10n.unitWizardValidationStep1;
      case 2:
        message = l10n.unitWizardValidationStep2;
      case 3:
        message = l10n.unitWizardValidationStep3;
      case 4:
        message = l10n.unitWizardValidationStep5; // Review step validation
      default:
        message = l10n.unitWizardValidationDefault;
    }

    ErrorDisplayUtils.showWarningSnackBar(context, message);
  }

  /// Publish unit (final step)
  Future<void> _publishUnit() async {
    if (!mounted) return;

    try {
      // Get current draft
      final draft = ref.read(unitWizardNotifierProvider(widget.unitId)).value;
      if (draft == null) {
        throw PropertyException(
          'Draft not found',
          code: 'property/draft-not-found',
        );
      }

      // Validate required fields
      // Note: propertyId validation temporarily disabled until Phase 3 (Property Selector)
      if (draft.name == null ||
          draft.pricePerNight == null ||
          draft.maxGuests == null) {
        throw PropertyException(
          'Missing required fields',
          code: 'property/missing-required-fields',
        );
      }

      // Get propertyId and ownerId - use draft's propertyId or fetch owner's first property
      String propertyId;
      String ownerId;
      final properties = await ref.read(ownerPropertiesProvider.future);
      if (properties.isEmpty) {
        throw PropertyException(
          'No properties found. Please create a property first.',
          code: 'property/no-properties',
        );
      }

      if (draft.propertyId != null && draft.propertyId!.isNotEmpty) {
        propertyId = draft.propertyId!;
      } else {
        // Use the first property
        propertyId = properties.first.id;
      }

      // ownerId is optional - security rules check parent property's owner_id
      // We still set it for backwards compatibility from parent property
      final property = properties.firstWhere(
        (p) => p.id == propertyId,
        orElse: () => properties.first,
      );
      ownerId = property.ownerId ?? '';

      // Generate slug from name if not set
      final slug =
          draft.slug ??
          draft.name!
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '');

      // Create or update UnitModel
      final unit = UnitModel(
        id: widget.unitId ?? '',
        propertyId: propertyId,
        ownerId: ownerId,
        name: draft.name!,
        slug: slug,
        description: draft.description,
        pricePerNight: draft.pricePerNight!,
        weekendBasePrice: draft.weekendBasePrice,
        weekendDays: draft.weekendDays,
        maxGuests: draft.maxGuests!,
        maxTotalCapacity: draft.maxTotalCapacity,
        extraBedFee: draft.extraBedFee,
        petFee: draft.petFee,
        maxPets: draft.maxPets,
        bedrooms: draft.bedrooms ?? 1,
        bathrooms: draft.bathrooms ?? 1,
        areaSqm: draft.areaSqm,
        images: draft.images,
        minStayNights: draft.minStayNights ?? 1,
        maxStayNights: draft.maxStayNights, // null = no limit
        createdAt: draft.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final unitRepository = ref.read(unitRepositoryProvider);
      final savedUnit = widget.unitId == null
          ? await unitRepository.createUnit(unit)
          : await unitRepository.updateUnit(unit);

      // Create default widget settings for new units
      if (widget.unitId == null && mounted) {
        await ref
            .read(widgetSettingsRepositoryProvider)
            .createDefaultSettings(
              propertyId: propertyId,
              unitId: savedUnit.id,
              ownerId: ownerId,
            );
      }

      // Invalidate units provider so Unit Hub refreshes its list
      ref.invalidate(ownerUnitsProvider);
      // Also invalidate calendar provider so timeline shows new unit immediately
      ref.invalidate(allOwnerUnitsProvider);

      // Show success message
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          widget.unitId == null
              ? l10n.unitWizardCreateSuccess
              : l10n.unitWizardUpdateSuccess,
        );
      }

      // Navigate back to units list
      if (mounted) {
        // Use canPop check - page may be accessed directly via URL
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/owner/units');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  /// Get next button label based on current step
  String _getNextLabel(int step, AppLocalizations l10n) => switch (step) {
    4 => l10n.unitWizardPublish,
    3 => l10n.unitWizardContinueToReview,
    _ => l10n.unitWizardNext,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle browser back button on Chrome Android
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/properties');
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('unit_wizard_screen_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            toolbarHeight:
                56.0, // Standard AppBar height (matches CommonAppBar)
            title: AutoSizeText(
              widget.unitId == null
                  ? l10n.unitWizardCreateTitle
                  : l10n.unitWizardEditTitle,
              maxLines: 1,
              minFontSize: 14,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: GradientTokens.brandPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Note: PageView handles keyboard spacing automatically when resizeToAvoidBottomInset is true
                return wizardState.when(
                  data: (draft) => Column(
                    children: [
                      // Progress Bar
                      WizardProgressBar(
                        currentStep: draft.currentStep,
                        completedSteps: draft.completedSteps,
                        onStepTap: _goToStep,
                      ),

                      // Step Content
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable swipe
                          children: [
                            Step1BasicInfo(unitId: widget.unitId),
                            Step2Capacity(unitId: widget.unitId),
                            Step3Pricing(unitId: widget.unitId),
                            Step4Review(unitId: widget.unitId),
                          ],
                        ),
                      ),

                      // Navigation Buttons
                      WizardNavigationButtons(
                        onBack: draft.currentStep > 1 ? _handleBack : null,
                        onNext: _handleNext,
                        nextLabel: _getNextLabel(draft.currentStep, l10n),
                        showBack: draft.currentStep > 1,
                      ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.unitWizardFailedToLoad,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
