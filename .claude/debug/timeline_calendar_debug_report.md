# Timeline Calendar Debug Report
## Issue: Multiple "Goran" Units Without Bookings

**Date:** 2025-12-07
**Status:** 🔴 INVESTIGATING

---

## 🎯 SYMPTOM

Timeline Calendar prikazuje:
- **7x "Goran" rows** (4 guests capacity) - **NO bookings displayed** ❌
- **1x "Rab" row** (6 guests capacity) - **Bookings visible** ✅

---

## 🔬 DATA FLOW ANALYSIS

### Step 1: How Units Are Loaded

```dart
// File: owner_calendar_provider.dart (lines 32-44)

@riverpod
Future<List<UnitModel>> allOwnerUnits(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesCalendarProvider.future);
  final repository = ref.watch(ownerPropertiesRepositoryProvider);

  final List<UnitModel> allUnits = [];

  for (final property in properties) {
    final units = await repository.getPropertyUnits(property.id);
    allUnits.addAll(units);  // ← Adds all units from each property
  }

  return allUnits;  // ← Returns complete list
}
```

**What This Does:**
1. Gets ALL properties for logged-in owner
2. For EACH property, loads all its units
3. Combines into single `allUnits` list
4. No duplicate removal or filtering

**Potential Issues:**
- ✅ **Correct**: Each unit appears once in list
- ❌ **Problem**: If database has 7 separate "Goran" units, they'll ALL show

---

### Step 2: How Bookings Are Filtered

```dart
// File: owner_calendar_provider.dart (lines 48-86)

@riverpod
Future<Map<String, List<BookingModel>>> calendarBookings(Ref ref) async {
  final repository = ref.watch(ownerBookingsRepositoryProvider);

  // Get bookings for date range
  final allBookings = await repository.getCalendarBookings(
    ownerId: userId,
    startDate: startDate,  // 3 months ago
    endDate: endDate,      // 1 year future
  );

  // FILTER: Only show active bookings (pending + confirmed)
  final activeBookingsMap = <String, List<BookingModel>>{};
  for (final entry in allBookings.entries) {
    final activeBookings = entry.value
        .where((booking) =>
            booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed)
        .toList();
    if (activeBookings.isNotEmpty) {
      activeBookingsMap[entry.key] = activeBookings;  // ← Only units WITH bookings
    }
  }

  return activeBookingsMap;  // ← Map: unitId → List<BookingModel>
}
```

**What This Does:**
1. Loads ALL bookings for owner (3 months past → 1 year future)
2. Filters to show ONLY `pending` and `confirmed` status
3. Groups bookings by `unit_id`
4. **IMPORTANT**: Only includes units that HAVE bookings in the map

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
// File: timeline_calendar_widget.dart (line 785-799)

Widget _buildTimelineGrid(
  List<UnitModel> units,
  Map<String, List<BookingModel>> bookingsByUnit,
  ...
) {
  return Container(
    child: Column(
      children: units.map((unit) {  // ← Iterates over ALL units
        final bookings = bookingsByUnit[unit.id] ?? [];  // ← Gets bookings for this unit
        return _buildUnitRow(unit, bookings, dates, offsetWidth, bookingsByUnit);
      }).toList(),
    ),
  );
}
```

**Logical Flow:**
```
FOR EACH unit in units:
    bookings = bookingsByUnit[unit.id] ?? []

    IF unit.id NOT in bookingsByUnit:
        bookings = []  ← Empty list!

    Create row with bookings (even if empty)
```

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
- These units likely have NO bookings in date range (3 months ago → 1 year future)
- OR bookings exist but status is `completed` or `cancelled` (filtered out)

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

### Step 2: Add Debug Logging

**File:** `timeline_calendar_widget.dart`

Add logging to `_buildTimelineGrid`:

```dart
Widget _buildTimelineGrid(
  List<UnitModel> units,
  Map<String, List<BookingModel>> bookingsByUnit,
  ...
) {
  // DEBUG: Log unit info
  print('═══════════════════════════════════════');
  print('📊 TIMELINE GRID DEBUG');
  print('Total units: ${units.length}');
  print('Units with bookings: ${bookingsByUnit.length}');

  for (final unit in units) {
    final bookingCount = bookingsByUnit[unit.id]?.length ?? 0;
    print('  • ${unit.name} (${unit.id}) - ${bookingCount} bookings');
  }
  print('═══════════════════════════════════════');

  return Container(
    child: Column(
      children: units.map((unit) {
        final bookings = bookingsByUnit[unit.id] ?? [];
        return _buildUnitRow(unit, bookings, dates, offsetWidth, bookingsByUnit);
      }).toList(),
    ),
  );
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
- If yes, what status? (`completed`, `cancelled`, `pending`, `confirmed`)
- Are bookings outside the 3-month-past → 1-year-future range?

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

**Modify `_buildTimelineGrid` to filter empty units:**

```dart
Widget _buildTimelineGrid(
  List<UnitModel> units,
  Map<String, List<BookingModel>> bookingsByUnit,
  ...
) {
  // FILTER: Only show units that have bookings
  final unitsWithBookings = units.where((unit) {
    final bookings = bookingsByUnit[unit.id] ?? [];
    return bookings.isNotEmpty;
  }).toList();

  return Container(
    child: Column(
      children: unitsWithBookings.map((unit) {  // ← Use filtered list
        final bookings = bookingsByUnit[unit.id] ?? [];
        return _buildUnitRow(unit, bookings, dates, offsetWidth, bookingsByUnit);
      }).toList(),
    ),
  );
}
```

**Pros:**
- Quick fix
- Timeline only shows relevant units

**Cons:**
- Can't create bookings for units without existing bookings
- Hides available units

---

### Solution 4: Add "Show Empty Units" Toggle

**Best UX solution:**

1. Add toggle button in calendar toolbar
2. When enabled: Show ALL units (current behavior)
3. When disabled: Show only units with bookings

```dart
// Add state
bool _showEmptyUnits = true;

// Modify _buildTimelineGrid
final visibleUnits = _showEmptyUnits
    ? units
    : units.where((u) => bookingsByUnit[u.id]?.isNotEmpty ?? false).toList();
```

---

## 📋 RECOMMENDED ACTION PLAN

### Immediate (Today):

1. **Add Debug Logging** (Step 2 above)
   - Identify exact unit IDs
   - Confirm our theory

2. **Inspect Firestore**
   - Check how many "Goran" units exist
   - Verify they're separate documents

### Short-term (This Week):

3. **Clean Up Database**
   - Delete duplicate units (if any)
   - OR mark inactive units as `isActive: false`

4. **Filter Inactive Units in Provider**
   - Update `allOwnerUnitsProvider` to exclude inactive

### Long-term (Future):

5. **Add Unit Management UI**
   - Bulk edit/delete units
   - Mark units as archived instead of deleting

6. **Add "Show Empty Units" Toggle**
   - Better UX for large properties

---

## 🎓 KEY LEARNINGS

### Why This Happens:

1. **No Duplicate Prevention:**
   - `allOwnerUnitsProvider` doesn't check for duplicate names
   - Firestore allows multiple docs with same field values

2. **Timeline Shows ALL Units:**
   - By design, timeline doesn't filter empty units
   - Allows creating bookings for any unit

3. **Booking Filtering:**
   - Only `pending` and `confirmed` bookings show
   - Other statuses (`completed`, `cancelled`) are hidden

---

## 📊 EXPECTED VS ACTUAL

### Expected Behavior:
```
Timeline shows:
├── Goran (4 guests) → 2 bookings
├── Rab (6 guests) → 3 bookings
└── Villa Sunset (8 guests) → 0 bookings (but available for booking)
```

### Actual Behavior:
```
Timeline shows:
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 1
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 2
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 3
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 4
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 5
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 6
├── Goran (4 guests) → 0 bookings  ❌ Duplicate 7
└── Rab (6 guests) → 3 bookings    ✅ Correct
```

---

## 🔗 RELATED FILES

| File | Purpose | Lines |
|------|---------|-------|
| `owner_calendar_provider.dart` | Loads units and bookings | 32-86 |
| `timeline_calendar_widget.dart` | Renders timeline UI | 785-843 |
| `calendar_filters_provider.dart` | Applies filters | 174-277 |
| `firebase_unit_repository.dart` | Database queries | Check `getPropertyUnits` method |

---

## ✅ NEXT STEPS

Run debug logging and report back with:
1. Console output from Step 2
2. Firestore screenshot showing "Goran" units
3. Count of total units in database

This will confirm the root cause and guide the fix.

---

**Status:** 🔄 AWAITING DEBUG DATA
**Priority:** HIGH
**Impact:** UX - Timeline cluttered with duplicate/empty units
