import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_price.freezed.dart';
part 'daily_price.g.dart';

/// Cijena po danu za specifičnu jedinicu
@freezed
class DailyPrice with _$DailyPrice {
  const factory DailyPrice({
    required String id,
    required String unitId,
    required DateTime date,
    required double price,
    required DateTime createdAt,
  }) = _DailyPrice;

  factory DailyPrice.fromJson(Map<String, dynamic> json) =>
      _$DailyPriceFromJson(json);
}
