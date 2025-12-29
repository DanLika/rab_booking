// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_wizard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UnitWizardDraft _$UnitWizardDraftFromJson(Map<String, dynamic> json) {
  return _UnitWizardDraft.fromJson(json);
}

/// @nodoc
mixin _$UnitWizardDraft {
  // Meta
  String? get unitId =>
      throw _privateConstructorUsedError; // null = new unit, non-null = edit existing
  int get currentStep => throw _privateConstructorUsedError; // 1-8
  Map<int, bool> get completedSteps =>
      throw _privateConstructorUsedError; // {1: true, 2: true, ...}
  Map<int, bool> get skippedSteps =>
      throw _privateConstructorUsedError; // {5: true, 7: true}
  // Step 1: Basic Info (REQUIRED)
  String? get name => throw _privateConstructorUsedError;
  String? get propertyId => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get slug =>
      throw _privateConstructorUsedError; // Auto-generated from name
  // Step 2: Capacity & Space (REQUIRED)
  int? get bedrooms => throw _privateConstructorUsedError;
  int? get bathrooms => throw _privateConstructorUsedError;
  int? get maxGuests => throw _privateConstructorUsedError;
  double? get areaSqm =>
      throw _privateConstructorUsedError; // Step 3: Pricing (REQUIRED)
  double? get pricePerNight => throw _privateConstructorUsedError;
  double? get weekendBasePrice =>
      throw _privateConstructorUsedError; // Weekend price (Fri-Sat nights by default)
  List<int> get weekendDays =>
      throw _privateConstructorUsedError; // Days considered weekend (1=Mon...7=Sun) - Fri=5, Sat=6 for hotel nights
  int? get minStayNights => throw _privateConstructorUsedError;
  int? get maxStayNights =>
      throw _privateConstructorUsedError; // Maximum nights per booking (null = no limit)
  List<Map<String, dynamic>> get seasons =>
      throw _privateConstructorUsedError; // Seasonal pricing (simplified)
  // Step 4: Availability (REQUIRED)
  bool get availableYearRound => throw _privateConstructorUsedError;
  DateTime? get seasonStartDate => throw _privateConstructorUsedError;
  DateTime? get seasonEndDate => throw _privateConstructorUsedError;
  List<DateTime> get blockedDates =>
      throw _privateConstructorUsedError; // Step 5: Photos (RECOMMENDED)
  List<String> get images =>
      throw _privateConstructorUsedError; // URLs after upload
  String? get coverImageUrl =>
      throw _privateConstructorUsedError; // First image by default
  // Step 6: Widget Setup (RECOMMENDED)
  String? get widgetMode =>
      throw _privateConstructorUsedError; // 'calendarOnly', 'bookingInstant', 'bookingPending'
  String? get widgetTheme =>
      throw _privateConstructorUsedError; // 'minimalist', 'modern', 'luxury'
  Map<String, dynamic>? get widgetSettings =>
      throw _privateConstructorUsedError; // Full widget_settings data
  // Step 7: Advanced Options (OPTIONAL)
  Map<String, dynamic>? get icalConfig => throw _privateConstructorUsedError;
  Map<String, dynamic>? get emailConfig => throw _privateConstructorUsedError;
  Map<String, dynamic>? get taxLegalConfig =>
      throw _privateConstructorUsedError; // Step 8: Review & Publish (FINAL)
  bool get isPublished =>
      throw _privateConstructorUsedError; // false = draft, true = active unit
  // Timestamps
  DateTime? get lastSaved => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this UnitWizardDraft to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnitWizardDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnitWizardDraftCopyWith<UnitWizardDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnitWizardDraftCopyWith<$Res> {
  factory $UnitWizardDraftCopyWith(
    UnitWizardDraft value,
    $Res Function(UnitWizardDraft) then,
  ) = _$UnitWizardDraftCopyWithImpl<$Res, UnitWizardDraft>;
  @useResult
  $Res call({
    String? unitId,
    int currentStep,
    Map<int, bool> completedSteps,
    Map<int, bool> skippedSteps,
    String? name,
    String? propertyId,
    String? description,
    String? slug,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    double? areaSqm,
    double? pricePerNight,
    double? weekendBasePrice,
    List<int> weekendDays,
    int? minStayNights,
    int? maxStayNights,
    List<Map<String, dynamic>> seasons,
    bool availableYearRound,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    List<DateTime> blockedDates,
    List<String> images,
    String? coverImageUrl,
    String? widgetMode,
    String? widgetTheme,
    Map<String, dynamic>? widgetSettings,
    Map<String, dynamic>? icalConfig,
    Map<String, dynamic>? emailConfig,
    Map<String, dynamic>? taxLegalConfig,
    bool isPublished,
    DateTime? lastSaved,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$UnitWizardDraftCopyWithImpl<$Res, $Val extends UnitWizardDraft>
    implements $UnitWizardDraftCopyWith<$Res> {
  _$UnitWizardDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnitWizardDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unitId = freezed,
    Object? currentStep = null,
    Object? completedSteps = null,
    Object? skippedSteps = null,
    Object? name = freezed,
    Object? propertyId = freezed,
    Object? description = freezed,
    Object? slug = freezed,
    Object? bedrooms = freezed,
    Object? bathrooms = freezed,
    Object? maxGuests = freezed,
    Object? areaSqm = freezed,
    Object? pricePerNight = freezed,
    Object? weekendBasePrice = freezed,
    Object? weekendDays = null,
    Object? minStayNights = freezed,
    Object? maxStayNights = freezed,
    Object? seasons = null,
    Object? availableYearRound = null,
    Object? seasonStartDate = freezed,
    Object? seasonEndDate = freezed,
    Object? blockedDates = null,
    Object? images = null,
    Object? coverImageUrl = freezed,
    Object? widgetMode = freezed,
    Object? widgetTheme = freezed,
    Object? widgetSettings = freezed,
    Object? icalConfig = freezed,
    Object? emailConfig = freezed,
    Object? taxLegalConfig = freezed,
    Object? isPublished = null,
    Object? lastSaved = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            unitId: freezed == unitId
                ? _value.unitId
                : unitId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentStep: null == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as int,
            completedSteps: null == completedSteps
                ? _value.completedSteps
                : completedSteps // ignore: cast_nullable_to_non_nullable
                      as Map<int, bool>,
            skippedSteps: null == skippedSteps
                ? _value.skippedSteps
                : skippedSteps // ignore: cast_nullable_to_non_nullable
                      as Map<int, bool>,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            propertyId: freezed == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            bedrooms: freezed == bedrooms
                ? _value.bedrooms
                : bedrooms // ignore: cast_nullable_to_non_nullable
                      as int?,
            bathrooms: freezed == bathrooms
                ? _value.bathrooms
                : bathrooms // ignore: cast_nullable_to_non_nullable
                      as int?,
            maxGuests: freezed == maxGuests
                ? _value.maxGuests
                : maxGuests // ignore: cast_nullable_to_non_nullable
                      as int?,
            areaSqm: freezed == areaSqm
                ? _value.areaSqm
                : areaSqm // ignore: cast_nullable_to_non_nullable
                      as double?,
            pricePerNight: freezed == pricePerNight
                ? _value.pricePerNight
                : pricePerNight // ignore: cast_nullable_to_non_nullable
                      as double?,
            weekendBasePrice: freezed == weekendBasePrice
                ? _value.weekendBasePrice
                : weekendBasePrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            weekendDays: null == weekendDays
                ? _value.weekendDays
                : weekendDays // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            minStayNights: freezed == minStayNights
                ? _value.minStayNights
                : minStayNights // ignore: cast_nullable_to_non_nullable
                      as int?,
            maxStayNights: freezed == maxStayNights
                ? _value.maxStayNights
                : maxStayNights // ignore: cast_nullable_to_non_nullable
                      as int?,
            seasons: null == seasons
                ? _value.seasons
                : seasons // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            availableYearRound: null == availableYearRound
                ? _value.availableYearRound
                : availableYearRound // ignore: cast_nullable_to_non_nullable
                      as bool,
            seasonStartDate: freezed == seasonStartDate
                ? _value.seasonStartDate
                : seasonStartDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            seasonEndDate: freezed == seasonEndDate
                ? _value.seasonEndDate
                : seasonEndDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            blockedDates: null == blockedDates
                ? _value.blockedDates
                : blockedDates // ignore: cast_nullable_to_non_nullable
                      as List<DateTime>,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            coverImageUrl: freezed == coverImageUrl
                ? _value.coverImageUrl
                : coverImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            widgetMode: freezed == widgetMode
                ? _value.widgetMode
                : widgetMode // ignore: cast_nullable_to_non_nullable
                      as String?,
            widgetTheme: freezed == widgetTheme
                ? _value.widgetTheme
                : widgetTheme // ignore: cast_nullable_to_non_nullable
                      as String?,
            widgetSettings: freezed == widgetSettings
                ? _value.widgetSettings
                : widgetSettings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            icalConfig: freezed == icalConfig
                ? _value.icalConfig
                : icalConfig // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            emailConfig: freezed == emailConfig
                ? _value.emailConfig
                : emailConfig // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            taxLegalConfig: freezed == taxLegalConfig
                ? _value.taxLegalConfig
                : taxLegalConfig // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            isPublished: null == isPublished
                ? _value.isPublished
                : isPublished // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastSaved: freezed == lastSaved
                ? _value.lastSaved
                : lastSaved // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnitWizardDraftImplCopyWith<$Res>
    implements $UnitWizardDraftCopyWith<$Res> {
  factory _$$UnitWizardDraftImplCopyWith(
    _$UnitWizardDraftImpl value,
    $Res Function(_$UnitWizardDraftImpl) then,
  ) = __$$UnitWizardDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? unitId,
    int currentStep,
    Map<int, bool> completedSteps,
    Map<int, bool> skippedSteps,
    String? name,
    String? propertyId,
    String? description,
    String? slug,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    double? areaSqm,
    double? pricePerNight,
    double? weekendBasePrice,
    List<int> weekendDays,
    int? minStayNights,
    int? maxStayNights,
    List<Map<String, dynamic>> seasons,
    bool availableYearRound,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    List<DateTime> blockedDates,
    List<String> images,
    String? coverImageUrl,
    String? widgetMode,
    String? widgetTheme,
    Map<String, dynamic>? widgetSettings,
    Map<String, dynamic>? icalConfig,
    Map<String, dynamic>? emailConfig,
    Map<String, dynamic>? taxLegalConfig,
    bool isPublished,
    DateTime? lastSaved,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$UnitWizardDraftImplCopyWithImpl<$Res>
    extends _$UnitWizardDraftCopyWithImpl<$Res, _$UnitWizardDraftImpl>
    implements _$$UnitWizardDraftImplCopyWith<$Res> {
  __$$UnitWizardDraftImplCopyWithImpl(
    _$UnitWizardDraftImpl _value,
    $Res Function(_$UnitWizardDraftImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UnitWizardDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unitId = freezed,
    Object? currentStep = null,
    Object? completedSteps = null,
    Object? skippedSteps = null,
    Object? name = freezed,
    Object? propertyId = freezed,
    Object? description = freezed,
    Object? slug = freezed,
    Object? bedrooms = freezed,
    Object? bathrooms = freezed,
    Object? maxGuests = freezed,
    Object? areaSqm = freezed,
    Object? pricePerNight = freezed,
    Object? weekendBasePrice = freezed,
    Object? weekendDays = null,
    Object? minStayNights = freezed,
    Object? maxStayNights = freezed,
    Object? seasons = null,
    Object? availableYearRound = null,
    Object? seasonStartDate = freezed,
    Object? seasonEndDate = freezed,
    Object? blockedDates = null,
    Object? images = null,
    Object? coverImageUrl = freezed,
    Object? widgetMode = freezed,
    Object? widgetTheme = freezed,
    Object? widgetSettings = freezed,
    Object? icalConfig = freezed,
    Object? emailConfig = freezed,
    Object? taxLegalConfig = freezed,
    Object? isPublished = null,
    Object? lastSaved = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$UnitWizardDraftImpl(
        unitId: freezed == unitId
            ? _value.unitId
            : unitId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentStep: null == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as int,
        completedSteps: null == completedSteps
            ? _value._completedSteps
            : completedSteps // ignore: cast_nullable_to_non_nullable
                  as Map<int, bool>,
        skippedSteps: null == skippedSteps
            ? _value._skippedSteps
            : skippedSteps // ignore: cast_nullable_to_non_nullable
                  as Map<int, bool>,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        propertyId: freezed == propertyId
            ? _value.propertyId
            : propertyId // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        bedrooms: freezed == bedrooms
            ? _value.bedrooms
            : bedrooms // ignore: cast_nullable_to_non_nullable
                  as int?,
        bathrooms: freezed == bathrooms
            ? _value.bathrooms
            : bathrooms // ignore: cast_nullable_to_non_nullable
                  as int?,
        maxGuests: freezed == maxGuests
            ? _value.maxGuests
            : maxGuests // ignore: cast_nullable_to_non_nullable
                  as int?,
        areaSqm: freezed == areaSqm
            ? _value.areaSqm
            : areaSqm // ignore: cast_nullable_to_non_nullable
                  as double?,
        pricePerNight: freezed == pricePerNight
            ? _value.pricePerNight
            : pricePerNight // ignore: cast_nullable_to_non_nullable
                  as double?,
        weekendBasePrice: freezed == weekendBasePrice
            ? _value.weekendBasePrice
            : weekendBasePrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        weekendDays: null == weekendDays
            ? _value._weekendDays
            : weekendDays // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        minStayNights: freezed == minStayNights
            ? _value.minStayNights
            : minStayNights // ignore: cast_nullable_to_non_nullable
                  as int?,
        maxStayNights: freezed == maxStayNights
            ? _value.maxStayNights
            : maxStayNights // ignore: cast_nullable_to_non_nullable
                  as int?,
        seasons: null == seasons
            ? _value._seasons
            : seasons // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        availableYearRound: null == availableYearRound
            ? _value.availableYearRound
            : availableYearRound // ignore: cast_nullable_to_non_nullable
                  as bool,
        seasonStartDate: freezed == seasonStartDate
            ? _value.seasonStartDate
            : seasonStartDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        seasonEndDate: freezed == seasonEndDate
            ? _value.seasonEndDate
            : seasonEndDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        blockedDates: null == blockedDates
            ? _value._blockedDates
            : blockedDates // ignore: cast_nullable_to_non_nullable
                  as List<DateTime>,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        coverImageUrl: freezed == coverImageUrl
            ? _value.coverImageUrl
            : coverImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        widgetMode: freezed == widgetMode
            ? _value.widgetMode
            : widgetMode // ignore: cast_nullable_to_non_nullable
                  as String?,
        widgetTheme: freezed == widgetTheme
            ? _value.widgetTheme
            : widgetTheme // ignore: cast_nullable_to_non_nullable
                  as String?,
        widgetSettings: freezed == widgetSettings
            ? _value._widgetSettings
            : widgetSettings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        icalConfig: freezed == icalConfig
            ? _value._icalConfig
            : icalConfig // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        emailConfig: freezed == emailConfig
            ? _value._emailConfig
            : emailConfig // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        taxLegalConfig: freezed == taxLegalConfig
            ? _value._taxLegalConfig
            : taxLegalConfig // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        isPublished: null == isPublished
            ? _value.isPublished
            : isPublished // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastSaved: freezed == lastSaved
            ? _value.lastSaved
            : lastSaved // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnitWizardDraftImpl implements _UnitWizardDraft {
  const _$UnitWizardDraftImpl({
    this.unitId,
    this.currentStep = 1,
    final Map<int, bool> completedSteps = const {},
    final Map<int, bool> skippedSteps = const {},
    this.name,
    this.propertyId,
    this.description,
    this.slug,
    this.bedrooms,
    this.bathrooms,
    this.maxGuests,
    this.areaSqm,
    this.pricePerNight,
    this.weekendBasePrice,
    final List<int> weekendDays = const [5, 6],
    this.minStayNights,
    this.maxStayNights,
    final List<Map<String, dynamic>> seasons = const [],
    this.availableYearRound = true,
    this.seasonStartDate,
    this.seasonEndDate,
    final List<DateTime> blockedDates = const [],
    final List<String> images = const [],
    this.coverImageUrl,
    this.widgetMode,
    this.widgetTheme,
    final Map<String, dynamic>? widgetSettings,
    final Map<String, dynamic>? icalConfig,
    final Map<String, dynamic>? emailConfig,
    final Map<String, dynamic>? taxLegalConfig,
    this.isPublished = false,
    this.lastSaved,
    this.createdAt,
  }) : _completedSteps = completedSteps,
       _skippedSteps = skippedSteps,
       _weekendDays = weekendDays,
       _seasons = seasons,
       _blockedDates = blockedDates,
       _images = images,
       _widgetSettings = widgetSettings,
       _icalConfig = icalConfig,
       _emailConfig = emailConfig,
       _taxLegalConfig = taxLegalConfig;

  factory _$UnitWizardDraftImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnitWizardDraftImplFromJson(json);

  // Meta
  @override
  final String? unitId;
  // null = new unit, non-null = edit existing
  @override
  @JsonKey()
  final int currentStep;
  // 1-8
  final Map<int, bool> _completedSteps;
  // 1-8
  @override
  @JsonKey()
  Map<int, bool> get completedSteps {
    if (_completedSteps is EqualUnmodifiableMapView) return _completedSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_completedSteps);
  }

  // {1: true, 2: true, ...}
  final Map<int, bool> _skippedSteps;
  // {1: true, 2: true, ...}
  @override
  @JsonKey()
  Map<int, bool> get skippedSteps {
    if (_skippedSteps is EqualUnmodifiableMapView) return _skippedSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_skippedSteps);
  }

  // {5: true, 7: true}
  // Step 1: Basic Info (REQUIRED)
  @override
  final String? name;
  @override
  final String? propertyId;
  @override
  final String? description;
  @override
  final String? slug;
  // Auto-generated from name
  // Step 2: Capacity & Space (REQUIRED)
  @override
  final int? bedrooms;
  @override
  final int? bathrooms;
  @override
  final int? maxGuests;
  @override
  final double? areaSqm;
  // Step 3: Pricing (REQUIRED)
  @override
  final double? pricePerNight;
  @override
  final double? weekendBasePrice;
  // Weekend price (Fri-Sat nights by default)
  final List<int> _weekendDays;
  // Weekend price (Fri-Sat nights by default)
  @override
  @JsonKey()
  List<int> get weekendDays {
    if (_weekendDays is EqualUnmodifiableListView) return _weekendDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weekendDays);
  }

  // Days considered weekend (1=Mon...7=Sun) - Fri=5, Sat=6 for hotel nights
  @override
  final int? minStayNights;
  @override
  final int? maxStayNights;
  // Maximum nights per booking (null = no limit)
  final List<Map<String, dynamic>> _seasons;
  // Maximum nights per booking (null = no limit)
  @override
  @JsonKey()
  List<Map<String, dynamic>> get seasons {
    if (_seasons is EqualUnmodifiableListView) return _seasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seasons);
  }

  // Seasonal pricing (simplified)
  // Step 4: Availability (REQUIRED)
  @override
  @JsonKey()
  final bool availableYearRound;
  @override
  final DateTime? seasonStartDate;
  @override
  final DateTime? seasonEndDate;
  final List<DateTime> _blockedDates;
  @override
  @JsonKey()
  List<DateTime> get blockedDates {
    if (_blockedDates is EqualUnmodifiableListView) return _blockedDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blockedDates);
  }

  // Step 5: Photos (RECOMMENDED)
  final List<String> _images;
  // Step 5: Photos (RECOMMENDED)
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  // URLs after upload
  @override
  final String? coverImageUrl;
  // First image by default
  // Step 6: Widget Setup (RECOMMENDED)
  @override
  final String? widgetMode;
  // 'calendarOnly', 'bookingInstant', 'bookingPending'
  @override
  final String? widgetTheme;
  // 'minimalist', 'modern', 'luxury'
  final Map<String, dynamic>? _widgetSettings;
  // 'minimalist', 'modern', 'luxury'
  @override
  Map<String, dynamic>? get widgetSettings {
    final value = _widgetSettings;
    if (value == null) return null;
    if (_widgetSettings is EqualUnmodifiableMapView) return _widgetSettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // Full widget_settings data
  // Step 7: Advanced Options (OPTIONAL)
  final Map<String, dynamic>? _icalConfig;
  // Full widget_settings data
  // Step 7: Advanced Options (OPTIONAL)
  @override
  Map<String, dynamic>? get icalConfig {
    final value = _icalConfig;
    if (value == null) return null;
    if (_icalConfig is EqualUnmodifiableMapView) return _icalConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _emailConfig;
  @override
  Map<String, dynamic>? get emailConfig {
    final value = _emailConfig;
    if (value == null) return null;
    if (_emailConfig is EqualUnmodifiableMapView) return _emailConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _taxLegalConfig;
  @override
  Map<String, dynamic>? get taxLegalConfig {
    final value = _taxLegalConfig;
    if (value == null) return null;
    if (_taxLegalConfig is EqualUnmodifiableMapView) return _taxLegalConfig;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // Step 8: Review & Publish (FINAL)
  @override
  @JsonKey()
  final bool isPublished;
  // false = draft, true = active unit
  // Timestamps
  @override
  final DateTime? lastSaved;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'UnitWizardDraft(unitId: $unitId, currentStep: $currentStep, completedSteps: $completedSteps, skippedSteps: $skippedSteps, name: $name, propertyId: $propertyId, description: $description, slug: $slug, bedrooms: $bedrooms, bathrooms: $bathrooms, maxGuests: $maxGuests, areaSqm: $areaSqm, pricePerNight: $pricePerNight, weekendBasePrice: $weekendBasePrice, weekendDays: $weekendDays, minStayNights: $minStayNights, maxStayNights: $maxStayNights, seasons: $seasons, availableYearRound: $availableYearRound, seasonStartDate: $seasonStartDate, seasonEndDate: $seasonEndDate, blockedDates: $blockedDates, images: $images, coverImageUrl: $coverImageUrl, widgetMode: $widgetMode, widgetTheme: $widgetTheme, widgetSettings: $widgetSettings, icalConfig: $icalConfig, emailConfig: $emailConfig, taxLegalConfig: $taxLegalConfig, isPublished: $isPublished, lastSaved: $lastSaved, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnitWizardDraftImpl &&
            (identical(other.unitId, unitId) || other.unitId == unitId) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            const DeepCollectionEquality().equals(
              other._completedSteps,
              _completedSteps,
            ) &&
            const DeepCollectionEquality().equals(
              other._skippedSteps,
              _skippedSteps,
            ) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.bedrooms, bedrooms) ||
                other.bedrooms == bedrooms) &&
            (identical(other.bathrooms, bathrooms) ||
                other.bathrooms == bathrooms) &&
            (identical(other.maxGuests, maxGuests) ||
                other.maxGuests == maxGuests) &&
            (identical(other.areaSqm, areaSqm) || other.areaSqm == areaSqm) &&
            (identical(other.pricePerNight, pricePerNight) ||
                other.pricePerNight == pricePerNight) &&
            (identical(other.weekendBasePrice, weekendBasePrice) ||
                other.weekendBasePrice == weekendBasePrice) &&
            const DeepCollectionEquality().equals(
              other._weekendDays,
              _weekendDays,
            ) &&
            (identical(other.minStayNights, minStayNights) ||
                other.minStayNights == minStayNights) &&
            (identical(other.maxStayNights, maxStayNights) ||
                other.maxStayNights == maxStayNights) &&
            const DeepCollectionEquality().equals(other._seasons, _seasons) &&
            (identical(other.availableYearRound, availableYearRound) ||
                other.availableYearRound == availableYearRound) &&
            (identical(other.seasonStartDate, seasonStartDate) ||
                other.seasonStartDate == seasonStartDate) &&
            (identical(other.seasonEndDate, seasonEndDate) ||
                other.seasonEndDate == seasonEndDate) &&
            const DeepCollectionEquality().equals(
              other._blockedDates,
              _blockedDates,
            ) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.coverImageUrl, coverImageUrl) ||
                other.coverImageUrl == coverImageUrl) &&
            (identical(other.widgetMode, widgetMode) ||
                other.widgetMode == widgetMode) &&
            (identical(other.widgetTheme, widgetTheme) ||
                other.widgetTheme == widgetTheme) &&
            const DeepCollectionEquality().equals(
              other._widgetSettings,
              _widgetSettings,
            ) &&
            const DeepCollectionEquality().equals(
              other._icalConfig,
              _icalConfig,
            ) &&
            const DeepCollectionEquality().equals(
              other._emailConfig,
              _emailConfig,
            ) &&
            const DeepCollectionEquality().equals(
              other._taxLegalConfig,
              _taxLegalConfig,
            ) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.lastSaved, lastSaved) ||
                other.lastSaved == lastSaved) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    unitId,
    currentStep,
    const DeepCollectionEquality().hash(_completedSteps),
    const DeepCollectionEquality().hash(_skippedSteps),
    name,
    propertyId,
    description,
    slug,
    bedrooms,
    bathrooms,
    maxGuests,
    areaSqm,
    pricePerNight,
    weekendBasePrice,
    const DeepCollectionEquality().hash(_weekendDays),
    minStayNights,
    maxStayNights,
    const DeepCollectionEquality().hash(_seasons),
    availableYearRound,
    seasonStartDate,
    seasonEndDate,
    const DeepCollectionEquality().hash(_blockedDates),
    const DeepCollectionEquality().hash(_images),
    coverImageUrl,
    widgetMode,
    widgetTheme,
    const DeepCollectionEquality().hash(_widgetSettings),
    const DeepCollectionEquality().hash(_icalConfig),
    const DeepCollectionEquality().hash(_emailConfig),
    const DeepCollectionEquality().hash(_taxLegalConfig),
    isPublished,
    lastSaved,
    createdAt,
  ]);

  /// Create a copy of UnitWizardDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnitWizardDraftImplCopyWith<_$UnitWizardDraftImpl> get copyWith =>
      __$$UnitWizardDraftImplCopyWithImpl<_$UnitWizardDraftImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UnitWizardDraftImplToJson(this);
  }
}

abstract class _UnitWizardDraft implements UnitWizardDraft {
  const factory _UnitWizardDraft({
    final String? unitId,
    final int currentStep,
    final Map<int, bool> completedSteps,
    final Map<int, bool> skippedSteps,
    final String? name,
    final String? propertyId,
    final String? description,
    final String? slug,
    final int? bedrooms,
    final int? bathrooms,
    final int? maxGuests,
    final double? areaSqm,
    final double? pricePerNight,
    final double? weekendBasePrice,
    final List<int> weekendDays,
    final int? minStayNights,
    final int? maxStayNights,
    final List<Map<String, dynamic>> seasons,
    final bool availableYearRound,
    final DateTime? seasonStartDate,
    final DateTime? seasonEndDate,
    final List<DateTime> blockedDates,
    final List<String> images,
    final String? coverImageUrl,
    final String? widgetMode,
    final String? widgetTheme,
    final Map<String, dynamic>? widgetSettings,
    final Map<String, dynamic>? icalConfig,
    final Map<String, dynamic>? emailConfig,
    final Map<String, dynamic>? taxLegalConfig,
    final bool isPublished,
    final DateTime? lastSaved,
    final DateTime? createdAt,
  }) = _$UnitWizardDraftImpl;

  factory _UnitWizardDraft.fromJson(Map<String, dynamic> json) =
      _$UnitWizardDraftImpl.fromJson;

  // Meta
  @override
  String? get unitId; // null = new unit, non-null = edit existing
  @override
  int get currentStep; // 1-8
  @override
  Map<int, bool> get completedSteps; // {1: true, 2: true, ...}
  @override
  Map<int, bool> get skippedSteps; // {5: true, 7: true}
  // Step 1: Basic Info (REQUIRED)
  @override
  String? get name;
  @override
  String? get propertyId;
  @override
  String? get description;
  @override
  String? get slug; // Auto-generated from name
  // Step 2: Capacity & Space (REQUIRED)
  @override
  int? get bedrooms;
  @override
  int? get bathrooms;
  @override
  int? get maxGuests;
  @override
  double? get areaSqm; // Step 3: Pricing (REQUIRED)
  @override
  double? get pricePerNight;
  @override
  double? get weekendBasePrice; // Weekend price (Fri-Sat nights by default)
  @override
  List<int> get weekendDays; // Days considered weekend (1=Mon...7=Sun) - Fri=5, Sat=6 for hotel nights
  @override
  int? get minStayNights;
  @override
  int? get maxStayNights; // Maximum nights per booking (null = no limit)
  @override
  List<Map<String, dynamic>> get seasons; // Seasonal pricing (simplified)
  // Step 4: Availability (REQUIRED)
  @override
  bool get availableYearRound;
  @override
  DateTime? get seasonStartDate;
  @override
  DateTime? get seasonEndDate;
  @override
  List<DateTime> get blockedDates; // Step 5: Photos (RECOMMENDED)
  @override
  List<String> get images; // URLs after upload
  @override
  String? get coverImageUrl; // First image by default
  // Step 6: Widget Setup (RECOMMENDED)
  @override
  String? get widgetMode; // 'calendarOnly', 'bookingInstant', 'bookingPending'
  @override
  String? get widgetTheme; // 'minimalist', 'modern', 'luxury'
  @override
  Map<String, dynamic>? get widgetSettings; // Full widget_settings data
  // Step 7: Advanced Options (OPTIONAL)
  @override
  Map<String, dynamic>? get icalConfig;
  @override
  Map<String, dynamic>? get emailConfig;
  @override
  Map<String, dynamic>? get taxLegalConfig; // Step 8: Review & Publish (FINAL)
  @override
  bool get isPublished; // false = draft, true = active unit
  // Timestamps
  @override
  DateTime? get lastSaved;
  @override
  DateTime? get createdAt;

  /// Create a copy of UnitWizardDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnitWizardDraftImplCopyWith<_$UnitWizardDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
