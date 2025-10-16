# Navigation & Deep Linking Guide

## GoRouter Configuration

Rab Booking koristi GoRouter za deklarativnu navigaciju sa sledećim featurima:
- Auth-aware routing sa redirect logic-om
- Role-based access control (Guest, Owner, Admin)
- Custom page transitions
- Bottom navigation shell
- Deep linking support (Android & iOS)
- Type-safe navigation helpers

---

## Routes Overview

### Public Routes (dostupne svima)

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | HomeScreen | Početna stranica sa featured properties |
| `/search` | SearchResultsScreen | Pretraga properties sa filterima |
| `/property/:id` | PropertyDetailsScreen | Detalji pojedinačnog property-a |

### Protected Routes (zahtevaju autentifikaciju)

| Route | Screen | Description |
|-------|--------|-------------|
| `/booking/:unitId` | BookingScreen | Rezervacija unit-a |
| `/payment/confirm` | PaymentConfirmationScreen | Potvrda plaćanja |
| `/profile` | ProfileScreen | Korisnički profil |
| `/bookings` | MyBookingsScreen | Lista rezervacija korisnika |

### Owner Routes (zahtevaju owner ili admin ulogu)

| Route | Screen | Description |
|-------|--------|-------------|
| `/owner/dashboard` | OwnerDashboardScreen | Owner dashboard sa statistikama |
| `/owner/property/:id` | PropertyManagementScreen | Upravljanje propertyem |

### Auth Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/auth/login` | LoginScreen | Prijava korisnika |
| `/auth/register` | RegisterScreen | Registracija novog korisnika |

---

## Navigation Guards

### Authentication Guard

Unauthenticated korisnici pokušavajući pristupiti protected routes bivaju automatski redirectovani na `/auth/login` sa `redirect` query parametrom:

```dart
// User pokušava pristupiti /booking/abc123
// Nije prijavljen → redirect na:
'/auth/login?redirect=%2Fbooking%2Fabc123'

// Nakon prijave, automatski redirect nazad na:
'/booking/abc123'
```

### Role-Based Access Control

Owner i Admin route su zaštićene role checkom:

```dart
// Guest pokušava pristupiti /owner/dashboard
// → Redirect na '/' (Home)

// Owner pristupa /owner/dashboard
// → Allowed ✓

// Admin pristupa /owner/dashboard
// → Allowed ✓ (admin ima pristup svemu)
```

### Auth Page Redirect

Authenticated korisnici pokušavajući pristupiti auth page-ovima bivaju redirectovani:

```dart
// Prijavljen korisnik pokušava pristupiti /auth/login
// → Redirect na '/' ili na query param 'redirect' ako postoji
```

---

## Type-Safe Navigation

Koristi navigation extension methods na `BuildContext` za type-safe navigation:

```dart
// Basic navigation
context.goToHome();
context.goToSearch(query: 'villa', maxGuests: 4);
context.goToPropertyDetails(propertyId);
context.goToBooking(unitId);

// Auth navigation
context.goToLogin(redirectTo: '/booking/abc123');
context.goToRegister();

// Owner navigation
context.goToOwnerDashboard();
context.goToOwnerProperty(propertyId);

// Profile navigation
context.goToProfile();
context.goToMyBookings();

// Stack navigation
context.pushPropertyDetails(propertyId);
context.goBack();
context.goBackWithResult(result);

// Replace navigation
context.replaceWithHome();
context.replaceWithLogin();

// Navigation state
bool canGoBack = context.canPop();
String currentRoute = context.currentRoute;
Map<String, String> params = context.pathParameters;
```

---

## Route Constants

Koristi `Routes` klasu za konstante umesto hardcoded stringova:

```dart
import '../core/utils/navigation_helpers.dart';

// ✓ Good
context.go(Routes.home);
context.go(Routes.ownerDashboard);

// ✗ Bad
context.go('/');
context.go('/owner/dashboard');
```

### Dynamic Routes

Koristi `RoutePaths` za buildovanje parametrizovanih ruta:

```dart
// Property details
context.go(RoutePaths.propertyDetails('abc-123'));
// → '/property/abc-123'

// Booking
context.go(RoutePaths.booking('unit-456'));
// → '/booking/unit-456'

// Search sa query parameters
context.go(RoutePaths.search(
  query: 'beach villa',
  location: 'Rab',
  maxGuests: 6,
  checkIn: '2025-07-01',
  checkOut: '2025-07-07',
));
// → '/search?q=beach%20villa&location=Rab&guests=6&checkIn=2025-07-01&checkOut=2025-07-07'
```

---

## Custom Page Transitions

GoRouter podržava custom transitions za premium UX:

### Fade Transition
Koristi se za tab switches (Home, Search, Bookings, Profile):

```dart
pageBuilder: (context, state) => CustomTransitionPage(
  child: const HomeScreen(),
  transitionsBuilder: _fadeTransition,
)
```

### Slide Transition
Koristi se za stack navigation (Property details, Booking flow):

```dart
pageBuilder: (context, state) => CustomTransitionPage(
  child: PropertyDetailsScreen(propertyId: id),
  transitionsBuilder: _slideTransition, // Slide from right
)
```

### Slide Up Transition
Koristi se za modals (Payment, Confirmation):

```dart
transitionsBuilder: _slideUpTransition, // Slide from bottom
```

### Scale Transition
Koristi se za dialogs i popups:

```dart
transitionsBuilder: _scaleTransition, // Scale + fade
```

---

## Bottom Navigation

Bottom navigation je implementovan kroz `ShellRoute` koji wrappuje main app sections:

```dart
ShellRoute(
  builder: (context, state, child) {
    if (_shouldShowBottomNav(state.uri.path)) {
      return AppScaffoldWithNav(child: child);
    }
    return child; // No bottom nav for full-screen routes
  },
  routes: [...]
)
```

### Bottom Nav Items

| Index | Icon | Label | Route |
|-------|------|-------|-------|
| 0 | home | Home | `/` |
| 1 | search | Pretraga | `/search` |
| 2 | calendar | Bookings | `/bookings` |
| 3 | person | Profil | `/profile` |

Bottom nav se automatski skriva na full-screen route-ama (Property details, Booking flow, Auth pages).

---

## Deep Linking

Rab Booking podržava deep linkove za sharing i eksterne redirecte.

### Supported Deep Link Formats

1. **Custom URL Scheme** (za internal app linking)
   ```
   rabbooking://property/abc-123
   rabbooking://booking/unit-456
   rabbooking://search?q=villa
   ```

2. **Universal Links / App Links** (za web sharing)
   ```
   https://rabbooking.com/property/abc-123
   https://rabbooking.com/booking/unit-456
   https://rabbooking.com/search?q=villa
   ```

### Testing Deep Links

#### Android (ADB)

```bash
# Custom scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "rabbooking://property/abc-123" com.rabbooking.app

# HTTPS link
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://rabbooking.com/property/abc-123" com.rabbooking.app
```

#### iOS (Simulator)

```bash
# Custom scheme
xcrun simctl openurl booted "rabbooking://property/abc-123"

# HTTPS link
xcrun simctl openurl booted "https://rabbooking.com/property/abc-123"
```

### Shareable Link Builder

Za kreiranje shareable linkova koristi `DeepLinkHelpers`:

```dart
import '../core/utils/navigation_helpers.dart';

// Build shareable link
String shareableLink = DeepLinkHelpers.buildShareableLink(
  RoutePaths.propertyDetails('abc-123'),
);
// → "https://rabbooking.com/property/abc-123"

// Share via platform share dialog
Share.share(shareableLink);
```

### Deep Link Handling

GoRouter automatski parsira deep linkove:

```dart
// User clicks: rabbooking://property/abc-123
// GoRouter route: /property/:id
// Screen receives: PropertyDetailsScreen(propertyId: 'abc-123')
```

Ako deep link vodi na protected route, auth guard će redirect-ovati na login sa `redirect` parametrom.

---

## Universal Links Setup (Production)

Za production app, potrebno je setup-ovati Apple App Site Association i Android App Links:

### 1. Apple App Site Association (iOS)

Kreiraj fajl na serveru:
```
https://rabbooking.com/.well-known/apple-app-site-association
```

Sadržaj:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.rabbooking.app",
        "paths": ["*"]
      }
    ]
  }
}
```

### 2. Digital Asset Links (Android)

Kreiraj fajl na serveru:
```
https://rabbooking.com/.well-known/assetlinks.json
```

Sadržaj:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.rabbooking.app",
      "sha256_cert_fingerprints": ["SHA256_FINGERPRINT"]
    }
  }
]
```

Dobij SHA256 fingerprint:
```bash
keytool -list -v -keystore release.keystore
```

---

## Error Handling

### 404 Not Found

GoRouter automatski prikazuje `NotFoundScreen` za nepostojeće rute:

```dart
errorBuilder: (context, state) => const NotFoundScreen(),
```

### Auth Errors

Ako auth check faila, korisnik biva redirect-ovan na login:

```dart
redirect: (context, state) {
  if (isProtectedRoute && !isAuthenticated) {
    return '/auth/login?redirect=${currentPath}';
  }
  return null;
}
```

### Role Check Errors

Ako korisnik nema potrebnu ulogu, redirect na home:

```dart
if (userRole != UserRole.owner) {
  return Routes.home; // Forbidden
}
```

---

## Navigation State Management

Auth state je integrisan sa GoRouter-om kroz `GoRouterRefreshStream`:

```dart
refreshListenable: GoRouterRefreshStream(
  ref.read(authStateNotifierProvider.notifier).stream,
)
```

Kad se auth state promeni (login/logout), GoRouter automatski re-evaluira redirect logic.

---

## Best Practices

### 1. Koristi Type-Safe Navigation

```dart
// ✓ Good - type-safe, autocomplete
context.goToPropertyDetails(propertyId);

// ✗ Bad - prone to typos
context.go('/property/$propertyId');
```

### 2. Koristi Named Routes

```dart
// ✓ Good - named route
context.goNamed('propertyDetails', pathParameters: {'id': propertyId});

// ✗ Bad - path string
context.go('/property/$propertyId');
```

### 3. Validiraj Path Parameters

```dart
GoRoute(
  path: '/property/:id',
  pageBuilder: (context, state) {
    final id = state.pathParameters['id'];
    if (id == null || id.isEmpty) {
      return const NotFoundScreen();
    }
    return PropertyDetailsScreen(propertyId: id);
  },
)
```

### 4. Koristi Query Parameters za Filters

```dart
// ✓ Good - query params za filter state
/search?location=Rab&guests=4&checkIn=2025-07-01

// ✗ Bad - path params za filters
/search/Rab/4/2025-07-01
```

### 5. Preserve Navigation State

Bottom nav koristi `go()` umesto `push()` da preservuje state:

```dart
// ✓ Good - preserves tab state
context.go(Routes.search);

// ✗ Bad - creates navigation stack
context.push(Routes.search);
```

---

## Debugging

### Enable Debug Logging

```dart
GoRouter(
  debugLogDiagnostics: true,
  ...
)
```

Output:
```
[GoRouter] location changed to /property/abc-123
[GoRouter] redirecting to /auth/login?redirect=%2Fproperty%2Fabc-123
```

### Check Current Route

```dart
final currentRoute = context.currentRoute;
print('Current route: $currentRoute');
```

### Check Route Parameters

```dart
final pathParams = context.pathParameters;
final queryParams = context.queryParameters;

print('Property ID: ${pathParams['id']}');
print('Search query: ${queryParams['q']}');
```

---

## Future Enhancements

- [ ] Web routing sa browser back/forward support
- [ ] Route analytics (Firebase Analytics integration)
- [ ] Deep link preview cards (Open Graph meta tags)
- [ ] Dynamic link generation (Firebase Dynamic Links)
- [ ] In-app browser for external links
- [ ] Route transition animations based on direction
- [ ] Persistent navigation state (save/restore on app restart)

---

## References

- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Universal Links (iOS)](https://developer.apple.com/ios/universal-links/)
- [App Links (Android)](https://developer.android.com/training/app-links)
