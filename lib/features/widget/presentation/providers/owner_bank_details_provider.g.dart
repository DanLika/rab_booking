// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_bank_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ownerBankDetailsHash() => r'ee77ad533b5dccf178e0066780b130b9a02a1f93';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider to fetch owner's bank details by ownerId
/// Used in booking widget to display bank transfer payment info
///
/// Copied from [ownerBankDetails].
@ProviderFor(ownerBankDetails)
const ownerBankDetailsProvider = OwnerBankDetailsFamily();

/// Provider to fetch owner's bank details by ownerId
/// Used in booking widget to display bank transfer payment info
///
/// Copied from [ownerBankDetails].
class OwnerBankDetailsFamily extends Family<AsyncValue<CompanyDetails?>> {
  /// Provider to fetch owner's bank details by ownerId
  /// Used in booking widget to display bank transfer payment info
  ///
  /// Copied from [ownerBankDetails].
  const OwnerBankDetailsFamily();

  /// Provider to fetch owner's bank details by ownerId
  /// Used in booking widget to display bank transfer payment info
  ///
  /// Copied from [ownerBankDetails].
  OwnerBankDetailsProvider call(String ownerId) {
    return OwnerBankDetailsProvider(ownerId);
  }

  @override
  OwnerBankDetailsProvider getProviderOverride(
    covariant OwnerBankDetailsProvider provider,
  ) {
    return call(provider.ownerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ownerBankDetailsProvider';
}

/// Provider to fetch owner's bank details by ownerId
/// Used in booking widget to display bank transfer payment info
///
/// Copied from [ownerBankDetails].
class OwnerBankDetailsProvider
    extends AutoDisposeFutureProvider<CompanyDetails?> {
  /// Provider to fetch owner's bank details by ownerId
  /// Used in booking widget to display bank transfer payment info
  ///
  /// Copied from [ownerBankDetails].
  OwnerBankDetailsProvider(String ownerId)
    : this._internal(
        (ref) => ownerBankDetails(ref as OwnerBankDetailsRef, ownerId),
        from: ownerBankDetailsProvider,
        name: r'ownerBankDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$ownerBankDetailsHash,
        dependencies: OwnerBankDetailsFamily._dependencies,
        allTransitiveDependencies:
            OwnerBankDetailsFamily._allTransitiveDependencies,
        ownerId: ownerId,
      );

  OwnerBankDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ownerId,
  }) : super.internal();

  final String ownerId;

  @override
  Override overrideWith(
    FutureOr<CompanyDetails?> Function(OwnerBankDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OwnerBankDetailsProvider._internal(
        (ref) => create(ref as OwnerBankDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ownerId: ownerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CompanyDetails?> createElement() {
    return _OwnerBankDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OwnerBankDetailsProvider && other.ownerId == ownerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ownerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OwnerBankDetailsRef on AutoDisposeFutureProviderRef<CompanyDetails?> {
  /// The parameter `ownerId` of this provider.
  String get ownerId;
}

class _OwnerBankDetailsProviderElement
    extends AutoDisposeFutureProviderElement<CompanyDetails?>
    with OwnerBankDetailsRef {
  _OwnerBankDetailsProviderElement(super.provider);

  @override
  String get ownerId => (origin as OwnerBankDetailsProvider).ownerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
