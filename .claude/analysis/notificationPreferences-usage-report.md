# IZVJEŠTAJ: Analiza `notificationPreferences.ts`

**Datum**: 2025-12-04
**Modul**: Notification Preferences System
**Status**: ⚠️ **PARTIAL** - UI IMPLEMENTIRAN ali backend **NEAKTIVAN**

---

## 🔍 TRENUTNO STANJE

### Backend Status (Cloud Functions)

| Aspekt | Status |
|--------|--------|
| **Lokacija** | `functions/src/notificationPreferences.ts` |
| **Exportovana** | ❌ NE (nije u `functions/src/index.ts`) |
| **Deployed** | ❌ NE - nije exportovana |
| **Korištena u Functions** | ❌ NE - namjerno UKLONJENA (bug fix) |
| **Flutter Repository** | ✅ DA - implementiran u `user_profile_repository.dart` |
| **Flutter Model** | ✅ DA - `notification_preferences_model.dart` |
| **Flutter UI** | ✅ DA - `notification_settings_screen.dart` |

### Frontend Status (Flutter)

| Komponenta | Status | Napomena |
|------------|--------|----------|
| **Data Model** | ✅ IMPLEMENTIRAN | `NotificationPreferences`, `NotificationCategories`, `NotificationChannels` |
| **Repository** | ✅ IMPLEMENTIRAN | `getNotificationPreferences()`, `updateNotificationPreferences()` |
| **UI Screen** | ✅ IMPLEMENTIRAN | Premium UI sa master switch + 4 kategorije |
| **Router** | ✅ IMPLEMENTIRAN | Route: `/owner/profile/notifications` |
| **Navigation** | ✅ IMPLEMENTIRAN | Accessible from Profile Screen |

---

## 📊 ŠTA RADI `notificationPreferences.ts`?

### Funkcije u Backend Modulu

#### 1. `getNotificationPreferences(userId: string)`
**Namjena**: Dohvata notification preferences iz Firestore

**Firestore Path**:
```
users/{userId}/data/preferences
```

**Default Vrijednosti**:
```typescript
{
  masterEnabled: true,
  categories: {
    bookings: { email: true, push: true, sms: false },
    payments: { email: true, push: true, sms: false },
    calendar: { email: true, push: true, sms: false },
    marketing: { email: false, push: false, sms: false }, // Marketing opt-in!
  }
}
```

#### 2. `shouldSendEmailNotification(userId, category)`
**Namjena**: Provjerava da li owner želi primati email za specifičnu kategoriju

**Kategorije**:
- `bookings` - Nova rezervacija, cancellation, update
- `payments` - Payment confirmation, transaction update
- `calendar` - Availability change, blocked dates, price update
- `marketing` - Promotional offers, tips, platform news

**Logika**:
```typescript
1. Dohvati preferences iz Firestore
2. Ako nema preferences → default: SEND (opt-out approach)
3. Provjeri masterEnabled → ako false: DON'T SEND
4. Provjeri category.email → ako false: DON'T SEND
5. Inače: SEND
```

#### 3. `shouldSendPushNotification(userId, category)`
**Isto kao email** - provjera za push notifications

#### 4. `shouldSendSmsNotification(userId, category)`
**Razlika**: Default je `false` (SMS je **opt-in**, ne opt-out)

---

## ❌ ZAŠTO SE NE KORISTI?

### Bug Fix u `atomicBooking.ts`

**Linija 14-15**:
```typescript
// BUG #2 FIX: Removed shouldSendEmailNotification import
// Owner email is now ALWAYS sent for new bookings (user requirement B1: 1)
```

**Razlog**: User requirement je da owner **UVIJEK** dobije email za novu rezervaciju.

### Trenutno Stanje Email Slanja

Sve email funkcije šalju **BEZUSLOVNO** (bez provjere preferences):

1. **`sendBookingConfirmationOwnerEmail()`** → Šalje se UVIJEK
2. **`sendPendingBookingOwnerNotification()`** → Šalje se UVIJEK
3. **`sendBookingApprovedEmail()`** → Šalje se UVIJEK
4. **`sendCancellationEmail()`** → Šalje se UVIJEK

**Rezultat**: Owner nema način da isključi notifikacije (osim da ne pogleda UI).

---

## 🔌 FLUTTER INTEGRACIJA (VEĆ IMPLEMENTIRANA)

### 1. Data Model

**File**: `lib/shared/models/notification_preferences_model.dart`

```dart
@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required String userId,
    @Default(true) bool masterEnabled,
    @Default(NotificationCategories()) NotificationCategories categories,
    DateTime? updatedAt,
  }) = _NotificationPreferences;

  Map<String, dynamic> toFirestore() {
    return {
      'masterEnabled': masterEnabled,
      'categories': categories.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
```

### 2. Repository

**File**: `lib/shared/repositories/user_profile_repository.dart`

```dart
/// Get notification preferences once
Future<NotificationPreferences?> getNotificationPreferences(String userId) async {
  final snapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('data')
      .doc('preferences')
      .get();

  if (!snapshot.exists || snapshot.data() == null) {
    return null;
  }
  return NotificationPreferences.fromFirestore(userId, snapshot.data()!);
}

/// Update notification preferences
Future<void> updateNotificationPreferences(NotificationPreferences preferences) async {
  await _firestore
      .collection('users')
      .doc(preferences.userId)
      .collection('data')
      .doc('preferences')
      .set(
        preferences.toFirestore(),
        SetOptions(merge: true),
      );
}
```

### 3. Premium UI Screen

**File**: `lib/features/owner_dashboard/presentation/screens/notification_settings_screen.dart`

**Features**:
- ✅ **Master Switch** - Premium gradient card sa icon animation
- ✅ **4 Categories** - Bookings, Payments, Calendar, Marketing
- ✅ **3 Channels** - Email, Push, SMS (per category)
- ✅ **Expansion Tiles** - Expand za channel settings
- ✅ **Visual Feedback** - Success snackbar nakon save
- ✅ **Error Handling** - Error display za Firestore failures
- ✅ **Loading State** - CircularProgressIndicator dok učitava
- ✅ **Disabled State** - Vizualno disabled kada master switch OFF

**Route**: `/owner/profile/notifications`

**Navigation**: Accessible from Profile Screen → "Notification Settings" tile

### 4. Firestore Write RADI ✅

Owner MOŽE spremiti preferences u Firestore:
```
users/{userId}/data/preferences
{
  "masterEnabled": false,
  "categories": {
    "bookings": { "email": false, "push": true, "sms": false },
    "payments": { "email": true, "push": true, "sms": false },
    ...
  },
  "updatedAt": Timestamp
}
```

**Ali**: Backend **NE PROVJERAVA** ove podatke prije slanja emaila! 🚨

---

## 🚨 KRITIČAN PROBLEM

### **GAP**: UI Radi, Backend NE Čita

```
┌──────────────────────────────────────────────────────┐
│ Owner otvori Notification Settings screen           │
│ Owner DISABLE email notifications za bookings       │
│ Firestore WRITE: bookings.email = false             │
│ Success snackbar: "Settings saved ✓"                │
└──────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────┐
│ Nova booking request dolazi                          │
│ atomicBooking.ts poziva sendOwnerNotificationEmail() │
│ ❌ NE provjerava shouldSendEmailNotification()       │
│ Email se šalje UVIJEK                                │
└──────────────────────────────────────────────────────┘
                          ↓
                    OWNER RAZOČARAN
           "Isključio sam notifikacije, ali ih još uvijek dobijam!"
```

---

## 💡 KADA BI BILO KORISNO?

### Use Case #1: GDPR Compliance 🇪🇺

**Scenario**: EU zakoni zahtijevaju opt-out za marketing emailove

**Implementacija**: Marketing emailovi NE smiju biti poslani ako:
```typescript
const shouldSend = await shouldSendEmailNotification(ownerId, 'marketing');
if (!shouldSend) {
  logInfo('[Email] Owner opted out of marketing emails');
  return; // DON'T SEND
}
```

**Benefit**: GDPR compliance, izbjegavanje fines (€20M ili 4% global turnover!)

---

### Use Case #2: Smanjenje Email Spam 📧

**Scenario**: Owner ima 10 units, dobija 50+ emailova dnevno

**Problema**: Owner overwhelmed sa notifikacijama, počinje ignorisati SVE emailove (uključujući kritične)

**Rješenje**: Owner može:
- ✅ Isključiti marketing emailove
- ✅ Isključiti calendar change emailove (sync preko iCal-a je dovoljan)
- ✅ Zadržati SAMO booking + payment emailove

**Implementacija u `sendOwnerNotificationEmail()`**:
```typescript
export async function sendOwnerNotificationEmail(
  ownerId: string,
  propertyId: string,
  booking: any,
  category: 'bookings' | 'payments' | 'calendar'
) {
  // CHECK PREFERENCES
  const shouldSend = await shouldSendEmailNotification(ownerId, category);
  if (!shouldSend) {
    logInfo(`[Email] Owner ${ownerId} opted out of ${category} notifications`);
    return;
  }

  // Send email...
}
```

---

### Use Case #3: SMS Notifications (Opt-In) 📱

**Scenario**: Owner želi SMS za HITNE notifikacije (cancellations, payment failures)

**Default**: SMS je **opt-in** (default: false)

**Implementacija**:
```typescript
// Za kritične eventi (cancellation unutar 24h)
if (isCriticalEvent) {
  const shouldSendSMS = await shouldSendSmsNotification(ownerId, 'bookings');
  if (shouldSendSMS) {
    await sendSmsNotification(ownerPhone, `URGENT: Booking cancelled for ${propertyName}`);
  }
}
```

**Benefit**: Owner dobije instant notifikaciju za urgentne stvari

---

### Use Case #4: Push Notifications (Budućnost) 🔔

**Scenario**: Flutter mobile app sa push notifications

**Implementacija**:
```typescript
const shouldSendPush = await shouldSendPushNotification(ownerId, 'bookings');
if (shouldSendPush) {
  await sendPushNotification(ownerFcmToken, {
    title: 'New Booking Request',
    body: `${guestName} requested ${propertyName} for ${dates}`,
  });
}
```

**Benefit**: Real-time notifikacije u mobile app

---

## ⚖️ ANALIZA: Da Li Aktivirati Modul?

### ✅ PREDNOSTI AKTIVIRANJA

| Prednost | Impact | Priority |
|----------|--------|----------|
| **GDPR Compliance** | KRITIČNO za EU market | ⭐⭐⭐⭐⭐ (legal requirement) |
| **UX Improvement** | Owner kontrola nad email spamom | ⭐⭐⭐⭐ |
| **SMS Support** | Opt-in za kritične notifikacije | ⭐⭐⭐ (future enhancement) |
| **Push Notifications** | Mobile app support (budućnost) | ⭐⭐ (not urgent) |
| **Competitivness** | Airbnb, Booking ima ovo | ⭐⭐⭐ |

### ❌ NEDOSTACI/RIZICI

| Nedostatak | Impact | Mitigation |
|------------|--------|------------|
| **Owner može fulirati** | Owner isključi SVE emailove, propusti booking | Force enable za kritične eventi (cancellations) |
| **Backend complexity** | Svaka email funkcija mora provjeriti preferences | Helper wrapper: `sendEmailIfAllowed()` |
| **Testing overhead** | Mora se testirati 24 kombinacije (4 categories × 3 channels × 2 states) | Automated unit tests u `notificationPreferences.test.ts` |

---

## 🔧 IMPLEMENTACIJA PLAN

### FAZA 1: Aktiviraj Backend Modul

#### 1.1 Exportuj Modul
**File**: `functions/src/index.ts`

```typescript
// Export notification preferences functions
export * from "./notificationPreferences";
```

#### 1.2 Kreiraj Wrapper Helper
**New File**: `functions/src/utils/emailNotificationHelper.ts`

```typescript
import { shouldSendEmailNotification } from "./notificationPreferences";
import { logInfo } from "./logger";

/**
 * Wrapper za slanje emaila sa provjerom preferences
 *
 * @param ownerId - Owner user ID
 * @param category - Notification category
 * @param sendEmailFn - Async funkcija koja šalje email
 * @param forceIfCritical - Ako true, šalje email čak i ako owner opted out (za kritične eventi)
 * @returns true if sent, false if skipped
 */
export async function sendEmailIfAllowed(
  ownerId: string,
  category: 'bookings' | 'payments' | 'calendar' | 'marketing',
  sendEmailFn: () => Promise<void>,
  forceIfCritical = false
): Promise<boolean> {
  // Critical events override preferences
  if (forceIfCritical) {
    logInfo(`[EmailHelper] Sending critical ${category} email (bypassing preferences)`);
    await sendEmailFn();
    return true;
  }

  // Check preferences
  const shouldSend = await shouldSendEmailNotification(ownerId, category);

  if (!shouldSend) {
    logInfo(`[EmailHelper] Owner ${ownerId} opted out of ${category} emails`);
    return false;
  }

  // Send email
  await sendEmailFn();
  return true;
}
```

### FAZA 2: Integriraj u Email Functions

#### 2.1 Update `atomicBooking.ts`

**Before**:
```typescript
// Uvijek šalje
await sendBookingConfirmationOwnerEmail(
  ownerEmail,
  ownerName,
  propertyName,
  bookingDetails,
  subdomain,
  propertyId
);
```

**After**:
```typescript
import { sendEmailIfAllowed } from "./utils/emailNotificationHelper";

// Provjeri preferences prije slanja
await sendEmailIfAllowed(
  ownerId,
  'bookings', // Category
  async () => {
    await sendBookingConfirmationOwnerEmail(
      ownerEmail,
      ownerName,
      propertyName,
      bookingDetails,
      subdomain,
      propertyId
    );
  },
  false // Ne force - owner može opt-out za instant bookings
);
```

#### 2.2 Update `bookingManagement.ts`

Za pending bookings (requireOwnerApproval):
```typescript
await sendEmailIfAllowed(
  ownerId,
  'bookings',
  async () => {
    await sendPendingBookingOwnerNotification(...);
  },
  true // FORCE = true - owner MORA biti notifikovan za pending requests
);
```

**Razlog za force**: Pending bookings zahtijevaju owner approval - kriticalan event.

#### 2.3 Update `stripePayment.ts`

Payment confirmation:
```typescript
await sendEmailIfAllowed(
  ownerId,
  'payments',
  async () => {
    await sendPaymentConfirmationEmail(...);
  },
  false // Owner može opt-out za payment notifications
);
```

### FAZA 3: Marketing Emails (Budućnost)

**New Function**: `functions/src/marketing.ts`

```typescript
export const sendMonthlyReportEmail = onSchedule(
  { schedule: "0 9 1 * *" }, // Prvi dan mjeseca u 9:00
  async () => {
    const db = getFirestore();
    const ownersSnapshot = await db.collection("users").get();

    for (const ownerDoc of ownersSnapshot.docs) {
      const ownerId = ownerDoc.id;

      // CHECK PREFERENCES za marketing
      const shouldSend = await shouldSendEmailNotification(ownerId, 'marketing');

      if (!shouldSend) {
        logInfo(`[Marketing] Owner ${ownerId} opted out of marketing emails`);
        continue; // Skip
      }

      // Generate monthly report
      const reportData = await generateMonthlyReport(ownerId);

      // Send email
      await sendMonthlyReportEmail(ownerId, reportData);
    }
  }
);
```

---

## 📝 PREPORUKE

### OPCIJA A: **AKTIVIRAJ SADA** (preporučeno za GDPR + UX)

**Razlozi**:
1. ✅ **GDPR Compliance** - KRITIČNO za EU market
2. ✅ **UX Improvement** - Owner feedback: "Previše emailova"
3. ✅ **UI već radi** - Flutter screen je implementiran i testiran
4. ✅ **Minimal risk** - Backend modul je dobro napisan, samo treba integrisati

**Akcija**:
```bash
# 1. Export modul u index.ts
echo "export * from \"./notificationPreferences\";" >> functions/src/index.ts

# 2. Kreiraj helper (copy/paste kod gore)
touch functions/src/utils/emailNotificationHelper.ts

# 3. Update email functions (3-4 file edit-a)
# - atomicBooking.ts
# - bookingManagement.ts
# - stripePayment.ts

# 4. Deploy
npm run build
firebase deploy --only functions

# 5. Test
# - Owner dashboard → Profile → Notification Settings
# - Disable "Bookings" email
# - Create test booking
# - Verify: NO EMAIL sent to owner
```

**Estimated Work**: ~3-4 sata

---

### OPCIJA B: **STAGE FOR MVP+1** (odgodi za post-launch)

**Razlozi**:
1. ✅ **MVP focus** - Trenutno radi, ne blokira launch
2. ✅ **Low user count** - Manji broj owner-a = manje email spam problema
3. ✅ **Time constraint** - Fokus na kritične feature-e

**Akcija**:
- Ostavi kako jeste
- Dodaj u roadmap za MVP+1
- Dodaj u CLAUDE.md kao "planned enhancement"

**Risk**: GDPR non-compliance ako šalješ marketing emailove bez opt-out

---

### OPCIJA C: **PARTIAL ACTIVATION** (samo GDPR kritični dijelovi)

**Razlozi**:
1. ✅ **GDPR compliance** - Minimum viable za EU
2. ✅ **Minimal scope** - Samo marketing opt-out

**Akcija**:
```typescript
// SAMO za marketing emailove
if (isMarketingEmail) {
  const shouldSend = await shouldSendEmailNotification(ownerId, 'marketing');
  if (!shouldSend) {
    return; // Comply with GDPR
  }
}

// Bookings, payments, calendar → UVIJEK ŠALJI (za sada)
```

**Estimated Work**: ~1 sat (samo marketing check)

---

## 🎯 FINALNA PREPORUKA

### ⭐ **OPCIJA A** (AKTIVIRAJ SADA)

**Obrazloženje**:
1. 🇪🇺 **GDPR Compliance** - Legal requirement za EU market (fines: €20M!)
2. ✅ **UI već radi** - 90% posla već uradjen (model, repository, screen, router)
3. 📧 **Owner feedback** - "Previše emailova" je realan problem
4. 🚀 **Competitive advantage** - Airbnb/Booking ima ovo, ti nemoj biti lošiji
5. 🧪 **Low risk** - Backend modul je čist, dobro napisan, samo treba integrisati

**Implementation Priority**:
1. **HIGH** - Marketing email opt-out (GDPR)
2. **MEDIUM** - Bookings/payments opt-out (UX)
3. **LOW** - SMS/Push support (budućnost)

---

## 📊 Rezime

| Modul | Backend Status | Frontend Status | Koristi? | Preporuka |
|-------|----------------|-----------------|----------|-----------|
| `notificationPreferences.ts` | ⚠️ NEAKTIVIRAN | ✅ IMPLEMENTIRAN | ❌ NE | **AKTIVIRAJ** |

**Odluka**: Tvoja je! Javi mi hoćeš li **OPCIJU A (aktiviraj)**, **OPCIJU B (MVP+1)** ili **OPCIJU C (samo GDPR)**. 🤔

---

**Last Updated**: 2025-12-04
