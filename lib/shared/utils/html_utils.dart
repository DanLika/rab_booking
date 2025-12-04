/// HTML escape utility for security
///
/// Prevents XSS (Cross-Site Scripting) attacks by escaping HTML special characters.
/// This is critical for safely embedding user input in HTML emails.
///
/// ## Usage
/// ```dart
/// final safeName = HtmlUtils.escapeHtml(booking.guestName);
/// final html = '<p>Welcome $safeName</p>'; // Safe from XSS
/// ```
///
/// ## Security Note
/// ALWAYS escape user input before embedding in HTML:
/// - Guest names
/// - Guest emails
/// - Guest phone numbers
/// - Booking notes
/// - Any other user-provided content
class HtmlUtils {
  /// Escape HTML special characters to prevent XSS attacks
  ///
  /// Converts dangerous HTML characters to their HTML entity equivalents:
  /// - `&` → `&amp;`
  /// - `<` → `&lt;`
  /// - `>` → `&gt;`
  /// - `"` → `&quot;`
  /// - `'` → `&#39;`
  ///
  /// This prevents user input from being interpreted as HTML/JavaScript.
  ///
  /// ## Example Attack Prevention
  /// ```dart
  /// // Malicious input
  /// final malicious = '<script>alert("XSS")</script>';
  ///
  /// // Without escaping (DANGEROUS):
  /// final bad = '<p>$malicious</p>';
  /// // Result: <p><script>alert("XSS")</script></p>  ← Script executes!
  ///
  /// // With escaping (SAFE):
  /// final safe = '<p>${HtmlUtils.escapeHtml(malicious)}</p>';
  /// // Result: <p>&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;</p>  ← Script is text
  /// ```
  ///
  /// @param text - Text that may contain HTML special characters (nullable)
  /// @returns Escaped text safe for HTML insertion, or empty string if null
  static String escapeHtml(String? text) {
    if (text == null || text.isEmpty) return '';

    return text
        .replaceAll('&', '&amp;') // Must be first to avoid double-escaping
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
