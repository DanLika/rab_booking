# Animations Quick Reference

Quick guide for using animation components in the RAB Booking app.

## 📦 Import

```dart
import 'package:rab_booking/shared/widgets/animations/animations.dart';
```

---

## 🎨 Components

### 1. Hover Effects (Desktop Only)

#### Property Card Hover
```dart
HoverScaleCard(
  child: PropertyCard(property: property),
)
```

#### Image Zoom on Hover
```dart
HoverZoomImage(
  zoom: 1.05, // 5% zoom
  child: Image.network(imageUrl),
)
```

#### Button Brightness
```dart
HoverBrightnessButton(
  child: ElevatedButton(...),
)
```

---

### 2. Skeleton Loaders

#### Property Card Skeleton
```dart
// Loading state
PropertyCardSkeleton()

// Or multiple cards
PropertyListSkeleton(itemCount: 6)
```

#### Custom Skeleton
```dart
SkeletonLoader(
  width: 200,
  height: 20,
  borderRadius: 8,
)
```

#### Text Skeleton
```dart
TextSkeleton(width: 150)
```

#### Avatar Skeleton
```dart
CircleSkeleton(size: 40)
```

---

### 3. Micro-Animations

#### Animated Favorite (Heart Pop)
```dart
AnimatedFavoriteIcon(
  isFavorite: true,
  onTap: () => toggleFavorite(),
  size: 24,
)
```

#### Success Checkmark
```dart
AnimatedSuccessCheckmark(
  size: 60,
  color: Colors.green,
)
```

#### Error Shake
```dart
AnimatedErrorShake(
  trigger: hasError, // Set to true to trigger shake
  child: TextField(...),
)
```

#### Add to Cart Animation
```dart
final key = GlobalKey<_AnimatedAddToCartState>();

AnimatedAddToCart(
  key: key,
  child: IconButton(...),
)

// Trigger animation
key.currentState?.playAnimation();
```

---

### 4. Scroll Effects

#### Fade-in AppBar on Scroll
```dart
final scrollController = ScrollController();

Scaffold(
  appBar: FadeInAppBar(
    scrollController: scrollController,
    title: Text('My App'),
    fadeThreshold: 100, // Fade starts after 100px scroll
  ),
  body: ListView(
    controller: scrollController,
    children: [...],
  ),
)
```

#### Parallax Effect
```dart
final scrollController = ScrollController();

ParallaxEffect(
  scrollController: scrollController,
  parallaxFactor: 0.3, // Background moves 30% of scroll speed
  child: Image.network(heroImage),
)
```

#### Fade In When Scrolled Into View
```dart
FadeInOnScroll(
  delay: Duration(milliseconds: 100),
  duration: Duration(milliseconds: 600),
  child: PropertyCard(...),
)
```

#### Staggered Fade-In List
```dart
StaggeredFadeInList(
  staggerDelay: Duration(milliseconds: 100),
  children: [
    PropertyCard(...),
    PropertyCard(...),
    PropertyCard(...),
  ],
)
```

---

## 🎯 Common Patterns

### Loading State
```dart
AsyncValue<List<Property>> propertiesAsync;

propertiesAsync.when(
  data: (properties) => ListView.builder(...),
  loading: () => PropertyListSkeleton(itemCount: 6),
  error: (e, _) => ErrorWidget(e),
)
```

### Property Grid with Animations
```dart
GridView.builder(
  itemBuilder: (context, index) {
    return FadeInOnScroll(
      delay: Duration(milliseconds: index * 100),
      child: HoverScaleCard(
        child: PropertyCard(property: properties[index]),
      ),
    );
  },
)
```

### Form with Error Shake
```dart
bool hasError = false;

AnimatedErrorShake(
  trigger: hasError,
  child: TextField(
    onChanged: (value) {
      setState(() {
        hasError = !isValid(value);
      });
    },
  ),
)
```

### Success Screen
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedSuccessCheckmark(size: 80),
      SizedBox(height: 24),
      Text('Success!', style: TextStyle(fontSize: 24)),
    ],
  ),
)
```

---

## ⚙️ Customization

### Adjust Animation Speed
```dart
HoverScaleCard(
  duration: Duration(milliseconds: 150), // Faster
  child: ...,
)
```

### Change Animation Curve
```dart
HoverScaleCard(
  curve: Curves.easeOutBack, // Bouncy effect
  child: ...,
)
```

### Custom Scale Amount
```dart
HoverScaleCard(
  scale: 1.05, // 5% scale instead of 2%
  child: ...,
)
```

---

## 🚀 Performance Tips

1. **Use RepaintBoundary** for expensive widgets:
```dart
RepaintBoundary(
  child: HoverScaleCard(...),
)
```

2. **Throttle scroll listeners** (already done internally):
```dart
// Scroll updates throttled to 16ms (60fps)
```

3. **Dispose controllers** (already handled):
```dart
// All animation controllers auto-disposed
```

4. **Use const constructors** when possible:
```dart
const SkeletonLoader() // if all params are const
```

---

## 🎬 Animation Specs

| Component | Duration | Curve | FPS |
|-----------|----------|-------|-----|
| Hover Scale | 200ms | easeInOut | 60 |
| Hover Zoom | 300ms | easeInOut | 60 |
| Favorite Pop | 400ms | easeOut → elasticOut | 60 |
| Shimmer | 1500ms | easeInOut | 60 |
| Fade In Scroll | 600ms | easeOut | 60 |
| Error Shake | 500ms | linear | 60 |
| Success Check | 600ms | easeOut | 60 |

---

## 🐛 Troubleshooting

### Animation not playing?
- Check if controller is disposed
- Verify trigger condition is changing
- Ensure widget is mounted

### Janky animation?
- Add RepaintBoundary
- Reduce animation complexity
- Check for unnecessary rebuilds

### Hover not working on mobile?
- Hover effects only work on desktop (by design)
- Mobile uses tap interactions

---

## 📚 Examples

See `ANIMATIONS_IMPLEMENTATION.md` for complete examples and integration guide.
