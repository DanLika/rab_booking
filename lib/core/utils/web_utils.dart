/// Platform-agnostic web utilities.
/// Uses conditional imports to provide web-specific functionality
/// while maintaining compatibility with mobile/desktop platforms.
///
/// Usage:
/// ```dart
/// import 'package:rab_booking/core/utils/web_utils.dart';
///
/// // Replace URL without navigation (web only, no-op on mobile)
/// replaceUrlState('/new-path?param=value');
///
/// // Navigate to external URL (web only)
/// navigateToUrl('https://checkout.stripe.com/...');
/// ```

export 'web_utils_stub.dart'
    if (dart.library.js_interop) 'web_utils_web.dart';
