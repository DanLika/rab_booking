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

**NAPOMENA**: Projekt ima dva breakpoint sistema namjerno:
- `ResponsiveSpacingHelper` (za spacing/dialoge): 600 / 1200
- `Breakpoints` class (za layoute): 600 / 1024

**Preporučeni pristup - koristi postojeće klase:**
```dart
import '../../core/constants/breakpoints.dart';

// Za layoute
if (Breakpoints.isMobile(context)) { ... }
if (Breakpoints.isTablet(context)) { ... }
if (Breakpoints.isDesktop(context)) { ... }

// Ili getValue helper
final padding = Breakpoints.getValue(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);
```

**Za spacing/dialoge:**
```dart
import '../../core/utils/responsive_spacing_helper.dart';

final padding = ResponsiveSpacingHelper.getPagePadding(context, density: PageDensity.normal);
final dialogPadding = ResponsiveSpacingHelper.getDialogPadding(context);
```

**LayoutBuilder samo ako treba custom logic:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 600;
    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
    final isDesktop = constraints.maxWidth >= 1024;
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
