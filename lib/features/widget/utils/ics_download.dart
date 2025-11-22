/// Platform-agnostic ICS file download interface
///
/// This library uses conditional imports to select the correct implementation
/// based on the target platform:
///
/// - **Web:** Browser download via Blob + Anchor element (dart:html)
/// - **Mobile/Desktop:** Share dialog via share_plus package
///
/// Usage:
/// ```dart
/// import 'package:rab_booking/features/widget/utils/ics_download.dart';
///
/// await downloadIcsFile(icsContent, 'booking.ics');
/// ```
///
/// The implementation is automatically selected at compile-time based on
/// the availability of dart:html library (web-only).
library;

// Default export: Mobile/Desktop implementation (stub)
// Override: If dart:html is available (web), use web implementation
export 'ics_download_stub.dart'
    if (dart.library.html) 'ics_download_web.dart';
