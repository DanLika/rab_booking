# Feature Plan: Bookings Screen Design System Migration

**Status**: Ready for Implementation
**Last Updated**: 2025-12-04
**Estimated Complexity**: Medium (7 files, ~2000 lines affected)

---

## 🎯 Objective

Migrate the Owner Bookings screen (`/owner/bookings`) and all related dialogs to use the centralized design system (`AppGradients`, `AppShadows`, theme-aware styling) for consistent light/dark mode support.

**Current State**:
- ✅ Main screen already uses `context.gradients.pageBackground`
- ❌ Empty state, error state, filters use inline colors/no gradients
- ❌ 6 dialogs use old `GradientTokens.brandPrimary` and `AppColors`
- ❌ No `AppShadows` usage in dialogs
- ❌ Hardcoded inline gradients in action dialogs

**Target State**:
- All components use `context.gradients` (pageBackground, sectionBackground, brandPrimary, sectionBorder)
- All dialogs use `AppShadows.elevation3` or higher
- No `GradientTokens` or inline gradient definitions
- Full light/dark mode theme awareness

---

## 📋 Implementation Checklist

### 1. Main Screen: `owner_bookings_screen.dart` (Partial Update)
**Status**: 🟡 Partially Complete
**Lines Affected**: ~150 lines
**Changes**:

- [x] Main background gradient - ALREADY DONE ✅
- [ ] **Filters Section** (Line ~300-350):
  - Replace `Card` wrapper with `Container`
  - Add `decoration: BoxDecoration(gradient: context.gradients.sectionBackground)`
  - Add `border: Border.all(color: context.gradients.sectionBorder)`
  - Add `boxShadow: AppShadows.elevation2`
  - Keep `borderRadius: BorderRadius.circular(12)`

- [ ] **Empty State Icon Container** (Line ~450-480):
  ```dart
  // BEFORE:
  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)

  // AFTER:
  decoration: BoxDecoration(
    gradient: context.gradients.sectionBackground,
    shape: BoxShape.circle,
    boxShadow: AppShadows.elevation1,
  )
  ```

- [ ] **Error State** (Line ~500-530):
  - Wrap error icon in `Container` with `sectionBackground` gradient
  - Add `AppShadows.elevation2`
  - Remove inline `colorScheme.error.withAlpha()`

- [ ] **Booking Card Widget** (`_BookingCard`, Line ~600-800):
  - Replace `Card` with `Container`
  - Add `gradient: context.gradients.sectionBackground`
  - Add `border: Border.all(color: context.gradients.sectionBorder)`
  - Add `boxShadow: AppShadows.elevation2`

---

### 2. Booking Details Dialog: `booking_details_dialog.dart`
**Status**: ❌ Not Started
**Lines Affected**: ~200 lines
**Changes**:

- [ ] **Dialog Header** (Line ~150-180):
  ```dart
  // BEFORE:
  decoration: const BoxDecoration(
    gradient: GradientTokens.brandPrimary,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  )

  // AFTER:
  decoration: BoxDecoration(
    gradient: context.gradients.brandPrimary,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    boxShadow: AppShadows.elevation3,
  )
  ```

- [ ] **Dialog Content Container** (Line ~200-250):
  - Add outer `Container` wrapper
  - Apply `gradient: context.gradients.sectionBackground`
  - Add `border: Border.all(color: context.gradients.sectionBorder)`
  - Add `boxShadow: AppShadows.elevation3`

- [ ] **Section Headers** (`_SectionHeader`, Line ~400-450):
  - Replace `GradientTokens.brandPrimary` with `context.gradients.brandPrimary`
  - Add `AppShadows.elevation1`

- [ ] **Payment Status Colors** (Line ~300-320):
  ```dart
  // BEFORE:
  color: AppColors.success / AppColors.warning

  // AFTER:
  color: Theme.of(context).colorScheme.primary (for success)
  color: Theme.of(context).colorScheme.error (for pending/failed)
  ```

---

### 3. Filters Dialog: `bookings_filters_dialog.dart`
**Status**: ❌ Not Started
**Lines Affected**: ~150 lines
**Changes**:

- [ ] **Dialog Header** (Line ~100-130):
  - Replace `GradientTokens.brandPrimary` with `context.gradients.brandPrimary`
  - Add `boxShadow: AppShadows.elevation3`

- [ ] **Dialog Body** (Line ~150-300):
  - Wrap content in `Container`
  - Apply `gradient: context.gradients.sectionBackground`
  - Add `border: Border.all(color: context.gradients.sectionBorder, width: 1)`
  - Add `boxShadow: AppShadows.elevation2`

- [ ] **Apply Button** (Line ~480-500):
  - Keep `GradientTokens.brandPrimary` for button OR use `context.gradients.brandPrimary`
  - Buttons can keep brand gradient for emphasis

---

### 4. Action Dialogs (Approve, Reject, Cancel, Complete)

#### 4.1 `booking_approve_dialog.dart`
**Status**: ❌ Not Started
**Lines Affected**: ~40 lines
**Changes**:

- [ ] **Header Gradient** (Line ~40-60):
  ```dart
  // BEFORE:
  gradient: LinearGradient(
    colors: [
      AppColors.success.withAlpha((0.85 * 255).toInt()),
      AppColors.success,
    ],
  )

  // AFTER:
  decoration: BoxDecoration(
    gradient: context.gradients.brandPrimary, // Use brand for all action dialogs
    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    boxShadow: AppShadows.elevation4,
  )
  ```

- [ ] **Dialog Container**:
  - Add `gradient: context.gradients.sectionBackground` to content area
  - Add `border: Border.all(color: context.gradients.sectionBorder)`

#### 4.2 `booking_reject_dialog.dart`
**Status**: ❌ Not Started
**Lines Affected**: ~50 lines
**Changes**:

- [ ] Same pattern as approve dialog
- [ ] Replace `theme.colorScheme.error` inline gradient with `context.gradients.brandPrimary`
- [ ] Add `AppShadows.elevation4` to header

#### 4.3 `booking_cancel_dialog.dart`
**Status**: ❌ Not Started
**Lines Affected**: ~50 lines
**Changes**:

- [ ] Same pattern as approve dialog
- [ ] Replace `AppColors.warning` inline gradient with `context.gradients.brandPrimary`
- [ ] Add `AppShadows.elevation4` to header

#### 4.4 `booking_complete_dialog.dart`
**Status**: ❌ Not Started
**Lines Affected**: ~40 lines
**Changes**:

- [ ] Replace `GradientTokens.brandPrimary` with `context.gradients.brandPrimary`
- [ ] Add `AppShadows.elevation4` to header
- [ ] Add `gradient: context.gradients.sectionBackground` to content area
- [ ] Add border with `context.gradients.sectionBorder`

---

## 🎨 Design System Reference

### Gradients (`context.gradients`)
```dart
// Page background (main screen)
gradient: context.gradients.pageBackground
// Direction: topLeft → bottomRight
// Stops: [0.0, 0.3]

// Section/Card background
gradient: context.gradients.sectionBackground
// Direction: centerRight → centerLeft (top right → bottom left)
// Stops: [0.0, 0.3]

// Brand gradient (headers, buttons)
gradient: context.gradients.brandPrimary
// Direction: topLeft → bottomRight
// Colors: Purple (#6B4CE6 → #7E5FEE)

// Section border
border: Border.all(color: context.gradients.sectionBorder)
// Light: #E8E5DC, Dark: #3D3733
```

### Shadows (`AppShadows`)
```dart
// Cards, chips (1dp)
boxShadow: AppShadows.elevation1

// Floating buttons, dropdowns (2-4dp)
boxShadow: AppShadows.elevation2

// Modals, app bars (6-8dp)
boxShadow: AppShadows.elevation3

// Dialogs, sheets (12-16dp) - USE FOR ACTION DIALOGS
boxShadow: AppShadows.elevation4

// Dark mode (auto-detected via isDark parameter)
AppShadows.getElevation(level, isDark: true)
```

### Border Radius
- Inputs, small cards: `12px`
- Dialogs: `12px`
- Buttons: `8-12px`

---

## 🚨 Critical Rules

1. **Never use**:
   - `GradientTokens.*` (old static system)
   - `AppColors.success/warning/error` for backgrounds (use theme colors)
   - Inline `LinearGradient()` definitions
   - Hardcoded color values with `withAlpha()` / `withValues()`

2. **Always use**:
   - `context.gradients.*` for all backgrounds
   - `AppShadows.elevation*` for depth
   - `Theme.of(context).colorScheme.*` for semantic colors
   - `context.gradients.sectionBorder` for all borders

3. **Testing**:
   - Test BOTH light and dark mode
   - Verify gradients fade at 30% (`stops: [0.0, 0.3]`)
   - Check section gradients go right → left
   - Verify shadows adapt to theme

---

## 📦 Files to Modify

1. `lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart` (partial)
2. `lib/features/owner_dashboard/presentation/widgets/booking_details_dialog.dart`
3. `lib/features/owner_dashboard/presentation/widgets/bookings/bookings_filters_dialog.dart`
4. `lib/features/owner_dashboard/presentation/widgets/booking_actions/booking_approve_dialog.dart`
5. `lib/features/owner_dashboard/presentation/widgets/booking_actions/booking_reject_dialog.dart`
6. `lib/features/owner_dashboard/presentation/widgets/booking_actions/booking_cancel_dialog.dart`
7. `lib/features/owner_dashboard/presentation/widgets/booking_actions/booking_complete_dialog.dart`

**Total**: 7 files, ~2000 lines affected

---

## ✅ Acceptance Criteria

- [ ] All dialogs use `context.gradients.brandPrimary` for headers
- [ ] All dialogs use `context.gradients.sectionBackground` for content areas
- [ ] All dialogs use `AppShadows.elevation3` or `elevation4`
- [ ] All cards/sections use `sectionBackground` + `sectionBorder`
- [ ] No `GradientTokens` imports remaining
- [ ] No inline `LinearGradient()` definitions
- [ ] `flutter analyze` = 0 issues
- [ ] Light mode tested and looks correct
- [ ] Dark mode tested and looks correct
- [ ] All gradients fade at 30% of container

---

## 🔄 Implementation Order

1. **Start with dialogs** (quick wins, most visible):
   - `booking_approve_dialog.dart`
   - `booking_reject_dialog.dart`
   - `booking_cancel_dialog.dart`
   - `booking_complete_dialog.dart`

2. **Complex dialogs**:
   - `booking_details_dialog.dart`
   - `bookings_filters_dialog.dart`

3. **Main screen polish**:
   - `owner_bookings_screen.dart` (empty state, error state, filters, cards)

4. **Final verification**:
   - Test all dialogs in light/dark mode
   - Screenshot comparison
   - `flutter analyze`

---

**Estimated Time**: 3-4 hours total
**Risk Level**: Low (design-only changes, no business logic)
**Rollback**: Easy (each file is independent)
