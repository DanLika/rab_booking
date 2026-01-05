# Firebase Agent

Kreiraj Firebase CRUD operacije prema korisnikovom opisu.

## Obavezni standardi:

### 1. Repository Pattern

**Interface (domain layer):**
```dart
// lib/shared/repositories/example_repository.dart
abstract class ExampleRepository {
  Future<List<ExampleModel>> getAll(String ownerId);
  Future<ExampleModel?> getById(String id);
  Future<String> create(ExampleModel model);
  Future<void> update(ExampleModel model);
  Future<void> delete(String id);
  Stream<List<ExampleModel>> watchAll(String ownerId);
}
```

**Implementation (data layer):**
```dart
// lib/shared/repositories/firebase/firebase_example_repository.dart
class FirebaseExampleRepository implements ExampleRepository {
  final FirebaseFirestore _firestore;

  FirebaseExampleRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('examples');

  @override
  Future<List<ExampleModel>> getAll(String ownerId) async {
    final snapshot = await _collection
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExampleModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<String> create(ExampleModel model) async {
    final docRef = await _collection.add(model.toJson());
    return docRef.id;
  }

  @override
  Future<void> update(ExampleModel model) async {
    await _collection.doc(model.id).update(model.toJson());
  }

  @override
  Future<void> delete(String id) async {
    // Hard delete (default) - za cascade brisanje
    await _collection.doc(id).delete();
  }
}
```

### 2. Delete Strategije

**Hard Delete (default)** - koristi za:
- Property, Unit - cascade brisanje svih povezanih podataka
- DailyPrice - nije potreban recovery

```dart
Future<void> delete(String id) async {
  await _collection.doc(id).delete();
}
```

**Soft Delete** - koristi SAMO za podatke gdje treba recovery opcija:
- AdditionalServices - mogu se slučajno obrisati

```dart
Future<void> delete(String id) async {
  await _collection.doc(id).update({
    'deleted_at': Timestamp.now(),
    'is_available': false,
  });
}

// Pri dohvaćanju filtriraj:
.where('deleted_at', isNull: true)
```

**Status Change (Bookings)** - NE briši, promijeni status:
```dart
Future<void> cancelBooking(String id, String reason) async {
  await _collection.doc(id).update({
    'status': 'cancelled',
    'cancellation_reason': reason,
    'cancelled_at': Timestamp.now(),
  });
}
```

### 3. Riverpod Providers

**Repository Provider:**
```dart
// lib/shared/providers/repository_providers.dart
@riverpod
ExampleRepository exampleRepository(Ref ref) {
  return FirebaseExampleRepository(FirebaseFirestore.instance);
}
```

**Data Provider:**
```dart
// lib/features/.../providers/example_provider.dart
@riverpod
Future<List<ExampleModel>> examples(Ref ref, String ownerId) async {
  final repository = ref.watch(exampleRepositoryProvider);
  return repository.getAll(ownerId);
}

// Stream provider za real-time updates
@riverpod
Stream<List<ExampleModel>> examplesStream(Ref ref, String ownerId) {
  final repository = ref.watch(exampleRepositoryProvider);
  return repository.watchAll(ownerId);
}
```

### 4. Error Handling

```dart
Future<void> _saveData() async {
  setState(() => _isSaving = true);

  try {
    await ref.read(exampleRepositoryProvider).create(model);

    if (mounted) {
      ErrorDisplayUtils.showSuccessSnackBar(
        context,
        'Uspješno sačuvano!',
      );
    }
  } on FirebaseException catch (e) {
    if (mounted) {
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        'Firebase greška: ${e.message}',
      );
    }
  } catch (e) {
    if (mounted) {
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        'Greška: $e',
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

### 5. Optimistic UI Updates & Provider Invalidation

**KRITIČNO:** Uvijek invalidiraj providere NAKON uspješne operacije!

```dart
Future<void> _deleteItem(String id) async {
  // 1. Optimistic UI - ukloni iz lokalnog state-a odmah
  setState(() {
    _items.removeWhere((item) => item.id == id);
  });

  try {
    // 2. Pozovi repository
    await ref.read(exampleRepositoryProvider).delete(id);

    // 3. KRITIČNO: Invalidiraj providere za svježe podatke
    ref.invalidate(examplesProvider);
    ref.invalidate(examplesStreamProvider);

    if (mounted) {
      ErrorDisplayUtils.showSuccessSnackBar(context, 'Obrisano!');
    }
  } catch (e) {
    // 4. Rollback - vrati item ako je greška
    setState(() {
      _items.add(deletedItem);
    });

    if (mounted) {
      ErrorDisplayUtils.showErrorSnackBar(context, 'Greška: $e');
    }
  }
}
```

### 6. Model sa Freezed (fromJson/toJson)

```dart
// lib/features/.../domain/models/example_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String name,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);
}

// Korištenje u repository:
ExampleModel.fromJson({...doc.data(), 'id': doc.id})
```

**Za Timestamp konverziju** koristi custom converter:
```dart
// lib/core/utils/timestamp_converter.dart
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

// U modelu:
@TimestampConverter()
@JsonKey(name: 'created_at')
required DateTime createdAt,
```

### 7. Nested Config Update Pattern

**NIKADA ne koristi konstruktor za nested objekte - koristi .copyWith()!**

```dart
// ❌ LOŠE - gubi postojeće podatke!
final updated = settings.copyWith(
  emailConfig: EmailConfig(requireVerification: true),
);

// ✅ DOBRO - čuva postojeće podatke
final updated = settings.copyWith(
  emailConfig: settings.emailConfig.copyWith(
    requireVerification: true,
  ),
);
```

### 8. Firestore Security Rules Pattern

```javascript
// Provjeri owner_id matches authenticated user
match /examples/{exampleId} {
  allow read: if request.auth != null &&
    resource.data.owner_id == request.auth.uid;
  allow create: if request.auth != null &&
    request.resource.data.owner_id == request.auth.uid;
  allow update, delete: if request.auth != null &&
    resource.data.owner_id == request.auth.uid;
}
```

## File Structure:

```
lib/
├── shared/
│   ├── repositories/
│   │   ├── example_repository.dart          # Interface
│   │   └── firebase/
│   │       └── firebase_example_repository.dart  # Implementation
│   └── providers/
│       └── repository_providers.dart        # Repository providers
└── features/
    └── feature_name/
        ├── domain/
        │   └── models/
        │       └── example_model.dart       # Freezed model
        └── presentation/
            └── providers/
                └── example_provider.dart    # Data providers
```

## Zadatak:

Korisnikov zahtjev: $ARGUMENTS

Kreiraj Firebase CRUD implementaciju koja:
1. Slijedi Repository pattern
2. Ima Riverpod providere
3. Implementira proper error handling
4. Koristi optimistic UI updates sa provider invalidation
5. Ima Freezed model sa fromJson/toJson
6. Koristi odgovarajuću delete strategiju (hard/soft/status change)
