# audit/24 — P3 backlog investigations

**Date:** 2026-05-23
**Scope:** Three P3 items carried forward from `audit/21` §Outstanding "P3 backlog".
**Mode:** Doc only — no code or config touched.

Each item documents: current state, recommended action, risk, effort. Final section reconsiders priority.

---

## 1. `getUnitIcalFeed` region drift

### Current state

`functions/src/icalExport.ts:92` declares the handler with a bare `onRequest`:

```typescript
export const getUnitIcalFeed = onRequest(async (request, response) => {
```

No `region: "europe-west1"` option is set. Firebase Functions v2 default region is **`us-central1`**. The deployed function therefore runs in us-central1 for both `bookbed-dev` and prod (`rab-booking-248fc`).

**Re docstring claim:** audit/21 §Observations describes a "docstring claims `europe-west1`" drift. Re-reading lines 78–91 of `icalExport.ts`, the docstring does NOT explicitly claim a region — it lists supported clients (Google/Apple/Outlook) but is silent on deployment region. The real drift is between the deployed region and the latency-optimal region per `.claude/rules/cloud-functions.md` §"Region split" + `audit/11-cloudfunctions-inventory.md`, which call out `getUnitIcalFeed` among the EU-hot-path callables still in us-central1 (+~120ms RTT per EU caller).

In other words: there is no docstring to fix. The audit/21 framing of this as a doc-vs-deploy mismatch is inaccurate; it is purely a runtime-region question.

### Recommended action

**Option B (pin region to `europe-west1`)** is the substantive fix. Option A (a doc-only annotation) does not exist as a meaningful repair because no contrary docstring exists today. Option A only makes sense as a *defensive* annotation if we deliberately keep us-central1 — e.g., to document why.

Two sub-paths for B:

| Sub-path | Description | Trade-off |
|---|---|---|
| **B1: redeploy in-place** | Add `{region: "europe-west1"}` to `onRequest`, redeploy. CF region is **immutable** post-create — Firebase will refuse or create a parallel deployment. | iCal subscribers (Google/Apple/Outlook) hold the existing us-central1 URL. Changing the URL invalidates every owner's published feed in every external calendar. **Unacceptable.** |
| **B2: dual-deploy + cutover** | Deploy `getUnitIcalFeed` to europe-west1 in parallel with the existing us-central1 instance. Update `EnvironmentConfig.functionsBaseUrl` mapping to new region for newly-issued URLs. Old URLs continue to resolve to us-central1 indefinitely (or behind a redirect proxy). | Long migration tail (years). Operationally expensive — two functions to maintain. Marginal user benefit per call. |

### Performance impact

- Per call: ~120ms RTT delta for EU clients (Croatia → us-central1 vs Croatia → europe-west1), corroborated by `audit/11-cloudfunctions-inventory.md` P3 latency entry.
- Cadence: external calendars poll the iCal URL on their own schedule. Google Calendar polls 12–24h; Apple Calendar 15min–6h; Outlook 1–3h. Owners do not interactively wait on iCal latency — it is background sync.
- Therefore: the +120ms is **invisible to humans** on this specific endpoint. Materially different from `getUnitAvailability` (interactive widget calendar) or `createBookingAtomic` (interactive checkout) — both also us-central1 per `audit/11`, both with the same 120ms cost but on human-perceptible paths.

### Recommendation

**Hold (do nothing) for now.** Background-polled iCal endpoint does not justify B2's migration complexity. Reframe the audit/21 line item as "no action — latency cost is invisible." If/when a broader us-central1 → europe-west1 migration is planned (per `audit/11` P3), include `getUnitIcalFeed` in that sweep; otherwise leave it.

Optionally add a one-line code comment near the `onRequest` declaration noting the deliberate choice, to prevent future "let's fix this" cycles.

| Field | Value |
|---|---|
| Risk | Very low — no behavior change |
| Effort | 1 line comment if added; 0 otherwise |
| Priority adjustment | **Demote to "won't fix" / informational** — close item |

---

## 2. `getUnitAvailability` `logWarn` on unknown unit

### Current state

`functions/src/availability.ts:113-236` is a callable CF returning `{unitId, windows, generatedAt, cacheHint}` for the widget calendar.

The function performs **no existence check** on `unitId`. It runs three parallel `collectionGroup` queries (`bookings`, `daily_prices`, `ical_events`) all keyed by `where("unit_id", "==", unitId)`. If the unitId is bogus (non-existent or malformed-but-passes-string-validation):

- All three queries return 0 docs.
- `windows: []` is returned with HTTP 200.
- `logInfo("[GetUnitAvailability] Served availability", {unitId, propertyId, windowCount: 0, ...})` fires — same log line as a legitimate empty-window response for a real unit with no upcoming bookings.

**Fail class.** This is **fail-OPEN** by appearance (200 OK / no blocks). Per `audit/21` defense-in-depth matrix, the *write* path is still gated: `atomicBooking.ts:743` performs an independent overlap check, and `widget_settings` token lookup gates any actual booking write. So an attacker scanning unit IDs cannot create bookings against fake units. But they CAN scan the keyspace cheaply, and abuse is undetectable in logs because empty-windows responses are indistinguishable from "valid quiet unit."

### Where to add the warn

Two viable insertion points:

| Location | Lines | Mechanism |
|---|---|---|
| **Inside `try`, after all three `.get()` resolve, before the `for` loops** | After `availability.ts:172` | Check `propertyId` doc exists, OR check that the requested `unitId` exists under that property. If not, emit warn + return early `windows: []`. |
| **Cheaper alternative**: only check `propertyId` doc | After parsing input, before parallel queries | Saves the three CG queries for bogus IDs. Slightly different semantics — bogus propertyId errors, bogus unitId still 0-result. |

The cheap version is more attack-cost-effective (denies the keyspace scan), but adds a Firestore read on the legitimate hot path. Given `maxInstances: 50` and the cache hint of 30s, the legitimate hot-path overhead is acceptable.

### Sample structured warn line

Following `.claude/rules/cloud-functions.md` `logWarn` conventions:

```typescript
import {getClientIp, hashIp} from "./utils/ipUtils";

// after Promise.all returns
if (bookingsSnap.empty && pricesSnap.empty && icalSnap.empty) {
  const propertyDoc = await db.collection("properties").doc(propertyId).get();
  if (!propertyDoc.exists) {
    logWarn("[GetUnitAvailability] Unknown property/unit lookup", {
      propertyId,
      unitId,
      ipHash: hashIp(getClientIp(request)),
      timestamp: new Date().toISOString(),
      userAgent: (request.rawRequest?.headers?.["user-agent"] as string)?.slice(0, 120) ?? "n/a",
    });
  }
}
```

Note: `ipHash` not raw IP — matches the rate-limit convention already in use (`availability.ts:139`). User-agent truncated to 120 chars to bound log payload size.

### Rate-limit consideration

A keyspace scan could trip up to **30 unique unitId requests/min/IP** before the in-memory rate limit (`avail:${unitId}:${ipKey}` window of 30 req/60s) fires. With a single attacker probing many unit IDs, each unique unitId resets the key — meaning the rate limit is effectively **per-unitId** not per-attacker. A scan of 1000 fake unitIds at 1 req/sec evades the limit entirely.

To avoid drowning Cloud Logging on a scan attack, add a **second in-memory counter** keyed only on `ipKey`:

```typescript
// Only warn once per IP per hour for unknown-unit attempts
if (!checkRateLimit(`avail_unknown_warn:${ipKey}`, 1, 3600)) {
  // suppress — already warned this IP recently
} else {
  logWarn(...);
}
```

This keeps Cloud Logging volume bounded at ≤1 unknown-unit warn per IP per hour, while still surfacing the abuser's hashed IP. Pair with an alerting rule on `severity=WARNING AND jsonPayload.message:"Unknown property/unit lookup"` to make abuse actionable.

### Recommendation

Implement. Use the cheap (property-doc-only) variant + per-IP warn-rate-limit. Small surface, no functional change for valid traffic, closes a real abuse-detection gap.

| Field | Value |
|---|---|
| Risk | Low — adds one Firestore read on cold/cache-miss requests; no behavior change for valid traffic |
| Effort | ~30 minutes including deploy + log-based metric alert wiring |
| Priority adjustment | **Promote P3 → P2.** Abuse-detection gap on a public endpoint is more than cosmetic. Already flagged P2 in audit/21 §Observations table; the P3 entry in §Outstanding is the inconsistency. |

---

## 3. `.claude/rules/hosting-build.md` `--release`-only rule re-verify

### Current state

`.claude/rules/hosting-build.md:134-137` says:

> ### Android Debug Build Bug
> **Problem**: `firebase_storage` plugin ne kompajlira Kotlin kod prije Java koda u debug modu.
> **Workaround**: Koristi `--release` flag za Android uređaje.

Mirrored at the build-mode table (lines 108–113) and run-instructions (line 163: `flutter run -d <ANDROID_DEVICE_ID> --release`).

Per `audit/21` §Observations: Terminal E built `assembleDebug` successfully in **37.9 seconds** against Flutter 3.38.5 on Pixel_8 emulator. No firebase_storage compile-order error. This **contradicts** the rule's stated workaround necessity.

### Git blame on origin

The `--release`-only rule **predates** the AAB section. `git log` on the file shows the AAB section landed in `6ae3ecb2` (2026-05-22), but the firebase_storage entry appears in earlier revisions and is grandfathered. There is no commit message that surfaces a specific firebase_storage version OR Kotlin version that triggered the failure originally. The rule documents the symptom (Kotlin-before-Java compile-order mismatch) without naming the package version that introduced it. Likely sources of the original fix:

- Old `firebase_storage` 11.x / 12.x with Kotlin 1.9.x — known Gradle plugin-ordering issues on certain AGP versions.
- A specific local toolchain combo that has since been silently fixed upstream.

Current pin: `flutter_riverpod ^2.5.1`, `freezed ^2.5.7`. `firebase_storage` not pinned in CLAUDE.md — current `pubspec.lock` resolution likely has a newer patch.

### Why the rule may still be valid

Three reasons NOT to declare the bug fixed:

1. **One green build ≠ permanent fix.** Plugin compile-order bugs are notoriously order-of-Gradle-invocation-sensitive. Terminal E's success in a clean worktree on a single device does not generalize.
2. **The rule is cheap insurance.** `--release` on Android during dev costs Hot Reload (significant) but does not break workflows. The cost of one developer hitting a build failure they can't diagnose >> the cost of using `--release`.
3. **Edge-case recurrence.** A future `firebase_storage` or AGP/Kotlin bump could resurrect the bug. Removing the rule then forces re-investigation.

### Test plan to verify safely

To re-verify on a PROD-shape device without risking PROD contamination:

```bash
# 1. Isolate to a git worktree to keep main clean
git worktree add -b experiment/android-debug-reverify ../bookbed-debug-reverify

# 2. In the worktree, swap to dev google-services.json
cd ../bookbed-debug-reverify
cp android/app/google-services.json.backup android/app/google-services.json
grep project_id android/app/google-services.json
#   expect: "project_id": "bookbed-dev"

# 3. Try assembleDebug on three combinations
flutter clean
flutter pub get
# (a) main entrypoint
flutter run -d <android-id> --target lib/main_dev.dart
# (b) widget entrypoint
flutter run -d <android-id> --target lib/widget_main_dev.dart
# (c) Trigger a hot reload (the actual reason --release breaks the workflow)
#     Edit any lib/**/*.dart file, save, observe whether hot reload fires.

# 4. Tear down worktree (no commit to main)
cd /Users/duskolicanin/git/bookbed
git worktree remove ../bookbed-debug-reverify
```

Pass criteria: all three steps complete (build, run, hot-reload). One failure → keep rule.

Suggested matrix to harden the verification (do once, not per-developer):

| Device | Flutter ver | Kotlin ver | AGP ver | Result |
|---|---|---|---|---|
| Pixel_8 emulator | 3.38.5 | 2.1.0 | 8.9.1 | Terminal E says PASS |
| Pixel_8 emulator | 3.38.5 | 2.1.0 | 8.9.1 | (repeat — sanity) |
| Physical mid-range device | 3.38.5 | 2.1.0 | 8.9.1 | TBD |
| Pixel_8 emulator | next-Flutter | 2.1.0 | 8.9.1 | TBD on next bump |

### Recommendation

**Keep the rule as-is, soften the prose.** Replace the absolute "MORA biti release" with a conditional:

> Default to `--release` on Android for safety. Debug builds are known to fail on certain `firebase_storage` / Kotlin / AGP combinations (root cause: Kotlin-before-Java compile order). If `assembleDebug` works in your environment, you can use it — but treat any new build failure as "first try `--release`." Hot Reload is the trade-off.

No code change, no deploy, no behavior change. Documentation-only edit.

**Do NOT remove the rule.** The cost is low; the savings on a future incident is high. The rule is a memo, not a CI gate.

| Field | Value |
|---|---|
| Risk | Very low — doc edit only |
| Effort | 5 minutes — one paragraph rewrite |
| Priority adjustment | **Stay P3.** No urgency; tighten the next time someone touches the file. |

---

## Should any of these promote to P1/P2?

**Yes, one:** §2 (`getUnitAvailability` unknown-unit `logWarn`) is materially more important than its P3 categorization suggests, and is already inconsistently flagged P2 in `audit/21` §Observations. The keyspace-scan abuse-detection gap is not security-critical (write path is gated separately) but is the kind of thing that, once an attacker is operating against the system, leaves zero forensic trail. **Promote to P2** with the rate-limited warn implementation above.

**No** for the other two:

- §1 (`getUnitIcalFeed` region) — **demote to "won't fix" / informational**. Background-polled endpoint; +120ms invisible to humans; migration cost (dual-deploy long-tail) >> benefit. Roll into a broader region migration if/when planned.
- §3 (`--release` rule) — **stay P3**. One successful debug build is weak evidence against a stated workaround for an intermittent compile-order bug. Cheap insurance; soften prose next pass.

### Net effect on audit/21 §Outstanding "P3 backlog"

| Original | After this audit |
|---|---|
| getUnitIcalFeed region drift (P3) | Closed — informational; no action |
| getUnitAvailability logWarn unknown unit (P3) | **Promoted to P2**; implementation sketch above |
| hosting-build.md --release rule (P3) | Remains P3; prose softening queued |
| Dependabot #242 package_info_plus (P3) | Untouched — out of scope this audit |

---

## See also

- `audit/11-cloudfunctions-inventory.md` §"Region split" — latency cost of us-central1 EU hot paths
- `audit/21-sprint-summary-2026-05-22-23.md` §Observations + §"P3 backlog"
- `.claude/rules/cloud-functions.md` §"Region split" + §"Logging" — `logWarn` conventions
- `.claude/rules/hosting-build.md` §"Android Debug Build Bug"
- `functions/src/availability.ts:113-236` — getUnitAvailability handler
- `functions/src/icalExport.ts:92` — getUnitIcalFeed bare onRequest
- `functions/src/atomicBooking.ts:743` — server-side overlap-check defense layer
