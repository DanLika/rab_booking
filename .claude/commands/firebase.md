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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('examples');

  @override
  Future<List<ExampleModel>> getAll(String ownerId) async {
    final snapshot = await _collection
        .where('owner_id', isEqualTo: ownerId)
        .where('deleted_at', isNull: true)  // Soft delete support
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExampleModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<String> create(ExampleModel model) async {
    final docRef = await _collection.add(model.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> update(ExampleModel model) async {
    await _collection.doc(model.id).update({
      ...model.toFirestore(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> delete(String id) async {
    // Soft delete
    await _collection.doc(id).update({
      'deleted_at': FieldValue.serverTimestamp(),
    });
  }
}
```

### 2. Riverpod Providers

**Repository Provider:**
```dart
// lib/shared/providers/repository_providers.dart
@riverpod
ExampleRepository exampleRepository(ExampleRepositoryRef ref) {
  return FirebaseExampleRepository();
}
```

**Data Provider:**
```dart
// lib/features/.../providers/example_provider.dart
@riverpod
Future<List<ExampleModel>> examples(ExamplesRef ref, String ownerId) async {
  final repository = ref.watch(exampleRepositoryProvider);
  return repository.getAll(ownerId);
}

// Stream provider za real-time updates
@riverpod
Stream<List<ExampleModel>> examplesStream(ExamplesStreamRef ref, String ownerId) {
  final repository = ref.watch(exampleRepositoryProvider);
  return repository.watchAll(ownerId);
}
```

### 3. Error Handling

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

### 4. Optimistic UI Updates & Provider Invalidation

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

### 5. Model sa Firestore Serialization

```dart
// lib/features/.../domain/models/example_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    required String id,
    required String ownerId,
    required String name,
    @Default(false) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ExampleModel;

  factory ExampleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExampleModel(
      id: doc.id,
      ownerId: data['owner_id'] ?? '',
      name: data['name'] ?? '',
      isActive: data['is_active'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      deletedAt: (data['deleted_at'] as Timestamp?)?.toDate(),
    );
  }

  const ExampleModel._();

  Map<String, dynamic> toFirestore() {
    return {
      'owner_id': ownerId,
      'name': name,
      'is_active': isActive,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      if (deletedAt != null) 'deleted_at': Timestamp.fromDate(deletedAt!),
    };
  }
}
```

### 6. Nested Config Update Pattern

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

### 7. Firestore Security Rules Pattern

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
5. Ima Freezed model sa Firestore serialization
