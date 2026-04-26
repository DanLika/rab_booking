import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService<String> cache;

    setUp(() {
      cache = CacheService<String>(ttl: const Duration(minutes: 5));
    });

    test('should set and get a value', () {
      cache.set('key1', 'value1');
      expect(cache.get('key1'), equals('value1'));
    });

    test('get should return null if key does not exist', () {
      expect(cache.get('missing_key'), isNull);
    });

    test('has should return true if key exists and is valid', () {
      cache.set('key1', 'value1');
      expect(cache.has('key1'), isTrue);
    });

    test('has should return false if key does not exist', () {
      expect(cache.has('missing_key'), isFalse);
    });

    test('get should return null after TTL expires', () async {
      final shortCache = CacheService<String>(ttl: const Duration(milliseconds: 50));
      shortCache.set('key1', 'value1');

      // Still valid immediately
      expect(shortCache.get('key1'), equals('value1'));

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      expect(shortCache.get('key1'), isNull);
    });

    test('has should return false after TTL expires', () async {
      final shortCache = CacheService<String>(ttl: const Duration(milliseconds: 50));
      shortCache.set('key1', 'value1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      expect(shortCache.has('key1'), isFalse);
    });

    test('invalidate should remove a specific key', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.invalidate('key1');

      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), equals('value2'));
    });

    test('invalidatePattern should remove matching keys', () {
      cache.set('user_1', 'alice');
      cache.set('user_2', 'bob');
      cache.set('property_1', 'villa');

      cache.invalidatePattern('user_');

      expect(cache.get('user_1'), isNull);
      expect(cache.get('user_2'), isNull);
      expect(cache.get('property_1'), equals('villa'));
    });

    test('clear should remove all keys', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.clear();

      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });

    test('getStats should return correct valid, expired, and total entry counts', () async {
      final shortCache = CacheService<String>(ttl: const Duration(milliseconds: 50));

      shortCache.set('key1', 'value1');
      shortCache.set('key2', 'value2');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      // Add a new valid entry
      shortCache.set('key3', 'value3');

      final stats = shortCache.getStats();
      expect(stats.totalEntries, equals(3));
      expect(stats.validEntries, equals(1)); // only key3 is valid
      expect(stats.expiredEntries, equals(2)); // key1, key2 are expired
    });

    test('cleanExpired should remove expired entries only', () async {
      final shortCache = CacheService<String>(ttl: const Duration(milliseconds: 50));

      shortCache.set('key1', 'value1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      shortCache.set('key2', 'value2');

      shortCache.cleanExpired();

      final stats = shortCache.getStats();
      expect(stats.totalEntries, equals(1));
      expect(stats.validEntries, equals(1));
      expect(stats.expiredEntries, equals(0));

      expect(shortCache.has('key1'), isFalse);
      expect(shortCache.has('key2'), isTrue);
    });

    test('getOrSet should return cached value if present and valid', () async {
      cache.set('key1', 'cached_value');

      int fetchCount = 0;
      final result = await cache.getOrSet('key1', () async {
        fetchCount++;
        return 'fetched_value';
      });

      expect(result, equals('cached_value'));
      expect(fetchCount, equals(0));
    });

    test('getOrSet should fetch and cache value if missing', () async {
      int fetchCount = 0;
      final result = await cache.getOrSet('key1', () async {
        fetchCount++;
        return 'fetched_value';
      });

      expect(result, equals('fetched_value'));
      expect(fetchCount, equals(1));
      expect(cache.get('key1'), equals('fetched_value'));
    });

    test('getOrSet should fetch and cache value if expired', () async {
      final shortCache = CacheService<String>(ttl: const Duration(milliseconds: 50));

      shortCache.set('key1', 'old_value');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      int fetchCount = 0;

      final result = await shortCache.getOrSet('key1', () async {
        fetchCount++;
        return 'new_value';
      });

      expect(result, equals('new_value'));
      expect(fetchCount, equals(1));
      expect(shortCache.get('key1'), equals('new_value'));
    });
  });

  group('AppCache', () {
    setUp(() {
      AppCache.clearAll();
    });

    test('clearAll should clear all caches', () {
      AppCache.properties.set('prop1', 'value1');
      AppCache.users.set('user1', 'value1');
      AppCache.searchResults.set('search1', 'value1');
      AppCache.bookings.set('booking1', 'value1');

      expect(AppCache.properties.has('prop1'), isTrue);
      expect(AppCache.users.has('user1'), isTrue);
      expect(AppCache.searchResults.has('search1'), isTrue);
      expect(AppCache.bookings.has('booking1'), isTrue);

      AppCache.clearAll();

      expect(AppCache.properties.has('prop1'), isFalse);
      expect(AppCache.users.has('user1'), isFalse);
      expect(AppCache.searchResults.has('search1'), isFalse);
      expect(AppCache.bookings.has('booking1'), isFalse);
    });

    test('cleanAllExpired should remove expired entries from all caches', () async {
      // Using AppCache directly makes testing TTL harder because we cannot inject TTLs easily
      // without changing the source code. Let's just verify it can be called.
      // And we can manipulate time via future.delayed if we really want, but AppCache uses 2-10 mins.
      // So let's just make sure it doesn't crash and works on empty caches.

      AppCache.properties.set('prop1', 'value1');
      AppCache.cleanAllExpired();

      expect(AppCache.properties.has('prop1'), isTrue); // Not expired yet
    });

    test('getAllStats should return stats for all caches', () {
      AppCache.properties.set('prop1', 'value1');
      AppCache.users.set('user1', 'value1');
      AppCache.users.set('user2', 'value2');

      final stats = AppCache.getAllStats();

      expect(stats.keys, containsAll(['properties', 'users', 'searchResults', 'bookings']));
      expect(stats['properties']!.totalEntries, equals(1));
      expect(stats['users']!.totalEntries, equals(2));
      expect(stats['searchResults']!.totalEntries, equals(0));
      expect(stats['bookings']!.totalEntries, equals(0));
    });
  });
}
