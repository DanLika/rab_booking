import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../models/notification_preferences_model.dart';

/// Repository for managing user profile and preferences in Firestore
///
/// Firestore structure:
/// - users/{userId}/profile (UserProfile)
/// - users/{userId}/company (CompanyDetails)
/// - users/{userId}/preferences (NotificationPreferences + theme + language)
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========== USER PROFILE ==========

  /// Get user profile stream
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('profile')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfile.fromFirestore(userId, snapshot.data()!);
    });
  }

  /// Get user profile once
  Future<UserProfile?> getUserProfile(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('profile')
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfile.fromFirestore(userId, snapshot.data()!);
  }

  /// Update user profile (optimistic update pattern)
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.userId)
          .collection('data')
          .doc('profile')
          .set(
            profile.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ========== COMPANY DETAILS ==========

  /// Get company details stream
  Stream<CompanyDetails?> watchCompanyDetails(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('company')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return CompanyDetails.fromFirestore(snapshot.data()!);
    });
  }

  /// Get company details once
  Future<CompanyDetails?> getCompanyDetails(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('company')
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return CompanyDetails.fromFirestore(snapshot.data()!);
  }

  /// Update company details
  Future<void> updateCompanyDetails(
    String userId,
    CompanyDetails company,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('company')
          .set(
        {
          'companyName': company.companyName,
          'taxId': company.taxId,
          'vatId': company.vatId,
          'bankAccountIban': company.bankAccountIban,
          'swift': company.swift,
          'bankName': company.bankName,
          'accountHolder': company.accountHolder,
          'address': company.address.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update company details: $e');
    }
  }

  // ========== NOTIFICATION PREFERENCES ==========

  /// Get notification preferences stream
  Stream<NotificationPreferences?> watchNotificationPreferences(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('preferences')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return NotificationPreferences.fromFirestore(userId, snapshot.data()!);
    });
  }

  /// Get notification preferences once
  Future<NotificationPreferences?> getNotificationPreferences(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('preferences')
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return NotificationPreferences.fromFirestore(userId, snapshot.data()!);
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(preferences.userId)
          .collection('data')
          .doc('preferences')
          .set(
            preferences.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // ========== COMBINED DATA ==========

  /// Get complete user data (profile + company)
  Future<UserData?> getUserData(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) return null;

    final company = await getCompanyDetails(userId) ?? const CompanyDetails();

    return UserData(profile: profile, company: company);
  }

  /// Watch complete user data stream
  Stream<UserData?> watchUserData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .snapshots()
        .asyncMap((snapshot) async {
      UserProfile? profile;
      CompanyDetails? company;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (doc.id == 'profile') {
          profile = UserProfile.fromFirestore(userId, data);
        } else if (doc.id == 'company') {
          company = CompanyDetails.fromFirestore(data);
        }
      }

      if (profile == null) return null;

      return UserData(
        profile: profile,
        company: company ?? const CompanyDetails(),
      );
    });
  }
}
