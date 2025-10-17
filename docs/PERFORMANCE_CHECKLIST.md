# Performance Optimization Checklist

Use this checklist to ensure all performance optimizations are implemented correctly.

## Image Optimization

- [ ] All images use `ImageService.optimizedImage()` or helper methods
- [ ] Images specify exact width/height for memory optimization
- [ ] List views use `ImageService.propertyCardImage()` (400px thumbnails)
- [ ] Detail screens use `ImageService.propertyDetailImage()` (1200px)
- [ ] Avatar images use `ImageService.avatarImage()`
- [ ] Critical images are precached before navigation
- [ ] Images have proper error and placeholder widgets
- [ ] No direct use of `Image.network()` in the codebase
- [ ] Image URLs use CDN transformations for thumbnails
- [ ] Image cache is cleared on low memory warnings

**Files to check:**
- All `*_screen.dart` files
- All `*_widget.dart` files
- Especially: `property_card.dart`, `property_details_screen.dart`

---

## List Performance

- [ ] All long lists use `ListView.builder` (not `ListView` with `children`)
- [ ] Infinite scroll pagination implemented (page size: 20)
- [ ] Scroll controller added with load-more trigger at 200px from bottom
- [ ] Loading indicator shown while fetching next page
- [ ] `itemExtent` specified for fixed-height list items
- [ ] `cacheExtent` increased to 1000 for smoother scrolling
- [ ] Each list item has unique `key: ValueKey(item.id)`
- [ ] Complex list items use `AutomaticKeepAliveClientMixin`
- [ ] No unnecessary rebuilds of list items
- [ ] Skeleton loaders used during initial load

**Files to check:**
- `search_results_screen.dart`
- `property_list_screen.dart`
- `user_bookings_screen.dart`
- `owner_properties_screen.dart`

---

## State Management Optimization

### Riverpod

- [ ] `.select()` used to watch specific fields instead of entire objects
- [ ] Family providers use autoDispose (default with `@riverpod`)
- [ ] Global data uses `@Riverpod(keepAlive: true)`
- [ ] No unnecessary provider watches in build methods
- [ ] Providers split into smaller, focused units
- [ ] Provider dependencies are explicit

**Example check:**
```dart
// ✅ Good
final name = ref.watch(propertyProvider(id).select((p) => p.value?.name));

// ❌ Bad
final property = ref.watch(propertyProvider(id));
final name = property.value?.name;
```

### Debouncing & Throttling

- [ ] Search inputs debounced (500ms) using `Debouncer`
- [ ] Filter changes throttled (300ms) using `Throttler`
- [ ] High-frequency scroll events throttled
- [ ] API calls not triggered on every keystroke
- [ ] Debouncers/throttlers properly disposed

**Files to check:**
- `search_bar_widget.dart`
- `filter_panel.dart`
- Any TextField with `onChanged` callbacks

---

## Database Query Optimization

### Query Patterns

- [ ] `SELECT` specifies exact columns (no `SELECT *`)
- [ ] Pagination implemented with `.range(start, end)`
- [ ] Filters applied before fetching data (not in Dart)
- [ ] Joins used for related data (one query instead of multiple)
- [ ] Count queries use `FetchOptions(count: CountOption.exact, head: true)`
- [ ] Date range queries use indexed columns
- [ ] Full-text search uses GIN indexes

**Example check:**
```dart
// ✅ Good
.select('id, name, location, price_per_night')

// ❌ Bad
.select('*')
```

### Database Indexes

- [ ] Migration file `004_performance_indexes.sql` applied to Supabase
- [ ] All indexes created successfully (check Supabase Dashboard)
- [ ] Composite indexes for common query patterns
- [ ] Full-text search index on properties table
- [ ] Partial indexes for status-based queries
- [ ] Foreign key columns have indexes

**To verify:**
```sql
-- Run in Supabase SQL Editor
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## Caching Strategy

- [ ] `CacheService` used for frequently accessed data
- [ ] Appropriate TTL configured per data type:
  - Properties: 5 minutes
  - Users: 10 minutes
  - Search results: 2 minutes
  - Bookings: 3 minutes
- [ ] Cache invalidated after mutations (create/update/delete)
- [ ] `AppCache.clearAll()` called on logout
- [ ] Cache stats monitored in debug mode
- [ ] Expired entries cleaned periodically
- [ ] `getOrSet` pattern used for fetch-and-cache

**Files to check:**
- `*_repository.dart` files
- `*_notifier.dart` files

**Example check:**
```dart
// ✅ Good - with caching
final cached = AppCache.properties.get('featured');
if (cached != null) return cached;

final properties = await fetchFeatured();
AppCache.properties.set('featured', properties);

// Or better:
return await AppCache.properties.getOrSet('featured', () => fetchFeatured());
```

---

## Widget Build Optimization

### Const Constructors

- [ ] All StatelessWidgets use const constructors
- [ ] Widget instances created with `const` where possible
- [ ] Constant values extracted to separate constants file
- [ ] No non-const widgets in const widget trees

**Example check:**
```dart
// ✅ Good
class MyButton extends StatelessWidget {
  const MyButton({super.key, required this.label});
  final String label;
}

// Usage:
const MyButton(label: 'Click me')
```

### RepaintBoundary

- [ ] Expensive widgets wrapped in `RepaintBoundary`
- [ ] Animations isolated with `RepaintBoundary`
- [ ] Complex list items wrapped in `RepaintBoundary`
- [ ] Images isolated from parent rebuilds
- [ ] No excessive RepaintBoundary usage (adds overhead)

**Files to check:**
- `property_card.dart`
- `animated_*_widget.dart`
- Complex custom widgets

### Builder Widgets

- [ ] `Builder` used for isolated rebuilds
- [ ] Favorite buttons isolated with Builder
- [ ] Large widgets split into smaller components
- [ ] Each component watches only necessary providers
- [ ] Build methods are small (< 50 lines)

---

## Performance Monitoring

### PerformanceTracker

- [ ] Critical operations tracked with `PerformanceTracker.trackAsync()`
- [ ] Repository methods measured with `PerformanceTracker.measureAsync()`
- [ ] Build times tracked for heavy screens
- [ ] Timeline events visible in DevTools
- [ ] Performance metrics logged in profile mode

**Example check:**
```dart
// ✅ Repository methods
Future<Result<List<Property>>> fetchProperties() async {
  return await PerformanceTracker.measureAsync(
    'fetchProperties',
    () async {
      // ... fetch logic
    },
  );
}
```

### Performance Logging

- [ ] `PerformanceLogger.logSummary()` called periodically in debug
- [ ] Key metrics monitored:
  - API call durations
  - Widget build times
  - Frame rate (FPS)
- [ ] Performance bottlenecks identified and addressed
- [ ] Regression tests for performance

### AppPerformanceObserver

- [ ] `AppPerformanceObserver` registered in `main.dart`
- [ ] FPS monitoring active in profile mode
- [ ] Memory pressure warnings handled
- [ ] Performance data logged or sent to analytics

---

## Flutter DevTools Testing

- [ ] App tested in profile mode: `flutter run --profile`
- [ ] Timeline view shows no jank (all frames < 16ms)
- [ ] No frame rendering issues identified
- [ ] Widget rebuild stats analyzed
- [ ] No unnecessary rebuilds detected
- [ ] Memory view shows no leaks
- [ ] Memory usage stable over time
- [ ] Network tab shows reasonable request count
- [ ] Image cache size reasonable
- [ ] No shader compilation jank

**To test:**
```bash
flutter run --profile
# Open DevTools
# Navigate through app
# Check Timeline tab for jank
```

---

## Build & Release Performance

- [ ] App compiled in release mode works correctly
- [ ] Cold start time < 3 seconds
- [ ] Hot reload works without issues
- [ ] Build time reasonable (< 2 minutes for full build)
- [ ] APK/IPA size optimized (tree shaking enabled)
- [ ] Obfuscation enabled for release builds
- [ ] Split debug info for smaller build size

**Build commands:**
```bash
# Android release
flutter build apk --release --split-per-abi

# iOS release
flutter build ios --release
```

---

## Network Performance

- [ ] API responses cached appropriately
- [ ] Retry logic with exponential backoff implemented
- [ ] Timeout handling (30 seconds max)
- [ ] Offline mode gracefully handled
- [ ] Failed requests don't block UI
- [ ] Loading states properly displayed
- [ ] Error states properly displayed

---

## User Experience Performance

- [ ] Search responds within 500ms
- [ ] List scrolling is smooth (60fps)
- [ ] Image loading doesn't block UI
- [ ] Animations run at 60fps
- [ ] Navigation transitions are smooth
- [ ] Form inputs feel responsive
- [ ] No ANR (Application Not Responding) issues
- [ ] No UI freezes during data loading

---

## Performance Budget

Track these metrics and ensure they stay within budget:

| Metric | Budget | Current | Status |
|--------|--------|---------|--------|
| Cold Start Time | < 3s | ___ | ⬜ |
| Search Response | < 500ms | ___ | ⬜ |
| List Scroll FPS | 60fps | ___ | ⬜ |
| Image Load Time | < 1s | ___ | ⬜ |
| API Call Duration | < 2s | ___ | ⬜ |
| Memory Usage | < 150MB | ___ | ⬜ |
| APK Size | < 50MB | ___ | ⬜ |
| Frame Build Time | < 16ms | ___ | ⬜ |

---

## Testing Scenarios

Test these scenarios to verify performance:

### Scenario 1: Large Property List
- [ ] Load 100+ properties
- [ ] Scroll smoothly through entire list
- [ ] Memory usage remains stable
- [ ] Pagination works correctly
- [ ] Images load progressively

### Scenario 2: Search & Filter
- [ ] Type in search box - no lag
- [ ] Debouncing works (waits 500ms)
- [ ] Results load quickly
- [ ] Filter changes are smooth
- [ ] Clear filters works instantly

### Scenario 3: Property Details
- [ ] Navigate from list to details
- [ ] Images load without blocking
- [ ] Reviews load on demand
- [ ] Back navigation is instant
- [ ] Memory released after leaving

### Scenario 4: Booking Flow
- [ ] Calendar interactions smooth
- [ ] Date selection responsive
- [ ] Price calculation instant
- [ ] Payment screen loads fast
- [ ] Confirmation shows immediately

### Scenario 5: Offline Mode
- [ ] App works with cached data
- [ ] Graceful error messages
- [ ] No crashes or freezes
- [ ] Retry mechanism works
- [ ] Online mode recovers smoothly

---

## Final Verification

Before marking this complete:

- [ ] All sections above reviewed
- [ ] Critical issues addressed
- [ ] Performance guide reviewed
- [ ] DevTools profiling completed
- [ ] Test coverage adequate
- [ ] Documentation updated
- [ ] Code review completed
- [ ] Performance regression tests added

---

## Maintenance

Schedule regular performance checks:

- **Weekly:** Review PerformanceLogger metrics
- **Monthly:** Full DevTools profiling session
- **Per Release:** Complete this checklist
- **Quarterly:** Review and update performance budget

---

## Notes

Add notes about specific performance issues or optimizations here:

```
[Date] - [Developer] - [Issue/Optimization]
Example:
2025-01-15 - Claude - Added RepaintBoundary to PropertyCard, reduced rebuild time by 40%
```

---

## Resources

- [PERFORMANCE_GUIDE.md](./PERFORMANCE_GUIDE.md) - Detailed implementation guide
- [Flutter Performance Docs](https://docs.flutter.dev/perf/best-practices)
- [Supabase Performance](https://supabase.com/docs/guides/database/performance)
- [Riverpod Performance](https://riverpod.dev/docs/essentials/faq)
