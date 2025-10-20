import 'package:freezed_annotation/freezed_annotation.dart';
import 'search_filters.dart';

part 'saved_search.freezed.dart';
part 'saved_search.g.dart';

/// Model for saved search with filters
@freezed
class SavedSearch with _$SavedSearch {
  const factory SavedSearch({
    required String id,
    required String userId,
    required String name,
    required SearchFilters filters,
    @Default(false) bool notificationEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SavedSearch;

  factory SavedSearch.fromJson(Map<String, dynamic> json) =>
      _$SavedSearchFromJson(json);
}
