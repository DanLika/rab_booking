import '../models/user_model.dart';

/// Abstract user repository interface
abstract class UserRepository {
  /// Get user by ID
  Future<UserModel?> getUserById(String id);

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email);

  /// Create new user
  Future<UserModel> createUser(UserModel user);

  /// Update user
  Future<UserModel> updateUser(UserModel user);

  /// Delete user
  Future<void> deleteUser(String id);

  /// Get current authenticated user
  Future<UserModel?> getCurrentUser();

  /// Check if user exists
  Future<bool> userExists(String id);
}
