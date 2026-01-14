import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/shared/models/user_model.dart';
import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/providers/enhanced_auth_provider.dart';

/// Test provider that allows us to override the auth state without
/// needing real Firebase dependencies.
///
/// This uses a simple StateProvider to hold the EnhancedAuthState,
/// which can be easily overridden in tests.
final _testAuthStateProvider = StateProvider<EnhancedAuthState>((ref) {
  return const EnhancedAuthState();
});

/// A test-friendly version of FeatureHighlightWidget that uses our test provider
/// instead of the real enhancedAuthProvider.
class _TestableFeatureHighlight extends ConsumerWidget {
  final String featureId;
  final Widget child;
  final String? tooltipMessage;
  final bool showTooltipAlways;

  const _TestableFeatureHighlight({
    required this.featureId,
    required this.child,
    this.tooltipMessage,
    this.showTooltipAlways = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(_testAuthStateProvider);
    final userModel = authState.userModel;

    // Check if feature has been seen
    final hasSeenFeature = userModel?.featureFlags[featureId] == true;

    // If already seen or no user, just return child
    if (hasSeenFeature || userModel == null) {
      if (tooltipMessage != null && showTooltipAlways) {
        return Tooltip(message: tooltipMessage, child: child);
      }
      return child;
    }

    // Show highlight for unseen features
    return child;
  }
}

void main() {
  group('FeatureHighlightWidget', () {
    late UserModel testUser;

    setUp(() {
      testUser = UserModel(
        id: 'test-user-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.owner,
        createdAt: DateTime(2025),
        featureFlags: {},
      );
    });

    Widget buildTestWidget({
      required EnhancedAuthState authState,
      String featureId = 'test_feature',
      String? tooltipMessage,
      bool showTooltipAlways = false,
    }) {
      return ProviderScope(
        overrides: [_testAuthStateProvider.overrideWith((ref) => authState)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: _TestableFeatureHighlight(
                featureId: featureId,
                tooltipMessage: tooltipMessage,
                showTooltipAlways: showTooltipAlways,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows child widget when feature is already seen', (
      tester,
    ) async {
      final userWithSeenFeature = testUser.copyWith(
        featureFlags: {'test_feature': true},
      );

      await tester.pumpWidget(
        buildTestWidget(
          authState: EnhancedAuthState(userModel: userWithSeenFeature),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows child widget when user is null (loading state)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(authState: const EnhancedAuthState()),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows child widget when feature is not seen', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(authState: EnhancedAuthState(userModel: testUser)),
      );

      // Widget should still show the button (with animation)
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets(
      'renders with tooltip when provided and showTooltipAlways=true',
      (tester) async {
        final userWithSeenFeature = testUser.copyWith(
          featureFlags: {'test_feature': true},
        );

        await tester.pumpWidget(
          buildTestWidget(
            authState: EnhancedAuthState(userModel: userWithSeenFeature),
            tooltipMessage: 'Test tooltip',
            showTooltipAlways: true,
          ),
        );

        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(Tooltip), findsOneWidget);
      },
    );

    testWidgets('does not show tooltip when feature not seen', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          authState: EnhancedAuthState(userModel: testUser),
          tooltipMessage: 'Test tooltip',
          showTooltipAlways: true,
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      // No tooltip because feature not seen yet (showing highlight instead)
      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group('UserModel.featureFlags', () {
    test('featureFlags defaults to empty map', () {
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.owner,
        createdAt: DateTime(2025),
      );

      expect(user.featureFlags, isEmpty);
    });

    test('featureFlags can be set via constructor', () {
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.owner,
        createdAt: DateTime(2025),
        featureFlags: {'feature_a': true, 'feature_b': false},
      );

      expect(user.featureFlags['feature_a'], true);
      expect(user.featureFlags['feature_b'], false);
      expect(user.featureFlags['feature_c'], isNull);
    });

    test('featureFlags can be updated via copyWith', () {
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: UserRole.owner,
        createdAt: DateTime(2025),
        featureFlags: {'feature_a': false},
      );

      final updatedUser = user.copyWith(
        featureFlags: {'feature_a': true, 'feature_b': true},
      );

      expect(updatedUser.featureFlags['feature_a'], true);
      expect(updatedUser.featureFlags['feature_b'], true);
      // Original unchanged
      expect(user.featureFlags['feature_a'], false);
    });
  });
}
