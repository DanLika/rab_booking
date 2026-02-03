/// Web implementation of ICS file download
///
/// This file uses package:web + dart:js_interop which are the modern
/// replacements for the deprecated dart:html library.
/// Flutter automatically excludes this file from mobile/desktop builds
/// via conditional imports in ics_download.dart.
///
/// Implementation:
/// 1. Converts content string to a JS Blob with MIME type 'text/calendar'
/// 2. Generates a temporary object URL for the blob
/// 3. Creates a hidden anchor element and triggers download
/// 4. Cleans up by revoking the temporary URL
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/logging_service.dart';

/// Downloads an ICS file in the browser
///
/// [content] - The ICS file content as a string (RFC 5545 format)
/// [filename] - The filename to save as (e.g., 'booking.ics')
///
/// Throws an [Exception] if the download fails.
///
/// Example:
/// ```dart
/// await downloadIcsFile(icsContent, 'my-booking.ics');
/// ```
Future<void> downloadIcsFile(String content, String filename) async {
  try {
    // 1. Create a Blob with MIME type 'text/calendar'
    // Passing the string directly; Blob handles UTF-8 encoding
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: 'text/calendar;charset=utf-8'),
    );

    // 2. Generate a temporary object URL for the blob
    // This creates a URL like: blob:http://example.com/uuid
    final url = web.URL.createObjectURL(blob);

    // 3. Create a hidden anchor element and trigger download
    // The 'download' attribute forces browser to download instead of navigate
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    anchor.click();

    // 4. Clean up - revoke the temporary URL to free memory
    // Important: Prevents memory leaks in long-running web apps
    web.URL.revokeObjectURL(url);
  } catch (e, stackTrace) {
    // Log error using LoggingService instead of print
    await LoggingService.logError(
      '[ICS Download] Failed to download ICS file in browser',
      e,
      stackTrace,
    );
    // Throw typed exception for better error handling upstream
    throw FileException.icsDownloadFailedWeb(e);
  }
}
