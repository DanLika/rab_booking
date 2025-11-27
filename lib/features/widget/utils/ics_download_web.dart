/// Web implementation of ICS file download
///
/// This file uses dart:html which is ONLY available on web platform.
/// Flutter automatically excludes this file from mobile/desktop builds
/// via conditional imports in ics_download.dart.
///
/// Implementation:
/// 1. Converts content string to UTF-8 bytes
/// 2. Creates a Blob with MIME type 'text/calendar'
/// 3. Generates a temporary object URL for the blob
/// 4. Creates a hidden anchor element and triggers download
/// 5. Cleans up by revoking the temporary URL
library;

// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

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
    // 1. Convert content string to UTF-8 bytes
    final bytes = utf8.encode(content);

    // 2. Create a Blob with MIME type 'text/calendar'
    // This tells the browser to treat it as an iCalendar file
    final blob = html.Blob([bytes], 'text/calendar');

    // 3. Generate a temporary object URL for the blob
    // This creates a URL like: blob:http://example.com/uuid
    final url = html.Url.createObjectUrlFromBlob(blob);

    // 4. Create a hidden anchor element and trigger download
    // The 'download' attribute forces browser to download instead of navigate
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    // 5. Clean up - revoke the temporary URL to free memory
    // Important: Prevents memory leaks in long-running web apps
    html.Url.revokeObjectUrl(url);
  } catch (e, stackTrace) {
    // Log the full error with stack trace for debugging
    // ignore: avoid_print
    print('ICS Download Error: $e\n$stackTrace');
    // Rethrow with context - original stack trace is logged above
    throw Exception('Failed to download ICS file in browser: $e');
  }
}
