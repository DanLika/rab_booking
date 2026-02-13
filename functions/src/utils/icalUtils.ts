/**
 * Represents a range of consecutive blocked days
 */
export interface BlockedRange {
  startDate: Date;
  endDate: Date; // Inclusive
}

/**
 * Truncate time to midnight UTC for consistent comparisons
 *
 * TIMEZONE FIX: Firestore stores dates as midnight local time (UTC+1/+2 for Europe/Zagreb).
 * When converted to JS Date via .toDate(), these appear as 22:00/23:00 PREVIOUS day in UTC.
 * Example: "May 28, 00:00 UTC+2" → "May 27, 22:00 UTC" → getUTCDate() = 27 (WRONG!)
 * Adding 12h before truncating ensures we land on the correct calendar date:
 * "May 27, 22:00 UTC" + 12h → "May 28, 10:00 UTC" → setUTCHours(0) → "May 28, 00:00 UTC" ✓
 * This works for any timezone offset from UTC-12 to UTC+14.
 */
export function truncateTime(date: Date): Date {
  const d = new Date(date.getTime() + 12 * 60 * 60 * 1000);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

/**
 * Calculate min-stay gap blocks
 * Gaps between bookings/blocks shorter than unit's min_stay_nights must be blocked
 */
export function calculateMinStayGapBlocks(
  bookings: any[],
  icalEvents: any[],
  blockedRanges: BlockedRange[],
  minStayNights: number
): BlockedRange[] {
  if (minStayNights <= 1) return [];

  // 1. Convert all inputs to [start, end) intervals (milliseconds)
  // Use truncateTime for consistent UTC dates
  const intervals: {start: number; end: number}[] = [];

  // Bookings
  for (const b of bookings) {
    if (b.check_in && b.check_out) {
      const start = truncateTime(b.check_in.toDate()).getTime();
      const end = truncateTime(b.check_out.toDate()).getTime();
      if (start < end) intervals.push({start, end});
    }
  }

  // iCal Events
  for (const e of icalEvents) {
    if (e.start_date && e.end_date) {
      const start = truncateTime(e.start_date.toDate()).getTime();
      const end = truncateTime(e.end_date.toDate()).getTime();
      if (start < end) intervals.push({start, end});
    }
  }

  // Blocked Ranges (from daily_prices)
  // These are inclusive [startDate, endDate], so convert to exclusive end (+1 day)
  for (const r of blockedRanges) {
    const start = truncateTime(r.startDate).getTime();
    const end = truncateTime(r.endDate).getTime() + 24 * 60 * 60 * 1000;
    if (start < end) intervals.push({start, end});
  }

  if (intervals.length === 0) return [];

  // 2. Sort by start time
  intervals.sort((a, b) => a.start - b.start);

  // 3. Merge overlapping intervals
  const merged: {start: number; end: number}[] = [];
  let current = intervals[0];

  for (let i = 1; i < intervals.length; i++) {
    const next = intervals[i];
    if (next.start < current.end) {
      // Overlap or adjacent - merge
      current.end = Math.max(current.end, next.end);
    } else {
      // Gap or adjacent
      merged.push(current);
      current = next;
    }
  }
  merged.push(current);

  // 4. Find gaps < minStayNights
  const gaps: BlockedRange[] = [];
  const minStayMs = minStayNights * 24 * 60 * 60 * 1000;

  for (let i = 0; i < merged.length - 1; i++) {
    const prevEnd = merged[i].end;
    const nextStart = merged[i+1].start;
    const gapDuration = nextStart - prevEnd;

    // Check if gap exists and is shorter than minStay
    // gapDuration must be > 0 (otherwise they touch/overlap)
    // gapDuration must be < minStayMs
    if (gapDuration > 0 && gapDuration < minStayMs) {
      // Create blocked range for the gap
      // Start: prevEnd (inclusive)
      // End: nextStart - 1 day (inclusive)
      gaps.push({
        startDate: new Date(prevEnd),
        endDate: new Date(nextStart - 24 * 60 * 60 * 1000)
      });
    }
  }

  return gaps;
}
