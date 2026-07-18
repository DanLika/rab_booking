# EXECUTION checklist (izvor: REMEDIATION_PLAN.md; nalazi: FINDINGS.md/SUMMARY.md)
Pravila: worktree/branch po tasku od origin/main; backend NE; FROZEN wrap-only; verifikacija analyze 0/0 → ciljani test → puni suite → goldeni → format; commiti LOKALNI (push/PR na GO); grep za braću poslije fixa. Svježi worktree: pub get + build_runner PRIJE analyze.

## F2 primitivi
- [x] F2.1 BbInput params backport — feat/f21-bbinput-a11y-params (wt /tmp/bb-f21-bbinput-wt) — suite 1945/1945
- [x] F2.2 BbButton — feat/f22-bbbutton-tap-targets (wt /tmp/bb-f22-bbbutton-wt) — sm/asIcon hit-area 44 (vizual netaknut), spinner ExcludeSemantics, assert, static Matrix4; 8 testova; golden regen owner_about ×2 (0.64% layout, namjerno); suite FULL GREEN nakon regena
- [x] F2.3 BbChip — feat/f23-bbchip-semantics — Semantics(button/selected/label+count), 44px hit-area (pill 32/40 netaknut), purpleGlow(context), focus/hover, badge fullAll; golden regen guides_faq ×4 namjeran; suite FULL GREEN; deferred: text-scale minHeight
- [x] F2.4 BbIcon — feat/f24-bbicon-semantics — decorative-by-default ExcludeSemantics + semanticLabel opt-in, glyph cache, debug unknown-name print; suite FULL GREEN; deferred: fill/weight int→double
- [x] F2.5 BbSectionHeader — feat/f25-bbsectionheader-a11y — header:true (34 sitea) + merged action button node; semantics-only, 0 vizuelno; suite FULL GREEN; deferred: akcija 44px hit-area (34 redova reshape = zaseban golden pass)
- [x] F2.6 BbCard — feat/f26-bbcard-semantics — excludeSemantics param (double-read fix), container role za neinteraktivne s labelom, static Matrix4; 0 vizuelno; suite FULL GREEN
- [x] F2.7 toggles — feat/f27-toggle-a11y — checkbox 44×44+subtitle-u-label+error-sibling, radio checked+mutuallyExclusive+minWidth48+validator stateVal, switch merged node+keyboard verified; Opacity IZVAN Semantics sva tri; suite FULL GREEN
- [x] F2.8 BbSpinner — feat/f28-bbspinner-semantics — ExcludeSemantics default + semanticsLabel liveRegion opt-in (obje grane); suite FULL GREEN
- [x] F2.9 CommonAppBar — feat/f29-commonappbar-tooltip @61761015 — leadingTooltip param (default 'Menu' backward-compat, migracija u F5/F6) + sizeOf; suite FULL GREEN; deferred: title nullable (širi refactor)
- [x] F2.10 PremiumListTile — feat/f210-premium-list-tile @78287d33 — minTileHeight:48, chevron samo uz onTap, ListTile.enabled; goldeni netaknuti; suite FULL GREEN
- [x] F2.11 loaderi — feat/f211-loader-a11y — UniversalLoader merged liveRegion node, GlobalNavigationOverlay ExcludeSemantics barijera + const, PremiumLoading merged node + reduced-motion; suite FULL GREEN. POUKA: grep -c u && lancu = exit 1 na nuli (presjekao commit)
- [ ] F2.12 BbDialog: Dialog.semanticsLabel=title, Semantics(header) titula, opcioni bodyWidget slot
## F4 bugovi (UI-wiring)
- [ ] F4.1 owner_booking_detail:682 _RoundIconButton InkWell wire + 44px (mrtva mail/call)
- [ ] F4.2 unit_form: tryParse area (crash) + amenities restore u _loadUnitData (wipe); upload no-op = GO-queue
- [ ] F4.3 subscription: 'Usporedi' recognizer + 'Zadrži besplatno' wire-ili-ukloni
- [ ] F4.4 booking_confirmation: copy dugme Clipboard wire + 44px; resend 44px
- [ ] F4.5 logout_tile: BbDialog confirm prije onLogout
- [ ] F4.6 smart_tooltip: as EdgeInsets → resolve(TextDirection.ltr)
- [ ] F4.7 offline_indicator: liveRegion + side-efekti van build + stream cancel (connectivity_provider ref.onDispose)
- [ ] F4.8 _RezAINudge no-op dugmad: ukloni do featurea
- [ ] F4.9 email_verification: timer cancel na paused + RepaintBoundary
- [ ] F4.10 tax_legal ExpansionTile controller (ostaje otvoren poslije disable)
- [ ] F4.11 bookings_filters: Clear → pop + clear-date IconButton 0×0 fix
- [ ] F4.12 _toBbStatus imported case (owner_booking_detail:1073)
- [ ] F4.13 force_update iOS store URL + social_login Google G bijela podloga + ripple fix
- [ ] F4.14 skeleton_loader: shrinkWrap/physics na 2 unbounded ListView-a
## F3 boje/flat (namjerne vizuelne — screenshot prije/poslije + golden regen)
- [ ] F3.1 widget status TEKST boje: success→#059669, warning→#B45309, textTertiary→#767676 (minimalist_colors) + kontrast-matrica test
- [ ] F3.2 bb_status_badge: importedDeep token + completed-dark + pending-light korekcije
- [ ] F3.3 BBColorSet.onPrimary token + sweep Colors.white-on-primary (neutralno)
- [ ] F3.4 admin BbAdminDarkTokens.textTertiary izračunati min za #2A2342
- [ ] F3.5 flat regresije: profile_screen ×4 → solid; profile_image_picker; unit_pricing Save; booking_cancel_dialog header; bb_logo default false (+eyeball 3 default-sitea)
- [ ] F3.6 stale TIP-1 docstringovi (5 fajlova, doc-only)
- [ ] F3.7 skeleton dark ladder na audit/127 (#1E1E1E/#2A2A2A/#333333) + StatsCards light-only fix
## F1b konsolidacija
- [ ] PremiumCard: migriraj 2 callera → BbCard, obriši card.dart + glass API
- [ ] core/widgets/bb_* set: gallery/probe migracija na Bb*, delete (BBInput sad smije — backport gotov)
- [ ] redesign/bb_bottom_sheet (mrtvi blizanac) delete
## F5 ekrani (klaster PR-ovi, punch-liste u REMEDIATION_PLAN.md §5A-5G)
- [ ] 5A kalendari → [ ] 5B admin → [ ] 5C auth → [ ] 5D forme → [ ] 5E settings/guides → [ ] 5F widget-gost → [ ] 5G ostalo
## F6 l10n — [ ] validatori kod→prevod; [ ] hardcoded HR/EN sweep (ARB ×4)
## F7 — [ ] /audit re-run 5 najgorih; [ ] golden konsolidacija; [ ] CHANGELOG/audit-log; [ ] GO-queue prezentacija operatoru
## F8 ZAVRŠNO (nalog operatora 2026-07-18): MERGE → TEST → COMMIT → DEV
- [ ] integration/visual-campaign branch: merge SVIH feature brancheva (f1, f21, f22, ...) → analyze + PUNI suite + build web
- [ ] dev deploy: ⚠ PROVJERI hosting target PRIJE (memorija: bookbed-owner-dev.web.app gađa PROD uprkos imenu!) — dev-first pravilo, PROD ostaje GO-gated
- [ ] smoke na dev buildu (login + 2-3 fixana ekrana)
## GO-QUEUE (čeka operatora — NE raditi bez GO)
upload implement-vs-hide · HRK removal · login hero-metrike · forgot glass · push/PR svi branchevi · PROD deploy
