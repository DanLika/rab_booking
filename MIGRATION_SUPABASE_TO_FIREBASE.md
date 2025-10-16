# Migration Guide: Supabase → Firebase

> **Napomena:** Ova aplikacija je dizajnirana za Supabase, ali može se migrirati na Firebase u budućnosti. Ovaj dokument opisuje kompletan proces migracije.

---

## 📋 Table of Contents

1. [Pregled Migracije](#pregled-migracije)
2. [Prije Migracije - Backup](#prije-migracije---backup)
3. [Firebase Setup](#firebase-setup)
4. [Data Migration](#data-migration)
5. [Code Changes](#code-changes)
6. [Testing & Verification](#testing--verification)
7. [Deployment](#deployment)
8. [Rollback Plan](#rollback-plan)

---

## 1. Pregled Migracije

### Šta se mijenja:

| Komponenta | Supabase | Firebase | Težina Migracije |
|------------|----------|----------|------------------|
| **Database** | PostgreSQL | Cloud Firestore | 🟡 Medium |
| **Authentication** | Supabase Auth | Firebase Auth | 🟢 Easy |
| **Storage** | Supabase Storage | Firebase Storage | 🟢 Easy |
| **Functions** | Edge Functions (Deno) | Cloud Functions (Node.js) | 🟡 Medium |
| **Realtime** | PostgreSQL subscriptions | Firestore snapshots | 🟢 Easy |
| **Security** | RLS Policies | Security Rules | 🔴 Hard |

### Vrijeme migracije:
- **Mala app** (< 1000 users): **2-3 dana**
- **Medium app** (1000-10000 users): **1-2 sedmice**
- **Large app** (> 10000 users): **3-4 sedmice**

### Cijena migracije:
- Firebase Cloud Functions: **~$10-50/mjesec**
- Firestore reads/writes: **~$20-100/mjesec** (za booking app)
- Storage: **~$5-20/mjesec**

---

## 2. Prije Migracije - Backup

### 2.1 Export Supabase Data

```bash
# Instaliraj Supabase CLI
npm install -g supabase

# Login
supabase login

# Export PostgreSQL schema
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres --schema-only > schema.sql

# Export data
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres --data-only > data.sql
```

### 2.2 Export User Data

```sql
-- Export users tabelu
COPY (SELECT * FROM auth.users) TO '/tmp/users.csv' CSV HEADER;

-- Export sve custom podatke
COPY (SELECT * FROM properties) TO '/tmp/properties.csv' CSV HEADER;
COPY (SELECT * FROM units) TO '/tmp/units.csv' CSV HEADER;
COPY (SELECT * FROM bookings) TO '/tmp/bookings.csv' CSV HEADER;
COPY (SELECT * FROM payments) TO '/tmp/payments.csv' CSV HEADER;
```

### 2.3 Export Storage Files

```bash
# Supabase Storage buckets
supabase storage download --bucket property-images --output ./backup/images
```

---

## 3. Firebase Setup

### 3.1 Kreiraj Firebase Project

1. Idi na: https://console.firebase.google.com
2. Klikni "Add project"
3. Project name: `rab-booking-prod`
4. Enable Google Analytics (optional)
5. Create project

### 3.2 Enable Firebase Services

```bash
# Instaliraj Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
cd rab_booking
firebase init

# Odaberi:
# - Firestore
# - Functions
# - Storage
# - Hosting (optional)
```

### 3.3 Flutter Firebase Setup

Dodaj u `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.4
  cloud_functions: ^5.1.3
```

Run:
```bash
# Firebase FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure
```

---

## 4. Data Migration

### 4.1 Firestore Data Structure

**Supabase PostgreSQL → Firestore NoSQL konverzija:**

#### Properties Collection

```javascript
// Firestore structure
properties/{propertyId}
  ├── id: string
  ├── ownerId: string
  ├── name: string
  ├── description: string
  ├── location: string
  ├── pricePerNight: number
  ├── images: array<string>
  ├── amenities: array<string>
  ├── status: string
  ├── createdAt: timestamp
  └── updatedAt: timestamp

// Subcollections
properties/{propertyId}/units/{unitId}
  ├── id: string
  ├── propertyId: string
  ├── name: string
  ├── maxGuests: number
  ├── pricePerNight: number
  └── ...

properties/{propertyId}/bookings/{bookingId}
  ├── id: string
  ├── unitId: string
  ├── guestId: string
  ├── checkIn: timestamp
  ├── checkOut: timestamp
  ├── status: string
  └── ...
```

### 4.2 Migration Script (Node.js)

```javascript
// migration/supabase-to-firestore.js

const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

// Initialize Supabase
const supabase = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SUPABASE_SERVICE_KEY'
);

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert('./serviceAccountKey.json')
});

const db = admin.firestore();

async function migrateProperties() {
  console.log('Migrating properties...');

  // Fetch from Supabase
  const { data: properties, error } = await supabase
    .from('properties')
    .select('*');

  if (error) throw error;

  // Write to Firestore
  const batch = db.batch();

  properties.forEach(property => {
    const docRef = db.collection('properties').doc(property.id);
    batch.set(docRef, {
      id: property.id,
      ownerId: property.owner_id,
      name: property.name,
      description: property.description,
      location: property.location,
      pricePerNight: property.price_per_night,
      images: property.images || [],
      amenities: property.amenities || [],
      status: property.status,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(property.created_at)),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date(property.updated_at))
    });
  });

  await batch.commit();
  console.log(`Migrated ${properties.length} properties`);
}

async function migrateUnits() {
  console.log('Migrating units...');

  const { data: units, error } = await supabase
    .from('units')
    .select('*');

  if (error) throw error;

  const batch = db.batch();

  units.forEach(unit => {
    const docRef = db
      .collection('properties').doc(unit.property_id)
      .collection('units').doc(unit.id);

    batch.set(docRef, {
      id: unit.id,
      propertyId: unit.property_id,
      name: unit.name,
      maxGuests: unit.max_guests,
      pricePerNight: unit.price_per_night,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(unit.created_at))
    });
  });

  await batch.commit();
  console.log(`Migrated ${units.length} units`);
}

async function migrateBookings() {
  console.log('Migrating bookings...');

  const { data: bookings, error } = await supabase
    .from('bookings')
    .select('*, units(property_id)');

  if (error) throw error;

  const batch = db.batch();

  bookings.forEach(booking => {
    const docRef = db
      .collection('properties').doc(booking.units.property_id)
      .collection('bookings').doc(booking.id);

    batch.set(docRef, {
      id: booking.id,
      unitId: booking.unit_id,
      guestId: booking.guest_id,
      checkIn: admin.firestore.Timestamp.fromDate(new Date(booking.check_in)),
      checkOut: admin.firestore.Timestamp.fromDate(new Date(booking.check_out)),
      totalPrice: booking.total_price,
      status: booking.status,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(booking.created_at))
    });
  });

  await batch.commit();
  console.log(`Migrated ${bookings.length} bookings`);
}

async function migrateUsers() {
  console.log('Migrating users...');

  const { data: users, error } = await supabase
    .from('users')
    .select('*');

  if (error) throw error;

  // Firebase Auth import format
  const userImports = users.map(user => ({
    uid: user.id,
    email: user.email,
    displayName: user.name,
    phoneNumber: user.phone,
    emailVerified: user.email_verified || false,
    disabled: false
  }));

  // Import users to Firebase Auth
  const result = await admin.auth().importUsers(userImports);
  console.log(`Successfully imported ${result.successCount} users`);
  console.log(`Failed to import ${result.failureCount} users`);
}

async function main() {
  try {
    await migrateUsers();
    await migrateProperties();
    await migrateUnits();
    await migrateBookings();
    console.log('Migration completed successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

main();
```

### 4.3 Run Migration

```bash
cd migration
npm install @supabase/supabase-js firebase-admin
node supabase-to-firestore.js
```

---

## 5. Code Changes

### 5.1 Data Models (Freezed)

**PRIJE (Supabase):**
```dart
@freezed
class Property with _$Property {
  const factory Property({
    required String id,
    required String ownerId,
    required String name,
    // ... other fields
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}
```

**POSLIJE (Firebase):**
```dart
@freezed
class Property with _$Property {
  const factory Property({
    required String id,
    required String ownerId,
    required String name,
    // ... other fields
  }) = _Property;

  // Firebase Firestore adapter
  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      // ... map other fields
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      // ... other fields
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}
```

### 5.2 Repository Implementation

**PRIJE (Supabase):**
```dart
class PropertyRepositoryImpl implements PropertyRepository {
  final SupabaseClient _client;

  @override
  Future<Result<List<Property>>> fetchProperties() async {
    try {
      final response = await _client
          .from('properties')
          .select()
          .eq('status', 'published');

      final properties = (response as List)
          .map((json) => Property.fromJson(json))
          .toList();

      return Success(properties);
    } catch (e) {
      return Failure(DatabaseException('Failed to fetch properties'));
    }
  }
}
```

**POSLIJE (Firebase):**
```dart
class PropertyRepositoryImpl implements PropertyRepository {
  final FirebaseFirestore _firestore;

  PropertyRepositoryImpl(this._firestore);

  @override
  Future<Result<List<Property>>> fetchProperties() async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('status', isEqualTo: 'published')
          .get();

      final properties = querySnapshot.docs
          .map((doc) => Property.fromFirestore(doc))
          .toList();

      return Success(properties);
    } catch (e) {
      return Failure(DatabaseException('Failed to fetch properties'));
    }
  }
}
```

### 5.3 Realtime Subscriptions

**PRIJE (Supabase):**
```dart
@riverpod
Stream<List<Booking>> bookingsStream(BookingsStreamRef ref, String propertyId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('property_id', propertyId)
      .map((data) => data.map((json) => Booking.fromJson(json)).toList());
}
```

**POSLIJE (Firebase):**
```dart
@riverpod
Stream<List<Booking>> bookingsStream(BookingsStreamRef ref, String propertyId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('properties')
      .doc(propertyId)
      .collection('bookings')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList()
      );
}
```

### 5.4 Authentication

**PRIJE (Supabase):**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  @override
  Future<Result<User>> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return Success(User.fromSupabase(response.user!));
    } catch (e) {
      return Failure(AuthException('Login failed'));
    }
  }
}
```

**POSLIJE (Firebase):**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;

  @override
  Future<Result<User>> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return Success(User.fromFirebase(userCredential.user!));
    } catch (e) {
      return Failure(AuthException('Login failed'));
    }
  }
}
```

### 5.5 Cloud Functions (Stripe Payment)

**PRIJE (Supabase Edge Function - Deno):**
```typescript
// supabase/functions/create-payment-intent/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@11.1.0";

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

serve(async (req) => {
  const { amount, bookingId } = await req.json();

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 0.20 * 100), // 20% advance
    currency: 'eur',
    metadata: { bookingId },
  });

  return new Response(JSON.stringify({ clientSecret: paymentIntent.client_secret }));
});
```

**POSLIJE (Firebase Cloud Function - Node.js):**
```javascript
// functions/index.js
const functions = require('firebase-functions');
const stripe = require('stripe')(functions.config().stripe.secret_key);

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { amount, bookingId } = data;

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 0.20 * 100), // 20% advance
    currency: 'eur',
    metadata: { bookingId },
  });

  return { clientSecret: paymentIntent.client_secret };
});
```

**Flutter call:**

PRIJE:
```dart
final response = await supabase.functions.invoke('create-payment-intent',
  body: {'amount': 500, 'bookingId': 'booking123'});
```

POSLIJE:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
final result = await callable.call({'amount': 500, 'bookingId': 'booking123'});
```

### 5.6 Security Rules

**PRIJE (Supabase RLS Policies):**
```sql
-- Properties: Owners can CRUD their own, everyone can read published
CREATE POLICY "owners_crud_own_properties"
ON properties
USING (auth.uid() = owner_id);

CREATE POLICY "public_read_published_properties"
ON properties FOR SELECT
USING (status = 'published');
```

**POSLIJE (Firestore Security Rules):**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Properties collection
    match /properties/{propertyId} {
      // Anyone can read published properties
      allow read: if resource.data.status == 'published';

      // Only owner can create/update/delete
      allow create: if request.auth != null &&
                       request.resource.data.ownerId == request.auth.uid;

      allow update, delete: if request.auth != null &&
                               resource.data.ownerId == request.auth.uid;

      // Units subcollection
      match /units/{unitId} {
        allow read: if true;
        allow write: if request.auth != null &&
                        get(/databases/$(database)/documents/properties/$(propertyId)).data.ownerId == request.auth.uid;
      }

      // Bookings subcollection
      match /bookings/{bookingId} {
        // Property owner can read all bookings
        allow read: if request.auth != null &&
                       get(/databases/$(database)/documents/properties/$(propertyId)).data.ownerId == request.auth.uid;

        // Guest can read their own bookings
        allow read: if request.auth != null &&
                       resource.data.guestId == request.auth.uid;

        // Guests can create bookings
        allow create: if request.auth != null &&
                         request.resource.data.guestId == request.auth.uid;
      }
    }
  }
}
```

---

## 6. Testing & Verification

### 6.1 Test Checklist

- [ ] **Authentication**
  - [ ] Email/password login
  - [ ] Google OAuth
  - [ ] Password reset
  - [ ] User profile update

- [ ] **Properties**
  - [ ] List all properties
  - [ ] View property details
  - [ ] Owner CRUD operations
  - [ ] Image upload to Storage

- [ ] **Bookings**
  - [ ] Create booking
  - [ ] View booking calendar
  - [ ] Check availability
  - [ ] Realtime updates

- [ ] **Payments**
  - [ ] Stripe payment intent
  - [ ] 20% advance calculation
  - [ ] Payment success flow

- [ ] **Performance**
  - [ ] Load time < 3s
  - [ ] Firestore reads optimized
  - [ ] Image caching works

### 6.2 Data Verification

```dart
// Verify migration script
Future<void> verifyMigration() async {
  // Count records in Supabase
  final supabaseCount = await supabase.from('properties').select('count');

  // Count documents in Firestore
  final firestoreSnapshot = await FirebaseFirestore.instance
      .collection('properties')
      .get();

  print('Supabase properties: $supabaseCount');
  print('Firestore properties: ${firestoreSnapshot.docs.length}');

  assert(supabaseCount == firestoreSnapshot.docs.length,
         'Data count mismatch!');
}
```

---

## 7. Deployment

### 7.1 Deployment Steps

1. **Deploy Cloud Functions:**
```bash
firebase deploy --only functions
```

2. **Deploy Firestore Rules:**
```bash
firebase deploy --only firestore:rules
```

3. **Deploy Storage Rules:**
```bash
firebase deploy --only storage
```

4. **Update Flutter App:**
```bash
# Build Android
flutter build apk --release

# Build iOS
flutter build ipa --release

# Build Web
flutter build web --release
firebase deploy --only hosting
```

### 7.2 DNS & Domain

```bash
# Firebase Hosting custom domain
firebase hosting:channel:deploy production --expires 30d
```

---

## 8. Rollback Plan

### 8.1 Ako Nešto Pođe Po Zlu

1. **Zadrži Supabase projekat aktivan** 30 dana nakon migracije
2. **Backup Firebase data** prije rollback-a:
```bash
firebase firestore:export gs://your-bucket/backup-$(date +%Y%m%d)
```

3. **Switch nazad na Supabase:**
```dart
// In main.dart - feature flag
const USE_FIREBASE = false;

void main() async {
  if (USE_FIREBASE) {
    await Firebase.initializeApp();
  } else {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }
  runApp(MyApp());
}
```

### 8.2 Gradual Migration (Preporučeno)

Umjesto "big bang" migracije, možete:

1. **Faza 1:** Novi useri na Firebase, postojeći na Supabase
2. **Faza 2:** Migriraj 10% usera
3. **Faza 3:** Migriraj 50% usera
4. **Faza 4:** Migriraj sve usere
5. **Faza 5:** Isključi Supabase

---

## 9. Trošak Migracije

### 9.1 Firebase Pricing Calculator

Za booking app sa:
- 1000 active users
- 50 bookings/dan
- 10 properties
- 100 images

**Mjesečni troškovi:**

| Service | Operacije | Cijena |
|---------|-----------|--------|
| **Firestore reads** | 150,000 reads/mjesec | $0.90 |
| **Firestore writes** | 5,000 writes/mjesec | $0.18 |
| **Storage** | 5GB storage | $0.13 |
| **Cloud Functions** | 50,000 invocations | $0.40 |
| **Hosting** | 10GB bandwidth | $0.15 |
| **TOTAL** | | **~$1.76/mjesec** |

**Napomena:** Firebase ima **generous free tier**, pa prvih nekoliko mjeseci može biti potpuno besplatno!

---

## 10. Zaključak

### ✅ Prednosti Firebase:

- ☁️ Google infrastructure (99.99% uptime)
- 🔒 Enterprise-level security
- 📊 Google Analytics integration
- 🚀 Auto-scaling
- 🌍 Global CDN

### ⚠️ Nedostaci Firebase:

- 💰 Može biti skuplje za visok traffic
- 🗄️ NoSQL ograničenja (nema JOINs)
- 🔍 Kompleksni upiti teži za optimizaciju

### 💡 Moja Preporuka:

**Ostanite na Supabase** dok ne dosegnete:
- 10,000+ active users
- 500+ bookings/dan
- Potreba za Google Cloud integracijom

Tada migrirajte na Firebase za bolji scaling i reliability.

---

**Autor:** Claude Code
**Datum:** 2025-10-16
**Verzija:** 1.0
**Status:** Ready for future migration
