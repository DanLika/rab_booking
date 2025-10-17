// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_view_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search view mode provider

@ProviderFor(SearchViewModeNotifier)
const searchViewModeProvider = SearchViewModeNotifierProvider._();

/// Search view mode provider
final class SearchViewModeNotifierProvider
    extends $NotifierProvider<SearchViewModeNotifier, SearchViewMode> {
  /// Search view mode provider
  const SearchViewModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchViewModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchViewModeNotifierHash();

  @$internal
  @override
  SearchViewModeNotifier create() => SearchViewModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchViewMode>(value),
    );
  }
}

String _$searchViewModeNotifierHash() =>
    r'8cd1eba0ea6c00244ccda22a4f285f330bc94c99';

/// Search view mode provider

abstract class _$SearchViewModeNotifier extends $Notifier<SearchViewMode> {
  SearchViewMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SearchViewMode, SearchViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchViewMode, SearchViewMode>,
              SearchViewMode,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
