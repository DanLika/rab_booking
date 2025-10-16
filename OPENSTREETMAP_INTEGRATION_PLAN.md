# OpenStreetMap Integration Plan
## Rab Booking - Map & Location Features

### 📦 Installed Dependencies

```yaml
flutter_map: ^7.0.2      # OSM map rendering
latlong2: ^0.9.1         # Latitude/Longitude objects
geolocator: ^13.0.2      # User location & permissions
geocoding: ^3.0.0        # Address ↔ Coordinates conversion
```

---

## 🗺️ Features to Implement

### 1. **Property Location Display** (Priority: HIGH)
Prikaži lokaciju nekretnine na mapi sa markerom.

**Components:**
- `lib/shared/widgets/maps/property_location_map.dart`
  - Stateless map widget za prikaz jedne lokacije
  - Input: `LatLng` koordinate
  - Marker na lokaciji nekretnine
  - Zoom controls
  - Fullscreen option

**Use Cases:**
- Property Details screen - prikaži gdje se nalazi apartman
- Unit Details screen - prikaži lokaciju unique unita

---

### 2. **Interactive Search Map** (Priority: HIGH)
Mapa za pretraživanje nekretnina po lokaciji.

**Components:**
- `lib/features/search/widgets/search_map_view.dart`
  - Full-screen interactive map
  - Multiple property markers (clusters za veći broj)
  - Tap marker → prikaži property card preview
  - Drag map → update search results
  - Current location button

**Features:**
- **Marker Clustering**: Grupiranje markera kada je zoom out
- **Property Preview Card**: Bottom sheet sa osnovnim info (slika, cijena, rating)
- **Filter Integration**: Prikaži samo properties koji match filtere

---

### 3. **Location Picker** (Priority: MEDIUM)
Za property ownere - odabir lokacije kada kreiraju novu nekretninu.

**Components:**
- `lib/features/owner/widgets/location_picker_map.dart`
  - Draggable marker
  - Search box za adrese (geocoding)
  - Current location button
  - Confirm location button

**Flow:**
1. Owner kreira property
2. Klikne "Set Location"
3. Otvori se fullscreen mapa
4. Može da:
   - Klikne na mapu da postavi marker
   - Draguje marker
   - Pretraži adresu (geocoding)
   - Koristi svoju trenutnu lokaciju
5. Confirm → vrati se na form sa lat/lng

---

### 4. **Nearby Properties** (Priority: MEDIUM)
Prikaži properties u blizini trenutne lokacije/odabrane lokacije.

**Components:**
- `lib/features/search/widgets/nearby_properties_map.dart`
  - Map sa circle overlay (radius indicator)
  - Properties unutar radijusa
  - Slider za promjenu radijusa (1km - 50km)

**Backend:**
- `PropertyRepository.getNearbyProperties()` - već implementirano!
- Koristi Haversine formula za distance calculation

---

### 5. **Directions & Navigation** (Priority: LOW)
Link za navigaciju do nekretnine.

**Components:**
- Button na Property Details: "Get Directions"
- Otvara:
  - **Android**: Google Maps app sa koordinatama
  - **iOS**: Apple Maps app sa koordinatama
  - **Web**: OSM Directions (https://www.openstreetmap.org/directions)

---

## 📂 File Structure

```
lib/
├── shared/
│   ├── widgets/
│   │   └── maps/
│   │       ├── base_osm_map.dart              # Base map widget (reusable)
│   │       ├── property_location_map.dart     # Static location display
│   │       ├── property_marker.dart           # Custom property marker widget
│   │       └── map_controls.dart              # Zoom, location, fullscreen buttons
│   │
│   ├── services/
│   │   ├── location_service.dart              # Geolocator wrapper
│   │   └── geocoding_service.dart             # Geocoding wrapper
│   │
│   └── providers/
│       └── location_providers.dart            # Riverpod providers for location
│
├── features/
│   ├── search/
│   │   └── widgets/
│   │       ├── search_map_view.dart           # Interactive search map
│   │       ├── property_marker_cluster.dart   # Marker clustering logic
│   │       └── property_preview_card.dart     # Bottom sheet preview
│   │
│   └── owner/
│       └── widgets/
│           └── location_picker_map.dart       # Location picker for owners
│
└── core/
    └── constants/
        └── map_constants.dart                 # Tile URLs, zoom levels, defaults
```

---

## 🔧 Implementation Details

### Base Map Configuration

```dart
// lib/core/constants/map_constants.dart

class MapConstants {
  // OpenStreetMap tile servers
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Alternative tile servers (fallback)
  static const String osmHotTileUrl = 'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  // Default center (Island Rab, Croatia)
  static const LatLng rabIslandCenter = LatLng(44.7604, 14.7606);

  // Zoom levels
  static const double defaultZoom = 13.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // Property details zoom
  static const double propertyZoom = 15.0;

  // Search map zoom
  static const double searchZoom = 12.0;

  // Nearby radius defaults (km)
  static const double defaultRadius = 10.0;
  static const double minRadius = 1.0;
  static const double maxRadius = 50.0;

  // User attribution (required by OSM)
  static const String attribution = '© OpenStreetMap contributors';
}
```

---

### Base OSM Map Widget

```dart
// lib/shared/widgets/maps/base_osm_map.dart

class BaseOSMMap extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final bool showZoomControls;
  final bool showLocationButton;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;

  const BaseOSMMap({
    super.key,
    required this.center,
    this.zoom = MapConstants.defaultZoom,
    this.markers = const [],
    this.showZoomControls = true,
    this.showLocationButton = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        onTap: onTap != null ? (_, latLng) => onTap!(latLng) : null,
        onLongPress: onLongPress != null ? (_, latLng) => onLongPress!(latLng) : null,
      ),
      children: [
        // OSM Tile Layer
        TileLayer(
          urlTemplate: MapConstants.osmTileUrl,
          userAgentPackageName: 'com.rab_booking.app',
          maxNativeZoom: 19,
        ),

        // Markers Layer
        if (markers.isNotEmpty)
          MarkerLayer(markers: markers),

        // Attribution (required by OSM)
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              MapConstants.attribution,
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),

        // Controls
        if (showZoomControls || showLocationButton)
          MapControls(
            showZoomControls: showZoomControls,
            showLocationButton: showLocationButton,
          ),
      ],
    );
  }
}
```

---

### Location Service

```dart
// lib/shared/services/location_service.dart

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  // Check location permission status
  Future<LocationPermission> checkPermission();

  // Request location permission
  Future<LocationPermission> requestPermission();

  // Get current location
  Future<Position?> getCurrentLocation();

  // Get location as LatLng
  Future<LatLng?> getCurrentLatLng();

  // Open location settings
  Future<bool> openLocationSettings();

  // Stream of location updates (for real-time tracking)
  Stream<Position> getPositionStream();
}
```

---

### Geocoding Service

```dart
// lib/shared/services/geocoding_service.dart

class GeocodingService {
  // Address → Coordinates
  Future<LatLng?> getCoordinatesFromAddress(String address);

  // Coordinates → Address
  Future<String?> getAddressFromCoordinates(LatLng location);

  // Search places (autocomplete)
  Future<List<PlaceResult>> searchPlaces(String query);

  // Get place details
  Future<PlaceDetails?> getPlaceDetails(String placeId);
}

class PlaceResult {
  final String displayName;
  final LatLng location;
  final String? placeId;
}

class PlaceDetails {
  final String address;
  final LatLng location;
  final String? city;
  final String? country;
  final String? postalCode;
}
```

---

## 🔐 Permissions Setup

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest>
    <!-- Location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Internet permission (already exists) -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <application>
        <!-- ... -->
    </application>
</manifest>
```

### iOS (`ios/Runner/Info.plist`)

```xml
<dict>
    <!-- Location permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Rab Booking needs your location to show nearby properties and help you find accommodations.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Rab Booking needs your location to show nearby properties.</string>

    <!-- ... -->
</dict>
```

---

## 🎨 Custom Property Markers

```dart
// lib/shared/widgets/maps/property_marker.dart

class PropertyMarker {
  static Marker create({
    required String propertyId,
    required LatLng location,
    required double price,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Marker(
      point: location,
      width: 100,
      height: 50,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.villa,
                size: 16,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              SizedBox(width: 4),
              Text(
                '€${price.toInt()}',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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

## 🚀 Implementation Order (Suggested)

### Phase 1: Basic Map Display (Prompt 06 ili 07)
1. ✅ Add dependencies (DONE)
2. Create `MapConstants`
3. Create `BaseOSMMap` widget
4. Create `PropertyLocationMap` widget
5. Integrate into Property Details screen
6. Test with real property coordinates

### Phase 2: Location Services (Prompt 08)
1. Setup permissions (Android + iOS)
2. Create `LocationService`
3. Create `GeocodingService`
4. Create location providers (Riverpod)
5. Test location permissions flow

### Phase 3: Interactive Search Map (Prompt 09)
1. Create `SearchMapView`
2. Create `PropertyMarker` widget
3. Create `PropertyPreviewCard` bottom sheet
4. Integrate with search filters
5. Add marker clustering
6. Test with multiple properties

### Phase 4: Location Picker (Prompt 10)
1. Create `LocationPickerMap` for owners
2. Implement draggable marker
3. Integrate geocoding search
4. Add to Create Property flow
5. Test address → coordinates conversion

### Phase 5: Nearby Properties (Prompt 11)
1. Create `NearbyPropertiesMap`
2. Add radius selector slider
3. Integrate with `PropertyRepository.getNearbyProperties()`
4. Test distance calculations

### Phase 6: Navigation & Directions (Prompt 12)
1. Add "Get Directions" button
2. Implement platform-specific navigation
3. Test on Android, iOS, Web

---

## 📝 Notes

### OSM Tile Server Usage Policy
- **Attribution required**: Uvijek prikaži "© OpenStreetMap contributors"
- **Rate limits**: Max 2 requests/second per client
- **User-Agent**: Mora biti specifičan (koristimo package name)
- **Caching**: flutter_map automatski cache-ira tile-ove

### Alternative Tile Servers (ako treba)
```dart
// Humanitarian OSM (bolji za mobilne app)
'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png'

// Stamen Terrain (lijepi outdoors view)
'https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}.png'

// CartoDB Positron (minimalistički light theme)
'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png'
```

### Geocoding Service
Za početak koristimo **Flutter geocoding** paket (koristi native platforme):
- Android: Geocoder API (besplatan, ali zahtijeva Google Play Services)
- iOS: CLGeocoder (besplatan)

Ako treba fallback ili više kontrole, možemo dodati **Nominatim** (OSM geocoder):
```dart
// https://nominatim.openstreetmap.org/search?q={query}&format=json
```

---

## ✅ Testing Checklist

- [ ] Map se učitava sa Rab island default center
- [ ] Markers se prikazuju na pravim koordinatama
- [ ] Zoom controls rade
- [ ] Current location button radi (permission flow)
- [ ] Tap na marker otvara property preview
- [ ] Geocoding: adresa → koordinate
- [ ] Reverse geocoding: koordinate → adresa
- [ ] Permission denied flow (show explanation dialog)
- [ ] Offline map loading (cache)
- [ ] Performance sa 100+ markers (clustering)

---

## 🔗 Resources

- **flutter_map docs**: https://docs.fleaflet.dev/
- **OpenStreetMap usage policy**: https://operations.osmfoundation.org/policies/tiles/
- **Nominatim API**: https://nominatim.org/release-docs/develop/api/Overview/
- **Geolocator plugin**: https://pub.dev/packages/geolocator
- **Geocoding plugin**: https://pub.dev/packages/geocoding

---

**NAPOMENA**: Ovaj plan pokriva sve map features za aplikaciju. Implementacija će biti postepena kroz naredne prompte, a možemo prioritizirati feature-e prema potrebi.
