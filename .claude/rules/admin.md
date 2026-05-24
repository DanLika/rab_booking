---
paths:
  - "lib/features/admin/**"
  - "lib/admin_main*.dart"
  - "functions/src/admin/**"
---

# Admin Dashboard

**Entry points**: `lib/admin_main.dart` (PROD), `lib/admin_main_staging.dart` (STAGING). No DEV entry point exists — DEV admin reuses the PROD entrypoint with the dev Firebase config (see `.firebaserc` admin target mapping below).

## Per-environment hosting (.firebaserc)

| URL | Hosting site | Firebase project | Purpose |
|---|---|---|---|
| `https://bookbed-admin.web.app` | `bookbed-admin` | `rab-booking-248fc` (**PROD**) | LIVE admin tools — real owner PII, real Stripe |
| `https://bookbed-admin-dev.web.app` | `bookbed-admin-dev` | `bookbed-dev` (**DEV**) | Smoke/regression test surface |
| `https://bookbed-admin-staging.web.app` | `bookbed-admin-staging` | `bookbed-staging` (**STAGING**) | Pre-prod verification |

**⚠️ NIKADA ne radi smoke / regression test direktno protiv `bookbed-admin.web.app`** — koristi DEV (preferred) ili STAGING. Bilo koji klik na Grant/Revoke u prod admin tools flipuje pravom kupcu polja + piše u `security_events`.

### Deploy commands (per env)

```bash
# DEV admin redeploy (after admin/* code change)
flutter build web --release --target lib/admin_main.dart -o build/web_admin
firebase deploy --only hosting:admin --project bookbed-dev

# PROD admin (only after staging green)
firebase deploy --only hosting:admin --project rab-booking-248fc
```

**Stale-build hazard:** DEV and STAGING admin sites are NOT auto-deployed by CI. If you change `lib/features/admin/**` or `lib/admin_main*.dart`, the DEV/STAGING admin URLs will show the previous build until you manually redeploy. Always re-check the rendered UI version against `git log -- lib/features/admin/presentation/screens/admin_login_screen.dart` (header copy, button label, footer year) before drawing smoke conclusions about CHANGELOG-claimed changes.

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

**⚠️ Security: audit/30 finding (pre-PR #462).** Path 2 (`isAdminFromFirestore()`) trusts `users/{uid}.role` which is currently writable by the owner of the document if not gated. PR #462 closes the role-write hole via Firestore rules allowlist. Until #462 merges, any vanilla owner account can promote itself to admin by writing `users/{uid}.role = "admin"` and gaining read access to the admin-gated collection-group queries. **Cloud Functions** (`functions/src/admin/setLifetimeLicense.ts`, `updateUserStatus.ts`) gate strictly on `request.auth.token.isAdmin === true` (JWT only) and are unaffected — Firestore-role escape only affects DIRECT Firestore admin reads from the Flutter app.

## Smoke / test account requirements

Admin smoke runs need an account with `request.auth.token.isAdmin === true` custom claim. Custom claims are set via firebase-admin SDK; they CANNOT be self-provisioned by the user. See `memory/admin-smoke-account.md` (provision-once-then-reuse pattern, mirroring `memory/test-account.md`). Run smoke against the DEV URL only.

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
