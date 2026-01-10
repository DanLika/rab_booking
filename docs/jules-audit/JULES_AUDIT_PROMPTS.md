# Jules AI Audit Prompts - V2 (10.01.2026)

Kompaktni promptovi za nove audit provjere. Osnovni auth sistem je implementiran.

**Kako koristiti:**
1. Kopiraj prompt u Jules AI
2. Pričekaj analizu i kreiranje brancha
3. Pregledaj PR

---

# 1. PERFORMANCE AUDIT

## PERF-001: Firestore Query Optimization
```
Analyze Firestore queries for optimization in:
- lib/features/owner_dashboard/presentation/providers/

Check for:
1. Missing composite indexes
2. Unnecessary document reads
3. Missing pagination
4. Queries without proper limits
5. N+1 query patterns
6. Opportunities to use subcollections
7. Expensive orderBy operations without index

Create fixes for any issues found.
Run: dart format . before committing.
```

## PERF-002: Widget Rebuild Optimization
```
Analyze widget rebuilds in:
- lib/features/owner_dashboard/presentation/screens/
- lib/features/calendar/presentation/screens/

Check for:
1. Missing const constructors
2. Expensive builds without caching
3. Missing RepaintBoundary for complex widgets
4. State management causing unnecessary rebuilds
5. Large widget trees that should be broken up
6. Missing ValueListenableBuilder/Selector for granular rebuilds

Create fixes for any issues found.
Run: dart format . before committing.
```

## PERF-003: Image and Asset Optimization
```
Analyze image loading in:
- lib/shared/widgets/
- lib/features/auth/presentation/widgets/profile_image_picker.dart

Check for:
1. Missing image caching
2. Images not resized before upload
3. Missing placeholder/error widgets
4. Large images loaded without compression
5. Missing precacheImage for critical images

Create fixes for any issues found.
Run: dart format . before committing.
```

## PERF-004: Cloud Functions Cold Start
```
Analyze Cloud Functions for cold start issues in:
- functions/src/

Check for:
1. Heavy imports at module level
2. Unnecessary global initializations
3. Functions that should be lazy-loaded
4. Opportunity to split large function files
5. Missing connection pooling for external services

Create fixes for any issues found.
```

---

# 2. SECURITY AUDIT

## SEC-001: Input Sanitization Coverage
```
Analyze input sanitization in:
- lib/features/auth/presentation/screens/
- lib/features/owner_dashboard/presentation/screens/
- functions/src/utils/inputSanitization.ts

Check for:
1. User inputs not sanitized before Firestore writes
2. Missing XSS prevention on text fields
3. SQL/NoSQL injection vectors
4. Missing sanitization on URL parameters
5. File upload validation gaps

Create fixes for any issues found.
Run: dart format . before committing.
```

## SEC-002: API Security
```
Analyze API security in:
- functions/src/

Check for:
1. Missing authentication checks on callable functions
2. Insufficient authorization (user can access others' data)
3. Missing rate limiting on sensitive endpoints
4. Sensitive data in logs (passwords, tokens)
5. Missing CORS configuration issues
6. Unvalidated external API responses

Create fixes for any issues found.
```

## SEC-003: Deep Link Security
```
Analyze deep link handling in:
- lib/core/config/router_owner.dart
- lib/core/services/deep_link_service.dart

Check for:
1. Deep links without authentication validation
2. Redirect URL manipulation vulnerabilities
3. Missing token validation on magic links
4. Unvalidated parameters from deep links
5. Open redirect vulnerabilities

Create fixes for any issues found.
Run: dart format . before committing.
```

## SEC-004: Sensitive Data Handling
```
Analyze sensitive data in:
- lib/core/providers/
- lib/shared/repositories/

Check for:
1. Passwords or tokens in memory longer than needed
2. Sensitive data in SharedPreferences (should use SecureStorage)
3. API keys hardcoded in source
4. Debug prints leaking sensitive data
5. Screenshots not disabled on sensitive screens
6. Missing ProGuard rules for Android

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 3. UI/UX AUDIT

## UX-001: Accessibility Audit
```
Analyze accessibility in:
- lib/features/auth/presentation/
- lib/features/owner_dashboard/presentation/

Check for:
1. Missing Semantics labels on interactive elements
2. Poor color contrast (WCAG AA)
3. Touch targets smaller than 48x48
4. Missing excludeFromSemantics on decorative elements
5. Form error announcements for screen readers
6. Missing focus trap in modals

Create fixes for any issues found.
Run: dart format . before committing.
```

## UX-002: Error State Handling
```
Analyze error handling UX in:
- lib/features/owner_dashboard/presentation/screens/
- lib/shared/widgets/

Check for:
1. Missing error states for failed API calls
2. Generic "Something went wrong" messages without actionable guidance
3. Missing retry functionality on transient errors
4. Errors not properly localized
5. Missing offline state handling
6. Long loading states without skeleton screens

Create fixes for any issues found.
Run: dart format . before committing.
```

## UX-003: Empty States
```
Analyze empty states in:
- lib/features/owner_dashboard/presentation/screens/
- lib/features/calendar/presentation/

Check for:
1. Missing empty state illustrations/text
2. No clear call-to-action in empty states
3. Inconsistent empty state designs
4. Empty state not localized
5. First-time user guidance missing

Create fixes for any issues found.
Run: dart format . before committing.
```

## UX-004: Responsive Design
```
Analyze responsive design in:
- lib/features/owner_dashboard/presentation/screens/
- lib/features/auth/presentation/screens/

Check for:
1. UI broken on small screens (<360px width)
2. UI broken on large screens/tablets
3. Missing landscape orientation support
4. Text overflow issues
5. Images not responsive
6. Navigation drawer vs bottom nav inconsistency

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 4. CODE QUALITY AUDIT

## CODE-001: Dead Code Analysis
```
Analyze for dead code in:
- lib/

Check for:
1. Unused imports
2. Unused variables and methods
3. Unreachable code
4. Deprecated code that should be removed
5. Unused widget files
6. Test files without tests

Remove dead code found.
Run: dart format . before committing.
```

## CODE-002: Duplicate Code
```
Analyze for code duplication in:
- lib/features/

Check for:
1. Duplicated widget code that should be extracted
2. Copy-paste code between screens
3. Similar providers that could be consolidated
4. Repeated validation logic
5. Duplicated API call patterns

Create refactoring for issues found.
Run: dart format . before committing.
```

## CODE-003: Error Handling Patterns
```
Analyze error handling consistency in:
- lib/features/
- lib/shared/repositories/

Check for:
1. Inconsistent try-catch patterns
2. Swallowed exceptions (catch with no handling)
3. Missing error logging
4. Errors that should be rethrown
5. Missing typed exceptions
6. Inconsistent error display (SnackBar vs Dialog)

Create fixes for any issues found.
Run: dart format . before committing.
```

## CODE-004: Naming and Documentation
```
Analyze naming conventions and docs in:
- lib/core/
- lib/shared/

Check for:
1. Inconsistent naming conventions
2. Missing documentation on public APIs
3. Outdated documentation
4. Magic numbers without constants
5. Unclear variable names
6. Missing README files for feature modules

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 5. BOOKING WIDGET AUDIT

## WIDGET-001: Embed Widget Security
```
Analyze widget security in:
- lib/features/widget/
- functions/src/bookingAccessToken.ts

Check for:
1. Widget accessible without valid token
2. Token validation bypass possibilities
3. CORS issues on embedded widget
4. XSS vulnerabilities in widget
5. Cross-origin communication security
6. Rate limiting on widget API calls

Create fixes for any issues found.
Run: dart format . before committing.
```

## WIDGET-002: Widget Performance
```
Analyze widget performance in:
- lib/features/widget/presentation/

Check for:
1. Widget bundle size optimization
2. Lazy loading of non-critical components
3. Animation performance (60fps target)
4. Initial load time optimization
5. Missing tree-shaking opportunities

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 6. PAYMENT AUDIT

## PAY-001: Stripe Payment Security
```
Analyze Stripe integration in:
- functions/src/stripePayment.ts
- functions/src/stripeConnect.ts
- lib/features/payments/

Check for:
1. Payment amounts validated server-side
2. Webhook signature validation
3. Idempotency keys for payment operations
4. Refund authorization checks
5. Payment status synced with booking status
6. Error handling for failed payments

Create fixes for any issues found.
```

## PAY-002: Payment UX
```
Analyze payment UX in:
- lib/features/booking/presentation/
- lib/features/widget/presentation/

Check for:
1. Clear price breakdown display
2. Loading states during payment processing
3. Error messages for declined cards
4. Retry mechanism for failed payments
5. Confirmation before payment
6. Receipt/confirmation display after payment

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 7. LOCALIZATION AUDIT

## L10N-001: Missing Translations
```
Analyze localization coverage in:
- lib/l10n/app_en.arb
- lib/l10n/app_hr.arb
- lib/features/

Check for:
1. Hardcoded strings in Dart files
2. Keys in app_en.arb missing from app_hr.arb
3. Inconsistent placeholder usage
4. Missing pluralization rules
5. Date/time format inconsistencies
6. Currency format issues

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 8. TESTING AUDIT

## TEST-001: Test Coverage Gaps
```
Analyze test coverage in:
- test/
- functions/test/

Check for:
1. Critical auth flows without tests
2. Payment logic without tests
3. Booking state machine without tests
4. Missing edge case tests
5. Integration tests for Cloud Functions
6. Widget tests for key screens

Create tests for gaps found.
Run: flutter test before committing.
```

---

**Total Prompts: 20**
- Performance: 4
- Security: 4
- UI/UX: 4
- Code Quality: 4
- Booking Widget: 2
- Payment: 2
- Localization: 1
- Testing: 1

**Created**: 2026-01-10
**For**: Jules AI (Google Labs)
**Project**: BookBed MVP SaaS Booking
