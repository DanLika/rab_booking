import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_date.freezed.dart';
part 'blocked_date.g.dart';

/// Blokirani datumi (maintenance, personal use, etc.)
@freezed
class BlockedDate with _$BlockedDate {
  const factory BlockedDate({
    required String id,
    required String unitId,
    required DateTime blockedFrom,
    required DateTime blockedTo,
    @Default('maintenance') String reason,
    String? notes,
    required DateTime createdAt,
  }) = _BlockedDate;

  factory BlockedDate.fromJson(Map<String, dynamic> json) =>
      _$BlockedDateFromJson(json);
}

/// Razlozi za blokiranje datuma
enum BlockReason {
  maintenance,
  personal,
  renovation,
  other,
}
