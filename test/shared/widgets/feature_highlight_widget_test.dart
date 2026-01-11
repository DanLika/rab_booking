import 'package:bookbed/core/providers/enhanced_auth_provider.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:bookbed/shared/widgets/feature_highlight_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/core/services/rate_limit_service.dart';
import 'package:bookbed/core/services/security_events_service.dart';
import 'package:bookbed/core/services/ip_geolocation_service.dart';

// Mock UserModel
class MockUserModel extends Mock implements UserModel {}

// Mocks for dependencies
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockRateLimitService extends Mock implements RateLimitService {}
class MockSecurityEventsService extends Mock implements SecurityEventsService {}
class MockIpGeolocationService extends Mock implements IpGeolocationService {}

// Fake Notifier for testing state
class FakeEnhancedAuthNotifier extends EnhancedAuthNotifier {
  FakeEnhancedAuthNotifier(FirebaseAuth auth)
      : super(
          auth,
          MockFirebaseFirestore(),
          MockRateLimitService(),
          MockSecurityEventsService(),
          MockIpGeolocationService(),
        );

  void setTestState(EnhancedAuthState newState) {
    state = newState;
  }

  @override
  Future<void> markFeatureAsSeen(String featureId) async {
    if (state.userModel != null) {
      final updatedFlags = Map<String, bool>.from(state.userModel!.featureFlags);
      updatedFlags[featureId] = true;
      state = state.copyWith(userModel: state.userModel!.copyWith(featureFlags: updatedFlags));
    }
  }
}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeEnhancedAuthNotifier mockNotifier;
  late MockUserModel mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

    mockNotifier = FakeEnhancedAuthNotifier(mockAuth);
    mockUser = MockUserModel();

    // Note: We set state immediately, but the auth listener might overwrite it.
    // However, since authStateChanges emits null synchronously in our mock (Stream.value),
    // the listener fires. We just need to make sure we overwrite it effectively.
    // In a real app, listen() is async.
  });

  testWidgets('FeatureHighlightWidget shows tooltip and animation when feature is unseen', (tester) async {
    // Ensure screen size is large enough for Tooltip
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;

    // Set state right before pumping
    mockNotifier.setTestState(EnhancedAuthState(userModel: mockUser));
    when(() => mockUser.featureFlags).thenReturn({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enhancedAuthProvider.overrideWith((ref) => mockNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FeatureHighlightWidget(
              featureId: 'test_feature',
              tooltipMessage: 'Test Tooltip',
              child: const Text('Target Widget'),
            ),
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Check if the widget tree has the Tooltip. If not, it means state might have been cleared.
    // To debug, we can print the state in the widget if needed, but let's assume setting it here works.

    // Allow animations to start
    await tester.pump(const Duration(milliseconds: 100));

    // Verify the child is present
    expect(find.text('Target Widget'), findsOneWidget);

    // Verify tooltip logic
    final tooltip = find.byType(Tooltip);
    expect(tooltip, findsOneWidget);
    expect((tester.widget(tooltip) as Tooltip).message, 'Test Tooltip');

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('FeatureHighlightWidget does NOT animate when feature is seen', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;

    when(() => mockUser.featureFlags).thenReturn({'test_feature': true});
    mockNotifier.setTestState(EnhancedAuthState(userModel: mockUser));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enhancedAuthProvider.overrideWith((ref) => mockNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FeatureHighlightWidget(
              featureId: 'test_feature',
              tooltipMessage: 'Test Tooltip',
              child: const Text('Target Widget'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Target Widget'), findsOneWidget);
    expect(find.byType(Tooltip), findsNothing);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
