// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentThemeModeHash() => r'b3e192ff17eff2e8c9892cebdfb5de7c13da62a1';

/// Provider to get the current theme mode synchronously (with fallback to system)
///
/// Copied from [currentThemeMode].
@ProviderFor(currentThemeMode)
final currentThemeModeProvider = AutoDisposeProvider<ThemeMode>.internal(
  currentThemeMode,
  name: r'currentThemeModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentThemeModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentThemeModeRef = AutoDisposeProviderRef<ThemeMode>;
String _$themeNotifierHash() => r'19ea4f64be8b7aa96538f8a5c33c9cd0f83485a8';

/// Provider for managing theme mode (light/dark) with persistent storage
///
/// Copied from [ThemeNotifier].
@ProviderFor(ThemeNotifier)
final themeNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ThemeNotifier, ThemeMode>.internal(
      ThemeNotifier.new,
      name: r'themeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeNotifier = AutoDisposeAsyncNotifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
