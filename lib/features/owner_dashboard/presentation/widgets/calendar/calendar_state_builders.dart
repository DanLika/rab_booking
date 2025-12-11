import 'package:flutter/material.dart';
import '../../../../../shared/widgets/animations/skeleton_loader.dart';

/// Static builder methods for calendar state UI
/// Shared across Week, Month, and Timeline calendar views
class CalendarStateBuilders {
  CalendarStateBuilders._(); // Private constructor to prevent instantiation

  /// Build empty state when no units are found
  static Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text('No units found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Add units to your properties to see them in the calendar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build loading state with skeleton loaders
  static Widget buildLoadingState() {
    return Column(
      children: [
        // Header skeleton
        const SkeletonLoader(width: double.infinity, height: 60),
        const SizedBox(height: 8),
        // Grid skeleton
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SkeletonLoader(width: double.infinity, height: 60),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build error state with retry button
  static Widget buildErrorState(
    BuildContext context,
    Object error,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading calendar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
