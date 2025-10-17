# Performance Optimization Guide

This guide covers all performance optimizations implemented in the Rab Booking app.

## Table of Contents

1. [Image Optimization](#image-optimization)
2. [List Performance](#list-performance)
3. [State Management](#state-management)
4. [Database Queries](#database-queries)
5. [Caching Strategy](#caching-strategy)
6. [Build Optimizations](#build-optimizations)
7. [Performance Monitoring](#performance-monitoring)
8. [Best Practices](#best-practices)

---

## Image Optimization

### ImageService

The `ImageService` class provides optimized image loading with caching, memory optimization, and progressive loading.

**Features:**
- Automatic memory cache resizing
- Shimmer placeholder for smooth loading
- CDN-based thumbnail transformations
- Precaching for critical images

**Usage:**

```dart
// Basic optimized image
ImageService.optimizedImage(
  imageUrl: property.imageUrl,
  width: 400,
  height: 300,
  fit: BoxFit.cover,
);

// Property card image (automatically uses thumbnail)
ImageService.propertyCardImage(
  imageUrl: property.imageUrl,
  height: 200,
);

// Property detail image (higher quality)
ImageService.propertyDetailImage(
  imageUrl: property.imageUrl,
  height: 400,
);

// Precache images before navigation
await ImageService.precacheImages(
  context,
  property.images.take(3).toList(),
);
```

**Best Practices:**
- ✅ Always use `ImageService.optimizedImage()` instead of raw `CachedNetworkImage`
- ✅ Use `propertyCardImage()` for list views (400px wide thumbnail)
- ✅ Use `propertyDetailImage()` for detail screens (1200px wide)
- ✅ Precache images before navigating to image-heavy screens
- ✅ Specify exact width/height for memory optimization
- ❌ Don't use full resolution images in list views

---

## List Performance

### Infinite Scroll Pagination

Implement pagination to load data in chunks instead of loading everything at once.

**Benefits:**
- Faster initial load
- Lower memory usage
- Better user experience

**Implementation Pattern:**

```dart
class PropertyListScreen extends ConsumerStatefulWidget {
  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends ConsumerState<PropertyListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await ref.read(propertiesProvider.notifier).loadMore(
          page: _currentPage + 1,
          pageSize: _pageSize,
        );
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);

    return ListView.builder(
      controller: _scrollController,
      itemCount: properties.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == properties.length) {
          return Center(child: CircularProgressIndicator());
        }
        return PropertyCard(property: properties[index]);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### ListView Optimizations

**Best Practices:**
- ✅ Use `ListView.builder` (not `ListView` with `children`)
- ✅ Specify `itemExtent` for fixed-height items
- ✅ Use `cacheExtent` (default 250, increase to 1000 for smoother scrolling)
- ✅ Use `AutomaticKeepAliveClientMixin` for complex items
- ✅ Add `key: ValueKey(item.id)` for proper widget reuse
- ❌ Don't build all items upfront
- ❌ Don't use `ListView(children: [])` for large lists

---

## State Management

### Riverpod Optimizations

**1. Use `.select()` for granular rebuilds**

```dart
// ❌ Bad - rebuilds on any property change
final property = ref.watch(propertyProvider(id));
return Text(property.name);

// ✅ Good - only rebuilds when name changes
final propertyName = ref.watch(
  propertyProvider(id).select((async) => async.value?.name),
);
return Text(propertyName ?? 'Loading...');
```

**2. Use Family Providers with AutoDispose**

```dart
@riverpod  // Automatically autoDisposes
Future<Property> property(PropertyRef ref, String id) async {
  final result = await ref.read(propertyRepositoryProvider)
      .fetchPropertyById(id);

  return result.when(
    success: (property) => property,
    failure: (exception) => throw exception,
  );
}
```

**3. Cache Providers for Global Data**

```dart
@Riverpod(keepAlive: true)  // Keep alive - don't autodispose
class AppConfigNotifier extends _$AppConfigNotifier {
  @override
  Future<AppConfig> build() async {
    return await _loadAppConfig();
  }
}
```

### Debouncing & Throttling

**Debouncing (for search inputs):**

```dart
final debouncer = Debouncer(duration: Duration(milliseconds: 500));

TextField(
  onChanged: (value) {
    debouncer.run(() {
      ref.read(searchProvider.notifier).search(value);
    });
  },
);
```

**Throttling (for scroll events):**

```dart
final throttler = Throttler(duration: Duration(milliseconds: 300));

NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    throttler.run(() {
      updateScrollPosition(notification.metrics.pixels);
    });
    return true;
  },
);
```

---

## Database Queries

### Query Optimization

**1. Select only needed columns**

```dart
// ❌ Bad - selects all columns
final response = await supabase
    .from('properties')
    .select();

// ✅ Good - only needed fields
final response = await supabase
    .from('properties')
    .select('id, name, location, price_per_night, images');
```

**2. Use Pagination**

```dart
Future<Result<List<Property>>> fetchProperties({
  int page = 0,
  int pageSize = 20,
}) async {
  final response = await supabase
      .from('properties')
      .select('id, name, location, price_per_night, images')
      .eq('status', 'published')
      .order('created_at', ascending: false)
      .range(page * pageSize, (page + 1) * pageSize - 1);

  return Success(response.map((json) => Property.fromJson(json)).toList());
}
```

**3. Use Joins for Related Data**

```dart
// ✅ Fetch property with units in ONE query
final response = await supabase
    .from('properties')
    .select('''
      id, name, description, location, price_per_night,
      units!inner(
        id, name, price_per_night, max_guests
      ),
      owner:owner_id(
        id, name, email
      )
    ''')
    .eq('id', id)
    .single();
```

### Database Indexes

We've created comprehensive indexes in `supabase/migrations/004_performance_indexes.sql`:

- **Properties:** location+status, price, owner_id, full-text search
- **Bookings:** date ranges, property_id, user_id, status
- **Units:** property_id, status
- **Payments:** booking_id, user_id, stripe_payment_intent_id
- **Reviews:** property_id, user_id, rating

**To apply indexes:**
```bash
# In Supabase Dashboard > SQL Editor
# Run the SQL file: 004_performance_indexes.sql
```

---

## Caching Strategy

### CacheService

The `CacheService` implements an in-memory cache with TTL (Time To Live).

**Usage:**

```dart
final cache = CacheService<List<Property>>(
  ttl: Duration(minutes: 5),
);

// Set value
cache.set('properties', properties);

// Get value (returns null if expired)
final cached = cache.get('properties');

// Get or fetch pattern
final properties = await cache.getOrSet('properties', () async {
  return await fetchPropertiesFromApi();
});

// Invalidate cache
cache.invalidate('properties');
cache.invalidatePattern('property_'); // Removes all keys starting with 'property_'
cache.clear(); // Clear all
```

### Global Cache Instances

Pre-configured cache instances for common use cases:

```dart
// Use global caches
AppCache.properties.set('featured', featuredProperties);
final cached = AppCache.properties.get('featured');

// Available caches:
// - AppCache.properties (5 minutes TTL)
// - AppCache.users (10 minutes TTL)
// - AppCache.searchResults (2 minutes TTL)
// - AppCache.bookings (3 minutes TTL)

// Clear all caches
AppCache.clearAll();

// Get stats
final stats = AppCache.getAllStats();
```

**Cache Strategy:**
- ✅ Cache frequently accessed data (featured properties, user profile)
- ✅ Use shorter TTL for dynamic data (search results: 2min)
- ✅ Use longer TTL for static data (user profile: 10min)
- ✅ Invalidate cache on mutations (after create/update/delete)
- ❌ Don't cache user-specific data globally
- ❌ Don't cache data that changes frequently

---

## Build Optimizations

### 1. Const Constructors

```dart
// ✅ Good - const constructor
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// Usage - const instance
const PrimaryButton(
  label: 'Submit',
  onPressed: _handleSubmit,
)
```

### 2. RepaintBoundary

Use `RepaintBoundary` to isolate expensive widgets and animations.

```dart
class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        child: Column(
          children: [
            // Image rarely changes - isolate it
            RepaintBoundary(
              child: ImageService.propertyCardImage(
                imageUrl: property.imageUrl,
              ),
            ),
            PropertyInfo(property: property),
          ],
        ),
      ),
    );
  }
}
```

### 3. Builder Widgets for Isolated Rebuilds

```dart
Scaffold(
  appBar: AppBar(
    title: const Text('Property Details'),
    actions: [
      // Only this builder rebuilds when favorite changes
      Builder(
        builder: (context) {
          final isFavorite = ref.watch(favoriteProvider(propertyId));
          return IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () => ref.read(favoriteProvider(propertyId).notifier).toggle(),
          );
        },
      ),
    ],
  ),
);
```

---

## Performance Monitoring

### PerformanceTracker

Track operation performance with Timeline integration (visible in Flutter DevTools).

```dart
// Track async operation
final properties = await PerformanceTracker.trackAsync(
  'fetchProperties',
  () async {
    return await repository.fetchProperties();
  },
);

// Measure and log duration
final result = await PerformanceTracker.measureAsync(
  'fetchProperties',
  () async {
    return await repository.fetchProperties();
  },
);
// Logs: "⏱️ Performance [fetchProperties]: 234ms"
```

### PerformanceLogger

Collect metrics and analyze performance.

```dart
// Metrics are automatically logged by PerformanceTracker.measureAsync()

// View summary
PerformanceLogger.logSummary();
// Output:
// 📊 Performance Summary:
// [fetchProperties]
//   Calls: 10
//   Avg: 234.50ms
//   Min: 189ms
//   Max: 312ms

// Get specific metrics
final avg = PerformanceLogger.getAverage('fetchProperties');
final max = PerformanceLogger.getMax('fetchProperties');
```

### BuildTimeTracker

Track widget build times.

```dart
BuildTimeTracker(
  label: 'PropertyListView',
  child: ListView.builder(
    itemCount: properties.length,
    itemBuilder: (context, index) {
      return PropertyCard(property: properties[index]);
    },
  ),
)
// Logs: "⏱️ Performance [PropertyListView.build]: 45ms"
```

### AppPerformanceObserver

Monitor app-wide performance metrics like FPS.

```dart
// Register in main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(AppPerformanceObserver());
  runApp(MyApp());
}
// Logs: "📊 Average FPS: 59.80"
```

---

## Best Practices

### ✅ DO:

- **Images:**
  - Use `ImageService.optimizedImage()` for all images
  - Specify exact dimensions for memory optimization
  - Use thumbnails in list views, full images in detail views
  - Precache images before navigation

- **Lists:**
  - Use `ListView.builder` with pagination
  - Set `itemExtent` for fixed-height items
  - Add unique keys: `key: ValueKey(item.id)`
  - Implement infinite scroll for large datasets

- **State Management:**
  - Use `.select()` for granular rebuilds
  - Use autoDispose for family providers
  - Debounce search inputs (500ms)
  - Throttle high-frequency events (300ms)

- **Database:**
  - Select only needed columns
  - Use pagination (20 items per page)
  - Apply all indexes from migration file
  - Use joins for related data

- **Caching:**
  - Cache frequently accessed data
  - Use appropriate TTL (2-10 minutes)
  - Invalidate on mutations

- **Builds:**
  - Use const constructors everywhere possible
  - Wrap expensive widgets in RepaintBoundary
  - Split large widgets into smaller components

- **Monitoring:**
  - Test in profile mode: `flutter run --profile`
  - Use DevTools Timeline to identify jank
  - Track critical operations with PerformanceTracker

### ❌ DON'T:

- Use full resolution images in list views
- Build entire lists upfront with `ListView(children: [])`
- Watch entire objects when you only need one field
- Use `SELECT *` queries
- Cache user-specific data globally
- Create large widgets that rebuild frequently
- Test performance only in debug mode

---

## Performance Testing Checklist

Before releasing, ensure:

- [ ] All images use `ImageService`
- [ ] Lists implement pagination
- [ ] Database indexes are applied
- [ ] Search inputs are debounced
- [ ] Critical operations use caching
- [ ] Large widgets use RepaintBoundary
- [ ] Profile mode shows 60fps (no jank)
- [ ] Memory usage is stable (no leaks)
- [ ] Cold start time < 3 seconds
- [ ] Search response time < 500ms
- [ ] List scroll is smooth

---

## Testing in Profile Mode

```bash
# Run app in profile mode
flutter run --profile

# Then in DevTools:
# 1. Open Timeline tab
# 2. Check for jank (frames > 16ms)
# 3. Analyze widget rebuild stats
# 4. Monitor memory usage
# 5. Check network requests

# Profile-specific code:
runInPerformanceMode(() {
  // This only runs in profile/release mode
  PerformanceLogger.logSummary();
});
```

---

## Resources

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools)
- [Supabase Performance Tips](https://supabase.com/docs/guides/database/performance)
- [Riverpod Best Practices](https://riverpod.dev/docs/essentials/faq)
