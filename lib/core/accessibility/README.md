# Accessibility & Error Handling Guide

## 🎯 Overview

This guide covers the accessibility helpers and error handling infrastructure added to improve UX for all users, including those with disabilities.

## 🔍 Accessibility Helpers

### Purpose
Provide semantic labels to interactive widgets for screen reader support (TalkBack, VoiceOver).

### Location
`lib/core/accessibility/accessibility_helpers.dart`

---

## 📦 Available Widgets

### 1. AccessibleIconButton
Replaces `IconButton` with semantic label.

```dart
// ❌ Before (no accessibility)
IconButton(
  icon: Icon(Icons.close),
  onPressed: () => Navigator.pop(context),
)

// ✅ After (accessible)
AccessibleIconButton(
  icon: Icons.close,
  semanticLabel: 'Close dialog',
  onPressed: () => Navigator.pop(context),
)
```

### 2. AccessibleInkWell
Replaces `InkWell` with semantic label.

```dart
// ✅ Accessible InkWell
AccessibleInkWell(
  semanticLabel: 'Select payment method',
  onTap: () => selectPayment(),
  child: PaymentMethodWidget(),
)
```

### 3. AccessibleGestureDetector
Replaces `GestureDetector` with semantic label.

```dart
// ✅ Accessible GestureDetector
AccessibleGestureDetector(
  semanticLabel: 'Open calendar',
  onTap: () => showCalendar(),
  child: CalendarIcon(),
)
```

### 4. AccessibleCard
Card with semantic label for navigation.

```dart
// ✅ Accessible Card
AccessibleCard(
  semanticLabel: 'Booking details card',
  onTap: () => viewDetails(),
  child: BookingDetailsContent(),
)
```

### 5. AccessibleImage
Image with semantic label for screen readers.

```dart
// ✅ Accessible Image
AccessibleImage(
  image: NetworkImage(propertyImageUrl),
  semanticLabel: 'Villa Marija property photo',
  width: 200,
  height: 150,
)
```

---

## 🔧 Extension Methods

### Add Semantics to Any Widget

```dart
// Add semantic label
Text('Book Now').withSemantics(
  label: 'Book now button',
  button: true,
);

// Exclude decorative widgets
Container(
  decoration: BoxDecoration(...),
).excludeFromSemantics();
```

---

## 📏 Tap Target Sizes

Minimum tap target: **44x44 dp** (Material Design guideline)

```dart
// Ensure minimum tap target
withMinTapTarget(
  child: Icon(Icons.favorite),
  size: A11yConstants.minTapTargetSize, // 44.0
)
```

---

## 🛡️ Error Boundary

### Purpose
Catch widget tree errors and show graceful fallback UI instead of red error screens.

### Location
`lib/core/error_handling/error_boundary.dart`

### Global Setup (already done in main.dart)

```dart
void main() {
  // Initialize error handling
  if (kReleaseMode) {
    // Production: Firebase Crashlytics
  } else {
    // Debug: Custom error handler
    GlobalErrorHandler.initialize();
  }

  runApp(...);
}
```

### Usage - Wrap Widgets with ErrorBoundary

```dart
// Wrap entire app (already in main.dart)
MaterialApp.router(
  builder: (context, child) {
    return ErrorBoundary(
      child: child!,
      onError: (details) {
        debugPrint('Error: ${details.exception}');
      },
    );
  },
)

// Wrap specific widgets
ErrorBoundary(
  child: ComplexFeatureWidget(),
  errorBuilder: (details) {
    return Center(
      child: Text('Feature temporarily unavailable'),
    );
  },
)
```

---

## 🎨 Best Practices

### 1. Always Add Semantic Labels

```dart
// ❌ BAD - No accessibility
IconButton(
  icon: Icon(Icons.delete),
  onPressed: deleteBooking,
)

// ✅ GOOD - Accessible
AccessibleIconButton(
  icon: Icons.delete,
  semanticLabel: 'Delete booking',
  onPressed: deleteBooking,
)
```

### 2. Use Descriptive Labels

```dart
// ❌ BAD - Generic label
semanticLabel: 'Button'

// ✅ GOOD - Descriptive label
semanticLabel: 'Confirm payment and complete booking'
```

### 3. Exclude Decorative Elements

```dart
// Decorative icon (doesn't add meaning)
Icon(Icons.star).excludeFromSemantics()

// Informational icon (adds meaning - keep accessible)
Icon(Icons.warning).withSemantics(
  label: 'Warning: Cancellation deadline approaching',
)
```

### 4. Test with Screen Readers

- **Android**: TalkBack (Settings → Accessibility → TalkBack)
- **iOS**: VoiceOver (Settings → Accessibility → VoiceOver)

---

## 📊 Migration Checklist

- [ ] Replace `IconButton` → `AccessibleIconButton`
- [ ] Replace `InkWell` → `AccessibleInkWell`
- [ ] Replace `GestureDetector` → `AccessibleGestureDetector`
- [ ] Add `semanticLabel` to all `Image` widgets
- [ ] Exclude decorative widgets with `excludeFromSemantics()`
- [ ] Test with TalkBack/VoiceOver
- [ ] Ensure minimum 44dp tap targets

---

## 🔗 Resources

- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
