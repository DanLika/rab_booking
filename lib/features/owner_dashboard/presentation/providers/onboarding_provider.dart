import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/onboarding_state.dart';
import '../../../../core/exceptions/app_exceptions.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() {
    // Try to load saved progress on init
    _loadProgress();
    return const OnboardingState();
  }

  /// Load saved progress from Firestore
  Future<void> _loadProgress() async {
    try {
      final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('onboarding_progress')
          .doc('current')
          .get();

      if (doc.exists) {
        state = OnboardingState.fromJson(doc.data()!);
      }
    } catch (e) {
      unawaited(LoggingService.logError('Failed to load onboarding progress', e));
    }
  }

  /// Save progress to Firestore after each step
  Future<void> saveProgress() async {
    try {
      final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('onboarding_progress')
          .doc('current')
          .set(state.toJson());

      LoggingService.log(
        'Onboarding progress saved: Step ${state.currentStep}',
        tag: 'ONBOARDING',
      );
    } catch (e) {
      unawaited(LoggingService.logError('Failed to save onboarding progress', e));
      rethrow;
    }
  }

  /// Delete progress data (called on completion)
  Future<void> _deleteProgress() async {
    try {
      final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('onboarding_progress')
          .doc('current')
          .delete();

      LoggingService.log('Onboarding progress deleted', tag: 'ONBOARDING');
    } catch (e) {
      unawaited(LoggingService.logError('Failed to delete onboarding progress', e));
    }
  }

  /// Save property data (Step 1)
  void savePropertyData(PropertyFormData data) {
    state = state.copyWith(propertyData: data);
  }

  /// Save unit data (Step 2)
  void saveUnitData(UnitFormData? data) {
    state = state.copyWith(unitData: data);
  }

  /// Save pricing data (Step 3)
  void savePricingData(PricingFormData? data) {
    state = state.copyWith(pricingData: data);
  }

  /// Move to next step
  Future<void> nextStep() async {
    if (state.currentStep < 2) {
      final newStep = state.currentStep + 1;
      final completed = [...state.completedSteps, state.currentStep];

      state = state.copyWith(currentStep: newStep, completedSteps: completed);

      await saveProgress();
    }
  }

  /// Move to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Create actual property in Firebase (from Step 1 data)
  Future<String> createProperty() async {
    if (state.propertyData == null) {
      throw PropertyException('Property data is null', code: 'property/data-missing');
    }

    final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
    if (userId == null) {
      throw AuthException('User not authenticated', code: 'auth/not-authenticated');
    }

    final data = state.propertyData!;
    final propertyRepository = ref.read(ownerPropertiesRepositoryProvider);

    // Create property using repository method with named parameters
    final property = await propertyRepository.createProperty(
      ownerId: userId,
      name: data.name,
      description: 'Property created via onboarding wizard',
      propertyType: data.propertyType,
      location: '${data.address}, ${data.city}, ${data.country}',
      amenities: [],
    );

    LoggingService.log('Property created: ${property.id}', tag: 'ONBOARDING');
    return property.id;
  }

  /// Create unit in Firebase (from Step 2 data)
  Future<String?> createUnit(String propertyId) async {
    if (state.unitData == null) {
      return null; // Optional step
    }

    final data = state.unitData!;
    final unitRepository = ref.read(unitRepositoryProvider);

    final unit = UnitModel(
      id: '', // Will be set by repository
      propertyId: propertyId,
      name: data.name,
      maxGuests: data.maxGuests,
      bedrooms: data.numBeds ?? 1,
      bathrooms: data.numBathrooms ?? 1,
      description: data.description,
      pricePerNight: state.pricingData?.basePrice ?? 0.0,
      images: [],
      createdAt: DateTime.now(),
    );

    final createdUnit = await unitRepository.createUnit(unit);
    LoggingService.log('Unit created: ${createdUnit.id}', tag: 'ONBOARDING');
    return createdUnit.id;
  }

  /// Complete onboarding wizard
  Future<void> complete() async {
    try {
      // Mark as completed
      state = state.copyWith(isCompleted: true);

      // Update user's onboardingCompleted field
      await ref.read(enhancedAuthProvider.notifier).completeOnboarding();

      // Delete progress data
      await _deleteProgress();

      LoggingService.log('Wizard completed successfully', tag: 'ONBOARDING');
    } catch (e) {
      unawaited(LoggingService.logError('Failed to complete onboarding wizard', e));
      rethrow;
    }
  }

  /// Skip onboarding wizard
  Future<void> skip() async {
    try {
      state = state.copyWith(isSkipped: true);

      // Mark onboarding as completed (even though skipped)
      await ref.read(enhancedAuthProvider.notifier).completeOnboarding();

      // Delete progress
      await _deleteProgress();

      LoggingService.log('Wizard skipped', tag: 'ONBOARDING');
    } catch (e) {
      unawaited(LoggingService.logError('Failed to skip onboarding wizard', e));
      rethrow;
    }
  }

  /// Reset onboarding state
  void reset() {
    state = const OnboardingState();
  }
}
