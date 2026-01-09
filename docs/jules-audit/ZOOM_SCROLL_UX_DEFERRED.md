# Jules Branch: Zoom/Scroll UX Improvements

**Branch:** `zoom-scroll-ux-improvements-373058651913635908`
**Status:** ⏸️ ODGOĐENO - NE BRISATI

---

## Što branch radi:
- Pinch-to-zoom za widget (InteractiveViewer)
- Legacy site detekcija
- Iframe auto-resize
- LayoutBuilder refaktor kalendara

## Zašto je odgođeno:
- InteractiveViewer + SingleChildScrollView = gesture konflikti
- Može slomiti responsive layout (conditional sizes)
- Potrebno temeljito testiranje na svim platformama

## TODO (buduće):
- Pronaći način za zoom bez InteractiveViewer unutar scroll containera
- Testirati na iOS Safari, Android Chrome, desktop browseri
- Osigurati da ne lomi date selection geste

**Datum:** 2026-01-09
