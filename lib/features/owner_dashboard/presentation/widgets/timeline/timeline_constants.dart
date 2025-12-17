/// Timeline Calendar Constants
/// Centralized configuration for the timeline calendar widget
library;

// ============================================================================
// DATE RANGE CONFIGURATION (Simplified - Fixed Range)
// ============================================================================
// DESIGN DECISION: Use a fixed large date range instead of dynamic PREPEND/APPEND
// This eliminates scroll compensation race conditions that caused erratic scrolling
// (user swipes right but calendar jumps left due to scroll position compensation timing)

/// Days before today for the fixed date range
/// 2 years in the past allows viewing historical bookings
const int kTimelineDaysBefore = 365 * 2; // 730 days

/// Days after today for the fixed date range
/// 2 years in the future allows planning far ahead
const int kTimelineDaysAfter = 365 * 2; // 730 days

/// Total days in range (for reference: ~4 years = 1460 days)
/// This is large enough that users won't hit edges during normal use
/// Virtualization ensures only visible days are rendered (no performance impact)
const int kTimelineTotalDays = kTimelineDaysBefore + kTimelineDaysAfter;

// LEGACY: Keep old constants for backward compatibility during transition
// TODO: Remove these after confirming new system works

/// @deprecated Use kTimelineDaysBefore instead
const int kTimelineInitialDaysOffset = 15;

/// @deprecated No longer used - fixed range doesn't need extension
const int kTimelineDaysToExtend = 30;

/// @deprecated Use kTimelineDaysBefore/kTimelineDaysAfter instead
const int kTimelineMaxDaysLimit = 365;

/// @deprecated No longer used - no edge detection needed
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
/// Increased from 10 to 50 (5 seconds total) to handle slow data loading
/// The grid must render before ScrollController has clients
const int kTimelineMaxScrollRetryAttempts = 50;

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
/// Set to 0.5 to create 1px total gap between adjacent bookings
const double kTimelineBookingBlockHorizontalMargin = 0.5;

/// Hover scale transform (1.02 = 2% larger on hover)
const double kTimelineBookingBlockHoverScale = 1.02;

/// Normal opacity for booking blocks
const double kTimelineBookingBlockNormalOpacity = 0.92;

/// Hover opacity for booking blocks
const double kTimelineBookingBlockHoverOpacity = 1.0;

/// Animation duration for hover effects
const Duration kTimelineBookingBlockHoverAnimationDuration = Duration(milliseconds: 150);
