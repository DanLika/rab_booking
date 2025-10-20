// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SearchFilters _$SearchFiltersFromJson(Map<String, dynamic> json) {
  return _SearchFilters.fromJson(json);
}

/// @nodoc
mixin _$SearchFilters {
  // Location & dates (from search bar)
  String? get location => throw _privateConstructorUsedError;
  DateTime? get checkIn => throw _privateConstructorUsedError;
  DateTime? get checkOut => throw _privateConstructorUsedError;
  int get guests => throw _privateConstructorUsedError; // Price range
  double? get minPrice => throw _privateConstructorUsedError;
  double? get maxPrice => throw _privateConstructorUsedError; // Property type
  List<PropertyType> get propertyTypes =>
      throw _privateConstructorUsedError; // Single property type filter (for saved searches)
  String? get propertyType => throw _privateConstructorUsedError; // Amenities
  List<String> get amenities =>
      throw _privateConstructorUsedError; // Minimum rating filter
  double? get minRating =>
      throw _privateConstructorUsedError; // Bedrooms & bathrooms
  int? get minBedrooms => throw _privateConstructorUsedError;
  int? get minBathrooms => throw _privateConstructorUsedError; // Sorting
  SortBy get sortBy => throw _privateConstructorUsedError; // Pagination
  int get page => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;

  /// Serializes this SearchFilters to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchFiltersCopyWith<SearchFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchFiltersCopyWith<$Res> {
  factory $SearchFiltersCopyWith(
    SearchFilters value,
    $Res Function(SearchFilters) then,
  ) = _$SearchFiltersCopyWithImpl<$Res, SearchFilters>;
  @useResult
  $Res call({
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    int guests,
    double? minPrice,
    double? maxPrice,
    List<PropertyType> propertyTypes,
    String? propertyType,
    List<String> amenities,
    double? minRating,
    int? minBedrooms,
    int? minBathrooms,
    SortBy sortBy,
    int page,
    int pageSize,
  });
}

/// @nodoc
class _$SearchFiltersCopyWithImpl<$Res, $Val extends SearchFilters>
    implements $SearchFiltersCopyWith<$Res> {
  _$SearchFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = freezed,
    Object? checkIn = freezed,
    Object? checkOut = freezed,
    Object? guests = null,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? propertyTypes = null,
    Object? propertyType = freezed,
    Object? amenities = null,
    Object? minRating = freezed,
    Object? minBedrooms = freezed,
    Object? minBathrooms = freezed,
    Object? sortBy = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(
      _value.copyWith(
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            checkIn: freezed == checkIn
                ? _value.checkIn
                : checkIn // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            checkOut: freezed == checkOut
                ? _value.checkOut
                : checkOut // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            guests: null == guests
                ? _value.guests
                : guests // ignore: cast_nullable_to_non_nullable
                      as int,
            minPrice: freezed == minPrice
                ? _value.minPrice
                : minPrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            maxPrice: freezed == maxPrice
                ? _value.maxPrice
                : maxPrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            propertyTypes: null == propertyTypes
                ? _value.propertyTypes
                : propertyTypes // ignore: cast_nullable_to_non_nullable
                      as List<PropertyType>,
            propertyType: freezed == propertyType
                ? _value.propertyType
                : propertyType // ignore: cast_nullable_to_non_nullable
                      as String?,
            amenities: null == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            minRating: freezed == minRating
                ? _value.minRating
                : minRating // ignore: cast_nullable_to_non_nullable
                      as double?,
            minBedrooms: freezed == minBedrooms
                ? _value.minBedrooms
                : minBedrooms // ignore: cast_nullable_to_non_nullable
                      as int?,
            minBathrooms: freezed == minBathrooms
                ? _value.minBathrooms
                : minBathrooms // ignore: cast_nullable_to_non_nullable
                      as int?,
            sortBy: null == sortBy
                ? _value.sortBy
                : sortBy // ignore: cast_nullable_to_non_nullable
                      as SortBy,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            pageSize: null == pageSize
                ? _value.pageSize
                : pageSize // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchFiltersImplCopyWith<$Res>
    implements $SearchFiltersCopyWith<$Res> {
  factory _$$SearchFiltersImplCopyWith(
    _$SearchFiltersImpl value,
    $Res Function(_$SearchFiltersImpl) then,
  ) = __$$SearchFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    int guests,
    double? minPrice,
    double? maxPrice,
    List<PropertyType> propertyTypes,
    String? propertyType,
    List<String> amenities,
    double? minRating,
    int? minBedrooms,
    int? minBathrooms,
    SortBy sortBy,
    int page,
    int pageSize,
  });
}

/// @nodoc
class __$$SearchFiltersImplCopyWithImpl<$Res>
    extends _$SearchFiltersCopyWithImpl<$Res, _$SearchFiltersImpl>
    implements _$$SearchFiltersImplCopyWith<$Res> {
  __$$SearchFiltersImplCopyWithImpl(
    _$SearchFiltersImpl _value,
    $Res Function(_$SearchFiltersImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? location = freezed,
    Object? checkIn = freezed,
    Object? checkOut = freezed,
    Object? guests = null,
    Object? minPrice = freezed,
    Object? maxPrice = freezed,
    Object? propertyTypes = null,
    Object? propertyType = freezed,
    Object? amenities = null,
    Object? minRating = freezed,
    Object? minBedrooms = freezed,
    Object? minBathrooms = freezed,
    Object? sortBy = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(
      _$SearchFiltersImpl(
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        checkIn: freezed == checkIn
            ? _value.checkIn
            : checkIn // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        checkOut: freezed == checkOut
            ? _value.checkOut
            : checkOut // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        guests: null == guests
            ? _value.guests
            : guests // ignore: cast_nullable_to_non_nullable
                  as int,
        minPrice: freezed == minPrice
            ? _value.minPrice
            : minPrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        maxPrice: freezed == maxPrice
            ? _value.maxPrice
            : maxPrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        propertyTypes: null == propertyTypes
            ? _value._propertyTypes
            : propertyTypes // ignore: cast_nullable_to_non_nullable
                  as List<PropertyType>,
        propertyType: freezed == propertyType
            ? _value.propertyType
            : propertyType // ignore: cast_nullable_to_non_nullable
                  as String?,
        amenities: null == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        minRating: freezed == minRating
            ? _value.minRating
            : minRating // ignore: cast_nullable_to_non_nullable
                  as double?,
        minBedrooms: freezed == minBedrooms
            ? _value.minBedrooms
            : minBedrooms // ignore: cast_nullable_to_non_nullable
                  as int?,
        minBathrooms: freezed == minBathrooms
            ? _value.minBathrooms
            : minBathrooms // ignore: cast_nullable_to_non_nullable
                  as int?,
        sortBy: null == sortBy
            ? _value.sortBy
            : sortBy // ignore: cast_nullable_to_non_nullable
                  as SortBy,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        pageSize: null == pageSize
            ? _value.pageSize
            : pageSize // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchFiltersImpl extends _SearchFilters {
  const _$SearchFiltersImpl({
    this.location,
    this.checkIn,
    this.checkOut,
    this.guests = 2,
    this.minPrice,
    this.maxPrice,
    final List<PropertyType> propertyTypes = const [],
    this.propertyType,
    final List<String> amenities = const [],
    this.minRating,
    this.minBedrooms,
    this.minBathrooms,
    this.sortBy = SortBy.recommended,
    this.page = 0,
    this.pageSize = 20,
  }) : _propertyTypes = propertyTypes,
       _amenities = amenities,
       super._();

  factory _$SearchFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchFiltersImplFromJson(json);

  // Location & dates (from search bar)
  @override
  final String? location;
  @override
  final DateTime? checkIn;
  @override
  final DateTime? checkOut;
  @override
  @JsonKey()
  final int guests;
  // Price range
  @override
  final double? minPrice;
  @override
  final double? maxPrice;
  // Property type
  final List<PropertyType> _propertyTypes;
  // Property type
  @override
  @JsonKey()
  List<PropertyType> get propertyTypes {
    if (_propertyTypes is EqualUnmodifiableListView) return _propertyTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_propertyTypes);
  }

  // Single property type filter (for saved searches)
  @override
  final String? propertyType;
  // Amenities
  final List<String> _amenities;
  // Amenities
  @override
  @JsonKey()
  List<String> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  // Minimum rating filter
  @override
  final double? minRating;
  // Bedrooms & bathrooms
  @override
  final int? minBedrooms;
  @override
  final int? minBathrooms;
  // Sorting
  @override
  @JsonKey()
  final SortBy sortBy;
  // Pagination
  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final int pageSize;

  @override
  String toString() {
    return 'SearchFilters(location: $location, checkIn: $checkIn, checkOut: $checkOut, guests: $guests, minPrice: $minPrice, maxPrice: $maxPrice, propertyTypes: $propertyTypes, propertyType: $propertyType, amenities: $amenities, minRating: $minRating, minBedrooms: $minBedrooms, minBathrooms: $minBathrooms, sortBy: $sortBy, page: $page, pageSize: $pageSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchFiltersImpl &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.checkIn, checkIn) || other.checkIn == checkIn) &&
            (identical(other.checkOut, checkOut) ||
                other.checkOut == checkOut) &&
            (identical(other.guests, guests) || other.guests == guests) &&
            (identical(other.minPrice, minPrice) ||
                other.minPrice == minPrice) &&
            (identical(other.maxPrice, maxPrice) ||
                other.maxPrice == maxPrice) &&
            const DeepCollectionEquality().equals(
              other._propertyTypes,
              _propertyTypes,
            ) &&
            (identical(other.propertyType, propertyType) ||
                other.propertyType == propertyType) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            (identical(other.minRating, minRating) ||
                other.minRating == minRating) &&
            (identical(other.minBedrooms, minBedrooms) ||
                other.minBedrooms == minBedrooms) &&
            (identical(other.minBathrooms, minBathrooms) ||
                other.minBathrooms == minBathrooms) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    location,
    checkIn,
    checkOut,
    guests,
    minPrice,
    maxPrice,
    const DeepCollectionEquality().hash(_propertyTypes),
    propertyType,
    const DeepCollectionEquality().hash(_amenities),
    minRating,
    minBedrooms,
    minBathrooms,
    sortBy,
    page,
    pageSize,
  );

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchFiltersImplCopyWith<_$SearchFiltersImpl> get copyWith =>
      __$$SearchFiltersImplCopyWithImpl<_$SearchFiltersImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchFiltersImplToJson(this);
  }
}

abstract class _SearchFilters extends SearchFilters {
  const factory _SearchFilters({
    final String? location,
    final DateTime? checkIn,
    final DateTime? checkOut,
    final int guests,
    final double? minPrice,
    final double? maxPrice,
    final List<PropertyType> propertyTypes,
    final String? propertyType,
    final List<String> amenities,
    final double? minRating,
    final int? minBedrooms,
    final int? minBathrooms,
    final SortBy sortBy,
    final int page,
    final int pageSize,
  }) = _$SearchFiltersImpl;
  const _SearchFilters._() : super._();

  factory _SearchFilters.fromJson(Map<String, dynamic> json) =
      _$SearchFiltersImpl.fromJson;

  // Location & dates (from search bar)
  @override
  String? get location;
  @override
  DateTime? get checkIn;
  @override
  DateTime? get checkOut;
  @override
  int get guests; // Price range
  @override
  double? get minPrice;
  @override
  double? get maxPrice; // Property type
  @override
  List<PropertyType> get propertyTypes; // Single property type filter (for saved searches)
  @override
  String? get propertyType; // Amenities
  @override
  List<String> get amenities; // Minimum rating filter
  @override
  double? get minRating; // Bedrooms & bathrooms
  @override
  int? get minBedrooms;
  @override
  int? get minBathrooms; // Sorting
  @override
  SortBy get sortBy; // Pagination
  @override
  int get page;
  @override
  int get pageSize;

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchFiltersImplCopyWith<_$SearchFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
