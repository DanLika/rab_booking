# Test Agent

Generiši testove za dati kod prema korisnikovom opisu.

## Test Types:

### 1. Unit Tests (Business Logic)

**Lokacija:** `test/unit/`

**Za testiranje:**
- Models (serialization, validation)
- Repositories (mock Firestore)
- Providers (Riverpod state)
- Utils/Helpers (pure functions)

```dart
// test/unit/models/example_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:rab_booking/features/.../domain/models/example_model.dart';

void main() {
  group('ExampleModel', () {
    group('fromFirestore', () {
      test('should parse valid document', () {
        final doc = MockDocumentSnapshot(
          id: 'test-id',
          data: {
            'name': 'Test Name',
            'owner_id': 'owner-123',
            'is_active': true,
          },
        );

        final model = ExampleModel.fromFirestore(doc);

        expect(model.id, 'test-id');
        expect(model.name, 'Test Name');
        expect(model.ownerId, 'owner-123');
        expect(model.isActive, true);
      });

      test('should handle missing fields with defaults', () {
        final doc = MockDocumentSnapshot(
          id: 'test-id',
          data: {'name': 'Test'},
        );

        final model = ExampleModel.fromFirestore(doc);

        expect(model.isActive, false); // default value
      });
    });

    group('toFirestore', () {
      test('should serialize all fields', () {
        final model = ExampleModel(
          id: 'test-id',
          name: 'Test',
          ownerId: 'owner-123',
          isActive: true,
        );

        final data = model.toFirestore();

        expect(data['name'], 'Test');
        expect(data['owner_id'], 'owner-123');
        expect(data['is_active'], true);
      });
    });

    group('copyWith', () {
      test('should create copy with updated field', () {
        final original = ExampleModel(
          id: '1',
          name: 'Original',
          ownerId: 'owner',
        );

        final updated = original.copyWith(name: 'Updated');

        expect(updated.name, 'Updated');
        expect(updated.id, original.id); // unchanged
        expect(updated.ownerId, original.ownerId); // unchanged
      });
    });
  });
}
```

### 2. Widget Tests (UI Components)

**Lokacija:** `test/widget/`

**Za testiranje:**
- Widget rendering
- User interactions (tap, scroll, input)
- State changes
- Theme compliance

```dart
// test/widget/features/example_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rab_booking/features/.../presentation/screens/example_screen.dart';

// Mocks
class MockExampleRepository extends Mock implements ExampleRepository {}

void main() {
  late MockExampleRepository mockRepository;

  setUp(() {
    mockRepository = MockExampleRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        exampleRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: ExampleScreen(),
      ),
    );
  }

  group('ExampleScreen', () {
    testWidgets('should render loading indicator initially', (tester) async {
      when(() => mockRepository.getAll(any()))
          .thenAnswer((_) async => Future.delayed(
                const Duration(seconds: 1),
                () => [],
              ));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should render list when data loaded', (tester) async {
      when(() => mockRepository.getAll(any())).thenAnswer(
        (_) async => [
          ExampleModel(id: '1', name: 'Item 1', ownerId: 'owner'),
          ExampleModel(id: '2', name: 'Item 2', ownerId: 'owner'),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('should show error message on failure', (tester) async {
      when(() => mockRepository.getAll(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Greška'), findsOneWidget);
    });

    testWidgets('should call delete when delete button tapped', (tester) async {
      when(() => mockRepository.getAll(any())).thenAnswer(
        (_) async => [ExampleModel(id: '1', name: 'Item', ownerId: 'owner')],
      );
      when(() => mockRepository.delete(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirm dialog
      await tester.tap(find.text('Obriši'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.delete('1')).called(1);
    });

    testWidgets('should be responsive on mobile', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      when(() => mockRepository.getAll(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify mobile layout
      expect(find.byType(Column), findsWidgets);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('should use theme colors', (tester) async {
      when(() => mockRepository.getAll(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exampleRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
            ),
            home: const ExampleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Widget should use theme colors, not hardcoded
      final container = tester.widget<Container>(find.byType(Container).first);
      // Add assertions based on expected theme usage
    });
  });
}
```

### 3. Integration Tests (Firebase)

**Lokacija:** `test/integration/`

**Za testiranje:**
- Full CRUD flows
- Real Firestore operations (emulator)
- Authentication flows
- Cloud Functions triggers

```dart
// test/integration/repositories/example_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:rab_booking/shared/repositories/firebase/firebase_example_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseExampleRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseExampleRepository(firestore: fakeFirestore);
  });

  group('FirebaseExampleRepository', () {
    group('create', () {
      test('should create document and return id', () async {
        final model = ExampleModel(
          id: '',
          name: 'Test',
          ownerId: 'owner-123',
        );

        final id = await repository.create(model);

        expect(id, isNotEmpty);

        // Verify in Firestore
        final doc = await fakeFirestore.collection('examples').doc(id).get();
        expect(doc.exists, true);
        expect(doc.data()?['name'], 'Test');
      });
    });

    group('getAll', () {
      test('should return all documents for owner', () async {
        // Seed data
        await fakeFirestore.collection('examples').add({
          'name': 'Item 1',
          'owner_id': 'owner-123',
          'deleted_at': null,
        });
        await fakeFirestore.collection('examples').add({
          'name': 'Item 2',
          'owner_id': 'owner-123',
          'deleted_at': null,
        });
        await fakeFirestore.collection('examples').add({
          'name': 'Other Owner',
          'owner_id': 'owner-456',
          'deleted_at': null,
        });

        final results = await repository.getAll('owner-123');

        expect(results.length, 2);
        expect(results.map((e) => e.name), containsAll(['Item 1', 'Item 2']));
      });

      test('should exclude soft-deleted documents', () async {
        await fakeFirestore.collection('examples').add({
          'name': 'Active',
          'owner_id': 'owner-123',
          'deleted_at': null,
        });
        await fakeFirestore.collection('examples').add({
          'name': 'Deleted',
          'owner_id': 'owner-123',
          'deleted_at': Timestamp.now(),
        });

        final results = await repository.getAll('owner-123');

        expect(results.length, 1);
        expect(results.first.name, 'Active');
      });
    });

    group('update', () {
      test('should update document fields', () async {
        final docRef = await fakeFirestore.collection('examples').add({
          'name': 'Original',
          'owner_id': 'owner-123',
        });

        final model = ExampleModel(
          id: docRef.id,
          name: 'Updated',
          ownerId: 'owner-123',
        );

        await repository.update(model);

        final doc = await docRef.get();
        expect(doc.data()?['name'], 'Updated');
        expect(doc.data()?['updated_at'], isNotNull);
      });
    });

    group('delete', () {
      test('should soft delete by setting deleted_at', () async {
        final docRef = await fakeFirestore.collection('examples').add({
          'name': 'To Delete',
          'owner_id': 'owner-123',
          'deleted_at': null,
        });

        await repository.delete(docRef.id);

        final doc = await docRef.get();
        expect(doc.data()?['deleted_at'], isNotNull);
      });
    });

    group('watchAll', () {
      test('should emit updates when data changes', () async {
        final stream = repository.watchAll('owner-123');

        // Initial empty
        expectLater(
          stream,
          emitsInOrder([
            [], // Initial empty
            hasLength(1), // After add
          ]),
        );

        // Add document
        await fakeFirestore.collection('examples').add({
          'name': 'New Item',
          'owner_id': 'owner-123',
          'deleted_at': null,
        });
      });
    });
  });
}
```

### 4. Provider Tests (Riverpod)

```dart
// test/unit/providers/example_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockExampleRepository extends Mock implements ExampleRepository {}

void main() {
  late MockExampleRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockExampleRepository();
    container = ProviderContainer(
      overrides: [
        exampleRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('examplesProvider', () {
    test('should fetch data from repository', () async {
      when(() => mockRepository.getAll('owner-123')).thenAnswer(
        (_) async => [
          ExampleModel(id: '1', name: 'Test', ownerId: 'owner-123'),
        ],
      );

      final result = await container.read(
        examplesProvider('owner-123').future,
      );

      expect(result.length, 1);
      expect(result.first.name, 'Test');
      verify(() => mockRepository.getAll('owner-123')).called(1);
    });

    test('should invalidate and refetch after mutation', () async {
      when(() => mockRepository.getAll('owner-123'))
          .thenAnswer((_) async => []);

      // Initial fetch
      await container.read(examplesProvider('owner-123').future);

      // Invalidate
      container.invalidate(examplesProvider('owner-123'));

      // Should fetch again
      await container.read(examplesProvider('owner-123').future);

      verify(() => mockRepository.getAll('owner-123')).called(2);
    });
  });
}
```

## Test Dependencies (pubspec.yaml):

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  fake_cloud_firestore: ^2.4.0
  firebase_auth_mocks: ^0.12.0
  integration_test:
    sdk: flutter
```

## File Structure:

```
test/
├── unit/
│   ├── models/
│   │   └── example_model_test.dart
│   ├── repositories/
│   │   └── example_repository_test.dart
│   └── providers/
│       └── example_provider_test.dart
├── widget/
│   └── features/
│       └── example_screen_test.dart
├── integration/
│   └── repositories/
│       └── firebase_example_repository_test.dart
└── helpers/
    ├── mocks.dart
    └── test_helpers.dart
```

## Running Tests:

```bash
# All tests
flutter test

# Specific file
flutter test test/unit/models/example_model_test.dart

# With coverage
flutter test --coverage

# Integration tests (requires emulator)
flutter test test/integration/
```

## Zadatak:

Korisnikov zahtjev: $ARGUMENTS

Generiši testove koji:
1. Pokrivaju happy path i edge cases
2. Koriste mocktail za mocking
3. Testiraju sve CRUD operacije
4. Verificiraju theme compliance za widget tests
5. Koriste fake_cloud_firestore za Firebase tests
