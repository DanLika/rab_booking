import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/property_model.dart';
import '../../domain/models/search_filters.dart';
import 'search_constants.dart';

/// Cache entry for search results
class SearchCacheEntry {
  final List<PropertyModel> properties;
  final DateTime timestamp;
  final SearchFilters filters;

  SearchCacheEntry({
    required this.properties,
    required this.timestamp,
    required this.filters,
  });

  /// Check if cache entry is still valid
  bool get isValid {
    final age = DateTime.now().difference(timestamp);
    return age < SearchConstants.searchCacheDuration;
  }

  /// Check if cache entry is expired
  bool get isExpired => !isValid;
}

/// Search cache manager with LRU eviction
///
/// Features:
/// - Caches search results by filter hash
/// - Automatic expiration after configurable duration
/// - LRU eviction when cache is full
/// - Thread-safe operations
class SearchCacheManager {
  // Cache storage: filterHash -> CacheEntry
  final Map<String, SearchCacheEntry> _cache = {};

  // Access order for LRU eviction
  final List<String> _accessOrder = [];

  /// Get cached results for given filters
  ///
  /// Returns null if:
  /// - No cache entry exists
  /// - Cache entry is expired
  /// - Cache is disabled
  List<PropertyModel>? get(SearchFilters filters) {
    if (!SearchConstants.enableQueryCache) return null;

    final key = _generateCacheKey(filters);
    final entry = _cache[key];

    if (entry == null) {
      return null; // Cache miss
    }

    if (entry.isExpired) {
      // Remove expired entry
      _cache.remove(key);
      _accessOrder.remove(key);
      return null; // Cache expired
    }

    // Update access order (move to end = most recently used)
    _accessOrder.remove(key);
    _accessOrder.add(key);

    return List.from(entry.properties); // Return copy to prevent mutation
  }

  /// Store search results in cache
  void set(SearchFilters filters, List<PropertyModel> properties) {
    if (!SearchConstants.enableQueryCache) return;

    final key = _generateCacheKey(filters);

    // Check if cache is full
    if (_cache.length >= SearchConstants.maxCachedQueries &&
        !_cache.containsKey(key)) {
      _evictLRU();
    }

    // Store new entry
    _cache[key] = SearchCacheEntry(
      properties: List.from(properties),
      timestamp: DateTime.now(),
      filters: filters,
    );

    // Update access order
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Invalidate cache entry for specific filters
  void invalidate(SearchFilters filters) {
    final key = _generateCacheKey(filters);
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Invalidate all cache entries
  void invalidateAll() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Invalidate all entries that match a partial filter
  ///
  /// Example: Invalidate all searches for a specific location
  void invalidateMatching(bool Function(SearchFilters) predicate) {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (predicate(entry.value.filters)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Remove expired entries
  void cleanupExpired() {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Get cache statistics
  CacheStats get stats {
    final validEntries = _cache.values.where((e) => e.isValid).length;
    final expiredEntries = _cache.length - validEntries;

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      maxEntries: SearchConstants.maxCachedQueries,
      utilizationPercent: (_cache.length / SearchConstants.maxCachedQueries) * 100,
    );
  }

  /// Evict least recently used entry
  void _evictLRU() {
    if (_accessOrder.isEmpty) return;

    // Remove oldest (first) entry
    final oldestKey = _accessOrder.first;
    _cache.remove(oldestKey);
    _accessOrder.removeAt(0);
  }

  /// Generate cache key from filters
  ///
  /// Creates a deterministic hash from filter values
  /// Ensures same filters always produce same key
  String _generateCacheKey(SearchFilters filters) {
    // Create deterministic string from filters
    final filterString = [
      filters.location ?? '',
      filters.checkIn?.toIso8601String() ?? '',
      filters.checkOut?.toIso8601String() ?? '',
      filters.guests.toString(),
      filters.minPrice?.toString() ?? '',
      filters.maxPrice?.toString() ?? '',
      filters.propertyTypes.map((t) => t.name).join(','),
      filters.amenities.join(','),
      filters.minBedrooms?.toString() ?? '',
      filters.minBathrooms?.toString() ?? '',
      filters.sortBy.name,
      filters.page.toString(),
      filters.pageSize.toString(),
    ].join('|');

    // Generate SHA256 hash
    final bytes = utf8.encode(filterString);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int maxEntries;
  final double utilizationPercent;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.maxEntries,
    required this.utilizationPercent,
  });

  @override
  String toString() {
    return 'CacheStats('
        'total: $totalEntries, '
        'valid: $validEntries, '
        'expired: $expiredEntries, '
        'utilization: ${utilizationPercent.toStringAsFixed(1)}%'
        ')';
  }
}

/// Provider for search cache manager (singleton)
final searchCacheManagerProvider = Provider<SearchCacheManager>((ref) {
  final manager = SearchCacheManager();

  // Cleanup expired entries every 5 minutes
  ref.onDispose(() {
    manager.invalidateAll();
  });

  return manager;
});
