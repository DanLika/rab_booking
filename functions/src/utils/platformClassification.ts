/**
 * Platform Classification for iCal Echo Detection
 *
 * Classifies iCal platforms as "authoritative" or "aggregator" to determine
 * echo detection behavior during import.
 *
 * - Authoritative: OTAs that only export their own native bookings (safe to import)
 * - Aggregator: Platforms that re-export imported calendars (may cause echo loops)
 */

export interface PlatformConfig {
  type: "authoritative" | "aggregator";
  /** Lower = higher priority (0 = BookBed native, 1 = major OTAs) */
  priority: number;
  /** Whether this platform re-exports imported calendar data */
  reExports: boolean | null;
  /** Whether this platform corrupts dates during re-export */
  hasDateCorruption: boolean;
  /** Known date shift in days (e.g., 29 for Holiday-Home month-index bug) */
  dateShiftDays: number;
  /** Whether the platform offers an opt-out parameter for re-export */
  hasOptOut?: boolean;
  /** The opt-out URL parameter if available */
  optOutParam?: string;
}

/**
 * Platform configuration registry
 *
 * Based on real-world analysis of platform behavior:
 * - Booking.com, Airbnb: Only export native bookings (verified)
 * - Adriagate: Re-exports imported data WITHOUT date corruption (verified 2026-02-06)
 * - Holiday-Home: Re-exports imported data AND corrupts dates by ~29 days
 * - Atraveo: Re-exports by default, but has opt-out parameter
 */
export const PLATFORM_CONFIG: Record<string, PlatformConfig> = {
  // === Authoritative platforms ===
  // Their bookings are "source of truth" — safe to import

  "booking_com": {
    type: "authoritative",
    priority: 1,
    reExports: false,
    hasDateCorruption: false,
    dateShiftDays: 0,
  },

  "airbnb": {
    type: "authoritative",
    priority: 1,
    reExports: false,
    hasDateCorruption: false,
    dateShiftDays: 0,
  },

  // === BookBed native sources ===
  // These represent native BookBed bookings — highest priority

  "direct": {
    type: "authoritative",
    priority: 0, // Highest priority — BookBed native bookings
    reExports: false,
    hasDateCorruption: false,
    dateShiftDays: 0,
  },

  "widget": {
    type: "authoritative",
    priority: 0, // BookBed widget bookings
    reExports: false,
    hasDateCorruption: false,
    dateShiftDays: 0,
  },

  // === Aggregator platforms ===
  // May re-export imported data — echo detection needed

  "adriagate": {
    type: "aggregator",
    priority: 3,
    reExports: true, // PROVEN 2026-02-06: re-exports BookBed bookings verbatim (no date corruption)
    hasDateCorruption: false,
    dateShiftDays: 0,
  },

  "holiday-home": {
    type: "aggregator",
    priority: 10,
    reExports: true,
    hasDateCorruption: true,
    dateShiftDays: 29, // Known month-index bug
    hasOptOut: false,
  },

  "atraveo": {
    type: "aggregator",
    priority: 10,
    reExports: true,
    hasDateCorruption: false,
    dateShiftDays: 0,
    hasOptOut: true,
    optOutParam: "dontincludeimported=1",
  },

  // === Unknown/other ===
  // Treat with caution — may or may not re-export

  "other": {
    type: "aggregator",
    priority: 5,
    reExports: null, // Unknown
    hasDateCorruption: false,
    dateShiftDays: 0,
  },
};

/**
 * Get platform configuration for a given source identifier
 * Falls back to "other" config for unknown platforms
 */
export function getPlatformConfig(source: string): PlatformConfig {
  return PLATFORM_CONFIG[source] || PLATFORM_CONFIG["other"];
}

/**
 * Check if a platform is classified as an aggregator
 * Aggregators may re-export imported data, causing echo loops
 */
export function isAggregator(source: string): boolean {
  return getPlatformConfig(source).type === "aggregator";
}

/**
 * Check if a platform is classified as authoritative
 * Authoritative platforms only export their own native bookings
 */
export function isAuthoritative(source: string): boolean {
  return getPlatformConfig(source).type === "authoritative";
}
