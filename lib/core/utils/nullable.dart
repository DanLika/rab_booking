/// A wrapper class that allows distinguishing between "not provided" and "explicitly null"
/// in copyWith methods.
///
/// This solves the problem where `value ?? this.value` cannot differentiate between:
/// - Parameter not passed (should keep existing value)
/// - Parameter passed as null (should set to null)
///
/// ## Usage in copyWith:
/// ```dart
/// class MyModel {
///   final String? optionalField;
///
///   MyModel copyWith({
///     Nullable<String>? optionalField,
///   }) {
///     return MyModel(
///       optionalField: optionalField != null
///           ? optionalField.value
///           : this.optionalField,
///     );
///   }
/// }
///
/// // Keep existing value
/// model.copyWith();
///
/// // Set to new value
/// model.copyWith(optionalField: Nullable('new value'));
///
/// // Explicitly set to null
/// model.copyWith(optionalField: Nullable(null));
/// // Or use the convenience constructor:
/// model.copyWith(optionalField: Nullable.nil());
/// ```
class Nullable<T> {
  /// The wrapped value, which may be null.
  final T? value;

  /// Creates a Nullable wrapper with the given value.
  /// The value can be null to explicitly set a field to null.
  const Nullable(this.value);

  /// Convenience constructor to create a Nullable with null value.
  /// This is more readable than `Nullable<String>(null)`.
  const Nullable.nil() : value = null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nullable<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Nullable<$T>($value)';
}
