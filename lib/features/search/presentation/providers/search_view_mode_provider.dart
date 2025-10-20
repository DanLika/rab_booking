import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_view_mode_provider.g.dart';

/// View mode for search results (grid, list, or map)
enum SearchViewMode {
  grid,
  list,
  map;

  String get displayName {
    switch (this) {
      case SearchViewMode.grid:
        return 'Grid';
      case SearchViewMode.list:
        return 'List';
      case SearchViewMode.map:
        return 'Map';
    }
  }
}

/// Search view mode provider
@riverpod
class SearchViewModeNotifier extends _$SearchViewModeNotifier {
  @override
  SearchViewMode build() {
    return SearchViewMode.grid;
  }

  void toggle() {
    state = switch (state) {
      SearchViewMode.grid => SearchViewMode.list,
      SearchViewMode.list => SearchViewMode.map,
      SearchViewMode.map => SearchViewMode.grid,
    };
  }

  void setMode(SearchViewMode mode) {
    state = mode;
  }
}
