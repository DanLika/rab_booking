import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/geopoint_converter.dart';
import 'property_model.dart';

part 'property_summary_model.g.dart';
part 'property_summary_model.freezed.dart';

/// Lightweight property summary for lists and dropdowns
/// Corresponds to the "Metadata" concept (reduced payload)
@freezed
class PropertySummary with _$PropertySummary {
  const factory PropertySummary({
    required String id,
    required String name,
    required String location,
    String? coverImage,
    @Default(0) int unitsCount,
    @Default(true) bool isActive,
  }) = _PropertySummary;

  factory PropertySummary.fromJson(Map<String, dynamic> json) =>
      _$PropertySummaryFromJson(json);

  // Factory to create from full PropertyModel
  factory PropertySummary.fromModel(PropertyModel model) {
    return PropertySummary(
      id: model.id,
      name: model.name,
      location: model.location,
      coverImage: model.primaryImage,
      unitsCount: model.unitsCount,
      isActive: model.isActive,
    );
  }
}
