# Booking Widget Refactor Plan (4808 → modular)

Status: **Phase 0+1 EXECUTED** on branch `refactor/booking-widget-phase1` (2026-05-22, CHANGELOG 6.78). Phases 2-5 deferred — tracked in `docs/TODO.md` § "Booking widget refactor — Phases 2-5".
Date: 2026-05-22
Target: `lib/features/widget/presentation/screens/booking_widget_screen.dart` (4811 → **4126 LOC**, –685)

## Execution log (Phase 0+1)

| Decision (this plan §8) | Resolved as |
|---|---|
| Q1 agent-log instrumentation status | **DELETED** wholesale (debug session closed) — Phase 0 commit `08973bc9`, –419 LOC |
| Q2 BookingFormState approach | **Promoted to `ChangeNotifier`** (minimum churn) — commit `a3acc3f7` |
| Q9 `helpers/formatters.dart` | **Dropped from plan** — no formatters to extract |

Phase 1 commits on `refactor/booking-widget-phase1` (8 commits total incl. this audit doc):
- `074c2652` audit doc (this file)
- `08973bc9` Phase 0 — delete 18 agent-log regions
- `eaabf7ce` extract `booking_widget_url_helpers.dart` + 34-case test
- `84a1d906` extract `booking_widget_url_intent.dart` + 16-case test
- `a3acc3f7` promote `BookingFormState` to `ChangeNotifier` + 23-case test + `toPersistedFormData`/`applyFromPersisted` factories
- `2243a6e7` extract `IframeHeightReporter`
- `3ac4af3b` extract `ZoomControlState` (also fixes pre-existing `_transformationController` dispose leak)
- `4b01e033` extract `PoweredByBadge` to its own file

Net delta: 11 files changed, 1802 insertions, 843 deletions. Screen –685 LOC. 73 new test cases. `flutter analyze` clean. Test parity vs main: identical 21 pre-existing failures, zero new regressions.

Phases 2-5 (composers, validation orchestrator, submit pipeline, payment messaging consolidation) deferred — see `docs/TODO.md`.

---

Original audit below (kept verbatim for reference).

Source-of-truth scan: full file read in 4 passes (0–800, 800–1600, 1600–2400, 2400–3200, 3200–4000, 4000–4808). LOC counts below are exact at audit time.

---

## 1. Structural inventory

### Classes / state

| Class / State | Lines | LOC | Notes |
|---|---|---|---|
| `BookingWidgetScreen` (ConsumerStatefulWidget) | 82–92 | 11 | Public widget shell; takes optional `urlSlug` |
| `_BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen>` | 94–4766 | **4673** | The god-screen |
| `_PoweredByBadge` (StatefulWidget) | 4769–4777 | 9 | Tiny footer link |
| `_PoweredByBadgeState extends State<_PoweredByBadge>` | 4779–4808 | 30 | Hover/launchUrl |

No mixins, no extensions. The state class is the entire problem surface.

### State fields, grouped semantically

| Group | Fields (with type) | Lines |
|---|---|---|
| **URL sanitization (static helpers)** | `_sanitizeId`, `_isValidBookingReference`, `_isValidFirestoreId`, `_isValidStripeSessionId`, `_safeErrorToString` | 100–145 |
| **Unit & property data** | `_unitId:String`, `_propertyId:String?`, `_ownerId:String?`, `_unit:UnitModel?`, `_widgetSettings:WidgetSettings?` | 150–154 |
| **Validation state** | `_validationError:String?` | 161 |
| **Calendar refresh** | `_calendarRefreshKey:int=0` | 168 |
| **Form state (delegated)** | `_formState:BookingFormState`, **20 getter/setter pass-throughs** to `_formState` (dates, controllers, country, guest counts, payment method, processing/verification flags, locked price, pillBarDismissed, hasInteractedWithBookingFlow) | 173–219 |
| **Theme detection** | `_hasDetectedSystemTheme:bool=false` | 225 |
| **Form persistence (debounce)** | `_saveDebounce:Timer?`, `_isDisposed:bool=false` | 230–231 |
| **Cross-tab / payment messaging** | `_paymentCompletionTimeout:Timer?`, `_tabCommunicationService:TabCommunicationService?`, `_tabMessageSubscription:StreamSubscription<TabMessage>?`, `_postMessageListenerCleanup:VoidCallback?` | 237–244 |
| **Iframe height** | `_contentKey:GlobalKey`, `_lastSentHeight:double=0` | 250–252 |
| **Zoom** | `_zoomScale:double=1.0`, `_transformationController:TransformationController`, `_interactiveViewerKey:GlobalKey` | 257–261 |

### Methods >100 LOC — primary extraction candidates

| Method | Lines | LOC | Notes |
|---|---|---|---|
| `_handleConfirmBooking` | 3444–3938 | **495** | Biggest single method. Validation → price lock → fresh price revalidation (150 LOC inline) → inline AlertDialog (80 LOC) → submit → sealed-class dispatch → error handling |
| `build` | 1944–2522 | **579** | Inline error screen, iframe height callback, custom title, calendar-only banner, Listener+InteractiveViewer wrapping LazyCalendarContainer, overlay Stack (rotate/backdrop/pill/zoom). The actual god-method. |
| `_setupPaymentBridgeListener` | 512–706 | 195 | JS interop callback with nested agent-log regions |
| `_handleStripePayment` | 4024–4350 | **327** | Popup pre-open → checkout session → 4 popup-result branches (popup/redirect/blocked/unexpected) |
| `_buildPaymentSection` | 2885–3215 | **331** | No-payment fallback, single-method auto-select, multi-method selector, info card, confirm button |
| `_handleStripeReturnWithSessionId` | 1301–1482 | 182 | Poll loop (15× 2s) for webhook-created booking, navigate to confirmation |
| `_buildFloatingDraggablePillBar` | 2525–2882 | **358** | Watches price provider, computes services total, fee math, responsive sizing, builds PillBarContent with 4 builder closures |
| `_handlePaymentCompleteFromOtherTab` | 897–1010 | 114 | Cross-tab paymentComplete handler |
| `_initTabCommunication` | 420–509 | 90 | Just under threshold; many agent-log regions |
| `_buildGuestInfoForm` | 3217–3411 | 195 | Form composer wrapping leaf widgets |
| `_showConfirmationFromUrl` | 4360–4524 | 165 | Fetch + 20s pending-payment poll + navigate |
| `_validateUnitAndProperty` | 1492–1651 | 160 | Two URL-resolution modes (slug vs query) |
| `dispose` | 1832–1942 | 111 | 9 defensive try/catch blocks + 2 agent-log regions |
| `_startPaymentCompletionTimeout` | 1142–1296 | 155 | 30s timer with 3 agent-log regions |

Sub-threshold methods (still notable): `_showPaymentDelayedDialog` (86), `_openVerificationDialog` (92), `_navigateToConfirmationAndCleanup` (69), `_validateEmailVerificationBeforeBooking` (96), `_setDefaultPaymentMethod` (41), `_handlePostMessage` (105), `_loadFormData` (47), `_retryValidation` (29).

### Cross-cutting debug instrumentation

**18 `// #region agent log … // #endregion` blocks** inside the state class, paired with `} catch (_) {}` silent guards (per `.claude/rules/widget.md` — INTENTIONAL, must not be replaced with `logError`). Located in:
- `_initTabCommunication` (×2)
- `_setupPaymentBridgeListener` (×4 — payment-bridge receive / cancel / reset before/after)
- `_handlePaymentCompleteFromOtherTab` (×1 entry)
- `_startPaymentCompletionTimeout` (×4)
- `dispose` (×2)
- `_handleConfirmBooking` (×1)
- `_handleStripePayment` (×2 — popup-decision logs)
- Other touchpoints (×2)

Together these inflate ~600 LOC of pure telemetry noise.

---

## 2. Build method map

### `build()` outer structure (lines 1944–2522)

1. Theme watch (1946–1948)
2. Conditional `ref.listen(bookingPriceProvider)` — listens for `DatesNotAvailableException`, clears dates + shows SnackBar (1952–2020). ~70 LOC
3. Early return `_validationError != null` → inline error Scaffold (2027–2064). ~38 LOC
4. `_sendIframeHeight()` side-effect (2070)
5. Returns `Scaffold` with:
   - transparent background if `isInIframe`
   - bottom-left FAB `mailto:dusko@book-bed.com` (2083–2107)
   - `SafeArea` → `LayoutBuilder` → `Stack` containing:
     - **Scrollable content** (`SingleChildScrollView` → `ConstrainedBox` → `Column` → `Center` → `ConstrainedBox` → `Padding` → `Column(key: _contentKey)`):
       - Custom title (if configured) (2186–2214)
       - Calendar-only banner (2222–2281)
       - `Listener(onPointerSignal)` + `InteractiveViewer` + `LazyCalendarContainer` (2287–2401) — includes inline min-nights validation + SnackBar in `onRangeSelected` closure (~60 LOC)
       - `_PoweredByBadge` (2407–2419)
     - **Overlays**:
       - `RotateDeviceOverlay` (2433–2444)
       - Full-screen backdrop when `_showGuestForm` (2447–2461)
       - `_buildFloatingDraggablePillBar` (2469–2473)
       - `ZoomControlButtons` with inline matrix math for centered zoom (2476–2515)

### `_buildXxx()` helpers

| Method | LOC | Responsibility |
|---|---|---|
| `_buildInstructionItem` | 12 | Single Text row inside payment-delayed dialog |
| `_buildFloatingDraggablePillBar` | 358 | Watches price provider, responsive sizing, builds PillBarContent with 4 builder closures (guestForm / payment / services / taxLegal) |
| `_buildGuestInfoForm` | 195 | Form composer: name, email-with-verification, phone+country, notes, guest count, confirm button |
| `_buildPaymentSection` | 331 | Payment method selector / single-method auto-select / no-method error / bookingPending info / confirm button |

The 4 builder closures inside the pill bar are the main reason `_buildGuestInfoForm` and `_buildPaymentSection` capture state (closure capture risk for extraction).

---

## 3. Dependency graph

### Riverpod providers — `ref.watch` / `ref.read` / `ref.listen`

| Provider | Type of access | Locations |
|---|---|---|
| `themeProvider` | watch, read | build, _buildFloatingDraggablePillBar, _buildPaymentSection, _buildGuestInfoForm, _openVerificationDialog, _handleConfirmBooking (×many) |
| `bookingPriceProvider` | listen, watch | build (DatesNotAvailableException listen), _buildFloatingDraggablePillBar |
| `realtimeYearCalendarProvider`, `realtimeMonthCalendarProvider` | invalidate | _resetFormState, _handleTabMessage, _handleStripeReturnWithSessionId, _showConfirmationFromUrl, _navigateToConfirmationAndCleanup |
| `widgetContextProvider((propertyId,unitId))` | read (await .future) + invalidate | _validateUnitAndProperty, _retryValidation |
| `optimizedSlugWidgetContextProvider(urlSlug)` | read + invalidate | _validateUnitAndProperty (slug path), _retryValidation |
| `widgetPropertyByIdProvider`, `unitByIdProvider`, `widgetSettingsProvider` | invalidate | _retryValidation |
| `selectedAdditionalServicesProvider` | watch, invalidate | _buildFloatingDraggablePillBar, _resetFormState |
| `unitAdditionalServicesProvider((propertyId,unitId))` | watch | _buildFloatingDraggablePillBar (×2) |
| `additionalServicesTotalProvider((services, selected, nights, guests))` | read | _buildFloatingDraggablePillBar |
| `calendarViewProvider` | watch, read | build, _shouldShowRotateOverlay |
| `bookingLookupServiceProvider` | read | _handleStripeReturnWithSessionId |
| `submitBookingUseCaseProvider` | read | _handleConfirmBooking |
| `bookingRepositoryProvider` | read | _showConfirmationFromUrl |
| `unitRepositoryProvider` | read | _handleConfirmBooking (price revalidation) |
| `bookingCalendarRepositoryProvider` | read | _handleConfirmBooking (price recalc) |
| `stripeServiceProvider` | read | _handleStripePayment |

### External services / native interop touched

| Surface | Where |
|---|---|
| `LoggingService.log / logError / logWarning / logOperation / logSuccess / addBreadcrumb` | Pervasive (~60+ calls) |
| `AnalyticsService.instance` (logStripePaymentInitiated / Completed / PopupBlocked) | _handlePaymentCompleteFromOtherTab, _handleStripeReturnWithSessionId, _handleStripePayment |
| `BrowserDetection.getBrowserName / getDeviceType` | (same call sites) |
| `EmailVerificationService.checkStatus` | _validateEmailVerificationBeforeBooking, _openVerificationDialog |
| `FormPersistenceService.{save,load,clear}FormData` | _saveFormData, _loadFormData, _clearFormData |
| `BookingValidationService.{validateAllBlocking, checkSameDayCheckIn}` | _handleConfirmBooking |
| `PriceLockService.checkAndConfirmPriceChange` | _handleConfirmBooking |
| `BookingUrlStateService.{addConfirmationParams, clearBookingParams}` | _navigateToConfirmationAndCleanup, _showConfirmationFromUrl, _handleStripeReturnWithSessionId |
| `TabCommunicationService` (BroadcastChannel) | _initTabCommunication / _handleTabMessage / _handlePaymentCompleteFromOtherTab |
| JS interop helpers (`web_utils.dart`): `isInIframe`, `isPopupWindow`, `isWebPlatform`, `setupIframeScrollCapture`, `sendIframeHeight`, `listenToParentMessages`, `setupPaymentResultListener`, `preOpenPaymentPopup`, `updatePaymentPopupUrl`, `redirectTopLevelWindow`, `navigateToUrl`, `saveBookingStateForPayment`, `isDeviceLandscape` | _initTabCommunication, _setupPaymentBridgeListener, _sendIframeHeight, _handleStripePayment, _shouldShowRotateOverlay |
| `launchUrl` (`url_launcher`) | build FAB, _handleStripePayment (mobile fallback), `_PoweredByBadge` |
| `EnvironmentConfig.{widgetHost, isMarketingHost}` | _handleStripePayment (return URL build) |
| `SnackBarHelper.{showError, showWarning, showSuccess}` | Pervasive |
| `WidgetTranslations.of(context, ref)` | Pervasive |
| `Navigator.push(MaterialPageRoute(builder: BookingConfirmationScreen(...)))` | _handleStripeReturnWithSessionId, _navigateToConfirmationAndCleanup, _showConfirmationFromUrl |

### Imported widget files (already extracted leaves)

- `lazy_calendar_container.dart`, `additional_services_widget.dart`, `tax_legal_disclaimer_widget.dart`
- `booking_pill_bar.dart`, `pill_bar_content.dart`
- `payment/{payment_option_widget, payment_method_card, no_payment_info}.dart`
- `guest_form/{guest_count_picker, email_field_with_verification, phone_field, guest_name_fields, notes_field}.dart`
- `country_code_dropdown.dart`, `email_verification_dialog.dart`
- `common/{rotate_device_overlay, info_card_widget}.dart`
- `zoom_control_buttons.dart`
- `booking_confirmation_screen.dart` (Navigator push target)

---

## 4. Proposed file split

### Convention corrections (vs. brief)

- **State path is `lib/features/widget/state/`** (sibling of `presentation/`), not `presentation/state/` — `BookingFormState` already lives there.
- **`BookingFormState` (232 LOC) already exists and is wired in.** Plan extends it; does NOT create parallel state files.
- **Most leaf widgets are already extracted** (see import list §3). New "widget" files are mostly *composers* wrapping existing leaves, not new leaf extractions.
- **Helpers already exist**: `domain/services/{booking_validation_service, booking_url_state_service, price_lock_service, calendar_data_service}.dart`, `shared/utils/validators/form_validators.dart`, `services/form_persistence_service.dart`. No `helpers/validators.dart` needed.

### Proposed file map

| New file | Source lines (current) | Est LOC | Deps | Rationale |
|---|---|---|---|---|
| **`presentation/screens/booking_widget_screen.dart`** (slimmed orchestrator) | n/a | ≤300 | `BookingFormState`, all extracted widgets/services below | Just initState/dispose + build skeleton + glue |
| **`presentation/helpers/booking_widget_url_helpers.dart`** | 100–145 | 50 | none | Static `_sanitizeId / _isValidBookingReference / _isValidFirestoreId / _isValidStripeSessionId / _safeErrorToString` — pure functions |
| **`presentation/helpers/booking_widget_url_intent.dart`** | 268–395 (initState URL parsing) | 90 | URL helpers above | Pure: parse `Uri.base`, return sealed `enum BookingUrlIntent { freshLoad, stripeReturnSession, stripeReturnLegacy, directBookingReturn }` for initState to dispatch on |
| **`presentation/helpers/iframe_height_reporter.dart`** | 822–862 + `_contentKey` field + `_lastSentHeight` | 70 | `web_utils.dart` | Encapsulate `_sendIframeHeight` + key + threshold |
| **`presentation/helpers/zoom_control_state.dart`** | 257–261 fields + 2476–2515 inline matrix math | 80 | `flutter/material.dart` | TransformationController owner; centered-zoom matrix builder |
| **Extend existing `state/booking_form_state.dart`** | 173–219 (delegates) + `_resetFormState` (1116–1137) + `_buildPersistedFormData` (1735–1754) | +60 to existing 232 | unchanged | Promote to `ChangeNotifier`; absorb `resetState` (already there) + add `toPersistedFormData()` factory + `applyFromPersisted(PersistedFormData)` |
| **`state/booking_payment_messaging_controller.dart`** | 237–244 fields + 420–815 (initTabComm / setupPaymentBridge / handlePostMessage / handleTabMessage / handlePaymentCompleteFromOtherTab) + 1142–1296 (timeout) | 450 | `web_utils.dart`, `TabCommunicationService` | Owns BroadcastChannel + postMessage + PaymentBridge listeners + timeout. Emits a single `Stream<PaymentEvent>` consumed by the screen. **This is the riskiest extraction.** |
| **`state/booking_validation_orchestrator.dart`** | 1492–1688 (`_validateUnitAndProperty` + `_retryValidation`) + `_setDefaultPaymentMethod` (1693–1730) | 230 | widget context providers, `WidgetContextException` | Two URL-resolution modes + retry + default-payment-method picker. Pure async, no `setState` |
| **`presentation/widgets/booking_widget_error_screen.dart`** | 2027–2064 | 50 | `MinimalistColorSchemeAdapter`, `WidgetTranslations` | Inline-built error Scaffold (icon + message + retry button) |
| **`presentation/widgets/booking_widget_calendar_section.dart`** | 2222–2401 | 200 | `LazyCalendarContainer`, zoom controller, `WidgetTranslations`, calendar providers | Calendar-only banner + Listener+InteractiveViewer+LazyCalendarContainer + min-nights validation closure |
| **`presentation/widgets/booking_widget_overlays.dart`** | 2433–2515 | 110 | `RotateDeviceOverlay`, `ZoomControlButtons`, zoom controller | Rotate + backdrop + zoom button positioning (Stack children helper) |
| **`presentation/widgets/floating_pill_bar.dart`** (composer) | 2525–2882 | 250 | `BookingPillBar`, `PillBarContent`, all existing form/payment leaves, `bookingPriceProvider`, additional-services providers | Replaces `_buildFloatingDraggablePillBar`. Internal `_PillBarContext` holds `unit`, `formState`, `widgetSettings`. Builder closures call back into orchestrator via `onReserve / onClose / onTaxLegalChanged` |
| **`presentation/widgets/guest_info_form_section.dart`** (composer) | 3217–3411 | 195 | existing `guest_form/*` leaves, `country_code_dropdown`, `EmailValidator`, `BookingFormState` | Replaces `_buildGuestInfoForm`. Reads/writes `BookingFormState` directly; takes `onConfirmPressed`, `onVerifyEmailPressed` callbacks |
| **`presentation/widgets/payment_method_section.dart`** (composer) | 2885–3215 | 280 | existing `payment/*` leaves, `WidgetTranslations` | Replaces `_buildPaymentSection`. No-method, single-method auto-select, multi-method selector, bookingPending info, confirm button |
| **`presentation/widgets/price_change_confirmation_dialog.dart`** | 3680–3724 | 70 | `MinimalistColorSchemeAdapter` | Inline AlertDialog extracted from `_handleConfirmBooking` |
| **`presentation/widgets/payment_delayed_dialog.dart`** | 1014–1113 (`_showPaymentDelayedDialog` + `_buildInstructionItem`) | 110 | `ColorTokens`, `WidgetTranslations` | Standalone AlertDialog widget |
| **`presentation/widgets/powered_by_badge.dart`** | 4769–4808 | 45 | `url_launcher` | Move `_PoweredByBadge` to its own file (currently file-private) |
| **`domain/services/pre_submit_price_revalidator.dart`** | 3565–3779 (inline price-revalidation block inside `_handleConfirmBooking`) | 200 | `unitRepositoryProvider`, `bookingCalendarRepositoryProvider`, `LoggingService` | Pure async: fetches fresh unit data, recomputes price+fees, returns `PriceRevalidationResult { calculation, deltaCents, anomaly }`. Caller decides whether to show dialog |
| **`domain/services/booking_submit_orchestrator.dart`** | 3782–3938 (post-validation submit branch of `_handleConfirmBooking`) + sealed-class dispatch | 200 | `SubmitBookingParams`, `submitBookingUseCaseProvider`, `BookingConflictException` | Build `SubmitBookingParams` from form state, dispatch `BookingSubmissionStripe` / `BookingSubmissionCreated`, surface errors as typed result |
| **`domain/services/stripe_payment_launcher.dart`** | 4024–4350 | 320 | `EnvironmentConfig`, `stripeServiceProvider`, `web_utils.dart` | Owns return-URL build, popup pre-open, 4 popup-result branches (popup/redirect/blocked/unexpected), error fallback |
| **`domain/services/stripe_return_handler.dart`** | 1301–1482 (`_handleStripeReturnWithSessionId`) + 4360–4524 (`_showConfirmationFromUrl`) | 340 | `bookingLookupServiceProvider`, `bookingRepositoryProvider`, `BookingUrlStateService` | Webhook poll loop (15× 2s for session) + legacy fetch-by-id with 20s pending poll. Returns `BookingDetailsModel` / `BookingModel` to caller; screen handles Navigator.push |
| **`presentation/helpers/booking_widget_debug_log.dart`** (Phase 0, optional) | All 18 `// #region agent log` blocks | 80 | `LoggingService` | Single helper `debugAgentLog(location, message, data, hypothesisId)`. Drops ~600 LOC of inline boilerplate across new files. Keeps `try { … } catch (_) {}` per `.claude/rules/widget.md` |

### Sanity check

Total proposed: 1 orchestrator + 4 helper files + 1 state extension + 2 controller/orchestrator state files + 9 widget files + 4 domain-service files = **21 new units** (plus extension of one existing).

Sum of estimated LOC: ~3500 across new files. Original was 4808. Net ~1300 LOC saved (mostly from agent-log consolidation and removing delegating getters in the screen). Each new file lands ≤340 LOC, target was ≤500.

---

## 5. Risk per split

| File | Risk | Notes |
|---|---|---|
| `booking_widget_url_helpers.dart` | **LOW** | Static, pure, no closures. Mechanical move. |
| `booking_widget_url_intent.dart` | **LOW** | Pure parse of `Uri.base`. Returns enum; initState dispatches. |
| `iframe_height_reporter.dart` | **LOW** | Owns its own `GlobalKey`. Screen passes `contentKey` to its child column. |
| `zoom_control_state.dart` | **LOW** | TransformationController + matrix math. No widget-tree captures. |
| Extend `BookingFormState` | **LOW** | Existing class already wired via `_formState`. Adding `ChangeNotifier` semantics + `toPersistedFormData()` is mechanical. |
| `booking_validation_orchestrator.dart` | **MEDIUM** | Two async paths reach into screen state (`_propertyId / _unitId / _unit / _widgetSettings / _ownerId`). Needs to return a `WidgetContextResult` struct screen applies via `setState`. No closures captured. |
| `booking_widget_error_screen.dart` | **LOW** | Takes `error:String, onRetry:VoidCallback`. Stateless. |
| `booking_widget_calendar_section.dart` | **MEDIUM** | `onRangeSelected` closure currently calls `setState`, reads `_unit.minStayNights`, calls `_saveFormData`. Needs callback contract `(start, end) => void` + `minNights:int` prop. |
| `booking_widget_overlays.dart` | **LOW** | Stateless. Receives `showBackdrop:bool`, `showRotate:bool`, `zoomState:ZoomControlState`, `onBackdropTap:VoidCallback`. |
| `floating_pill_bar.dart` | **MEDIUM** | Four builder closures (`guestFormBuilder`, `paymentSectionBuilder`, `additionalServicesBuilder`, `taxLegalBuilder`) reach into screen state. Need to bind each to its extracted composer + thread `BookingFormState` and `onTaxLegalAcceptedChanged` callback through. Fee math (extra-guest + pet) is local sync and moves cleanly. |
| `guest_info_form_section.dart` | **MEDIUM** | Form `key` is the existing `BookingFormState.formKey`; controllers live on `BookingFormState`. setState calls (×6) become `formState.notifyListeners()` once `BookingFormState` is `ChangeNotifier`. `_openVerificationDialog` stays on screen (calls `EmailVerificationService` + shows dialog) — pass as callback. |
| `payment_method_section.dart` | **MEDIUM** | `WidgetsBinding.addPostFrameCallback` for auto-select single method — moves into composer but caller passes `onPaymentMethodChanged`. Confirm button calls `_handleConfirmBooking(calculation)` — pass `onConfirmPressed` callback. |
| `price_change_confirmation_dialog.dart` | **LOW** | Pure async dialog. Returns `bool?`. |
| `payment_delayed_dialog.dart` | **LOW** | Static `show()` method. |
| `powered_by_badge.dart` | **LOW** | Already self-contained. Just file move + drop underscore prefix. |
| `pre_submit_price_revalidator.dart` | **MEDIUM** | Reads `_propertyId / _unitId / _checkIn / _checkOut / _adults / _children / _pets / _widgetSettings?.globalDepositPercentage`. Takes them as a params struct. Returns `PriceRevalidationResult`. No `setState`. Anomaly detection (NaN / >€10k) preserved. |
| `booking_submit_orchestrator.dart` | **MEDIUM** | Builds `SubmitBookingParams` from `BookingFormState` + unit/property/owner ids. Returns sealed `BookingSubmissionResult` (already exists in domain). |
| `stripe_payment_launcher.dart` | **BLOCKING (high)** | Four popup-result branches each call `setState({_isProcessing, _showGuestForm})` + `_resetFormState()` + sometimes `_startPaymentCompletionTimeout()`. Tight coupling to messaging controller (it starts the timeout) and to form-reset. Needs a callback contract: `onPopupResultDecided`, `onRedirectInitiated`, `onPopupOpened` + `paymentMessaging.startTimeout()`. Heavy testing burden. |
| `stripe_return_handler.dart` | **MEDIUM** | Async fetch + poll + Navigator.push. Returns `BookingDetailsModel`/`BookingModel`; screen calls Navigator. Cross-tab broadcast (`_tabCommunicationService!.sendPaymentComplete(...)`) lives in messaging controller, called by screen. |
| **`booking_payment_messaging_controller.dart`** | **BLOCKING (highest)** | Three messaging surfaces interleaved (BroadcastChannel + postMessage iframe + PaymentBridge JS interop). 8 of 18 agent-log blocks live here. Multiple closures capture screen-level state. Each callback currently calls `setState({_isProcessing})` + sometimes `_resetFormState` + sometimes `_handleStripeReturnWithSessionId`. Consolidating into a single `Stream<PaymentEvent>` API requires designing the event union carefully so the screen's reactor switch is exhaustive. Browser-matrix coverage assumption needs to be validated before collapsing. |
| `booking_widget_debug_log.dart` (Phase 0) | **LOW** | Pure helper. Replace ~18 inline blocks with `debugAgentLog(...)` call. Must keep `try { … } catch (_) {}` wrapper inside the helper per widget.md guard rules. |

---

## 6. Phase sequence + effort estimates

Conservative estimates assume one developer, manual smoke on Flutter web + iOS dev (with the `GoogleService-Info.plist` swap from `.claude/rules/ios-development.md`) after each phase, plus `flutter analyze` clean before merge.

### Phase 0 (optional preliminary cleanup) — 3–4 h
- Decide with stakeholder whether agent-log instrumentation is still active.
- If yes: extract `debug_log.dart` helper, replace 18 inline regions with single calls (~400 LOC reduction).
- If no: delete the regions entirely (~600 LOC reduction).
- This dramatically improves the LOC math for subsequent phases.

### Phase 1: pure helpers (zero behavior change) — 4 h
- Extract `booking_widget_url_helpers.dart`, `booking_widget_url_intent.dart`, `iframe_height_reporter.dart`, `zoom_control_state.dart`, `powered_by_badge.dart`.
- Promote `BookingFormState` to `ChangeNotifier`; add `toPersistedFormData()` + `applyFromPersisted()`.
- Smoke-test: dates, form auto-save, zoom buttons, iframe height resize event still fires.

### Phase 2: leaf composers (low/medium risk) — 8 h
- Extract `booking_widget_error_screen.dart`, `booking_widget_overlays.dart`, `price_change_confirmation_dialog.dart`, `payment_delayed_dialog.dart`.
- Extract `booking_validation_orchestrator.dart` — async return-struct, no widget-state coupling.
- Smoke-test: load fresh page (slug + query-param URLs), trigger validation error, retry, see error screen.

### Phase 3: form / payment composers (medium risk) — 12 h
- Extract `guest_info_form_section.dart`, `payment_method_section.dart`, `floating_pill_bar.dart`, `booking_widget_calendar_section.dart`.
- Wire callbacks for `onConfirmPressed`, `onReserve`, `onPaymentMethodChanged`, `onRangeSelected`, `onTaxLegalAcceptedChanged`.
- Smoke-test FULL booking flow on web + iOS dev for all three modes (`bookingInstant`, `bookingPending`, `calendarOnly`) and all three payment methods. Verify min-nights validation still triggers, verify min-nights SnackBar.

### Phase 4: domain services for the submit pipeline (medium / blocking-adjacent) — 14 h
- Extract `pre_submit_price_revalidator.dart`, `booking_submit_orchestrator.dart`, `stripe_return_handler.dart`.
- Replace `_handleConfirmBooking` internals with a thin sequencer:
  1. validation → 2. price lock check → 3. revalidator → 4. dialog if changed → 5. orchestrator submit → 6. dispatch sealed result.
- Smoke: race-condition path (`BookingConflictException`), fresh-price mismatch path with €0.50+ delta dialog, anomaly-detection log path, Stripe return via session id + legacy bookingId.

### Phase 5: payment messaging + Stripe launcher (BLOCKING) — 18 h
- Extract `stripe_payment_launcher.dart` first (it's a leaf inside the cluster).
- Then `booking_payment_messaging_controller.dart` — consolidate 3 messaging surfaces behind `Stream<PaymentEvent>`.
- Reduce screen to pure orchestrator (≤300 LOC). Define exhaustive `PaymentEvent` union (`paymentComplete`, `popupClosed`, `timeoutFired`, `bookingCancelled`, `calendarRefresh`).
- Smoke: cross-browser matrix (Chrome desktop, Chrome iOS, Safari iOS, Safari macOS, iframe + standalone for each). 30s timeout edge cases. Popup blocked path. Mobile redirect path. PaymentBridge fallback path.

**Total estimate: 59 h (incl. Phase 0)**, ~1.5–2 weeks of focused effort. Phase 5 is the long pole — recommend a dedicated PR with browser-matrix screenshot evidence in `audit/screenshots/`.

---

## 7. Sibling-file overlap check

| Sibling | LOC | Status vs. proposed |
|---|---|---|
| `l10n/widget_translations.dart` | 5128 | Unaffected. Continues as source of truth for all translations. |
| `widgets/year_calendar_widget.dart` | 1034 | Unaffected. Sub-component of `LazyCalendarContainer`. Separate refactor target. |
| `widgets/month_calendar_widget.dart` | 918 | Same as above. |
| `providers/realtime_booking_calendar_provider.g.dart` | 858 | Generated. Unaffected. |
| `theme/minimalist_colors.dart` | 786 | Unaffected. |
| `providers/subdomain_provider.g.dart` | 735 | Generated. Unaffected. |
| `providers/widget_context_provider.g.dart` | 701 | Generated. Unaffected. |
| `widgets/email_verification_dialog.dart` | 686 | **Already extracted.** Proposed plan does NOT add a duplicate. Used by `_openVerificationDialog` which stays on screen. |
| `screens/booking_details_screen.dart` | 625 | Unrelated (booking-view subscreen). Unaffected. |
| `screens/booking_confirmation_screen.dart` | 526 | **Already extracted.** Plan does NOT propose a redundant `confirmation_screen.dart`. The two confirmation-display code paths inside the target file (`_navigateToConfirmationAndCleanup`, `_showConfirmationFromUrl`, and the Navigator.push inside `_handleStripeReturnWithSessionId`) all push to this existing screen — they are *callers*, not duplicates. Plan's `stripe_return_handler.dart` continues to push to it. |
| `theme/minimalist_theme.dart` | 501 | Unaffected. |
| `widgets/split_day_calendar_painter.dart` | 403 | Unaffected. |
| `providers/booking_price_provider.g.dart` | 381 | Generated. Unaffected. |
| `screens/booking_view_screen.dart` | 380 | Unrelated. Unaffected. |
| `state/booking_form_state.dart` (232 LOC, not in table) | 232 | **Existing class to be extended**, not duplicated. Promote to `ChangeNotifier`; add persistence factories. |
| `services/form_persistence_service.dart` | n/a | **Existing.** Stays as-is; `BookingFormState` will hold the `PersistedFormData` factory. |
| `domain/services/{booking_validation_service, booking_url_state_service, price_lock_service, calendar_data_service}.dart` | n/a | **Existing services.** Plan does NOT propose `helpers/validators.dart` — already covered. |
| `shared/utils/validators/form_validators.dart` | n/a | **Existing.** Validators live here; no new helper needed. |

**No duplicate creations.** Every proposed file either extracts code from the target file or extends one specific existing file (`BookingFormState`).

### Rules to preserve verbatim during extraction

1. `.claude/rules/widget.md`: 18 `} catch (_) {}` silent guards inside `// #region agent log` blocks are INTENTIONAL — keep them, or fold them into the Phase 0 `debug_log.dart` helper which itself wraps the catch internally.
2. `.claude/rules/widget.md`: host comparisons MUST use `EnvironmentConfig.{widgetHost, isMarketingHost, isWidgetHost}`. `_handleStripePayment` already does. The extracted `stripe_payment_launcher.dart` must keep this.
3. `CLAUDE.md` NIKADA NE MIJENJAJ: `Navigator.push` for confirmation (NOT state-based navigation). All three confirmation push sites use `Navigator.of(context).push(MaterialPageRoute(builder: ...))` and must continue to.
4. `CLAUDE.md` Critical Learning #5: providers with `keepAlive: true` must watch auth — `widgetContextProvider` uses `keepAlive`, hence `_retryValidation` invalidates it. The extracted `booking_validation_orchestrator.dart` must preserve the invalidation list verbatim.

---

## 8. Open questions / unknowns

1. **Is the agent-log instrumentation still active or is the debug session closed?** If closed, the 18 `// #region agent log` blocks can be deleted wholesale in Phase 0 — saves ~600 LOC and changes which methods qualify as primary extraction candidates. If still active, the Phase 0 helper consolidation is the right move. Needs product/eng owner sign-off before Phase 0 runs.

2. **Promote `BookingFormState` to `ChangeNotifier` vs. split into 4 domain-scoped notifiers?** Recommend the former for minimum churn — the existing class is already wired in via 20 delegating getters/setters; promoting it to `ChangeNotifier` lets composers `listen` to specific fields without re-architecting the file. Splitting into `DateSelectionNotifier / GuestInfoNotifier / PricingNotifier / StripePaymentNotifier` is cleaner long-term but doubles the Phase 3 surface.

3. **Is one canonical messaging path achievable, or are all three (BroadcastChannel + postMessage + PaymentBridge) required for browser-matrix coverage?** The four handlers (`_handleTabMessage`, `_handlePostMessage`, `_setupPaymentBridgeListener` callback, `_handlePaymentCompleteFromOtherTab`) all converge on `_handleStripeReturnWithSessionId`. Before Phase 5 collapses them into a single `Stream<PaymentEvent>`, need to confirm which surfaces are redundant on which browser/iframe combinations. Without that, the consolidation risks regressing Safari iOS or popup-blocked paths.

4. **`_buildGuestInfoForm` callback contract.** Invoked via `guestFormBuilder: () => _buildGuestInfoForm(calculation, showButton: false)` closure inside `PillBarContent`. Extraction needs: `formState` (the existing `BookingFormState`), `widgetSettings.emailConfig.requireEmailVerification`, `unit.maxGuests / petFee / maxPets`, `onTaxLegalAcceptedChanged(bool)`, `onConfirmPressed(BookingPriceCalculation)`, `onVerifyEmailPressed()`. Spell this out as the formal API in the implementation PR.

5. **`_handleConfirmBooking`'s inline price-revalidation block** does its own dialog. Should the dialog stay inline in the orchestrator method or live in the extracted `pre_submit_price_revalidator.dart`? Recommend: revalidator returns `PriceRevalidationResult` only (no UI); screen owns the dialog (uses extracted `price_change_confirmation_dialog.dart`). Cleaner separation.

6. **`_setDefaultPaymentMethod`** is called from both `_validateUnitAndProperty` (after data load) and `_loadFormData` (after restoring persisted form). If `booking_validation_orchestrator.dart` owns the first call site, who owns the second? Recommend: `BookingFormState.applyFromPersisted()` calls the same picker (move picker to `BookingFormState` as `pickDefaultPaymentMethod(settings)`).

7. **`_PoweredByBadge` link** points at `https://bookbed.io` — per `.claude/rules/widget.md` § "Hardcoded `bookbed.io` exceptions", this is NOT one of the listed exceptions. Should it be using `EnvironmentConfig.marketingHost` (or analogous)? Flag for clarification — the extraction PR should either preserve the literal or fix it; out of scope for this audit.

8. **The 30s `_paymentCompletionTimeout`** is set in 3 places and cancelled in 5 places. After consolidation into `BookingPaymentMessagingController`, the timeout becomes an internal detail. Confirm: does the timeout *also* need to fire `_resetFormState()` (it does today, line 1240–1244), or only `setState({_isProcessing: false})`? The form-reset side-effect must remain after extraction.

9. **Brief proposed `helpers/formatters.dart`.** Searched: no inline-formatter code in the target file beyond `WidgetTranslations.of(context, ref).currencySymbol` + `calculation.format*` methods (which live in `BookingPriceCalculation`). Recommendation: drop from plan — no formatters to extract.

10. **`web/bookbed-overlay.js` iframe overlay** (per `.claude/rules/widget.md` v8 pattern) is owned outside this Dart file. No refactor impact. Mentioned for completeness only.

---

**End of plan. No code changes proposed by this document. Decision points 1, 2, 3 (Section 8) should be answered before any code work begins.**
