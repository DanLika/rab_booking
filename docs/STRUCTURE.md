# Dokumentacija Struktura

## 📁 docs/

```
docs/
├── README.md                          # Glavni index dokumentacije
├── api-integrations/                  # API integracije
│   ├── platform-apis/                # Direktni API pristup (Booking.com, Airbnb)
│   │   ├── API_ACCESS_REALITY_CHECK.md
│   │   ├── API_INTEGRATION_RISKS_AND_CONSIDERATIONS.md
│   │   ├── DEVELOPER_SETUP_CHECKLIST.md
│   │   ├── PLATFORM_API_INTEGRATION_SETUP.md
│   │   └── RESEARCH_PROMPT_PLATFORM_APIS.md
│   └── channel-managers/             # Channel Manager API pristup (preporučeno)
│       └── CHANNEL_MANAGER_SETUP.md
├── features/                          # Feature dokumentacija
│   ├── email-templates/              # Email template dokumentacija
│   │   ├── BOOKING_DETAILS_PAGE_IMPROVEMENTS_SUMMARY.md
│   │   ├── EMAIL_TEMPLATES_REORGANIZATION_PLAN.md
│   │   ├── EMAIL_TEMPLATES_UPDATE_PLAN.md
│   │   ├── EMAIL_TEMPLATES_UPDATE_SUMMARY.md
│   │   ├── MINIMALIST_CSS_STYLING_UPDATE.md
│   │   └── WIDGET_NOTIFICATION_PREFERENCES_FIX_SUMMARY.md
│   ├── overbooking-detection/        # Overbooking detekcija
│   │   ├── LONG_TERM_CONSIDERATIONS.md
│   │   └── OVERBOOKING_DETECTION_IMPLEMENTATION_SUMMARY.md
│   ├── pwa/                          # Progressive Web App
│   │   ├── PWA_INSTALLATION.md
│   │   └── PWA_TESTING.md
│   └── stripe/                       # Stripe integracija
│       ├── STRIPE_CROSS_TAB_COMMUNICATION_FIX_SUMMARY.md
│       ├── STRIPE_DEBUG_GUIDE.md
│       └── STRIPE_FIX_IMPLEMENTATION_CHECKLIST.md
├── setup/                            # Setup i deployment
│   ├── developer-setup/              # Developer setup
│   │   └── README.md
│   └── deployment/                   # Deployment dokumentacija
│       └── SUBDOMAIN_SETUP.md
├── architecture/                     # Arhitektura
│   └── ARCHITECTURAL_IMPROVEMENTS.md
└── summaries/                        # Summary fajlovi
    ├── COMPLETE_SUMMARY.md
    └── FIXES_APPLIED.md
```

## 📁 .cursor/plans/

```
.cursor/plans/
├── README.md                          # Glavni index planova
├── api-integrations/                  # API integracija planovi
│   └── channel_manager_integration_strategy.md
├── features/                          # Feature planovi
│   └── overbooking_detection_and_warning_system.md
└── fixes/                             # Fix planovi
    └── stripe_cross_tab_communication_fix.md
```

## 🔍 Brzo Pronalaženje

### API Integracije
- **Direktni API (nedostupan)** → `docs/api-integrations/platform-apis/`
- **Channel Manager (preporučeno)** → `docs/api-integrations/channel-managers/`
- **Planovi** → `.cursor/plans/api-integrations/`

### Features
- **Overbooking Detection** → `docs/features/overbooking-detection/`
- **Stripe** → `docs/features/stripe/`
- **PWA** → `docs/features/pwa/`
- **Email Templates** → `docs/features/email-templates/`
- **Planovi** → `.cursor/plans/features/`

### Setup & Deployment
- **Developer Setup** → `docs/setup/developer-setup/`
- **Deployment** → `docs/setup/deployment/`

### Ostalo
- **Arhitektura** → `docs/architecture/`
- **Summaries** → `docs/summaries/`
- **Fix Planovi** → `.cursor/plans/fixes/`
