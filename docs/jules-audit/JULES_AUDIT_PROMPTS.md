# Jules AI Audit Prompts

Ovaj dokument sadrži 6 kompleta mikro promptova za detaljnu analizu BookBed projekta.

**Kako koristiti:**
1. Kopiraj prompt u Jules AI
2. Pričekaj analizu i kreiranje brancha
3. Pregledaj rezultate
4. Ponovi za sljedeći prompt

**Kompleti:**
1. [SECURITY](#1-security-prompts) - Sigurnosna analiza
2. [UI/UX](#2-uiux-prompts) - Vizualni i interakcijski problemi
3. [PERFORMANCE](#3-performance-prompts) - Optimizacije
4. [LOGIC](#4-logic-prompts) - Business logika i edge cases
5. [DEAD CODE](#5-dead-code-prompts) - Nekorišteni kod
6. [DOCUMENTATION](#6-documentation-prompts) - Zastarjela dokumentacija

---

# 1. SECURITY PROMPTS

## SEC-001: Authentication Security
```
Analyze authentication security in the following files:
- lib/core/providers/enhanced_auth_provider.dart
- lib/core/services/secure_storage_service.dart
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/models/saved_credentials.dart

Check for:
1. Insecure credential storage (passwords in plaintext)
2. Missing rate limiting on login attempts
3. Session token handling vulnerabilities
4. Remember me functionality security
5. Password reset flow vulnerabilities
6. Missing input validation before Firebase calls
7. Exposed sensitive data in error messages

Create fixes for any issues found.
```

## SEC-002: Password Validation Security
```
Analyze password validation in:
- lib/core/utils/password_validator.dart
- lib/features/owner_dashboard/presentation/screens/change_password_screen.dart

Check for:
1. Weak password requirements
2. Missing sequential character detection (abc, 123)
3. Missing common password blacklist
4. Password history not enforced
5. Missing password strength indicator accuracy
6. Timing attacks in validation

Create fixes for any issues found.
```

## SEC-003: Cloud Functions Authentication
```
Analyze Cloud Functions authentication in:
- functions/src/atomicBooking.ts
- functions/src/stripePayment.ts
- functions/src/stripeConnect.ts
- functions/src/emailVerification.ts
- functions/src/ownerNotifications.ts

Check for:
1. Missing authentication checks (context.auth)
2. Insufficient authorization (user can only access own data)
3. Missing input validation
4. SQL/NoSQL injection vulnerabilities
5. Rate limiting bypass
6. Privilege escalation possibilities

Create fixes for any issues found.
```

## SEC-004: Input Sanitization
```
Analyze input sanitization in:
- functions/src/utils/inputSanitization.ts
- lib/features/widget/domain/use_cases/submit_booking_use_case.dart
- lib/features/owner_dashboard/presentation/widgets/send_email_dialog.dart
- lib/shared/utils/validators/input_validators.dart

Check for:
1. XSS vulnerabilities (HTML/script injection)
2. Missing email sanitization
3. Missing phone number sanitization
4. SQL/NoSQL injection in search fields
5. Path traversal in file operations
6. Unicode normalization attacks

Create fixes for any issues found.
```

## SEC-005: SSRF and URL Validation
```
Analyze URL handling in:
- functions/src/icalSync.ts
- lib/core/services/ical_export_service.dart
- lib/features/owner_dashboard/presentation/screens/ical/ical_sync_screen.dart

Check for:
1. SSRF vulnerabilities (Server-Side Request Forgery)
2. Missing URL whitelist validation
3. Internal IP address access (localhost, 10.x, 192.168.x)
4. DNS rebinding attacks
5. Protocol smuggling (file://, gopher://)
6. Redirect following vulnerabilities

Create fixes for any issues found.
```

## SEC-006: Firestore Security Rules
```
Analyze Firestore security in:
- firestore.rules
- storage.rules
- lib/shared/repositories/firebase/firebase_repository_base.dart

Check for:
1. Overly permissive read/write rules
2. Missing owner validation
3. Data leakage between users
4. Missing field-level security
5. Unauthenticated access to sensitive data
6. Collection group query vulnerabilities

Create fixes for any issues found.
```

## SEC-007: Stripe Payment Security
```
Analyze Stripe integration security in:
- functions/src/stripePayment.ts
- functions/src/stripeConnect.ts
- functions/src/handleStripeWebhook.ts
- lib/core/services/stripe_service.dart
- lib/features/widget/presentation/widgets/booking/payment/stripe_payment_section.dart

Check for:
1. Webhook signature verification
2. Price manipulation vulnerabilities
3. Missing idempotency keys
4. Race conditions in payment processing
5. Sensitive data exposure in logs
6. Missing Stripe Connect account verification

Create fixes for any issues found.
```

## SEC-008: PII Data Protection
```
Analyze PII (Personally Identifiable Information) handling in:
- lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart
- lib/features/owner_dashboard/presentation/widgets/bookings/booking_card/booking_card_guest_info.dart
- lib/shared/models/booking_model.dart
- functions/src/email/templates/*.ts

Check for:
1. PII exposure in public APIs
2. Missing data masking in logs
3. PII in error messages
4. Unencrypted PII storage
5. PII in URL parameters
6. Missing GDPR compliance (data deletion)

Create fixes for any issues found.
```

## SEC-009: API Key and Secret Management
```
Analyze secret management in:
- functions/src/config/firebaseConfig.ts
- functions/src/sentry.ts
- lib/firebase_options.dart
- lib/firebase_options_dev.dart
- lib/firebase_options_staging.dart
- .env.development
- .env.staging
- .env.production
- functions/.gitignore

Check for:
1. Hardcoded API keys
2. Secrets in version control
3. Missing .gitignore entries for sensitive files
4. Environment variable exposure
5. Service account key exposure
6. Missing secret rotation

Create fixes for any issues found.
```

## SEC-010: Error Handling Security
```
Analyze error handling in:
- lib/core/utils/error_display_utils.dart
- lib/core/errors/error_handler.dart
- lib/features/widget/presentation/providers/widget_context_provider.dart
- functions/src/logger.ts

Check for:
1. Stack traces exposed to users
2. Internal paths in error messages
3. Database query details in errors
4. Sensitive configuration in errors
5. Missing error sanitization
6. Verbose error modes in production

Create fixes for any issues found.
```

## SEC-011: Session and Token Security
```
Analyze session management in:
- lib/core/providers/enhanced_auth_provider.dart
- lib/core/services/tab_communication_service.dart
- lib/core/services/tab_communication_service_web.dart
- functions/src/emailVerification.ts

Check for:
1. Token expiration not enforced
2. Missing token refresh logic
3. Cross-tab session synchronization issues
4. Session fixation vulnerabilities
5. Missing logout cleanup
6. Token storage in localStorage vs sessionStorage

Create fixes for any issues found.
```

## SEC-012: File Upload Security
```
Analyze file handling in:
- storage.rules
- lib/shared/repositories/firebase/firebase_storage_repository.dart
- functions/src/utils/imageProcessing.ts (if exists)

Check for:
1. Missing file type validation
2. Missing file size limits
3. Path traversal in file names
4. Executable file upload
5. Missing virus scanning
6. Public URL exposure

Create fixes for any issues found.
```



## SEC-013: Rate Limiting
```
Analyze rate limiting in:
- functions/src/utils/rateLimit.ts
- functions/src/atomicBooking.ts
- functions/src/stripePayment.ts
- lib/core/services/rate_limit_service.dart

Check for:
1. Missing rate limits on critical endpoints
2. Bypassable rate limiting (IP spoofing)
3. Inconsistent rate limit enforcement
4. Missing rate limit on password reset
5. Missing rate limit on email sending
6. DoS vulnerabilities

Create fixes for any issues found.
```

## SEC-014: Booking Security
```
Analyze booking security in:
- functions/src/atomicBooking.ts
- lib/features/widget/domain/use_cases/submit_booking_use_case.dart
- lib/features/widget/domain/use_cases/check_availability_use_case.dart
- lib/features/owner_dashboard/presentation/widgets/booking_create_dialog.dart

Check for:
1. Double booking race conditions
2. Price manipulation
3. Date manipulation (past dates)
4. Owner ID spoofing
5. Booking status manipulation
6. Missing transaction isolation

Create fixes for any issues found.
```

## SEC-015: Email Security
```
Analyze email security in:
- functions/src/emailService.ts
- functions/src/email/templates/*.ts
- lib/core/services/email_notification_service.dart

Check for:
1. Email header injection
2. HTML injection in email body
3. Missing email verification
4. Spoofable sender address
5. Sensitive data in email links
6. Missing link expiration

Create fixes for any issues found.
```

---

# 2. UI/UX PROMPTS

## UX-001: Login/Register Screens
```
Analyze UI/UX in authentication screens:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/features/auth/presentation/widgets/*.dart

Check for:
1. Missing loading states during async operations
2. Unclear error messages
3. Missing form validation feedback
4. Inaccessible elements (missing semantics)
5. Poor keyboard navigation
6. Missing haptic feedback
7. Inconsistent button states
8. Missing password visibility toggle tooltip

Create fixes for any issues found.
```

## UX-002: Owner Dashboard Navigation
```
Analyze navigation UX in:
- lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart
- lib/features/owner_dashboard/presentation/widgets/owner_bottom_nav.dart
- lib/core/config/router_owner.dart

Check for:
1. Inconsistent navigation patterns
2. Missing back button handling
3. Deep link handling issues
4. Missing breadcrumbs
5. Confusing menu structure
6. Missing active state indicators
7. Poor mobile navigation

Create fixes for any issues found.
```

## UX-003: Calendar Widget UX
```
Analyze calendar UX in:
- lib/features/widget/presentation/widgets/calendar/month_calendar_widget.dart
- lib/features/widget/presentation/widgets/calendar/year_calendar_widget.dart
- lib/features/widget/presentation/widgets/calendar/calendar_legend.dart

Check for:
1. Unclear date selection feedback
2. Missing loading skeletons
3. Poor color contrast for accessibility
4. Missing keyboard navigation
5. Unclear availability indicators
6. Missing touch feedback on mobile
7. Confusing turnover day display

Create fixes for any issues found.
```

## UX-004: Timeline Calendar UX
```
Analyze timeline calendar UX in:
- lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart
- lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart
- lib/features/owner_dashboard/presentation/widgets/calendar/calendar_top_toolbar.dart

Check for:
1. Scroll performance issues
2. Missing date range indicators
3. Unclear booking block colors
4. Poor touch targets on mobile
5. Missing keyboard shortcuts feedback
6. Confusing multi-select mode
7. Missing conflict indicators

Create fixes for any issues found.
```

## UX-005: Booking Form UX
```
Analyze booking form UX in:
- lib/features/widget/presentation/screens/booking_widget_screen.dart
- lib/features/widget/presentation/widgets/booking/guest_form/*.dart
- lib/features/widget/presentation/widgets/booking/payment/*.dart

Check for:
1. Missing step progress indicator
2. Unclear required field indicators
3. Poor form validation timing
4. Missing autofill support
5. Confusing payment options
6. Missing price breakdown clarity
7. Poor mobile keyboard handling

Create fixes for any issues found.
```

## UX-006: Booking Confirmation UX
```
Analyze confirmation UX in:
- lib/features/widget/presentation/screens/booking_confirmation_screen.dart
- lib/features/widget/presentation/widgets/confirmation/*.dart
- lib/features/widget/presentation/screens/booking_details_screen.dart

Check for:
1. Missing success animation
2. Unclear next steps
3. Missing print/share options
4. Poor bank transfer instructions
5. Missing booking reference copy button
6. Confusing status indicators
7. Missing email confirmation notice

Create fixes for any issues found.
```

## UX-007: Settings Screens UX
```
Analyze settings UX in:
- lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart
- lib/features/owner_dashboard/presentation/screens/notification_settings_screen.dart
- lib/features/owner_dashboard/presentation/screens/bank_account_screen.dart

Check for:
1. Missing save confirmation
2. Unclear toggle states
3. Missing unsaved changes warning
4. Poor section organization
5. Missing help tooltips
6. Confusing nested settings
7. Missing preview functionality

Create fixes for any issues found.
```

## UX-008: Booking List/Table UX
```
Analyze booking list UX in:
- lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart
- lib/features/owner_dashboard/presentation/widgets/bookings/*.dart
- lib/features/owner_dashboard/presentation/widgets/bookings/booking_card/*.dart

Check for:
1. Missing sort indicators
2. Poor filter UX
3. Missing bulk actions
4. Unclear status badges
5. Poor empty state messaging
6. Missing pagination feedback
7. Confusing date formats

Create fixes for any issues found.
```

## UX-009: Dialog and Modal UX
```
Analyze dialog UX in:
- lib/features/owner_dashboard/presentation/widgets/booking_details_dialog.dart
- lib/features/owner_dashboard/presentation/widgets/booking_create_dialog.dart
- lib/features/owner_dashboard/presentation/widgets/dialogs/*.dart
- lib/features/owner_dashboard/presentation/widgets/send_email_dialog.dart

Check for:
1. Missing close button
2. Poor mobile responsiveness
3. Missing keyboard dismiss
4. Unclear action buttons
5. Missing loading states
6. Poor scroll behavior
7. Missing backdrop dismiss option

Create fixes for any issues found.
```

## UX-010: Error States UX
```
Analyze error state UX in:
- lib/core/error_handling/error_boundary.dart
- lib/core/utils/error_display_utils.dart
- lib/shared/widgets/animations/animated_empty_state.dart

Check for:
1. Generic error messages
2. Missing retry buttons
3. Poor error illustrations
4. Missing error context
5. No offline state handling
6. Missing error reporting option
7. Confusing technical errors

Create fixes for any issues found.
```

## UX-011: Loading States UX
```
Analyze loading states in:
- lib/shared/widgets/loaders/owner_app_loader.dart
- lib/shared/widgets/loaders/bookbed_loader.dart
- lib/features/widget/presentation/widgets/calendar/month_calendar_skeleton.dart
- lib/features/widget/presentation/widgets/calendar/year_calendar_skeleton.dart

Check for:
1. Missing skeleton loaders
2. Inconsistent loading indicators
3. No progress indication for long operations
4. Missing loading state for buttons
5. Poor shimmer animation
6. No timeout handling
7. Missing cancel option for long loads

Create fixes for any issues found.
```

## UX-012: Responsive Design UX
```
Analyze responsive design in:
- lib/core/utils/responsive_builder.dart
- lib/core/utils/responsive_spacing_helper.dart
- lib/core/constants/breakpoints.dart
- lib/shared/widgets/responsive/*.dart

Check for:
1. Broken layouts on tablet
2. Poor mobile adaptation
3. Missing landscape handling
4. Inconsistent spacing
5. Text overflow issues
6. Touch target size issues
7. Missing responsive images

Create fixes for any issues found.
```

## UX-013: Accessibility (a11y)
```
Analyze accessibility in:
- lib/core/accessibility/accessibility_helpers.dart
- lib/features/widget/presentation/widgets/calendar/*.dart
- lib/features/auth/presentation/screens/*.dart

Check for:
1. Missing semantic labels
2. Poor color contrast (WCAG AA)
3. Missing focus indicators
4. No screen reader support
5. Missing alt text for images
6. Poor heading hierarchy
7. Missing ARIA labels equivalent

Create fixes for any issues found.
```

## UX-014: Form Input UX
```
Analyze form inputs in:
- lib/core/utils/input_decoration_helper.dart
- lib/features/auth/presentation/widgets/premium_input_field.dart
- lib/shared/widgets/debounced_search_field.dart

Check for:
1. Missing input masks (phone, date)
2. Poor autofill attributes
3. Missing character counters
4. Unclear validation messages
5. Poor disabled state styling
6. Missing clear button
7. Inconsistent input heights

Create fixes for any issues found.
```



---

# 3. PERFORMANCE PROMPTS

## PERF-001: Widget Rebuild Optimization
```
Analyze widget rebuilds in:
- lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart
- lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart
- lib/features/widget/presentation/widgets/calendar/month_calendar_widget.dart
- lib/features/widget/presentation/widgets/calendar/year_calendar_widget.dart

Check for:
1. Unnecessary setState calls
2. Missing const constructors
3. Missing ValueNotifier for local state
4. Rebuilding entire lists instead of items
5. Missing RepaintBoundary for complex widgets
6. Provider watching too much data
7. Missing memoization

Create fixes using ValueNotifier/ValueListenableBuilder pattern where appropriate.
```

## PERF-002: Firestore Query Optimization
```
Analyze Firestore queries in:
- lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart
- lib/shared/repositories/firebase/firebase_booking_repository.dart
- lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart
- lib/shared/providers/repository_providers.dart

Check for:
1. Missing query limits
2. Fetching unnecessary fields
3. Missing composite indexes
4. N+1 query problems
5. Missing pagination
6. Redundant queries
7. Missing query caching

Create fixes for any issues found.
```

## PERF-003: Stream and Provider Optimization
```
Analyze streams and providers in:
- lib/features/owner_dashboard/presentation/providers/*.dart
- lib/features/widget/presentation/providers/*.dart
- lib/shared/providers/*.dart

Check for:
1. Streams not being disposed
2. Missing autoDispose on providers
3. Unnecessary provider rebuilds
4. Missing select() for partial data
5. Duplicate stream subscriptions
6. Missing debounce on frequent updates
7. Memory leaks from undisposed listeners

Create fixes for any issues found.
```

## PERF-004: Image and Asset Optimization
```
Analyze image handling in:
- lib/features/owner_dashboard/presentation/widgets/property_image_gallery.dart
- lib/shared/repositories/firebase/firebase_storage_repository.dart
- assets/

Check for:
1. Missing image caching
2. Large unoptimized images
3. Missing lazy loading
4. No placeholder images
5. Missing image compression
6. Unused assets
7. Missing WebP format

Create fixes for any issues found.
```

## PERF-005: List and Grid Performance
```
Analyze list performance in:
- lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart
- lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart
- lib/features/widget/presentation/widgets/calendar/year_calendar_widget.dart

Check for:
1. Missing ListView.builder
2. Missing itemExtent for fixed height items
3. Missing cacheExtent optimization
4. Heavy itemBuilder computations
5. Missing keys for list items
6. Unnecessary list rebuilds
7. Missing virtualization

Create fixes for any issues found.
```

## PERF-006: Animation Performance
```
Analyze animations in:
- lib/core/theme/app_animations.dart
- lib/shared/widgets/animations/*.dart
- lib/features/auth/presentation/widgets/auth_logo_icon.dart
- lib/core/utils/flutter_animate_extensions.dart

Check for:
1. Animations not using GPU (missing Transform)
2. Missing AnimationController disposal
3. Heavy animations on main thread
4. Missing animation caching
5. Unnecessary animation rebuilds
6. Poor animation curves
7. Missing reduced motion support

Create fixes for any issues found.
```

## PERF-007: Cloud Functions Performance
```
Analyze Cloud Functions performance in:
- functions/src/atomicBooking.ts
- functions/src/icalSync.ts
- functions/src/scheduledTasks.ts
- functions/src/emailService.ts

Check for:
1. Cold start optimization (lazy imports)
2. Missing connection pooling
3. Unnecessary Firestore reads
4. Missing batch operations
5. Synchronous operations that could be async
6. Missing timeout handling
7. Memory leaks in long-running functions

Create fixes for any issues found.
```

## PERF-008: Bundle Size Optimization
```
Analyze bundle size in:
- pubspec.yaml
- lib/main.dart
- lib/widget_main.dart

Check for:
1. Unused dependencies
2. Heavy dependencies that could be replaced
3. Missing tree shaking
4. Duplicate code across entry points
5. Missing code splitting
6. Large asset files
7. Debug code in production

Create fixes for any issues found.
```

## PERF-009: Network Optimization
```
Analyze network usage in:
- lib/core/services/*.dart
- lib/features/widget/data/repositories/*.dart
- functions/src/*.ts

Check for:
1. Missing request caching
2. Redundant API calls
3. Missing request batching
4. Large payload sizes
5. Missing compression
6. No offline support
7. Missing retry with backoff

Create fixes for any issues found.
```

## PERF-010: Memory Management
```
Analyze memory usage in:
- lib/features/owner_dashboard/presentation/screens/*.dart
- lib/features/widget/presentation/screens/*.dart
- lib/core/services/*.dart

Check for:
1. Missing dispose() implementations
2. Retained references preventing GC
3. Large objects in memory
4. Missing weak references
5. Image memory not released
6. Stream subscriptions not cancelled
7. Timer not cancelled

Create fixes for any issues found.
```

## PERF-011: Startup Performance
```
Analyze app startup in:
- lib/main.dart
- lib/widget_main.dart
- lib/core/providers/*.dart
- lib/app.dart

Check for:
1. Heavy initialization on main thread
2. Blocking async operations
3. Unnecessary eager loading
4. Missing splash screen optimization
5. Heavy provider initialization
6. Synchronous file I/O
7. Missing deferred loading

Create fixes for any issues found.
```

## PERF-012: Calendar Rendering Performance
```
Analyze calendar rendering in:
- lib/features/widget/presentation/widgets/calendar/month_calendar_widget.dart
- lib/features/widget/presentation/widgets/calendar/year_calendar_widget.dart
- lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart
- lib/features/owner_dashboard/utils/calendar_grid_calculator.dart

Check for:
1. Expensive date calculations on every build
2. Missing date caching
3. Unnecessary calendar rebuilds
4. Heavy cell rendering
5. Missing virtualization for year view
6. Redundant availability checks
7. Missing shouldRebuild optimization

Create fixes for any issues found.
```

---

# 4. LOGIC PROMPTS

## LOGIC-001: Booking Flow Consistency
```
Analyze booking flow logic in:
- lib/features/widget/domain/use_cases/submit_booking_use_case.dart
- lib/features/widget/domain/use_cases/check_availability_use_case.dart
- functions/src/atomicBooking.ts
- lib/features/widget/presentation/providers/booking_flow_provider.dart

Check for:
1. Inconsistent availability checking (widget vs backend)
2. Race conditions in booking creation
3. Missing edge cases (same-day booking, minimum stay)
4. Price calculation mismatches
5. Status transition inconsistencies
6. Missing rollback on failure
7. Timezone handling issues

Create fixes for any issues found.
```

## LOGIC-002: Payment Flow Consistency
```
Analyze payment flow logic in:
- lib/features/widget/presentation/widgets/booking/payment/*.dart
- functions/src/stripePayment.ts
- functions/src/handleStripeWebhook.ts
- lib/core/services/stripe_service.dart

Check for:
1. Payment status not synced with booking status
2. Missing webhook event handling
3. Partial payment edge cases
4. Currency conversion issues
5. Refund logic inconsistencies
6. Deposit calculation errors
7. Missing payment timeout handling

Create fixes for any issues found.
```

## LOGIC-003: Calendar Data Consistency
```
Analyze calendar data logic in:
- lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart
- lib/features/owner_dashboard/presentation/providers/owner_calendar_provider.dart
- lib/features/widget/domain/models/date_status.dart

Check for:
1. Booking status not reflected in calendar
2. iCal sync not updating calendar
3. Turnover day calculation errors
4. Overlapping booking display issues
5. Timezone conversion errors
6. Cache invalidation issues
7. Real-time update inconsistencies

Create fixes for any issues found.
```

## LOGIC-004: Settings Propagation
```
Analyze settings propagation in:
- lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart
- lib/features/widget/domain/models/settings/*.dart
- lib/features/widget/presentation/providers/widget_settings_provider.dart

Check for:
1. Widget settings not applied to widget
2. Payment settings not reflected in checkout
3. Email settings not used in notifications
4. Calendar settings inconsistencies
5. Missing settings validation
6. Default values not applied
7. Settings not persisted correctly

Create fixes for any issues found.
```

## LOGIC-005: Notification Logic
```
Analyze notification logic in:
- functions/src/ownerNotifications.ts
- functions/src/emailService.ts
- lib/features/owner_dashboard/presentation/providers/notifications_provider.dart
- lib/core/services/notification_service.dart

Check for:
1. Notifications not sent for all booking events
2. Duplicate notifications
3. Missing notification preferences check
4. Email template variable mismatches
5. Notification timing issues
6. Missing notification for cancellations
7. Push notification not synced with email

Create fixes for any issues found.
```

## LOGIC-006: iCal Sync Logic
```
Analyze iCal sync logic in:
- functions/src/icalSync.ts
- lib/features/owner_dashboard/presentation/screens/ical/ical_sync_screen.dart
- lib/core/services/ical_export_service.dart

Check for:
1. iCal events not blocking calendar
2. Sync conflicts not resolved
3. Deleted external bookings not removed
4. Timezone conversion errors
5. Recurring event handling
6. Sync frequency issues
7. Error recovery logic

Create fixes for any issues found.
```

## LOGIC-007: Pricing Logic
```
Analyze pricing logic in:
- lib/features/widget/domain/use_cases/calculate_price_use_case.dart
- lib/features/widget/data/repositories/firebase_pricing_repository.dart
- functions/src/atomicBooking.ts (price validation)

Check for:
1. Daily price not applied correctly
2. Seasonal pricing conflicts
3. Minimum stay pricing issues
4. Cleaning fee calculation
5. Tax calculation errors
6. Discount application order
7. Price rounding inconsistencies

Create fixes for any issues found.
```

## LOGIC-008: User Role and Permission Logic
```
Analyze permission logic in:
- lib/core/providers/enhanced_auth_provider.dart
- firestore.rules
- functions/src/*.ts (authorization checks)

Check for:
1. Owner can access other owner's data
2. Guest can modify bookings
3. Missing role validation
4. Permission bypass possibilities
5. Inconsistent permission checks
6. Missing audit logging
7. Role escalation vulnerabilities

Create fixes for any issues found.
```

## LOGIC-009: Date and Time Logic
```
Analyze date/time handling in:
- lib/core/utils/date_time_parser.dart
- lib/core/utils/timestamp_converter.dart
- lib/features/widget/domain/models/date_status.dart
- functions/src/utils/*.ts

Check for:
1. Timezone inconsistencies (UTC vs local)
2. DST (Daylight Saving Time) handling
3. Date boundary issues (check-in/check-out)
4. Date format inconsistencies
5. Past date validation
6. Future date limits
7. Date range calculation errors

Create fixes for any issues found.
```

## LOGIC-010: State Management Logic
```
Analyze state management in:
- lib/features/widget/state/*.dart
- lib/features/owner_dashboard/presentation/state/*.dart
- lib/features/owner_dashboard/presentation/providers/*.dart

Check for:
1. State not reset on logout
2. Stale state after navigation
3. Missing loading states
4. Error state not cleared
5. Optimistic updates not rolled back
6. State persistence issues
7. Cross-screen state sync

Create fixes for any issues found.
```

## LOGIC-011: Validation Logic Consistency
```
Analyze validation in:
- lib/shared/utils/validators/*.dart
- lib/features/widget/domain/use_cases/submit_booking_use_case.dart
- functions/src/utils/inputSanitization.ts

Check for:
1. Client validation differs from server
2. Missing validation on some fields
3. Validation bypass possibilities
4. Inconsistent error messages
5. Missing length limits
6. Format validation gaps
7. Required field inconsistencies

Create fixes for any issues found.
```

## LOGIC-012: Error Recovery Logic
```
Analyze error recovery in:
- lib/core/utils/async_utils.dart
- lib/core/errors/error_handler.dart
- functions/src/logger.ts

Check for:
1. Missing retry logic
2. No graceful degradation
3. Error state stuck
4. Missing rollback on partial failure
5. No offline queue
6. Missing error boundaries
7. Unhandled promise rejections

Create fixes for any issues found.
```



---

# 5. DEAD CODE PROMPTS

## DEAD-001: Unused Imports Analysis
```
Analyze unused imports in ALL Dart files under:
- lib/

For each file, check for:
1. Imported packages never used
2. Imported files never referenced
3. Conditional imports that are always one branch
4. Duplicate imports
5. Imports only used in comments

List all unused imports and create fixes to remove them.
Run: dart analyze to verify no new errors after removal.
```

## DEAD-002: Unused Functions and Methods
```
Analyze unused functions in:
- lib/core/utils/*.dart
- lib/core/services/*.dart
- lib/shared/utils/*.dart
- functions/src/utils/*.ts

Check for:
1. Public functions never called
2. Private methods never used
3. Helper functions with no callers
4. Deprecated functions still present
5. Test-only functions in production code

List all unused functions and create fixes to remove them.
```

## DEAD-003: Unused Widgets
```
Analyze unused widgets in:
- lib/shared/widgets/*.dart
- lib/features/*/presentation/widgets/*.dart

Check for:
1. Widget classes never instantiated
2. Widgets only used in comments
3. Deprecated widgets still present
4. Duplicate widget implementations
5. Widgets replaced by newer versions

List all unused widgets and create fixes to remove them.
```

## DEAD-004: Unused Models and Classes
```
Analyze unused models in:
- lib/shared/models/*.dart
- lib/features/*/domain/models/*.dart
- lib/features/*/data/*.dart

Check for:
1. Model classes never instantiated
2. Freezed models with no usage
3. Deprecated models still present
4. Duplicate model definitions
5. Models only used in tests

List all unused models and create fixes to remove them.
```

## DEAD-005: Unused Providers
```
Analyze unused providers in:
- lib/core/providers/*.dart
- lib/shared/providers/*.dart
- lib/features/*/presentation/providers/*.dart

Check for:
1. Providers never watched or read
2. Providers only used in other unused providers
3. Deprecated providers still present
4. Duplicate provider definitions
5. Generated providers (.g.dart) with no source

List all unused providers and create fixes to remove them.
```

## DEAD-006: Commented Code
```
Analyze commented code in ALL files under:
- lib/
- functions/src/

Check for:
1. Large blocks of commented code (>5 lines)
2. TODO comments for completed tasks
3. FIXME comments for fixed issues
4. Commented imports
5. Commented function implementations
6. Debug print statements commented out

List all commented code blocks and create fixes to remove them.
```

## DEAD-007: Unused Cloud Functions
```
Analyze unused Cloud Functions in:
- functions/src/*.ts
- functions/src/index.ts (exports)

Check for:
1. Exported functions never called
2. Helper functions with no callers
3. Scheduled functions that should be disabled
4. HTTP functions with no routes
5. Trigger functions for deleted collections

List all unused functions and create fixes to remove them.
```

## DEAD-008: Unused Assets
```
Analyze unused assets in:
- assets/
- web/
- pubspec.yaml (assets section)

Check for:
1. Images never referenced in code
2. Fonts not used in theme
3. JSON files not loaded
4. Icons not used
5. Duplicate assets
6. Large unused files

List all unused assets and create fixes to remove them.
```

## DEAD-009: Unused Dependencies
```
Analyze unused dependencies in:
- pubspec.yaml
- functions/package.json

Check for:
1. Packages never imported
2. Dev dependencies in regular dependencies
3. Deprecated packages
4. Duplicate functionality packages
5. Packages only used in removed code

List all unused dependencies and create fixes to remove them.
```

## DEAD-010: Unused Routes
```
Analyze unused routes in:
- lib/core/config/router_owner.dart
- lib/core/config/router_widget.dart

Check for:
1. Routes with no navigation to them
2. Routes for deleted screens
3. Duplicate route definitions
4. Routes with broken builders
5. Redirect routes that are never hit

List all unused routes and create fixes to remove them.
```

## DEAD-011: Unused Localization Keys
```
Analyze unused localization in:
- lib/l10n/app_en.arb
- lib/l10n/app_hr.arb
- lib/l10n/app_localizations*.dart

Check for:
1. Keys defined but never used in code
2. Keys only used in comments
3. Duplicate key definitions
4. Keys for removed features
5. Placeholder keys never filled

List all unused keys and create fixes to remove them.
```

## DEAD-012: Unused Test Files
```
Analyze test files in:
- test/
- integration_test/

Check for:
1. Test files for deleted code
2. Skipped tests that should be removed
3. Test utilities never used
4. Mock files for removed dependencies
5. Outdated test fixtures

List all unused test files and create fixes to remove them.
```

## DEAD-013: Unused Configuration Files
```
Analyze configuration files in project root:
- *.bat, *.ps1, *.sh files
- *.json, *.yaml files
- *.html test files

Check for:
1. Build scripts for removed targets
2. Test HTML files no longer needed
3. Configuration for removed features
4. Duplicate configuration files
5. Outdated deployment scripts

List all unused files and create fixes to remove them.
```

## DEAD-014: Unused Email Templates
```
Analyze email templates in:
- functions/src/email/templates/*.ts
- functions/src/emailService.ts

Check for:
1. Templates never sent
2. Template functions never called
3. Duplicate template implementations
4. Templates for removed features
5. Unused template variables

List all unused templates and create fixes to remove them.
```

---

# 6. DOCUMENTATION PROMPTS

## DOC-001: Outdated Bug Documentation
```
Analyze bug documentation in:
- docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md
- docs/bugs/unresolved-bugs.md
- docs/unresolved-bugs/OWNER_DASHBOARD_BUGS.md
- docs/Resolved/*.md

Cross-reference with actual code to check:
1. Bugs marked as unresolved but actually fixed
2. Bugs marked as resolved but still present
3. Bug descriptions that don't match current code
4. Missing bug documentation for known issues
5. Duplicate bug entries

Update documentation to reflect current state.
```

## DOC-002: Outdated Feature Documentation
```
Analyze feature documentation in:
- docs/features/*.md
- docs/features/**/*.md

Cross-reference with actual code to check:
1. Features documented but not implemented
2. Features implemented but not documented
3. Feature descriptions that don't match implementation
4. Outdated screenshots or examples
5. Missing API documentation

Update documentation to reflect current state.
```

## DOC-003: Outdated Setup Documentation
```
Analyze setup documentation in:
- docs/setup/**/*.md
- docs/Implemented Plans/*.md
- README.md

Cross-reference with actual project to check:
1. Outdated installation steps
2. Wrong dependency versions
3. Missing environment variables
4. Outdated deployment instructions
5. Broken links

Update documentation to reflect current state.
```

## DOC-004: Outdated Security Documentation
```
Analyze security documentation in:
- docs/security/*.md
- docs/SECURITY_FIXES.md

Cross-reference with actual code to check:
1. Security fixes documented but not implemented
2. Security issues fixed but not documented
3. Outdated security recommendations
4. Missing security documentation
5. Incorrect file paths in documentation

Update documentation to reflect current state.
```

## DOC-005: Outdated API Documentation
```
Analyze API documentation in:
- docs/api-integrations/**/*.md
- CLAUDE.md (Cloud Functions section)

Cross-reference with actual code to check:
1. API endpoints that don't exist
2. Missing API documentation
3. Wrong parameter descriptions
4. Outdated response formats
5. Missing error code documentation

Update documentation to reflect current state.
```

## DOC-006: Outdated Architecture Documentation
```
Analyze architecture documentation in:
- docs/Implemented Plans/RabBooking-Architecture-Plan-v2.md
- docs/Implemented Plans/ARCHITECTURAL_IMPROVEMENTS.md
- docs/STRUCTURE.md

Cross-reference with actual code to check:
1. Folder structure changes not documented
2. New modules not in architecture docs
3. Removed modules still documented
4. Outdated dependency diagrams
5. Wrong file paths

Update documentation to reflect current state.
```

## DOC-007: CLAUDE.md Accuracy
```
Analyze CLAUDE.md against actual codebase:

Check each section for accuracy:
1. "NIKADA NE MIJENJAJ" - verify these files still exist and rules apply
2. "STANDARDI" - verify code examples match actual patterns
3. "CALENDAR SYSTEM" - verify repository and enum descriptions
4. "CLOUD FUNCTIONS" - verify function names and patterns
5. "STRIPE FLOW" - verify payment flow matches implementation
6. "HOSTING & DOMENE" - verify domain configuration
7. All file paths mentioned - verify they exist

Update CLAUDE.md to reflect current state.
```

## DOC-008: Code Comments Accuracy
```
Analyze code comments in:
- lib/features/widget/data/repositories/*.dart
- lib/features/owner_dashboard/presentation/screens/*.dart
- functions/src/*.ts

Check for:
1. Comments describing wrong behavior
2. TODO comments for completed tasks
3. FIXME comments for fixed issues
4. Outdated JSDoc/DartDoc
5. Comments referencing deleted code
6. Wrong parameter descriptions

Update comments to reflect current code.
```

## DOC-009: Changelog Accuracy
```
Analyze changelog in CLAUDE.md:

Check each changelog entry:
1. Verify mentioned files exist
2. Verify described changes are present
3. Check for missing changelog entries
4. Verify version numbers are sequential
5. Check dates are accurate

Update changelog to reflect actual changes.
```

## DOC-010: Test Documentation
```
Analyze test documentation in:
- docs/testing/*.md
- test/README.md (if exists)

Cross-reference with actual tests to check:
1. Test instructions that don't work
2. Missing test documentation
3. Outdated test commands
4. Wrong test file paths
5. Missing coverage information

Update documentation to reflect current state.
```

## DOC-011: Email System Documentation
```
Analyze email documentation in:
- docs/features/email-templates/EMAIL_SYSTEM.md
- docs/features/email-templates/EMAIL_TEMPLATES_UPDATE_SUMMARY.md

Cross-reference with actual code to check:
1. Template names that don't exist
2. Missing template documentation
3. Wrong variable names
4. Outdated email flow descriptions
5. Missing trigger documentation

Update documentation to reflect current state.
```

## DOC-012: Stripe Documentation
```
Analyze Stripe documentation in:
- docs/features/stripe/*.md
- docs/stripe-checkout/*.md

Cross-reference with actual code to check:
1. Outdated Stripe API versions
2. Wrong webhook event names
3. Missing payment flow steps
4. Outdated security recommendations
5. Wrong file paths

Update documentation to reflect current state.
```

---

# USAGE INSTRUCTIONS

## How to Use These Prompts with Jules AI

1. **Copy one prompt at a time** - Don't combine prompts
2. **Wait for analysis** - Jules will create a branch with findings
3. **Review the branch** - Check if issues are real or false positives
4. **Merge valid fixes** - Only merge fixes that are correct
5. **Document findings** - Update docs/SECURITY_FIXES.md if needed

## Recommended Order

1. Start with **SECURITY** prompts (highest priority)
2. Then **LOGIC** prompts (business-critical)
3. Then **DEAD CODE** prompts (cleanup)
4. Then **DOCUMENTATION** prompts (accuracy)
5. Then **PERFORMANCE** prompts (optimization)
6. Finally **UI/UX** prompts (polish)

## Tips

- Run one prompt per day to avoid overwhelming review
- Keep track of which prompts have been run
- Some prompts may find no issues - that's good!
- False positives are common - always verify before merging
- Update this document as prompts are completed

---

**Total Prompts: 68**
- Security: 15
- UI/UX: 14
- Performance: 12
- Logic: 12
- Dead Code: 14
- Documentation: 12

**Created**: 2026-01-06
**For**: Jules AI (Google Labs)
**Project**: BookBed (rab_booking)
