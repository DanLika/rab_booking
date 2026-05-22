import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService<String> cache;

    setUp(() {
      cache = CacheService<String>(ttl: const Duration(milliseconds: 50));
    });

    test('set and get store and retrieve values', () {
      cache.set('key1', 'value1');
      expect(cache.get('key1'), 'value1');
    });

    test('get returns null for missing key', () {
      expect(cache.get('missing'), null);
    });

    test('get returns null for expired entry', () async {
      cache.set('key1', 'value1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 60));

      expect(cache.get('key1'), null);
    });

    test('has checks existence without expiration', () {
      cache.set('key1', 'value1');
      expect(cache.has('key1'), true);
      expect(cache.has('missing'), false);
    });

    test('has returns false and removes expired entry', () async {
      cache.set('key1', 'value1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 60));

      expect(cache.has('key1'), false);
    });

    test('invalidate removes specific key', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.invalidate('key1');

      expect(cache.has('key1'), false);
      expect(cache.has('key2'), true);
    });

    test('invalidatePattern removes matching keys', () {
      cache.set('prop_1', 'value1');
      cache.set('prop_2', 'value2');
      cache.set('user_1', 'value3');

      cache.invalidatePattern('prop_');

      expect(cache.has('prop_1'), false);
      expect(cache.has('prop_2'), false);
      expect(cache.has('user_1'), true);
    });

    test('clear removes all entries', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      cache.clear();

      expect(cache.has('key1'), false);
      expect(cache.has('key2'), false);
      expect(cache.getStats().totalEntries, 0);
    });

    test('getStats returns accurate statistics', () async {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');

      var stats = cache.getStats();
      expect(stats.totalEntries, 2);
      expect(stats.validEntries, 2);
      expect(stats.expiredEntries, 0);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 60));

      // Add a valid entry
      cache.set('key3', 'value3');

      stats = cache.getStats();
      expect(stats.totalEntries, 3);
      expect(stats.validEntries, 1);
      expect(stats.expiredEntries, 2);
    });

    test('cleanExpired removes only expired entries', () async {
      cache.set('key1', 'value1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 60));

      // Add valid entry
      cache.set('key2', 'value2');

      cache.cleanExpired();

      // Stats should reflect removal
      final stats = cache.getStats();
      expect(stats.totalEntries, 1);
      expect(stats.validEntries, 1);
      expect(stats.expiredEntries, 0);

      expect(cache.has('key1'), false);
      expect(cache.has('key2'), true);
    });

    test('getOrSet returns existing value if present', () async {
      cache.set('key1', 'existing_value');

      bool fetcherCalled = false;
      final result = await cache.getOrSet('key1', () async {
        fetcherCalled = true;
        return 'new_value';
      });

      expect(result, 'existing_value');
      expect(fetcherCalled, false);
    });

    test('getOrSet calls fetcher and sets value if missing', () async {
      bool fetcherCalled = false;
      final result = await cache.getOrSet('key1', () async {
        fetcherCalled = true;
        return 'new_value';
      });

      expect(result, 'new_value');
      expect(fetcherCalled, true);
      expect(cache.get('key1'), 'new_value');
    });

    test('getOrSet calls fetcher and sets value if expired', () async {
      cache.set('key1', 'expired_value');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 60));

      bool fetcherCalled = false;
      final result = await cache.getOrSet('key1', () async {
        fetcherCalled = true;
        return 'new_value';
      });

      expect(result, 'new_value');
      expect(fetcherCalled, true);
      expect(cache.get('key1'), 'new_value');
    });
  });

  group('CacheStats', () {
    test('toString returns properly formatted string', () {
      final stats = CacheStats(
        totalEntries: 5,
        validEntries: 3,
        expiredEntries: 2,
      );

      expect(stats.toString(), 'CacheStats(total: 5, valid: 3, expired: 2)');
    });
  });

  group('AppCache', () {
    setUp(() {
      AppCache.clearAll();
    });

    test('clearAll clears all statically defined caches', () {
      AppCache.properties.set('prop1', 'value1');
      AppCache.users.set('user1', 'value1');
      AppCache.searchResults.set('search1', 'value1');
      AppCache.bookings.set('booking1', 'value1');

      AppCache.clearAll();

      expect(AppCache.properties.has('prop1'), false);
      expect(AppCache.users.has('user1'), false);
      expect(AppCache.searchResults.has('search1'), false);
      expect(AppCache.bookings.has('booking1'), false);
    });

    test('getAllStats returns stats for all standard caches', () {
      AppCache.properties.set('prop1', 'value1');
      AppCache.users.set('user1', 'value1');
      AppCache.users.set('user2', 'value2');

      final stats = AppCache.getAllStats();

      expect(stats.keys, containsAll(['properties', 'users', 'searchResults', 'bookings']));

      expect(stats['properties']!.totalEntries, 1);
      expect(stats['users']!.totalEntries, 2);
      expect(stats['searchResults']!.totalEntries, 0);
      expect(stats['bookings']!.totalEntries, 0);
    });

    test('cleanAllExpired executes without throwing', () {
      AppCache.properties.set('prop1', 'value1');

      expect(() => AppCache.cleanAllExpired(), returnsNormally);
    });
  });
}
