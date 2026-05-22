# SF-024 — widget_settings.ical_cache_content PII Leak (HIGH)

**Datum**: 2026-05-22
**Branch**: `hotfix/widget-secrets-exfil`
**Commit**: `e30db9d1` (bundled — Option A iz Chrome regresijskog smoke-a, `audit/16-chrome-regression-full.md`)
**Status**: ✅ Code-complete; deploy gated na SF-021 prereqs (Resend rotacija + `ICAL_TOKEN_PEPPER` set u oba env-a)
**Prioritet**: 🔴 High

---

## Problem

`getUnitIcalFeed` CF cache iCal feeda (raw VCALENDAR blob — sadrži guest email, ime, check-in / check-out, total amount kroz `SUMMARY` i `DESCRIPTION` polja) je pisao na `properties/{pid}/widget_settings/{uid}.ical_cache_content`. `widget_settings` ima `allow read: if true` u `firestore.rules` (widget mora čitati theme / branding bez autha), pa je svaki cache hit izlagao do TTL-a (default 600s) cijelu bookings listu unit-a bilo kome s validnim Firebase API ključem:

```js
// Public Firebase API key (extracted from widget JS bundle):
firestore
  .collection('properties').doc('PID')
  .collection('widget_settings').doc('UID')
  .get()
  → data.ical_cache_content
    // BEGIN:VCALENDAR
    //   SUMMARY:guest@example.com / John Doe
    //   DTSTART:20260601 DTEND:20260605
    //   DESCRIPTION:Total: €420
    // END:VCALENDAR
```

ETag (`ical_cache_etag`) je content hash — nije sam po sebi PII, ali derivira iz blob-a i daje cache-busting signal. Ide u istu owner-only zonu.

Phase A4 hotfix (`hotfix/widget-secrets-exfil`, commit `49af1625`) je već rješavao iste pattern probleme za:

- `ical_export_token` — token leak omogućavao bilo kome export iCal feeda za bilo koji unit
- `email_config.resend_api_key` — Resend API key krađa

Cache blob je 3. faza istog leak vector-a (write-na-publicly-readable-doc). Bundle u isti hotfix umjesto novog branch-a je Option A iz `audit/16-chrome-regression-full.md` SF-024 decision.

---

## Rješenje

**Premjesti `ical_cache_content` + `ical_cache_etag` iz `widget_settings` u `widget_secrets` (owner-only); proširi `noSecretsInWidgetSettings` predikat da odbije ponovni write tih polja na widget_settings.**

### Zahvaćeni fajlovi (commit `e30db9d1`)

| Fajl | Promjena |
|---|---|
| `firestore.rules` | `noSecretsInWidgetSettings` predikat proširen (+`ical_cache_content`, +`ical_cache_etag`) |
| `functions/src/icalExport.ts` | Cache read/write split: secrets u `widget_secrets`, ne-tajni markeri (`unit_name`, `last_generated`) u `widget_settings` |
| `functions/scripts/hotfix-widget-secrets.js` | Phase A3 migracija proširena — povlači postojeći cache content + etag u `widget_secrets`, briše ih iz `widget_settings` |
| `functions/test/firestore_rules/widget_secrets.test.ts` | +6 novih test cases (3 deny na widget_settings, 1 allow na widget_secrets write, 1 owner read, 1 cross-owner deny) |

### Firestore rules — predikat proširen

```diff
  function noSecretsInWidgetSettings(data) {
-   return !data.keys().hasAny(['ical_export_token']) &&
+   return !data.keys().hasAny(['ical_export_token', 'ical_cache_content', 'ical_cache_etag']) &&
      (!data.keys().hasAny(['email_config']) ||
        !data.email_config.keys().hasAny(['resend_api_key']));
  }
```

### icalExport.ts — split read + split write

```diff
  // Read:
- const cachedContent = widgetSettings.ical_cache_content;
- const cachedAt = widgetSettings.ical_cache_generated_at?.toDate();
- const cachedETag = widgetSettings.ical_cache_etag;
+ const cachedContent =
+   widgetSecrets?.ical_cache_content ?? widgetSettings.ical_cache_content;
+ const cachedAt = (
+   widgetSecrets?.ical_cache_updated_at ?? widgetSettings.ical_cache_generated_at
+ )?.toDate();
+ const cachedETag =
+   widgetSecrets?.ical_cache_etag ?? widgetSettings.ical_cache_etag;

  // Write (after fresh generation):
- await widgetSettingsDoc.ref.update({
-   ical_export_last_generated: Timestamp.now(),
-   ical_cache_content: icalContent,
-   ical_cache_generated_at: Timestamp.now(),
-   ical_cache_etag: etag,
-   ical_cache_unit_name: unitName,
- });
+ const cacheTimestamp = Timestamp.now();
+ await Promise.all([
+   widgetSettingsDoc.ref.update({
+     ical_export_last_generated: cacheTimestamp,
+     ical_cache_unit_name: unitName,   // non-secret filename marker, kept
+   }),
+   widgetSecretsDoc.ref.set(
+     {
+       ical_cache_content: icalContent,
+       ical_cache_etag: etag,
+       ical_cache_updated_at: cacheTimestamp,
+     },
+     {merge: true},
+   ),
+ ]);
```

Fallback read na `widget_settings` ostavljen kao bridge dok migracija ne pretrči sve unit-e. Nakon backfill-a (Phase A3 + SF-024 produžetak) widget_settings.ical_cache_* polja više ne postoje na nijednom doc-u — fallback grane postaju dead code (uklonjive u zasebnom cleanup PR-u).

### Migration script — pokriva i cache fields

```diff
  // existing: resend_api_key + ical_export_token migration
+ const existingIcalCacheContent = settings.ical_cache_content || null;
+ const existingIcalCacheEtag = settings.ical_cache_etag || null;

  const secretsPayload = {
    // ... existing fields (resend_api_key, ical_export_token_hash, ...)
  };
+ if (existingIcalCacheContent) {
+   secretsPayload.ical_cache_content = existingIcalCacheContent;
+   secretsPayload.ical_cache_updated_at = admin.firestore.FieldValue.serverTimestamp();
+ }
+ if (existingIcalCacheEtag) {
+   secretsPayload.ical_cache_etag = existingIcalCacheEtag;
+ }

  const settingsUpdate = {
    ical_export_token: admin.firestore.FieldValue.delete(),
    'email_config.resend_api_key': admin.firestore.FieldValue.delete(),
+   ical_cache_content: admin.firestore.FieldValue.delete(),
+   ical_cache_etag: admin.firestore.FieldValue.delete(),
  };
```

Dry-run + migrated log line-ovi prošireni s `cache_content_present=<bool>` / `cache_etag_present=<bool>` flags za audit-trail u `audit/migrations/2026-05-18-widget-secrets-{project}.log`.

---

## Što JE i NIJE pokriveno

| Polje na `widget_settings` (publicly readable) | Pre-fix | Post-fix |
|---|---|---|
| `ical_export_token` (Phase A4) | ❌ leak | ✅ deny + moved to `widget_secrets` |
| `email_config.resend_api_key` (Phase A4) | ❌ leak | ✅ deny + moved to `widget_secrets` |
| `ical_cache_content` (SF-024) | ❌ leak (guest PII u VCALENDAR blob-u) | ✅ deny + moved to `widget_secrets` |
| `ical_cache_etag` (SF-024) | ❌ leak (cache-busting signal) | ✅ deny + moved to `widget_secrets` |
| `ical_cache_unit_name` | publicly readable | publicly readable (non-secret filename marker, kept) |
| `ical_export_last_generated` | publicly readable | publicly readable (timestamp marker, kept) |
| `ical_cache_generated_at` (legacy) | publicly readable | publicly readable za pre-migration docs; novi writes idu na `widget_secrets.ical_cache_updated_at` |

---

## Testiranje

### Rules tests — 28/28 green

`functions/test/firestore_rules/widget_secrets.test.ts`: 14 postojećih + 6 novih SF-024 cases = 20/20. `functions/test/firestore_rules/bookings.test.ts`: 8/8 (no change). Ukupno: 28/28.

```
$ cd functions && npm run test:rules
PASS test/firestore_rules/widget_secrets.test.ts
  widget_settings write rejects ical cache fields (SF-024)
    ✓ owner CANNOT update widget_settings.ical_cache_content
    ✓ owner CANNOT update widget_settings.ical_cache_etag
    ✓ owner CAN update widget_settings.ical_cache_unit_name (non-secret marker)
  widget_secrets accepts ical cache fields (SF-024)
    ✓ owner CAN write ical_cache_content to widget_secrets
    ✓ property owner CAN read own widget_secrets.ical_cache_content
    ✓ foreign owner CANNOT read foreign widget_secrets.ical_cache_content

Tests:       28 passed, 28 total
```

### Static checks

- `cd functions && npm run build` — `tsc` 0 errors
- `flutter analyze --no-pub` — 60 issues, identično pre-fix baseline-u (sve u `lib/features/owner_dashboard/presentation/widgets/{price_list_calendar_widget,quick_action_buttons}.dart`, nisu vezane uz SF-024 fix)

---

## Moguće nuspojave

- **Cache regen burst nakon deploy-a rules-a**: Postojeći cache na `widget_settings.ical_cache_content` postaje nedostupan trenutno kad rules zabrane new writes i CF stopa čitati iz starog mjesta. Prvi GET request po unit-u će promašiti cache i generirati blob. Time → do 30s po unit-u pod opterećenjem (ovisno o broju bookings + ical_events). Migration script carry-over-a postojeći blob u `widget_secrets` da izbjegne thundering herd ako se pokrene **PRIJE** deploy rules-a.
- **Read fallback ostaje na `widget_settings` dok backfill ne pretrči**: ako CF deploya prije migration script-a, novi writes idu na `widget_secrets` ali stari cached blob na `widget_settings` može još uvijek poslužiti (oba reads-a u Promise.all). Idealan poredak: migration → CF deploy → rules deploy (rules zadnje, ista sekvenca kao SF-019).
- **`ical_cache_generated_at` legacy field**: ostaje na widget_settings docs koji nisu migrirani. Rules ne zabranjuju to polje (samo content + etag — content je payload, etag derivira iz njega, generated_at je samo timestamp i nije sigurnosno relevantan). Backfill ga ne briše. Eventualni cleanup PR može ga ukloniti zajedno s fallback granama.
- **`widget_secretsDoc.ref.set(...)` u `Promise.all`**: Ako `widget_secrets/{unitId}` ne postoji (npr. unit nije migriran i nikad nije imao iCal token), CF se sada oslanja na `set({...}, {merge: true})` da kreira doc. To traži da rules `match /widget_secrets/{unitId}` dopuste create iz Admin SDK — što one rade jer Admin SDK bypasses rules potpuno. Provjereno.

---

## Deploy sekvenca (NE pokrenuto)

```
PREREQ (SF-021):
  1. Resend rotacija per-env (CSV map ownerId → new_api_key)
  2. ICAL_TOKEN_PEPPER vrijednost generirana i upload-ovana u Secret Manager:
       firebase functions:secrets:set ICAL_TOKEN_PEPPER --project bookbed-dev
       firebase functions:secrets:set ICAL_TOKEN_PEPPER --project rab-booking-248fc

DEPLOY (dev first, prod tek nakon manualne validacije):
  1. ICAL_TOKEN_PEPPER=$(cat /tmp/pepper) RESEND_CSV=/tmp/csv \
       node functions/scripts/hotfix-widget-secrets.js \
       --project bookbed-dev --dry-run
  2. (verify dry-run log) → re-run bez --dry-run
  3. cd functions && npm run deploy --project bookbed-dev
  4. firebase deploy --only firestore:rules --project bookbed-dev
  5. Manual smoke: open widget-dev, trigger iCal export, verify VCALENDAR generates fresh + cache lands in widget_secrets (not widget_settings)

PROD CUTOVER (after dev validation):
  Repeat 1-5 with --project rab-booking-248fc.
```

---

## Povezani artefakti

- **Code commit**: `e30db9d1` na `hotfix/widget-secrets-exfil` ("fix(security): SF-024 bundle ical_cache into widget_secrets migration")
- **Phase A4 predecessor commit**: `49af1625` na istom branch-u ("fix(security): finalize widget_secrets rules + sendOwnerEmail CF (Phase A code-complete)")
- **Decision source**: `audit/16-chrome-regression-full.md` (na main branchu kao untracked tijekom development-a) — Option A "bundle into existing hotfix branch"
- **Deploy prereqs memory**: `memory/widget-secrets-exfil-deploy-prereqs.md` — Resend rotation + ICAL_TOKEN_PEPPER setup
- **Existing SF entries pattern**: `docs/SECURITY_FIXES.md` SF-019 (multi-clause public-read close) je analogon ovog fix-a — ista write-on-publicly-readable-doc klasa vektor-a, ista deploy choreography (rules deploy zadnje)
- **Phase A predecessor docs**: SF-021 entry na main branch-u (concurrent dev) dokumentira `ical_export_token` + `resend_api_key` premještanje. SF-024 je 3. faza istog rollout-a.
