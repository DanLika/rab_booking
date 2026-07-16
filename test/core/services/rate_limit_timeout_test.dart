// Guards the login-hang class found during PROD booking-detail testing
// (2026-07-16), same signature as #909: a Firebase call that never RESOLVES
// — rather than throwing — held the login screen forever. The documented
// "fail-open" catch is dead code against a hang, because a catch cannot fire
// on a call that never returns.
//
// The bite: without the .timeout() in RateLimitService.checkRateLimit, these
// tests hang instead of failing.

import 'dart:async';

import 'package:bookbed/core/services/rate_limit_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

void main() {
  group('RateLimitService.checkRateLimit — hang protection', () {
    late _MockFunctions functions;
    late _MockCallable callable;
    late RateLimitService service;

    setUp(() {
      functions = _MockFunctions();
      callable = _MockCallable();
      when(() => functions.httpsCallable(any())).thenReturn(callable);
      service = RateLimitService(functions: functions);
    });

    test('fails open when the callable never resolves', () async {
      // A callable that hangs forever — the real-world shape of the bug.
      when(() => callable.call<Map<dynamic, dynamic>>(any())).thenAnswer(
        (_) => Completer<HttpsCallableResult<Map<dynamic, dynamic>>>().future,
      );

      // Must return (fail-open => null), not hang. The 10s guard is the test
      // harness's own net: if the timeout regresses, this fails loudly rather
      // than hanging the whole suite.
      final result = await service
          .checkRateLimit('hang@example.com')
          .timeout(const Duration(seconds: 10));

      expect(result, isNull, reason: 'a hung lockout lookup must fail open');
    });

    test('still fails open when the callable throws', () async {
      when(() => callable.call<Map<dynamic, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(message: 'boom', code: 'unavailable'),
      );

      final result = await service.checkRateLimit('throw@example.com');

      expect(result, isNull);
    });
  });
}
