/**
 * Echo Detection Engine for iCal Sync
 *
 * Detects when an imported iCal event is actually an "echo" of a booking
 * that was previously exported from BookBed. This prevents duplicate
 * bookings caused by aggregator platforms (e.g., Holiday-Home) that
 * re-export imported calendar data.
 *
 * Uses multi-factor weighted scoring:
 *   - Date Match (25%) — with corruption tolerance for known platform bugs
 *   - Duration Match (25%) — INVARIANT under date shifting (key signal)
 *   - Export Correlation (25%) — was booking exported to this platform?
 *   - Platform Re-export Profile (15%) — is platform known to re-export?
 *   - Temporal Analysis (10%) — time gap between original and echo
 *
 * Confidence thresholds:
 *   - >= 95% → AUTO-SKIP (log only, don't import)
 *   - 85-94% → FLAG FOR REVIEW (import with needs_review status)
 *   - < 85%  → SAVE AS UNIQUE (import normally)
 */

import {getPlatformConfig, isAggregator} from "./platformClassification";

// Confidence thresholds
const AUTO_SKIP_THRESHOLD = 0.95;
const FLAG_REVIEW_THRESHOLD = 0.85;

// Temporal analysis windows
const ECHO_WINDOW_HOURS = 2; // Echoes typically arrive 2+ hours after original

export type RecommendedAction = "auto_skip" | "flag_review" | "save_unique";

export interface EchoMatchResult {
  isProbableEcho: boolean;
  confidence: number;
  matchedEventId?: string;
  matchedBookingId?: string;
  reasons: string[];
  recommendedAction: RecommendedAction;
}

export interface ExistingBooking {
  id: string;
  type: "booking" | "ical_event";
  checkIn: Date;
  checkOut: Date;
  source: string;
  importedAt: Date;
}

interface FactorResult {
  score: number;
  reasons: string[];
}

/**
 * Analyze an incoming iCal event against existing bookings for echo detection
 */
export function analyzeEvent(
  newEvent: {
    checkIn: Date;
    checkOut: Date;
    source: string;
    importedAt: Date;
  },
  existingBookings: ExistingBooking[]
): EchoMatchResult {
  const config = getPlatformConfig(newEvent.source);

  // Rule 1: Authoritative sources can't be echoes
  if (config.type === "authoritative") {
    return {
      isProbableEcho: false,
      confidence: 0,
      reasons: ["Source is authoritative OTA — cannot be echo"],
      recommendedAction: "save_unique",
    };
  }

  // Find potential matches with date tolerance (1:1 matching)
  const matches = findMatchingBookings(newEvent, existingBookings, config);

  // Analyze each match and pick the best
  let bestMatch: ExistingBooking | null = null;
  let highestConfidence = 0;
  let bestReasons: string[] = [];

  for (const existing of matches) {
    const analysis = analyzeMatch(newEvent, existing, config);
    if (analysis.confidence > highestConfidence) {
      highestConfidence = analysis.confidence;
      bestMatch = existing;
      bestReasons = analysis.reasons;
    }
  }

  // Containment analysis for merged echoes (N:1 matching)
  // Aggregators like Adriagate merge adjacent bookings into one large VEVENT.
  // The merged event doesn't match any single booking, but ALL its nights
  // are already blocked by the union of existing bookings.
  if (highestConfidence < AUTO_SKIP_THRESHOLD && isAggregator(newEvent.source)) {
    const containment = checkContainment(newEvent, existingBookings);

    if (containment.containmentRatio === 1.0 && containment.isExactUnion) {
      // Perfect containment + exact union = definite merged echo
      highestConfidence = 1.0;
      bestReasons = [
        `Merged echo: all ${containment.totalNights} nights already blocked`,
        `Exact union of ${containment.coveringBookingIds.length} existing bookings`,
      ];
    } else if (containment.containmentRatio === 1.0) {
      // All nights blocked but not exact union (overlapping bookings cover it)
      const containmentConfidence = 0.96;
      if (containmentConfidence > highestConfidence) {
        highestConfidence = containmentConfidence;
        bestReasons = [
          `Merged echo: all ${containment.totalNights} nights already blocked`,
          `Covered by ${containment.coveringBookingIds.length} existing bookings (overlapping)`,
        ];
      }
    } else if (containment.containmentRatio >= 0.95) {
      // Near-complete containment (1-2 nights off, likely rounding)
      const containmentConfidence = 0.90;
      if (containmentConfidence > highestConfidence) {
        highestConfidence = containmentConfidence;
        bestReasons = [
          `Probable merged echo: ${containment.blockedNights}/${containment.totalNights} nights blocked (${(containment.containmentRatio * 100).toFixed(0)}%)`,
          `${containment.totalNights - containment.blockedNights} unblocked nights may be rounding`,
        ];
      }
    }
    // <95% containment = significant unblocked dates, NOT a merged echo
  }

  // If no match found at all (neither 1:1 nor containment)
  if (highestConfidence === 0) {
    return {
      isProbableEcho: false,
      confidence: 0,
      reasons: ["No matching bookings found"],
      recommendedAction: "save_unique",
    };
  }

  // Decision based on confidence
  let recommendedAction: RecommendedAction;
  if (highestConfidence >= AUTO_SKIP_THRESHOLD) {
    recommendedAction = "auto_skip";
  } else if (highestConfidence >= FLAG_REVIEW_THRESHOLD) {
    recommendedAction = "flag_review";
  } else {
    recommendedAction = "save_unique";
  }

  return {
    isProbableEcho: highestConfidence >= FLAG_REVIEW_THRESHOLD,
    confidence: highestConfidence,
    matchedEventId: bestMatch?.type === "ical_event" ? bestMatch.id : undefined,
    matchedBookingId: bestMatch?.type === "booking" ? bestMatch.id : undefined,
    reasons: bestReasons,
    recommendedAction,
  };
}

/**
 * Find bookings that could potentially match the incoming event
 * Uses date tolerance based on platform's known corruption patterns
 */
function findMatchingBookings(
  newEvent: {checkIn: Date; checkOut: Date; source: string},
  existingBookings: ExistingBooking[],
  config: ReturnType<typeof getPlatformConfig>
): ExistingBooking[] {
  // Tolerance = known date shift + small variance buffer
  const tolerance = config.dateShiftDays + 3;

  return existingBookings.filter((existing) => {
    // Don't match against events from same source (those are from the same feed)
    if (existing.source === newEvent.source) return false;

    const checkinDiff = Math.abs(daysDiff(newEvent.checkIn, existing.checkIn));
    const checkoutDiff = Math.abs(daysDiff(newEvent.checkOut, existing.checkOut));

    // Check with general tolerance
    if (checkinDiff <= tolerance && checkoutDiff <= tolerance) return true;

    // Check with date correction for known corruption
    if (config.hasDateCorruption && config.dateShiftDays > 0) {
      const correctedCheckinDiff = Math.abs(checkinDiff - config.dateShiftDays);
      const correctedCheckoutDiff = Math.abs(checkoutDiff - config.dateShiftDays);
      if (correctedCheckinDiff <= 2 && correctedCheckoutDiff <= 2) return true;
    }

    return false;
  });
}

/**
 * Analyze a single match using the 5-factor weighted scoring system
 */
function analyzeMatch(
  newEvent: {checkIn: Date; checkOut: Date; source: string; importedAt: Date},
  existing: ExistingBooking,
  config: ReturnType<typeof getPlatformConfig>
): {confidence: number; reasons: string[]} {
  let confidence = 0;
  const reasons: string[] = [];

  // Factor 1: Date matching (25%)
  const dateResult = scoreDateMatch(newEvent, existing, config);
  confidence += dateResult.score * 0.25;
  reasons.push(...dateResult.reasons);

  // Factor 2: Duration match (25%) — INVARIANT under date shifting
  const durationResult = scoreDurationMatch(newEvent, existing);
  confidence += durationResult.score * 0.25;
  reasons.push(...durationResult.reasons);

  // Factor 3: Export correlation (25%)
  // Inferred from existing data: all native bookings are always exported
  const exportResult = scoreExportCorrelation(newEvent.source, existing);
  confidence += exportResult.score * 0.25;
  reasons.push(...exportResult.reasons);

  // Factor 4: Platform re-export profile (15%)
  const platformResult = scorePlatformReexport(newEvent.source, existing.source);
  confidence += platformResult.score * 0.15;
  reasons.push(...platformResult.reasons);

  // Factor 5: Temporal analysis (10%)
  const temporalResult = scoreTemporalDiff(newEvent.importedAt, existing.importedAt);
  confidence += temporalResult.score * 0.1;
  reasons.push(...temporalResult.reasons);

  return {confidence: Math.min(confidence, 1.0), reasons};
}

/**
 * Factor 1: Date Match (25%)
 * Compares check-in/check-out dates with tolerance for known corruption
 */
function scoreDateMatch(
  newEvent: {checkIn: Date; checkOut: Date},
  existing: ExistingBooking,
  config: ReturnType<typeof getPlatformConfig>
): FactorResult {
  const checkinDiff = Math.abs(daysDiff(newEvent.checkIn, existing.checkIn));
  const checkoutDiff = Math.abs(daysDiff(newEvent.checkOut, existing.checkOut));

  // Exact match
  if (checkinDiff === 0 && checkoutDiff === 0) {
    return {score: 1.0, reasons: ["Exact date match"]};
  }

  // Holiday-Home style date corruption correction
  if (config.hasDateCorruption && config.dateShiftDays > 0) {
    const correctedCheckinDiff = Math.abs(checkinDiff - config.dateShiftDays);
    const correctedCheckoutDiff = Math.abs(checkoutDiff - config.dateShiftDays);

    if (correctedCheckinDiff <= 1 && correctedCheckoutDiff <= 1) {
      return {
        score: 0.95,
        reasons: [`Matches with ${config.dateShiftDays}-day correction (known platform bug)`],
      };
    }
  }

  const totalDiff = checkinDiff + checkoutDiff;
  if (totalDiff <= 2) {
    return {score: 0.9, reasons: [`Close date match (${totalDiff} day total diff)`]};
  } else if (totalDiff <= 4) {
    return {score: 0.7, reasons: [`Fuzzy date match (${totalDiff} day total diff)`]};
  }

  return {score: 0, reasons: ["Dates do not match"]};
}

/**
 * Factor 2: Duration Match (25%)
 * Duration is INVARIANT under date shifting — key echo signal
 * A 7-night booking with corrupted dates is still 7 nights
 */
function scoreDurationMatch(
  newEvent: {checkIn: Date; checkOut: Date},
  existing: ExistingBooking
): FactorResult {
  const newDuration = daysDiff(newEvent.checkOut, newEvent.checkIn);
  const existingDuration = daysDiff(existing.checkOut, existing.checkIn);

  if (newDuration === existingDuration) {
    return {score: 1.0, reasons: [`Same duration (${newDuration} nights)`]};
  }

  // Allow 1-day tolerance for rounding
  if (Math.abs(newDuration - existingDuration) === 1) {
    return {score: 0.7, reasons: [`Similar duration (${newDuration} vs ${existingDuration} nights)`]};
  }

  return {score: 0, reasons: [`Different durations (${newDuration} vs ${existingDuration} nights)`]};
}

/**
 * Factor 3: Export Correlation (25%)
 * Inferred from existing data — no separate tracking system needed.
 *
 * Key insight: ALL native BookBed bookings are exported in every iCal feed.
 * So if the incoming event matches a native booking AND the source is a known
 * re-exporter, the booking was DEFINITELY exported to that platform.
 */
function scoreExportCorrelation(
  incomingSource: string,
  existingBooking: ExistingBooking
): FactorResult {
  const config = getPlatformConfig(incomingSource);

  // Native booking + known re-exporter = definite export
  if (existingBooking.type === "booking" && config.reExports === true) {
    return {
      score: 1.0,
      reasons: [`Native booking was exported to ${incomingSource} (all bookings are exported)`],
    };
  }

  // Native booking + aggregator with unknown re-export behavior
  if (existingBooking.type === "booking" && config.type === "aggregator") {
    return {
      score: 0.8,
      reasons: [`Native booking likely exported to ${incomingSource}`],
    };
  }

  // Imported event + known re-exporter = cross-platform echo
  if (existingBooking.type === "ical_event" && config.reExports === true) {
    return {
      score: 0.9,
      reasons: [`Imported event was re-exported via ${incomingSource}`],
    };
  }

  return {
    score: 0.5,
    reasons: ["Export correlation unclear"],
  };
}

/**
 * Factor 4: Platform Re-export Profile (15%)
 * Checks if the source platform is known to re-export imported data
 */
function scorePlatformReexport(
  newSource: string,
  existingSource: string
): FactorResult {
  const newConfig = getPlatformConfig(newSource);
  const existingIsAuthoritative = !isAggregator(existingSource);

  // Aggregator that re-exports + existing is authoritative = probable echo
  if (newConfig.type === "aggregator" && existingIsAuthoritative) {
    if (newConfig.reExports === true) {
      return {
        score: 1.0,
        reasons: [`${newSource} is KNOWN to re-export imported data`],
      };
    }
    return {
      score: 0.7,
      reasons: [`${newSource} is aggregator — may re-export`],
    };
  }

  // Both authoritative = likely REAL overbooking, not an echo
  if (!isAggregator(newSource) && existingIsAuthoritative) {
    return {
      score: 0,
      reasons: ["Both sources are authoritative — likely REAL overbooking"],
    };
  }

  return {
    score: 0.5,
    reasons: ["Platform profile unclear"],
  };
}

/**
 * Factor 5: Temporal Analysis (10%)
 * Echoes typically arrive hours after the original import,
 * while real race conditions arrive within minutes
 */
function scoreTemporalDiff(
  newImportedAt: Date,
  existingImportedAt: Date
): FactorResult {
  const diffMinutes = Math.abs(
    newImportedAt.getTime() - existingImportedAt.getTime()
  ) / 60000;

  // Within 10 minutes = likely real race condition, not echo
  if (diffMinutes <= 10) {
    return {
      score: 0,
      reasons: [`Arrived ${diffMinutes.toFixed(0)} min apart — likely REAL race condition`],
    };
  }

  // 2+ hours apart = likely echo (platform re-sync delay)
  if (diffMinutes >= ECHO_WINDOW_HOURS * 60) {
    const hours = diffMinutes / 60;
    return {
      score: 1.0,
      reasons: [`Arrived ${hours.toFixed(1)}h after original — consistent with echo delay`],
    };
  }

  // In between — linear interpolation
  const hours = diffMinutes / 60;
  const score = Math.min((hours - 0.167) / 2.0, 1.0);
  return {
    score: Math.max(score, 0),
    reasons: [`Moderate time gap (${hours.toFixed(1)}h)`],
  };
}

// ============================================================
// Containment Analysis — N:1 merged echo detection
// ============================================================

interface ContainmentResult {
  containmentRatio: number;
  blockedNights: number;
  totalNights: number;
  coveringBookingIds: string[];
  isExactUnion: boolean;
}

/**
 * Check what percentage of an incoming event's nights are already blocked
 * by the union of existing bookings. Detects merged echoes where an
 * aggregator combines multiple adjacent bookings into one large VEVENT.
 */
function checkContainment(
  newEvent: {checkIn: Date; checkOut: Date; source: string},
  existingBookings: ExistingBooking[]
): ContainmentResult {
  // 1. Generate night set for incoming event (check-in inclusive, check-out exclusive)
  const incomingNights = generateNightSet(newEvent.checkIn, newEvent.checkOut);

  if (incomingNights.size === 0) {
    return {containmentRatio: 0, blockedNights: 0, totalNights: 0, coveringBookingIds: [], isExactUnion: false};
  }

  // 2. Filter: only use bookings from OTHER sources (not the same feed)
  const otherSourceBookings = existingBookings.filter(
    (b) => b.source !== newEvent.source
  );

  // 3. Build union of all blocked nights from existing bookings
  const blockedNights = new Set<string>();
  const coveringBookingIds: string[] = [];

  for (const booking of otherSourceBookings) {
    const bookingNights = generateNightSet(booking.checkIn, booking.checkOut);
    let coversAny = false;
    for (const night of bookingNights) {
      if (incomingNights.has(night)) {
        blockedNights.add(night);
        coversAny = true;
      }
    }
    if (coversAny) coveringBookingIds.push(booking.id);
  }

  // 4. Calculate containment ratio
  const containmentRatio = blockedNights.size / incomingNights.size;

  // 5. Interval union check: do covering bookings form a contiguous chain?
  const isExactUnion = checkIntervalUnion(newEvent, otherSourceBookings);

  return {
    containmentRatio,
    blockedNights: blockedNights.size,
    totalNights: incomingNights.size,
    coveringBookingIds,
    isExactUnion,
  };
}

/**
 * Generate set of night date strings (check-in inclusive, check-out exclusive)
 * e.g., May 1-4 → {"2026-05-01", "2026-05-02", "2026-05-03"}
 */
function generateNightSet(checkIn: Date, checkOut: Date): Set<string> {
  const nights = new Set<string>();
  const current = new Date(checkIn);
  current.setUTCHours(0, 0, 0, 0);
  const end = new Date(checkOut);
  end.setUTCHours(0, 0, 0, 0);

  // Safety: max 365 nights to prevent infinite loop
  let safety = 0;
  while (current < end && safety < 365) {
    nights.add(current.toISOString().slice(0, 10));
    current.setUTCDate(current.getUTCDate() + 1);
    safety++;
  }
  return nights;
}

/**
 * Check if existing bookings form a contiguous chain covering the incoming range.
 * Allows same-day turnover (booking A checkout == booking B checkin).
 */
function checkIntervalUnion(
  newEvent: {checkIn: Date; checkOut: Date},
  existingBookings: ExistingBooking[]
): boolean {
  // Filter to bookings that overlap with the incoming range
  const overlapping = existingBookings.filter(
    (b) => b.checkIn < newEvent.checkOut && b.checkOut > newEvent.checkIn
  );

  if (overlapping.length === 0) return false;

  // Sort by check-in date
  overlapping.sort((a, b) => a.checkIn.getTime() - b.checkIn.getTime());

  // Check that chain starts at or before incoming check-in
  if (daysDiff(overlapping[0].checkIn, newEvent.checkIn) > 0) return false;

  // Walk the chain: each booking's checkout must touch next booking's checkin
  let coveredUntil = overlapping[0].checkOut;
  for (let i = 1; i < overlapping.length; i++) {
    // Allow same-day turnover (checkout == checkin) or overlap
    if (overlapping[i].checkIn > coveredUntil) return false; // gap found
    if (overlapping[i].checkOut > coveredUntil) {
      coveredUntil = overlapping[i].checkOut;
    }
  }

  // Check that chain ends at or after incoming check-out
  return daysDiff(coveredUntil, newEvent.checkOut) >= 0;
}

/**
 * Calculate difference in days between two dates
 */
function daysDiff(date1: Date, date2: Date): number {
  return Math.round((date1.getTime() - date2.getTime()) / (24 * 60 * 60 * 1000));
}
