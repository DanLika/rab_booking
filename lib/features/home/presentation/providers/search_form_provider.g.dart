// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search form state notifier

@ProviderFor(SearchFormNotifier)
const searchFormProvider = SearchFormNotifierProvider._();

/// Search form state notifier
final class SearchFormNotifierProvider
    extends $NotifierProvider<SearchFormNotifier, SearchFormState> {
  /// Search form state notifier
  const SearchFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFormNotifierHash();

  @$internal
  @override
  SearchFormNotifier create() => SearchFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchFormState>(value),
    );
  }
}

String _$searchFormNotifierHash() =>
    r'47c3a1c81b97af9db775302a37f8df9a31b2dffb';

/// Search form state notifier

abstract class _$SearchFormNotifier extends $Notifier<SearchFormState> {
  SearchFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SearchFormState, SearchFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchFormState, SearchFormState>,
              SearchFormState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
