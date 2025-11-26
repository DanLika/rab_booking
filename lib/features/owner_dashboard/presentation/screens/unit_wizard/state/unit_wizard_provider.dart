import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../shared/providers/repository_providers.dart';
import 'unit_wizard_state.dart';

part 'unit_wizard_provider.g.dart';

/// Unit Wizard Provider - manages wizard state in-memory
@riverpod
class UnitWizardNotifier extends _$UnitWizardNotifier {
  @override
  Future<UnitWizardDraft> build(String? unitId) async {
    // If editing existing unit, load it
    if (unitId != null) {
      try {
        final unit = await ref.read(unitRepositoryProvider).fetchUnitById(unitId);
        if (unit != null) {
          return UnitWizardDraft.fromUnit(unit);
        }
      } catch (e) {
        debugPrint('[UnitWizard] Failed to load unit: $e');
      }
    }

    // Create new empty draft (in-memory only)
    return const UnitWizardDraft();
  }

  /// Update a single field (in-memory only)
  void updateField(String field, dynamic value) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      _updateDraftField(currentState, field, value),
    );
  }

  /// Update multiple fields at once (in-memory only)
  void updateFields(Map<String, dynamic> fields) {
    final currentState = state.value;
    if (currentState == null) return;

    var updatedDraft = currentState;
    for (final entry in fields.entries) {
      updatedDraft = _updateDraftField(updatedDraft, entry.key, entry.value);
    }

    state = AsyncValue.data(updatedDraft);
  }

  /// Go to next step
  void goToNextStep() {
    final currentState = state.value;
    if (currentState == null || currentState.currentStep >= 5) return;

    final nextStep = currentState.currentStep + 1;
    state = AsyncValue.data(
      currentState.copyWith(currentStep: nextStep),
    );
  }

  /// Go to previous step
  void goToPreviousStep() {
    final currentState = state.value;
    if (currentState == null || currentState.currentStep <= 1) return;

    final prevStep = currentState.currentStep - 1;
    state = AsyncValue.data(
      currentState.copyWith(currentStep: prevStep),
    );
  }

  /// Jump to specific step
  void jumpToStep(int step) {
    if (step < 1 || step > 5) return;

    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(currentStep: step),
    );
  }

  /// Mark step as completed
  void markStepCompleted(int step) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedCompletedSteps = Map<int, bool>.from(currentState.completedSteps);
    updatedCompletedSteps[step] = true;

    state = AsyncValue.data(
      currentState.copyWith(completedSteps: updatedCompletedSteps),
    );
  }

  /// Mark step as skipped
  void markStepSkipped(int step) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedSkippedSteps = Map<int, bool>.from(currentState.skippedSteps);
    updatedSkippedSteps[step] = true;

    state = AsyncValue.data(
      currentState.copyWith(skippedSteps: updatedSkippedSteps),
    );
  }

  /// Helper to update draft field by name
  UnitWizardDraft _updateDraftField(
    UnitWizardDraft draft,
    String field,
    dynamic value,
  ) {
    switch (field) {
      // Step 1 - Basic Info
      case 'name':
        return draft.copyWith(name: value);
      case 'propertyId':
        return draft.copyWith(propertyId: value);
      case 'slug':
        return draft.copyWith(slug: value);
      case 'description':
        return draft.copyWith(description: value);
      // Step 2 - Capacity
      case 'bedrooms':
        return draft.copyWith(bedrooms: value);
      case 'bathrooms':
        return draft.copyWith(bathrooms: value);
      case 'maxGuests':
        return draft.copyWith(maxGuests: value);
      case 'areaSqm':
        return draft.copyWith(areaSqm: value);
      // Step 3 - Pricing & Availability (merged)
      case 'pricePerNight':
        return draft.copyWith(pricePerNight: value);
      case 'minStayNights':
        return draft.copyWith(minStayNights: value);
      case 'seasons':
        return draft.copyWith(seasons: value);
      case 'availableYearRound':
        return draft.copyWith(availableYearRound: value);
      case 'seasonStartDate':
        return draft.copyWith(seasonStartDate: value);
      case 'seasonEndDate':
        return draft.copyWith(seasonEndDate: value);
      case 'blockedDates':
        return draft.copyWith(blockedDates: value);
      // Step 4 - Photos (optional)
      case 'images':
        return draft.copyWith(images: value);
      case 'coverImageUrl':
        return draft.copyWith(coverImageUrl: value);
      // Step 5 - Review & Publish (no fields to update here)
      // Additional fields for future use
      case 'widgetMode':
        return draft.copyWith(widgetMode: value);
      case 'widgetTheme':
        return draft.copyWith(widgetTheme: value);
      case 'widgetSettings':
        return draft.copyWith(widgetSettings: value);
      case 'icalConfig':
        return draft.copyWith(icalConfig: value);
      case 'emailConfig':
        return draft.copyWith(emailConfig: value);
      case 'taxLegalConfig':
        return draft.copyWith(taxLegalConfig: value);
      default:
        return draft;
    }
  }

  // Note: Riverpod will automatically dispose the provider when no longer used
}
