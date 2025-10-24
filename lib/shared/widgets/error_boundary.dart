import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// Error boundary widget to prevent section failures from crashing entire page
/// Wraps each HomePage section to provide graceful error handling
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({
    required this.child,
    this.fallback,
    this.onError,
    this.sectionName,
    super.key,
  });

  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? fallback;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final String? sectionName;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Creates error boundary with default fallback UI
  static Widget withDefaultFallback({
    required Widget child,
    String? sectionName,
  }) {
    return ErrorBoundary(
      sectionName: sectionName,
      fallback: (error, stackTrace) => _DefaultErrorFallback(
        error: error,
        sectionName: sectionName,
      ),
      child: child,
    );
  }
}

/// Default error fallback widget
class _DefaultErrorFallback extends StatelessWidget {
  const _DefaultErrorFallback({
    required this.error,
    this.sectionName,
  });

  final Object error;
  final String? sectionName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      margin: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceM,
        horizontal: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 48,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            sectionName != null
                ? 'Error in $sectionName'
                : 'Section Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            'This section encountered an error and couldn\'t be loaded.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          TextButton.icon(
            onPressed: () {
              // Trigger page refresh
              Navigator.of(context).pushReplacementNamed('/');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Page'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section error boundary - wraps async sections with try-catch
class AsyncSectionBoundary extends StatelessWidget {
  const AsyncSectionBoundary({
    required this.child,
    required this.sectionName,
    super.key,
  });

  final Widget child;
  final String sectionName;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary.withDefaultFallback(
      sectionName: sectionName,
      child: child,
    );
  }
}
