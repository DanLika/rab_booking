import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/contact_message.dart';

part 'contact_repository.g.dart';

@riverpod
ContactRepository contactRepository(Ref ref) {
  return ContactRepository(Supabase.instance.client);
}

class ContactRepository {
  final SupabaseClient _supabase;

  ContactRepository(this._supabase);

  Future<void> submitContactMessage(ContactMessage message) async {
    try {
      await _supabase.from('contact_messages').insert({
        'name': message.name,
        'email': message.email,
        'subject': message.subject,
        'message': message.message,
        'user_id': message.userId,
        'status': 'new',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to submit contact message: $e');
    }
  }

  Future<List<ContactMessage>> getUserMessages(String userId) async {
    try {
      final response = await _supabase
          .from('contact_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ContactMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch contact messages: $e');
    }
  }
}
