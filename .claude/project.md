# BookBed - Vacation Rental Booking System

## Available VS Code Extensions & Tools

Claude Code can leverage these installed extensions:

### 🔍 Code Quality & Analysis
- **Error Lens** - Errors/warnings shown inline (Claude sees them immediately)
- **GitLens** - Git history, blame, contributors info
- **Dart/Flutter** - Automatic code analysis, formatting, hot reload
- **TODO Tree** - Finds TODO, FIXME, BUG, OPTIMIZE comments

### 🔥 Firebase & Database
- **Firestore Explorer** - Browse Firestore collections directly in IDE
- Service account path configured

### 🎨 Code Helpers
- **Flutter Riverpod Snippets** - Riverpod code generation
- **Awesome Flutter Snippets** - Flutter widget shortcuts
- **Pubspec Assist** - Package search and auto-complete
- **Flutter Tree** - Visual widget tree

### 💡 How Claude Uses These

**Error Detection:**
```
When you edit code, Error Lens shows errors inline
→ Claude can immediately see and fix them
```

**Git History:**
```bash
# Claude can auto-run (no approval needed):
git log --oneline -10
git blame path/to/file.dart
git show commit_hash
```

**TODO Management:**
```dart
// TODO: Implement dark mode toggle
// FIXME: Calendar selection bug on mobile
// OPTIMIZE: Reduce calendar re-renders
// BUG: Booking overlap validation
```

**Flutter Development:**
- Auto format on save (80 char line length)
- Hot reload on save (instant updates)
- Flutter DevTools integration

## Architecture Overview
- **Framework**: Flutter Web with Riverpod state management
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Multi-tenant**: Property owners manage multiple rental units
- **Embeddable Widget**: Calendar widget for property websites

## Key Directories
```
lib/
├── features/
│   ├── widget/           # Embeddable booking widget (calendar, forms)
│   │   ├── presentation/ # UI components (screens, widgets)
│   │   ├── providers/    # State management (Riverpod)
│   │   └── domain/       # Models (DateStatus, CalendarDateInfo)
│   ├── owner/            # Owner dashboard (property management)
│   └── auth/             # Authentication flows
├── core/
│   ├── design_tokens/    # Design system (colors, typography, spacing)
│   └── theme/            # Theme configuration (light/dark modes)
└── shared/               # Shared utilities and providers

## Design System
- **Color Tokens**: MinimalistColors (light), MinimalistColorsDark (dark)
- **Always use**: WidgetColorScheme for theme-aware colors
- **Typography**: TypographyTokens for font sizes and weights
- **Spacing**: SpacingTokens for consistent spacing
- **Borders**: BorderTokens for border radius and width

## Common Commands
```bash
# Run widget on specific port
flutter run -d chrome --web-port=8081

# Run with hot reload
flutter run -d chrome --web-port=8081 --dart-define=FLUTTER_WEB_USE_SKIA=true

# Code analysis
flutter analyze

# Fix formatting
dart format lib/

# Run tests
flutter test
```

## Widget Architecture
1. **Calendar Views**: Month, Year, Week calendars with date selection
2. **Date Statuses**: available, booked, pending, pastReservation, partialCheckIn/Out
3. **Theme System**: Automatic light/dark theme detection via themeProvider
4. **State Management**: Riverpod FutureProvider.family for calendar data

## Common Issues & Solutions
- **Theme colors**: Use `colors.propertyName` (WidgetColorScheme), NOT hardcoded colors
- **Past dates**: Apply 50% opacity to day numbers, use pastReservation status
- **Calendar providers**: month_calendar_provider.dart, year_calendar_provider.dart, week_calendar_provider.dart
- **Custom painting**: split_day_calendar_painter.dart for diagonal check-in/out visuals

## Firebase Structure
- **Collections**: properties, units, bookings, users, widgetSettings
- **Security**: Row-level security based on propertyId ownership

## Testing Widget
1. Open: `http://localhost:PORT/widget?propertyId=X&unitId=Y`
2. For embedded: Use HTML file with iframe
3. Owner app: `http://localhost:PORT/login`

## Known Patterns
- Switch statements MUST handle all DateStatus enum cases
- Use `isPast` calculation: `date.isBefore(todayNormalized)`
- Always use design tokens, never hardcoded values
- Opacity wrapper for past date numbers: `Opacity(opacity: isPast ? 0.5 : 1.0)`
