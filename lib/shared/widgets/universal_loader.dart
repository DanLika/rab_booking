import 'dart:ui';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/widgets/auth_logo_icon.dart';

/// Universal loading widget for the entire app
///
/// A flexible loading widget that can be used in multiple scenarios:
/// - As a full-screen overlay (like LoginLoadingOverlay)
/// - As an inline widget in specific sections
/// - With or without blur effect
/// - With custom messages and sizes
///
/// Features:
/// - BookBed logo with proper dark/light mode support
/// - Optional backdrop blur (glassmorphism)
/// - Configurable size (small, medium, large)
/// - Optional message display
/// - Debounced rendering to prevent flicker
///
/// Usage Examples:
/// ```dart
/// // Full-screen overlay with blur
/// UniversalLoader.overlay(message: 'Loading...')
///
/// // Inline centered loader
/// UniversalLoader.centered(size: LoaderSize.medium)
///
/// // Small loader for buttons/cards
/// UniversalLoader.inline(size: LoaderSize.small)
/// ```
class UniversalLoader extends StatefulWidget {
  /// Display mode: overlay (full-screen with optional blur) or inline (embedded in layout)
  final LoaderMode mode;

  /// Size of the logo and progress indicator
  final LoaderSize size;

  /// Optional message to display below the loader
  final String? message;

  /// Whether to show backdrop blur (only applies to overlay mode)
  final bool withBlur;

  /// Debounce duration - only show loader if loading takes longer than this
  /// Set to Duration.zero to disable debouncing
  final Duration debounceDuration;

  const UniversalLoader({
    super.key,
    this.mode = LoaderMode.inline,
    this.size = LoaderSize.medium,
    this.message,
    this.withBlur = true,
    this.debounceDuration = const Duration(milliseconds: 50),
  });

  // ============================================================
  // SEMANTIC FACTORIES - Use these! Auto-select correct size
  // ============================================================

  /// For auth screens: login, register, password reset
  /// Full-screen overlay with blur, medium size
  factory UniversalLoader.forAuth({String? message}) {
    return UniversalLoader(mode: LoaderMode.overlay, message: message);
  }

  /// For dialogs: confirmation, edit, create dialogs
  /// Centered, small size (dialogs are already small)
  factory UniversalLoader.forDialog({String? message}) {
    return UniversalLoader(
      mode: LoaderMode.centered,
      size: LoaderSize.small,
      message: message,
    );
  }

  /// For sections: dashboard cards, list sections, panels
  /// Centered, medium size
  factory UniversalLoader.forSection({String? message}) {
    return UniversalLoader(mode: LoaderMode.centered, message: message);
  }

  /// For full screen: initial app load, route transitions
  /// Full-screen overlay with blur, large size
  factory UniversalLoader.forScreen({String? message}) {
    return UniversalLoader(
      mode: LoaderMode.overlay,
      size: LoaderSize.large,
      message: message,
    );
  }

  /// For buttons: submit buttons, refresh icons
  /// Inline, small size, no message (too small)
  factory UniversalLoader.forButton() {
    return const UniversalLoader(
      size: LoaderSize.small,
      debounceDuration: Duration.zero, // No delay for buttons
    );
  }

  // ============================================================
  // ADVANCED FACTORIES - For custom control (rarely needed)
  // ============================================================

  /// Custom overlay loader
  factory UniversalLoader.overlay({
    String? message,
    LoaderSize size = LoaderSize.medium,
    bool withBlur = true,
  }) {
    return UniversalLoader(
      mode: LoaderMode.overlay,
      size: size,
      message: message,
      withBlur: withBlur,
    );
  }

  /// Custom centered loader
  factory UniversalLoader.centered({
    String? message,
    LoaderSize size = LoaderSize.medium,
  }) {
    return UniversalLoader(
      mode: LoaderMode.centered,
      size: size,
      message: message,
    );
  }

  /// Custom inline loader
  factory UniversalLoader.inline({
    LoaderSize size = LoaderSize.small,
    String? message,
  }) {
    return UniversalLoader(size: size, message: message);
  }

  @override
  State<UniversalLoader> createState() => _UniversalLoaderState();
}

class _UniversalLoaderState extends State<UniversalLoader> {
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    // Debounce: Only show if loading takes longer than specified duration
    if (widget.debounceDuration > Duration.zero) {
      Future.delayed(widget.debounceDuration, () {
        if (mounted) {
          setState(() {
            _shouldShow = true;
          });
        }
      });
    } else {
      _shouldShow = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final content = _buildLoaderContent(isDarkMode, theme);

    switch (widget.mode) {
      case LoaderMode.overlay:
        return _buildOverlay(isDarkMode, content);
      case LoaderMode.centered:
        return Center(child: content);
      case LoaderMode.inline:
        return content;
    }
  }

  Widget _buildOverlay(bool isDarkMode, Widget content) {
    final background = Container(
      color: (isDarkMode ? Colors.black : Colors.white).withAlpha(200),
      width: double.infinity,
      height: double.infinity,
      child: Center(child: content),
    );

    if (widget.withBlur) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: background,
      );
    }

    return background;
  }

  Widget _buildLoaderContent(bool isDarkMode, ThemeData theme) {
    final dimensions = widget.size._dimensions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BookBed Logo
        AuthLogoIcon(size: dimensions.logoSize, isWhite: isDarkMode),
        SizedBox(height: dimensions.logoToIndicatorSpacing),

        // Progress Indicator
        SizedBox(
          width: dimensions.indicatorSize,
          height: dimensions.indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: dimensions.strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            backgroundColor: theme.colorScheme.primary.withAlpha(40),
          ),
        ),

        // Optional Message
        if (widget.message != null) ...[
          SizedBox(height: dimensions.indicatorToMessageSpacing),
          Text(
            widget.message!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: dimensions.messageFontSize,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Loader display modes
enum LoaderMode {
  /// Full-screen overlay with optional blur
  overlay,

  /// Centered within parent widget
  centered,

  /// Inline (no centering, just the loader widgets)
  inline,
}

/// Loader size presets
enum LoaderSize {
  /// Small size for buttons, cards, inline usage
  small,

  /// Medium size for sections, dialogs
  medium,

  /// Large size for full-screen overlays, splash screens
  large;

  _LoaderDimensions get _dimensions {
    switch (this) {
      case LoaderSize.small:
        return const _LoaderDimensions(
          logoSize: 40,
          logoToIndicatorSpacing: 16,
          indicatorSize: 30,
          strokeWidth: 2.5,
          indicatorToMessageSpacing: 16,
          messageFontSize: 12,
        );
      case LoaderSize.medium:
        return const _LoaderDimensions(
          logoSize: 60,
          logoToIndicatorSpacing: 24,
          indicatorSize: 40,
          strokeWidth: 3,
          indicatorToMessageSpacing: 24,
          messageFontSize: 14,
        );
      case LoaderSize.large:
        return const _LoaderDimensions(
          logoSize: 100,
          logoToIndicatorSpacing: 48,
          indicatorSize: 50,
          strokeWidth: 3,
          indicatorToMessageSpacing: 32,
          messageFontSize: 16,
        );
    }
  }
}

/// Internal dimensions class
class _LoaderDimensions {
  final double logoSize;
  final double logoToIndicatorSpacing;
  final double indicatorSize;
  final double strokeWidth;
  final double indicatorToMessageSpacing;
  final double messageFontSize;

  const _LoaderDimensions({
    required this.logoSize,
    required this.logoToIndicatorSpacing,
    required this.indicatorSize,
    required this.strokeWidth,
    required this.indicatorToMessageSpacing,
    required this.messageFontSize,
  });
}
