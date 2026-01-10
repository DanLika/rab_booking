# Core Module

The `lib/core` directory contains the foundational elements of the application. These are singletons, configurations, constants, and utilities that are used across the entire application and are not specific to any single feature.

## Structure

- **accessibility/**: Accessibility helpers and configurations.
- **config/**: Global application configuration (e.g., router, Firebase options).
- **constants/**: Application-wide constants (e.g., API keys, dimensions, enums).
- **design_tokens/**: Design system tokens (colors, typography, spacing).
- **error_handling/**: Global error handling logic.
- **errors/**: Custom error classes.
- **exceptions/**: Custom exception classes.
- **localization/**: Localization (l10n) setup and generated files.
- **providers/**: Global Riverpod providers (e.g., auth, theme).
- **services/**: Singleton services (e.g., Analytics, FCM, Storage).
- **theme/**: Theme definitions and extensions.
- **utils/**: General utility functions and helpers.
- **widgets/**: Core widgets used globally (e.g., app-wide loaders).

## Guidelines

- **Do not import feature-specific code**: Core should never depend on `lib/features`.
- **Keep it light**: Only put things here that are truly global.
- **Document everything**: Public APIs in core must be well-documented as they are used everywhere.
