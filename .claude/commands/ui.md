# Flutter UI Agent

Kreiraj Flutter widget prema korisnikovom opisu.

## Obavezni standardi:

### 1. Material 3 Design
- Koristi `Material 3` komponente (FilledButton, OutlinedButton, Card, etc.)
- Poštuj Material Design guidelines za spacing (8px grid)
- Koristi `theme.textTheme.*` za tipografiju

### 2. Riverpod State Management
- Koristi `ConsumerWidget` ili `ConsumerStatefulWidget`
- Definiši providere sa `@riverpod` annotacijom
- Koristi `ref.watch()` za reactive state, `ref.read()` za one-time reads

### 3. Responsive Layout
- Koristi `LayoutBuilder` za responsive breakpoints:
  - Mobile: `< 600px`
  - Tablet: `600px - 1199px`
  - Desktop: `>= 1200px`
- Pattern:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 600;
    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
    final isDesktop = constraints.maxWidth >= 1200;
    // ...
  },
)
```

### 4. Theme-Aware Colors
- NIKADA hardcoded boje!
- Uvijek koristi:
```dart
final theme = Theme.of(context);
theme.colorScheme.primary
theme.colorScheme.secondary
theme.colorScheme.surface
theme.colorScheme.error
theme.cardColor
theme.textTheme.*
```

### 5. Gradient Standard (ako je potreban)
```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    theme.colorScheme.primary,
    theme.colorScheme.primary.withValues(alpha: 0.7),
  ],
)
```

### 6. Input Fields
- Koristi `borderRadius: BorderRadius.circular(12)`
- `filled: true` sa `fillColor: theme.cardColor`

### 7. Spacing
- Koristi `SizedBox` za spacing (ne `Padding` gdje nije potrebno)
- Standard spacing: 8, 12, 16, 24, 32px

## Struktura widgeta:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          // Widget implementation
        );
      },
    );
  }
}
```

## Zadatak:

Korisnikov zahtjev: $ARGUMENTS

Kreiraj Flutter widget koji:
1. Implementira traženu funkcionalnost
2. Poštuje sve navedene standarde
3. Ima jasne komentare za kompleksnu logiku
4. Koristi const konstruktore gdje je moguće
