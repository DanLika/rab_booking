import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/payment_info_repository.dart';
import '../../domain/models/payment_info.dart';

/// Provider za PaymentInfo Repository
final paymentInfoRepositoryProvider = Provider<PaymentInfoRepository>((ref) {
  return PaymentInfoRepository(Supabase.instance.client);
});

/// Provider za payment info vlasnika
final ownerPaymentInfoProvider =
    FutureProvider.family<PaymentInfo?, String>((ref, ownerId) async {
  final repository = ref.watch(paymentInfoRepositoryProvider);
  return repository.getPaymentInfoByOwnerId(ownerId);
});

/// Provider za payment info određene jedinice
final unitPaymentInfoProvider =
    FutureProvider.family<PaymentInfo?, String>((ref, unitId) async {
  final repository = ref.watch(paymentInfoRepositoryProvider);
  return repository.getPaymentInfoForUnit(unitId);
});

/// Stream provider za payment info (real-time)
final paymentInfoStreamProvider =
    StreamProvider.family<PaymentInfo?, String>((ref, ownerId) {
  final repository = ref.watch(paymentInfoRepositoryProvider);
  return repository.watchPaymentInfo(ownerId);
});

/// State Notifier za upravljanje payment info
class PaymentInfoNotifier extends StateNotifier<AsyncValue<PaymentInfo?>> {
  final PaymentInfoRepository _repository;

  PaymentInfoNotifier(this._repository) : super(const AsyncValue.loading());

  /// Učitava payment info za vlasnika
  Future<void> loadPaymentInfo(String ownerId) async {
    state = const AsyncValue.loading();

    try {
      final paymentInfo = await _repository.getPaymentInfoByOwnerId(ownerId);
      state = AsyncValue.data(paymentInfo);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Kreira novi payment info
  Future<PaymentInfo> createPaymentInfo(PaymentInfo paymentInfo) async {
    state = const AsyncValue.loading();

    try {
      final created = await _repository.createPaymentInfo(paymentInfo);
      state = AsyncValue.data(created);
      return created;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Ažurira payment info
  Future<PaymentInfo> updatePaymentInfo(
    String paymentInfoId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updated =
          await _repository.updatePaymentInfo(paymentInfoId, updates);
      state = AsyncValue.data(updated);
      return updated;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider za PaymentInfo Notifier
final paymentInfoNotifierProvider =
    StateNotifierProvider<PaymentInfoNotifier, AsyncValue<PaymentInfo?>>((ref) {
  final repository = ref.watch(paymentInfoRepositoryProvider);
  return PaymentInfoNotifier(repository);
});
