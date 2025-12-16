# Email System Documentation

**Last Updated**: 2025-12-16
**Status**: Active

---

## Overview

BookBed koristi Resend API za slanje transakcijskih emailova. Svi template-i koriste minimalist dizajn sa HTML escaping-om za sigurnost i inline CSS za Gmail kompatibilnost.

---

## Template Lista (16 template-a)

### Booking Flow (4)
| Template | Primatelj | Trigger |
|----------|-----------|---------|
| `booking-confirmation.ts` | Guest | Nakon kreiranja rezervacije |
| `booking-approved.ts` | Guest | Owner odobri pending request |
| `booking-rejected.ts` | Guest | Owner odbije pending request |
| `pending-request.ts` | Guest | Guest pošalje pending request |

### Cancellation (3)
| Template | Primatelj | Trigger |
|----------|-----------|---------|
| `guest-cancellation.ts` | Guest | Guest otkaže rezervaciju |
| `owner-cancellation.ts` | Guest | Owner otkaže rezervaciju |
| `refund-notification.ts` | Guest | Stripe automatski refundira |

### Reminders (3)
| Template | Primatelj | Trigger |
|----------|-----------|---------|
| `check-in-reminder.ts` | Guest | **7 dana** prije check-in-a |
| `check-out-reminder.ts` | Guest | 1 dan prije check-out-a |
| `payment-reminder.ts` | Guest | **Dan 6** od 7 (1 dan prije isteka roka) |

### Owner Notifications (3)
| Template | Primatelj | Trigger |
|----------|-----------|---------|
| `owner-notification.ts` | Owner | Novi confirmed booking |
| `pending-owner-notification.ts` | Owner | Novi pending request |
| `overbooking-detected.ts` | Owner | Detektovan konflikt (samo owner, nikad gosti) |

### Auth (2)
| Template | Primatelj | Trigger |
|----------|-----------|---------|
| `email-verification.ts` | User | Verifikacija email adrese |
| `password-reset.ts` | User | Reset passworda |

### Custom (1)
| Template | Primatelj | Trigger |
|----------|-----------|---------|
| `custom-email.ts` | Bilo ko | Owner ručno šalje (unese email) |

---

## Folder Struktura

```
functions/src/email/
├── templates/
│   ├── base.ts                      ← Shared utility
│   ├── booking-confirmation.ts
│   ├── booking-approved.ts
│   ├── booking-rejected.ts
│   ├── pending-request.ts
│   ├── guest-cancellation.ts
│   ├── owner-cancellation.ts
│   ├── refund-notification.ts
│   ├── check-in-reminder.ts
│   ├── check-out-reminder.ts
│   ├── payment-reminder.ts
│   ├── owner-notification.ts
│   ├── pending-owner-notification.ts
│   ├── overbooking-detected.ts
│   ├── email-verification.ts
│   ├── password-reset.ts
│   └── custom-email.ts
├── utils/
│   └── template-helpers.ts          ← Helper funkcije (escapeHtml, generateCard, etc.)
├── styles/
│   └── base-styles.ts               ← HTML wrapper & CSS reset
└── index.ts                         ← Central export
```

---

## Ključni Parametri

### Payment Flow
| Parametar | Vrijednost |
|-----------|------------|
| Rok za plaćanje (bank transfer) | **7 dana** |
| Payment reminder | **Dan 6** (1 dan prije isteka) |
| Auto-cancel bez uplate | **Da** (Cloud Function) |

### Reminders
| Parametar | Vrijednost |
|-----------|------------|
| Check-in reminder | **7 dana** prije |
| Check-out reminder | 1 dan prije |

---

## Multi-Language Support

### Podržani jezici
| Jezik | Kod | Koristi se za |
|-------|-----|---------------|
| Hrvatski | `hr` | Owner Dashboard + Widget |
| English | `en` | Owner Dashboard + Widget |
| Deutsch | `de` | Widget only |
| Italiano | `it` | Widget only |

### Implementacija
- Owner Dashboard emailovi: HR + EN
- Widget emailovi (guest-facing): HR + EN + DE + IT
- Jezik se detektira iz:
  1. URL parameter (`?lang=hr`)
  2. Browser language
  3. Default: `hr`

---

## Security: HTML Escaping

**KRITIČNO**: Sav user-provided content MORA biti escaped!

```typescript
import { escapeHtml } from "../utils/template-helpers";

// ✅ CORRECT
const html = `<div>${escapeHtml(guestName)}</div>`;

// ❌ WRONG - XSS vulnerability
const html = `<div>${guestName}</div>`;
```

### Što se escape-a:
- `guestName`, `ownerName`
- `bookingReference`
- `propertyName`, `unitName`
- `contactEmail`, `contactPhone`
- `reason`, `rejectionReason`, `cancellationReason`
- Sav ostali user input

### Escaping mapa:
| Karakter | Escape |
|----------|--------|
| `&` | `&amp;` |
| `<` | `&lt;` |
| `>` | `&gt;` |
| `"` | `&quot;` |
| `'` | `&#39;` |

---

## Design Standards

### Minimalist Philosophy
- **No gradients** - solid colors only
- **No shadows** - flat design
- **Sharp edges** - `border-radius: 0` (buttons: 4px)
- **Reduced padding** - 16px cards, 12px mobile
- **Reduced fonts** - 16px body, 14px mobile

### Color Palette (Neutral)
```typescript
const COLORS = {
  pageBg: "#F9FAFB",
  cardBg: "#FFFFFF",
  textPrimary: "#1F2937",
  textSecondary: "#6B7280",
  border: "#E5E7EB",
  buttonPrimary: "#374151",
  success: "#059669",
  warning: "#D97706",
  error: "#DC2626",
  info: "#2563EB",
};
```

---

## Helper Functions

### Available in `template-helpers.ts`:

```typescript
// Text Utilities
escapeHtml(text: string): string
formatCurrency(amount: number): string         // €XX.XX
formatDate(date: Date): string                 // Croatian locale
formatDateRange(start: Date, end: Date): string
calculateNights(start: Date, end: Date): number

// Layout Components
generateHeader(options: HeaderOptions): string
generateCard(title: string, content: string): string
generateDetailsTable(rows: DetailRow[]): string
generateButton(options: ButtonOptions): string
generateAlert(options: AlertOptions): string
generateBadge(text: string, type: string): string
generateDivider(): string
generateFooter(options?: FooterOptions): string

// Content Blocks
generateGreeting(name: string): string         // "Poštovani/a {name},"
generateIntro(text: string): string
generateList(items: string[]): string
generateInfoBox(text: string): string

// Booking-Specific
generateBookingDetailsCard(params): string
generatePaymentDetailsCard(params): string
generateBankTransferCard(params): string
```

---

## Template Anatomy

```typescript
// 1. IMPORTS
import { generateEmailHtml } from "./base";
import {
  escapeHtml,
  generateHeader,
  generateCard,
  generateButton,
  // ... other helpers
} from "../utils/template-helpers";

// 2. PARAMS INTERFACE
export interface BookingConfirmationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  // ... other params
}

// 3. GENERATE FUNCTION
export function generateBookingConfirmationEmail(
  params: BookingConfirmationParams
): string {
  const header = generateHeader({
    icon: getSuccessIcon(),
    title: "Rezervacija potvrđena!",
    bookingReference: escapeHtml(params.bookingReference),
  });

  const content = `
    ${generateGreeting(escapeHtml(params.guestName))}
    ${generateCard("Detalji", detailsHtml)}
    ${generateButton({ text: "Pregledaj", url: params.viewUrl })}
  `;

  return generateEmailHtml({
    header,
    content,
    footer: { contactEmail: escapeHtml(params.contactEmail) },
  });
}

// 4. SEND FUNCTION
export async function sendBookingConfirmationEmail(
  params: BookingConfirmationParams
): Promise<void> {
  const resend = new Resend(process.env.RESEND_API_KEY);
  const html = generateBookingConfirmationEmail(params);

  await resend.emails.send({
    from: "BookBed <noreply@bookbed.io>",
    to: params.guestEmail,
    subject: `Rezervacija - ${escapeHtml(params.bookingReference)}`,
    html,
  });
}
```

---

## Owner Email Behavior

### KRITIČNO: Owner UVIJEK dobija email za booking

```typescript
// atomicBooking.ts - NE MIJENJATI
await sendOwnerNotificationEmail(...);  // UVIJEK se šalje

// NE vraćati conditional check:
// const shouldSend = await shouldSendEmailNotification(ownerId, "bookings");
// if (shouldSend) { ... }
```

**Razlog**: Dok nema push notifikacija, owner NE SMIJE propustiti niti jednu rezervaciju.

### Notification Preferences (Widget)
- Widget flow poštuje owner notification preferences
- **Izuzetak**: Pending bookings UVIJEK šalju email (kritično - owner mora odobriti)
- Fallback: Ako provjera preferences ne uspije → email se šalje

---

## Scheduled Functions

### Check-In Reminder
- **Trigger**: Scheduled Cloud Function (daily)
- **Šalje se**: 7 dana prije check-in-a
- **Uvjet**: Booking status = `confirmed`

### Check-Out Reminder
- **Trigger**: Scheduled Cloud Function (daily)
- **Šalje se**: 1 dan prije check-out-a
- **Uvjet**: Booking status = `confirmed`

### Payment Reminder
- **Trigger**: Scheduled Cloud Function (daily)
- **Šalje se**: Dan 6 od 7 (1 dan prije isteka)
- **Uvjet**: Booking status = `pending`, payment_method = `bank_transfer`

### Auto-Cancel Unpaid
- **Trigger**: Scheduled Cloud Function (daily)
- **Akcija**: Cancel booking nakon 7 dana bez uplate
- **Uvjet**: Booking status = `pending`, payment_method = `bank_transfer`, created > 7 dana

---

## TODO (Future)

- [ ] **Welcome Email** - Za novog owner-a nakon email verifikacije
- [ ] **Suspicious Activity** - Security alert (kad definišemo trigere)
- [ ] **Custom reminder intervals** - Owner bira koliko dana prije check-in-a

---

## Related Files

| File | Purpose |
|------|---------|
| `functions/src/email/index.ts` | Central export |
| `functions/src/emailService.ts` | Email sending logic |
| `functions/src/emailNotificationHelper.ts` | Notification preferences |
| `lib/features/widget/utils/email_notification_helper.dart` | Widget email logic |

---

## Changelog

### 2025-12-16
- Uklonjen `suspicious-activity.ts` (TODO za budućnost)
- Check-in reminder: 1 dan → **7 dana** prije
- Payment rok: 3 dana → **7 dana**
- Payment reminder: **Dan 6** (1 dan prije isteka)
- Auto-cancel nakon 7 dana bez uplate
- Uklonjeni V1 legacy template-i
- Uklonjeni `-v2` suffix iz imena
- Premješteno iz `version-2/` u `templates/`
- Multi-language: HR + EN za sve, DE + IT za widget
