import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../presentation/utils/scroll_direction_tracker.dart';

/// Windowed bookings state for bidirectional virtual scrolling
///
/// Maintains a sliding window of bookings in memory to prevent
/// memory bloat when scrolling through thousands of bookings.
///
/// Window sizes:
/// - Card View: 20 items (page size 20)
/// - Table View: 50 items (page size 50)
class WindowedBookingsState {
  final List<OwnerBooking> visibleBookings;
  final DocumentSnapshot? topCursor;
  final DocumentSnapshot? bottomCursor;
  final bool hasMoreTop;
  final bool hasMoreBottom;
  final bool isLoadingTop;
  final bool isLoadingBottom;
  final bool isInitialLoad;
  final String? error;
  final int windowSize;
  final int pageSize;
  final ScrollDirection lastScrollDirection;
  final DateTime? lastTrimTime;

  const WindowedBookingsState({
    this.visibleBookings = const [],
    this.topCursor,
    this.bottomCursor,
    this.hasMoreTop = false,
    this.hasMoreBottom = true,
    this.isLoadingTop = false,
    this.isLoadingBottom = false,
    this.isInitialLoad = true,
    this.error,
    this.windowSize = 20,
    this.pageSize = 20,
    this.lastScrollDirection = ScrollDirection.idle,
    this.lastTrimTime,
  });

  /// Can load more items from top (scrolling up)
  bool get canLoadTop =>
      hasMoreTop && !isLoadingTop && !isLoadingBottom && !isInitialLoad;

  /// Can load more items from bottom (scrolling down)
  bool get canLoadBottom =>
      hasMoreBottom && !isLoadingBottom && !isLoadingTop && !isInitialLoad;

  /// Should trim items from the window
  /// Uses conservative threshold: windowSize + 50% buffer
  bool get shouldTrim => visibleBookings.length > trimThreshold;

  /// Threshold at which to start trimming
  /// Card view: 30 items (20 + 10 buffer)
  /// Table view: 70 items (50 + 20 buffer)
  int get trimThreshold => windowSize + (windowSize ~/ 2);

  /// Number of items to keep after trimming
  int get itemsToKeepAfterTrim => windowSize;

  /// Is the list empty (not loading)
  bool get isEmpty =>
      visibleBookings.isEmpty &&
      !isInitialLoad &&
      !isLoadingTop &&
      !isLoadingBottom;

  /// Is currently loading anything
  bool get isLoading => isInitialLoad || isLoadingTop || isLoadingBottom;

  /// Can perform trim now (conservative: 500ms debounce)
  bool canTrimNow() {
    if (lastTrimTime == null) return true;
    return DateTime.now().difference(lastTrimTime!) >
        const Duration(milliseconds: 500);
  }

  WindowedBookingsState copyWith({
    List<OwnerBooking>? visibleBookings,
    DocumentSnapshot? topCursor,
    bool clearTopCursor = false,
    DocumentSnapshot? bottomCursor,
    bool clearBottomCursor = false,
    bool? hasMoreTop,
    bool? hasMoreBottom,
    bool? isLoadingTop,
    bool? isLoadingBottom,
    bool? isInitialLoad,
    String? error,
    bool clearError = false,
    int? windowSize,
    int? pageSize,
    ScrollDirection? lastScrollDirection,
    DateTime? lastTrimTime,
    bool clearLastTrimTime = false,
  }) {
    return WindowedBookingsState(
      visibleBookings: visibleBookings ?? this.visibleBookings,
      topCursor: clearTopCursor ? null : (topCursor ?? this.topCursor),
      bottomCursor: clearBottomCursor
          ? null
          : (bottomCursor ?? this.bottomCursor),
      hasMoreTop: hasMoreTop ?? this.hasMoreTop,
      hasMoreBottom: hasMoreBottom ?? this.hasMoreBottom,
      isLoadingTop: isLoadingTop ?? this.isLoadingTop,
      isLoadingBottom: isLoadingBottom ?? this.isLoadingBottom,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      error: clearError ? null : (error ?? this.error),
      windowSize: windowSize ?? this.windowSize,
      pageSize: pageSize ?? this.pageSize,
      lastScrollDirection: lastScrollDirection ?? this.lastScrollDirection,
      lastTrimTime: clearLastTrimTime
          ? null
          : (lastTrimTime ?? this.lastTrimTime),
    );
  }

  /// Initial state for card view (window: 20, page: 20)
  static const cardViewInitial = WindowedBookingsState(windowSize: 20);

  /// Initial state for table view (window: 50, page: 50)
  static const tableViewInitial = WindowedBookingsState(
    windowSize: 50,
    pageSize: 50,
  );

  @override
  String toString() {
    return 'WindowedBookingsState('
        'items: ${visibleBookings.length}, '
        'window: $windowSize, '
        'hasMoreTop: $hasMoreTop, '
        'hasMoreBottom: $hasMoreBottom, '
        'loading: $isLoading'
        ')';
  }
}

/// Debug info for the windowing system
class WindowingDebugInfo {
  final int visibleCount;
  final int windowSize;
  final int trimThreshold;
  final bool hasMoreTop;
  final bool hasMoreBottom;
  final bool isLoadingTop;
  final bool isLoadingBottom;
  final ScrollDirection scrollDirection;
  final double scrollPosition;
  final double maxScrollExtent;

  const WindowingDebugInfo({
    required this.visibleCount,
    required this.windowSize,
    required this.trimThreshold,
    required this.hasMoreTop,
    required this.hasMoreBottom,
    required this.isLoadingTop,
    required this.isLoadingBottom,
    required this.scrollDirection,
    required this.scrollPosition,
    required this.maxScrollExtent,
  });

  double get scrollPercentage =>
      maxScrollExtent > 0 ? (scrollPosition / maxScrollExtent * 100) : 0;

  String get memoryEstimate {
    // Rough estimate: ~2KB per booking object
    final bytes = visibleCount * 2048;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
