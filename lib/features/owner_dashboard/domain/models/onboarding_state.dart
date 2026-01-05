import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

/// Onboarding wizard state
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default([]) List<int> completedSteps,
    PropertyFormData? propertyData,
    UnitFormData? unitData,
    PricingFormData? pricingData,
    @Default(false) bool isSkipped,
    @Default(false) bool isCompleted,
  }) = _OnboardingState;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);
}

/// Property form data (Step 1)
@freezed
class PropertyFormData with _$PropertyFormData {
  const factory PropertyFormData({
    required String name,
    required String propertyType,
    required String address,
    required String city,
    required String country,
    String? phone,
    String? email,
    String? website,
  }) = _PropertyFormData;

  factory PropertyFormData.fromJson(Map<String, dynamic> json) =>
      _$PropertyFormDataFromJson(json);
}

/// Unit form data (Step 2 - Optional)
@freezed
class UnitFormData with _$UnitFormData {
  const factory UnitFormData({
    required String name,
    required String unitType,
    required int maxGuests,
    int? numBeds,
    int? numBathrooms,
    String? description,
  }) = _UnitFormData;

  factory UnitFormData.fromJson(Map<String, dynamic> json) =>
      _$UnitFormDataFromJson(json);
}

/// Pricing form data (Step 3 - Optional)
@freezed
class PricingFormData with _$PricingFormData {
  const factory PricingFormData({double? basePrice, String? currency}) =
      _PricingFormData;

  factory PricingFormData.fromJson(Map<String, dynamic> json) =>
      _$PricingFormDataFromJson(json);
}
