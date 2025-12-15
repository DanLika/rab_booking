/// Timeline Calendar Constants
/// Centralized configuration for the timeline calendar widget
library;

// ============================================================================
// INFINITE SCROLL CONFIGURATION
// ============================================================================

/// Initial days before/after today for dynamic date range
const int kTimelineInitialDaysOffset = 15;

/// Days to prepend/append when scrolling near edge
const int kTimelineDaysToExtend = 30;

/// Max days in past/future (1 year)
const int kTimelineMaxDaysLimit = 365;

/// Days from edge before triggering infinite scroll
const int kTimelineEdgeThresholdDays = 5;

// ============================================================================
// WINDOWING CONFIGURATION
// ============================================================================

/// Threshold for visible range update (avoid excessive rebuilds)
const int kTimelineVisibleRangeUpdateThreshold = 10;

/// Initial visible window - days before initial date
const int kTimelineInitialWindowDaysBefore = 60;

/// Initial visible window - total days
const int kTimelineInitialWindowDaysTotal = 120;

/// Extra days before/after visible area for smooth scrolling
const int kTimelineBufferDays = 30;

/// Default visible day count for initial render
const int kTimelineDefaultVisibleDayCount = 90;

// ============================================================================
// SCROLL RETRY CONFIGURATION
// ============================================================================

/// Scroll retry delay in milliseconds
const int kTimelineScrollRetryDelayMs = 100;

/// Max scroll retry attempts
const int kTimelineMaxScrollRetryAttempts = 10;

// ============================================================================
// RESPONSIVE BREAKPOINTS
// ============================================================================

/// Mobile breakpoint for header height
const double kTimelineMobileBreakpoint = 600.0;

/// Tablet breakpoint for header height
const double kTimelineTabletBreakpoint = 900.0;

// ============================================================================
// HEADER DIMENSIONS
// ============================================================================

/// Mobile header height
const double kTimelineMobileHeaderHeight = 60.0;

/// Tablet header height
const double kTimelineTabletHeaderHeight = 70.0;

/// Desktop header height
const double kTimelineDesktopHeaderHeight = 80.0;

/// Month header proportion (35% of total header)
const double kTimelineMonthHeaderProportion = 0.35;

/// Day header proportion (65% of total header)
const double kTimelineDayHeaderProportion = 0.65;

// ============================================================================
// ZOOM CONFIGURATION
// ============================================================================

/// Minimum zoom scale
const double kTimelineMinZoomScale = 0.5;

/// Maximum zoom scale
const double kTimelineMaxZoomScale = 2.5;

/// Default zoom scale
const double kTimelineDefaultZoomScale = 1.0;

// ============================================================================
// ROW LAYOUT CONFIGURATION
// ============================================================================

/// Top padding for booking blocks within a row
/// Set to 12px to vertically center 34px booking blocks in rows
const double kTimelineBookingTopPadding = 12.0;

/// Total vertical padding for stacked rows
/// This determines row height as: (unitRowHeight * stackCount) + this value
/// Kept at 16px to maintain compact row heights while centering is achieved
/// via kTimelineBookingTopPadding positioning
const double kTimelineStackedRowPadding = 16.0;

// ============================================================================
// BOOKING BLOCK CONFIGURATION
// ============================================================================

/// Block height padding (reduces block height from unit row height)
const double kTimelineBookingBlockHeightPadding = 8.0;

/// Horizontal margin for booking blocks (gap on each side)
const double kTimelineBookingBlockHorizontalMargin = 2.0;

/// Hover scale transform (1.02 = 2% larger on hover)
const double kTimelineBookingBlockHoverScale = 1.02;

/// Normal opacity for booking blocks
const double kTimelineBookingBlockNormalOpacity = 0.92;

/// Hover opacity for booking blocks
const double kTimelineBookingBlockHoverOpacity = 1.0;

/// Animation duration for hover effects
const Duration kTimelineBookingBlockHoverAnimationDuration = Duration(milliseconds: 150);
