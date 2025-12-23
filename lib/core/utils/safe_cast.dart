/// Safe casting utilities to prevent runtime errors from invalid data types
///
/// Use these helpers when deserializing data from external sources
/// (Firestore, SharedPreferences, JSON) to prevent crashes from unexpected types.
///
/// **Problem**: Direct casting like `data['field'] as String` throws if type is wrong
/// **Solution**: These helpers return null or default values on type mismatches
library;

/// Safely cast dynamic value to String
///
/// Returns null if value is null or not a String
///
/// Example:
/// ```dart
/// final name = safeCastString(data['name']); // Returns null if not String
/// final nameOrDefault = safeCastString(data['name']) ?? 'Unknown';
/// ```
String? safeCastString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return null; // Invalid type - return null instead of crashing
}

/// Safely cast dynamic value to int
///
/// Returns null if value is null or not an int
///
/// Example:
/// ```dart
/// final count = safeCastInt(data['count']); // Returns null if not int
/// final countOrDefault = safeCastInt(data['count']) ?? 0;
/// ```
int? safeCastInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  // Handle double that represents an integer (e.g., 5.0 from JSON)
  if (value is double && value == value.toInt()) {
    return value.toInt();
  }
  return null;
}

/// Safely cast dynamic value to double
///
/// Returns null if value is null or not a number
///
/// Example:
/// ```dart
/// final price = safeCastDouble(data['price']); // Returns null if not number
/// final priceOrDefault = safeCastDouble(data['price']) ?? 0.0;
/// ```
double? safeCastDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return null;
}

/// Safely cast dynamic value to bool
///
/// Returns null if value is null or not a bool
///
/// Example:
/// ```dart
/// final enabled = safeCastBool(data['enabled']); // Returns null if not bool
/// final enabledOrDefault = safeCastBool(data['enabled']) ?? false;
/// ```
bool? safeCastBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  return null;
}

/// Safely cast dynamic value to List of type T
///
/// Returns null if value is null or not a List
/// Individual items that don't match type T are filtered out
///
/// Example:
/// ```dart
/// final ids = safeCastList<int>(data['ids']); // Returns List of int or null
/// final idsOrEmpty = safeCastList<int>(data['ids']) ?? [];
/// ```
List<T>? safeCastList<T>(dynamic value) {
  if (value == null) return null;
  if (value is! List) return null;

  // Filter out items that don't match type T
  final result = <T>[];
  for (final item in value) {
    if (item is T) {
      result.add(item);
    }
  }

  return result;
}

/// Safely cast dynamic value to Map with String keys and dynamic values
///
/// Returns null if value is null or not a Map
///
/// Example:
/// ```dart
/// final config = safeCastMap(data['config']); // Returns Map or null
/// final configOrEmpty = safeCastMap(data['config']) ?? {};
/// ```
Map<String, dynamic>? safeCastMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;

  // Try to convert Map<dynamic, dynamic> to Map<String, dynamic>
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } catch (e) {
      return null; // Conversion failed
    }
  }

  return null;
}

/// Validate that a Map contains required keys
///
/// Throws ArgumentError if any required key is missing
///
/// Example:
/// ```dart
/// validateRequiredKeys(data, ['id', 'name']);
/// // Throws if 'id' or 'name' is missing from data
/// ```
void validateRequiredKeys(
  Map<String, dynamic> data,
  List<String> requiredKeys,
) {
  for (final key in requiredKeys) {
    if (!data.containsKey(key) || data[key] == null) {
      throw ArgumentError(
        'Required key "$key" is missing or null in data: $data',
      );
    }
  }
}

/// Safely get a value from Map with fallback
///
/// Returns fallback if key doesn't exist or value has wrong type
///
/// Example:
/// ```dart
/// final name = safeMapGet(data, 'name', 'Unknown');
/// final count = safeMapGet(data, 'count', 0);
/// ```
T safeMapGet<T>(Map<String, dynamic> data, String key, T fallback) {
  final value = data[key];
  if (value == null) return fallback;

  // Type-specific handling
  if (T == String) {
    return safeCastString(value) as T? ?? fallback;
  } else if (T == int) {
    return safeCastInt(value) as T? ?? fallback;
  } else if (T == double) {
    return safeCastDouble(value) as T? ?? fallback;
  } else if (T == bool) {
    return safeCastBool(value) as T? ?? fallback;
  } else if (value is T) {
    return value;
  }

  return fallback;
}
