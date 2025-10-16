import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_view_mode_provider.g.dart';

/// View mode for search results (grid or list)
enum SearchViewMode {
  grid,
  list;

  String get displayName {
    switch (this) {
      case SearchViewMode.grid:
        return 'Grid';
      case SearchViewMode.list:
        return 'List';
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
    state = state == SearchViewMode.grid ? SearchViewMode.list : SearchViewMode.grid;
  }

  void setMode(SearchViewMode mode) {
    state = mode;
  }
}
