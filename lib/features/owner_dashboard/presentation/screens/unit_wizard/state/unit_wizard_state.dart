import 'package:cloud_firestore/cloud_firestore.dart';
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
    int? minStayNights,
    @Default([]) List<Map<String, dynamic>> seasons, // Seasonal pricing (simplified)

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
    @Default(false) bool isPublished, // false = draft, true = active unit

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
      currentStep: 1,
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
      minStayNights: unit.minStayNights,
      availableYearRound: true,
      images: unit.images,
      coverImageUrl: unit.images.isNotEmpty ? unit.images.first : null,
      widgetMode: 'bookingInstant',
      widgetTheme: 'minimalist',
      isPublished: unit.isAvailable,
      createdAt: unit.createdAt,
      lastSaved: DateTime.now(),
    );
  }
}

/// Extension for Firestore serialization
extension UnitWizardDraftFirestore on UnitWizardDraft {
  Map<String, dynamic> toFirestore() {
    return {
      'unit_id': unitId,
      'current_step': currentStep,
      'completed_steps': completedSteps.map((k, v) => MapEntry(k.toString(), v)),
      'skipped_steps': skippedSteps.map((k, v) => MapEntry(k.toString(), v)),
      'name': name,
      'property_id': propertyId,
      'description': description,
      'slug': slug,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'max_guests': maxGuests,
      'area_sqm': areaSqm,
      'price_per_night': pricePerNight,
      'min_stay_nights': minStayNights,
      'seasons': seasons,
      'available_year_round': availableYearRound,
      'season_start_date': seasonStartDate != null ? Timestamp.fromDate(seasonStartDate!) : null,
      'season_end_date': seasonEndDate != null ? Timestamp.fromDate(seasonEndDate!) : null,
      'blocked_dates': blockedDates.map((d) => Timestamp.fromDate(d)).toList(),
      'images': images,
      'cover_image_url': coverImageUrl,
      'widget_mode': widgetMode,
      'widget_theme': widgetTheme,
      'widget_settings': widgetSettings,
      'ical_config': icalConfig,
      'email_config': emailConfig,
      'tax_legal_config': taxLegalConfig,
      'is_published': isPublished,
      'last_saved': Timestamp.now(),
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  static UnitWizardDraft fromFirestore(Map<String, dynamic> data) {
    return UnitWizardDraft(
      unitId: data['unit_id'],
      currentStep: data['current_step'] ?? 1,
      completedSteps: (data['completed_steps'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(int.parse(k), v as bool)) ?? {},
      skippedSteps: (data['skipped_steps'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(int.parse(k), v as bool)) ?? {},
      name: data['name'],
      propertyId: data['property_id'],
      description: data['description'],
      slug: data['slug'],
      bedrooms: data['bedrooms'],
      bathrooms: data['bathrooms'],
      maxGuests: data['max_guests'],
      areaSqm: data['area_sqm'],
      pricePerNight: data['price_per_night'],
      minStayNights: data['min_stay_nights'],
      seasons: List<Map<String, dynamic>>.from(data['seasons'] ?? []),
      availableYearRound: data['available_year_round'] ?? true,
      seasonStartDate: data['season_start_date'] != null ? (data['season_start_date'] as Timestamp).toDate() : null,
      seasonEndDate: data['season_end_date'] != null ? (data['season_end_date'] as Timestamp).toDate() : null,
      blockedDates: (data['blocked_dates'] as List<dynamic>?)?.map((t) => (t as Timestamp).toDate()).toList() ?? [],
      images: List<String>.from(data['images'] ?? []),
      coverImageUrl: data['cover_image_url'],
      widgetMode: data['widget_mode'],
      widgetTheme: data['widget_theme'],
      widgetSettings: data['widget_settings'],
      icalConfig: data['ical_config'],
      emailConfig: data['email_config'],
      taxLegalConfig: data['tax_legal_config'],
      isPublished: data['is_published'] ?? false,
      lastSaved: data['last_saved'] != null ? (data['last_saved'] as Timestamp).toDate() : null,
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }
}
