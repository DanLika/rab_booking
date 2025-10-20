// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_results_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchResultsCountHash() =>
    r'd18323365806c8dfc396fdbe4eb8d8163585d2b1';

/// Search results count provider
///
/// Copied from [searchResultsCount].
@ProviderFor(searchResultsCount)
final searchResultsCountProvider = AutoDisposeProvider<int>.internal(
  searchResultsCount,
  name: r'searchResultsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsCountRef = AutoDisposeProviderRef<int>;
String _$searchResultsNotifierHash() =>
    r'266ba11aee538d457395c6d3904b1f95c8c747a1';

/// Search results notifier with infinite scroll support
///
/// Copied from [SearchResultsNotifier].
@ProviderFor(SearchResultsNotifier)
final searchResultsNotifierProvider =
    AutoDisposeNotifierProvider<
      SearchResultsNotifier,
      SearchResultsState
    >.internal(
      SearchResultsNotifier.new,
      name: r'searchResultsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchResultsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchResultsNotifier = AutoDisposeNotifier<SearchResultsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
