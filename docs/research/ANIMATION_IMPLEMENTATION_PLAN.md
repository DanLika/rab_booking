# Flutter Animation Implementation Plan

**Status**: Ready for implementation
**Priority**: High-impact, low-effort items first
**Packages**: `flutter_animate: ^4.5.0`, `AnimationTokens` (custom)

---

## Quick Reference: AnimationTokens

```dart
import 'package:bookbed/core/design_tokens/animation_tokens.dart';

// Durations
AnimationTokens.instant  // 100ms - button press
AnimationTokens.fast     // 200ms - hover, tooltips
AnimationTokens.normal   // 300ms - dialogs, modals
AnimationTokens.slow     // 500ms - page transitions
AnimationTokens.slower   // 600ms - entrance animations

// Curves
AnimationTokens.easeOut      // Entrance animations (recommended)
AnimationTokens.easeInOut    // State transitions
AnimationTokens.fastOutSlowIn // Material Design standard
AnimationTokens.elasticOut   // Playful/success feedback
```

---

## Phase 1: Empty States (High Impact, Easy)

Empty states are shown when there's no data. Adding subtle animations makes the app feel more polished.

### Pattern: Fade + Scale Entrance

```dart
// Before
Column(
  children: [
    Icon(Icons.inbox_outlined, size: 64),
    Text('No bookings yet'),
  ],
)

// After
Column(
  children: [
    Icon(Icons.inbox_outlined, size: 64)
      .animate()
      .fadeIn(duration: AnimationTokens.fast)
      .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1)),
    Text('No bookings yet')
      .animate(delay: Duration(milliseconds: 100))
      .fadeIn(duration: AnimationTokens.fast),
  ],
)
```

### Locations to Update

| File | Location | Description |
|------|----------|-------------|
| `owner_bookings_screen.dart` | Line ~552 | "No bookings" empty window |
| `unified_unit_hub_screen.dart` | Lines 336, 452, 597 | No properties/units states |
| `notifications_screen.dart` | Line ~109 | Empty notifications |
| `platform_connections_screen.dart` | Line ~164 | No connections |
| `ical_export_list_screen.dart` | Lines 92-100 | No exports |
| `dashboard_overview_tab.dart` | Line ~70 | Welcome screen (new user) |

---

## Phase 2: Dialog Entrances (High Impact, Medium)

Replace default `showDialog` with animated versions.

### Pattern: Scale + Fade Dialog

```dart
// Create reusable animated dialog
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: AnimationTokens.normal,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: AnimationTokens.fastOutSlowIn,
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}
```

### Locations to Update

| File | Method | Current |
|------|--------|---------|
| `owner_bookings_screen.dart` | `_openBookingDetails` | `showDialog` |
| `owner_bookings_screen.dart` | `_showFiltersDialog` | `showDialog` |
| `notifications_screen.dart` | Delete confirmation | `showDialog` |
| `price_list_calendar_widget.dart` | Edit price dialog | `showDialog` |

---

## Phase 3: Button Micro-interactions (Medium Impact, Easy)

Add tactile feedback to primary action buttons.

### Pattern: Scale on Press

```dart
// Wrap ElevatedButton with animation
class AnimatedPrimaryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  @override
  _AnimatedPrimaryButtonState createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AnimationTokens.instant,
        curve: AnimationTokens.easeOut,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          child: widget.child,
        ),
      ),
    );
  }
}
```

### Locations to Update

| File | Button | Priority |
|------|--------|----------|
| `edit_profile_screen.dart` | Save button | High |
| `stripe_connect_setup_screen.dart` | Connect button | High |
| `send_email_dialog.dart` | Send button | Medium |
| `property_form_screen.dart` | Save button | Medium |

---

## Phase 4: Loading State Transitions (Medium Impact, Medium)

Smooth transitions between loading skeleton and content.

### Pattern: Crossfade Transition

```dart
AnimatedSwitcher(
  duration: AnimationTokens.normal,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
  child: isLoading
    ? SkeletonLoader(key: ValueKey('skeleton'))
    : ContentWidget(key: ValueKey('content')),
)
```

### Locations to Update

| File | Transition |
|------|------------|
| `ical_export_list_screen.dart` | Skeleton → List |
| `platform_connections_screen.dart` | Loading → Content |
| `notifications_screen.dart` | Loading → List |
| `unified_unit_hub_screen.dart` | Skeleton → Grid |

---

## Phase 5: Success Celebrations (Low Priority, Fun)

Add subtle success feedback for important actions.

### Pattern: Checkmark Animation

```dart
class AnimatedCheckmark extends StatefulWidget {
  @override
  _AnimatedCheckmarkState createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.slower,
      vsync: this,
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: AnimationTokens.elasticOut,
      ),
      child: Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 64,
      ),
    );
  }
}
```

### Locations to Update

| File | Action |
|------|--------|
| `owner_bookings_screen.dart` | Booking approved |
| `edit_profile_screen.dart` | Profile saved |
| `property_form_screen.dart` | Property created |

---

## Phase 6: Card Hover Effects (Desktop Only)

Add elevation/scale on hover for interactive cards.

### Pattern: Hover Scale

```dart
class HoverScaleCard extends StatefulWidget {
  final Widget child;

  @override
  _HoverScaleCardState createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AnimationTokens.fast,
        curve: AnimationTokens.easeOut,
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.02 : 1.0),
        child: AnimatedContainer(
          duration: AnimationTokens.fast,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: _isHovered ? 12 : 4,
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
```

### Locations to Update

| File | Element |
|------|---------|
| `property_card_owner.dart` | Property cards |
| `unified_unit_hub_screen.dart` | Unit cards |
| `notifications_screen.dart` | Notification tiles |

---

## Implementation Checklist

### Phase 1: Empty States
- [ ] `owner_bookings_screen.dart` - No bookings
- [ ] `unified_unit_hub_screen.dart` - No properties/units (3 locations)
- [ ] `notifications_screen.dart` - Empty notifications
- [ ] `platform_connections_screen.dart` - No connections
- [ ] `ical_export_list_screen.dart` - No exports
- [ ] `dashboard_overview_tab.dart` - Welcome screen

### Phase 2: Dialog Entrances
- [ ] Create `showAnimatedDialog` utility
- [ ] Update `owner_bookings_screen.dart` dialogs
- [ ] Update `notifications_screen.dart` dialogs
- [ ] Update `price_list_calendar_widget.dart` dialogs

### Phase 3: Button Micro-interactions
- [ ] Create `AnimatedPrimaryButton` widget
- [ ] Update save/submit buttons across forms

### Phase 4: Loading Transitions
- [ ] Add `AnimatedSwitcher` to skeleton→content transitions

### Phase 5: Success Celebrations
- [ ] Create `AnimatedCheckmark` widget
- [ ] Add to booking approval flow

### Phase 6: Card Hover Effects
- [ ] Create `HoverScaleCard` widget
- [ ] Apply to property/unit cards

---

## Existing Good Patterns (Reference)

1. **`booking_confirmation_screen.dart`** (Lines 79-98)
   - `AnimationController` + `ScaleTransition` + `FadeTransition`
   - Excellent template for dialog/screen entrances

2. **`_MoneyLoadingAnimation`** in `stripe_connect_setup_screen.dart`
   - Staggered animations with multiple controllers
   - Currency symbol bounce effect

3. **`_IndeterminateProgress`** in `bookbed_loader.dart`
   - Smooth progress bar animation
   - Uses `AnimatedBuilder` pattern

4. **`SkeletonLoader`** in `skeleton_loader.dart`
   - Shimmer gradient animation
   - Consistent loading placeholder

---

**Last Updated**: 2025-12-19
