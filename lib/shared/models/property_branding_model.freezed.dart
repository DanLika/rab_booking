// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_branding_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PropertyBranding _$PropertyBrandingFromJson(Map<String, dynamic> json) {
  return _PropertyBranding.fromJson(json);
}

/// @nodoc
mixin _$PropertyBranding {
  /// Custom display name (defaults to property name if null)
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;

  /// Logo URL for branding
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;

  /// Primary brand color (hex format, e.g., "#1976d2")
  @JsonKey(name: 'primary_color')
  String? get primaryColor => throw _privateConstructorUsedError;

  /// Secondary brand color (hex format)
  @JsonKey(name: 'secondary_color')
  String? get secondaryColor => throw _privateConstructorUsedError;

  /// Favicon URL for widget
  @JsonKey(name: 'favicon_url')
  String? get faviconUrl => throw _privateConstructorUsedError;

  /// Serializes this PropertyBranding to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PropertyBranding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertyBrandingCopyWith<PropertyBranding> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyBrandingCopyWith<$Res> {
  factory $PropertyBrandingCopyWith(
    PropertyBranding value,
    $Res Function(PropertyBranding) then,
  ) = _$PropertyBrandingCopyWithImpl<$Res, PropertyBranding>;
  @useResult
  $Res call({
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
    @JsonKey(name: 'favicon_url') String? faviconUrl,
  });
}

/// @nodoc
class _$PropertyBrandingCopyWithImpl<$Res, $Val extends PropertyBranding>
    implements $PropertyBrandingCopyWith<$Res> {
  _$PropertyBrandingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PropertyBranding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = freezed,
    Object? logoUrl = freezed,
    Object? primaryColor = freezed,
    Object? secondaryColor = freezed,
    Object? faviconUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryColor: freezed == primaryColor
                ? _value.primaryColor
                : primaryColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            secondaryColor: freezed == secondaryColor
                ? _value.secondaryColor
                : secondaryColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            faviconUrl: freezed == faviconUrl
                ? _value.faviconUrl
                : faviconUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PropertyBrandingImplCopyWith<$Res>
    implements $PropertyBrandingCopyWith<$Res> {
  factory _$$PropertyBrandingImplCopyWith(
    _$PropertyBrandingImpl value,
    $Res Function(_$PropertyBrandingImpl) then,
  ) = __$$PropertyBrandingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'primary_color') String? primaryColor,
    @JsonKey(name: 'secondary_color') String? secondaryColor,
    @JsonKey(name: 'favicon_url') String? faviconUrl,
  });
}

/// @nodoc
class __$$PropertyBrandingImplCopyWithImpl<$Res>
    extends _$PropertyBrandingCopyWithImpl<$Res, _$PropertyBrandingImpl>
    implements _$$PropertyBrandingImplCopyWith<$Res> {
  __$$PropertyBrandingImplCopyWithImpl(
    _$PropertyBrandingImpl _value,
    $Res Function(_$PropertyBrandingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PropertyBranding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = freezed,
    Object? logoUrl = freezed,
    Object? primaryColor = freezed,
    Object? secondaryColor = freezed,
    Object? faviconUrl = freezed,
  }) {
    return _then(
      _$PropertyBrandingImpl(
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryColor: freezed == primaryColor
            ? _value.primaryColor
            : primaryColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        secondaryColor: freezed == secondaryColor
            ? _value.secondaryColor
            : secondaryColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        faviconUrl: freezed == faviconUrl
            ? _value.faviconUrl
            : faviconUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PropertyBrandingImpl extends _PropertyBranding {
  const _$PropertyBrandingImpl({
    @JsonKey(name: 'display_name') this.displayName,
    @JsonKey(name: 'logo_url') this.logoUrl,
    @JsonKey(name: 'primary_color') this.primaryColor,
    @JsonKey(name: 'secondary_color') this.secondaryColor,
    @JsonKey(name: 'favicon_url') this.faviconUrl,
  }) : super._();

  factory _$PropertyBrandingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PropertyBrandingImplFromJson(json);

  /// Custom display name (defaults to property name if null)
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;

  /// Logo URL for branding
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  /// Primary brand color (hex format, e.g., "#1976d2")
  @override
  @JsonKey(name: 'primary_color')
  final String? primaryColor;

  /// Secondary brand color (hex format)
  @override
  @JsonKey(name: 'secondary_color')
  final String? secondaryColor;

  /// Favicon URL for widget
  @override
  @JsonKey(name: 'favicon_url')
  final String? faviconUrl;

  @override
  String toString() {
    return 'PropertyBranding(displayName: $displayName, logoUrl: $logoUrl, primaryColor: $primaryColor, secondaryColor: $secondaryColor, faviconUrl: $faviconUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertyBrandingImpl &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.secondaryColor, secondaryColor) ||
                other.secondaryColor == secondaryColor) &&
            (identical(other.faviconUrl, faviconUrl) ||
                other.faviconUrl == faviconUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    displayName,
    logoUrl,
    primaryColor,
    secondaryColor,
    faviconUrl,
  );

  /// Create a copy of PropertyBranding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertyBrandingImplCopyWith<_$PropertyBrandingImpl> get copyWith =>
      __$$PropertyBrandingImplCopyWithImpl<_$PropertyBrandingImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PropertyBrandingImplToJson(this);
  }
}

abstract class _PropertyBranding extends PropertyBranding {
  const factory _PropertyBranding({
    @JsonKey(name: 'display_name') final String? displayName,
    @JsonKey(name: 'logo_url') final String? logoUrl,
    @JsonKey(name: 'primary_color') final String? primaryColor,
    @JsonKey(name: 'secondary_color') final String? secondaryColor,
    @JsonKey(name: 'favicon_url') final String? faviconUrl,
  }) = _$PropertyBrandingImpl;
  const _PropertyBranding._() : super._();

  factory _PropertyBranding.fromJson(Map<String, dynamic> json) =
      _$PropertyBrandingImpl.fromJson;

  /// Custom display name (defaults to property name if null)
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;

  /// Logo URL for branding
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;

  /// Primary brand color (hex format, e.g., "#1976d2")
  @override
  @JsonKey(name: 'primary_color')
  String? get primaryColor;

  /// Secondary brand color (hex format)
  @override
  @JsonKey(name: 'secondary_color')
  String? get secondaryColor;

  /// Favicon URL for widget
  @override
  @JsonKey(name: 'favicon_url')
  String? get faviconUrl;

  /// Create a copy of PropertyBranding
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertyBrandingImplCopyWith<_$PropertyBrandingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
