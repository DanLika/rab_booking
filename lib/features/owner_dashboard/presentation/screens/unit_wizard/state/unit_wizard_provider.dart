import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../shared/models/unit_model.dart';
import '../../../../../../shared/providers/repository_providers.dart';
import '../../../../../../core/providers/enhanced_auth_provider.dart';
import 'unit_wizard_state.dart';

part 'unit_wizard_provider.g.dart';

/// Unit Wizard Provider - manages draft state with auto-save
@riverpod
class UnitWizardNotifier extends _$UnitWizardNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _autoSaveTimer;
  String? _draftId;

  Future<UnitWizardDraft> build(String? unitId) async {
    // Get current user
    final authState = ref.read(enhancedAuthProvider);
    final userId = authState.firebaseUser?.uid;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Generate draft ID
    _draftId = unitId ?? 'new_${DateTime.now().millisecondsSinceEpoch}';

    // If editing existing unit, load it
    if (unitId != null) {
      try {
        final unit = await ref.read(unitRepositoryProvider).fetchUnitById(unitId);

        // If unit not found, create empty draft
        if (unit == null) {
          return const UnitWizardDraft();
        }

        // Check if there's a draft for this unit
        final draftDoc = await _firestore
            .collection('unit_drafts')
            .doc('${userId}_$_draftId')
            .get();

        if (draftDoc.exists) {
          // Resume from draft
          return UnitWizardDraftFirestore.fromFirestore(draftDoc.data()!);
        } else {
          // Create draft from existing unit
          return UnitWizardDraft.fromUnit(unit);
        }
      } catch (e) {
        // If fetch fails, create empty draft
        return const UnitWizardDraft();
      }
    }

    // New unit - check if there's an existing draft
    final draftDoc = await _firestore
        .collection('unit_drafts')
        .doc('${userId}_$_draftId')
        .get();

    if (draftDoc.exists) {
      return UnitWizardDraftFirestore.fromFirestore(draftDoc.data()!);
    }

    // Create new empty draft
    return const UnitWizardDraft(
      createdAt: null, // Will be set on first save
    );
  }

  /// Update a single field with auto-save (2s debounce)
  Future<void> updateField(String field, dynamic value) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Update local state immediately
    state = AsyncValue.data(
      _updateDraftField(currentState, field, value),
    );

    // Schedule auto-save (debounced)
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveDraft();
    });
  }

  /// Update multiple fields at once
  Future<void> updateFields(Map<String, dynamic> fields) async {
    final currentState = state.value;
    if (currentState == null) return;

    var updatedDraft = currentState;
    for (final entry in fields.entries) {
      updatedDraft = _updateDraftField(updatedDraft, entry.key, entry.value);
    }

    state = AsyncValue.data(updatedDraft);

    // Auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveDraft();
    });
  }

  /// Go to next step
  Future<void> goToNextStep() async {
    final currentState = state.value;
    if (currentState == null || currentState.currentStep >= 8) return;

    final nextStep = currentState.currentStep + 1;
    state = AsyncValue.data(
      currentState.copyWith(currentStep: nextStep),
    );

    await _saveDraft(); // Save immediately when changing steps
  }

  /// Go to previous step
  Future<void> goToPreviousStep() async {
    final currentState = state.value;
    if (currentState == null || currentState.currentStep <= 1) return;

    final prevStep = currentState.currentStep - 1;
    state = AsyncValue.data(
      currentState.copyWith(currentStep: prevStep),
    );

    await _saveDraft();
  }

  /// Jump to specific step
  Future<void> jumpToStep(int step) async {
    if (step < 1 || step > 8) return;

    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(currentStep: step),
    );

    await _saveDraft();
  }

  /// Mark step as completed
  Future<void> markStepCompleted(int step) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedCompletedSteps = Map<int, bool>.from(currentState.completedSteps);
    updatedCompletedSteps[step] = true;

    state = AsyncValue.data(
      currentState.copyWith(completedSteps: updatedCompletedSteps),
    );

    await _saveDraft();
  }

  /// Mark step as skipped
  Future<void> markStepSkipped(int step) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedSkippedSteps = Map<int, bool>.from(currentState.skippedSteps);
    updatedSkippedSteps[step] = true;

    state = AsyncValue.data(
      currentState.copyWith(skippedSteps: updatedSkippedSteps),
    );

    await _saveDraft();
  }

  /// Save draft to Firestore
  Future<void> _saveDraft() async {
    final currentState = state.value;
    if (currentState == null) return;

    final authState = ref.read(enhancedAuthProvider);
    final userId = authState.firebaseUser?.uid;
    if (userId == null) return;

    try {
      // Add createdAt if this is first save
      final draftToSave = currentState.createdAt == null
          ? currentState.copyWith(createdAt: DateTime.now())
          : currentState;

      await _firestore
          .collection('unit_drafts')
          .doc('${userId}_$_draftId')
          .set(draftToSave.toFirestore());

      // Update state with save timestamp
      state = AsyncValue.data(
        draftToSave.copyWith(lastSaved: DateTime.now()),
      );
    } catch (e) {
      // Silent fail - don't interrupt user flow
      print('[UnitWizard] Auto-save failed: $e');
    }
  }

  /// Clear draft (delete from Firestore)
  Future<void> clearDraft() async {
    final authState = ref.read(enhancedAuthProvider);
    final userId = authState.firebaseUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('unit_drafts')
          .doc('${userId}_$_draftId')
          .delete();
    } catch (e) {
      print('[UnitWizard] Failed to delete draft: $e');
    }
  }

  /// Helper to update draft field by name
  UnitWizardDraft _updateDraftField(
    UnitWizardDraft draft,
    String field,
    dynamic value,
  ) {
    switch (field) {
      // Step 1
      case 'name':
        return draft.copyWith(name: value);
      case 'propertyId':
        return draft.copyWith(propertyId: value);
      case 'description':
        return draft.copyWith(description: value);
      // Step 2
      case 'bedrooms':
        return draft.copyWith(bedrooms: value);
      case 'bathrooms':
        return draft.copyWith(bathrooms: value);
      case 'maxGuests':
        return draft.copyWith(maxGuests: value);
      case 'areaSqm':
        return draft.copyWith(areaSqm: value);
      // Step 3
      case 'pricePerNight':
        return draft.copyWith(pricePerNight: value);
      case 'minStayNights':
        return draft.copyWith(minStayNights: value);
      case 'seasons':
        return draft.copyWith(seasons: value);
      // Step 4
      case 'availableYearRound':
        return draft.copyWith(availableYearRound: value);
      case 'seasonStartDate':
        return draft.copyWith(seasonStartDate: value);
      case 'seasonEndDate':
        return draft.copyWith(seasonEndDate: value);
      case 'blockedDates':
        return draft.copyWith(blockedDates: value);
      // Step 5
      case 'images':
        return draft.copyWith(images: value);
      case 'coverImageUrl':
        return draft.copyWith(coverImageUrl: value);
      // Step 6
      case 'widgetMode':
        return draft.copyWith(widgetMode: value);
      case 'widgetTheme':
        return draft.copyWith(widgetTheme: value);
      case 'widgetSettings':
        return draft.copyWith(widgetSettings: value);
      // Step 7
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
