// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_wizard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unitWizardNotifierHash() =>
    r'0365956d326bbe8769a4c92169f5a5f1826e9154';

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

abstract class _$UnitWizardNotifier
    extends BuildlessAutoDisposeAsyncNotifier<UnitWizardDraft> {
  late final String? unitId;

  FutureOr<UnitWizardDraft> build(String? unitId);
}

/// Unit Wizard Provider - manages wizard state in-memory
///
/// Copied from [UnitWizardNotifier].
@ProviderFor(UnitWizardNotifier)
const unitWizardNotifierProvider = UnitWizardNotifierFamily();

/// Unit Wizard Provider - manages wizard state in-memory
///
/// Copied from [UnitWizardNotifier].
class UnitWizardNotifierFamily extends Family<AsyncValue<UnitWizardDraft>> {
  /// Unit Wizard Provider - manages wizard state in-memory
  ///
  /// Copied from [UnitWizardNotifier].
  const UnitWizardNotifierFamily();

  /// Unit Wizard Provider - manages wizard state in-memory
  ///
  /// Copied from [UnitWizardNotifier].
  UnitWizardNotifierProvider call(String? unitId) {
    return UnitWizardNotifierProvider(unitId);
  }

  @override
  UnitWizardNotifierProvider getProviderOverride(
    covariant UnitWizardNotifierProvider provider,
  ) {
    return call(provider.unitId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'unitWizardNotifierProvider';
}

/// Unit Wizard Provider - manages wizard state in-memory
///
/// Copied from [UnitWizardNotifier].
class UnitWizardNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          UnitWizardNotifier,
          UnitWizardDraft
        > {
  /// Unit Wizard Provider - manages wizard state in-memory
  ///
  /// Copied from [UnitWizardNotifier].
  UnitWizardNotifierProvider(String? unitId)
    : this._internal(
        () => UnitWizardNotifier()..unitId = unitId,
        from: unitWizardNotifierProvider,
        name: r'unitWizardNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$unitWizardNotifierHash,
        dependencies: UnitWizardNotifierFamily._dependencies,
        allTransitiveDependencies:
            UnitWizardNotifierFamily._allTransitiveDependencies,
        unitId: unitId,
      );

  UnitWizardNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unitId,
  }) : super.internal();

  final String? unitId;

  @override
  FutureOr<UnitWizardDraft> runNotifierBuild(
    covariant UnitWizardNotifier notifier,
  ) {
    return notifier.build(unitId);
  }

  @override
  Override overrideWith(UnitWizardNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UnitWizardNotifierProvider._internal(
        () => create()..unitId = unitId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unitId: unitId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<UnitWizardNotifier, UnitWizardDraft>
  createElement() {
    return _UnitWizardNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitWizardNotifierProvider && other.unitId == unitId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unitId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnitWizardNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<UnitWizardDraft> {
  /// The parameter `unitId` of this provider.
  String? get unitId;
}

class _UnitWizardNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          UnitWizardNotifier,
          UnitWizardDraft
        >
    with UnitWizardNotifierRef {
  _UnitWizardNotifierProviderElement(super.provider);

  @override
  String? get unitId => (origin as UnitWizardNotifierProvider).unitId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
