// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_results_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search results provider

@ProviderFor(searchResults)
const searchResultsProvider = SearchResultsProvider._();

/// Search results provider

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PropertyModel>>,
          List<PropertyModel>,
          FutureOr<List<PropertyModel>>
        >
    with
        $FutureModifier<List<PropertyModel>>,
        $FutureProvider<List<PropertyModel>> {
  /// Search results provider
  const SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<PropertyModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PropertyModel>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'4ce5cd16d2043c42297af20a1e1abe290600a4bb';

/// Search results count provider

@ProviderFor(searchResultsCount)
const searchResultsCountProvider = SearchResultsCountProvider._();

/// Search results count provider

final class SearchResultsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Search results count provider
  const SearchResultsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return searchResultsCount(ref);
  }
}

String _$searchResultsCountHash() =>
    r'62d0c145463618bd4c600490905a11217f7611b0';
