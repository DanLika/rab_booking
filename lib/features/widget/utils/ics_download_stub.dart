/// Mobile/Desktop implementation of ICS file download
///
/// This file uses Flutter packages (path_provider, share_plus) which work
/// on mobile and desktop platforms. It does NOT use dart:html.
///
/// Implementation:
/// 1. Gets the platform's temporary directory
/// 2. Creates a .ics file in the temp directory
/// 3. Writes the ICS content to the file
/// 4. Opens the native share sheet to let user save/share the file
///
/// Platforms:
/// - iOS: Opens iOS share sheet (Mail, Messages, Save to Files, etc.)
/// - Android: Opens Android share chooser (Gmail, Drive, etc.)
/// - macOS: Opens macOS share menu
/// - Windows/Linux: Opens file save dialog or share options
library;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Downloads/shares an ICS file on mobile/desktop platforms
///
/// [content] - The ICS file content as a string (RFC 5545 format)
/// [filename] - The filename to save as (e.g., 'booking.ics')
///
/// On mobile, this opens the native share sheet where the user can:
/// - Save to Files app
/// - Email the file
/// - Share via messaging apps
/// - Add to calendar app
///
/// Throws an [Exception] if the share fails.
///
/// Example:
/// ```dart
/// await downloadIcsFile(icsContent, 'my-booking.ics');
/// ```
Future<void> downloadIcsFile(String content, String filename) async {
  try {
    // 1. Get the platform's temporary directory
    // This works on all platforms (iOS, Android, macOS, Windows, Linux)
    final tempDir = await getTemporaryDirectory();

    // 2. Create file path in temp directory
    final file = File('${tempDir.path}/$filename');

    // 3. Write ICS content to the file
    await file.writeAsString(content);

    // 4. Share the file via native share sheet
    // XFile is a cross-platform file representation from cross_file package
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Add this booking to your calendar',
      subject: 'Booking Confirmation',
    );

    // Note: share_plus doesn't throw on user cancel
    // The share sheet will just close if user cancels
  } catch (e) {
    // Wrap error with context for better debugging
    throw Exception('Failed to share ICS file: $e');
  }
}
