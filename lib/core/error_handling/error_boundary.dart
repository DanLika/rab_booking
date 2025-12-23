import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/gradient_extensions.dart';

/// Safely convert exception to string, handling null and edge cases
/// Prevents "Null check operator used on a null value" errors
String _safeExceptionToString(dynamic exception) {
  if (exception == null) {
    return 'Unknown error';
  }
  try {
    return exception.toString();
  } catch (e) {
    // If toString() itself throws, return a safe fallback
    return 'Error: Unable to display error details';
  }
}

/// Error Boundary Widget - Catches errors in widget tree and shows fallback UI
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: MyWidget(),
///   onError: (error, stackTrace) => print('Error: $error'),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  FlutterExceptionHandler? _originalOnError;

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      // Show error UI if error caught
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }
      return _DefaultErrorWidget(errorDetails: _errorDetails!);
    }

    // Return child directly - errors will be caught by global handler
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Set up error listener for this boundary
    _setupErrorListener();
  }

  void _setupErrorListener() {
    // Store original error handler as instance variable for cleanup
    _originalOnError = FlutterError.onError;

    // Override error handler for this boundary's scope
    FlutterError.onError = (FlutterErrorDetails details) {
      // Call original handler first
      _originalOnError?.call(details);

      // Capture error in this boundary
      // Use addPostFrameCallback to avoid setState during build
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorDetails = details;
            });
          }
        });
        widget.onError?.call(details);
      }
    };
  }

  @override
  void dispose() {
    // Restore original error handler to prevent memory leak
    if (_originalOnError != null) {
      FlutterError.onError = _originalOnError;
    }
    super.dispose();
  }
}

/// Default error widget shown when error occurs - with friendly animation
class _DefaultErrorWidget extends StatefulWidget {
  final FlutterErrorDetails errorDetails;

  const _DefaultErrorWidget({required this.errorDetails});

  @override
  State<_DefaultErrorWidget> createState() => _DefaultErrorWidgetState();
}

class _DefaultErrorWidgetState extends State<_DefaultErrorWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Material(
      child: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated illustration with float and rotate effect
                    // Both animations run simultaneously (delay: Duration.zero)
                    _buildErrorIllustration(primaryColor)
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .moveY(
                          duration: const Duration(seconds: 3),
                          begin: -8,
                          end: 8,
                          curve: Curves.easeInOut,
                        )
                        .rotate(
                          delay: Duration.zero, // Run simultaneously with moveY
                          duration: const Duration(seconds: 3),
                          begin: -0.05 / (2 * 3.14159), // Convert radians to turns
                          end: 0.05 / (2 * 3.14159),
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Oops! Something went wrong',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'Don\'t worry, this happens sometimes. You can try again or go back to the dashboard.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(
                          (0.7 * 255).toInt(),
                        ),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Debug info (only in debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withAlpha(
                            (0.3 * 255).toInt(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withAlpha(
                              (0.5 * 255).toInt(),
                            ),
                          ),
                        ),
                        child: Text(
                          _safeExceptionToString(widget.errorDetails.exception),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.error,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        // Go Home button (guaranteed to work)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToHome(context),
                            icon: const Icon(Icons.home_outlined, size: 20),
                            label: const Text('Go Home'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Try Again button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: context.gradients.brandPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _tryAgain(context),
                              icon: const Icon(Icons.refresh, size: 20),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIllustration(Color primaryColor) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withAlpha((0.1 * 255).toInt()),
            ),
          ),
          // Document/page icon
          Container(
            width: 60,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lines representing content
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: EdgeInsets.only(
                      left: 10,
                      right: i == 2 ? 20 : 10,
                      top: i == 0 ? 0 : 6,
                    ),
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
          // Warning badge
          Positioned(
            right: 15,
            bottom: 15,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFFA726,
                    ).withAlpha((0.4 * 255).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Direct navigation to dashboard - always works
    try {
      // Defensive check: ensure GoRouter is available before navigation
      // Use GoRouter.maybeOf to safely check if router is available
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go('/owner/dashboard');
      } else {
        // GoRouter not available, use Navigator as fallback
        throw Exception('GoRouter not found in context');
      }
    } catch (e) {
      debugPrint('Error navigating to home: ${_safeExceptionToString(e)}');
      // If go_router fails completely, use Navigator
      try {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/owner/dashboard', (_) => false);
      } catch (navError) {
        // If Navigator also fails, just log the error
        debugPrint(
          'Navigator fallback also failed: ${_safeExceptionToString(navError)}',
        );
      }
    }
  }

  void _tryAgain(BuildContext context) {
    try {
      // Defensive check: ensure GoRouter is available before navigation
      final router = GoRouter.maybeOf(context);
      if (router != null && context.canPop()) {
        context.pop();
      } else {
        // Can't go back or router not available, go home instead
        _navigateToHome(context);
      }
    } catch (e) {
      debugPrint('Error trying again: ${_safeExceptionToString(e)}');
      _navigateToHome(context);
    }
  }
}

/// Global error handler - sets up Flutter error handling
class GlobalErrorHandler {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack);
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true; // Mark as handled
    };
  }

  static void _logError(dynamic error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('GlobalErrorHandler caught error: $error');
      if (stack != null) {
        debugPrint('Stack trace:\n$stack');
      }
    }

    // Production error tracking is handled by ErrorHandler.logError()
    // which sends to Firebase Crashlytics
  }
}
