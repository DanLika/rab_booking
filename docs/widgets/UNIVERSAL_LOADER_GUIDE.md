# Universal Loader Widget - Usage Guide

Univerzalni loading widget za cijelu aplikaciju koji zamjenjuje razne ad-hoc loading indikatore.

## Karakteristike

- ✅ **BookBed logo** sa ispravnom dark/light mode podrškom
- ✅ **3 veličine**: small, medium, large
- ✅ **3 načina prikaza**: overlay, centered, inline
- ✅ **Opcionalna poruka** ispod loadera
- ✅ **Glassmorphism blur** (za overlay mode)
- ✅ **Debounce** - ne prikazuje se odmah (sprječava flicker)

## Kada koristiti

### 1. Full-screen Overlay (kao LoginLoadingOverlay)
Za kritične operacije gdje ne želimo da korisnik interakciju sa UI-em:
- Login/Register/Password reset
- Payment processing
- Critical API calls

### 2. Centered Loader (za sekcije)
Za prazne sekcije ili kada se cijela komponenta učitava:
- Empty state tokom loading-a
- Dashboard kartice koje se učitavaju
- Liste prije nego dođu podaci

### 3. Inline Loader (mali)
Za male komponente, dugmad, kartice:
- Submit button tokom slanja
- Refresh dugme
- Inline komponente tokom učitavanja

---

## Usage Examples

### Example 1: Full-Screen Overlay (Login/Register)

```dart
import 'package:bookbed/shared/widgets/universal_loader.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        LoginForm(),

        // Show loader during login
        if (_isLoading)
          UniversalLoader.overlay(
            message: 'Logging in...',
            size: LoaderSize.medium,
          ),
      ],
    );
  }
}
```

**Trenutno koristi**: `LoginLoadingOverlay` → **MOŽEMO ZAMIJENITI**

---

### Example 2: Centered Section Loader (Dashboard)

```dart
class DashboardCard extends StatelessWidget {
  final bool isLoading;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 200,
        child: isLoading
            ? UniversalLoader.centered(
                message: 'Loading analytics...',
                size: LoaderSize.medium,
              )
            : content,
      ),
    );
  }
}
```

**Gdje koristiti**:
- `dashboard_overview_tab.dart` - dashboard kartice tokom loading-a
- `owner_bookings_screen.dart` - bookings lista tokom loading-a
- `notifications_screen.dart` - notifications tokom loading-a

---

### Example 3: Inline Loader (Buttons, Small Sections)

```dart
class RefreshButton extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isRefreshing ? null : onRefresh,
      icon: isRefreshing
          ? UniversalLoader.inline(size: LoaderSize.small)
          : Icon(Icons.refresh),
    );
  }
}
```

**Gdje koristiti**:
- Submit dugmad tokom slanja (umjesto `CircularProgressIndicator`)
- Refresh ikone
- Inline komponente u karticama

---

### Example 4: Custom Configuration

```dart
// Overlay bez blur-a
UniversalLoader.overlay(
  message: 'Processing payment...',
  withBlur: false,
)

// Bez debounce-a (odmah prikaži)
UniversalLoader.centered(
  message: 'Loading...',
  debounceDuration: Duration.zero,
)

// Large loader za splash-like experience
UniversalLoader.overlay(
  size: LoaderSize.large,
  message: 'Welcome to BookBed',
)
```

---

## Migration Path

### Step 1: Replace LoginLoadingOverlay
**Fajlovi**:
- `enhanced_login_screen.dart` (linija 511)
- `enhanced_register_screen.dart` (linija 347)
- `forgot_password_screen.dart` (linija 143)

**Prije**:
```dart
if (_isLoading) LoginLoadingOverlay(message: l10n.loading)
```

**Poslije**:
```dart
if (_isLoading) UniversalLoader.overlay(message: l10n.loading)
```

### Step 2: Replace CircularProgressIndicator in sections
**Fajlovi**: `dashboard_overview_tab.dart`, `owner_bookings_screen.dart`, itd.

**Prije**:
```dart
if (isLoading)
  Center(child: CircularProgressIndicator())
```

**Poslije**:
```dart
if (isLoading)
  UniversalLoader.centered(message: 'Loading bookings...')
```

### Step 3: Replace LoadingOverlay in routers
**Fajlovi**: `router_owner.dart` (linije 351, 778, 807, 834, 864)

**Prije**:
```dart
const Scaffold(body: LoadingOverlay(message: 'Loading...'))
```

**Poslije**:
```dart
Scaffold(body: UniversalLoader.overlay(message: 'Loading...'))
```

---

## Comparison with Existing Loaders

| Feature | LoginLoadingOverlay | LoadingOverlay | UniversalLoader |
|---------|-------------------|----------------|-----------------|
| Full-screen overlay | ✅ | ✅ | ✅ |
| Inline mode | ❌ | ❌ | ✅ |
| Blur effect | ✅ | ❌ | ✅ (optional) |
| Multiple sizes | ❌ | ❌ | ✅ (3 sizes) |
| Debounce | ✅ (50ms) | ❌ | ✅ (configurable) |
| Logo display | ✅ AuthLogoIcon | ✅ BookBedBrandedLoader | ✅ AuthLogoIcon |
| Dark mode support | ✅ | ✅ | ✅ |

**Prednosti UniversalLoader**:
- ✅ Jedan widget za sve potrebe (3-in-1)
- ✅ Konzistentan dizajn kroz cijelu aplikaciju
- ✅ Bolja kontrola nad veličinama
- ✅ Factory methods za lake use case-ove

---

## API Reference

### Constructors

```dart
// Default constructor
UniversalLoader({
  LoaderMode mode = LoaderMode.inline,
  LoaderSize size = LoaderSize.medium,
  String? message,
  bool withBlur = true,
  Duration debounceDuration = const Duration(milliseconds: 50),
})

// Factory methods
UniversalLoader.overlay({...})   // Full-screen with blur
UniversalLoader.centered({...})  // Centered in parent
UniversalLoader.inline({...})    // Small inline loader
```

### Enums

```dart
enum LoaderMode {
  overlay,   // Full-screen overlay
  centered,  // Centered within parent
  inline,    // No centering
}

enum LoaderSize {
  small,   // 40px logo, 30px indicator
  medium,  // 60px logo, 40px indicator
  large,   // 100px logo, 50px indicator
}
```

---

## Visual Examples

### Small Loader (LoaderSize.small)
- Logo: 40px
- Indicator: 30px × 2.5px stroke
- Message: 12px font
- Use: Buttons, inline components

### Medium Loader (LoaderSize.medium)
- Logo: 60px
- Indicator: 40px × 3px stroke
- Message: 14px font
- Use: Dialogs, sections, cards

### Large Loader (LoaderSize.large)
- Logo: 100px
- Indicator: 50px × 3px stroke
- Message: 16px font
- Use: Full-screen overlays, splash screens

---

## Best Practices

### DO ✅
- Use `overlay` mode for critical operations (login, payment)
- Use `centered` mode for empty states and loading sections
- Use `inline` mode for small components (buttons, icons)
- Provide meaningful messages when possible
- Use appropriate size for context

### DON'T ❌
- Don't use large loaders for small buttons
- Don't disable debounce unless necessary (causes flicker)
- Don't show loader for operations < 50ms (handled by debounce)
- Don't mix with old loading widgets (maintain consistency)

---

## Future Improvements (Optional)

1. **Progress Indicator**: Add optional percentage progress (0-100%)
2. **Custom Colors**: Allow overriding primary color
3. **Animation Variants**: Different animation styles (pulse, fade, etc.)
4. **Cancel Button**: Optional cancel button for long operations
5. **Time Estimate**: Show estimated time remaining

---

## Related Files

- Widget: `lib/shared/widgets/universal_loader.dart`
- Logo: `lib/features/auth/presentation/widgets/auth_logo_icon.dart`
- Old loaders:
  - `lib/shared/widgets/login_loading_overlay.dart` (can be deprecated)
  - `lib/shared/widgets/loading_overlay.dart` (can be deprecated)
  - `lib/core/widgets/owner_app_loader.dart` (keep for specific use case)
