// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_filter_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CalendarFilterOptions _$CalendarFilterOptionsFromJson(
  Map<String, dynamic> json,
) {
  return _CalendarFilterOptions.fromJson(json);
}

/// @nodoc
mixin _$CalendarFilterOptions {
  /// Selected property IDs (empty = all properties)
  List<String> get propertyIds => throw _privateConstructorUsedError;

  /// Selected unit IDs (empty = all units)
  List<String> get unitIds => throw _privateConstructorUsedError;

  /// Selected booking statuses (empty = all statuses)
  /// Values: 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  List<String> get statuses => throw _privateConstructorUsedError;

  /// Selected booking sources (empty = all sources)
  /// Values: 'widget', 'admin', 'booking_com', 'airbnb', 'other'
  List<String> get sources => throw _privateConstructorUsedError;

  /// Start date for filtering (check-in date range start)
  DateTime? get startDate => throw _privateConstructorUsedError;

  /// End date for filtering (check-in date range end)
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// Guest name or email search query
  String? get guestSearchQuery => throw _privateConstructorUsedError;

  /// Booking ID search
  String? get bookingIdSearch => throw _privateConstructorUsedError;

  /// Serializes this CalendarFilterOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarFilterOptionsCopyWith<CalendarFilterOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarFilterOptionsCopyWith<$Res> {
  factory $CalendarFilterOptionsCopyWith(
    CalendarFilterOptions value,
    $Res Function(CalendarFilterOptions) then,
  ) = _$CalendarFilterOptionsCopyWithImpl<$Res, CalendarFilterOptions>;
  @useResult
  $Res call({
    List<String> propertyIds,
    List<String> unitIds,
    List<String> statuses,
    List<String> sources,
    DateTime? startDate,
    DateTime? endDate,
    String? guestSearchQuery,
    String? bookingIdSearch,
  });
}

/// @nodoc
class _$CalendarFilterOptionsCopyWithImpl<
  $Res,
  $Val extends CalendarFilterOptions
>
    implements $CalendarFilterOptionsCopyWith<$Res> {
  _$CalendarFilterOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? propertyIds = null,
    Object? unitIds = null,
    Object? statuses = null,
    Object? sources = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? guestSearchQuery = freezed,
    Object? bookingIdSearch = freezed,
  }) {
    return _then(
      _value.copyWith(
            propertyIds: null == propertyIds
                ? _value.propertyIds
                : propertyIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            unitIds: null == unitIds
                ? _value.unitIds
                : unitIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            statuses: null == statuses
                ? _value.statuses
                : statuses // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sources: null == sources
                ? _value.sources
                : sources // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            guestSearchQuery: freezed == guestSearchQuery
                ? _value.guestSearchQuery
                : guestSearchQuery // ignore: cast_nullable_to_non_nullable
                      as String?,
            bookingIdSearch: freezed == bookingIdSearch
                ? _value.bookingIdSearch
                : bookingIdSearch // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CalendarFilterOptionsImplCopyWith<$Res>
    implements $CalendarFilterOptionsCopyWith<$Res> {
  factory _$$CalendarFilterOptionsImplCopyWith(
    _$CalendarFilterOptionsImpl value,
    $Res Function(_$CalendarFilterOptionsImpl) then,
  ) = __$$CalendarFilterOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> propertyIds,
    List<String> unitIds,
    List<String> statuses,
    List<String> sources,
    DateTime? startDate,
    DateTime? endDate,
    String? guestSearchQuery,
    String? bookingIdSearch,
  });
}

/// @nodoc
class __$$CalendarFilterOptionsImplCopyWithImpl<$Res>
    extends
        _$CalendarFilterOptionsCopyWithImpl<$Res, _$CalendarFilterOptionsImpl>
    implements _$$CalendarFilterOptionsImplCopyWith<$Res> {
  __$$CalendarFilterOptionsImplCopyWithImpl(
    _$CalendarFilterOptionsImpl _value,
    $Res Function(_$CalendarFilterOptionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CalendarFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? propertyIds = null,
    Object? unitIds = null,
    Object? statuses = null,
    Object? sources = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? guestSearchQuery = freezed,
    Object? bookingIdSearch = freezed,
  }) {
    return _then(
      _$CalendarFilterOptionsImpl(
        propertyIds: null == propertyIds
            ? _value._propertyIds
            : propertyIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        unitIds: null == unitIds
            ? _value._unitIds
            : unitIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        statuses: null == statuses
            ? _value._statuses
            : statuses // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sources: null == sources
            ? _value._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        guestSearchQuery: freezed == guestSearchQuery
            ? _value.guestSearchQuery
            : guestSearchQuery // ignore: cast_nullable_to_non_nullable
                  as String?,
        bookingIdSearch: freezed == bookingIdSearch
            ? _value.bookingIdSearch
            : bookingIdSearch // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarFilterOptionsImpl implements _CalendarFilterOptions {
  const _$CalendarFilterOptionsImpl({
    final List<String> propertyIds = const [],
    final List<String> unitIds = const [],
    final List<String> statuses = const [],
    final List<String> sources = const [],
    this.startDate,
    this.endDate,
    this.guestSearchQuery,
    this.bookingIdSearch,
  }) : _propertyIds = propertyIds,
       _unitIds = unitIds,
       _statuses = statuses,
       _sources = sources;

  factory _$CalendarFilterOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarFilterOptionsImplFromJson(json);

  /// Selected property IDs (empty = all properties)
  final List<String> _propertyIds;

  /// Selected property IDs (empty = all properties)
  @override
  @JsonKey()
  List<String> get propertyIds {
    if (_propertyIds is EqualUnmodifiableListView) return _propertyIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_propertyIds);
  }

  /// Selected unit IDs (empty = all units)
  final List<String> _unitIds;

  /// Selected unit IDs (empty = all units)
  @override
  @JsonKey()
  List<String> get unitIds {
    if (_unitIds is EqualUnmodifiableListView) return _unitIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unitIds);
  }

  /// Selected booking statuses (empty = all statuses)
  /// Values: 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  final List<String> _statuses;

  /// Selected booking statuses (empty = all statuses)
  /// Values: 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  @override
  @JsonKey()
  List<String> get statuses {
    if (_statuses is EqualUnmodifiableListView) return _statuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statuses);
  }

  /// Selected booking sources (empty = all sources)
  /// Values: 'widget', 'admin', 'booking_com', 'airbnb', 'other'
  final List<String> _sources;

  /// Selected booking sources (empty = all sources)
  /// Values: 'widget', 'admin', 'booking_com', 'airbnb', 'other'
  @override
  @JsonKey()
  List<String> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  /// Start date for filtering (check-in date range start)
  @override
  final DateTime? startDate;

  /// End date for filtering (check-in date range end)
  @override
  final DateTime? endDate;

  /// Guest name or email search query
  @override
  final String? guestSearchQuery;

  /// Booking ID search
  @override
  final String? bookingIdSearch;

  @override
  String toString() {
    return 'CalendarFilterOptions(propertyIds: $propertyIds, unitIds: $unitIds, statuses: $statuses, sources: $sources, startDate: $startDate, endDate: $endDate, guestSearchQuery: $guestSearchQuery, bookingIdSearch: $bookingIdSearch)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarFilterOptionsImpl &&
            const DeepCollectionEquality().equals(
              other._propertyIds,
              _propertyIds,
            ) &&
            const DeepCollectionEquality().equals(other._unitIds, _unitIds) &&
            const DeepCollectionEquality().equals(other._statuses, _statuses) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.guestSearchQuery, guestSearchQuery) ||
                other.guestSearchQuery == guestSearchQuery) &&
            (identical(other.bookingIdSearch, bookingIdSearch) ||
                other.bookingIdSearch == bookingIdSearch));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_propertyIds),
    const DeepCollectionEquality().hash(_unitIds),
    const DeepCollectionEquality().hash(_statuses),
    const DeepCollectionEquality().hash(_sources),
    startDate,
    endDate,
    guestSearchQuery,
    bookingIdSearch,
  );

  /// Create a copy of CalendarFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarFilterOptionsImplCopyWith<_$CalendarFilterOptionsImpl>
  get copyWith =>
      __$$CalendarFilterOptionsImplCopyWithImpl<_$CalendarFilterOptionsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarFilterOptionsImplToJson(this);
  }
}

abstract class _CalendarFilterOptions implements CalendarFilterOptions {
  const factory _CalendarFilterOptions({
    final List<String> propertyIds,
    final List<String> unitIds,
    final List<String> statuses,
    final List<String> sources,
    final DateTime? startDate,
    final DateTime? endDate,
    final String? guestSearchQuery,
    final String? bookingIdSearch,
  }) = _$CalendarFilterOptionsImpl;

  factory _CalendarFilterOptions.fromJson(Map<String, dynamic> json) =
      _$CalendarFilterOptionsImpl.fromJson;

  /// Selected property IDs (empty = all properties)
  @override
  List<String> get propertyIds;

  /// Selected unit IDs (empty = all units)
  @override
  List<String> get unitIds;

  /// Selected booking statuses (empty = all statuses)
  /// Values: 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  @override
  List<String> get statuses;

  /// Selected booking sources (empty = all sources)
  /// Values: 'widget', 'admin', 'booking_com', 'airbnb', 'other'
  @override
  List<String> get sources;

  /// Start date for filtering (check-in date range start)
  @override
  DateTime? get startDate;

  /// End date for filtering (check-in date range end)
  @override
  DateTime? get endDate;

  /// Guest name or email search query
  @override
  String? get guestSearchQuery;

  /// Booking ID search
  @override
  String? get bookingIdSearch;

  /// Create a copy of CalendarFilterOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarFilterOptionsImplCopyWith<_$CalendarFilterOptionsImpl>
  get copyWith => throw _privateConstructorUsedError;
}
