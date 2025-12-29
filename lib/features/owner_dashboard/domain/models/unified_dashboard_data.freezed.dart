// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_dashboard_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UnifiedDashboardData _$UnifiedDashboardDataFromJson(Map<String, dynamic> json) {
  return _UnifiedDashboardData.fromJson(json);
}

/// @nodoc
mixin _$UnifiedDashboardData {
  /// Total revenue in the selected period (EUR)
  double get revenue => throw _privateConstructorUsedError;

  /// Number of bookings in the selected period
  int get bookings => throw _privateConstructorUsedError;

  /// Upcoming check-ins in next 7 days (always 7 days, regardless of period)
  int get upcomingCheckIns => throw _privateConstructorUsedError;

  /// Occupancy rate for the selected period (0-100%)
  double get occupancyRate => throw _privateConstructorUsedError;

  /// Revenue data points for chart
  List<RevenueDataPoint> get revenueHistory =>
      throw _privateConstructorUsedError;

  /// Booking data points for chart
  List<BookingDataPoint> get bookingHistory =>
      throw _privateConstructorUsedError;

  /// Serializes this UnifiedDashboardData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedDashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedDashboardDataCopyWith<UnifiedDashboardData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedDashboardDataCopyWith<$Res> {
  factory $UnifiedDashboardDataCopyWith(
    UnifiedDashboardData value,
    $Res Function(UnifiedDashboardData) then,
  ) = _$UnifiedDashboardDataCopyWithImpl<$Res, UnifiedDashboardData>;
  @useResult
  $Res call({
    double revenue,
    int bookings,
    int upcomingCheckIns,
    double occupancyRate,
    List<RevenueDataPoint> revenueHistory,
    List<BookingDataPoint> bookingHistory,
  });
}

/// @nodoc
class _$UnifiedDashboardDataCopyWithImpl<
  $Res,
  $Val extends UnifiedDashboardData
>
    implements $UnifiedDashboardDataCopyWith<$Res> {
  _$UnifiedDashboardDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedDashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? revenue = null,
    Object? bookings = null,
    Object? upcomingCheckIns = null,
    Object? occupancyRate = null,
    Object? revenueHistory = null,
    Object? bookingHistory = null,
  }) {
    return _then(
      _value.copyWith(
            revenue: null == revenue
                ? _value.revenue
                : revenue // ignore: cast_nullable_to_non_nullable
                      as double,
            bookings: null == bookings
                ? _value.bookings
                : bookings // ignore: cast_nullable_to_non_nullable
                      as int,
            upcomingCheckIns: null == upcomingCheckIns
                ? _value.upcomingCheckIns
                : upcomingCheckIns // ignore: cast_nullable_to_non_nullable
                      as int,
            occupancyRate: null == occupancyRate
                ? _value.occupancyRate
                : occupancyRate // ignore: cast_nullable_to_non_nullable
                      as double,
            revenueHistory: null == revenueHistory
                ? _value.revenueHistory
                : revenueHistory // ignore: cast_nullable_to_non_nullable
                      as List<RevenueDataPoint>,
            bookingHistory: null == bookingHistory
                ? _value.bookingHistory
                : bookingHistory // ignore: cast_nullable_to_non_nullable
                      as List<BookingDataPoint>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnifiedDashboardDataImplCopyWith<$Res>
    implements $UnifiedDashboardDataCopyWith<$Res> {
  factory _$$UnifiedDashboardDataImplCopyWith(
    _$UnifiedDashboardDataImpl value,
    $Res Function(_$UnifiedDashboardDataImpl) then,
  ) = __$$UnifiedDashboardDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double revenue,
    int bookings,
    int upcomingCheckIns,
    double occupancyRate,
    List<RevenueDataPoint> revenueHistory,
    List<BookingDataPoint> bookingHistory,
  });
}

/// @nodoc
class __$$UnifiedDashboardDataImplCopyWithImpl<$Res>
    extends _$UnifiedDashboardDataCopyWithImpl<$Res, _$UnifiedDashboardDataImpl>
    implements _$$UnifiedDashboardDataImplCopyWith<$Res> {
  __$$UnifiedDashboardDataImplCopyWithImpl(
    _$UnifiedDashboardDataImpl _value,
    $Res Function(_$UnifiedDashboardDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnifiedDashboardData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? revenue = null,
    Object? bookings = null,
    Object? upcomingCheckIns = null,
    Object? occupancyRate = null,
    Object? revenueHistory = null,
    Object? bookingHistory = null,
  }) {
    return _then(
      _$UnifiedDashboardDataImpl(
        revenue: null == revenue
            ? _value.revenue
            : revenue // ignore: cast_nullable_to_non_nullable
                  as double,
        bookings: null == bookings
            ? _value.bookings
            : bookings // ignore: cast_nullable_to_non_nullable
                  as int,
        upcomingCheckIns: null == upcomingCheckIns
            ? _value.upcomingCheckIns
            : upcomingCheckIns // ignore: cast_nullable_to_non_nullable
                  as int,
        occupancyRate: null == occupancyRate
            ? _value.occupancyRate
            : occupancyRate // ignore: cast_nullable_to_non_nullable
                  as double,
        revenueHistory: null == revenueHistory
            ? _value._revenueHistory
            : revenueHistory // ignore: cast_nullable_to_non_nullable
                  as List<RevenueDataPoint>,
        bookingHistory: null == bookingHistory
            ? _value._bookingHistory
            : bookingHistory // ignore: cast_nullable_to_non_nullable
                  as List<BookingDataPoint>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnifiedDashboardDataImpl implements _UnifiedDashboardData {
  const _$UnifiedDashboardDataImpl({
    required this.revenue,
    required this.bookings,
    required this.upcomingCheckIns,
    required this.occupancyRate,
    required final List<RevenueDataPoint> revenueHistory,
    required final List<BookingDataPoint> bookingHistory,
  }) : _revenueHistory = revenueHistory,
       _bookingHistory = bookingHistory;

  factory _$UnifiedDashboardDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnifiedDashboardDataImplFromJson(json);

  /// Total revenue in the selected period (EUR)
  @override
  final double revenue;

  /// Number of bookings in the selected period
  @override
  final int bookings;

  /// Upcoming check-ins in next 7 days (always 7 days, regardless of period)
  @override
  final int upcomingCheckIns;

  /// Occupancy rate for the selected period (0-100%)
  @override
  final double occupancyRate;

  /// Revenue data points for chart
  final List<RevenueDataPoint> _revenueHistory;

  /// Revenue data points for chart
  @override
  List<RevenueDataPoint> get revenueHistory {
    if (_revenueHistory is EqualUnmodifiableListView) return _revenueHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_revenueHistory);
  }

  /// Booking data points for chart
  final List<BookingDataPoint> _bookingHistory;

  /// Booking data points for chart
  @override
  List<BookingDataPoint> get bookingHistory {
    if (_bookingHistory is EqualUnmodifiableListView) return _bookingHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookingHistory);
  }

  @override
  String toString() {
    return 'UnifiedDashboardData(revenue: $revenue, bookings: $bookings, upcomingCheckIns: $upcomingCheckIns, occupancyRate: $occupancyRate, revenueHistory: $revenueHistory, bookingHistory: $bookingHistory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedDashboardDataImpl &&
            (identical(other.revenue, revenue) || other.revenue == revenue) &&
            (identical(other.bookings, bookings) ||
                other.bookings == bookings) &&
            (identical(other.upcomingCheckIns, upcomingCheckIns) ||
                other.upcomingCheckIns == upcomingCheckIns) &&
            (identical(other.occupancyRate, occupancyRate) ||
                other.occupancyRate == occupancyRate) &&
            const DeepCollectionEquality().equals(
              other._revenueHistory,
              _revenueHistory,
            ) &&
            const DeepCollectionEquality().equals(
              other._bookingHistory,
              _bookingHistory,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    revenue,
    bookings,
    upcomingCheckIns,
    occupancyRate,
    const DeepCollectionEquality().hash(_revenueHistory),
    const DeepCollectionEquality().hash(_bookingHistory),
  );

  /// Create a copy of UnifiedDashboardData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedDashboardDataImplCopyWith<_$UnifiedDashboardDataImpl>
  get copyWith =>
      __$$UnifiedDashboardDataImplCopyWithImpl<_$UnifiedDashboardDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UnifiedDashboardDataImplToJson(this);
  }
}

abstract class _UnifiedDashboardData implements UnifiedDashboardData {
  const factory _UnifiedDashboardData({
    required final double revenue,
    required final int bookings,
    required final int upcomingCheckIns,
    required final double occupancyRate,
    required final List<RevenueDataPoint> revenueHistory,
    required final List<BookingDataPoint> bookingHistory,
  }) = _$UnifiedDashboardDataImpl;

  factory _UnifiedDashboardData.fromJson(Map<String, dynamic> json) =
      _$UnifiedDashboardDataImpl.fromJson;

  /// Total revenue in the selected period (EUR)
  @override
  double get revenue;

  /// Number of bookings in the selected period
  @override
  int get bookings;

  /// Upcoming check-ins in next 7 days (always 7 days, regardless of period)
  @override
  int get upcomingCheckIns;

  /// Occupancy rate for the selected period (0-100%)
  @override
  double get occupancyRate;

  /// Revenue data points for chart
  @override
  List<RevenueDataPoint> get revenueHistory;

  /// Booking data points for chart
  @override
  List<BookingDataPoint> get bookingHistory;

  /// Create a copy of UnifiedDashboardData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedDashboardDataImplCopyWith<_$UnifiedDashboardDataImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RevenueDataPoint _$RevenueDataPointFromJson(Map<String, dynamic> json) {
  return _RevenueDataPoint.fromJson(json);
}

/// @nodoc
mixin _$RevenueDataPoint {
  DateTime get date => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;

  /// Serializes this RevenueDataPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RevenueDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RevenueDataPointCopyWith<RevenueDataPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RevenueDataPointCopyWith<$Res> {
  factory $RevenueDataPointCopyWith(
    RevenueDataPoint value,
    $Res Function(RevenueDataPoint) then,
  ) = _$RevenueDataPointCopyWithImpl<$Res, RevenueDataPoint>;
  @useResult
  $Res call({DateTime date, double amount, String label});
}

/// @nodoc
class _$RevenueDataPointCopyWithImpl<$Res, $Val extends RevenueDataPoint>
    implements $RevenueDataPointCopyWith<$Res> {
  _$RevenueDataPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RevenueDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? amount = null,
    Object? label = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RevenueDataPointImplCopyWith<$Res>
    implements $RevenueDataPointCopyWith<$Res> {
  factory _$$RevenueDataPointImplCopyWith(
    _$RevenueDataPointImpl value,
    $Res Function(_$RevenueDataPointImpl) then,
  ) = __$$RevenueDataPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, double amount, String label});
}

/// @nodoc
class __$$RevenueDataPointImplCopyWithImpl<$Res>
    extends _$RevenueDataPointCopyWithImpl<$Res, _$RevenueDataPointImpl>
    implements _$$RevenueDataPointImplCopyWith<$Res> {
  __$$RevenueDataPointImplCopyWithImpl(
    _$RevenueDataPointImpl _value,
    $Res Function(_$RevenueDataPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RevenueDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? amount = null,
    Object? label = null,
  }) {
    return _then(
      _$RevenueDataPointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RevenueDataPointImpl implements _RevenueDataPoint {
  const _$RevenueDataPointImpl({
    required this.date,
    required this.amount,
    required this.label,
  });

  factory _$RevenueDataPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$RevenueDataPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double amount;
  @override
  final String label;

  @override
  String toString() {
    return 'RevenueDataPoint(date: $date, amount: $amount, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RevenueDataPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, amount, label);

  /// Create a copy of RevenueDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RevenueDataPointImplCopyWith<_$RevenueDataPointImpl> get copyWith =>
      __$$RevenueDataPointImplCopyWithImpl<_$RevenueDataPointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RevenueDataPointImplToJson(this);
  }
}

abstract class _RevenueDataPoint implements RevenueDataPoint {
  const factory _RevenueDataPoint({
    required final DateTime date,
    required final double amount,
    required final String label,
  }) = _$RevenueDataPointImpl;

  factory _RevenueDataPoint.fromJson(Map<String, dynamic> json) =
      _$RevenueDataPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get amount;
  @override
  String get label;

  /// Create a copy of RevenueDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RevenueDataPointImplCopyWith<_$RevenueDataPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BookingDataPoint _$BookingDataPointFromJson(Map<String, dynamic> json) {
  return _BookingDataPoint.fromJson(json);
}

/// @nodoc
mixin _$BookingDataPoint {
  DateTime get date => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;

  /// Serializes this BookingDataPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingDataPointCopyWith<BookingDataPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingDataPointCopyWith<$Res> {
  factory $BookingDataPointCopyWith(
    BookingDataPoint value,
    $Res Function(BookingDataPoint) then,
  ) = _$BookingDataPointCopyWithImpl<$Res, BookingDataPoint>;
  @useResult
  $Res call({DateTime date, int count, String label});
}

/// @nodoc
class _$BookingDataPointCopyWithImpl<$Res, $Val extends BookingDataPoint>
    implements $BookingDataPointCopyWith<$Res> {
  _$BookingDataPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? count = null, Object? label = null}) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            count: null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as int,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookingDataPointImplCopyWith<$Res>
    implements $BookingDataPointCopyWith<$Res> {
  factory _$$BookingDataPointImplCopyWith(
    _$BookingDataPointImpl value,
    $Res Function(_$BookingDataPointImpl) then,
  ) = __$$BookingDataPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, int count, String label});
}

/// @nodoc
class __$$BookingDataPointImplCopyWithImpl<$Res>
    extends _$BookingDataPointCopyWithImpl<$Res, _$BookingDataPointImpl>
    implements _$$BookingDataPointImplCopyWith<$Res> {
  __$$BookingDataPointImplCopyWithImpl(
    _$BookingDataPointImpl _value,
    $Res Function(_$BookingDataPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BookingDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? count = null, Object? label = null}) {
    return _then(
      _$BookingDataPointImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        count: null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingDataPointImpl implements _BookingDataPoint {
  const _$BookingDataPointImpl({
    required this.date,
    required this.count,
    required this.label,
  });

  factory _$BookingDataPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingDataPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final int count;
  @override
  final String label;

  @override
  String toString() {
    return 'BookingDataPoint(date: $date, count: $count, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingDataPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, count, label);

  /// Create a copy of BookingDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingDataPointImplCopyWith<_$BookingDataPointImpl> get copyWith =>
      __$$BookingDataPointImplCopyWithImpl<_$BookingDataPointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingDataPointImplToJson(this);
  }
}

abstract class _BookingDataPoint implements BookingDataPoint {
  const factory _BookingDataPoint({
    required final DateTime date,
    required final int count,
    required final String label,
  }) = _$BookingDataPointImpl;

  factory _BookingDataPoint.fromJson(Map<String, dynamic> json) =
      _$BookingDataPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  int get count;
  @override
  String get label;

  /// Create a copy of BookingDataPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingDataPointImplCopyWith<_$BookingDataPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DateRangeFilter _$DateRangeFilterFromJson(Map<String, dynamic> json) {
  return _DateRangeFilter.fromJson(json);
}

/// @nodoc
mixin _$DateRangeFilter {
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  String get preset => throw _privateConstructorUsedError;

  /// Serializes this DateRangeFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DateRangeFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DateRangeFilterCopyWith<DateRangeFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DateRangeFilterCopyWith<$Res> {
  factory $DateRangeFilterCopyWith(
    DateRangeFilter value,
    $Res Function(DateRangeFilter) then,
  ) = _$DateRangeFilterCopyWithImpl<$Res, DateRangeFilter>;
  @useResult
  $Res call({DateTime startDate, DateTime endDate, String preset});
}

/// @nodoc
class _$DateRangeFilterCopyWithImpl<$Res, $Val extends DateRangeFilter>
    implements $DateRangeFilterCopyWith<$Res> {
  _$DateRangeFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DateRangeFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? endDate = null,
    Object? preset = null,
  }) {
    return _then(
      _value.copyWith(
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            preset: null == preset
                ? _value.preset
                : preset // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DateRangeFilterImplCopyWith<$Res>
    implements $DateRangeFilterCopyWith<$Res> {
  factory _$$DateRangeFilterImplCopyWith(
    _$DateRangeFilterImpl value,
    $Res Function(_$DateRangeFilterImpl) then,
  ) = __$$DateRangeFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime startDate, DateTime endDate, String preset});
}

/// @nodoc
class __$$DateRangeFilterImplCopyWithImpl<$Res>
    extends _$DateRangeFilterCopyWithImpl<$Res, _$DateRangeFilterImpl>
    implements _$$DateRangeFilterImplCopyWith<$Res> {
  __$$DateRangeFilterImplCopyWithImpl(
    _$DateRangeFilterImpl _value,
    $Res Function(_$DateRangeFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DateRangeFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? endDate = null,
    Object? preset = null,
  }) {
    return _then(
      _$DateRangeFilterImpl(
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        preset: null == preset
            ? _value.preset
            : preset // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DateRangeFilterImpl implements _DateRangeFilter {
  const _$DateRangeFilterImpl({
    required this.startDate,
    required this.endDate,
    this.preset = 'last7',
  });

  factory _$DateRangeFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$DateRangeFilterImplFromJson(json);

  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  @JsonKey()
  final String preset;

  @override
  String toString() {
    return 'DateRangeFilter(startDate: $startDate, endDate: $endDate, preset: $preset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DateRangeFilterImpl &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.preset, preset) || other.preset == preset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startDate, endDate, preset);

  /// Create a copy of DateRangeFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DateRangeFilterImplCopyWith<_$DateRangeFilterImpl> get copyWith =>
      __$$DateRangeFilterImplCopyWithImpl<_$DateRangeFilterImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DateRangeFilterImplToJson(this);
  }
}

abstract class _DateRangeFilter implements DateRangeFilter {
  const factory _DateRangeFilter({
    required final DateTime startDate,
    required final DateTime endDate,
    final String preset,
  }) = _$DateRangeFilterImpl;

  factory _DateRangeFilter.fromJson(Map<String, dynamic> json) =
      _$DateRangeFilterImpl.fromJson;

  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  String get preset;

  /// Create a copy of DateRangeFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DateRangeFilterImplCopyWith<_$DateRangeFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
