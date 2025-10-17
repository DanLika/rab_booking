# Error Handling & Logging System

## Pregled

Ovaj projekat implementira robust error handling sistem sa:
- Custom exception hierarchijom
- Result pattern za funkcionalnu obradu grešaka
- ErrorHandler utiliti za user-friendly poruke
- Logging service za praćenje događaja
- Analytics service za error tracking (spreman za Firebase/Sentry)
- Globalni error widgeti

## Struktura

```
lib/core/
├── exceptions/
│   └── app_exceptions.dart          # Custom exception classes
├── errors/
│   ├── error_handler.dart           # Error handling utilities
│   └── error_handling_examples.dart # Usage examples
├── utils/
│   ├── result.dart                  # Result<T> type
│   └── async_helpers.dart           # Async helper functions
├── services/
│   ├── logging_service.dart         # Logging service
│   └── analytics_service.dart       # Analytics & error tracking
└── shared/widgets/
    └── error_state_widget.dart      # Error UI widget
```

## Exception Hierarchy

### Base Exception
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
}
```

### Available Exceptions
- `NetworkException` - Problemi sa mrežom/konekcijom
- `AuthException` - Greške pri autentifikaciji
- `AuthorizationException` - Nedostatak dozvola
- `DatabaseException` - Greške u bazi podataka
- `ValidationException` - Greške validacije unosa
- `NotFoundException` - Resurs nije pronađen
- `ConflictException` - Konflikt podataka
- `TimeoutException` - Timeout operacije
- `BookingException` - Specifične greške za booking
- `PaymentException` - Greške plaćanja

## Result Pattern

```dart
// Result<T> omogućava funkcionalnu obradu grešaka
Future<Result<List<Property>>> fetchProperties() async {
  try {
    final response = await _client.from('properties').select();
    return Success(response);
  } on SocketException {
    return const Failure(NetworkException());
  } catch (e) {
    return const Failure(DatabaseException('Greška'));
  }
}

// Korištenje
final result = await repository.fetchProperties();
result.when(
  success: (properties) => displayProperties(properties),
  failure: (exception) => showError(exception),
);
```

## Error Handler

```dart
// Konvertuj greške u user-friendly poruke (na hrvatskom/srpskom)
String message = ErrorHandler.getUserFriendlyMessage(error);

// Prikaži SnackBar sa greškom
ErrorHandler.showErrorSnackBar(context, error);

// Prikaži dialog sa greškom
ErrorHandler.showErrorDialog(context, error);

// Loguj grešku
await ErrorHandler.logError(error, stackTrace);
```

## Riverpod Integration

```dart
@riverpod
class PropertiesNotifier extends _$PropertiesNotifier {
  @override
  Future<List<Property>> build() async {
    return executeAsync(() async {
      final result = await ref.read(propertyRepositoryProvider).fetchProperties();
      return result.when(
        success: (data) => data,
        failure: (exception) => throw exception,
      );
    });
  }
}

// U UI-u
Consumer(
  builder: (context, ref, child) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);

    return propertiesAsync.when(
      data: (properties) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) {
        ErrorHandler.showErrorSnackBar(context, error);
        return ErrorStateWidget(
          message: ErrorHandler.getUserFriendlyMessage(error),
          onRetry: () => ref.invalidate(propertiesNotifierProvider),
        );
      },
    );
  },
)
```

## Logging Service

```dart
// Različiti nivoi logiranja
LoggingService.logInfo('Info poruka');
LoggingService.logWarning('Upozorenje');
LoggingService.logError('Greška', error, stackTrace);
LoggingService.logDebug('Debug info'); // samo u debug modu

// Specifični logovi
LoggingService.logNetworkRequest('GET', '/api/properties');
LoggingService.logUserAction('property_viewed', data: {'id': '123'});
LoggingService.logNavigation('/property-details');
```

## Analytics Service

```dart
// Praćenje događaja
AnalyticsService.logEvent('booking_created', parameters: {
  'property_id': propertyId,
  'amount': amount,
});

// Screen tracking
AnalyticsService.logScreenView('PropertyDetailsScreen');

// User tracking
AnalyticsService.setUserId(userId);
AnalyticsService.setUserProperties({'role': 'guest'});

// Error tracking
await AnalyticsService.reportError(error, stackTrace);

// Booking-specific analytics
AnalyticsService.logBookingCreated(
  propertyId: 'prop-123',
  amount: 299.99,
  nights: 3,
);
```

## Error State Widget

```dart
ErrorStateWidget(
  message: 'Nekretnine nisu pronađene',
  onRetry: () => ref.invalidate(propertiesProvider),
  icon: Icons.search_off, // optional
)
```

## Setup za Production Error Tracking

### Firebase Crashlytics

1. Dodaj u `pubspec.yaml`:
```yaml
dependencies:
  firebase_crashlytics: ^3.4.0
```

2. U `lib/core/services/analytics_service.dart`, odkomentiraj:
```dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

3. U `main.dart`:
```dart
await AnalyticsService.initializeCrashlytics();
```

### Sentry

1. Dodaj u `pubspec.yaml`:
```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

2. Registruj se na [sentry.io](https://sentry.io) i dobij DSN

3. U `lib/core/services/analytics_service.dart`:
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
    options.tracesSampleRate = 1.0;
  },
);
```

4. U `main.dart`:
```dart
await AnalyticsService.initializeSentry();
```

## Best Practices

1. **Uvijek koristi Result pattern u repositorijima**
   - Omogućava eksplicitnu obradu grešaka
   - Čini kod čitljivijim i lakšim za održavanje

2. **Loguj sve greške**
   - Koristi `ErrorHandler.logError()` za automatsko logiranje
   - U produkciji greške se šalju na tracking service

3. **User-friendly poruke**
   - Nikad ne prikazuj tehničke greške korisniku
   - Koristi `ErrorHandler.getUserFriendlyMessage()` za konverziju

4. **Konzistentno koristi ErrorStateWidget**
   - Omogućava retry funkcionalnost
   - Uniforman UX kroz cijelu aplikaciju

5. **Specifične exception klase**
   - Koristi `BookingException.unitNotAvailable()` umjesto generičkih
   - Lakše za filtriranje i obradu

## Primjeri

Detaljni primjeri korištenja možeš pronaći u:
- `lib/core/errors/error_handling_examples.dart` - Kompletni primjeri
- `lib/features/auth/data/auth_repository.dart` - Postojeći repository

## User-Friendly Poruke (Hrvatski/Srpski)

- Network error: "Provjerite internet konekciju i pokušajte ponovo."
- Auth error: "Greška prilikom autentifikacije. Molimo prijavite se ponovo."
- Database error: "Greška u bazi podataka. Pokušajte ponovo."
- Payment error: "Greška prilikom plaćanja: [detalji]"
- Not found: "Traženi resurs nije pronađen."
- Timeout: "Operacija je istekla. Pokušajte ponovo."
- Authorization: "Nemate dozvolu za ovu akciju."
- Generic: "Došlo je do neočekivane greške. Pokušajte ponovo."

## Testing

```bash
# Pokreni build_runner
dart run build_runner build --delete-conflicting-outputs

# Provjeri kod
flutter analyze

# Pokreni testove
flutter test
```

## Implementovano u Prompt 16

✅ Custom exception hierarchy
✅ ErrorHandler utility class
✅ Result type pattern
✅ Async helper functions
✅ ErrorStateWidget
✅ LoggingService
✅ AnalyticsService (pripremljen za Firebase/Sentry)
✅ Detaljni primjeri korištenja
✅ User-friendly poruke na hrvatskom/srpskom

---

**Napomena**: Firebase Crashlytics i Sentry integracije su pripremljene ali zakomentirane. Odkomentiraš ih kada budeš spreman za production deployment.
