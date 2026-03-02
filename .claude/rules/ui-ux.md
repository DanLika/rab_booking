---
paths:
  - "lib/**/*.dart"
---

# UI/UX Standardi

**Filozofija**: Less colorful, more professional - neutralne pozadine sa jednom accent bojom na ikonama.

## Dialogs

- Footer: `AppColors.dialogFooterDark/Light`, border: `AppColors.sectionDividerDark/Light`
- Padding: 12px mobile (<400px), 16-20px desktop
- Border radius: 11-12px
- Warning/Error pattern: Header `AppColors.error` background, Content `context.gradients.sectionBackground`, Footer `AppColors.dialogFooterDark/Light`
- Use `ResponsiveDialogUtils` for width, padding, and height constraints

## Cards/Tiles

- Ikone: jedna boja (primary) sa 10-12% opacity pozadinom
- Shadows: `AppShadows.elevation1` za većinu, `elevation2` za istaknute
- Border radius: 12px standard

## Skeleton loaders

`SkeletonColors.baseColor/highlightColor` iz `skeleton_loader.dart`

## Animation System — `flutter_animate`

```dart
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bookbed/core/design_tokens/animation_tokens.dart';

// Empty states - fade+scale entrance (PREFERIRANO)
child.animate()
  .fadeIn(duration: AnimationTokens.normal, curve: AnimationTokens.easeOut)
  .scale(begin: Offset(0.8, 0.8), curve: AnimationTokens.fastOutSlowIn)

// Staggered list entrances
ListView.builder(
  itemBuilder: (context, index) => Card(...)
    .animate(delay: Duration(milliseconds: index * 100))
    .fadeIn(duration: AnimationTokens.fast)
    .slideY(begin: 20, end: 0),
)

// Button press feedback (state-driven)
child.animate(target: _isPressed ? 1 : 0)
  .scale(begin: Offset(1.0, 1.0), end: Offset(0.95, 0.95), duration: AnimationTokens.instant)

// Hover effects (desktop)
child.animate(target: _isHovered ? 1 : 0)
  .scale(end: Offset(1.02, 1.02), duration: AnimationTokens.fast)
```

## Pre-built Animation Widgets (`lib/shared/widgets/animations/`)

```dart
AnimatedEmptyState(icon: Icons.inbox, title: 'No items', subtitle: 'Add your first item')
StaggeredEmptyState(icon: Icons.notifications_none, title: 'No notifications')
AnimatedContentSwitcher(showContent: !isLoading, skeleton: MySkeleton(), content: MyContent())

// Custom extensions (lib/core/utils/flutter_animate_extensions.dart)
child.animateWithTokens().emptyStateEntrance()
child.animateWithTokens().cardEntrance(staggerIndex: index)
child.animateWithTokens().buttonPress()
child.animateWithTokens().hoverScale()
```

## flutter_animate Parallel Animations — KRITIČNO

```dart
// ❌ POGREŠNO - efekti se izvršavaju sekvencijalno
child.animate()
  .scale(duration: 3.seconds)
  .rotate(duration: 3.seconds)

// ✅ ISPRAVNO - efekti se izvršavaju paralelno
child.animate()
  .scale(duration: 3.seconds)
  .rotate(delay: Duration.zero, duration: 3.seconds)  // delay: Duration.zero = počni odmah
```

## NE MIGRIRATI na flutter_animate (ostaju sa AnimationController)

- `owner_app_loader.dart`, `bookbed_loader.dart` - custom Alignment(-1→2) pattern
- `connectivity_banner.dart` - event-driven forward()/reverse()
- `enhanced_login_screen.dart` - programmatic shake
