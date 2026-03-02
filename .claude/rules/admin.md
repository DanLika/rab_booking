---
paths:
  - "lib/features/admin/**"
  - "lib/admin_main*.dart"
  - "functions/src/admin/**"
---

# Admin Dashboard

**URL**: `https://bookbed-admin.web.app`
**Entry point**: `lib/admin_main.dart`

## Screens

| Screen | Fajl | Svrha |
|--------|------|-------|
| Login | `admin_login_screen.dart` | Email/password auth za admine |
| Dashboard | `admin_dashboard_screen.dart` | Stats: total owners, trial, premium |
| Users List | `users_list_screen.dart` | Lista svih owner-a sa paginacijom |
| User Detail | `user_detail_screen.dart` | Detalji korisnika, properties count, bookings count |

## Shell navigacija (`admin_shell_screen.dart`)

- Unified Drawer za mobile i desktop
- Dark/Light theme toggle u drawer-u
- Logout dugme u drawer-u

## Firestore Rules za Admin pristup

```javascript
// users collection - admin može čitati sve korisnike
allow read: if isOwner(userId) || isAdmin() || isAdminFromFirestore();

// bookings collection group - admin može čitati sve bookinge
match /{path=**}/bookings/{bookingId} {
  allow read: if
    isAdmin() || isAdminFromFirestore() ||
    // ... ostale rules
}
```

## Admin provjera (dva načina)

1. `isAdmin()` - Firebase custom claims: `request.auth.token.isAdmin == true`
2. `isAdminFromFirestore()` - Firestore document: `users/{uid}.role == 'admin'`

## Providers (`admin_providers.dart`)

- `adminNavIndexProvider` - trenutni tab index
- `adminDarkModeProvider` - dark/light mode state

## Repository (`admin_users_repository.dart`)

- `getOwners()` - paginated lista owner-a
- `getUserById()` - pojedinačni korisnik
- `getDashboardStats()` - count agregacije
- `getUserPropertiesCount()` - broj property-ja korisnika
- `getUserBookingsCount()` - broj bookinga korisnika (collectionGroup query)

**⚠️ VAŽNO**: Admin bookings count koristi `collectionGroup('bookings').where('owner_id', isEqualTo: userId)` - zahtijeva admin pristup u Firestore rules!
