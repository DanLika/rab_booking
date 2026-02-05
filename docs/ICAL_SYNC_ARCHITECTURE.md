# iCal Sync Architecture - Complete Analysis

**Date:** 2026-02-05
**Status:** Analysis Complete, Pending Implementation Decision
**Priority:** HIGH - Potential Overbooking Risk

---

## 1. Current Architecture

### Data Collections

| Collection | Purpose | What's Stored |
|------------|---------|---------------|
| `bookings` | Native BookBed reservations | Guest bookings created via widget |
| `ical_events` | Imported external reservations | Events from Booking.com, Airbnb, Adriagate, etc. |
| `daily_prices` | Blocked days + pricing | Manual blocks, seasonal pricing |

### Current Data Flow

```
                    ┌─────────────────────────────────────────┐
                    │              BOOKBED                     │
                    │  ┌─────────────────┬─────────────────┐  │
    IMPORT          │  │    bookings     │   ical_events   │  │          EXPORT
    ───────────►    │  │  (native)       │   (imported)    │  │    ────────────►
                    │  └────────┬────────┴────────┬────────┘  │
                    │           │                  │           │
                    │           ▼                  ▼           │
                    │    ┌──────────────────────────────┐     │
                    │    │   Widget Calendar Display    │     │
                    │    │   (shows BOTH collections)   │     │
                    │    └──────────────────────────────┘     │
                    └─────────────────────────────────────────┘
```

### Import Flow (icalSync.ts)
1. Fetch iCal from external URL (Booking.com, Airbnb, Adriagate, etc.)
2. Parse VEVENT entries
3. Store in `properties/{propertyId}/ical_events` collection
4. **Does NOT copy to `bookings` collection**

### Export Flow (icalExport.ts)
1. Query `collectionGroup("bookings")` for unit's reservations
2. Query `collectionGroup("daily_prices")` for blocked days (available=false)
3. Generate iCal file
4. **Does NOT query `ical_events` collection!**

### Widget Calendar (Flutter)
1. Streams `bookings` collection
2. Streams `ical_events` collection
3. Streams `daily_prices` for blocked days
4. **Displays ALL three sources correctly**

---

## 2. CRITICAL BUG IDENTIFIED

### The Gap

**Widget calendar shows all blocked dates correctly**, but **iCal export only exports native BookBed bookings**.

### Overbooking Scenario

```
Timeline:
1. Owner imports Adriagate calendar into BookBed
2. Adriagate booking (Aug 10-15) stored in ical_events
3. Owner gives BookBed export URL to Booking.com
4. Booking.com imports BookBed calendar
5. Booking.com does NOT see Aug 10-15 as blocked!
6. Guest books Aug 10-15 on Booking.com
7. OVERBOOKING - same dates booked on both platforms
```

### Current Behavior vs Expected

| Scenario | Current | Expected (Hub Model) |
|----------|---------|---------------------|
| BookBed → Booking.com | Only native bookings | Native + imported (except Booking.com's own) |
| BookBed → Airbnb | Only native bookings | Native + imported (except Airbnb's own) |
| Widget Display | All sources | All sources (working correctly) |

---

## 3. Circular Sync Prevention

### The Problem

If we naively export ALL imported events, we risk circular syncs:

```
Scenario WITHOUT filtering:
1. Booking.com has reservation X
2. Booking.com exports to BookBed → X stored in ical_events
3. BookBed exports to Booking.com → X included
4. Booking.com imports from BookBed → Creates duplicate of X!
```

### The Solution: Source Filtering

When exporting, exclude events that originated from the same platform:

```
Export to Booking.com:
├── Include: Native BookBed bookings ✅
├── Include: Airbnb imports ✅
├── Include: Adriagate imports ✅
├── Include: Manual blocks ✅
└── EXCLUDE: Booking.com imports ❌ (prevent circular sync)
```

### Implementation Challenge

**Current export URL is platform-agnostic:**
```
https://cloudfunctions.net/getUnitIcalFeed/{propertyId}/{unitId}/{token}
```

We don't know WHO is requesting the feed, so we can't filter by destination.

### Solution Options

#### Option A: Per-Platform Export URLs (Recommended)
```
/getUnitIcalFeed/{propertyId}/{unitId}/{token}?exclude=booking_com
/getUnitIcalFeed/{propertyId}/{unitId}/{token}?exclude=airbnb
```

Pros:
- Clean filtering per destination
- No circular syncs possible
- Owner controls what each platform sees

Cons:
- Need to update UI to generate per-platform URLs
- Slightly more complex setup for owners

#### Option B: UID-Based Deduplication (Risky)
Export all events with UIDs based on external_id. Hope platforms deduplicate.

Pros:
- Simpler implementation
- No per-platform URLs needed

Cons:
- Relies on external platform behavior
- UID format may not match (e.g., "abc@booking.com" vs "ical-abc@booking.com@bookbed.io")
- Risk of duplicates if dedup fails

#### Option C: Export ALL Except Same-Source (Recommended)
Add `exclude` parameter with default based on detected URL patterns.

```typescript
// In icalExport.ts
const excludeSource = request.query.exclude || detectSourceFromReferer(request);
```

---

## 4. Recommended Architecture (Hub Model)

```
                         ┌──────────────────────────────────────────────────────────┐
                         │                       BOOKBED (HUB)                       │
                         │                                                          │
  ┌──────────┐ import    │  ┌────────────┐    ┌────────────┐    ┌────────────┐     │    export    ┌──────────┐
  │Booking.com│─────────►│  │ical_events │    │  bookings  │    │daily_prices│     │─────────────►│Booking.com│
  └──────────┘           │  │(source:bc) │    │  (native)  │    │ (blocks)   │     │  (exclude bc)└──────────┘
                         │  └─────┬──────┘    └─────┬──────┘    └─────┬──────┘     │
  ┌──────────┐ import    │        │                 │                 │            │    export    ┌──────────┐
  │  Airbnb  │─────────►│  ┌─────▼─────────────────▼─────────────────▼─────┐      │─────────────►│  Airbnb  │
  └──────────┘           │  │              MERGED AVAILABILITY              │      │  (exclude ab)└──────────┘
                         │  │          (shown in widget calendar)           │      │
  ┌──────────┐ import    │  └─────────────────────────────────────────────-─┘      │    export    ┌──────────┐
  │ Adriagate│─────────►│                                                          │─────────────►│ Adriagate│
  └──────────┘           │                                                          │ (exclude ag) └──────────┘
                         └──────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Single Source of Truth**: BookBed shows merged availability from all sources
2. **No Data Duplication**: Imported events stay in `ical_events`, not copied to `bookings`
3. **Filtered Export**: Each export excludes events from the destination platform
4. **Same-Day Turnover**: All platforms use same DTEND convention (exclusive end date)

---

## 5. Potential Bugs & Edge Cases

### Bug 1: Export Missing Imported Events (CURRENT - CRITICAL)
- **Status**: Active bug
- **Impact**: Overbooking risk when using hub model
- **Fix**: Modify `icalExport.ts` to include `ical_events`

### Bug 2: Circular Sync Without Filtering
- **Status**: Will occur if Bug 1 fixed without filtering
- **Impact**: Duplicate events on platforms
- **Fix**: Add `exclude` parameter to export

### Bug 3: Race Condition (15-min Sync)
- **Scenario**: Guest books on Booking.com at 14:01, sync runs at 14:15
- **Window**: 14 minutes where BookBed doesn't know about booking
- **Impact**: Potential overbooking if someone books on BookBed in that window
- **Mitigation**:
  - Widget shows "Pending confirmation" state
  - Payment deadline gives owner time to detect conflicts
  - Consider real-time webhooks for Booking.com/Airbnb (paid feature)

### Bug 4: Event Deletion on Platform
- **Scenario**: Booking cancelled on Booking.com
- **Current behavior**: icalSync deletes ALL events from feed, re-imports
- **Impact**: Cancelled booking disappears, no record kept
- **Fix needed**: Compare before delete, mark as cancelled instead

### Bug 5: Date Timezone Mismatch
- **Status**: Fixed in icalExport.ts with `truncateTime()`
- **Note**: Uses +12h normalization to handle UTC+1/+2 → UTC conversion

### Bug 6: Overlapping Import Sources
- **Scenario**: Same property imported from BOTH Booking.com AND Adriagate
- **Risk**: Adriagate might be getting Booking.com data via channel manager
- **Impact**: Same booking imported twice with different external_ids
- **Detection**: Check for overlapping dates from different sources
- **UI Warning needed**: "These dates overlap with an existing imported booking"

---

## 6. Implementation Plan

### Phase 1: Add ical_events to Export (Required)

```typescript
// In icalExport.ts, after fetching bookings:

// 7c. Fetch imported ical_events (EXCLUDING events from destination platform)
const excludeSource = (request.query.exclude as string) || null;

let icalEventsQuery = db
  .collection("properties")
  .doc(propertyId)
  .collection("ical_events")
  .where("unit_id", "==", unitId)
  .where("start_date", ">=", admin.firestore.Timestamp.fromDate(pastDate))
  .where("start_date", "<=", admin.firestore.Timestamp.fromDate(futureDate));

// If excluding a source (e.g., don't send Booking.com events back to Booking.com)
// Note: Firestore doesn't support != queries well, so we filter client-side
const icalEventsSnapshot = await icalEventsQuery.get();

const icalEvents = icalEventsSnapshot.docs
  .filter(doc => {
    if (!excludeSource) return true;
    const source = doc.data().source?.toLowerCase() || '';
    return source !== excludeSource.toLowerCase();
  })
  .map(doc => ({
    ...doc.data(),
    id: doc.id,
    isExternal: true,
  }));
```

### Phase 2: Generate iCal Events for Imported Bookings

```typescript
function generateIcalEventForImported(event: any, unitName: string): string[] {
  const lines: string[] = [];

  lines.push("BEGIN:VEVENT");

  // Use external_id to ensure UID uniqueness
  const externalId = event.external_id || event.id;
  lines.push(`UID:ical-${sanitizeUid(externalId)}@bookbed.io`);

  // ... rest of event generation (similar to generateBookingEvent)
  // IMPORTANT: Use "Reserved" summary (no PII)

  lines.push("END:VEVENT");
  return lines;
}
```

### Phase 3: Update UI for Per-Platform URLs

```dart
// In iCal Export settings screen
String getExportUrlForPlatform(String platform) {
  final baseUrl = icalExportUrl;
  final excludeParam = switch (platform) {
    'booking_com' => '?exclude=booking_com',
    'airbnb' => '?exclude=airbnb',
    _ => '', // Generic URL for other platforms
  };
  return '$baseUrl$excludeParam';
}

// Show different URLs:
// - "For Booking.com: https://...?exclude=booking_com"
// - "For Airbnb: https://...?exclude=airbnb"
// - "For other platforms: https://..."
```

### Phase 4: Add Overlap Detection Warning

```dart
// When owner adds new iCal feed, check for overlaps
Future<List<Conflict>> checkForOverlaps(String unitId, List<IcalEvent> newEvents) async {
  final existingEvents = await getExistingIcalEvents(unitId);
  final existingBookings = await getExistingBookings(unitId);

  return newEvents
    .where((newEvent) =>
      existingEvents.any((e) => datesOverlap(newEvent, e)) ||
      existingBookings.any((b) => datesOverlap(newEvent, b))
    )
    .map((e) => Conflict(newEvent: e, existingEvent: findOverlapping(e)))
    .toList();
}
```

---

## 7. Legal & Liability Considerations

### Disclaimer for Terms of Service

```
ICAL SYNCHRONIZATION DISCLAIMER

BookBed provides iCal calendar synchronization as a convenience feature.
While we make every effort to keep calendars synchronized:

1. SYNC DELAY: External calendars are synchronized every 15 minutes.
   Bookings made on external platforms during this window may not be
   immediately reflected in BookBed.

2. NO GUARANTEE: We do not guarantee real-time synchronization with
   third-party platforms (Booking.com, Airbnb, etc.). Platform outages,
   rate limits, or changes to their iCal format may affect sync reliability.

3. OWNER RESPONSIBILITY: Property owners are responsible for:
   - Verifying calendar accuracy after initial setup
   - Monitoring for sync errors in the dashboard
   - Manually blocking dates if sync issues are detected
   - Resolving any double-bookings that may occur

4. LIABILITY: BookBed shall not be held liable for:
   - Double bookings resulting from sync delays or failures
   - Guest compensation or relocation costs
   - Lost revenue due to sync issues
   - Any damages arising from calendar synchronization failures

5. RECOMMENDATION: For properties with high booking volume, we recommend:
   - Using real-time channel managers (paid services)
   - Keeping a buffer day between bookings
   - Regularly checking sync status in the dashboard
```

---

## 8. Testing Checklist

### Before Deployment

- [ ] Export includes native bookings ✅ (current)
- [ ] Export includes imported ical_events (after fix)
- [ ] Export excludes events with `?exclude={source}` param
- [ ] Circular sync test: Import from platform A, export to A, verify no duplicates
- [ ] Race condition test: Simultaneous booking on widget + external platform
- [ ] Date accuracy: Check-in/check-out dates match across all systems
- [ ] Timezone test: Bookings from different timezones display correctly
- [ ] Empty calendar: Export valid iCal even with no events

### Integration Tests

- [ ] Import → Booking.com export includes imported events
- [ ] Import → Same-source export excludes imported events
- [ ] Widget calendar shows all sources correctly
- [ ] Overlap detection warns user

---

## 9. FAQ for Owners

### Q: Why do I need different export URLs for different platforms?

A: To prevent circular syncs. If you import your Booking.com calendar AND export
to Booking.com, without filtering, Booking.com would re-import its own reservations
as duplicates.

### Q: Can I use the same export URL for all platforms?

A: Yes, you can use the generic URL (without `?exclude=` parameter). However,
if you're also importing from a platform, you MUST use the filtered URL for
that platform's export.

### Q: What's the sync delay?

A: BookBed syncs external calendars every 15 minutes. Bookings made on external
platforms may take up to 15 minutes to appear in BookBed.

### Q: What if I see a double booking?

A: Contact both guests immediately. The booking with the earlier timestamp
typically has priority. You may need to relocate one guest to alternative
accommodation.

---

## 10. Summary

| Issue | Status | Action |
|-------|--------|--------|
| Export missing ical_events | BUG | Fix in Phase 1 |
| Circular sync risk | RISK | Mitigate with exclude param |
| 15-min race condition | ACCEPTABLE | Document, add ToS disclaimer |
| Overlap detection | MISSING | Add in Phase 4 |
| Legal disclaimer | MISSING | Add to ToS |

**Recommendation**: Implement Phase 1 + Phase 2 immediately to enable hub model.
Phase 3 (per-platform URLs) can be done with UI update. Phase 4 (overlap warning)
is nice-to-have for UX improvement.
