# Layout Audit Report: 340px Width Constraints

## Overview
This audit identifies UI components in `lib/features/` that may break or overflow on devices with narrow screens (e.g., iPhone SE 1st Gen, width: 320px-340px).

## Critical Issues

### 1. `PopupBlockedDialog` Hardcoded Width
**Location:** `lib/features/widget/presentation/widgets/popup_blocked_dialog.dart`
**Issue:** The dialog content is constrained to a fixed width of **400px**.
**Impact:** On a 340px screen, this dialog will overflow horizontally, making it impossible to read the full text or access all options properly.
**Snippet:**
```dart
content: SizedBox(
  width: 400, // <--- CRITICAL OVERFLOW
  child: Column(
```
**Recommendation:**
Remove the fixed width or use `ConstrainedBox` with `maxWidth`.
```dart
content: ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 400),
  child: Column(...),
)
```

### 2. `BookingStatusChangeDialog` Tight Width
**Location:** `lib/features/owner_dashboard/presentation/widgets/calendar/booking_status_change_dialog.dart`
**Issue:** Hardcoded width of **320px**.
**Impact:** While 320px fits exactly on an iPhone SE, adding dialog margins (typically 24px-40px per side) implies the actual screen width required is ~368px+. This will likely cause the dialog to be squeezed or clipped on 340px screens.
**Snippet:**
```dart
child: Container(
  width: 320, // <--- Risk of overflow with margins
```
**Recommendation:**
Use relative width (e.g., `width: double.maxFinite` inside a dialog with inset padding) or `ConstrainedBox`.

## Potential Issues & Suggestions

### 3. `EmbedCodeGeneratorDialog` Fixed Height/Ratio
**Location:** `lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart`
**Issue:** Contains inline styles for copy-paste code with `min-height: 500px`.
**Impact:** If this logic is used to render a preview (not just text string), it might break on short screens (iPhone 8 is 667px, but effective viewport is smaller with browser bars).
**Recommendation:** Ensure `SingleChildScrollView` wraps any preview content.

### 4. `EmailVerificationDialog` Spacing
**Location:** `lib/features/widget/presentation/widgets/email_verification_dialog.dart`
**Issue:** Multiple `SizedBox(width: 8/12)` inside Rows.
**Impact:** Accumulation of fixed spacing in Rows without `Flexible` children can cause overflow if the text is long (e.g., German translations).
**Recommendation:** Ensure all text widgets inside these Rows are wrapped in `Expanded` or `Flexible`.

## General Recommendations for 340px Support

1.  **Replace `Row` with `Wrap`**: For lists of chips, tags, or pills, usage of `Wrap` prevents overflow.
2.  **Avoid Fixed Widths**: Replace `width: 400` with `constraints: BoxConstraints(maxWidth: 400)`.
3.  **Scrollable Dialogs**: Ensure all Dialog `content` widgets are wrapped in `SingleChildScrollView`.
4.  **Test on Small Devices**: Use the Chrome DevTools "Device Toolbar" set to "iPhone SE" (320px width) or a custom 340px width to verify layout resilience.
