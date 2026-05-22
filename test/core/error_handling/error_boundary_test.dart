import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/error_handling/error_boundary.dart';
import 'package:bookbed/core/config/router_owner.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  testWidgets('ErrorBoundary fallback to global navigator for Go Home', (WidgetTester tester) async {
    bool fallbackNavigated = false;

    // Save the test framework's error handler
    final originalTestOnError = FlutterError.onError;

    // Override it so the test doesn't fail when an error is reported
    FlutterError.onError = (details) {};

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == '/owner/dashboard') {
            fallbackNavigated = true;
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Dashboard')));
          }
          return null;
        },
        home: Scaffold(
          body: ErrorBoundary(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FlutterError.reportError(
                      FlutterErrorDetails(
                        exception: Exception('Test Error'),
                        library: 'Test Library',
                      ),
                    );
                  },
                  child: const Text('Trigger Error'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Trigger the error
    await tester.tap(find.text('Trigger Error'));

    // ErrorBoundary's handler schedules a post frame callback
    await tester.pump();

    // Pumping multiple times for the animation in _DefaultErrorWidget
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Restore the original test error handler
    FlutterError.onError = originalTestOnError;

    // Verify Error UI is shown
    expect(find.text('Go Home'), findsOneWidget);

    // Now tap Go Home
    await tester.tap(find.text('Go Home'));

    await tester.pumpAndSettle();

    expect(fallbackNavigated, isTrue);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('ErrorBoundary primary navigation uses GoRouter for Go Home', (WidgetTester tester) async {
    // Save the test framework's error handler
    final originalTestOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    final mockGoRouter = MockGoRouter();
    // when(() => mockGoRouter.go('/owner/dashboard')).thenReturn(null); // return type is void

    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FlutterError.reportError(
                        FlutterErrorDetails(
                          exception: Exception('Test Error'),
                          library: 'Test Library',
                        ),
                      );
                    },
                    child: const Text('Trigger Error'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Trigger the error
    await tester.tap(find.text('Trigger Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Restore the original test error handler
    FlutterError.onError = originalTestOnError;

    expect(find.text('Go Home'), findsOneWidget);

    await tester.tap(find.text('Go Home'));
    await tester.pumpAndSettle();

    verify(() => mockGoRouter.go('/owner/dashboard')).called(1);
  });

  testWidgets('ErrorBoundary Try Again fallback to global navigator', (WidgetTester tester) async {
    bool fallbackNavigated = false;

    // Save the test framework's error handler
    final originalTestOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == '/owner/dashboard') {
            fallbackNavigated = true;
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Dashboard')));
          }
          return null;
        },
        home: Scaffold(
          body: ErrorBoundary(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    FlutterError.reportError(
                      FlutterErrorDetails(
                        exception: Exception('Test Error'),
                        library: 'Test Library',
                      ),
                    );
                  },
                  child: const Text('Trigger Error'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Trigger the error
    await tester.tap(find.text('Trigger Error'));

    // ErrorBoundary's handler schedules a post frame callback
    await tester.pump();

    // Pumping multiple times for the animation in _DefaultErrorWidget
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Restore the original test error handler
    FlutterError.onError = originalTestOnError;

    // Verify Error UI is shown
    expect(find.text('Try Again'), findsOneWidget);

    // Now tap Try Again
    await tester.tap(find.text('Try Again'));

    await tester.pumpAndSettle();

    // It should try to pop but there's nothing to pop, so it goes to home.
    expect(fallbackNavigated, isTrue);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('ErrorBoundary Try Again primary navigation uses GoRouter', (WidgetTester tester) async {
    // Save the test framework's error handler
    final originalTestOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    final mockGoRouter = MockGoRouter();
    when(() => mockGoRouter.canPop()).thenReturn(true);
    // when(() => mockGoRouter.pop()).thenReturn(null); // return type is void

    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: Scaffold(
            body: ErrorBoundary(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FlutterError.reportError(
                        FlutterErrorDetails(
                          exception: Exception('Test Error'),
                          library: 'Test Library',
                        ),
                      );
                    },
                    child: const Text('Trigger Error'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Trigger the error
    await tester.tap(find.text('Trigger Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Restore the original test error handler
    FlutterError.onError = originalTestOnError;

    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    verify(() => mockGoRouter.pop()).called(1);
  });

  testWidgets('ErrorBoundary Try Again global navigator pop', (WidgetTester tester) async {
    // Save the test framework's error handler
    final originalTestOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: rootNavigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  // Push a route that has the ErrorBoundary
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: ErrorBoundary(
                          child: Builder(
                            builder: (context) {
                              return ElevatedButton(
                                onPressed: () {
                                  FlutterError.reportError(
                                    FlutterErrorDetails(
                                      exception: Exception('Test Error'),
                                      library: 'Test Library',
                                    ),
                                  );
                                },
                                child: const Text('Trigger Error'),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Push Route'),
              );
            },
          ),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Push the route
    await tester.tap(find.text('Push Route'));
    await tester.pumpAndSettle();

    // Now we are on the new route
    expect(find.text('Trigger Error'), findsOneWidget);

    // Trigger the error
    await tester.tap(find.text('Trigger Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Restore the original test error handler
    FlutterError.onError = originalTestOnError;

    // Verify Error UI is shown
    expect(find.text('Try Again'), findsOneWidget);

    // Now tap Try Again
    await tester.tap(find.text('Try Again'));

    await tester.pumpAndSettle();

    // The route should have been popped! So we should see 'Push Route' again.
    expect(find.text('Push Route'), findsOneWidget);
  });
}
