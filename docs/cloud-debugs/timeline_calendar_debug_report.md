# Timeline Calendar Debug Report
## Issue: Multiple "Goran" Units Without Bookings

**Date:** 2025-12-07
**Status:** 🟡 PARTIALLY RESOLVED (Solution 4 implemented)
**Implementation Date:** 2025-01-XX

---

## 🎯 SYMPTOM

Timeline Calendar prikazuje:
- **7x "Goran" rows** (4 guests capacity) - **NO bookings displayed** ❌
- **1x "Rab" row** (6 guests capacity) - **Bookings visible** ✅

---

## 🔬 DATA FLOW ANALYSIS

### Step 1: How Units Are Loaded

```dart
// File: owner_calendar_provider.dart (lines 34-54)

@Riverpod(keepAlive: true)
Future<List<UnitModel>> allOwnerUnits(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesCalendarProvider.future);
  final repository = ref.watch(ownerPropertiesRepositoryProvider);

  final List<UnitModel> allUnits = [];

  for (final property in properties) {
    final units = await repository.getPropertyUnits(property.id);

    // FILTER: Only include active units (not soft-deleted)
    final activeUnits = units.where((unit) => unit.deletedAt == null).toList();

    allUnits.addAll(activeUnits);  // ← Adds active units from each property
  }

  return allUnits;  // ← Returns complete list of active units
}
```

**What This Does:**
1. Gets ALL properties for logged-in owner
2. For EACH property, loads all its units
3. **UPDATED:** Filters out soft-deleted units (`deletedAt == null`)
4. Combines into single `allUnits` list
5. No duplicate removal or name-based filtering

**Potential Issues:**
- ✅ **Correct**: Each unit appears once in list
- ✅ **Fixed**: Soft-deleted units are now filtered out
- ❌ **Still an issue**: If database has 7 separate active "Goran" units, they'll ALL show

---

### Step 2: How Bookings Are Filtered

```dart
// File: owner_calendar_provider.dart (lines 56-107)

@riverpod
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);
  // ... authentication check ...

  // Date range: 1 year back to 1 year forward
  final allBookings = await repository.getCalendarBookingsWithUnitIds(
    unitIds: unitIds,
    startDate: startDate,
    endDate: endDate,
  );

  // FILTER: Show active bookings + completed (exclude only cancelled)
  final visibleBookingsMap = <String, List<BookingModel>>{};
  for (final entry in allBookings.entries) {
    final visibleBookings = entry.value
        .where((booking) => booking.status != BookingStatus.cancelled)
        .toList();
    if (visibleBookings.isNotEmpty) {
      visibleBookingsMap[entry.key] = visibleBookings;  // ← Only units WITH bookings
    }
  }

  return visibleBookingsMap;  // ← Map: unitId → List<BookingModel>
}
```

**What This Does:**
1. Loads ALL bookings for owner (1 year past → 1 year future)
2. **UPDATED:** Filters to show `pending`, `confirmed`, and `completed` bookings
3. **UPDATED:** Only excludes `cancelled` bookings (they don't occupy dates)
4. Groups bookings by `unit_id`
5. **IMPORTANT**: Only includes units that HAVE bookings in the map

**Result:**
```
activeBookingsMap = {
  "rab_unit_id": [booking1, booking2, ...],  // ✅ Rab has bookings
  // "goran_unit_id_1": []  ❌ NOT included (no active bookings)
  // "goran_unit_id_2": []  ❌ NOT included (no active bookings)
  // ... etc
}
```

---

### Step 3: Timeline Rendering Logic

```dart
// File: timeline_calendar_widget.dart (lines 635-642)

Widget _buildTimelineView(
  List<UnitModel> units,
  Map<String, List<BookingModel>> bookingsByUnit,
) {
  // FILTER: Optionally hide units without bookings based on toggle
  final visibleUnits = widget.showEmptyUnits
      ? units
      : units.where((unit) {
          final bookings = bookingsByUnit[unit.id] ?? [];
          return bookings.isNotEmpty;
        }).toList();

  // ... rest of rendering logic ...
}
```

**Logical Flow:**
```
IF showEmptyUnits toggle is ON:
    visibleUnits = all units  ← Shows all units (default)
ELSE:
    visibleUnits = units.filter(has bookings)  ← Only units with bookings

FOR EACH unit in visibleUnits:
    bookings = bookingsByUnit[unit.id] ?? []
    Create row with bookings
```

**UPDATED:** Filter logic now respects `showEmptyUnits` toggle state.

**Example:**
```
units = [goran1, goran2, goran3, ..., goran7, rab]
bookingsByUnit = { "rab_id": [booking1, booking2] }

Result:
├── goran1 → bookings: [] ❌
├── goran2 → bookings: [] ❌
├── goran3 → bookings: [] ❌
├── goran4 → bookings: [] ❌
├── goran5 → bookings: [] ❌
├── goran6 → bookings: [] ❌
├── goran7 → bookings: [] ❌
└── rab → bookings: [booking1, booking2] ✅
```

---

## 🧩 ROOT CAUSE ANALYSIS

### Theory 1: Database Has 7 "Goran" Units ⭐ MOST LIKELY

**Evidence:**
- Timeline shows exactly 7 "Goran" rows
- All have same capacity (4 guests)
- `allOwnerUnits` provider doesn't filter duplicates
- Each row likely represents a separate Firestore document

**Database Structure:**
```
properties/
  └── property_id_1/
      └── units/
          ├── goran_unit_1  (name: "Goran", capacity: 4)
          ├── goran_unit_2  (name: "Goran", capacity: 4)
          ├── goran_unit_3  (name: "Goran", capacity: 4)
          ├── goran_unit_4  (name: "Goran", capacity: 4)
          ├── goran_unit_5  (name: "Goran", capacity: 4)
          ├── goran_unit_6  (name: "Goran", capacity: 4)
          ├── goran_unit_7  (name: "Goran", capacity: 4)
          └── rab_unit_1    (name: "Rab", capacity: 6)
```

**Why No Bookings Show:**
- These units likely have NO bookings in date range (1 year past → 1 year future)
- OR bookings exist but status is `cancelled` (filtered out)
- **NOTE:** `completed` bookings are now shown (updated in provider)

---

### Theory 2: Multiple Properties with "Goran" Units

**Evidence:**
- User has multiple properties
- Each property has a unit named "Goran"

**Database Structure:**
```
properties/
  ├── property_jasko/
  │   └── units/
  │       └── goran  (name: "Goran", capacity: 4)
  ├── property_villa_marija/
  │   └── units/
  │       └── goran  (name: "Goran", capacity: 4)
  └── ... (5 more properties with "Goran" units)
```

---

### Theory 3: Stale/Orphaned Unit Documents

**Evidence:**
- Old units that weren't properly deleted
- Still exist in Firestore but no longer used

---

## 🔧 DEBUGGING STEPS

### Step 1: Inspect Firestore Database

**Firebase Console → Firestore Database:**

1. Navigate to `properties` collection
2. For each property, open `units` subcollection
3. Count how many units have `name: "Goran"`
4. Check `id`, `propertyId`, and `isActive` fields

**Expected Findings:**
```
If Theory 1 is correct:
  → You'll find 7 separate unit documents with name "Goran"

If Theory 2 is correct:
  → You'll find 1 "Goran" unit per property (7 properties total)

If Theory 3 is correct:
  → Some "Goran" units will have isActive: false or be orphaned
```

---

### Step 2: Add Debug Logging (Optional - for database investigation)

**File:** `timeline_calendar_widget.dart`

Add logging to `_buildTimelineView` (note: method name changed from `_buildTimelineGrid`):

```dart
Widget _buildTimelineView(
  List<UnitModel> units,
  Map<String, List<BookingModel>> bookingsByUnit,
) {
  // DEBUG: Log unit info
  print('═══════════════════════════════════════');
  print('📊 TIMELINE GRID DEBUG');
  print('Total units: ${units.length}');
  print('Units with bookings: ${bookingsByUnit.length}');
  print('Show empty units: ${widget.showEmptyUnits}');

  for (final unit in units) {
    final bookingCount = bookingsByUnit[unit.id]?.length ?? 0;
    print('  • ${unit.name} (${unit.id}) - ${bookingCount} bookings');
  }
  print('═══════════════════════════════════════');

  // FILTER: Optionally hide units without bookings based on toggle
  final visibleUnits = widget.showEmptyUnits
      ? units
      : units.where((unit) {
          final bookings = bookingsByUnit[unit.id] ?? [];
          return bookings.isNotEmpty;
        }).toList();

  // ... rest of implementation ...
}
```

**Run App and Check Console:**
```bash
flutter run
# Navigate to Timeline Calendar
# Check console output
```

**Expected Output:**
```
═══════════════════════════════════════
📊 TIMELINE GRID DEBUG
Total units: 8
Units with bookings: 1
  • Goran (unit_abc123) - 0 bookings
  • Goran (unit_abc124) - 0 bookings
  • Goran (unit_abc125) - 0 bookings
  • Goran (unit_abc126) - 0 bookings
  • Goran (unit_abc127) - 0 bookings
  • Goran (unit_abc128) - 0 bookings
  • Goran (unit_abc129) - 0 bookings
  • Rab (unit_xyz789) - 3 bookings
═══════════════════════════════════════
```

This will show:
- Exact `unit.id` for each "Goran"
- Whether they're truly different units (different IDs)

---

### Step 3: Check Bookings in Database

**For each "Goran" unit ID from Step 2:**

1. Go to Firestore Console → `bookings` collection
2. Filter by `unit_id == <goran_unit_id>`
3. Check booking `status` and dates

**Questions:**
- Do these units have ANY bookings?
- If yes, what status? (`cancelled` bookings are hidden, others are shown)
- Are bookings outside the 1-year-past → 1-year-future range?

---

## 💡 SOLUTIONS

### Solution 1: Clean Up Duplicate Units (If Theory 1/3)

**If database has duplicate "Goran" units:**

1. **Identify Which to Keep:**
   - Check which unit has bookings
   - Check which unit is active/published
   - Choose the "correct" one

2. **Delete Others:**
   ```
   Firebase Console → Firestore → properties/{propertyId}/units
   - Select duplicate units
   - Click Delete
   ```

3. **OR Mark as Inactive:**
   ```dart
   // Update unit document
   {
     "is_active": false,
     "is_published": false
   }
   ```

4. **Update Provider to Filter Inactive Units:**
   ```dart
   // In allOwnerUnitsProvider:
   for (final property in properties) {
     final units = await repository.getPropertyUnits(property.id);
     final activeUnits = units.where((u) => u.isActive && u.isPublished);  // ← Filter
     allUnits.addAll(activeUnits);
   }
   ```

---

### Solution 2: Rename Units for Clarity (If Theory 2)

**If different properties have units with same name:**

1. Update unit names to be unique:
   ```
   "Goran" → "Goran - Villa Marija"
   "Goran" → "Goran - Apartment Sunset"
   ```

2. This makes timeline more readable

---

### Solution 3: Show Only Units with Bookings (Quick Fix)

**Status:** ⚠️ SUPERSEDED by Solution 4

This solution was considered but replaced with Solution 4 (toggle) for better UX.

**Pros:**
- Quick fix
- Timeline only shows relevant units

**Cons:**
- Can't create bookings for units without existing bookings
- Hides available units
- Less flexible than toggle approach

---

### Solution 4: Add "Show Empty Units" Toggle ✅ IMPLEMENTED

**Status:** ✅ COMPLETED

**Best UX solution - now implemented:**

1. ✅ Toggle button added in calendar toolbar (desktop and mobile)
2. ✅ When enabled: Show ALL units (default behavior)
3. ✅ When disabled: Show only units with bookings

**Implementation:**
```dart
// State in owner_timeline_calendar_screen.dart
bool _showEmptyUnits = true; // Default: show all

// Filter logic in timeline_calendar_widget.dart
final visibleUnits = widget.showEmptyUnits
    ? units
    : units.where((unit) {
        final bookings = bookingsByUnit[unit.id] ?? [];
        return bookings.isNotEmpty;
      }).toList();
```

**See "Implementation Status" section above for full details.**

---

## 📋 RECOMMENDED ACTION PLAN

### ✅ Completed:

6. **Add "Show Empty Units" Toggle** - ✅ COMPLETED
   - Toggle button added to calendar toolbar
   - Filter logic implemented in timeline widget
   - Localization keys added
   - Better UX for large properties

### Immediate (If Needed):

1. **Add Debug Logging** (Step 2 above) - Optional
   - Identify exact unit IDs
   - Confirm duplicate units theory
   - Useful for database cleanup planning

2. **Inspect Firestore** - Optional
   - Check how many "Goran" units exist
   - Verify they're separate documents
   - Determine if cleanup is needed

### Short-term (If Duplicates Found):

3. **Clean Up Database** - If duplicates exist
   - Delete duplicate units (if any)
   - OR mark inactive units as `isActive: false`

4. **Filter Inactive Units in Provider** - If needed
   - Update `allOwnerUnitsProvider` to exclude inactive
   - Note: Currently filters `deletedAt == null` (soft-deleted units)

### Long-term (Future Enhancements):

5. **Add Unit Management UI**
   - Bulk edit/delete units
   - Mark units as archived instead of deleting

7. **Persist Toggle State** - Future enhancement
   - Save `_showEmptyUnits` preference in user settings
   - Restore on app restart

---

## 🎓 KEY LEARNINGS

### Why This Happens:

1. **No Duplicate Prevention:**
   - `allOwnerUnitsProvider` doesn't check for duplicate names
   - Firestore allows multiple docs with same field values
   - Provider now filters soft-deleted units (`deletedAt == null`)

2. **Timeline Shows ALL Units:**
   - By design, timeline shows all active units by default
   - Allows creating bookings for any unit
   - **UPDATE:** Toggle now available to hide empty units for better UX

3. **Booking Filtering:**
   - **UPDATED:** Shows `pending`, `confirmed`, and `completed` bookings
   - Only `cancelled` bookings are hidden (they don't occupy dates)
   - Completed bookings included for historical visibility

### Implementation Notes:

4. **Toggle Implementation:**
   - Filter applied in `_buildTimelineView` method (not in provider)
   - Avoids circular dependency issues
   - No performance impact (simple list filter)
   - Default shows all units (backward compatible)

---

## 📊 EXPECTED VS ACTUAL

### Expected Behavior:
```
Timeline shows:
├── Goran (4 guests) → 2 bookings
├── Rab (6 guests) → 3 bookings
└── Villa Sunset (8 guests) → 0 bookings (but available for booking)
```

### Actual Behavior (Before Toggle):
```
Timeline shows (when toggle is ON - default):
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 1
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 2
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 3
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 4
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 5
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 6
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 7
└── Rab (6 guests) → 3 bookings    ✅ Correct
```

### Actual Behavior (After Toggle OFF):
```
Timeline shows (when toggle is OFF):
└── Rab (6 guests) → 3 bookings    ✅ Only units with bookings
```

**Note:** Toggle allows users to hide empty units, providing immediate UX improvement.

---

## 🔗 RELATED FILES

| File | Purpose | Lines |
|------|---------|-------|
| `owner_calendar_provider.dart` | Loads units and bookings | 34-107 |
| `timeline_calendar_widget.dart` | Renders timeline UI, filter logic | 635-642 (filter), 48-72 (props) |
| `owner_timeline_calendar_screen.dart` | Screen state, toggle state | 42, 154-159, 192 |
| `calendar_top_toolbar.dart` | Toolbar with toggle button | 29-31, 59-60, 236-244, 308-317 |
| `calendar_filters_provider.dart` | Applies filters | 174-277 |
| `firebase_unit_repository.dart` | Database queries | Check `getPropertyUnits` method |
| `app_en.arb` / `app_hr.arb` | Localization keys | `ownerCalendarHideEmptyUnits`, `ownerCalendarShowEmptyUnits` |

---

## ✅ NEXT STEPS

Run debug logging and report back with:
1. Console output from Step 2
2. Firestore screenshot showing "Goran" units
3. Count of total units in database

This will confirm the root cause and guide the fix.

---

**Status:** 🟡 PARTIALLY RESOLVED (Solution 4 implemented)
**Priority:** MEDIUM (UX improvement implemented, database cleanup may still be needed)
**Impact:** UX - Timeline cluttered with duplicate/empty units (mitigated with toggle)

---

## ✅ IMPLEMENTATION STATUS

### Solution 4: "Show Empty Units" Toggle - COMPLETED

**Implementation Date:** 2025-01-XX

**Status:** ✅ IMPLEMENTED

A toggle button has been added to the calendar toolbar that allows users to show/hide units without bookings. This provides immediate UX improvement while database cleanup can be addressed separately.

**Files Changed:**
- `lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart`
  - Added `_showEmptyUnits` state variable (default: `true`)
  - Passes toggle state to `CalendarTopToolbar` and `TimelineCalendarWidget`

- `lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart`
  - Added `showEmptyUnits` prop (default: `true`)
  - Implemented filter logic in `_buildTimelineView` method (lines 635-642)
  - Filters units: `units.where((unit) => bookingsByUnit[unit.id]?.isNotEmpty ?? false)`

- `lib/features/owner_dashboard/presentation/widgets/calendar/calendar_top_toolbar.dart`
  - Added `showEmptyUnitsToggle`, `isEmptyUnitsVisible`, and `onEmptyUnitsToggleChanged` props
  - Added toggle button for desktop mode (icon button)
  - Added menu item for mobile/compact mode (popup menu)

- `lib/l10n/app_en.arb` and `lib/l10n/app_hr.arb`
  - Added `ownerCalendarHideEmptyUnits` / `ownerCalendarShowEmptyUnits` keys

**How It Works:**
- Default behavior: Shows all units (including those without bookings) - `_showEmptyUnits = true`
- When toggle is OFF: Filters to only show units that have bookings
- Filter logic: Checks if `bookingsByUnit[unit.id]` is not empty
- User can toggle at any time via toolbar button

**User Experience:**
- Desktop: Icon button in toolbar with visibility icon (`Icons.visibility` / `Icons.visibility_off`)
- Mobile: Menu item in overflow menu
- Tooltip: "Show empty units" / "Hide empty units"
- State persists during session (resets on app restart to default: show all)

**Benefits:**
- Immediate UX improvement - users can hide cluttered empty units
- Flexible - users can still see all units when needed (for creating bookings)
- No breaking changes - default behavior unchanged
- No database changes required

**Limitations:**
- Does not solve root cause (duplicate units in database)
- Toggle state resets on app restart
- Debug logging (Solution 2) still recommended for identifying duplicate units

**Next Steps:**
- Debug logging (Solution 2) can still be used to identify duplicate units in database
- Database cleanup (Solution 1) may still be needed if there are actual duplicate units
- Consider persisting toggle state in user preferences for future enhancement
