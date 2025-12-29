// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currencyServiceHash() => r'270dc9d29d1ba050130107b38169df699371efa6';

/// Currency service for managing selected currency and conversions
///
/// Copied from [currencyService].
@ProviderFor(currencyService)
final currencyServiceProvider = AutoDisposeProvider<CurrencyService>.internal(
  currencyService,
  name: r'currencyServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currencyServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrencyServiceRef = AutoDisposeProviderRef<CurrencyService>;
String _$selectedCurrencyHash() => r'20ee4cfe68839dd52601cee7942415973ab4c48d';

/// Current selected currency provider
///
/// Copied from [SelectedCurrency].
@ProviderFor(SelectedCurrency)
final selectedCurrencyProvider =
    AutoDisposeAsyncNotifierProvider<SelectedCurrency, Currency>.internal(
      SelectedCurrency.new,
      name: r'selectedCurrencyProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedCurrencyHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedCurrency = AutoDisposeAsyncNotifier<Currency>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
