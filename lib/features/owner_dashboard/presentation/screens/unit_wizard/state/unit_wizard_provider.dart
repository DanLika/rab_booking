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
        final unit = await ref
            .read(unitRepositoryProvider)
            .fetchUnitById(unitId);
        if (unit != null) {
          return UnitWizardDraft.fromUnit(unit);
        }
      } catch (_) {
        // Silently ignore - fall through to create new empty draft
      }
    }

    // Create new empty draft (in-memory only)
    return const UnitWizardDraft();
  }

  /// Update a single field (in-memory only)
  void updateField(String field, dynamic value) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(_updateDraftField(currentState, field, value));
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
    if (currentState == null || currentState.currentStep >= 4) return;

    final nextStep = currentState.currentStep + 1;
    state = AsyncValue.data(currentState.copyWith(currentStep: nextStep));
  }

  /// Go to previous step
  void goToPreviousStep() {
    final currentState = state.value;
    if (currentState == null || currentState.currentStep <= 1) return;

    final prevStep = currentState.currentStep - 1;
    state = AsyncValue.data(currentState.copyWith(currentStep: prevStep));
  }

  /// Jump to specific step
  void jumpToStep(int step) {
    if (step < 1 || step > 4) return;

    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(currentStep: step));
  }

  /// Mark step as completed
  void markStepCompleted(int step) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedCompletedSteps = Map<int, bool>.from(
      currentState.completedSteps,
    );
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
  ) => switch (field) {
    // Step 1 - Basic Info
    'name' => draft.copyWith(name: value),
    'propertyId' => draft.copyWith(propertyId: value),
    'slug' => draft.copyWith(slug: value),
    'description' => draft.copyWith(description: value),
    // Step 2 - Capacity
    'bedrooms' => draft.copyWith(bedrooms: value),
    'bathrooms' => draft.copyWith(bathrooms: value),
    'maxGuests' => draft.copyWith(maxGuests: value),
    'areaSqm' => draft.copyWith(areaSqm: value),
    // Step 2 - Extra beds & pets (expandable sections)
    'maxTotalCapacity' => draft.copyWith(maxTotalCapacity: value),
    'extraBedFee' => draft.copyWith(extraBedFee: value),
    'maxPets' => draft.copyWith(maxPets: value),
    'petFee' => draft.copyWith(petFee: value),
    // Step 3 - Pricing & Availability (merged)
    'pricePerNight' => draft.copyWith(pricePerNight: value),
    'weekendBasePrice' => draft.copyWith(weekendBasePrice: value),
    'weekendDays' => draft.copyWith(weekendDays: value),
    'minStayNights' => draft.copyWith(minStayNights: value),
    'maxStayNights' => draft.copyWith(maxStayNights: value),
    'seasons' => draft.copyWith(seasons: value),
    'availableYearRound' => draft.copyWith(availableYearRound: value),
    'seasonStartDate' => draft.copyWith(seasonStartDate: value),
    'seasonEndDate' => draft.copyWith(seasonEndDate: value),
    'blockedDates' => draft.copyWith(blockedDates: value),
    // Step 4 - Review & Publish (no fields to update here)
    // Legacy photo fields (kept for backwards compatibility)
    'images' => draft.copyWith(images: value),
    'coverImageUrl' => draft.copyWith(coverImageUrl: value),
    // Additional fields for future use
    'widgetMode' => draft.copyWith(widgetMode: value),
    'widgetTheme' => draft.copyWith(widgetTheme: value),
    'widgetSettings' => draft.copyWith(widgetSettings: value),
    'icalConfig' => draft.copyWith(icalConfig: value),
    'emailConfig' => draft.copyWith(emailConfig: value),
    'taxLegalConfig' => draft.copyWith(taxLegalConfig: value),
    _ => draft,
  };

  // Note: Riverpod will automatically dispose the provider when no longer used
}
