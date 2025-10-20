/// Constants for search functionality
/// Centralizes all magic numbers and configuration values
class SearchConstants {
  SearchConstants._(); // Private constructor

  // ============================================================================
  // PAGINATION
  // ============================================================================

  /// Default page size for search results
  static const int defaultPageSize = 20;

  /// Maximum page size allowed
  static const int maxPageSize = 100;

  /// Scroll threshold for infinite scroll (0.8 = 80% scrolled)
  static const double scrollLoadThreshold = 0.8;

  // ============================================================================
  // PRICE FILTERS
  // ============================================================================

  /// Minimum price for filter (in EUR)
  static const double minPriceFilter = 0.0;

  /// Maximum price for filter (in EUR)
  static const double maxPriceFilter = 1000.0;

  /// Default maximum price when no filter applied
  static const double defaultMaxPrice = 500.0;

  /// Price slider divisions
  static const int priceSliderDivisions = 100;

  // ============================================================================
  // ROOMS FILTERS
  // ============================================================================

  /// Maximum bedrooms to show in filter
  static const int maxBedroomsFilter = 5;

  /// Maximum bathrooms to show in filter
  static const int maxBathroomsFilter = 3;

  // ============================================================================
  // DEBOUNCING & THROTTLING
  // ============================================================================

  /// Debounce duration for filter changes (milliseconds)
  static const int filterDebounceMs = 300;

  /// Debounce duration for search input (milliseconds)
  static const int searchInputDebounceMs = 500;

  /// Throttle duration for scroll events (milliseconds)
  static const int scrollThrottleMs = 200;

  // ============================================================================
  // CACHING
  // ============================================================================

  /// Cache duration for search results (seconds)
  static const int searchResultsCacheDuration = 300; // 5 minutes

  /// Cache duration for property details (seconds)
  static const int propertyDetailsCacheDuration = 600; // 10 minutes

  /// Maximum number of cached search queries
  static const int maxCachedQueries = 50;

  // ============================================================================
  // QUERY OPTIMIZATION
  // ============================================================================

  /// Use optimized materialized view for search
  static const bool useOptimizedView = true;

  /// Enable query result caching
  static const bool enableQueryCache = true;

  /// Enable availability pre-filtering
  static const bool enableAvailabilityFilter = true;

  // ============================================================================
  // SKELETON LOADERS
  // ============================================================================

  /// Number of skeleton items to show per row (mobile)
  static const int skeletonItemsPerRowMobile = 1;

  /// Number of skeleton items to show per row (tablet)
  static const int skeletonItemsPerRowTablet = 2;

  /// Number of skeleton items to show per row (desktop)
  static const int skeletonItemsPerRowDesktop = 3;

  /// Number of skeleton rows to show initially
  static const int skeletonRows = 3;

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Maximum retry attempts for failed queries
  static const int maxRetryAttempts = 3;

  /// Delay between retry attempts (milliseconds)
  static const int retryDelayMs = 1000;

  /// Timeout for search queries (seconds)
  static const int searchQueryTimeout = 10;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get skeleton item count based on screen columns
  static int getSkeletonCount(int columns) {
    return columns * skeletonRows;
  }

  /// Get debounce duration as Duration object
  static Duration get filterDebounceDuration =>
      Duration(milliseconds: filterDebounceMs);

  /// Get search input debounce duration
  static Duration get searchInputDebounceDuration =>
      Duration(milliseconds: searchInputDebounceMs);

  /// Get scroll throttle duration
  static Duration get scrollThrottleDuration =>
      Duration(milliseconds: scrollThrottleMs);

  /// Get cache duration for search results
  static Duration get searchCacheDuration =>
      Duration(seconds: searchResultsCacheDuration);

  /// Get cache duration for property details
  static Duration get propertyCacheDuration =>
      Duration(seconds: propertyDetailsCacheDuration);

  /// Get retry delay duration
  static Duration get retryDelay =>
      Duration(milliseconds: retryDelayMs);

  /// Get query timeout duration
  static Duration get queryTimeout =>
      Duration(seconds: searchQueryTimeout);
}
