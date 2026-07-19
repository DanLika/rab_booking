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
- [x] F2.12 BbDialog: Dialog.semanticsLabel=title, Semantics(header) titula, opcioni bodyWidget slot — feat/f212-bbdialog-a11y @8c7f0dc5, suite 1950 GREEN (Semantics scopesRoute/namesRoute wrap jer raw Dialog nema semanticLabel; body sad default-'' + assert)
## F4 bugovi (UI-wiring)
- [x] F4.1 owner_booking_detail _RoundIconButton InkWell wire + 44px — fix/f4a-booking-detail @3eedc7f3, suite 1950 GREEN (mail/call bili mrtvi: Container bez geste; sad Material+InkWell, 44px box oko 36px pilule, Semantics button, tertiary tint disabled)
- [x] F4.2 unit_form — fix/f4b-unit-form @48abea94, suite 1949 GREEN (area tryParse ×2 + createUnit param double? — 1 caller, bez interfacea; amenities: UnitModel NIJE IMAO polje pa je edit save pisao [] — aditivno @Default([]) polje + restore u _loadUnitData; upload no-op = GO-queue)
- [x] F4.3 subscription — fix/f4d-guest @4b35e997, suite 1948 GREEN ('Zadrži besplatno' → maybePop; mrtvi 'Usporedi' span UKLONJEN — nema comparison surfacea, kartice već listaju features; kIsWeb-gated → buildFreeInlineForTest/buildFootNoteForTest seamovi)
- [x] F4.4 booking_confirmation — isti branch @4b35e997 (copy pill: InkWell+Clipboard+Semantics, 44px box oko 28px pilule; resend minHeight 44; Clipboard mock test potvrđuje setData)
- [x] F4.5 logout_tile — VERIFIED CLOSED bez izmjene: jedini živi caller (profile_screen:484) VEĆ wrapa onLogout u BbDialog confirm + `confirmed != true` guard; nalaz je gledao komponentu, ne call site
- [x] F4.6 smart_tooltip — fix/f4e-shared @c3a04437 (Container prima EdgeInsetsGeometry pa castovi 320/321 samo obrisani; :367 math resolve(ltr); RED→GREEN long-press test s EdgeInsetsDirectional)
- [x] F4.7 offline_indicator — fix/f4f-misc @e7c4fc2f, suite 1947 GREEN (Semantics liveRegion na banner; side-efekti build()→ref.listen+setState; ConnectivityService drži subscription + dispose() + ref.onDispose)
- [x] F4.8 _RezAINudge — isti branch @e7c4fc2f ('Kasnije'/'Odgovori' onPressed:(){} UKLONJENI — pending queue ispod nosi prave Odobri/Odbij; nudge ionako debug/env-gated)
- [x] F4.9 email_verification — isti branch @e7c4fc2f (3s poll cancel na paused + ??= re-arm na resumed, cooldown NE staje — rate-limit gate ostaje pošten; RepaintBoundary oko BackdropFilter kartice)
- [x] F4.10 tax_legal ExpansionTile — fix/f4c-dialogs @9735651f, suite 1947 GREEN (StatefulWidget + ExpansibleController iz didUpdateWidget; header i dalje ručno expandira = nema lock-outa; POUKA: Switch živi u children pa nestaje na collapse — test assertuje kroz header re-expand)
- [x] F4.11 bookings_filters — isti branch @9735651f (Clear sada pop-a kao Apply; clear-date IconButton BoxConstraints() → minWidth/minHeight 48)
- [x] F4.12 _toBbStatus imported — isti branch @3eedc7f3 (BookingStatus enum NEMA imported → uzima BookingModel i vraća imported za isExternalBooking, cancelled i dalje pobjeđuje; 5 testova matrica)
- [x] F4.13 (social dio) — isti branch @c3a04437: GoogleBrandIcon → CircleAvatar bijeli disk + glyph 72%, fallback nasljeđuje disk. iOS store URL = GO-QUEUE (treba pravi App Store ID)
- [~] F4.14 skeleton_loader → BUNDLE s F3.7 (isti fajl — dark ladder + unbounded ListView zajedno)
## F3 boje/flat (namjerne vizuelne — screenshot prije/poslije + golden regen)
- [x] F3.1 widget status TEKST boje — fix/f31-widget-status-colors @2ac8c4e4, suite GREEN (plan-hexovi NISU prolazili mjerenje → IZRAČUNATI minimumi: successText #047857, warningText #B45309, textTertiary #6F6F6F — svi ≥4.5:1 i na #F5F5F5 i na 10% tintovima; novi successText/warningText tokeni na WidgetColorScheme ×3 sheme; fillovi/ikone netaknuti; 15-cell matrica test)
- [x] F3.2 bb_status_badge — fix/f32-status-badge @d70d063a, suite GREEN (IZRAČUNATI minimumi na kompozitnom tintu: imported L #2B6CB0, pending L #A05E14, confirmed L #2A7354 — matrica UHVATILA i confirmed 4.27:1 koji je audit propustio, completed D #A78BFF; ×3 token surfacea konzistentno; badge Semantics node + pending dot statusPendingDeep; golden regen ×12 NAMJERAN — boja-only na legendama/chipovima)
- [x] F3.3 BBColorSet.onPrimary — fix/f33-onprimary-token @7aa8a95b, suite 1947 GREEN (default Colors.white na konstruktoru = svi setovi automatski; BbButton primary/destructive/success + BbChip + BbCheckbox + BbLogo migrirani; onGradient/translucent NAMJERNO ne; neutrality-pin test; bajt-identično, bez rendera)
- [x] F3.4 admin textTertiary — fix/f34-admin-tertiary @13371aeb, suite 1946 GREEN (white@0.40→0.50 = 3.62→4.81:1 na panelBg #2A2342; postojeći pin test ažuriran uz obrazloženje; novi named-surface guard test)
- [x] F3.5 flat regresije — fix/f35-flat-regressions @f5398dfc, suite 1947 GREEN (profile ×4 solid primary + gauge painter Color umjesto shadera — usput fix always-true shouldRepaint; image_picker ×2; cancel dialog header gradient DROPPED — reject nikad nije imao = asimetrija; bb_logo default false + lažni asset-fallback docstring; golden regen ×12 namjeran; unit_pricing Save → GO-QUEUE jer FROZEN 'Spremi')
- [x] F3.6 stale TIP-1 docstringovi — docs/f36-stale-tip1-docstrings @c234c42c, comments-only 0 behavior, analyze 112 baseline (unit_form ×2, step_4_review, widget_settings_section, property_form ×2; admin_login dijagonala je ŽIVI sanctioned hero — netaknut)
- [x] F3.7+F4.14 skeleton — fix/f37-skeleton @204d68b2, suite 1949 GREEN (SkeletonColors dark → OLED ladder; StatsCards theme-aware; 2 unbounded ListViewa → shrinkWrap+NeverScrollable; 4 testa uklj. nested-in-Column survival)
## F1b konsolidacija
- [x] PremiumCard → BbCard ×2 + card.dart DELETED — chore/f1b-consolidation @5e156d41, suite 1945 GREEN
- [~] core/widgets/bb_* set: ai_assistant (zadnji ne-dev konzument) migriran na redesign BbSkeleton; SAM SET ostaje — jedini konzumenti gallery_dev (54 sitea) + responsive_probe = dev alati → GO-QUEUE (migrate vs delete showcases = operator)
- [x] redesign/bb_bottom_sheet DELETED (0 callera) — isti branch
## F5 ekrani (klaster PR-ovi, punch-liste u REMEDIATION_PLAN.md §5A-5G)
- [x] 5A kalendari — fix/f5a-calendar-chrome @25870273, suite 1952 GREEN (delegirano sonnetu + firsthand verify; portrait-lock <600 only, FAB/day-cell/date-header Semantics ADITIVNO, dupli setState konsolidovan uz post-frame za AnimatedSize, red.shade700→AppColors.error, textInputAction ×3, CalendarDayCell Semantics IZVAN FROZEN sadržaja; 7 testova; 0 golden diffova)
- [x] 5B admin — fix/f5b-admin-chrome @a79a322b, suite 1951 GREEN (event kartice Semantics + toLocal; user_detail copy 44px + BbSkeleton umjesto '...'; users_list SelectableText→Text vraća row-tap + dark date-picker + kartica Semantics; shell static teme + nav selected + SignOut 44px; KPI Tooltip+Semantics; 6 testova; POUKA: agentov "pre-existing infos" claim bio netačan — +2 u njegovom test fajlu, počišćeno firsthand)
- [x] 5C auth — fix/f5c-auth-chrome @aefdfd01+@dc51550a, suite 1961 GREEN (toggle/footer 44px; terms label-tap uz link recognizer; verif liveRegion na status NE countdown; legal trio header/ToC/FAB/const datum; golden regen auth_register ×4 — 44px terms row)
- [x] 5D forme — fix/f5d-owner-forms @fa18fe7a, suite 1959 GREEN (overlay BbCard+ExcludeSemantics; delete 44px; bank 1024→1200; strength liveRegion; edit_profile SF-012 leak fix; ⚠ textInputAction/autofill za bank/change_password POSLIJE F8 mergea — trebaju feat/f21 parami)
- [x] 5E settings/guides — fix/f5e-settings-guides (chipovi/swatches/slideri Semantics; quiet-time 44px; iCal 900→1200 + builder liste; guides copy 44px; tax_legal hunk REVERTOVAN — F4.10 branch posjeduje fajl; suite u toku)
- [x] 5F widget-gost — fix/f5f-widget-guest @eeaf4d9e (breakpointi 1024→1200 ×4; confirm blok dedup; backdrop Semantics; SnackBarHelper; pill bar 320-safe; details header ellipsis; elasticOut→easeOutBack; legacy tokeni; computeLuminance→themeProvider; 404/subdomain header roles; POUKA: prvi agent umro usred posla — drugi agent nastavio po git diff stanju; suite -5 ISTRAŽITI na wakeup)
- [x] 5G ostalo — fix/f5g-misc-screens (subscription toggle Semantics+44+consts; wizard announce+node labeli+BbDialog step2; splash liveRegion+tokeni; master panel 44px DROPPED → GO-queue: širina ×3 gnječi čuvani 60px name floor @320, panel fiksne širine — treba dizajn odluka; suite u toku)
## F6 l10n — [ ] validatori kod→prevod; [ ] hardcoded HR/EN sweep (ARB ×4)
## F7 — [ ] /audit re-run 5 najgorih; [ ] golden konsolidacija; [ ] CHANGELOG/audit-log; [ ] GO-queue prezentacija operatoru
## F8 ZAVRŠNO (nalog operatora 2026-07-18): MERGE → TEST → COMMIT → DEV
- [ ] integration/visual-campaign branch: merge SVIH feature brancheva (f1, f21, f22, ...) → analyze + PUNI suite + build web
- [ ] dev deploy: ⚠ PROVJERI hosting target PRIJE (memorija: bookbed-owner-dev.web.app gađa PROD uprkos imenu!) — dev-first pravilo, PROD ostaje GO-gated
- [ ] smoke na dev buildu (login + 2-3 fixana ekrana)
## GO-QUEUE (čeka operatora — NE raditi bez GO)
unit_pricing Save gradient→solid (FROZEN 'Spremi') · gallery/probe dev-alati: migrate-vs-delete · master-panel 44px ikonice vs 60px name floor (šire panel ili overflow meni?) · upload implement-vs-hide · HRK removal · login hero-metrike · forgot glass · push/PR svi branchevi · PROD deploy
