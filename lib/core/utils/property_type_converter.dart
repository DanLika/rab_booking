import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/enums.dart';

/// Custom JSON converter for PropertyType that handles legacy values
/// Maps unknown values (apartment, studio, room) to PropertyType.other
class PropertyTypeConverter implements JsonConverter<PropertyType, String?> {
  const PropertyTypeConverter();

  @override
  PropertyType fromJson(String? json) {
    if (json == null) return PropertyType.villa;

    // Try to match known values
    for (final type in PropertyType.values) {
      if (type.value == json) {
        return type;
      }
    }

    // Legacy values map to 'other'
    // This handles: apartment, studio, room, and any other unknown values
    return PropertyType.other;
  }

  @override
  String toJson(PropertyType object) => object.value;
}
