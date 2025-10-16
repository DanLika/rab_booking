import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../user_repository.dart';
import '../../../core/exceptions/app_exceptions.dart';

/// Supabase implementation of UserRepository
class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._client);

  final SupabaseClient _client;

  /// Table name
  static const String _tableName = 'users';

  @override
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      final data = user.toJson();
      data.remove('id'); // Let database generate ID

      final response = await _client
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final data = user.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .update(data)
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) return null;

      return getUserById(authUser.id);
    } catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<bool> userExists(String id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('id', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw e.toAppException();
    }
  }
}
