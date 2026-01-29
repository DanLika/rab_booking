import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../../shared/models/unit_model.dart';

part 'unit_wizard_state.freezed.dart';
part 'unit_wizard_state.g.dart';

/// Unit Wizard Draft - stores partial unit data during wizard flow
/// Supports auto-save, resume, and skip functionality
@freezed
class UnitWizardDraft with _$UnitWizardDraft {
  const factory UnitWizardDraft({
    // Meta
    String? unitId, // null = new unit, non-null = edit existing
    @Default(1) int currentStep, // 1-8
    @Default({}) Map<int, bool> completedSteps, // {1: true, 2: true, ...}
    @Default({}) Map<int, bool> skippedSteps, // {5: true, 7: true}
    // Step 1: Basic Info (REQUIRED)
    String? name,
    String? propertyId,
    String? description,
    String? slug, // Auto-generated from name
    // Step 2: Capacity & Space (REQUIRED)
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    double? areaSqm,

    // Step 3: Pricing (REQUIRED)
    double? pricePerNight,
    double? weekendBasePrice, // Weekend price (Fri-Sat nights by default)
    @Default([5, 6])
    List<int>
    weekendDays, // Days considered weekend (1=Mon...7=Sun) - Fri=5, Sat=6 for hotel nights
    int? minStayNights,
    int? maxStayNights, // Maximum nights per booking (null = no limit)
    int? maxTotalCapacity, // Max guests including extra beds
    double? extraBedFee, // Fee per extra person per night
    double? petFee, // Fee per pet per night
    @Default([])
    List<Map<String, dynamic>> seasons, // Seasonal pricing (simplified)
    // Step 4: Availability (REQUIRED)
    @Default(true) bool availableYearRound,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    @Default([]) List<DateTime> blockedDates,

    // Step 5: Photos (RECOMMENDED)
    @Default([]) List<String> images, // URLs after upload
    String? coverImageUrl, // First image by default
    // Step 6: Widget Setup (RECOMMENDED)
    String? widgetMode, // 'calendarOnly', 'bookingInstant', 'bookingPending'
    String? widgetTheme, // 'minimalist', 'modern', 'luxury'
    Map<String, dynamic>? widgetSettings, // Full widget_settings data
    // Step 7: Advanced Options (OPTIONAL)
    Map<String, dynamic>? icalConfig,
    Map<String, dynamic>? emailConfig,
    Map<String, dynamic>? taxLegalConfig,

    // Step 8: Review & Publish (FINAL)
    @Default(true)
    bool isPublished, // Default to ON - most owners want to publish immediately
    // Timestamps
    DateTime? lastSaved,
    DateTime? createdAt,
  }) = _UnitWizardDraft;

  factory UnitWizardDraft.fromJson(Map<String, dynamic> json) =>
      _$UnitWizardDraftFromJson(json);

  /// Create draft from existing unit (for edit mode)
  factory UnitWizardDraft.fromUnit(UnitModel unit) {
    return UnitWizardDraft(
      unitId: unit.id,
      completedSteps: {1: true, 2: true, 3: true, 4: true},
      name: unit.name,
      propertyId: unit.propertyId,
      description: unit.description,
      slug: unit.slug,
      bedrooms: unit.bedrooms,
      bathrooms: unit.bathrooms,
      maxGuests: unit.maxGuests,
      areaSqm: unit.areaSqm,
      pricePerNight: unit.pricePerNight,
      weekendBasePrice: unit.weekendBasePrice,
      weekendDays: unit.weekendDays ?? [5, 6],
      minStayNights: unit.minStayNights,
      maxStayNights: unit.maxStayNights,
      maxTotalCapacity: unit.maxTotalCapacity,
      extraBedFee: unit.extraBedFee,
      petFee: unit.petFee,
      images: unit.images,
      coverImageUrl: unit.images.isNotEmpty ? unit.images.first : null,
      widgetMode: 'bookingInstant',
      widgetTheme: 'minimalist',
      isPublished: unit.isAvailable,
      createdAt: unit.createdAt,
    );
  }
}
