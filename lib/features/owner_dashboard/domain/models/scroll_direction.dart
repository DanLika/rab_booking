/// Scroll direction enum for tracking user scroll behavior
///
/// Used by:
/// - [WindowedBookingsState] for bidirectional pagination
/// - [ScrollDirectionTracker] for scroll detection
enum ScrollDirection { up, down, idle }
