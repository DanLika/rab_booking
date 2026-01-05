---
description: Refactor and clean up Flutter/Dart code following best practices
---

Clean up and refactor the following Flutter/Dart code to improve readability, maintainability, and follow best practices.

## Code to Clean

$ARGUMENTS

## Cleanup Checklist for Flutter/Dart

### 1. **Code Smells to Fix**

**Naming**
- Descriptive variable/function names
- Use lowerCamelCase for variables and functions
- Use UpperCamelCase for classes and types
- Use lowercase_with_underscores for library/file names
- Boolean names start with is/has/can/should

**Functions & Methods**
- Single responsibility per function
- Keep functions small (< 50 lines)
- Reduce parameters (max 3-4, use object/class if more)
- Extract complex logic into private methods
- Avoid side effects where possible
- Use expression bodies for simple getters: `String get name => _name;`

**DRY (Don't Repeat Yourself)**
- Extract repeated code to utilities
- Create reusable widgets
- Use mixins for shared behavior
- Centralize constants in dedicated files
- Use extension methods for common operations

**Complexity**
- Reduce nested if statements
- Replace complex conditions with well-named functions
- Use early returns (guard clauses)
- Simplify boolean logic
- Use switch expressions (Dart 3.0+)

**Type Safety**
- Remove dynamic types where possible
- Add proper type annotations
- Use sealed classes for finite state types
- Leverage generics for reusable code
- Use pattern matching (Dart 3.0+)

### 2. **Modern Dart Patterns to Apply**

**Null Safety**
- Use null-aware operators: `value ?? defaultValue`
- Use cascade operator: `..method1()..method2()`
- Use collection if/for: `[if (condition) item]`
- Use spread operator: `[...list1, ...list2]`

**Dart 3.0+ Features**
- Records for multiple return values: `(String, int) getData()`
- Pattern matching in switch expressions
- Sealed classes for exhaustive matching
- Class modifiers: final, base, interface, sealed, mixin

**Functional Style**
- Use collection methods: where, map, fold, firstWhere
- Use tear-offs: `list.forEach(print)` instead of `list.forEach((e) => print(e))`
- Prefer immutable data with copyWith patterns

### 3. **Flutter-Specific Cleanup**

**Widget Structure**
- Extract large build methods into smaller widgets
- Use const constructors where possible
- Prefer StatelessWidget when no state needed
- Keep widget tree shallow (extract sub-widgets)

**State Management**
- Move business logic out of widgets
- Use appropriate state solution (Riverpod, Bloc, etc.)
- Avoid setState in favor of state management
- Keep UI and logic separated

**Performance**
- Add const to widget constructors
- Use const for static widgets
- Avoid rebuilding entire trees
- Use keys appropriately for lists

**Theme & Styling**
- Use Theme.of(context) instead of hardcoded values
- Use theme.colorScheme for colors
- Use theme.textTheme for text styles
- Centralize custom theme extensions

### 4. **Common Cleanup Tasks**

**Remove Dead Code**
- Unused imports (dart fix --apply)
- Unreachable code
- Commented out code
- Unused variables and parameters

**Improve Error Handling**
- Use specific exception types
- Handle errors at appropriate levels
- Use Result pattern or Either for expected errors
- Log errors with context

**Consistent Formatting**
- Run dart format
- Run flutter analyze
- Fix all linter warnings
- Organize imports (dart fix --apply)

**Documentation**
- Add doc comments to public APIs (///)
- Remove obvious comments
- Document complex logic with "why" not "what"
- Keep comments up to date

### 5. **Riverpod Specific (if applicable)**

**Providers**
- Use appropriate provider types (Provider, StateProvider, FutureProvider, etc.)
- Keep providers focused and small
- Use family for parameterized providers
- Dispose resources properly

**State**
- Use AsyncValue for loading/error states
- Avoid unnecessary rebuilds with select
- Use ref.invalidate for cache invalidation
- Handle errors gracefully

## Output Format

1. **Issues Found** - List of code smells and problems
2. **Cleaned Code** - Refactored version with changes
3. **Explanations** - What changed and why
4. **Further Improvements** - Optional enhancements

Focus on practical improvements that make code more maintainable without over-engineering. Balance clean code with pragmatism.
