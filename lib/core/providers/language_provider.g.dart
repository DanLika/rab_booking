// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentLocaleHash() => r'5dfec30f1472f911ee7e9301187e22fb17746645';

/// Provider to get the current locale synchronously (with fallback to default)
///
/// Copied from [currentLocale].
@ProviderFor(currentLocale)
final currentLocaleProvider = AutoDisposeProvider<Locale>.internal(
  currentLocale,
  name: r'currentLocaleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocaleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLocaleRef = AutoDisposeProviderRef<Locale>;
String _$languageNotifierHash() => r'b6bab001d1d9e11879b15e8ce3b66306ff4e49b6';

/// Provider for managing language preferences with persistent storage
///
/// ## AutoDispose Decision: TRUE (current) - SHOULD BE keepAlive
/// Language preference is app-wide and used in MaterialApp.locale.
/// AutoDispose is acceptable because:
/// - SharedPreferences persists the value across sessions
/// - State rebuilds quickly from cached SharedPreferences
///
/// Consider @Riverpod(keepAlive: true) if locale flickering occurs on navigation
///
/// Copied from [LanguageNotifier].
@ProviderFor(LanguageNotifier)
final languageNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LanguageNotifier, Locale>.internal(
      LanguageNotifier.new,
      name: r'languageNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$languageNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LanguageNotifier = AutoDisposeAsyncNotifier<Locale>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
