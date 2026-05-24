import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../../../../core/utils/web_utils.dart' as web_utils;

/// Measures the rendered height of a child subtree and posts it to the
/// parent window (via `web_utils.sendIframeHeight`) so an embedding iframe
/// can resize itself.
///
/// Threshold: only posts when the height changed by more than 10 px since
/// the last successful post. 32 px of padding is added for visual breathing
/// room before posting.
///
/// Wire-up: attach [contentKey] to the column / scroll body you want to
/// measure, and call [send] whenever the layout may have changed. The class
/// schedules its own post-frame callback, so calling from `build()` or
/// inside listeners is safe.
///
/// Web-only: no-op on non-web platforms.
class IframeHeightReporter {
  final GlobalKey contentKey = GlobalKey();
  double _lastSentHeight = 0;
  bool _disposed = false;

  /// Schedule a height measurement after the next frame.
  ///
  /// No-op if disposed, off-web, or the render box is missing / has invalid
  /// dimensions. Swallows internal exceptions (post-frame callbacks can
  /// fire after a context goes invalid).
  void send() {
    if (_disposed || !kIsWeb) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;

      try {
        final renderBox =
            contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) return;

        final size = renderBox.size;
        if (!size.height.isFinite ||
            !size.width.isFinite ||
            size.height <= 0 ||
            size.width <= 0) {
          return;
        }

        final totalHeight = size.height + 32;
        if (!totalHeight.isFinite || totalHeight <= 0) return;

        if ((totalHeight - _lastSentHeight).abs() > 10) {
          _lastSentHeight = totalHeight;
          web_utils.sendIframeHeight(totalHeight);
        }
      } catch (_) {
        // Render box may be disposed or context may be invalid by the time
        // this post-frame callback runs — silently skip.
      }
    });
  }

  /// Stop scheduling new post-frame callbacks. Call from the owning state's
  /// `dispose()` to prevent stale callbacks firing after teardown.
  void dispose() {
    _disposed = true;
  }
}
