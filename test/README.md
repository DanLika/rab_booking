# Testing Guide

Comprehensive testing setup for RabBooking app with unit tests, widget tests, and integration tests.

## Test Structure

```
test/
├── unit/              # Unit tests
│   ├── utils/         # Utility function tests
│   ├── exceptions/    # Exception handling tests
│   └── errors/        # Error handler tests
├── widget/            # Widget/UI component tests
├── helpers/           # Test utilities and builders
├── mocks/             # Mock classes
└── flutter_test_config.dart  # Global test configuration

integration_test/      # End-to-end integration tests
```

## Running Tests

### All Tests
```bash
flutter test
```

### Unit Tests Only
```bash
flutter test test/unit/
```

### Widget Tests Only
```bash
flutter test test/widget/
```

### Specific Test File
```bash
flutter test test/unit/utils/result_test.dart
```

### Integration Tests
```bash
flutter test integration_test/
```

### With Coverage
```bash
flutter test --coverage
```

### View Coverage Report (HTML)
```bash
# Install lcov (if not installed)
# macOS: brew install lcov
# Ubuntu/Debian: sudo apt-get install lcov
# Windows: Download from http://ltp.sourceforge.net/coverage/lcov.php

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
# macOS/Linux: open coverage/html/index.html
# Windows: start coverage/html/index.html
```

## Test Categories

### Unit Tests

Testing business logic, models, utilities, and error handling without UI.

**Example:**
```dart
test('should calculate total price correctly', () {
  final result = calculateTotal(nights: 3, pricePerNight: 100);
  expect(result, 300);
});
```

**Covered Areas:**
- ✅ Result pattern (Success/Failure)
- ✅ Exception hierarchy
- ✅ Error handler (user-friendly messages)
- Validators
- Date utilities
- Price calculations
- Business logic

### Widget Tests

Testing UI components in isolation.

**Example:**
```dart
testWidgets('ErrorStateWidget shows retry button', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ErrorStateWidget(
        message: 'Error',
        onRetry: () {},
      ),
    ),
  );

  expect(find.text('Pokušaj ponovo'), findsOneWidget);
});
```

**Covered Areas:**
- ✅ ErrorStateWidget
- Buttons (PrimaryButton, SecondaryButton)
- Input fields
- Cards
- SearchBar
- Property cards
- Calendar components

### Integration Tests

Testing complete user flows end-to-end.

**Example:**
```dart
testWidgets('Complete booking flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Search for property
  await tester.enterText(find.byKey(Key('search_location')), 'Rab');
  await tester.tap(find.text('Search'));
  await tester.pumpAndSettle();

  // Select property
  await tester.tap(find.byType(PropertyCard).first);
  await tester.pumpAndSettle();

  // Complete booking
  // ...
});
```

**Covered Areas:**
- Authentication flow
- Property search → details → booking
- Payment flow
- Owner dashboard operations

## Writing Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureName Tests', () {
    late YourClass instance;

    setUp(() {
      // Setup before each test
      instance = YourClass();
    });

    tearDown(() {
      // Cleanup after each test
    });

    test('should do something', () {
      // Arrange
      final input = 'test';

      // Act
      final result = instance.doSomething(input);

      // Assert
      expect(result, 'expected output');
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('MyWidget Tests', () {
    testWidgets('should display text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MyWidget(text: 'Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
```

### Using Test Helpers

```dart
import '../helpers/test_helpers.dart';
import '../helpers/test_data_builders.dart';

// Build test data
final property = PropertyBuilder()
    .withName('Test Villa')
    .withPrice(150.0)
    .build();

// Or use convenience function
final property = createMockProperty(price: 150.0);

// Pump widget with providers
await pumpWithProviders(
  tester,
  MyWidget(),
  overrides: [
    myProvider.overrideWith((ref) => mockData),
  ],
);
```

## Mocking with Mocktail

```dart
import 'package:mocktail/mocktail.dart';
import '../mocks/mocks.dart';

void main() {
  late MockPropertyRepository mockRepository;

  setUp(() {
    mockRepository = MockPropertyRepository();
  });

  test('should fetch properties', () async {
    // Setup mock behavior
    when(() => mockRepository.fetchProperties())
        .thenAnswer((_) async => Success([property1, property2]));

    // Use mock
    final result = await mockRepository.fetchProperties();

    // Verify
    expect(result.isSuccess, true);
    verify(() => mockRepository.fetchProperties()).called(1);
  });
}
```

## Best Practices

1. **Arrange-Act-Assert Pattern**
   - Arrange: Set up test data
   - Act: Execute the code being tested
   - Assert: Verify the results

2. **Descriptive Test Names**
   ```dart
   // Good
   test('should return Success when API call succeeds', () {});

   // Bad
   test('test1', () {});
   ```

3. **One Assertion Per Test**
   - Focus on testing one thing at a time
   - Makes test failures easier to debug

4. **Use Test Builders**
   ```dart
   final property = PropertyBuilder()
       .withName('Villa')
       .withPrice(200)
       .build();
   ```

5. **Mock External Dependencies**
   - Mock API calls, databases, services
   - Tests should be fast and isolated

6. **Clean Up Resources**
   ```dart
   tearDown(() {
     // Clean up
   });
   ```

7. **Test Edge Cases**
   - Empty lists
   - Null values
   - Error conditions
   - Boundary values

## Code Coverage Goals

- **Target**: 70% or higher
- **Critical paths**: 90%+ coverage
- **UI widgets**: 60%+ coverage

### Check Coverage
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

### Generate HTML Report
```bash
genhtml coverage/lcov.info -o coverage/html
```

## Continuous Integration

Tests automatically run on:
- Pull requests
- Pushes to main/develop branches
- GitHub Actions workflow (`.github/workflows/test.yml`)

## Test Data

Test data builders are available in `test/helpers/test_data_builders.dart`:

- `PropertyBuilder` - Build Property objects
- `BookingBuilder` - Build Booking objects
- `createMockProperty()` - Quick property creation
- `createMockBooking()` - Quick booking creation

## Troubleshooting

### Tests Failing Locally

1. **Clean and rebuild**
   ```bash
   flutter clean
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Update golden files** (if using golden tests)
   ```bash
   flutter test --update-goldens
   ```

3. **Check test dependencies**
   ```bash
   flutter pub outdated
   ```

### Slow Tests

- Use `pumpAndSettle()` sparingly
- Mock expensive operations
- Run specific test files instead of all tests

### Flaky Tests

- Check for timing issues
- Use `pumpAndSettle()` after user interactions
- Ensure proper cleanup in `tearDown()`

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Widget Testing Best Practices](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

## Contributing

When adding new features:
1. Write tests first (TDD approach preferred)
2. Ensure tests pass locally
3. Maintain or improve code coverage
4. Update this README if adding new test utilities

---

**Current Test Coverage:**
- Unit Tests: ✅ Error handling, Result pattern, Exceptions
- Widget Tests: ✅ ErrorStateWidget
- Integration Tests: 🚧 In progress

**Last Updated:** 2025-01-17
