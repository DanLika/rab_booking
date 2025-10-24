import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/units_repository.dart';
import '../../domain/models/unit.dart';

/// Provider za Units Repository
final unitsRepositoryProvider = Provider<UnitsRepository>((ref) {
  return UnitsRepository(Supabase.instance.client);
});

/// Provider za dohvatanje jedinica po property-ju
final unitsByPropertyProvider =
    FutureProvider.family<List<Unit>, String>((ref, propertyId) async {
  final repository = ref.watch(unitsRepositoryProvider);
  return repository.getUnitsByProperty(propertyId);
});

/// Provider za dohvatanje jedne jedinice
final unitByIdProvider =
    FutureProvider.family<Unit?, String>((ref, unitId) async {
  final repository = ref.watch(unitsRepositoryProvider);
  return repository.getUnitById(unitId);
});

/// Stream provider za real-time updates
final unitsStreamProvider =
    StreamProvider.family<List<Unit>, String>((ref, propertyId) {
  final repository = ref.watch(unitsRepositoryProvider);
  return repository.watchUnitsByProperty(propertyId);
});

/// State Notifier za upravljanje Unit CRUD operacijama
class UnitsNotifier extends StateNotifier<AsyncValue<List<Unit>>> {
  final UnitsRepository _repository;
  final String propertyId;

  UnitsNotifier(this._repository, this.propertyId)
      : super(const AsyncValue.loading()) {
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    state = const AsyncValue.loading();
    try {
      final units = await _repository.getUnitsByProperty(propertyId);
      state = AsyncValue.data(units);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createUnit(Unit unit) async {
    try {
      await _repository.createUnit(unit);
      await _loadUnits();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUnit(String unitId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateUnit(unitId, updates);
      await _loadUnits();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUnit(String unitId) async {
    try {
      await _repository.deleteUnit(unitId);
      await _loadUnits();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleActive(String unitId, bool isActive) async {
    try {
      await _repository.toggleUnitActive(unitId, isActive);
      await _loadUnits();
    } catch (e) {
      rethrow;
    }
  }

  void refresh() {
    _loadUnits();
  }
}

/// Provider za Units Notifier
final unitsNotifierProvider = StateNotifierProvider.family<UnitsNotifier,
    AsyncValue<List<Unit>>, String>((ref, propertyId) {
  final repository = ref.watch(unitsRepositoryProvider);
  return UnitsNotifier(repository, propertyId);
});
