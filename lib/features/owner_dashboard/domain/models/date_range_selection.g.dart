// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_range_selection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DateRangeSelectionImpl _$$DateRangeSelectionImplFromJson(
  Map<String, dynamic> json,
) => _$DateRangeSelectionImpl(
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
);

Map<String, dynamic> _$$DateRangeSelectionImplToJson(
  _$DateRangeSelectionImpl instance,
) => <String, dynamic>{
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
};
