# Claude Code - Project Documentation

**RabBooking** - Booking management platforma za property owner-e na otoku Rabu.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands

---

## 🎯 NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab (`unified_unit_hub_screen.dart`) | FROZEN - referentna implementacija |
| Unit Wizard publish flow | 3 Firestore docs redoslijed kritičan |
| Timeline Calendar z-index | Cancelled PRVI, confirmed ZADNJI |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK šalje - NE vraćaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/` |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraćaj state-based navigaciju |

---

## 🎨 STANDARDI

```dart
// Gradients
final gradients = Theme.of(context).extension<AppGradients>()!;

// Input fields - UVIJEK 12px borderRadius
InputDecorationHelper.buildDecoration()

// Provider invalidation - POSLIJE save-a
await repository.updateData(...);
ref.invalidate(dataProvider);

// Nested config - UVIJEK copyWith
currentSettings.emailConfig.copyWith(requireEmailVerification: false)
// NE: EmailNotificationConfig(requireEmailVerification: false) - gubi polja!
```

---

## 📅 CALENDAR SYSTEM - KRITIČNO

**Repository**: `firebase_booking_calendar_repository.dart`
- Koristi `DateTime.utc()` za SVE map keys
- Stream errors: `onErrorReturnWith()` vraća prazan map
- Turnover detection MORA provjeriti: `partialCheckIn`, `partialCheckOut`, `booked`, `partialBoth`

**DateStatus enum**:
- `pending` → žuta + dijagonalni uzorak (`#6B4C00` @ 60%)
- `partialBoth` → turnover day (oba bookinga)
- `isCheckOutPending` / `isCheckInPending` → prati koja polovica je pending

**⚠️ NE REFAKTORISATI** - duplikacija `_buildCalendarMap` vs `_buildYearCalendarMap` je NAMJERNA safety net. Prethodni refaktoring uveo 5+ bugova.

---

## 💳 STRIPE FLOW

```
1. User klikne "Pay with Stripe"
2. Form data se BRIŠE
3. Same-tab redirect na Stripe Checkout
4. Webhook kreira booking sa stripe_session_id
5. Return URL: ?stripe_status=success&session_id=cs_xxx
6. Widget poll-uje fetchBookingByStripeSessionId() (max 30s)
7. Confirmation screen
```

---

## 🔗 SUBDOMAIN SYSTEM

- Production: `villa-marija.rabbooking.com/view?ref=XXX&email=YYY`
- Testing: `localhost:5000/view?subdomain=villa-marija&ref=XXX&email=YYY`
- Query param ima prioritet nad hostname parsingom

---

## ✅ QUICK CHECKLIST

**Prije commitanja:**
- [ ] `flutter analyze` = 0 issues
- [ ] Pročitaj CLAUDE.md ako diraš kritične sekcije
- [ ] `ref.invalidate()` POSLIJE repository poziva
- [ ] `mounted` check prije async setState/navigation

**Responsive breakpoints:**
- Desktop: ≥1200px
- Tablet: 600-1199px
- Mobile: <600px

---

**Last Updated**: 2025-12-03 | **Version**: 4.0
