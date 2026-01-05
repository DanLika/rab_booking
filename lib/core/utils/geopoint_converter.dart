import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper functions for converting Firestore GeoPoint to/from JSON
/// Use with @JsonKey(fromJson: geoPointFromJson, toJson: geoPointToJson)

GeoPoint? geoPointFromJson(dynamic json) {
  if (json == null) return null;

  // If it's already a GeoPoint, return it
  if (json is GeoPoint) return json;

  // Handle Map (from JSON or Firestore)
  if (json is Map<String, dynamic>) {
    // Handle GeoPoint object from Firestore
    if (json['_latitude'] != null && json['_longitude'] != null) {
      return GeoPoint(
        (json['_latitude'] as num).toDouble(),
        (json['_longitude'] as num).toDouble(),
      );
    }

    // Handle plain JSON with latitude/longitude keys
    if (json['latitude'] != null && json['longitude'] != null) {
      return GeoPoint(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }
  }

  return null;
}

Map<String, dynamic>? geoPointToJson(GeoPoint? geoPoint) {
  if (geoPoint == null) return null;

  return {'latitude': geoPoint.latitude, 'longitude': geoPoint.longitude};
}
