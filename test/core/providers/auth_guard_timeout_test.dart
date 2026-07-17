// Guards BOTH pre-auth rate-limit callables against the #909/#933 class: a
// Firebase call that never RESOLVES — rather than throwing — leaves the user
// on a spinner forever, because a `catch` cannot fire on a call that never
// returns. Each site documents a "fail-open" intent that is dead code without
// a timeout.
//
// #933 fixed the LOGIN guard and missed its REGISTRATION twin two methods
// below it in the same file. This pins both so the pair cannot drift again.
//
// WHY A SOURCE SCAN, not a behaviour test: both methods build their own
// `FirebaseFunctions.instanceFor(...)` inline and are not injectable, and the
// register harness overrides `checkCloudRegistrationRateLimit` to a no-op —
// so no test can drive the real callable without refactoring the auth path.
// The contract worth pinning is "this await is bounded and its timeout fails
// open", which is readable from the source. (RateLimitService, which IS
// injectable, gets a real behaviour test in rate_limit_timeout_test.dart.)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const emailAuth = 'lib/core/providers/enhanced_auth_email.dart';
  const session = 'lib/core/providers/enhanced_auth_session.dart';

  late String emailSrc;
  late String sessionSrc;

  setUpAll(() {
    emailSrc = File(emailAuth).readAsStringSync();
    sessionSrc = File(session).readAsStringSync();
  });

  /// The guard block around a given `httpsCallable('<name>')` site: from the
  /// callable up to the end of its catch chain. Anchored on the callable
  /// itself, NOT on a method name — `checkLoginRateLimit` is an inline closure
  /// and `checkCloudRegistrationRateLimit` appears as a call site before its
  /// declaration, so a name-based `indexOf` slices the wrong region.
  String guardAround(String src, String callableName) {
    final anchor = "httpsCallable('$callableName')";
    final start = src.indexOf(anchor);
    expect(
      start,
      greaterThan(-1),
      reason: '$callableName call site must exist',
    );
    return src.substring(start, (start + 900).clamp(0, src.length));
  }

  group('pre-auth guards are bounded (#909/#933 class)', () {
    test('LOGIN rate-limit callable has a timeout + fail-open branch', () {
      final body = guardAround(emailSrc, 'checkLoginRateLimit');
      expect(
        body.contains('.timeout(_kAuthGuardTimeout)'),
        isTrue,
        reason: 'an unbounded await here strands the login screen',
      );
      expect(
        body.contains('on TimeoutException'),
        isTrue,
        reason:
            'the catch is typed to FirebaseFunctionsException — a bare '
            '.timeout() would escape it and show the user an error instead '
            'of failing open',
      );
    });

    // THE BITE: this twin shipped un-timeouted while its login sibling was
    // fixed. Same file, same shape, same documented fail-open.
    test(
      'REGISTRATION rate-limit callable has a timeout + fail-open branch',
      () {
        final body = guardAround(emailSrc, 'checkRegistrationRateLimit');
        expect(
          body.contains('.timeout(_kAuthGuardTimeout)'),
          isTrue,
          reason: 'an unbounded await here strands the register screen',
        );
        expect(
          body.contains('on TimeoutException'),
          isTrue,
          reason: 'same typed-catch trap as the login twin',
        );
      },
    );

    test('both twins share one timeout constant', () {
      expect(
        RegExp(r'_kAuthGuardTimeout').allMatches(emailSrc).length,
        greaterThanOrEqualTo(3),
        reason: 'declaration + both call sites — no per-site magic numbers',
      );
    });
  });

  group('auth-recovery path is bounded', () {
    // forgot_password_screen sets `_isLoading = true` and clears it only in its
    // try/catch. A hung callable never throws, so the spinner never clears —
    // on the path taken by someone who already cannot log in.
    test('sendPasswordResetEmail callable is bounded', () {
      final body = guardAround(sessionSrc, 'sendPasswordResetEmail');
      expect(
        body.contains('withCloudFunctionTimeout'),
        isTrue,
        reason: 'a hung reset traps the user on a permanent spinner',
      );
    });
  });
}
