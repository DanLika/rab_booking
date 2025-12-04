# RabBooking

**Booking management platforma za property owner-e na otoku Rabu.**

RabBooking omogućava vlasnićima smještaja da kreiraju i upravljaju svojim bookingima kroz centralizirani dashboard, dok gostima pruža jednostavan embeddable booking widget sa Stripe checkout integracijom.

---

## 🚀 Quick Start

### Prerequisites

- **Flutter** 3.x+ (SDK)
- **Node.js** 18+ (za Firebase Functions)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **Stripe CLI** (za webhook testing)
- **Git**

### Installation

```bash
# 1. Clone repository
git clone https://github.com/yourusername/rab_booking.git
cd rab_booking

# 2. Install Flutter dependencies
flutter pub get

# 3. Install Firebase Functions dependencies
cd functions
npm install
cd ..

# 4. Setup Firebase
firebase login
firebase use --add  # Select your Firebase project

# 5. Setup environment variables
cp .env.example .env  # Add your API keys
```

### Running Locally

```bash
# Start Flutter web app (port 5000)
flutter run -d chrome --web-port=5000

# Start Firebase Emulators (separate terminal)
firebase emulators:start

# Start Stripe webhook listener (separate terminal)
stripe listen --forward-to localhost:5001/your-project/us-central1/handleStripeWebhook
```

---

## 🏗️ Tech Stack

### Frontend
- **Flutter Web** - Cross-platform UI framework
- **Riverpod** - State management
- **Freezed** - Immutable data classes
- **Go Router** - Routing & navigation

### Backend
- **Firebase**
  - Firestore - Database
  - Cloud Functions - Serverless backend (TypeScript)
  - Authentication - User management
  - Hosting - Web hosting
  - Storage - File uploads

### Integrations
- **Stripe** - Payment processing
- **Resend** - Email service
- **iCal** - Calendar sync (export/import)

---

## 📁 Project Structure

```
rab_booking/
├── lib/
│   ├── core/                 # Core utilities, themes, constants
│   ├── features/
│   │   ├── owner/           # Owner dashboard (bookings, units, settings)
│   │   └── widget/          # Public booking widget
│   └── shared/              # Shared models, widgets, services
│
├── functions/               # Firebase Cloud Functions (TypeScript)
│   └── src/
│       ├── atomicBooking.ts       # Atomic booking creation
│       ├── stripePayment.ts       # Stripe webhook handler
│       ├── emailService.ts        # Email templates
│       └── email/templates/       # HTML email templates
│
├── test/                    # Unit & widget tests
├── web/                     # Web-specific assets
├── CLAUDE.md               # Development guidelines
└── firebase.json           # Firebase configuration
```

---

## 🎯 Key Features

### For Property Owners
- **Multi-unit management** - Manage multiple properties from one dashboard
- **Booking calendar** - Month/year view with turnover detection
- **Price management** - Base prices + seasonal adjustments
- **Automated emails** - Confirmation, reminders, cancellations
- **Custom domains** - `villa-marija.rabbooking.com`
- **Payment tracking** - Deposits, remaining amounts, refunds

### For Guests
- **Embeddable widget** - Seamless integration into owner websites
- **Stripe checkout** - Secure payment processing
- **Email verification** - Optional guest verification
- **Booking management** - View/cancel bookings via unique links
- **iCal sync** - Add bookings to personal calendars

---

## 🔧 Development Guidelines

### Code Standards

```dart
// Use theme gradients
final gradients = Theme.of(context).extension<AppGradients>()!;

// Input fields - always 12px borderRadius
InputDecorationHelper.buildDecoration()

// Provider invalidation after saves
await repository.updateData(...);
ref.invalidate(dataProvider);

// Nested config - always use copyWith
currentSettings.emailConfig.copyWith(requireEmailVerification: false)
```

### Critical Components

**DO NOT MODIFY without reading [CLAUDE.md](./CLAUDE.md):**
- Calendar Repository (`firebase_booking_calendar_repository.dart`)
- Unit Wizard publish flow
- Timeline Calendar z-index ordering
- Subdomain validation regex
- Email URL generation logic

### Before Committing

- [ ] `flutter analyze` shows 0 issues
- [ ] Read [CLAUDE.md](./CLAUDE.md) if touching critical sections
- [ ] `ref.invalidate()` called after repository updates
- [ ] `mounted` check before async `setState`/navigation

---

## 🌐 Deployment

### Deploy Firebase Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### Deploy Flutter Web

```bash
flutter build web --release
firebase deploy --only hosting
```

### Environment Variables

```bash
# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Resend
RESEND_API_KEY=re_...
```

---

## 📚 Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Development standards & critical sections
- **[CLAUDE_BUGS_ARCHIVE.md](./CLAUDE_BUGS_ARCHIVE.md)** - Bug fixes with code examples
- **[CLAUDE_WIDGET_SYSTEM.md](./CLAUDE_WIDGET_SYSTEM.md)** - Widget modes & payment logic
- **[CLAUDE_MCP_TOOLS.md](./CLAUDE_MCP_TOOLS.md)** - MCP servers & slash commands

---

## 🐛 Known Issues

- Calendar repository has intentional code duplication (safety net)
- Some email templates not yet migrated to new system (see `emailService.ts:19`)
- Subdomain routing uses query param fallback in development

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/widget/data/repositories/firebase_booking_calendar_repository_test.dart

# Run tests with coverage
flutter test --coverage
```

---

## 📝 License

[Add your license here]

---

## 👥 Contributors

- **Duško Ličanin** - Initial development

---

## 🆘 Support

For issues and feature requests, please contact: [your-email@example.com]

---

**Last Updated**: 2025-12-04
