import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Loading indicator with optional message
///
/// Example usage:
/// ```dart
/// LoadingIndicator()
/// ```
///
/// ```dart
/// LoadingIndicator(message: 'Loading properties...')
/// ```
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    this.message,
    this.size = 40.0,
    super.key,
  });

  /// Optional loading message
  final String? message;

  /// Size of the circular indicator
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spaceS), // 16px from design system
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay
///
/// Example usage:
/// ```dart
/// LoadingOverlay(
///   isLoading: isProcessing,
///   child: YourContentWidget(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    this.message,
    super.key,
  });

  /// Whether loading overlay should be shown
  final bool isLoading;

  /// Child widget to overlay
  final Widget child;

  /// Optional loading message
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: LoadingIndicator(message: message),
          ),
      ],
    );
  }
}

/// Shimmer loading placeholder
///
/// Example usage:
/// ```dart
/// ShimmerLoading(
///   width: 200,
///   height: 20,
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      AppColors.surfaceVariantDark,
                      AppColors.surfaceDark,
                      AppColors.surfaceVariantDark,
                    ]
                  : [
                      AppColors.shimmerBase,
                      AppColors.shimmerHighlight,
                      AppColors.shimmerBase,
                    ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
