import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

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

  const ErrorBoundary({super.key, required this.child, this.errorBuilder, this.onError});

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

/// Default error widget shown when error occurs
class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const _DefaultErrorWidget({required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[100];
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final errorColor = isDark ? Colors.red[300] : Colors.red[700];

    return Material(
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: errorColor, semanticLabel: 'Error icon'),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We encountered an unexpected error. Please try again.',
                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (errorColor ?? Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: errorColor ?? Colors.red),
                  ),
                  child: Text(
                    errorDetails.exception.toString(),
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: errorColor),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Try to navigate back using go_router
                  // If that fails, try to go to home
                  try {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // If we can't pop, go to home/dashboard
                      context.go('/owner/dashboard');
                    }
                  } catch (e) {
                    // Last resort: try to go home
                    try {
                      context.go('/owner/dashboard');
                    } catch (e2) {
                      // If all else fails, just log the error
                      debugPrint('Error navigating back: $e2');
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      ),
    );
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
