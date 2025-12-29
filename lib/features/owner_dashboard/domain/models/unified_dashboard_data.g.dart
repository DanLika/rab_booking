// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_dashboard_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnifiedDashboardDataImpl _$$UnifiedDashboardDataImplFromJson(
  Map<String, dynamic> json,
) => _$UnifiedDashboardDataImpl(
  revenue: (json['revenue'] as num).toDouble(),
  bookings: (json['bookings'] as num).toInt(),
  upcomingCheckIns: (json['upcomingCheckIns'] as num).toInt(),
  occupancyRate: (json['occupancyRate'] as num).toDouble(),
  revenueHistory: (json['revenueHistory'] as List<dynamic>)
      .map((e) => RevenueDataPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  bookingHistory: (json['bookingHistory'] as List<dynamic>)
      .map((e) => BookingDataPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$UnifiedDashboardDataImplToJson(
  _$UnifiedDashboardDataImpl instance,
) => <String, dynamic>{
  'revenue': instance.revenue,
  'bookings': instance.bookings,
  'upcomingCheckIns': instance.upcomingCheckIns,
  'occupancyRate': instance.occupancyRate,
  'revenueHistory': instance.revenueHistory,
  'bookingHistory': instance.bookingHistory,
};

_$RevenueDataPointImpl _$$RevenueDataPointImplFromJson(
  Map<String, dynamic> json,
) => _$RevenueDataPointImpl(
  date: DateTime.parse(json['date'] as String),
  amount: (json['amount'] as num).toDouble(),
  label: json['label'] as String,
);

Map<String, dynamic> _$$RevenueDataPointImplToJson(
  _$RevenueDataPointImpl instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'amount': instance.amount,
  'label': instance.label,
};

_$BookingDataPointImpl _$$BookingDataPointImplFromJson(
  Map<String, dynamic> json,
) => _$BookingDataPointImpl(
  date: DateTime.parse(json['date'] as String),
  count: (json['count'] as num).toInt(),
  label: json['label'] as String,
);

Map<String, dynamic> _$$BookingDataPointImplToJson(
  _$BookingDataPointImpl instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'count': instance.count,
  'label': instance.label,
};

_$DateRangeFilterImpl _$$DateRangeFilterImplFromJson(
  Map<String, dynamic> json,
) => _$DateRangeFilterImpl(
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  preset: json['preset'] as String? ?? 'last7',
);

Map<String, dynamic> _$$DateRangeFilterImplToJson(
  _$DateRangeFilterImpl instance,
) => <String, dynamic>{
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'preset': instance.preset,
};
