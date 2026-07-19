# SWEEP SUMMARY — full-screen /audit (2026-07-18)
Pokriveno: **48/48 ekrana + 104/241 komponenti** (svi bb_* primitivi, shared/, core/widgets, auth, booking dijalozi). Loop zaustavljen po nalogu operatora; preostali feature widgeti pokriveni sistemskim rootovima + transitivnim čitanjem. Detalji: FINDINGS.md. Izvršavanje: REMEDIATION_PLAN.md.

## Health scores (ekrani, najgori→najbolji)
10: month_calendar, activity_log, stripe_connect_setup · 11: enhanced_login, unit_form, unit_pricing, subscription, widget_settings · 12: user_detail, email_verification, enhanced_register, timeline, profile, ical_sync, widget_advanced · 13: owner_bookings, booking_detail, booking_widget, booking_details/view, edit_profile, property_form, bank_account, forgot, unit_wizard, splash · 14-16: ostali · Komponente prosjek ~13/20; najčišći: croatian_plural 19, fcm_navigation_handler 18.

## SISTEMSKI ROOTOVI (1 fix = svi ekrani)
1. **BbInput 3×P0**: nema textInputAction/focusNode/autofillHints (90 polja) — backport iz mrtvog core/BBInput + premium_input_field.
2. **BbChip**: zero Semantics + md=40px (svi filteri/tabovi).
3. **BbIcon**: nema semanticLabel/ExcludeSemantics API (sve ikone).
4. **BbSectionHeader**: nema header:true (34 naslova).
5. **BbButton**: sm=36px; asIcon 36×36 (62+ siteova).
6. **BbCheckbox/Radio/Switch**: <48px + Semantics-over-Opacity double-read.
7. **BbCard**: semanticLabel bez excludeSemantics (double-read).
8. **BbSpinner/loaderi**: bez ExcludeSemantics/liveRegion barijere (universal/global/premium_loading).
9. **CommonAppBar**: hardcoded EN 'Menu' tooltip (~40 ekrana).
10. **PremiumListTile**: dense → ~40px (profil hub).
11. **RAW IconButton bypass**: 131 raw vs 3 kroz AccessibleIconButton; + zamka `constraints: BoxConstraints()` PONIŠTAVA 48px enforcement (booking_details_dialog:121).
12. **Status-color AA (5 članova)**: success #10B981 2.54:1, warning #F59E0B 2.15:1, imported #4A90D9 2.95-3.3:1, completed-dark #8B6FFF 3.76:1, pending-light #B7791F 3.30:1 — svi kao TEKST. + textTertiary light #718096/#999999 + BbAdminDarkTokens 0x66FFFFFF.
13. **Breakpoint drift**: 720/1024/1440/900/800/700/600/260 vs kanonski 1200 (uklj. BBBreakpoint tokene i bb_scaffold default).
14. **Flat-chrome regresije ×5 živih**: profile_screen heroGradient×4, profile_image_picker diagonal, unit_pricing Save, bb_logo useGradient default (sidebar:90/rail:56/admin_login:542), booking_cancel_dialog header. Sankcionisano: 4 privatne _buildGlassCard auth metode.
15. **l10n**: EN-only validatori (profile/password/IBAN), hardcoded HR u premium headerima/badge/primitivi/date-picker, price_text ' / night' EN + **HRK stale (činjenična greška, EUR od 2023)**.

## TOP P0/P1 (pojedinačni)
- owner_booking_detail:682 mrtva mail/call dugmad (P0)
- unit_form:889 parse crash + :69 amenities wipe + :867 upload no-op (data loss)
- global_navigation_loader:79 + offline_indicator:41 SR prolazi kroz overlay / offline nečujan (P0)
- logout_tile:85 bez confirm dijaloga (P0)
- smart_tooltip:320 force-cast TypeError (P0)
- subscription:992 mrtav link + :952 no-op dugme; booking_confirmation:542 mrtvo copy dugme
- force_update_dialog:98 iOS store URL fallback ne postoji
- social_login_button:146 Google brand violation (G bez bijele podloge)
- bookings_filters_dialog:534 Clear ne zatvara dijalog
- owner_booking_detail:1073 _toBbStatus bez imported casea
- ConnectivityService stream leak (connectivity_provider:17)
- skeleton_loader:168,652 unbounded ListView (runtime assertion rizik)

## DEAD CODE (delete lista, ~33 — RE-GREP prije rm!)
shared/widgets: bookbed_logo, button(PremiumButton), gradient_button, deferred_loader, debounced_search_field, error_state_widget, loading_overlay, login_loading_overlay, adaptive_layout, buttons/accessible_icon_button, card(PremiumCard→migriraj 2 callera)
auth: gradient_auth_button, premium_input_field, glass_card
core/widgets: CIJELI bb_* set (BBButton/Card/Chip/EmptyState/Input*/SectionHeader/Skeleton/StatusBadge/avatar/bottom_sheet — *Input poslije backporta; gallery/probe migrirati), keyboard_aware_constrained_box, owner_app_loader
animations: animated_button, animated_card, animated_dialog, animated_success, StaggeredEmptyState klasa
owner: booking_details_dialog
redesign: bb_bottom_sheet (mrtvi blizanac)
barreli: widgets.dart L10/16/20; animations.dart L6/7/9/11
⚠ KONFLIKTI u nalazima (batch 5 vs 7): loading_overlay/login_loading_overlay/gradient_button imaju kontradiktorne caller-tvrdnje — re-grep ODLUČUJE.

## DUPLIKATI (konsolidacija)
core/bb_* vs redesign/Bb* (BB/Bb naming hazard) · AccessibleIconButton ×2 (jači u core/accessibility živi) · skeleton 3-way (BBSkeleton/BbSkeleton/SkeletonLoader god-file 1496 LOC) · update-dialozi _openStore dup · AuthLogoIcon vs BbLogo · _nightWord dup · _safeErrorToString dup.

## AKCIJE
Redoslijed i taskovi: **REMEDIATION_PLAN.md** (F1 dead-code → F2 primitivi → F4 bugovi → F3 boje → F5 ekrani → F6 l10n → F7 /audit re-run). Skillovi: /harden /adapt /colorize /normalize /distill /optimize /polish /critique /verify /code-review.
