/// Utility functions for generating URL-friendly slugs
///
/// Slugs are used to create SEO-friendly URLs for properties and units
/// Example: "Villa Jasko - Apartman 6" → "villa-jasko-apartman-6"
library;

/// Cached character replacements for slug generation (Croatian/European characters)
const _charReplacements = {
  'č': 'c',
  'ć': 'c',
  'đ': 'd',
  'š': 's',
  'ž': 'z',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
};

/// Cached regex patterns for slug generation
final RegExp _whitespaceRegex = RegExp(r'[\s_]+');
final RegExp _nonAlphanumericRegex = RegExp(r'[^a-z0-9\-]');
final RegExp _multipleHyphensRegex = RegExp(r'-+');
final RegExp _leadingTrailingHyphensRegex = RegExp(r'^-+|-+$');

/// Generate URL-friendly slug from a string
///
/// Converts string to lowercase, replaces spaces with hyphens,
/// removes special characters, and trims to max length
///
/// Examples:
/// - "Villa Jasko" → "villa-jasko"
/// - "Apartman 6" → "apartman-6"
/// - "Studio Apartment - Luxury!" → "studio-apartment-luxury"
/// - "Déluxe Suite #5" → "deluxe-suite-5"
String generateSlug(String input, {int maxLength = 50}) {
  if (input.isEmpty) return '';

  String slug = input.toLowerCase();

  // Replace special characters with ASCII equivalents (using cached map)
  _charReplacements.forEach((char, replacement) {
    slug = slug.replaceAll(char, replacement);
  });

  // Replace spaces and underscores with hyphens (using cached regex)
  slug = slug.replaceAll(_whitespaceRegex, '-');

  // Remove all characters except alphanumeric and hyphens (using cached regex)
  slug = slug.replaceAll(_nonAlphanumericRegex, '');

  // Replace multiple consecutive hyphens with single hyphen (using cached regex)
  slug = slug.replaceAll(_multipleHyphensRegex, '-');

  // Remove leading/trailing hyphens (using cached regex)
  slug = slug.replaceAll(_leadingTrailingHyphensRegex, '');

  // Truncate to max length (but keep whole words if possible)
  if (slug.length > maxLength) {
    slug = slug.substring(0, maxLength);

    // If truncation happened mid-word, remove the incomplete word
    final lastHyphenIndex = slug.lastIndexOf('-');
    if (lastHyphenIndex > 0 && lastHyphenIndex < slug.length - 1) {
      // Check if there's an incomplete word after last hyphen
      final lastPart = slug.substring(lastHyphenIndex + 1);
      if (lastPart.isNotEmpty) {
        slug = slug.substring(0, lastHyphenIndex);
      }
    }

    // Remove trailing hyphen if present (reuse cached regex)
    slug = slug.replaceAll(_leadingTrailingHyphensRegex, '');
  }

  return slug;
}

/// Generate hybrid slug with unit ID
///
/// Creates a slug in format: "{slug}-{shortId}"
/// Example: "apartman-6-gMIOos"
///
/// [slug] - Generated slug from unit/property name
/// [unitId] - Full Firestore document ID (e.g., "gMIOos56siO74VkCsSwY")
/// [shortIdLength] - Number of characters from unit ID to include (default: 6)
String generateHybridSlug(String slug, String unitId, {int shortIdLength = 6}) {
  if (slug.isEmpty || unitId.isEmpty) {
    throw ArgumentError('Slug and unitId cannot be empty');
  }

  // Extract short ID from full Firestore ID
  final shortId = unitId.length >= shortIdLength
      ? unitId.substring(0, shortIdLength)
      : unitId;

  return '$slug-$shortId';
}

/// Parse hybrid slug to extract short unit ID
///
/// Extracts the short ID portion from a hybrid slug
/// Example: "apartman-6-gMIOos" → "gMIOos"
///
/// Returns null if slug format is invalid
String? parseShortIdFromHybridSlug(String hybridSlug) {
  if (hybridSlug.isEmpty) return null;

  // Hybrid slug must contain at least one hyphen
  if (!hybridSlug.contains('-')) return null;

  // Split by hyphen and get last part (short ID)
  final parts = hybridSlug.split('-');
  if (parts.length < 2) return null;

  final shortId = parts.last;

  // Validate that it looks like a Firestore ID (alphanumeric, 6+ chars)
  if (shortId.length >= 6 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(shortId)) {
    return shortId;
  }

  return null;
}

/// Validate slug format
///
/// Checks if a slug follows the correct format:
/// - Only lowercase letters, numbers, and hyphens
/// - No consecutive hyphens
/// - No leading/trailing hyphens
bool isValidSlug(String slug) {
  if (slug.isEmpty) return false;

  // Check if matches slug pattern
  if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(slug)) {
    return false;
  }

  return true;
}

/// Check if slug is unique in a collection
///
/// This should be called before saving a new slug to Firestore
/// to prevent duplicates within the same property
///
/// Note: Actual Firestore check should be done in repository layer
bool shouldCheckSlugUniqueness(String slug) {
  // This is a placeholder for repository-level uniqueness check
  // In practice, this check should query Firestore
  return slug.isNotEmpty && isValidSlug(slug);
}

/// Generate fallback slug if generation fails
///
/// Creates a safe fallback slug using a UUID or timestamp
String generateFallbackSlug(String prefix) {
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  return '$prefix-$timestamp';
}
