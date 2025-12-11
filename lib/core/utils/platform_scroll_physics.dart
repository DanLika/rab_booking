import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Platform-aware scroll physics helper
///
/// On web: Uses ClampingScrollPhysics for better performance (no elastic overscroll)
/// On mobile: Uses BouncingScrollPhysics for native iOS/Android feel
///
/// This improves web performance by:
/// - Reducing paint operations during scroll
/// - Eliminating elastic overscroll animations that cause jank on web
class PlatformScrollPhysics {
  PlatformScrollPhysics._();

  /// Returns appropriate scroll physics based on platform
  ///
  /// Web: ClampingScrollPhysics (no elastic bounce)
  /// Mobile: BouncingScrollPhysics (native feel)
  static ScrollPhysics get adaptive {
    return kIsWeb
        ? const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// Returns clamping physics (always, regardless of platform)
  /// Useful when you specifically want no bounce effect
  static ScrollPhysics get clamping {
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// Returns bouncing physics (always, regardless of platform)
  /// Useful when you specifically want elastic effect
  static ScrollPhysics get bouncing {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// Returns whether the current platform is web
  static bool get isWeb => kIsWeb;

  /// Recommended debounce duration for scroll listeners on web
  /// Returns Duration.zero on mobile (no debounce needed)
  static Duration get scrollDebounceDelay {
    return kIsWeb
        ? const Duration(milliseconds: 100)
        : Duration.zero;
  }
}
