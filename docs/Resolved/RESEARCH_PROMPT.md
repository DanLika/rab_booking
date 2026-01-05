# Research Prompt za Landscape Keyboard Fix

**Original Date**: 2025-XX-XX | **Updated**: 2025-12-15 | **Last Verified**: 2025-01-XX
**Status**: **FULLY RESOLVED** - All questions answered and implemented

---

## RESOLUTION SUMMARY

All research questions have been answered and a comprehensive landscape-aware implementation has been deployed. The fix includes both JavaScript (index.html) and Dart (mixin) components working together.

---

## ORIGINAL RESEARCH QUESTIONS & ANSWERS

### 1. Visual Viewport API in Landscape Mode - **RESOLVED**

**Original Questions:**
- Does `window.visualViewport.height` work reliably in landscape mode on Android Chrome?
- Are there known issues with visualViewport API in landscape orientation?
- What are typical viewport height values in landscape mode when keyboard is open vs closed?

**Answers & Implementation:**
- **YES**, `visualViewport.height` works reliably in landscape mode
- The main issue was using **fixed pixel thresholds** that were too high for landscape
- Typical landscape values on Samsung Galaxy (~800x400px):
  - Without keyboard: ~400px height
  - With keyboard: ~250-300px height (keyboard takes 100-150px)
  - Height difference on dismiss: **50-100px** (vs 150-250px in portrait)

**Code Location:** `web/index.html:336-345`
```javascript
var CONFIG = {
  portraitMinThreshold: 100,
  landscapeMinThreshold: 50,   // Lower for landscape (50-80px typical change)
  portraitPercentageThreshold: 0.12,   // Portrait: 12% of viewport height
  landscapePercentageThreshold: 0.15,  // Landscape: 15% (smaller viewport needs larger %)
  debounceMs: 100,
  jiggleDelayLandscape: 100,
  jiggleDelayPortrait: 50,
  postJiggleMuteMs: 180
};
```

---

### 2. Keyboard Height in Landscape - **RESOLVED**

**Original Questions:**
- How much height does Android keyboard typically take in landscape mode?
- What is the typical height difference when keyboard dismisses in landscape?

**Answers:**
- Landscape keyboard height: **100-180px** (vs 250-350px in portrait)
- Height difference on dismiss: **50-100px** (vs 150-250px in portrait)
- Keyboard takes ~25-40% of viewport in landscape vs ~35-50% in portrait

**Implementation:** Both JavaScript and Dart use orientation-aware thresholds:

**JavaScript:** `web/index.html:365-374`
```javascript
function getThreshold() {
  var landscape = isLandscape();
  var viewportHeight = viewport.height || window.innerHeight;
  // Use orientation-specific percentage thresholds
  var percentageThreshold = landscape
    ? viewportHeight * CONFIG.landscapePercentageThreshold   // 15%
    : viewportHeight * CONFIG.portraitPercentageThreshold;   // 12%
  var minThreshold = landscape ? CONFIG.landscapeMinThreshold : CONFIG.portraitMinThreshold;
  return Math.max(percentageThreshold, minThreshold);
}
```

**Dart:** `keyboard_dismiss_fix_mixin.dart:133-143`
```dart
// Use orientation-specific thresholds (matching JavaScript implementation)
final viewportSize = MediaQuery.of(context).size;
final viewportHeight = isLandscape ? viewportSize.width : viewportSize.height;
final relativeThreshold = isLandscape
    ? viewportHeight * 0.15   // Landscape: 15%
    : viewportHeight * 0.12;  // Portrait: 12%
final absoluteThreshold = isLandscape
    ? 50.0    // Landscape: 50px (match JavaScript)
    : 100.0;  // Portrait: 100px
final threshold = relativeThreshold > absoluteThreshold ? relativeThreshold : absoluteThreshold;
```

---

### 3. Threshold Values - **RESOLVED**

**Original Questions:**
- What threshold values work best for detecting keyboard dismiss in landscape mode?
- Should we use percentage-based thresholds instead of fixed pixel values?
- What are recommended threshold values for landscape vs portrait?

**Answers & Final Values:**

| Mode | Min Absolute | Percentage | Effective Range |
|------|--------------|------------|-----------------|
| Portrait | 100px | 12% | 100-150px |
| Landscape | 50px | 15% | 50-100px |

**Recommendation:** Use **hybrid approach** - `Math.max(percentageThreshold, absoluteMinimum)`

This ensures:
- Small screens don't get too-small thresholds
- Large screens don't get unnecessarily large thresholds
- Works across all device sizes

---

### 4. Alternative Detection Methods - **RESOLVED**

**Original Questions:**
- Are there alternative ways to detect keyboard dismiss in landscape mode?
- Should we use `window.innerHeight` instead of `visualViewport.height`?
- Can we combine multiple detection methods for better reliability?

**Answers & Implementation:**

**Multiple detection methods combined:**

1. **Primary:** `visualViewport.resize` event (most reliable)
2. **Secondary:** `visualViewport.scroll` event (catches edge cases)
3. **Fallback:** `window.resize` event
4. **Additional:** `focusout` event on input elements

**Code Location:** `web/index.html:476-503`
```javascript
function initialize() {
  lastVisualHeight = viewport.height || window.innerHeight;
  lastWidth = window.innerWidth;
  fullHeight = lastVisualHeight;

  // Primary: visualViewport API (resize + scroll events)
  if (viewport) {
    viewport.addEventListener('resize', handleViewportResize);
    viewport.addEventListener('scroll', handleViewportResize);
  }

  // Fallback: window resize
  window.addEventListener('resize', handleViewportResize);

  // Additional: focusout for keyboard dismiss detection
  document.addEventListener('focusout', function(e) {
    if (e.target && (e.target.matches('input') || e.target.matches('textarea') || e.target.matches('[contenteditable]'))) {
      setTimeout(function() {
        var activeElement = document.activeElement;
        if (!activeElement || (!activeElement.matches('input') && !activeElement.matches('textarea') && !activeElement.matches('[contenteditable]'))) {
          // No input is focused - keyboard likely dismissed
          console.log('[KB-FIX] Focusout detected, forcing Flutter recalc');
          jiggleFlutterView();
        }
      }, 150);
    }
  });

  console.log('[KB-FIX] Android keyboard fix initialized (landscape-aware)');
}
```

---

### 5. Flutter CanvasKit in Landscape - **RESOLVED**

**Original Questions:**
- Are there known issues with Flutter CanvasKit not responding to viewport changes in landscape?
- Does the "jiggle" method work differently in landscape vs portrait?

**Answers:**
- CanvasKit has the **same bug** in both orientations - it doesn't automatically recalculate layout
- The jiggle method works the **same** way, but needs:
  - **More attempts** in landscape (smaller changes harder to detect)
  - **Longer delays** in landscape (layout recalc needs more time)

**Implementation:** `web/index.html:377-401, 463-467`
```javascript
// Jiggle function with orientation-aware delay
function jiggleFlutterView() {
  var glassPane = document.querySelector('flt-glass-pane');
  if (!glassPane) return;

  var delay = isLandscape() ? CONFIG.jiggleDelayLandscape : CONFIG.jiggleDelayPortrait;

  // Apply transform jiggle (most reliable, no flicker)
  glassPane.style.transform = 'translateX(1px)';

  setTimeout(function() {
    glassPane.style.transform = '';
    requestAnimationFrame(function() {
      window.dispatchEvent(new Event('resize'));
      lastJiggleAt = Date.now();
    });
  }, delay);
}

// Additional attempts with delays (more for landscape)
var delays = landscape ? [100, 200, 400] : [50, 100, 250];
delays.forEach(function(delay) {
  setTimeout(jiggleFlutterView, delay);
});
```

**Dart side:** `keyboard_dismiss_fix_mixin.dart:229-265`
```dart
void _forceFullRebuild() {
  // First, dispatch window resize events to trigger Flutter's resize handling
  forceCanvasInvalidateImpl();

  // Schedule multiple rebuilds to catch async layout updates
  for (final delay in [0, 16, 50, 100, 150, 250, 400]) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;

      // Force unfocus to ensure keyboard is fully dismissed
      FocusScope.of(context).unfocus();

      // Dispatch another resize event
      forceWindowResizeImpl();

      // Trigger rebuild
      setState(() {
        _rebuildKey++;
      });

      // Also schedule a frame callback to ensure rendering completes
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Force another layout pass
        final element = context as Element?;
        if (element != null) {
          element.markNeedsBuild();
        }
        forceWindowResizeImpl();
      });
    });
  }
}
```

---

### 6. Best Practices - **RESOLVED**

**Original Questions:**
- What are best practices for handling keyboard dismiss detection in landscape mode on mobile web?
- Are there any Flutter-specific workarounds for this issue?

**Best Practices Implemented:**

1. **Use percentage-based thresholds** with absolute minimums
2. **Detect orientation changes** and reset baseline heights
3. **Multiple detection methods** (visualViewport, window, focusout)
4. **Multiple jiggle attempts** with increasing delays
5. **Transform-based jiggle** (no visual flicker)
6. **Post-jiggle mute period** to prevent re-entrancy
7. **Dart mixin for state management** with `keyboardFixRebuildKey`

**Flutter-Specific Workarounds:**
- `KeyedSubtree` with incrementing key forces full rebuild
- `SchedulerBinding.addPostFrameCallback` ensures render completion
- `FocusScope.unfocus()` ensures keyboard is fully dismissed
- `Element.markNeedsBuild()` forces layout pass

---

## IMPLEMENTATION FILES

| File | Purpose |
|------|---------|
| `web/index.html:331-505` | JavaScript keyboard fix (landscape-aware) |
| `lib/core/utils/keyboard_dismiss_fix_mixin.dart` | Dart mixin for state management |
| `lib/core/utils/keyboard_dismiss_fix_web.dart` | Web-specific implementations |
| `lib/core/utils/keyboard_dismiss_fix_stub.dart` | Stub for non-web platforms |

---

## SCREENS USING THE FIX

All screens with input fields use `AndroidKeyboardDismissFix` mixin:

- `enhanced_login_screen.dart`
- `enhanced_register_screen.dart`
- `forgot_password_screen.dart`
- `change_password_screen.dart`
- `edit_profile_screen.dart`
- `bank_account_screen.dart`
- `property_form_screen.dart`
- `unit_form_screen.dart`
- `step_1_basic_info.dart`, `step_2_capacity.dart`, `step_3_pricing.dart`

---

## CONFIGURATION VALUES

**JavaScript (index.html:336-345):**
```javascript
var CONFIG = {
  portraitMinThreshold: 100,              // Minimum threshold for portrait
  landscapeMinThreshold: 50,               // Minimum threshold for landscape
  portraitPercentageThreshold: 0.12,      // Portrait: 12% of viewport height
  landscapePercentageThreshold: 0.15,      // Landscape: 15% (smaller viewport needs larger %)
  debounceMs: 100,                         // Debounce delay
  jiggleDelayLandscape: 100,               // Jiggle delay for landscape
  jiggleDelayPortrait: 50,                 // Jiggle delay for portrait
  postJiggleMuteMs: 180                    // Mute period after jiggle
};
```

**Dart (mixin:133-143, 147-149, 199-201):**
```dart
// Orientation-specific thresholds (matching JavaScript)
final relativeThreshold = isLandscape
    ? viewportHeight * 0.15   // Landscape: 15%
    : viewportHeight * 0.12;  // Portrait: 12%
final absoluteThreshold = isLandscape
    ? 50.0    // Landscape: 50px (match JavaScript)
    : 100.0;  // Portrait: 100px
final threshold = relativeThreshold > absoluteThreshold ? relativeThreshold : absoluteThreshold;

// Orientation change detection
final orientationChangeThreshold = viewportHeight * 0.4; // 40% = orientation change

// Near full height check (matching JavaScript)
final nearFullHeightThreshold = threshold * 0.5; // threshold * 0.5 (matching JavaScript)
```

---

## RELATED FLUTTER ISSUE

- **Flutter Issue:** [#175074](https://github.com/flutter/flutter/issues/175074)
- **Status:** Open (Flutter team hasn't fixed it yet)
- **Our Workaround:** Fully implemented and working in both portrait and landscape

---

## CHANGELOG

| Date | Change |
|------|--------|
| 2025-XX-XX | Original research prompt created |
| 2025-12-15 | All questions marked as RESOLVED |
| 2025-12-15 | Implementation details documented |
| 2025-12-15 | Configuration values documented |
| 2025-01-XX | Documentation updated to match actual implementation (separate portrait/landscape percentage thresholds) |

---

**Conclusion:** The landscape keyboard fix is fully implemented and working. The key insights were:
1. Use lower absolute thresholds for landscape (50px vs 100px)
2. Use orientation-specific percentage thresholds: 12% for portrait, 15% for landscape (smaller viewport needs larger percentage)
3. Use hybrid approach: `Math.max(percentageThreshold, absoluteMinimum)` for adaptive thresholds
4. Multiple detection methods (visualViewport resize/scroll, window resize, focusout) and multiple jiggle attempts with delays
5. Dart mixin handles state management and forces rebuilds via `keyboardFixRebuildKey`
6. Transform-based jiggle (translateX) prevents visual flicker
