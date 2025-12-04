# IZVJEŠTAJ: Analiza `setupWidgetConfig` Funkcije

**Datum**: 2025-12-04
**Funkcija**: `setupWidgetConfig` (setupWidgetConfig.ts:17)
**Status**: ⚠️ DEPLOYED ALI **NEKORIŠTENA** u produkciji

---

## 🔍 TRENUTNO STANJE

### Cloud Function Status

| Aspekt | Status |
|--------|--------|
| **Lokacija** | `functions/src/setupWidgetConfig.ts:17` |
| **Exportovana** | ✅ DA (`functions/src/index.ts:45`) |
| **Deployed** | ✅ DA (pretpostavljam) |
| **Korištena u Flutter-u** | ❌ **NE** - nema poziva u `lib/` |
| **Korištena u Functions** | ❌ NE - nema drugih poziva |

---

## 📊 ŠTA RADI `setupWidgetConfig`?

### Namjena (dokumentacija)

```typescript
/**
 * Callable function to configure widget settings
 *
 * Usage: Call this function with propertyId and unitId
 *
 * Sets up:
 * - Custom Logo
 * - Additional Services
 * - Tax/Legal Disclaimer
 * - Blur Effects
 * - iCal Sync Warning
 */
```

### Bulk Konfiguracija

Funkcija BULK konfiguriše sve widget settings odjednom:

1. **Theme Options** - Custom logo (Villa Jasko logo hardcoded)
2. **Blur Effects** - Glassmorphism (enabled, intensity: 10.0)
3. **Tax/Legal Disclaimer** - PDV tekst + boravišna pristojba
4. **iCal Sync Warning** - Banner za stale kalendar (>24h)
5. **Additional Services** - 3 sample usluge (rani dolazak, kasni odlazak, transfer)
6. **UI Options** - Dark mode, light mode, floating pill

### Firestore Putanja

```
properties/{propertyId}/widget_settings/{unitId}
```

**Merge Strategy**: `{merge: true}` - NE briše postojeće podatke

---

## ❌ ZAŠTO SE NE KORISTI?

### Flutter App Pristup

Flutter app **DIREKTNO** piše widget settings preko **repository pattern**:

**Repository**: `firebase_widget_settings_repository.dart`

```dart
/// Update widget settings
Future<void> updateWidgetSettings(WidgetSettings settings) async {
  final updatedSettings = settings.copyWith(updatedAt: DateTime.now());

  await _firestore
      .collection('properties')
      .doc(settings.propertyId)
      .collection('widget_settings')
      .doc(settings.id)
      .set(updatedSettings.toFirestore(), SetOptions(merge: true));
}
```

### UI Flow za Konfiguraciju

Owner konfiguriše widget settings kroz **GUI**:

1. **Widget Settings Screen** (`widget_settings_screen.dart`)
   - Widget mode (calendar only, booking instant, booking pending)
   - Contact options (email, phone)
   - Email verification settings
   - Tax/legal disclaimer

2. **Advanced Settings Screen** (`widget_advanced_settings_screen.dart`)
   - Additional services (dodavanje, brisanje, uređivanje)
   - Blur effects
   - Custom logo upload
   - Payment options (Stripe, Revolut)

3. **Pricing Screen** (Cjenovnik tab - `unified_unit_hub_screen.dart`)
   - Seasons, pricing rules
   - iCal export

### Razlog Nekorištenja

**Flutter app ima KOMPLETAN UI za sve što `setupWidgetConfig` radi.**

Owner može:
- ✅ Upload custom logo (Firebase Storage)
- ✅ Dodati additional services (JSON builder u UI)
- ✅ Konfigurirati blur effects (slider + toggle)
- ✅ Editovati tax disclaimer (text field)
- ✅ Enable/disable iCal warning (checkbox)

**Rezultat**: Nema potrebe za Cloud Function - owner sve radi kroz GUI.

---

## 💡 KADA BI `setupWidgetConfig` BILA KORISNA?

### Use Case #1: "Setup Demo Property" Dugme 🎬

**Scenario**: Quick onboarding za nove owner-e

**Implementacija**:
```dart
// Owner Dashboard - Demo Setup Button
ElevatedButton(
  onPressed: () async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('setupWidgetConfig');

    await callable.call({
      'propertyId': currentPropertyId,
      'unitId': currentUnitId,
    });

    showSuccess('Demo konfiguracija postavljena! ✓');
  },
  child: Text('Setup Demo Configuration'),
)
```

**Benefit**: Owner odmah vidi kako izgleda **fully configured** widget.

---

### Use Case #2: Bulk Migration Tool 🔄

**Scenario**: Masovna migracija postojećih properties na nova polja

**Primjer**: Dodavanje `icalSyncWarning` config-a svim properties odjednom

**Implementacija**:
```typescript
// Admin-only Cloud Function
export const bulkUpdateWidgetSettings = onCall(
  { cors: true },
  async (request) => {
    // Check admin permission
    if (!isAdmin(request)) throw new HttpsError('permission-denied', 'Admin only');

    const db = getFirestore();
    const propertiesSnapshot = await db.collection('properties').get();

    for (const propertyDoc of propertiesSnapshot.docs) {
      const unitsSnapshot = await propertyDoc.ref
        .collection('widget_settings')
        .get();

      for (const unitDoc of unitsSnapshot.docs) {
        await unitDoc.ref.update({
          icalSyncWarning: {
            enabled: true,
            showWhenStale: true,
            staleThresholdHours: 24,
          },
        });
      }
    }

    return { updated: propertiesSnapshot.size };
  }
);
```

**Benefit**: Batch update umjesto ručnog editovanja svakog unit-a.

---

### Use Case #3: Admin Panel "Reset to Defaults" 🔧

**Scenario**: Owner zabrlja konfiguraciju, želi reset na defaults

**Implementacija**:
```dart
// Settings Screen - Reset Button
TextButton.icon(
  icon: Icon(Icons.restore),
  label: Text('Reset to Defaults'),
  onPressed: () async {
    final confirmed = await showConfirmDialog(
      'Reset will restore default widget configuration. Continue?',
    );

    if (confirmed) {
      await _resetWidgetSettings();
    }
  },
)

Future<void> _resetWidgetSettings() async {
  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('setupWidgetConfig');

  await callable.call({
    'propertyId': widget.propertyId,
    'unitId': widget.unitId,
  });
}
```

**Benefit**: One-click reset bez potrebe za ručnim vraćanjem svakog polja.

---

### Use Case #4: Onboarding Wizard ✨

**Scenario**: Novi owner kreira prvi property

**Flow**:
```
1. Owner unese naziv i adresu property-a
2. Owner klikne "Create Property"
3. Backend kreira property + unit
4. Backend poziva setupWidgetConfig() za default config
5. Owner odmah ima funkcionalan widget sa default settings-ima
```

**Implementacija u Unit Wizard**:
```dart
// Nakon createUnit() poziva
if (isFirstUnit) {
  // Setup default widget config automatically
  await _setupDefaultWidgetConfig(
    propertyId: property.id,
    unitId: newUnit.id,
  );

  showSuccess('Property created with default widget configuration!');
}
```

**Benefit**: Smanjuje friction u onboarding-u - owner odmah vidi rješenje koje radi.

---

## ⚖️ ANALIZA: Da Li Zadržati Funkciju?

### ✅ PREDNOSTI ZADRŽAVANJA

| Prednost | Impact |
|----------|--------|
| **Demo setup** | Korisno za testiranje i prezentacije | ⭐⭐
| **Migration tool** | Batch update postojećih properties | ⭐⭐⭐
| **Admin safety net** | One-click reset ako owner zabrlja config | ⭐⭐
| **Onboarding** | Brži first-time setup za nove owner-e | ⭐⭐⭐

### ❌ NEDOSTACI ZADRŽAVANJA

| Nedostatak | Impact |
|------------|--------|
| **Hardcoded values** | Logo URL, services, text - specifični za Villa Jasko | ⚠️ **HIGH**
| **Maintenance overhead** | Mora se updateovati svaki put kad se doda novo polje u WidgetSettings | ⭐⭐
| **Code smell** | Deployed funkcija koja se NIKAD ne poziva | ⭐
| **Security risk** | Otvoren API - bilo ko može pozvati i resetovati settings | ⚠️ **CRITICAL**

---

## 🔒 KRITIČAN SIGURNOSNI PROBLEM

### Problem: Neautentifikovana Funkcija

```typescript
export const setupWidgetConfig = onCall(
  {cors: true},
  async (request) => {
    // ❌ NEMA AUTH CHECK!
    // Bilo ko može pozvati sa bilo kojim propertyId/unitId!
```

### Exploit Scenario

```javascript
// Malicious user poziva funkciju
const functions = firebase.functions();
const setup = functions.httpsCallable('setupWidgetConfig');

// Overwrite-uje TUĐU property konfiguraciju!
await setup({
  propertyId: 'victim_property_id',
  unitId: 'victim_unit_id',
});

// Rezultat: Victim-ov widget settings su overwrote-ovani sa hardcoded Villa Jasko vrijednostima!
```

### Što Se Dešava

1. ❌ Victim-ov custom logo → **replaced sa Villa Jasko logo**
2. ❌ Victim-ove usluge → **replaced sa 3 hardcoded usluge**
3. ❌ Victim-ov disclaimer → **replaced sa hardcoded tekstom**
4. ❌ Victim-ov contact info → **još uvijek tu (merge: true), ali sve drugo je gone**

**Severity**: ⚠️ **HIGH** - Denial of Service / Data Tampering

---

## 📝 PREPORUKE

### OPCIJA A: **IZBRIŠI FUNKCIJU** (preporučeno za trenutni MVP)

**Razlozi**:
1. ✅ **Sigurnost** - Eliminira security risk
2. ✅ **Jednostavnije** - Manje koda za maintain
3. ✅ **Nema use case-a** - Flutter UI pokriva SVE potrebe
4. ✅ **Hardcoded vrijednosti** - Specifične za Villa Jasko, ne generičke

**Akcija**:
```bash
# 1. Remove export
# functions/src/index.ts - izbriši liniju 45:
# export * from "./setupWidgetConfig";

# 2. Delete file
rm functions/src/setupWidgetConfig.ts

# 3. Rebuild & redeploy
npm run build
firebase deploy --only functions
```

**Deployment note**: Funkcija će biti **removed** iz Firebase-a nakon redeployment-a.

---

### OPCIJA B: **REFAKTORISATI I ZAŠTITITI** (ako hoćeš zadržati za admin/demo)

**Potrebne izmjene**:

#### 1. Dodaj Auth Check

```typescript
export const setupWidgetConfig = onCall(
  {cors: true},
  async (request) => {
    // ✅ CRITICAL: Provjeri da li je user owner property-a
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const {propertyId, unitId} = request.data;

    // Verify ownership
    const db = getFirestore();
    const propertyDoc = await db.collection('properties').doc(propertyId).get();

    if (!propertyDoc.exists || propertyDoc.data()?.ownerId !== userId) {
      throw new HttpsError('permission-denied', 'User does not own this property');
    }

    // Continue sa setup logic...
```

#### 2. Napravi Generic (Remove Hardcoded Values)

```typescript
// Umjesto hardcoded logo URL-a:
customLogoUrl: null, // Owner će upload-ovati preko UI

// Umjesto hardcoded services:
additionalServices: [], // Owner će dodati preko UI

// Umjesto hardcoded disclaimer:
disclaimerText: 'Rezervacijom prihvaćate uvjete korištenja.', // Generic text
```

#### 3. Dodaj Admin-Only Endpoint za Bulk

```typescript
export const bulkSetupWidgetConfigs = onCall(
  {cors: true},
  async (request) => {
    // Admin check (custom claim ili whitelist)
    if (!isAdmin(request)) {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const {propertyIds} = request.data;

    // Bulk setup logic...
  }
);
```

---

### OPCIJA C: **PRIVREMENO ONEMOGUĆI** (wait & see approach)

**Akcija**:
```typescript
// Dodaj na vrh funkcije:
throw new HttpsError(
  'unimplemented',
  'This function is temporarily disabled. Use Flutter UI for configuration.'
);
```

**Benefit**: Zadržava kod za potencijalni budući use case, ali sprječava pozivanje.

---

## 🎯 FINALNA PREPORUKA

### ⭐ **OPCIJA A** (IZBRIŠI)

**Obrazloženje**:
1. 🔒 **Security risk** - neautentifikovana funkcija može overwrote-ovati bilo čiji config
2. ✅ **No use case** - Flutter UI pokriva 100% potreba
3. 🗑️ **Code smell** - deployed ali nekorištena funkcija
4. ⚠️ **Hardcoded** - specifično za Villa Jasko, ne generičko rješenje

**Akcija**:
```bash
# Remove export i delete file
git rm functions/src/setupWidgetConfig.ts
# Edit functions/src/index.ts (remove line 45)
npm run build
firebase deploy --only functions
```

---

### 🔄 **Ako Hoćeš Zadržati** (OPCIJA B)

**Implementiraj U OVOM REDOSLIJEDU**:

1. ✅ **AUTH CHECK** (blocker - MORA)
2. ✅ **Remove hardcoded values** (high priority)
3. ✅ **Add admin-only bulk endpoint** (nice to have)
4. ✅ **Integrate u onboarding wizard** (optional enhancement)

**Estimated work**: ~2-3 sata

---

## 📊 Rezime

| Funkcija | Status | Korištena? | Security Risk | Preporuka |
|----------|--------|------------|---------------|-----------|
| `setupWidgetConfig` | ✅ Deployed | ❌ NE | ⚠️ **HIGH** | **IZBRIŠI** |

**Odluka**: Tvoja je! Javi mi hoćeš li **OPCIJU A (izbriši)** ili **OPCIJU B (refaktorisati)**. 🤔

---

**Last Updated**: 2025-12-04
