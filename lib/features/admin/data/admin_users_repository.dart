import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';

/// Repository for admin user management operations
class AdminUsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all users with owner role (paginated)
  Future<List<UserModel>> getOwners({
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    }).toList();
  }

  /// Get single user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }

  /// Update user's account type
  Future<void> updateAccountType(String userId, AccountType accountType) async {
    await _firestore.collection('users').doc(userId).update({
      'accountType': accountType.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update user's role
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get total counts for dashboard
  Future<Map<String, int>> getDashboardStats() async {
    // Total owners count
    final ownersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .count()
        .get();

    // Trial users count
    final trialSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .where('accountType', isEqualTo: 'trial')
        .count()
        .get();

    // Premium users count
    final premiumSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .where('accountType', isEqualTo: 'premium')
        .count()
        .get();

    return {
      'totalOwners': ownersSnapshot.count ?? 0,
      'trialUsers': trialSnapshot.count ?? 0,
      'premiumUsers': premiumSnapshot.count ?? 0,
    };
  }

  /// Get user's properties count
  Future<int> getUserPropertiesCount(String userId) async {
    final snapshot = await _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get user's bookings count
  Future<int> getUserBookingsCount(String userId) async {
    // Need to get all properties first, then count bookings
    final propsSnapshot = await _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: userId)
        .get();

    int totalBookings = 0;
    for (final prop in propsSnapshot.docs) {
      final bookingsCount = await _firestore
          .collection('properties')
          .doc(prop.id)
          .collection('bookings')
          .count()
          .get();
      totalBookings += bookingsCount.count ?? 0;
    }
    return totalBookings;
  }
}

/// Provider for admin users repository
final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository();
});

/// Provider for owners list
final ownersListProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getOwners();
});

/// Provider for dashboard stats
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getDashboardStats();
});

/// Provider for single user
final userDetailProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getUserById(userId);
});
