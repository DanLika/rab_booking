import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/payment_info.dart';

/// Repository za upravljanje payment info podacima
class PaymentInfoRepository {
  final SupabaseClient _supabase;

  PaymentInfoRepository(this._supabase);

  /// Dohvata payment info za određenog vlasnika
  Future<PaymentInfo?> getPaymentInfoByOwnerId(String ownerId) async {
    try {
      final response = await _supabase
          .from('payment_info')
          .select()
          .eq('owner_id', ownerId)
          .single();

      return PaymentInfo.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Kreira novi payment info zapis
  Future<PaymentInfo> createPaymentInfo(PaymentInfo paymentInfo) async {
    try {
      final response = await _supabase
          .from('payment_info')
          .insert({
            'owner_id': paymentInfo.ownerId,
            'bank_name': paymentInfo.bankName,
            'iban': paymentInfo.iban,
            'swift': paymentInfo.swift,
            'account_holder': paymentInfo.accountHolder,
            'default_advance_percentage': paymentInfo.defaultAdvancePercentage,
          })
          .select()
          .single();

      return PaymentInfo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create payment info: $e');
    }
  }

  /// Ažurira payment info
  Future<PaymentInfo> updatePaymentInfo(
    String paymentInfoId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('payment_info')
          .update(updates)
          .eq('id', paymentInfoId)
          .select()
          .single();

      return PaymentInfo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment info: $e');
    }
  }

  /// Dohvata payment info za jedinicu (preko property -> owner)
  Future<PaymentInfo?> getPaymentInfoForUnit(String unitId) async {
    try {
      // Join preko units -> properties -> payment_info
      final response = await _supabase
          .from('units')
          .select('''
            properties!inner(
              owner_id,
              payment_info!inner(*)
            )
          ''')
          .eq('id', unitId)
          .single();

      final paymentInfoData =
          response['properties']['payment_info'];

      if (paymentInfoData is List && paymentInfoData.isNotEmpty) {
        return PaymentInfo.fromJson(paymentInfoData.first as Map<String, dynamic>);
      } else if (paymentInfoData is Map) {
        return PaymentInfo.fromJson(Map<String, dynamic>.from(paymentInfoData));
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch payment info for unit: $e');
    }
  }

  /// Stream za praćenje payment info
  Stream<PaymentInfo?> watchPaymentInfo(String ownerId) {
    return _supabase
        .from('payment_info')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map((data) =>
            data.isNotEmpty ? PaymentInfo.fromJson(data.first) : null);
  }
}
