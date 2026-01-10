# Shared Module

The `lib/shared` directory contains reusable components, models, and repositories that are shared across multiple features but do not belong in `lib/core`.

## Structure

- **models/**: Shared data models (e.g., `BookingModel`, `PropertyModel`).
- **presentation/**: Shared UI logic (e.g., controllers not tied to a specific feature).
- **providers/**: Shared Riverpod providers.
- **repositories/**: Data access repositories that are used by multiple features.
- **utils/**: Utilities that are specific to shared components.
- **widgets/**: Reusable UI widgets (e.g., Buttons, Cards, Dialogs).

## Guidelines

- **Reusability**: Components here should be designed for reuse.
- **Decoupling**: Avoid coupling with specific features. Use callbacks or generic types where possible.
- **Documentation**: Provide clear documentation and examples for shared widgets.
- **Barrel Files**: Use `widgets.dart` to export common widgets for cleaner imports.
