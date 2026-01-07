# RabBooking - Arhitekturni Plan i Implementacijska Dokumentacija

> **Verzija:** 2.0
> **Datum:** Decembar 2024
> **Projekat:** RabBooking
> **Status:** ✅ IMPLEMENTED & VERIFIED (2025-12-15)

---

## 🚀 Quick Reference: Subdomain Implementacija

```
┌────────────────────────────────────────────────────────────────┐
│           IMPLEMENTACIJSKI PLAN: Subdomain Model               │
│                    (BEZ KUPOVINE DOMENE)                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  FAZA 1: Subdomain System (ODMAH - bez domene)                 │
│  ──────────────────────────────────────────────                │
│  1. Dodaj subdomain field u Property model                     │
│  2. Implementiraj unique slug validation                       │
│  3. Widget subdomain parser (čita ?subdomain=xxx)              │
│  4. Email link generation sa placeholder domenom               │
│                                                                │
│  TESTIRANJE (dok tražimo ime):                                 │
│  rab-booking-widget.web.app/view?subdomain=jasko-rab&ref=XXX   │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  FAZA 2: Custom Domain Setup (KAD KUPIŠ DOMENU)                │
│  ──────────────────────────────────────────────                │
│  1. Kupi domenu (npr. {ime}.hr ili {ime}.com)                  │
│  2. Setup DNS wildcard: *.{ime}.hr → Cloud Run                 │
│  3. Cloud Run proxy → Firebase Hosting                         │
│  4. Update email templates sa pravom domenom                   │
│                                                                │
│  FINALNI REZULTAT:                                             │
│  jasko-rab.{ime}.hr/view?ref=BK-123                            │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Vrijeme implementacije Faza 1:** 8-12 sati
**Vrijeme implementacije Faza 2:** 4-6 sati (kad kupiš domenu)

---

## 📋 Sadržaj

1. [Pregled Projekta](#1-pregled-projekta)
2. [Arhitekturne Odluke](#2-arhitekturne-odluke)
3. [Subdomain Model - Detaljna Implementacija](#3-subdomain-model---detaljna-implementacija)
4. [Widget Embedding Arhitektura](#4-widget-embedding-arhitektura)
5. [Implementacijski Plan (Faza 1 - Bez Domene)](#5-implementacijski-plan-faza-1---bez-domene)
6. [Custom Domain Setup (Faza 2 - Kasnije)](#6-custom-domain-setup-faza-2---kasnije)
7. [Testing Strategija](#7-testing-strategija)
8. [Skaliranje (5-20 Klijenata)](#8-skaliranje-5-20-klijenata)
9. [Appendix A: Mobile App (Future)](#appendix-a-mobile-app-future)
10. [Appendix B: Enterprise Features](#appendix-b-enterprise-features)

---

## 1. Pregled Projekta

### 1.1 Što je RabBooking?

SaaS booking platforma za property owner-e u Hrvatskoj (apartmani, kuće za odmor) koja omogućava:

**Owner Dashboard** (`owner-app`)
- Upravljanje jedinicama (units) - apartmani, sobe
- Kalendar rezervacija sa timeline prikazom
- Odobravanje/odbijanje rezervacija
- Postavke cijena (base, weekend, sezonske)
- Stripe Connect integracija za plaćanja
- Email notifikacije

**Embeddable Booking Widget** (`widget-app`)
- Kalendar za odabir datuma
- Forma za rezervaciju
- 3 moda rada:
  - `calendarOnly` - samo prikaz dostupnosti
  - `bookingPending` - rezervacija čeka odobrenje owner-a
  - `bookingInstant` - instant booking sa plaćanjem

### 1.2 Trenutna Arhitektura

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Project                          │
│                  (rab-booking-248fc)                         │
├─────────────────────────────────────────────────────────────┤
│  Hosting:                                                    │
│    - rab-booking-owner.web.app  (Owner Dashboard)           │
│    - rab-booking-widget.web.app (Booking Widget)            │
├─────────────────────────────────────────────────────────────┤
│  Backend:                                                    │
│    - Firestore (baza podataka)                              │
│    - Cloud Functions (webhooks, emails, atomic ops)         │
│    - Firebase Auth (autentifikacija owner-a)                │
│    - Firebase Storage (slike)                               │
├─────────────────────────────────────────────────────────────┤
│  Eksterni servisi:                                           │
│    - Stripe Connect (plaćanja)                              │
│    - Resend (emails)                                        │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Očekivano Skaliranje

| Period | Broj Klijenata | Pristup |
|--------|----------------|---------|
| Mjesec 1-3 | 1-5 | Ručno dodavanje slugova |
| Mjesec 3-6 | 5-20 | Automatizacija u Dashboard |
| Mjesec 6-12 | 20-50 | Full self-service |

---

## 2. Arhitekturne Odluke

### 2.1 Finalne Odluke

| Pitanje | Odluka | Obrazloženje |
|---------|--------|--------------|
| **Widget Hosting** | Centralizovano (Firebase) | Jedan deploy = svi klijenti updateovani |
| **Email Link URL** | Subdomain model (kad kupiš domenu) | Profesionalno, skalabilno |
| **Testing (sada)** | Firebase default + query param | Radi odmah, bez kupovine domene |
| **Multi-Property Embed** | Separatni iframe-ovi | SEO friendly, deep linking |
| **Embed Code Distribution** | Copy-paste iframe snippet | Već postoji EmbedCodeGeneratorDialog |

### 2.2 Dva Flow-a: Embed vs Email Link

```
┌─────────────────────────────────────────────────────────────────────┐
│  FLOW 1: WIDGET EMBED (iframe na klijentovom sajtu)                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  jasko-rab.com/apartments/sunset/                                   │
│    └── <iframe src="rab-booking-widget.web.app/?property=X&unit=Y"> │
│                                                                     │
│  Klijent embeduje widget na svoju stranicu.                         │
│  Widget se učitava sa Firebase hostinga.                            │
│  NEMA PROMJENE - ovo već radi!                                      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  FLOW 2: EMAIL LINK (reservation details)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  SADA (testing):                                                    │
│  rab-booking-widget.web.app/view?subdomain=jasko-rab&ref=BK-123     │
│                                                                     │
│  KASNIJE (sa domenom):                                              │
│  jasko-rab.{brandname}.hr/view?ref=BK-123                           │
│                                                                     │
│  Widget parsira subdomain i prikazuje branding.                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Subdomain Model - Detaljna Implementacija

### 3.1 Firestore Schema Update

```typescript
// Firestore: properties/{propertyId}

// TRENUTNO
{
  "name": "Jasko Rab Apartments",
  "ownerId": "user123",
  "units": [...],
  // ...
}

// NOVO (sa subdomain sistemom)
{
  "name": "Jasko Rab Apartments",
  "ownerId": "user123",
  "units": [...],

  // NOVA POLJA:
  "subdomain": "jasko-rab",           // Unique slug za URL
  "branding": {                        // Opciono - za prikaz na booking view
    "logoUrl": "https://...",
    "primaryColor": "#1976d2",
    "displayName": "Jasko Apartments"  // Opciono override za name
  },
  "customDomain": null,                // Za enterprise (kasnije)

  // ...ostala postojeća polja
}
```

### 3.2 Property Model Update (Dart)

```dart
// lib/features/owner_dashboard/domain/models/property.dart

@freezed
class Property with _$Property {
  const factory Property({
    required String id,
    required String name,
    required String ownerId,

    // NOVA POLJA:
    String? subdomain,          // Unique slug: "jasko-rab"
    PropertyBranding? branding, // Logo, color, display name
    String? customDomain,       // Enterprise: "booking.luxury-resort.com"

    // ...ostala polja
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

@freezed
class PropertyBranding with _$PropertyBranding {
  const factory PropertyBranding({
    String? logoUrl,
    String? primaryColor,
    String? displayName,
  }) = _PropertyBranding;

  factory PropertyBranding.fromJson(Map<String, dynamic> json) =>
      _$PropertyBrandingFromJson(json);
}
```

### 3.3 Unique Slug Validation (Cloud Function)

```typescript
// functions/src/slugValidation.ts

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./firebase";
import slugify from "slugify";

/**
 * Generate URL-safe slug from property name
 */
function generateSlug(name: string): string {
  return slugify(name, {
    lower: true,
    strict: true,  // Remove special characters
    locale: 'hr',  // Croatian locale for proper character handling
  });
}

/**
 * Check if subdomain is already taken
 */
async function isSubdomainTaken(subdomain: string, excludePropertyId?: string): Promise<boolean> {
  let query = db.collection('properties')
    .where('subdomain', '==', subdomain)
    .limit(1);

  const snapshot = await query.get();

  if (snapshot.empty) return false;

  // If we're updating existing property, exclude it from check
  if (excludePropertyId && snapshot.docs[0].id === excludePropertyId) {
    return false;
  }

  return true;
}

/**
 * Generate unique subdomain by appending numbers if needed
 */
async function generateUniqueSubdomain(baseName: string, excludePropertyId?: string): Promise<string> {
  const baseSlug = generateSlug(baseName);
  let slug = baseSlug;
  let counter = 1;

  while (await isSubdomainTaken(slug, excludePropertyId)) {
    slug = `${baseSlug}-${counter}`;
    counter++;

    // Safety limit
    if (counter > 100) {
      throw new Error('Unable to generate unique subdomain');
    }
  }

  return slug;
}

/**
 * Callable: Check subdomain availability
 */
export const checkSubdomainAvailability = onCall(async (request) => {
  const { subdomain, propertyId } = request.data;

  if (!subdomain || typeof subdomain !== 'string') {
    throw new HttpsError('invalid-argument', 'Subdomain is required');
  }

  // Validate format: lowercase letters, numbers, hyphens, 3-30 chars
  if (!/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/.test(subdomain)) {
    return {
      available: false,
      error: 'Subdomain must be 3-30 characters, lowercase letters, numbers, and hyphens only. Cannot start or end with hyphen.',
      suggestion: null
    };
  }

  // Reserved subdomains
  const reserved = ['www', 'app', 'api', 'admin', 'dashboard', 'widget', 'booking', 'test', 'demo'];
  if (reserved.includes(subdomain)) {
    return {
      available: false,
      error: 'This subdomain is reserved',
      suggestion: await generateUniqueSubdomain(subdomain, propertyId)
    };
  }

  const isTaken = await isSubdomainTaken(subdomain, propertyId);

  return {
    available: !isTaken,
    error: isTaken ? 'This subdomain is already taken' : null,
    suggestion: isTaken ? await generateUniqueSubdomain(subdomain, propertyId) : null
  };
});

/**
 * Callable: Auto-generate subdomain from property name
 */
export const generateSubdomainFromName = onCall(async (request) => {
  const { propertyName, propertyId } = request.data;

  if (!propertyName || typeof propertyName !== 'string') {
    throw new HttpsError('invalid-argument', 'Property name is required');
  }

  const subdomain = await generateUniqueSubdomain(propertyName, propertyId);

  return { subdomain };
});
```

### 3.4 Widget Subdomain Parser

```dart
// lib/core/services/subdomain_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for parsing and resolving subdomains to property branding
class SubdomainService {
  // Will be updated when domain is purchased
  static const String _baseDomain = 'rabbooking.com'; // Placeholder
  static const String _fallbackSubdomain = 'app';

  /// Singleton instance
  static final SubdomainService _instance = SubdomainService._internal();
  factory SubdomainService() => _instance;
  SubdomainService._internal();

  /// Cache for property branding
  final Map<String, PropertyBranding?> _brandingCache = {};

  /// Get subdomain from current URL
  ///
  /// Priority:
  /// 1. Query parameter: ?subdomain=jasko-rab (for testing)
  /// 2. Actual subdomain: jasko-rab.{domain}.com (production)
  String? getCurrentSubdomain() {
    if (!kIsWeb) return null;

    final uri = Uri.base;

    // Priority 1: Query parameter (for testing without custom domain)
    final querySubdomain = uri.queryParameters['subdomain'];
    if (querySubdomain != null && querySubdomain.isNotEmpty) {
      return querySubdomain;
    }

    // Priority 2: Parse from hostname (production with custom domain)
    final host = uri.host;

    // Skip for localhost/development
    if (host.contains('localhost') || host.contains('127.0.0.1')) {
      return null;
    }

    // Skip for Firebase default domains
    if (host.contains('.web.app') || host.contains('.firebaseapp.com')) {
      return null;
    }

    // Parse subdomain from custom domain
    // jasko-rab.rabbooking.com → ["jasko-rab", "rabbooking", "com"]
    final parts = host.split('.');
    if (parts.length >= 3) {
      final subdomain = parts.first;
      // Validate it's not www or other reserved
      if (subdomain != 'www' && subdomain != 'app') {
        return subdomain;
      }
    }

    return null;
  }

  /// Fetch property branding by subdomain
  Future<PropertyBranding?> getPropertyBranding(String subdomain) async {
    // Check cache first
    if (_brandingCache.containsKey(subdomain)) {
      return _brandingCache[subdomain];
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('properties')
          .where('subdomain', isEqualTo: subdomain)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _brandingCache[subdomain] = null;
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();

      final branding = PropertyBranding(
        propertyId: doc.id,
        subdomain: subdomain,
        name: data['branding']?['displayName'] ?? data['name'] ?? '',
        logoUrl: data['branding']?['logoUrl'],
        primaryColor: data['branding']?['primaryColor'],
      );

      _brandingCache[subdomain] = branding;
      return branding;

    } catch (e) {
      debugPrint('SubdomainService.getPropertyBranding error: $e');
      return null;
    }
  }

  /// Clear cache (call when property branding is updated)
  void clearCache([String? subdomain]) {
    if (subdomain != null) {
      _brandingCache.remove(subdomain);
    } else {
      _brandingCache.clear();
    }
  }
}

/// Property branding data for subdomain
class PropertyBranding {
  final String propertyId;
  final String subdomain;
  final String name;
  final String? logoUrl;
  final String? primaryColor;

  const PropertyBranding({
    required this.propertyId,
    required this.subdomain,
    required this.name,
    this.logoUrl,
    this.primaryColor,
  });
}
```

### 3.5 Email Link Generation (Cloud Function Update)

```typescript
// functions/src/emailService.ts

// CONFIGURATION
// Update this when domain is purchased
const BOOKING_DOMAIN = process.env.BOOKING_DOMAIN || null;
const WIDGET_URL = process.env.WIDGET_URL || "https://rab-booking-widget.web.app";

/**
 * Generate view booking URL based on property subdomain
 *
 * TESTING (no custom domain):
 *   https://rab-booking-widget.web.app/view?subdomain=jasko-rab&ref=BK-123&email=xxx&token=xxx
 *
 * PRODUCTION (with custom domain):
 *   https://jasko-rab.rabbooking.com/view?ref=BK-123&email=xxx&token=xxx
 */
async function generateViewBookingUrl(
  bookingReference: string,
  guestEmail: string,
  accessToken: string,
  propertyId: string
): Promise<string> {
  // Get property subdomain
  const propertyDoc = await db.collection('properties').doc(propertyId).get();
  const property = propertyDoc.data();
  const subdomain = property?.subdomain || 'app';

  // Build URL parameters
  const params = new URLSearchParams({
    ref: bookingReference,
    email: guestEmail,
    token: accessToken,
  });

  // Check if using custom domain
  if (BOOKING_DOMAIN) {
    // Production: subdomain.domain.com/view?ref=XXX
    return `https://${subdomain}.${BOOKING_DOMAIN}/view?${params.toString()}`;
  } else {
    // Testing: widget.web.app/view?subdomain=XXX&ref=XXX
    params.set('subdomain', subdomain);
    return `${WIDGET_URL}/view?${params.toString()}`;
  }
}

// Update email template usage:
export async function sendBookingConfirmation(booking: Booking): Promise<void> {
  const viewUrl = await generateViewBookingUrl(
    booking.booking_reference,
    booking.guest_email,
    booking.access_token,
    booking.property_id
  );

  // ... rest of email sending code
  // Use viewUrl in email template
}
```

### 3.6 BookingViewScreen - Branding Support

```dart
// lib/features/widget/presentation/screens/booking_view_screen.dart

class BookingViewScreen extends ConsumerStatefulWidget {
  final String? bookingRef;
  final String? email;
  final String? token;

  const BookingViewScreen({
    super.key,
    this.bookingRef,
    this.email,
    this.token,
  });

  @override
  ConsumerState<BookingViewScreen> createState() => _BookingViewScreenState();
}

class _BookingViewScreenState extends ConsumerState<BookingViewScreen> {
  PropertyBranding? _branding;
  bool _isLoadingBranding = true;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final subdomain = SubdomainService().getCurrentSubdomain();

    if (subdomain != null) {
      final branding = await SubdomainService().getPropertyBranding(subdomain);
      if (mounted) {
        setState(() {
          _branding = branding;
          _isLoadingBranding = false;
        });

        // Update page title if branding loaded
        if (kIsWeb && branding != null) {
          _updatePageTitle(branding.name);
        }
      }
    } else {
      setState(() => _isLoadingBranding = false);
    }
  }

  void _updatePageTitle(String propertyName) {
    // Update browser tab title
    if (kIsWeb) {
      // Use dart:html via conditional import
      document.title = '$propertyName - View Booking';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while fetching branding
    if (_isLoadingBranding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check for subdomain not found
    final subdomain = SubdomainService().getCurrentSubdomain();
    if (subdomain != null && _branding == null) {
      return SubdomainNotFoundScreen(subdomain: subdomain);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_branding?.name ?? 'View Booking'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        // Apply custom color if branding has primaryColor
        backgroundColor: _branding?.primaryColor != null
            ? Color(int.parse(_branding!.primaryColor!.replaceFirst('#', '0xFF')))
            : null,
      ),
      body: BookingLookupForm(
        initialRef: widget.bookingRef,
        initialEmail: widget.email,
        initialToken: widget.token,
        branding: _branding,
      ),
    );
  }
}
```

### 3.7 Error Screen - Subdomain Not Found

```dart
// lib/features/widget/presentation/screens/subdomain_not_found_screen.dart

import 'package:flutter/material.dart';

class SubdomainNotFoundScreen extends StatelessWidget {
  final String subdomain;

  const SubdomainNotFoundScreen({
    super.key,
    required this.subdomain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.domain_disabled,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Property Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The property "$subdomain" could not be found.\n'
                'Please check the link and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to main widget or show contact info
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Contact Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Widget Embedding Arhitektura

### 4.1 Embed Code Generator (Postojeći - bez promjena)

Owner App već ima `EmbedCodeGeneratorDialog` koji generira iframe kod:

```html
<iframe
  src="https://rab-booking-widget.web.app/?property=XXX&unit=YYY&lang=hr"
  width="100%"
  height="900px"
  frameborder="0"
  allow="payment"
></iframe>
```

### 4.2 Security Headers (Već konfigurisano)

```json
// firebase.json - već postoji
{
  "hosting": {
    "target": "widget",
    "headers": [
      {
        "source": "**",
        "headers": [
          { "key": "X-Frame-Options", "value": "ALLOWALL" },
          { "key": "Content-Security-Policy", "value": "frame-ancestors *" }
        ]
      }
    ]
  }
}
```

### 4.3 Multi-Property Scenario

Za klijenta sa 7 apartmana (npr. jasko-rab.com):

```
jasko-rab.com/
├── apartments/
│   ├── sunset/
│   │   └── <iframe src="widget/?property=X&unit=SUNSET_ID">
│   ├── marina/
│   │   └── <iframe src="widget/?property=X&unit=MARINA_ID">
│   ├── beach/
│   │   └── <iframe src="widget/?property=X&unit=BEACH_ID">
│   └── ... (4 more)
```

Svaki apartman ima svoju stranicu sa svojim iframe-om.

---

## 5. Implementacijski Plan (Faza 1 - Bez Domene)

### 5.1 Overview

```
FAZA 1: SUBDOMAIN SISTEM (bez kupovine domene)
Trajanje: 8-12 sati
Status: MOŽE ODMAH

┌─────────────────────────────────────────────────────────────────┐
│  KORAK 1: Firestore + Model Update (2-3 sata)                   │
│  ─────────────────────────────────────────────                  │
│  □ Dodaj subdomain field u Property model                       │
│  □ Dodaj PropertyBranding model                                 │
│  □ Regeneriraj freezed files                                    │
│  □ Update PropertyRepository                                    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  KORAK 2: Cloud Functions (2-3 sata)                            │
│  ─────────────────────────────────────                          │
│  □ Implementiraj checkSubdomainAvailability                     │
│  □ Implementiraj generateSubdomainFromName                      │
│  □ Update emailService.ts sa generateViewBookingUrl             │
│  □ Deploy functions                                             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  KORAK 3: Widget Subdomain Parser (2-3 sata)                    │
│  ──────────────────────────────────────────                     │
│  □ Kreiraj SubdomainService                                     │
│  □ Kreiraj PropertyBranding class                               │
│  □ Update BookingViewScreen sa branding support                 │
│  □ Kreiraj SubdomainNotFoundScreen                              │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  KORAK 4: Owner Dashboard UI (2-3 sata)                         │
│  ─────────────────────────────────────                          │
│  □ Dodaj subdomain field u Property settings                    │
│  □ Real-time availability check                                 │
│  □ Auto-generate suggestion from property name                  │
│  □ Branding settings (logo, color) - opciono                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Detaljan Korak 1: Firestore + Model

```bash
# 1. Update Property model
# lib/features/owner_dashboard/domain/models/property.dart

# 2. Regenerate freezed
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Update repository
# lib/features/owner_dashboard/data/repositories/property_repository.dart
```

### 5.3 Detaljan Korak 2: Cloud Functions

```bash
# 1. Create new file
touch functions/src/slugValidation.ts

# 2. Update index.ts exports
# export { checkSubdomainAvailability, generateSubdomainFromName } from './slugValidation';

# 3. Update emailService.ts

# 4. Deploy
cd functions && npm run deploy
```

### 5.4 Detaljan Korak 3: Widget

```bash
# 1. Create subdomain service
touch lib/core/services/subdomain_service.dart

# 2. Create not found screen
touch lib/features/widget/presentation/screens/subdomain_not_found_screen.dart

# 3. Update booking_view_screen.dart

# 4. Build and deploy widget
flutter build web --target lib/widget_main.dart --output build/web_widget
firebase deploy --only hosting:widget
```

### 5.5 Detaljan Korak 4: Owner Dashboard

```dart
// lib/features/owner_dashboard/presentation/screens/property_settings_screen.dart

// Add subdomain section:
class SubdomainSettingsSection extends ConsumerStatefulWidget {
  final Property property;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Booking Subdomain', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: property.subdomain,
                decoration: InputDecoration(
                  hintText: 'e.g., jasko-rab',
                  suffixText: '.${currentDomain}',
                  helperText: 'Used in booking confirmation emails',
                ),
                onChanged: _checkAvailability,
              ),
            ),
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_availability != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  _availability!.available ? Icons.check_circle : Icons.error,
                  color: _availability!.available ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
        if (_availability?.suggestion != null)
          TextButton(
            onPressed: () => _useSubdomain(_availability!.suggestion!),
            child: Text('Use suggestion: ${_availability!.suggestion}'),
          ),
      ],
    );
  }
}
```

---

## 6. Custom Domain Setup (Faza 2 - Implementirano)

### 6.1 Status

```
FAZA 2: CUSTOM DOMAIN (bookbed.io)
Status: ✅ DOMEN KUPLJEN I KONFIGURISAN
Pristup: MANUAL SETUP (ručno dodavanje subdomena)

✅ Owner postavlja subdomain u Property settings (automatski)
✅ Admin dodaje subdomain u Firebase Hosting (manual)
✅ Admin dodaje DNS record u Cloudflare (manual)
✅ Sistem generiše email linkove sa subdomain-om
```

### 6.2 Environment Variables

**Firebase Functions:**
```bash
BOOKING_DOMAIN=bookbed.io
WIDGET_URL=https://bookbed.io
```

**Status:** ✅ Već konfigurisano u `functions/src/emailService.ts`

---

## 7. Testing Strategija

### 7.1 Unit Tests

```dart
// test/services/subdomain_service_test.dart

void main() {
  group('SubdomainService', () {
    test('extracts subdomain from query param', () {
      // Mock Uri.base with ?subdomain=test
      final subdomain = SubdomainService().getCurrentSubdomain();
      expect(subdomain, equals('test'));
    });

    test('returns null for localhost', () {
      // Mock Uri.base with localhost
      final subdomain = SubdomainService().getCurrentSubdomain();
      expect(subdomain, isNull);
    });

    test('fetches branding from Firestore', () async {
      // Setup mock Firestore
      final branding = await SubdomainService().getPropertyBranding('jasko-rab');
      expect(branding, isNotNull);
      expect(branding!.name, isNotEmpty);
    });
  });
}
```

### 7.2 Integration Tests

```
TEST SCENARIO 1: Booking Flow with Email Link
─────────────────────────────────────────────
1. Create booking via widget
2. Verify email is sent with correct link
3. Open link in browser
4. Verify BookingViewScreen shows correct data
5. Verify branding is applied

TEST SCENARIO 2: Subdomain Not Found
────────────────────────────────────
1. Open widget with ?subdomain=nonexistent
2. Verify SubdomainNotFoundScreen is shown
3. Verify error is logged to analytics

TEST SCENARIO 3: Owner Sets Subdomain
─────────────────────────────────────
1. Open property settings
2. Enter subdomain
3. Verify availability check works
4. Save subdomain
5. Create booking
6. Verify email link uses new subdomain
```

### 7.3 Manual Testing Checklist

```
□ Firebase default URL works:
  rab-booking-widget.web.app/view?subdomain=test&ref=BK-123&email=test@test.com

□ Subdomain availability check works in Owner Dashboard

□ Email contains correct link format

□ Clicking email link shows correct booking details

□ Branding (logo, color) applies if configured

□ SubdomainNotFoundScreen shows for invalid subdomain

□ Mobile browser displays correctly
```

---

## 8. Skaliranje (5-20 Klijenata)

### 8.1 Self-Service Flow

Za 5-20 klijenata, Owner Dashboard treba:

```
┌─────────────────────────────────────────────────────────────────┐
│  OWNER ONBOARDING FLOW                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Owner kreira account                                        │
│     ↓                                                           │
│  2. Owner kreira Property                                       │
│     ↓                                                           │
│  3. System auto-generiše subdomain iz imena                     │
│     "Jasko Rab Apartments" → "jasko-rab"                        │
│     ↓                                                           │
│  4. Owner može promijeniti subdomain (ako želi)                 │
│     ↓                                                           │
│  5. Owner kreira Units                                          │
│     ↓                                                           │
│  6. Owner kopira embed code za svaki unit                       │
│     ↓                                                           │
│  7. Widget radi, emails koriste subdomain                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Automation Points

**Napomena:** Auto-generate subdomain na property create **NEMA** - owner ručno postavlja subdomain u Property settings UI.

Owner može:
1. Ručno unijeti subdomain u Property settings
2. Koristiti "Auto-generate" button koji poziva `generateSubdomainFromName` Cloud Function
3. Sistem provjerava dostupnost i validaciju prije spremanja

**Razlog:** Manual kontrola subdomena omogućava owner-u da odabere željeni subdomain, a admin ručno dodaje DNS records u Firebase/Cloudflare.

### 8.3 Analytics & Monitoring

```typescript
// Track subdomain usage
export async function logSubdomainAccess(subdomain: string, eventType: string) {
  await db.collection('analytics').add({
    subdomain,
    eventType, // 'view', 'booking', 'email_click'
    timestamp: FieldValue.serverTimestamp(),
    userAgent: // from request
  });
}
```

---

## Appendix A: Mobile App (Future)

> **Status:** Planirano za Fazu 3 (6+ mjeseci)
> **Prioritet:** Nizak - fokus je na Web

### A.1 Monorepo Struktura (Kad Bude Vrijeme)

```
rabbooking/
├── melos.yaml
├── apps/
│   ├── owner_dashboard_web/        # Postojeći
│   ├── owner_dashboard_mobile/     # NOVO - iOS + Android
│   └── booking_widget/             # Postojeći
├── packages/
│   ├── core/                       # Shared models, repos
│   ├── data/                       # API clients
│   ├── ui_kit/                     # Shared widgets
│   └── platform_utils/             # Platform abstraction
```

### A.2 Platform Abstraction (Za Mobile Kompatibilnost)

Zamjena `dart:html` sa conditional imports - vidjeti originalnu dokumentaciju.

### A.3 Mobile-Specific Features

- Push notifications za nove rezervacije
- Offline calendar view
- Quick approve/reject actions
- Deep linking iz email-a

---

## Appendix B: Enterprise Features

### B.1 Custom Domains (Pro Tier)

```
FREE TIER:
  └── {slug}.{brandname}.hr

PRO TIER (+50€/mj):
  └── booking.{client-domain}.com
  └── Uklonjen "Powered by" branding
  └── Priority support
```

### B.2 Implementation

```typescript
// Property with custom domain
{
  "subdomain": "luxury-resort",
  "customDomain": "booking.luxury-resort.com",  // Pro feature
  // ...
}

// Email link generation checks customDomain first
if (property.customDomain) {
  return `https://${property.customDomain}/view?ref=${ref}`;
}
```

### B.3 White-Label (Enterprise)

- Potpuno custom branding
- Dedicated support
- SLA guarantees
- Custom integrations

---

## ✅ Implementation Verification (2025-12-15)

### Faza 1 (Bez Domene) - ✅ COMPLETED

- [x] Property model update sa subdomain field (`subdomain`, `branding`, `customDomain`)
- [x] PropertyBranding model (embedded u Property)
- [x] checkSubdomainAvailability Cloud Function (`functions/src/subdomainService.ts:166-242`)
- [x] generateSubdomainFromName Cloud Function (`functions/src/subdomainService.ts:251-290`)
- [x] Update emailService.ts (`generateViewBookingUrl()` sa security validation)
- [x] SubdomainService (widget) - potpuna implementacija sa slug support
- [x] BookingViewScreen branding support (sa cached optimization)
- [x] SubdomainNotFoundScreen (user-friendly error UI)
- [x] Owner Dashboard subdomain UI (validation + suggestions)
- [x] Unit tests (subdomain regex, reserved domains, slug generation)
- [x] Integration tests (booking flow, email links)
- [x] Manual testing (production bookbed.io domain)

### Faza 2 (Sa Domenom) - ✅ COMPLETED

- [x] Kupovina domene (bookbed.io)
- [x] BOOKING_DOMAIN env variable (`functions/src/emailService.ts:311`)
- [x] Manual setup proces (admin workflow dokumentovan)
- [x] End-to-end test sa pravom domenom
- [x] DNS wildcard setup (*.bookbed.io → Firebase Hosting)
- [x] Subdomain validation (RFC 1123 compliance)
- [x] URL slug support (`{subdomain}.bookbed.io/{unit-slug}`)

**Napomena:** Auto-generate subdomain na property create **NEMA** - owner ručno postavlja u UI.
**Napomena:** Auto-dodavanje subdomena u Firebase/Cloudflare **NEMA** - admin ručno dodaje.

### Additional Features Implemented

- [x] **Cloud Functions Infrastructure**
  - Rate limiting (`checkRateLimit()`, `enforceRateLimit()`)
  - Input sanitization (`sanitizeText()`, `sanitizeEmail()`, `sanitizePhone()`)
  - Structured logging (`logInfo()`, `logError()`, `logSuccess()`)

- [x] **Email System V2**
  - Modern template design
  - Subdomain-aware URL generation
  - Multi-language support (hr, en, de, it)
  - Security validation (URL injection prevention)

**Overall Implementation: 100% Complete**

---

*Dokument generiran: Decembar 2024*
*Verzija: 2.0*
*Autor: Claude Code + Korisnik*
