# REMEDIATION PLAN — vizuelni upgrade svih ekrana, BEZ diranja backenda
(izveden iz FINDINGS.md — 48 ekrana + primitivi; komponentna faza još dopunjava nalaze)

## 0. PRAVILA SIGURNOSTI — VAŽE ZA SVAKI TASK
1. **Svaki PR = vlastiti worktree + branch** (nikad shared main; CLAUDE.md protokol).
2. **NE DIRATI backend povrsine:** `functions/**`, `firestore.rules`, provideri/notifieri (osim čitanja), repozitoriji, modeli, bilo koji `ref.read/watch` graf. Vizuelni taskovi mijenjaju SAMO widget/build kod, tokene i ARB stringove.
3. **FROZEN zone (CLAUDE.md tabela):** Cjenovnik tab content, Unit Wizard publish (2-doc write), Timeline dimenzije/z-order, Calendar Repository, atomicBooking owner-email, Navigator.push confirmation, subdomain regex, widget App Check OFF. Fixevi SMIJU dodavati Semantics/chrome OKO frozen sadržaja, NIKAD mijenjati sam sadržaj/logiku.
4. **Verifikacija po tasku (obavezno, tim redom):**
   - `flutter analyze` = 0 net-new
   - ciljani test za task (RED→GREEN seam gdje fix mijenja ponašanje)
   - puni suite (baseline: 1945/1945)
   - golden testovi gdje postoje (20 dark + ostali) — pixel-diff smije se promijeniti SAMO namjerno; svaka namjerna promjena = regenerisan golden u istom PR-u s obrazloženjem
   - `dart format .`
   - live eyeball dev build light+dark (recipe: memory `pregled-live-fidelity-verification-recipe`)
5. **Seam-test pravilo:** seam test dokazuje funkciju, NE wiring — za svaki novi param/widget provjeri ŽIVI call site (memory `seam-test-proves-fn-not-wiring`).
6. **"Fix ne zatvara klasu"** — poslije svakog root-fixa pokreni grep za braću (pouka ×4 iz hunt-loga).
7. Dark mod se testira SVAKI put (audit/127 ladder); kontrast računati, ne procjenjivati (#951 metod).
8. Deploy NIJE dio ovih taskova (dev-first pravilo; PROD batch tek na GO).

## SKILL MAPA (koji skill za koju fazu)
| Faza | Skill(ovi) |
|---|---|
| 1 dead-code | ručno + `/code-review` na PR |
| 2 primitive roots | `/harden` (a11y), `/adapt` (tap targeti), `/normalize` (API/tokeni) |
| 3 boje/kontrast | `/colorize` + `/normalize`; verifikacija matricom (#951) |
| 4 real bugovi | `/harden`; `/verify` za live provjeru |
| 5 per-screen | `/normalize` → `/adapt` → `/polish`; `/distill` gdje ima šuma; `/critique` prije/poslije za 3 najgora ekrana |
| 6 l10n/validatori | `/normalize`; pattern #943 (kod→prevod) |
| 7 završno | `/audit` re-run (score prije/poslije), `/polish`, `/code-review` |

---

## FAZA 1 — BRISANJE MRTVOG KODA (nula vizuelnog rizika, čisti teren)
Jedan PR. Svaki fajl potvrđen 0 callera u auditu; prije `rm` ponovo `grep -rn "<ClassName>" lib/ test/`.
- `lib/shared/widgets/`: `bookbed_logo.dart`, `button.dart` (PremiumButton), `gradient_button.dart`, `deferred_loader.dart`, `debounced_search_field.dart`, `error_state_widget.dart`, `loading_overlay.dart`, `login_loading_overlay.dart`, `adaptive_layout.dart`, `buttons/accessible_icon_button.dart` (slabiji duplikat), `smart_tooltip`-NE (živ)
- `lib/shared/widgets/animations/`: `animated_button.dart`, `animated_card.dart`, `animated_dialog.dart`, `animated_success.dart`, `StaggeredEmptyState` (klasa u animated_empty_state)
- `lib/core/widgets/bb_*.dart` — CIJELI SET (BBButton/BBCard/BBChip/BBEmptyState/BBInput*/BBSectionHeader/BBSkeleton/BBStatusBadge/bb_avatar/bb_bottom_sheet) — *BBInput tek NAKON backporta paramsa (Faza 2.1); gallery/probe ekrani se migriraju na Bb* u istom PR-u
- `card.dart` (PremiumCard): prvo migrirati 2 callera (`revenue_chart_widget:40`, `unit_hub_empty_state:155`) na BbCard, pa obrisati (ubija i glass API)
- barrel čišćenje: `widgets.dart` linije 10/16/20; `animations.dart` linije 6/7/9/11
- Verifikacija: analyze 0 + puni suite + `flutter build web` (dead-code delete ne smije promijeniti nijedan piksel).

## FAZA 2 — PRIMITIVE ROOT FIXEVI (1 fajl = fix na svim ekranima)
Svaki task = zaseban mali PR s vlastitim testom. Redoslijed po dosegu:

**2.1 BbInput — NAJVEĆI ROOT (90 call siteova)** — `redesign/bb_input.dart`
- Backportuj iz mrtvog `core/BBInput`: `textInputAction`, `focusNode` (external, dispose samo ako interno kreiran), `autofocus`; dodaj `autofillHints`, `textCapitalization`, `required` indikator.
- Poveži `label` → `InputDecoration.labelText` (SR asocijacija); `trailingAction` u `SizedBox(48×48)`; guard `_onText` listener na `charLimit != null`; `didUpdateWidget` za controller swap.
- SVE aditivno (nullable params, defaulti = današnje ponašanje) → nijedan postojeći call site se ne mijenja, nula vizuelne promjene.
- Test: widget test za chain (next→focus), autofill hints prisutni, stale-controller test. Pa zasebni mali PR-ovi koji URULJAJU chain u forme: login, register, forgot, bank, change-password, property_form, unit_form, wizard steps, widget_settings (svaki ekran = 5-min diff, `textInputAction`+`onFieldSubmitted`).

**2.2 BbButton** — `redesign/bb_button.dart:73`
- `sm` 36→44 min-height (ili minConstraints 44 uz vizuelnih 36 — odluka: hit-area expansion, vizuelno netaknuto = nula pixel diffa); `asIcon` minConstraints 44×44; loading: `Semantics(hint)` + `ExcludeSemantics` oko spinnera; assert(label!=null || asIcon).
- Golden check na 62 call sitea (goldeni pokazuju hoće li se išta pomjeriti; hit-area varijanta = 0 promjena).

**2.3 BbChip** — `redesign/bb_chip.dart`
- `Semantics(label,button:true,selected:)`; minHeight 48 hit-area; `BBShadow.purpleGlow(context)` umjesto light-only; fiksna visina → minHeight (text-scale).

**2.4 BbIcon** — `redesign/bb_icon.dart`
- Dodaj `semanticLabel` param; `null` = `ExcludeSemantics` wrap (dekorativni default). Static cache za `_resolve`. Aditivno — svi calleri odmah dobiju tihi ispravni default.

**2.5 BbSectionHeader** — `redesign/bb_section_header.dart:47`
- `Semantics(header:true)` oko title; akcija: `Semantics(button)+minHeight44`. Jedan wrap = svih 34 call sitea (legal, settings, about...).

**2.6 BbCard** — `redesign/bb_card.dart`
- `excludeSemantics` param (rješava double-read u notifications); `container:true` kad nije interaktivan; static `Matrix4.identity`.

**2.7 BbCheckbox / BbRadio / BbSwitch** (ista klasa)
- minWidth 44/48; `excludeSemantics:true` na vanjski Semantics (double-read); radio: `inMutuallyExclusiveGroup+checked`; switch: keyboard toggle (Space/Enter); subtitle u semantic label.

**2.8 BbSpinner** — `ExcludeSemantics` default + opt-in `semanticsLabel` liveRegion.

**2.9 CommonAppBar** — `common_app_bar.dart`
- `leadingTooltip` nullable param (l10n) umjesto hardcoded EN 'Menu'; `title` → nullable uz assert. ~40 ekrana pokriveno.

**2.10 PremiumListTile** — makni `dense+VisualDensity(-1)` → minHeight 48; chevron samo kad `onTap!=null`; `ListTile.enabled` umjesto Opacity. (profil hub klaster)

**2.11 Loader barijera (universal_loader + global_navigation_loader)**
- `Semantics(liveRegion,label)` na overlay + `ExcludeSemantics(excluding:isLoading)` na blokirani child; CPI `semanticsLabel`.

**2.12 BbDialog** — `Dialog.semanticsLabel=title` + `Semantics(header:true)` titula; opcioni `bodyWidget` slot (ubija razlog za raw AlertDialog).

## FAZA 3 — KONTRAST / TOKENI / FLAT-CHROME (vizuelno NAMJERNE promjene)
Jedan PR po stavci; svaka mijenja piksele → golden regen + light/dark eyeball obavezni.
- **3.1 Widget status boje (gost!):** `minimalist_colors` success `#10B981`→emerald600 `#059669` ZA TEKST (ikone/tintovi ostaju); warning `#F59E0B`→`#B45309`; textTertiary `#999999`→`#767676`. Test = kontrast matrica (#951 stil).
- **3.2 Status badge:** `statusImported` deep token; completed-dark / pending-light korekcije (redesign/bb_status_badge). + non-exhaustive `_toBbStatus` fix (owner_booking_detail:1073 — dodaj imported case).
- **3.3 `BBColorSet.onPrimary`** novi token (= Colors.white danas) + sweep zamjena raw `Colors.white`-on-primary (chip/avatar/logo/wizard/notifications/pricing...). Vizuelno neutralno (ista vrijednost) → bez rendera (memory `skip-render-for-neutral-hygiene-changes`).
- **3.4 `textTertiaryLight` na bijelom** — odluka: bump tokena ILI per-site `textSecondary` (notification_settings ×3, legal date stamp, avatar_slot). Preporuka: per-site (manji blast).
- **3.5 `BbAdminDarkTokens.textTertiary`** `0x66FFFFFF`→izračunati minimum za `#2A2342` (klasa #951, admin nikad pokriven).
- **3.6 FLAT-CHROME regresije (ukloni gradijente):** profile_screen heroGradient×4 → solid primary; profile_image_picker diagonal → flat; unit_pricing Save `GradientTokens.brandPrimary` → `colorScheme.primary`; bb_logo `useGradient` default → false (call siteovi s default=true: about/admin_login/sidebar — eyeball poslije). Svaki uz screenshot prije/poslije.
- **3.7 Stale "TIP-1 diagonal gradient" docstringovi** → "FLAT (CHANGELOG 7.23)" (unit_form:548, step_4_review:381, widget_settings_section:9, property_form:277,682). Doc-only.
- **3.8 Skeleton dark ladder:** SkeletonColors → `#1E1E1E/#2A2A2A/#333333`; StatsCardsSkeleton light-only refs → theme-aware; + `shrinkWrap/physics` na 2 unbounded ListView-a (real crash-guard).

## FAZA 4 — REALNI BUGOVI (mali, izolovani, UI-wiring — backend netaknut)
- **4.1 P0 owner_booking_detail:682** `_RoundIconButton` → InkWell(onTap:onPressed) + 44px (mail/call dugmad rade).
- **4.2 unit_form trio:** `double.tryParse` area (crash); `_selectedAmenities` restore u `_loadUnitData` (silent wipe); image-upload no-op → MINIMALNO: sakrij picker dok upload ne postoji ILI implementiraj upload (odluka operatora — data-honesty).
- **4.3 subscription:** "Usporedi" TapGestureRecognizer; "Zadrži besplatno" no-op → wire ili ukloni.
- **4.4 booking_confirmation:** copy dugme wire (`Clipboard.setData`) + 44px; resend tap-area.
- **4.5 logout_tile:** BbDialog confirm prije `onLogout`.
- **4.6 smart_tooltip:** `as EdgeInsets` → `.resolve(TextDirection.ltr)`.
- **4.7 offline_indicator:** liveRegion + side-efekti van build().
- **4.8 owner_bookings _RezAINudge:** no-op dugmad — wire ili ukloni do featurea.
- **4.9 email_verification:** timer cancel na paused; RepaintBoundary na BackdropFilter.
- **4.10 tax_legal ExpansionTile controller** (ostaje otvoren poslije disable).
Svaki: RED→GREEN test + live check (`/verify`).

## FAZA 5 — PER-SCREEN VIZUELNI PASSOVI (klasteri; punch-liste iz FINDINGS.md)
Svaki ekran: primijeniti fazu-2/3 ostatke + vlastite stavke. NE dirati state logiku. Redoslijed: najgori score prvi.

**5A. Kalendari (najniži scorovi; FROZEN-gusto — samo chrome!)**
- `month_calendar` (10/20): weekend #FFB84D→AA varijanta; FAB Semantics; legend badge boje; portrait-lock samo mobile; day-cell Semantics wrap; state mutation van build. NE dirati z-order/turnover.
- `owner_timeline_calendar` (12/20): ukloni dupli setState (410-423); ref.listen van build; FAB+unit-cell+date-header Semantics; `Colors.red.shade700`→token; `as dynamic` cast → GlobalKey API. NE dirati timeline_dimensions/repo.
- `unit_pricing` (11/20): textInputAction ×3; CalendarDayCell Semantics WRAP (aditivno oko FROZEN grida); Save flat (3.6); "base" label l10n.
**5B. Admin (dark konzola)**
- `activity_log` (10/20): Semantics na event kartice; dark-lift boje; `toLocal()`; maxWidth const. (paginacija = backend → SAMO zabilježi, ne diraj)
- `user_detail` (12/20): copy 44px; breakpoint 900→600/1200; spacing tokeni; skeleton umjesto '...'.
- `users_list` (14/20): SelectableText→Text u DataCell (vraća row-tap); date-picker dark theme; card semanticLabel.
- `admin_shell/login/dashboard`: nav Semantics(selected); Sign Out 44px; ThemeData cache; env-pill dark boje; checkbox role; KPI tooltipi.
**5C. Auth**
- `enhanced_login` (11/20): toggle 44px; chain (2.1); footer linkovi Semantics+44px; pitch panel padding responsive; TextStyle→BBType; hero-metrike → realne vrijednosti ili ukloni (odluka).
- `enhanced_register` (12/20): checkbox label-tap (2.7); legal prefix dupli string fix; validator overload → l10n put (#943); RichText link fokusabilan.
- `forgot_password` (13/20): ukloni BackdropFilter blur (glass) ILI zadrži uz RepaintBoundary (odluka — auth hero exception postoji); dupli error feedback ukloni.
- `email_verification` (12/20): 4.9 + liveRegion countdown + Semantics chip.
- legal trio (15-16/20): FAB semanticLabel (jedan helper); ToC pointer+44px; heading h1→h2→h3; eyebrow l10n; DateTime.now→const datum.
**5D. Owner forme** — `property_form` (BB-token migracija cijelog fajla — najveći pojedinačni; loading overlay→BbCard+ExcludeSemantics), `unit_form` (4.2 + delete dugmad 44px+label + docstring), `bank_account` (breakpoint 1024→1200; chain; icon Semantics), `change_password` (strength meter liveRegion; autofill (2.1); withValues fix), `edit_profile` (error→generic; avatar label l10n; nested setState).
**5E. Owner settings/guides/profil** — profile (12/20): heroGradient (3.6) + stat-strip l10n + support email const + verify chipovi Semantics; notification_settings (15/20): eyebrow AA + quiet-time 44px + timePicker helpText; notifications (15/20): dot ExcludeSemantics + double-read (2.6) + scrim token + FAB padding; widget_settings (11/20): part-fajlovi BB-token migracija + swatch Semantics + slider semanticFormatterCallback + breakpoint 600→1200; widget_advanced (12/20): kartice tokeni + Switch MergeSemantics + maxWidth 720; iCal ekrani (12-13/20): status l10n + dot + breakpoint 900→1200 + eager map→builder; guides/faq/about/ai (13-16/20): copy dugmad tooltip+44px; BbChip (2.3); send tooltip; hero ExcludeSemantics; keyboard-fix mixin na AI composer; _ContactRow cijeli red tappable.
**5F. Widget (gost — najviši prioritet kvaliteta)** — booking_widget (13/20): breakpoint 1024→1200 ×4; confirm dugme ekstrakt (dupli blok); backdrop Semantics; hex→tokeni; pill bar 320px; booking_details/view (13/20): status boje (3.1/3.2) + header Flexible @320 + language button label + flag fallback + Tooltip-on-disabled alternativa; booking_confirmation (12/20): 4.4 + elasticOut→easeOutBack + legacy tokeni + isDarkMode thread; subdomain_not_found (16/20): header:true + maxLines; not_found (14/20): CommonAppBar + tokeni + l10n.
**5G. Ostalo** — subscription (11/20): 4.3 + toggle Semantics+44 + breakpoint 720→600 + cijene NumberFormat + l10n; unit hub/wizard (13-14/20): tap targeti 26/28px→44 (master panel); wizard step Semantics + SemanticsService.announce + step4 BbCard + AlertDialog→BbDialog; splash (13/20): liveRegion + bg tokeni + try/catch ukloni.

## FAZA 6 — L10N + VALIDATORI (tekst, nula layouta)
- Validatori → kod-enum + prevod na ekranu (#943 pattern): profile_validators (9 stringova), IBAN/SWIFT, email.
- Hardcoded HR/EN sweep: premium headeri (FAQ/iCal/Units/AI), status labeli (badge, iCal), primitivi (BbAppBar hamburger/back — expose params), date-picker, offline, ' / night', 'Download', eyebrows, 404. ARB ×4 jezika.
- price_text: NumberFormat.currency + HRK uklanjanje (činjenična greška) — HRK dio je DATA odluka → GO operatora.

## FAZA 7 — ZAVRŠNO
- `/audit` re-run na 5 najgorih ekrana (score prije/poslije u SUMMARY).
- Golden regen konsolidovano; puni suite; `flutter build web`; `/code-review` na svaki PR; CHANGELOG + audit-log update.
- Otvorena pitanja za operatora (GO gate): unit_form image upload (implement vs hide), HRK, hero-metrike na loginu, forgot glass exception, PROD deploy batch.

## REDOSLIJED IZVOĐENJA (sažetak)
1 (dead code) → 2.1-2.12 (primitivi) → 4 (bugovi) → 3 (boje/flat) → 5A→5G (ekrani) → 6 (l10n) → 7.
Procjena: faze 1-4 = ~15 malih PR-ova; faza 5 = ~12 klaster PR-ova; 6 = 2-3 PR-a.
