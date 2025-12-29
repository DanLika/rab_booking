// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preferences_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NotificationChannels _$NotificationChannelsFromJson(Map<String, dynamic> json) {
  return _NotificationChannels.fromJson(json);
}

/// @nodoc
mixin _$NotificationChannels {
  bool get email => throw _privateConstructorUsedError;
  bool get push => throw _privateConstructorUsedError;
  bool get sms => throw _privateConstructorUsedError;

  /// Serializes this NotificationChannels to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationChannels
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationChannelsCopyWith<NotificationChannels> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationChannelsCopyWith<$Res> {
  factory $NotificationChannelsCopyWith(
    NotificationChannels value,
    $Res Function(NotificationChannels) then,
  ) = _$NotificationChannelsCopyWithImpl<$Res, NotificationChannels>;
  @useResult
  $Res call({bool email, bool push, bool sms});
}

/// @nodoc
class _$NotificationChannelsCopyWithImpl<
  $Res,
  $Val extends NotificationChannels
>
    implements $NotificationChannelsCopyWith<$Res> {
  _$NotificationChannelsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationChannels
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? push = null, Object? sms = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as bool,
            push: null == push
                ? _value.push
                : push // ignore: cast_nullable_to_non_nullable
                      as bool,
            sms: null == sms
                ? _value.sms
                : sms // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationChannelsImplCopyWith<$Res>
    implements $NotificationChannelsCopyWith<$Res> {
  factory _$$NotificationChannelsImplCopyWith(
    _$NotificationChannelsImpl value,
    $Res Function(_$NotificationChannelsImpl) then,
  ) = __$$NotificationChannelsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool email, bool push, bool sms});
}

/// @nodoc
class __$$NotificationChannelsImplCopyWithImpl<$Res>
    extends _$NotificationChannelsCopyWithImpl<$Res, _$NotificationChannelsImpl>
    implements _$$NotificationChannelsImplCopyWith<$Res> {
  __$$NotificationChannelsImplCopyWithImpl(
    _$NotificationChannelsImpl _value,
    $Res Function(_$NotificationChannelsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationChannels
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? push = null, Object? sms = null}) {
    return _then(
      _$NotificationChannelsImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as bool,
        push: null == push
            ? _value.push
            : push // ignore: cast_nullable_to_non_nullable
                  as bool,
        sms: null == sms
            ? _value.sms
            : sms // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationChannelsImpl implements _NotificationChannels {
  const _$NotificationChannelsImpl({
    this.email = true,
    this.push = true,
    this.sms = false,
  });

  factory _$NotificationChannelsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationChannelsImplFromJson(json);

  @override
  @JsonKey()
  final bool email;
  @override
  @JsonKey()
  final bool push;
  @override
  @JsonKey()
  final bool sms;

  @override
  String toString() {
    return 'NotificationChannels(email: $email, push: $push, sms: $sms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationChannelsImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.push, push) || other.push == push) &&
            (identical(other.sms, sms) || other.sms == sms));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, push, sms);

  /// Create a copy of NotificationChannels
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationChannelsImplCopyWith<_$NotificationChannelsImpl>
  get copyWith =>
      __$$NotificationChannelsImplCopyWithImpl<_$NotificationChannelsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationChannelsImplToJson(this);
  }
}

abstract class _NotificationChannels implements NotificationChannels {
  const factory _NotificationChannels({
    final bool email,
    final bool push,
    final bool sms,
  }) = _$NotificationChannelsImpl;

  factory _NotificationChannels.fromJson(Map<String, dynamic> json) =
      _$NotificationChannelsImpl.fromJson;

  @override
  bool get email;
  @override
  bool get push;
  @override
  bool get sms;

  /// Create a copy of NotificationChannels
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationChannelsImplCopyWith<_$NotificationChannelsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

NotificationCategories _$NotificationCategoriesFromJson(
  Map<String, dynamic> json,
) {
  return _NotificationCategories.fromJson(json);
}

/// @nodoc
mixin _$NotificationCategories {
  NotificationChannels get bookings => throw _privateConstructorUsedError;
  NotificationChannels get payments => throw _privateConstructorUsedError;
  NotificationChannels get calendar => throw _privateConstructorUsedError;
  NotificationChannels get marketing => throw _privateConstructorUsedError;

  /// Serializes this NotificationCategories to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationCategoriesCopyWith<NotificationCategories> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCategoriesCopyWith<$Res> {
  factory $NotificationCategoriesCopyWith(
    NotificationCategories value,
    $Res Function(NotificationCategories) then,
  ) = _$NotificationCategoriesCopyWithImpl<$Res, NotificationCategories>;
  @useResult
  $Res call({
    NotificationChannels bookings,
    NotificationChannels payments,
    NotificationChannels calendar,
    NotificationChannels marketing,
  });

  $NotificationChannelsCopyWith<$Res> get bookings;
  $NotificationChannelsCopyWith<$Res> get payments;
  $NotificationChannelsCopyWith<$Res> get calendar;
  $NotificationChannelsCopyWith<$Res> get marketing;
}

/// @nodoc
class _$NotificationCategoriesCopyWithImpl<
  $Res,
  $Val extends NotificationCategories
>
    implements $NotificationCategoriesCopyWith<$Res> {
  _$NotificationCategoriesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookings = null,
    Object? payments = null,
    Object? calendar = null,
    Object? marketing = null,
  }) {
    return _then(
      _value.copyWith(
            bookings: null == bookings
                ? _value.bookings
                : bookings // ignore: cast_nullable_to_non_nullable
                      as NotificationChannels,
            payments: null == payments
                ? _value.payments
                : payments // ignore: cast_nullable_to_non_nullable
                      as NotificationChannels,
            calendar: null == calendar
                ? _value.calendar
                : calendar // ignore: cast_nullable_to_non_nullable
                      as NotificationChannels,
            marketing: null == marketing
                ? _value.marketing
                : marketing // ignore: cast_nullable_to_non_nullable
                      as NotificationChannels,
          )
          as $Val,
    );
  }

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationChannelsCopyWith<$Res> get bookings {
    return $NotificationChannelsCopyWith<$Res>(_value.bookings, (value) {
      return _then(_value.copyWith(bookings: value) as $Val);
    });
  }

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationChannelsCopyWith<$Res> get payments {
    return $NotificationChannelsCopyWith<$Res>(_value.payments, (value) {
      return _then(_value.copyWith(payments: value) as $Val);
    });
  }

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationChannelsCopyWith<$Res> get calendar {
    return $NotificationChannelsCopyWith<$Res>(_value.calendar, (value) {
      return _then(_value.copyWith(calendar: value) as $Val);
    });
  }

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationChannelsCopyWith<$Res> get marketing {
    return $NotificationChannelsCopyWith<$Res>(_value.marketing, (value) {
      return _then(_value.copyWith(marketing: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NotificationCategoriesImplCopyWith<$Res>
    implements $NotificationCategoriesCopyWith<$Res> {
  factory _$$NotificationCategoriesImplCopyWith(
    _$NotificationCategoriesImpl value,
    $Res Function(_$NotificationCategoriesImpl) then,
  ) = __$$NotificationCategoriesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    NotificationChannels bookings,
    NotificationChannels payments,
    NotificationChannels calendar,
    NotificationChannels marketing,
  });

  @override
  $NotificationChannelsCopyWith<$Res> get bookings;
  @override
  $NotificationChannelsCopyWith<$Res> get payments;
  @override
  $NotificationChannelsCopyWith<$Res> get calendar;
  @override
  $NotificationChannelsCopyWith<$Res> get marketing;
}

/// @nodoc
class __$$NotificationCategoriesImplCopyWithImpl<$Res>
    extends
        _$NotificationCategoriesCopyWithImpl<$Res, _$NotificationCategoriesImpl>
    implements _$$NotificationCategoriesImplCopyWith<$Res> {
  __$$NotificationCategoriesImplCopyWithImpl(
    _$NotificationCategoriesImpl _value,
    $Res Function(_$NotificationCategoriesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookings = null,
    Object? payments = null,
    Object? calendar = null,
    Object? marketing = null,
  }) {
    return _then(
      _$NotificationCategoriesImpl(
        bookings: null == bookings
            ? _value.bookings
            : bookings // ignore: cast_nullable_to_non_nullable
                  as NotificationChannels,
        payments: null == payments
            ? _value.payments
            : payments // ignore: cast_nullable_to_non_nullable
                  as NotificationChannels,
        calendar: null == calendar
            ? _value.calendar
            : calendar // ignore: cast_nullable_to_non_nullable
                  as NotificationChannels,
        marketing: null == marketing
            ? _value.marketing
            : marketing // ignore: cast_nullable_to_non_nullable
                  as NotificationChannels,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationCategoriesImpl implements _NotificationCategories {
  const _$NotificationCategoriesImpl({
    this.bookings = const NotificationChannels(),
    this.payments = const NotificationChannels(),
    this.calendar = const NotificationChannels(),
    this.marketing = const NotificationChannels(email: false, push: false),
  });

  factory _$NotificationCategoriesImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationCategoriesImplFromJson(json);

  @override
  @JsonKey()
  final NotificationChannels bookings;
  @override
  @JsonKey()
  final NotificationChannels payments;
  @override
  @JsonKey()
  final NotificationChannels calendar;
  @override
  @JsonKey()
  final NotificationChannels marketing;

  @override
  String toString() {
    return 'NotificationCategories(bookings: $bookings, payments: $payments, calendar: $calendar, marketing: $marketing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationCategoriesImpl &&
            (identical(other.bookings, bookings) ||
                other.bookings == bookings) &&
            (identical(other.payments, payments) ||
                other.payments == payments) &&
            (identical(other.calendar, calendar) ||
                other.calendar == calendar) &&
            (identical(other.marketing, marketing) ||
                other.marketing == marketing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, bookings, payments, calendar, marketing);

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationCategoriesImplCopyWith<_$NotificationCategoriesImpl>
  get copyWith =>
      __$$NotificationCategoriesImplCopyWithImpl<_$NotificationCategoriesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationCategoriesImplToJson(this);
  }
}

abstract class _NotificationCategories implements NotificationCategories {
  const factory _NotificationCategories({
    final NotificationChannels bookings,
    final NotificationChannels payments,
    final NotificationChannels calendar,
    final NotificationChannels marketing,
  }) = _$NotificationCategoriesImpl;

  factory _NotificationCategories.fromJson(Map<String, dynamic> json) =
      _$NotificationCategoriesImpl.fromJson;

  @override
  NotificationChannels get bookings;
  @override
  NotificationChannels get payments;
  @override
  NotificationChannels get calendar;
  @override
  NotificationChannels get marketing;

  /// Create a copy of NotificationCategories
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationCategoriesImplCopyWith<_$NotificationCategoriesImpl>
  get copyWith => throw _privateConstructorUsedError;
}

NotificationPreferences _$NotificationPreferencesFromJson(
  Map<String, dynamic> json,
) {
  return _NotificationPreferences.fromJson(json);
}

/// @nodoc
mixin _$NotificationPreferences {
  String get userId => throw _privateConstructorUsedError;
  bool get masterEnabled => throw _privateConstructorUsedError;
  NotificationCategories get categories => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this NotificationPreferences to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationPreferencesCopyWith<NotificationPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationPreferencesCopyWith<$Res> {
  factory $NotificationPreferencesCopyWith(
    NotificationPreferences value,
    $Res Function(NotificationPreferences) then,
  ) = _$NotificationPreferencesCopyWithImpl<$Res, NotificationPreferences>;
  @useResult
  $Res call({
    String userId,
    bool masterEnabled,
    NotificationCategories categories,
    DateTime? updatedAt,
  });

  $NotificationCategoriesCopyWith<$Res> get categories;
}

/// @nodoc
class _$NotificationPreferencesCopyWithImpl<
  $Res,
  $Val extends NotificationPreferences
>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? masterEnabled = null,
    Object? categories = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            masterEnabled: null == masterEnabled
                ? _value.masterEnabled
                : masterEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as NotificationCategories,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationCategoriesCopyWith<$Res> get categories {
    return $NotificationCategoriesCopyWith<$Res>(_value.categories, (value) {
      return _then(_value.copyWith(categories: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NotificationPreferencesImplCopyWith<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  factory _$$NotificationPreferencesImplCopyWith(
    _$NotificationPreferencesImpl value,
    $Res Function(_$NotificationPreferencesImpl) then,
  ) = __$$NotificationPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    bool masterEnabled,
    NotificationCategories categories,
    DateTime? updatedAt,
  });

  @override
  $NotificationCategoriesCopyWith<$Res> get categories;
}

/// @nodoc
class __$$NotificationPreferencesImplCopyWithImpl<$Res>
    extends
        _$NotificationPreferencesCopyWithImpl<
          $Res,
          _$NotificationPreferencesImpl
        >
    implements _$$NotificationPreferencesImplCopyWith<$Res> {
  __$$NotificationPreferencesImplCopyWithImpl(
    _$NotificationPreferencesImpl _value,
    $Res Function(_$NotificationPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? masterEnabled = null,
    Object? categories = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$NotificationPreferencesImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        masterEnabled: null == masterEnabled
            ? _value.masterEnabled
            : masterEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        categories: null == categories
            ? _value.categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as NotificationCategories,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationPreferencesImpl extends _NotificationPreferences {
  const _$NotificationPreferencesImpl({
    required this.userId,
    this.masterEnabled = true,
    this.categories = const NotificationCategories(),
    this.updatedAt,
  }) : super._();

  factory _$NotificationPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationPreferencesImplFromJson(json);

  @override
  final String userId;
  @override
  @JsonKey()
  final bool masterEnabled;
  @override
  @JsonKey()
  final NotificationCategories categories;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'NotificationPreferences(userId: $userId, masterEnabled: $masterEnabled, categories: $categories, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationPreferencesImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.masterEnabled, masterEnabled) ||
                other.masterEnabled == masterEnabled) &&
            (identical(other.categories, categories) ||
                other.categories == categories) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, masterEnabled, categories, updatedAt);

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationPreferencesImplCopyWith<_$NotificationPreferencesImpl>
  get copyWith =>
      __$$NotificationPreferencesImplCopyWithImpl<
        _$NotificationPreferencesImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationPreferencesImplToJson(this);
  }
}

abstract class _NotificationPreferences extends NotificationPreferences {
  const factory _NotificationPreferences({
    required final String userId,
    final bool masterEnabled,
    final NotificationCategories categories,
    final DateTime? updatedAt,
  }) = _$NotificationPreferencesImpl;
  const _NotificationPreferences._() : super._();

  factory _NotificationPreferences.fromJson(Map<String, dynamic> json) =
      _$NotificationPreferencesImpl.fromJson;

  @override
  String get userId;
  @override
  bool get masterEnabled;
  @override
  NotificationCategories get categories;
  @override
  DateTime? get updatedAt;

  /// Create a copy of NotificationPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationPreferencesImplCopyWith<_$NotificationPreferencesImpl>
  get copyWith => throw _privateConstructorUsedError;
}
