import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trial_status.dart';

/// Provider for current user's trial status
final trialStatusProvider = StreamProvider<TrialStatus?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data();
        if (data == null) return null;
        return TrialStatus.fromFirestore(data);
      });
});

/// Provider to check if user has full access
final hasFullAccessProvider = Provider<bool>((ref) {
  final trialStatus = ref.watch(trialStatusProvider).valueOrNull;
  return trialStatus?.hasFullAccess ??
      true; // Default to true to avoid blocking
});

/// Provider to check if trial banner should be shown
final showTrialBannerProvider = Provider<bool>((ref) {
  final trialStatus = ref.watch(trialStatusProvider).valueOrNull;
  if (trialStatus == null) return false;

  // Show banner if:
  // 1. Trial is expiring soon (within 7 days)
  // 2. Trial has expired
  return trialStatus.isExpiringSoon || trialStatus.isTrialExpired;
});

/// Provider for days remaining in trial
final trialDaysRemainingProvider = Provider<int>((ref) {
  final trialStatus = ref.watch(trialStatusProvider).valueOrNull;
  return trialStatus?.daysRemaining ?? 0;
});
