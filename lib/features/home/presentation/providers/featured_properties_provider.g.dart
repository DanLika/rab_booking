// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_properties_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Featured properties provider (now using REAL Supabase data!)

@ProviderFor(featuredProperties)
const featuredPropertiesProvider = FeaturedPropertiesProvider._();

/// Featured properties provider (now using REAL Supabase data!)

final class FeaturedPropertiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PropertyModel>>,
          List<PropertyModel>,
          FutureOr<List<PropertyModel>>
        >
    with
        $FutureModifier<List<PropertyModel>>,
        $FutureProvider<List<PropertyModel>> {
  /// Featured properties provider (now using REAL Supabase data!)
  const FeaturedPropertiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredPropertiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredPropertiesHash();

  @$internal
  @override
  $FutureProviderElement<List<PropertyModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PropertyModel>> create(Ref ref) {
    return featuredProperties(ref);
  }
}

String _$featuredPropertiesHash() =>
    r'2ed437287890f780074163450b5ae740be0fe9f1';
