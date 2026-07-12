part of 'enhanced_auth_provider.dart';

/// Profile operations: onboarding/profile completion, feature-seen flags
/// and the re-auth-gated email update.
///
/// Extracted verbatim from EnhancedAuthNotifier on 2026-07-12 — file split
/// only, ZERO behavior change.
mixin _ProfileOpsMixin on _EnhancedAuthNotifierBase {
  /// Complete onboarding
  Future<void> completeOnboarding() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'onboardingCompleted': true,
    });

    if (state.userModel != null) {
      state = state.copyWith(
        userModel: state.userModel!.copyWith(onboardingCompleted: true),
        requiresOnboarding: false,
      );
    }
  }

  /// Complete profile (for social sign-in users)
  ///
  /// Called after user completes their profile on Edit Profile screen.
  /// Sets profileCompleted=true in Firestore and updates state.
  Future<void> completeProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'profile_completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (state.userModel != null) {
      state = state.copyWith(
        userModel: state.userModel!.copyWith(profileCompleted: true),
        requiresProfileCompletion: false,
      );
    }

    LoggingService.log(
      'Profile completed for user: $userId',
      tag: 'ENHANCED_AUTH',
    );
  }

  /// Mark a feature as seen (Feature Discovery)
  ///
  /// Used by [FeatureHighlightWidget] to track which features the user has interacted with.
  /// Uses optimistic update for instant UI feedback, then persists to Firestore.
  Future<void> markFeatureAsSeen(String featureId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || state.userModel == null) return;

    // Check if already seen to avoid unnecessary writes
    if (state.userModel!.featureFlags[featureId] == true) return;

    try {
      // Optimistic update for instant UI feedback
      final updatedFlags = Map<String, bool>.from(
        state.userModel!.featureFlags,
      );
      updatedFlags[featureId] = true;

      state = state.copyWith(
        userModel: state.userModel!.copyWith(featureFlags: updatedFlags),
      );

      // Persist to Firestore (non-blocking)
      await _firestore.collection('users').doc(userId).update({
        'featureFlags.$featureId': true,
      });

      LoggingService.log(
        'Feature marked as seen: $featureId',
        tag: 'FEATURE_DISCOVERY',
      );
    } catch (e) {
      // Silent fail - feature flags are not critical
      // User will see the highlight again next time, which is acceptable
      LoggingService.log(
        'Failed to mark feature as seen: $e',
        tag: 'AUTH_WARNING',
      );
    }
  }

  /// Update user email (Phase 3 feature)
  /// Re-authenticates user with password, then updates email and sends verification
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    LoggingService.log('Updating email to: $newEmail', tag: 'ENHANCED_AUTH');

    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user logged in', code: 'auth/no-user');
    }

    if (user.email == null) {
      throw AuthException('Current user has no email', code: 'auth/no-email');
    }

    try {
      // Re-authenticate user with current password
      LoggingService.log('Re-authenticating user...', tag: 'ENHANCED_AUTH');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Verify email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore
      LoggingService.log(
        'Updating email in Firestore...',
        tag: 'ENHANCED_AUTH',
      );
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'emailVerified': false, // Email now requires verification
        'updatedAt': FieldValue.serverTimestamp(),
      });

      LoggingService.log('Email updated successfully!', tag: 'ENHANCED_AUTH');

      // Update userModel with new email so resend works correctly
      final updatedUserModel = state.userModel?.copyWith(
        email: newEmail,
        emailVerified: false,
      );

      // Reload state to reflect changes
      state = state.copyWith(
        userModel: updatedUserModel,
        requiresEmailVerification: AuthFeatureFlags.requireEmailVerification,
      );
    } on FirebaseAuthException catch (e) {
      unawaited(LoggingService.logError('Email update failed: ${e.code}', e));
      throw _getAuthErrorMessage(e);
    } catch (e) {
      unawaited(LoggingService.logError('Email update error', e));
      const errorMessage = 'Failed to update email. Please try again.';
      throw errorMessage; // Throw user-friendly message instead of raw exception
    }
  }
}
