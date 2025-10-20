// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_properties_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$featuredPropertiesHash() =>
    r'dee2d5ea4225f90ae9f051ec675672a972e54245';

/// Featured properties provider - fetches real data from Supabase
///
/// Copied from [featuredProperties].
@ProviderFor(featuredProperties)
final featuredPropertiesProvider =
    AutoDisposeFutureProvider<List<PropertyModel>>.internal(
      featuredProperties,
      name: r'featuredPropertiesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$featuredPropertiesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedPropertiesRef =
    AutoDisposeFutureProviderRef<List<PropertyModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
