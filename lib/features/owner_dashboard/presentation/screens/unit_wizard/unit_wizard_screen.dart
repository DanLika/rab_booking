import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../shared/models/unit_model.dart';
import '../../../../../../shared/providers/repository_providers.dart';
import 'state/unit_wizard_provider.dart';
import 'widgets/wizard_progress_bar.dart';
import 'widgets/wizard_navigation_buttons.dart';
import 'steps/step_1_basic_info.dart';
import 'steps/step_2_capacity.dart';
import 'steps/step_3_pricing.dart';
import 'steps/step_4_availability.dart';
import 'steps/step_5_photos.dart';
import 'steps/step_6_widget.dart';
import 'steps/step_7_advanced.dart';
import 'steps/step_8_review.dart';

/// Unit Wizard Screen - Multi-step wizard for creating/editing units
///
/// Features:
/// - 8-step wizard flow (Basic Info → Review & Publish)
/// - Auto-save with draft persistence
/// - Skip optional steps (Photos, Advanced Options)
/// - Resume from draft
/// - Responsive design (mobile + desktop)
class UnitWizardScreen extends ConsumerStatefulWidget {
  final String? unitId; // null = new unit, non-null = edit existing

  const UnitWizardScreen({
    super.key,
    this.unitId,
  });

  @override
  ConsumerState<UnitWizardScreen> createState() => _UnitWizardScreenState();
}

class _UnitWizardScreenState extends ConsumerState<UnitWizardScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handle step navigation
  Future<void> _goToStep(int step) async {
    if (step < 1 || step > 8) return;

    await _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    await ref.read(unitWizardNotifierProvider(widget.unitId).notifier).jumpToStep(step);
  }

  /// Handle next button
  Future<void> _handleNext() async {
    final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
    final currentState = ref.read(unitWizardNotifierProvider(widget.unitId)).value;

    if (currentState == null) return;

    final currentStep = currentState.currentStep;

    // Validate current step before proceeding
    if (!_validateStep(currentStep, currentState)) {
      _showValidationError(currentStep);
      return;
    }

    // Mark step as completed
    await notifier.markStepCompleted(currentStep);

    // Move to next step
    if (currentStep < 8) {
      await notifier.goToNextStep();
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
  Future<void> _handleBack() async {
    final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
    await notifier.goToPreviousStep();

    unawaited(
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Handle skip button (optional steps only)
  Future<void> _handleSkip() async {
    final notifier = ref.read(unitWizardNotifierProvider(widget.unitId).notifier);
    final currentState = ref.read(unitWizardNotifierProvider(widget.unitId)).value;

    if (currentState == null) return;

    // Mark as skipped
    await notifier.markStepSkipped(currentState.currentStep);
    await notifier.goToNextStep();

    unawaited(
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Validate step data
  bool _validateStep(int step, dynamic state) {
    switch (step) {
      case 1: // Basic Info
        return state.name != null &&
               state.name!.isNotEmpty &&
               state.propertyId != null;
      case 2: // Capacity & Space
        return state.bedrooms != null &&
               state.bathrooms != null &&
               state.maxGuests != null;
      case 3: // Pricing
        return state.pricePerNight != null &&
               state.minStayNights != null;
      case 4: // Availability
        return true; // Always valid (defaults provided)
      case 5: // Photos (optional)
        return true; // Always valid
      case 6: // Widget Setup (recommended)
        return true; // Always valid
      case 7: // Advanced Options (optional)
        return true; // Always valid
      case 8: // Review & Publish
        return _validateAllRequiredSteps(state);
      default:
        return true;
    }
  }

  /// Validate all required steps are complete
  bool _validateAllRequiredSteps(dynamic state) {
    return state.name != null &&
           state.propertyId != null &&
           state.bedrooms != null &&
           state.bathrooms != null &&
           state.maxGuests != null &&
           state.pricePerNight != null &&
           state.minStayNights != null;
  }

  /// Show validation error
  void _showValidationError(int step) {
    String message;
    switch (step) {
      case 1:
        message = 'Please fill in unit name and select a property';
      case 2:
        message = 'Please fill in bedrooms, bathrooms, and max guests';
      case 3:
        message = 'Please set price per night and minimum stay';
      case 8:
        message = 'Please complete all required steps before publishing';
      default:
        message = 'Please complete this step';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Publish unit (final step)
  Future<void> _publishUnit() async {
    if (!mounted) return;

    try {
      // Get current draft
      final draft = ref.read(unitWizardNotifierProvider(widget.unitId)).value;
      if (draft == null) {
        throw Exception('Draft not found');
      }

      // Validate required fields
      if (draft.name == null ||
          draft.propertyId == null ||
          draft.pricePerNight == null ||
          draft.maxGuests == null) {
        throw Exception('Missing required fields');
      }

      // Generate slug from name if not set
      final slug = draft.slug ??
          draft.name!
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '');

      // Create or update UnitModel
      final unit = UnitModel(
        id: widget.unitId ?? '',
        propertyId: draft.propertyId!,
        name: draft.name!,
        slug: slug,
        description: draft.description,
        pricePerNight: draft.pricePerNight!,
        maxGuests: draft.maxGuests!,
        bedrooms: draft.bedrooms ?? 1,
        bathrooms: draft.bathrooms ?? 1,
        areaSqm: draft.areaSqm,
        images: draft.images,
        minStayNights: draft.minStayNights ?? 1,
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
              propertyId: draft.propertyId!,
              unitId: savedUnit.id,
            );
      }

      // Clear draft
      await ref.read(unitWizardNotifierProvider(widget.unitId).notifier).clearDraft();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.unitId == null
                ? 'Unit created successfully!'
                : 'Unit updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navigate back to units list
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish unit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Get next button label based on current step
  String _getNextLabel(int step) => switch (step) {
    8 => 'Publish',
    7 => 'Continue to Review',
    _ => 'Next',
  };

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitId == null ? 'Create New Unit' : 'Edit Unit'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B4CE6), // Purple 100%
                Color(0xB36B4CE6), // Purple 70%
              ],
            ),
          ),
        ),
        actions: [
          // Auto-save indicator
          wizardState.when(
            data: (draft) => draft.lastSaved != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getLastSavedText(draft.lastSaved!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: wizardState.when(
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
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  Step1BasicInfo(unitId: widget.unitId),
                  Step2Capacity(unitId: widget.unitId),
                  Step3Pricing(unitId: widget.unitId),
                  Step4Availability(unitId: widget.unitId),
                  Step5Photos(unitId: widget.unitId),
                  Step6Widget(unitId: widget.unitId),
                  Step7Advanced(unitId: widget.unitId),
                  Step8Review(unitId: widget.unitId),
                ],
              ),
            ),

            // Navigation Buttons
            WizardNavigationButtons(
              onBack: draft.currentStep > 1 ? _handleBack : null,
              onNext: _handleNext,
              onSkip: (draft.currentStep == 5 || draft.currentStep == 7)
                  ? _handleSkip
                  : null,
              nextLabel: _getNextLabel(draft.currentStep),
              showBack: draft.currentStep > 1,
              showSkip: draft.currentStep == 5 || draft.currentStep == 7,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
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
                'Failed to load wizard',
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
      ),
    );
  }

  /// Format last saved timestamp
  String _getLastSavedText(DateTime lastSaved) {
    final now = DateTime.now();
    final difference = now.difference(lastSaved);

    if (difference.inSeconds < 60) {
      return 'Saved just now';
    } else if (difference.inMinutes < 60) {
      return 'Saved ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Saved ${difference.inHours}h ago';
    } else {
      return 'Saved ${difference.inDays}d ago';
    }
  }
}
