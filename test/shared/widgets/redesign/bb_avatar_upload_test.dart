import 'package:bookbed/shared/widgets/redesign/bb_avatar.dart';
import 'package:bookbed/shared/widgets/redesign/bb_avatar_upload.dart';
import 'package:bookbed/shared/widgets/redesign/bb_icon.dart';
import 'package:bookbed/shared/widgets/redesign/bb_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wrap a widget tree in a minimal MaterialApp so theme-aware token
/// accessors (BBColor.of, BbRedesignTokens.of) can resolve.
Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

/// `Uint8List?, String?` no-op — `flutter_test` cannot exercise the
/// `image_picker` plugin path so we never expect this to fire from a tap
/// in these tests. See dart-doc on `BbAvatarUpload` + audit/103 §3.4.
void _noop(Object? a, Object? b) {}

void main() {
  group('BbAvatarUpload (Phase 1.4)', () {
    testWidgets('placeholder renders initials when no imageUrl', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbAvatarUpload(
            imageUrl: null,
            initials: 'ab',
            onImageSelected: _noop,
          ),
        ),
      );

      // Uppercased per dart-doc.
      expect(find.text('AB'), findsOneWidget);
      // Edit affordance always present in idle state.
      expect(find.byType(BbIcon), findsAtLeastNWidgets(1));
      // Not in busy state → spinner absent.
      expect(find.byType(BbSpinner), findsNothing);
    });

    testWidgets('placeholder falls back to `person` icon when initials null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbAvatarUpload(
            imageUrl: null,
            initials: null,
            onImageSelected: _noop,
          ),
        ),
      );

      final Iterable<BbIcon> icons = tester.widgetList<BbIcon>(
        find.byType(BbIcon),
      );
      // At least one is the person placeholder, another the edit affordance.
      expect(icons.any((BbIcon i) => i.name == 'person'), isTrue);
      expect(
        icons.any((BbIcon i) => i.name == 'add_a_photo' || i.name == 'edit'),
        isTrue,
      );
    });

    testWidgets(
      'edit affordance icon flips to `edit` when imageUrl is present',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _scaffold(
            const BbAvatarUpload(
              imageUrl: 'https://example.com/avatar.png',
              initials: 'AB',
              onImageSelected: _noop,
            ),
          ),
        );
        // First frame — Image.network triggers a fetch we deliberately
        // don't await; just confirm the widget tree shape.
        final Iterable<BbIcon> icons = tester.widgetList<BbIcon>(
          find.byType(BbIcon),
        );
        expect(icons.any((BbIcon i) => i.name == 'edit'), isTrue);
        expect(icons.any((BbIcon i) => i.name == 'add_a_photo'), isFalse);
      },
    );

    testWidgets('isUploading=true shows BbSpinner overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbAvatarUpload(
            imageUrl: null,
            initials: 'AB',
            isUploading: true,
            onImageSelected: _noop,
          ),
        ),
      );
      // Drive the AnimatedSwitcher crossfade past its `BBMotion.fast`
      // duration; can't `pumpAndSettle` because the spinner's
      // CircularProgressIndicator animation never settles.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(BbSpinner), findsOneWidget);
    });

    testWidgets('isUploading=false (idle) hides the spinner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbAvatarUpload(
            imageUrl: null,
            initials: 'AB',
            isUploading: false,
            onImageSelected: _noop,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(BbSpinner), findsNothing);
    });

    testWidgets('semantic button label exposed (default + override)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbAvatarUpload(
            imageUrl: null,
            initials: 'AB',
            onImageSelected: _noop,
          ),
        ),
      );

      final Semantics semantics = tester.widget<Semantics>(
        find
            .byWidgetPredicate(
              (Widget w) =>
                  w is Semantics &&
                  w.properties.label == 'Change profile photo',
            )
            .first,
      );
      expect(semantics.properties.button, isTrue);

      await tester.pumpWidget(
        _scaffold(
          const BbAvatarUpload(
            imageUrl: null,
            initials: 'AB',
            semanticLabel: 'Override',
            onImageSelected: _noop,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.label == 'Override',
        ),
        findsOneWidget,
      );
    });

    // We deliberately do NOT exercise an actual tap-to-pick path here:
    // `image_picker` requires a platform plugin that flutter_test does not
    // provide. The picker invocation logic is identical to the legacy
    // ProfileImagePicker (audit/103 §3.4 Phase 1.4 paragraph documents the
    // mirror-vs-wrap finding) and is exercised in screen-level integration
    // tests landed alongside the consuming screen migrations.
  });
}
