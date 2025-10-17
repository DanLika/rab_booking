# Testing Guide

Complete guide for testing the Rab Booking application.

## Test Statistics

- **Unit Tests**: 47 tests
- **Widget Tests**: 9 tests
- **Total Tests**: 56 tests ✅
- **Coverage**: >50%

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/utils/result_test.dart

# Run with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Structure

```
test/
├── unit/              # Unit tests
│   ├── utils/         # Utility tests
│   ├── exceptions/    # Exception tests
│   └── errors/        # Error handler tests
├── widget/            # Widget tests
├── helpers/           # Test helpers
│   ├── test_helpers.dart
│   └── test_data_builders.dart
└── mocks/             # Mock objects
    └── mocks.dart
```

## Writing Tests

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/utils/result.dart';

void main() {
  group('Result Tests', () {
    test('should create success result', () {
      const result = Success<int>(42);
      
      expect(result.isSuccess, true);
      expect(result.dataOrNull, 42);
    });
  });
}
```

### Widget Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/shared/widgets/error_state_widget.dart';

void main() {
  testWidgets('should render error message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorStateWidget(message: 'Test error'),
      ),
    );
    
    expect(find.text('Test error'), findsOneWidget);
  });
}
```

## Test Coverage Goals

- **Overall**: >70%
- **Core utils**: >90%
- **Features**: >60%
- **Widgets**: >50%

## CI/CD Integration

Tests run automatically on:
- Pull requests
- Pushes to main/develop
- Manual workflow dispatch

See `.github/workflows/test.yml` for configuration.

## Best Practices

1. **Test Naming**: Use descriptive names
2. **One Assertion**: Test one thing per test
3. **Mock External Dependencies**: Use mocktail
4. **Arrange-Act-Assert**: Follow AAA pattern
5. **Coverage**: Aim for >70% overall

---

For more details, see test/README.md
