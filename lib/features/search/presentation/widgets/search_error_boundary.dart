import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Error boundary widget for search feature
///
/// Catches and handles errors gracefully, preventing app crashes
/// and providing helpful error messages to users
class SearchErrorBoundary extends StatefulWidget {
  const SearchErrorBoundary({
    required this.child,
    this.onError,
    super.key,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<SearchErrorBoundary> createState() => _SearchErrorBoundaryState();
}

class _SearchErrorBoundaryState extends State<SearchErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Set up error handler
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
        widget.onError?.call(details.exception, details.stack ?? StackTrace.current);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorUI(context);
    }

    return widget.child;
  }

  Widget _buildErrorUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Error title
              Text(
                'Ups! Nešto je pošlo po zlu',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceM),

              // Error message
              Text(
                _getErrorMessage(_error),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceXXL),

              // Action buttons
              Column(
                children: [
                  PremiumButton.primary(
                    label: 'Pokušaj ponovo',
                    icon: Icons.refresh,
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _stackTrace = null;
                      });
                    },
                  ),

                  const SizedBox(height: AppDimensions.spaceM),

                  PremiumButton.outline(
                    label: 'Nazad na početnu',
                    icon: Icons.home,
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),

              // Debug info (only in debug mode)
              if (_stackTrace != null) ...[
                const SizedBox(height: AppDimensions.spaceXXL),
                ExpansionTile(
                  title: const Text('Debug Info'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceM),
                      color: AppColors.surfaceVariantLight,
                      child: SelectableText(
                        _stackTrace.toString(),
                        style: AppTypography.small.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object? error) {
    if (error == null) {
      return 'Došlo je do nepoznate greške.';
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'Provjerite internet konekciju i pokušajte ponovo.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Zahtjev je trajao predugo. Pokušajte ponovo.';
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('query')) {
      return 'Problem sa bazom podataka. Pokušajte ponovo kasnije.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('unauthorized')) {
      return 'Nemate dozvolu za ovu akciju.';
    }

    // Generic error
    return 'Došlo je do greške. Pokušajte ponovo.';
  }
}

/// Error boundary for async operations
///
/// Use this to wrap async operations and show error UI
class AsyncErrorBoundary<T> extends StatelessWidget {
  const AsyncErrorBoundary({
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    super.key,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Error
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              _buildDefaultError(context, snapshot.error!);
        }

        // Success
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        // No data
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Greška',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              error.toString(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
