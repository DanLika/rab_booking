import 'package:flutter/foundation.dart';

/// Entry in cache with value and timestamp
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  _CacheEntry({
    required this.value,
    required this.timestamp,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

/// Generic cache service with TTL (Time To Live) strategy
///
/// Usage example:
/// ```dart
/// final cache = CacheService<List<Property>>(
///   ttl: Duration(minutes: 5),
/// );
///
/// // Set value
/// cache.set('properties', properties);
///
/// // Get value (returns null if expired)
/// final cached = cache.get('properties');
/// ```
class CacheService<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration ttl;

  CacheService({
    this.ttl = const Duration(minutes: 5),
  });

  /// Set a value in cache with current timestamp
  void set(String key, T value) {
    _cache[key] = _CacheEntry(
      value: value,
      timestamp: DateTime.now(),
    );

    debugPrint('Cache: Set key "$key" with TTL ${ttl.inMinutes}m');
  }

  /// Get a value from cache
  /// Returns null if key doesn't exist or entry is expired
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) {
      debugPrint('Cache: Miss for key "$key" (not found)');
      return null;
    }

    if (entry.isExpired(ttl)) {
      _cache.remove(key);
      debugPrint('Cache: Miss for key "$key" (expired)');
      return null;
    }

    debugPrint('Cache: Hit for key "$key"');
    return entry.value;
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired(ttl)) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove a specific key from cache
  void invalidate(String key) {
    _cache.remove(key);
    debugPrint('Cache: Invalidated key "$key"');
  }

  /// Remove all keys matching a pattern
  /// Example: invalidatePattern('property_') removes 'property_1', 'property_2', etc.
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith(pattern))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    debugPrint('Cache: Invalidated ${keysToRemove.length} keys matching "$pattern"');
  }

  /// Clear all cache entries
  void clear() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('Cache: Cleared $count entries');
  }

  /// Get cache statistics
  CacheStats getStats() {
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired(ttl)) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: validCount,
      expiredEntries: expiredCount,
    );
  }

  /// Clean up expired entries
  void cleanExpired() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired(ttl))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    debugPrint('Cache: Cleaned ${expiredKeys.length} expired entries');
  }

  /// Get or set pattern: Get from cache, or fetch and cache if not available
  Future<T> getOrSet(
    String key,
    Future<T> Function() fetcher,
  ) async {
    // Try to get from cache first
    final cached = get(key);
    if (cached != null) {
      return cached;
    }

    // Fetch new data
    debugPrint('Cache: Fetching data for key "$key"');
    final value = await fetcher();

    // Store in cache
    set(key, value);

    return value;
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
  });

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, expired: $expiredEntries)';
  }
}

/// Global cache instances for common use cases
class AppCache {
  // Cache for property data (5 minutes TTL)
  static final properties = CacheService<dynamic>(
    ttl: const Duration(minutes: 5),
  );

  // Cache for user data (10 minutes TTL)
  static final users = CacheService<dynamic>(
    ttl: const Duration(minutes: 10),
  );

  // Cache for search results (2 minutes TTL - shorter as search is dynamic)
  static final searchResults = CacheService<dynamic>(
    ttl: const Duration(minutes: 2),
  );

  // Cache for bookings (3 minutes TTL)
  static final bookings = CacheService<dynamic>(
    ttl: const Duration(minutes: 3),
  );

  /// Clear all app caches
  static void clearAll() {
    properties.clear();
    users.clear();
    searchResults.clear();
    bookings.clear();
  }

  /// Clean expired entries from all caches
  static void cleanAllExpired() {
    properties.cleanExpired();
    users.cleanExpired();
    searchResults.cleanExpired();
    bookings.cleanExpired();
  }

  /// Get stats for all caches
  static Map<String, CacheStats> getAllStats() {
    return {
      'properties': properties.getStats(),
      'users': users.getStats(),
      'searchResults': searchResults.getStats(),
      'bookings': bookings.getStats(),
    };
  }
}
