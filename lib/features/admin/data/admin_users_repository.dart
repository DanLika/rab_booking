import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/logging_service.dart';
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

    // Lifetime users count
    final lifetimeSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .where('accountType', isEqualTo: 'lifetime')
        .count()
        .get();

    return {
      'totalOwners': ownersSnapshot.count ?? 0,
      'trialUsers': trialSnapshot.count ?? 0,
      'premiumUsers': premiumSnapshot.count ?? 0,
      'lifetimeUsers': lifetimeSnapshot.count ?? 0,
    };
  }

  /// Get user's properties count
  Future<int> getUserPropertiesCount(String userId) async {
    final snapshot = await _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get user's bookings count
  /// OPTIMIZED: Uses collectionGroup to count all bookings for owner in one query
  Future<int> getUserBookingsCount(String userId) async {
    final bookingsCount = await _firestore
        .collectionGroup('bookings')
        .where('owner_id', isEqualTo: userId)
        .count()
        .get();

    return bookingsCount.count ?? 0;
  }

  /// Get user's raw account status from Firestore
  /// (accountStatus field is not part of UserModel)
  Future<String?> getUserAccountStatus(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['accountStatus'] as String?;
  }

  /// Update admin-controlled flags for a user
  Future<void> updateAdminFlags(
    String userId, {
    bool? hideSubscription,
    AccountType? adminOverrideAccountType,
    bool clearOverride = false,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (hideSubscription != null) {
      updates['hide_subscription'] = hideSubscription;
    }

    if (clearOverride) {
      updates['admin_override_account_type'] = FieldValue.delete();
    } else if (adminOverrideAccountType != null) {
      updates['admin_override_account_type'] = adminOverrideAccountType.name;
    }

    await _firestore.collection('users').doc(userId).update(updates);
  }

  /// Update user's account status via Cloud Function (with audit trail)
  /// Valid statuses: trial, active, trial_expired, suspended
  Future<String> updateUserStatus({
    required String userId,
    required String newStatus,
    String? reason,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('updateUserStatus');

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'newStatus': newStatus,
        if (reason != null) 'reason': reason,
      });

      final data = result.data;
      return data['message'] as String? ?? 'Status updated';
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        'updateUserStatus failed: userId=$userId, status=$newStatus, code=${e.code}',
        e,
        StackTrace.current,
      );
      rethrow;
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'updateUserStatus unexpected error: userId=$userId, status=$newStatus',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get count of owners created in last N days
  Future<int> getRecentSignupsCount(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'owner')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get activity log entries from security_events collection
  Future<List<Map<String, dynamic>>> getActivityLog({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('security_events')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Set or revoke lifetime license for a user via Cloud Function
  /// Returns success message or throws exception on error
  Future<String> setLifetimeLicense({
    required String userId,
    required bool grant,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('setLifetimeLicense');

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'grant': grant,
      });

      final data = result.data;
      return data['message'] as String? ?? 'Operation completed';
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        'setLifetimeLicense failed: userId=$userId, grant=$grant, code=${e.code}',
        e,
        StackTrace.current,
      );
      rethrow;
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'setLifetimeLicense unexpected error: userId=$userId, grant=$grant',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

/// Provider for admin users repository
final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository();
});

/// Paginated owners list notifier
class OwnersListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final AdminUsersRepository _repo;
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  OwnersListNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _lastDoc = null;
    _hasMore = true;
    try {
      final result = await _repo.getOwners(limit: _pageSize);
      if (result.length < _pageSize) _hasMore = false;
      if (result.isNotEmpty) {
        // Store raw doc for cursor
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(result.last.id)
            .get();
        _lastDoc = snap;
      }
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _lastDoc == null) return;
    final current = state.valueOrNull ?? [];
    try {
      final result = await _repo.getOwners(
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      if (result.length < _pageSize) _hasMore = false;
      if (result.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(result.last.id)
            .get();
        _lastDoc = snap;
      }
      state = AsyncValue.data([...current, ...result]);
    } catch (e) {
      // Keep existing data on pagination error - don't overwrite list
      _hasMore = false;
    }
  }
}

/// Provider for paginated owners list
final ownersListProvider =
    StateNotifierProvider<OwnersListNotifier, AsyncValue<List<UserModel>>>((
      ref,
    ) {
      final repo = ref.watch(adminUsersRepositoryProvider);
      return OwnersListNotifier(repo);
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

/// Provider for user's properties count
final userPropertiesCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getUserPropertiesCount(userId);
});

/// Provider for user's bookings count
final userBookingsCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getUserBookingsCount(userId);
});

/// Provider for user's account status (raw Firestore field)
final userAccountStatusProvider = FutureProvider.family<String?, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getUserAccountStatus(userId);
});

/// Provider for recent signups analytics
final recentSignupsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  final last7 = await repo.getRecentSignupsCount(7);
  final last30 = await repo.getRecentSignupsCount(30);
  return {'last7Days': last7, 'last30Days': last30};
});

/// Provider for activity log
final activityLogProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminUsersRepositoryProvider);
  return repo.getActivityLog();
});
