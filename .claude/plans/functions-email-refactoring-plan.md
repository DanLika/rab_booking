# Functions Folder & Email Service Refactoring Plan

**Primary Goal**: Modernize email design and improve overall codebase maintainability
**Date**: 2025-12-04
**Status**: Ready for Implementation

---

## 🎯 PRIORITY LEVELS

### P0 - CRITICAL (Email Design)
1. Modernize email template design (2025 standards)
2. Improve email accessibility (WCAG, dark mode support)
3. Break down 1443-line emailService.ts

### P1 - HIGH (Code Quality)
4. Remove dead code and unused functions
5. Improve error handling and logging
6. Add TypeScript strict checks

### P2 - MEDIUM (Architecture)
7. Modularize email templates
8. Standardize email sending patterns
9. Add comprehensive tests

---

## 📊 CURRENT STATE ANALYSIS

### Email Service Structure (emailService.ts - 1443 lines)

**Lines 114-130**: Color constants
```typescript
const COLORS = {
  primary: "#6B4CE6",      // Purple
  primaryLight: "#F5F3FF",
  success: "#10B981",
  warning: "#F59E0B",
  // ... 10+ more colors
};
```

**Lines 135-280+**: Base styles function
- Inline CSS (required for email clients)
- Responsive design (@media queries)
- Minimalist theme
- Purple gradient header

**10 Email Functions** (lines 312-1341):
1. `sendBookingConfirmationEmail()` - 134 lines
2. `sendBookingApprovedEmail()` - 128 lines
3. `sendOwnerNotificationEmail()` - 122 lines
4. `sendGuestCancellationEmail()` - 110 lines
5. `sendOwnerCancellationNotificationEmail()` - 98 lines
6. `sendCustomGuestEmail()` - 143 lines
7. `sendPaymentReminderEmail()` - 115 lines
8. `sendCheckInReminderEmail()` - 108 lines
9. `sendCheckOutReminderEmail()` - 105 lines
10. `sendRefundNotificationEmail()` - 95 lines

**Helper Functions**:
- `generateViewBookingUrl()` - Subdomain URL generation
- `getResendClient()` - Resend API singleton
- `escapeHtml()` - XSS prevention

### Functions Inventory (17 modules)

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| emailService.ts | 1443 | 🔴 REFACTOR | Too large, needs splitting |
| stripePayment.ts | ~400 | ✅ OK | Well-structured webhook |
| atomicBooking.ts | ~350 | ✅ OK | Core booking logic |
| bookingManagement.ts | ~300 | ✅ OK | Owner actions |
| resendBookingEmail.ts | 162 | ✅ OK | Simple wrapper |
| guestCancelBooking.ts | ~250 | ✅ OK | Cancellation logic |
| customEmail.ts | ~150 | ✅ OK | Custom email sender |
| bookingAccessToken.ts | ~100 | ✅ OK | Token generation |
| icalExport.ts | ~200 | ✅ OK | Calendar export |
| icalSync.ts | ~180 | ✅ OK | Calendar sync |
| notificationService.ts | ~120 | ⚠️ REVIEW | May have overlap |
| publishUnit.ts | ~200 | ✅ OK | Unit publishing |
| unpublishUnit.ts | ~150 | ✅ OK | Unit unpublishing |
| unitSearch.ts | ~180 | ✅ OK | Search functionality |
| logger.ts | ~80 | ✅ OK | Logging utilities |
| firebase.ts | ~50 | ✅ OK | Firebase init |

**Dead Code Analysis**:
- ❓ notificationService.ts - may duplicate emailService functionality
- ✅ All other modules appear active and necessary

---

## 🎨 NEW EMAIL DESIGN PROPOSAL

### Design Principles (2025 Standards)

1. **Modern & Clean**
   - Reduced visual clutter
   - More whitespace
   - Softer colors
   - Subtle shadows instead of borders

2. **Accessible**
   - WCAG AA contrast (4.5:1 minimum)
   - Dark mode support via CSS prefers-color-scheme
   - Semantic HTML
   - Alt text for all icons/images

3. **Brand Consistency**
   - Match Flutter widget design tokens
   - Use same color palette (purple gradient)
   - Consistent typography

4. **Mobile-First**
   - Stack on small screens
   - Larger touch targets (48px minimum)
   - Readable font sizes (16px base)

### Color Palette Improvements

**Current Problems**:
- Too many color variables (14+)
- Purple gradient is bold (#6B4CE6 → #8B5CF6)
- No dark mode support

**Proposed Changes**:
```typescript
// Light theme (default)
const EMAIL_COLORS_LIGHT = {
  // Primary
  primary: "#6B4CE6",           // Keep existing purple
  primaryLight: "#F5F3FF",      // Keep for backgrounds
  primaryDark: "#5B3CD6",       // Darker for hover states

  // Neutral palette (simplified)
  background: "#FFFFFF",
  backgroundSecondary: "#F8F9FA",  // Match widget light theme
  text: "#111827",
  textSecondary: "#6B7280",
  border: "#E5E7EB",

  // Status colors
  success: "#10B981",
  warning: "#F59E0B",
  error: "#EF4444",
  info: "#3B82F6",
};

// Dark theme (NEW - for email clients that support it)
const EMAIL_COLORS_DARK = {
  primary: "#8B5CF6",           // Lighter purple for dark
  primaryLight: "#2D1B4E",      // Dark purple background
  primaryDark: "#A78BFA",

  background: "#1A1A1A",        // Match widget dark theme
  backgroundSecondary: "#2D2D2D",
  text: "#F1F5F9",              // slate100
  textSecondary: "#94A3B8",
  border: "#374151",

  success: "#34D399",
  warning: "#FBBF24",
  error: "#F87171",
  info: "#60A5FA",
};
```

### Template Structure Improvements

**Current Structure** (sendBookingConfirmationEmail):
```html
<div class="email-wrapper">
  <div class="header">         <!-- Purple gradient -->
    <div class="header-icon">✅</div>
    <h1>Rezervacija potvrđena!</h1>
    <p>Referenca: XXX</p>
  </div>
  <div class="content">
    <p class="greeting">Poštovani/a {name},</p>
    <div class="section">      <!-- Repeats 3-4 times -->
      <div class="section-title">📋 Detalji</div>
      <div class="detail-row">...</div>
    </div>
    <div class="button-container">
      <a class="button">Pregledaj</a>
    </div>
  </div>
</div>
```

**Problems**:
- Emoji icons (✅📋💰) - not accessible, don't scale
- Gradient header - too prominent, hard to read on some screens
- No card-based layout - content blends together
- No dark mode support

**Proposed Structure**:
```html
<div class="email-wrapper">
  <!-- IMPROVED HEADER -->
  <div class="header">
    <!-- Icon as inline SVG (not emoji) -->
    <svg class="header-icon">...</svg>
    <h1>Rezervacija potvrđena</h1>
    <p class="booking-ref">
      <span>Referenca</span>
      <strong>XXX-XXX-XXX</strong>
    </p>
  </div>

  <!-- CONTENT WITH CARDS -->
  <div class="content">
    <p class="greeting">Poštovani/a {name},</p>
    <p class="intro">Vaša rezervacija je uspješno potvrđena...</p>

    <!-- Card-based sections -->
    <div class="card">
      <h2>Detalji rezervacije</h2>
      <table class="details-table">
        <tr>
          <td class="label">Nekretnina</td>
          <td class="value">{propertyName}</td>
        </tr>
        <!-- More rows -->
      </table>
    </div>

    <div class="card">
      <h2>Datumi</h2>
      <table class="details-table">...</table>
    </div>

    <div class="card">
      <h2>Cijena</h2>
      <table class="details-table">...</table>
    </div>

    <!-- CTA Button -->
    <div class="cta-container">
      <a href="{url}" class="button">
        Pregledaj moju rezervaciju
      </a>
    </div>

    <!-- Footer info -->
    <div class="footer">
      <p>Imate pitanja? Kontaktirajte nas na...</p>
    </div>
  </div>
</div>

<!-- Dark mode media query -->
<style>
  @media (prefers-color-scheme: dark) {
    .email-wrapper { background: #1A1A1A !important; }
    .card { background: #2D2D2D !important; }
    /* ... more dark styles */
  }
</style>
```

**Key Improvements**:
1. SVG icons instead of emojis
2. Card-based layout with subtle shadows
3. Table-based detail rows (better email client support)
4. Dark mode CSS media query
5. Better visual hierarchy
6. More whitespace

---

## 🔨 IMPLEMENTATION PHASES

### Phase 1: Email Template Modernization (P0) - 3-4h

**Step 1.1: Create new email template components**
```
functions/src/email/
├── templates/
│   ├── base.ts                    # Base HTML structure
│   ├── booking-confirmation.ts    # Confirmation template
│   ├── booking-approved.ts        # Approval template
│   ├── cancellation.ts            # Cancellation template
│   └── reminder.ts                # Reminder template
├── styles/
│   ├── colors.ts                  # Color constants
│   ├── base-styles.ts             # Base CSS
│   └── components.ts              # Component CSS (cards, buttons)
└── utils/
    ├── template-helpers.ts        # HTML helpers
    └── svg-icons.ts               # SVG icon library
```

**Step 1.2: Implement base email structure**
- Create `base.ts` with new card-based layout
- Implement light/dark theme colors
- Add SVG icon system
- Build responsive CSS

**Step 1.3: Migrate sendBookingConfirmationEmail()**
- Use new template structure
- Test rendering in email clients
- Verify dark mode support
- Check accessibility

**Step 1.4: Migrate remaining 9 email functions**
- Apply same template structure
- Reuse shared components
- Maintain feature parity

**Step 1.5: Update resendBookingEmail.ts**
- No changes needed (wrapper only)
- Verify it works with new templates

**Verification**:
- [ ] Test in Gmail (web, mobile)
- [ ] Test in Outlook (desktop, web)
- [ ] Test in Apple Mail
- [ ] Test dark mode in supported clients
- [ ] Run accessibility audit (axe-core)
- [ ] Verify all links work
- [ ] Check image/icon rendering

### Phase 2: Code Organization (P1) - 2-3h

**Step 2.1: Refactor emailService.ts**
```
BEFORE: emailService.ts (1443 lines)
AFTER:
├── email/templates/ (350 lines)
├── email/styles/ (200 lines)
├── email/utils/ (150 lines)
└── email/index.ts (50 lines - exports)
```

**Step 2.2: Review notificationService.ts**
- Check for overlap with emailService
- Merge or clarify separation of concerns
- Update imports across codebase

**Step 2.3: Add TypeScript strict checks**
```typescript
// functions/tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

**Step 2.4: Improve error handling**
- Standardize error logging format
- Add retry logic for email failures
- Implement fallback mechanisms

### Phase 3: Testing & Documentation (P2) - 2-3h

**Step 3.1: Add unit tests**
```typescript
// functions/test/email/templates/booking-confirmation.test.ts
describe('sendBookingConfirmationEmail', () => {
  it('should generate valid HTML', () => {
    const html = generateBookingConfirmationHTML({...});
    expect(html).toContain('<html');
    expect(html).not.toContain('undefined');
  });

  it('should escape HTML in user input', () => {
    const html = generateBookingConfirmationHTML({
      guestName: '<script>alert(1)</script>'
    });
    expect(html).toContain('&lt;script&gt;');
  });

  it('should include dark mode styles', () => {
    const html = generateBookingConfirmationHTML({...});
    expect(html).toContain('@media (prefers-color-scheme: dark)');
  });
});
```

**Step 3.2: Integration tests**
- Test email sending flow
- Verify Resend API integration
- Test subdomain URL generation

**Step 3.3: Documentation**
- Document new email template system
- Add JSDoc comments
- Create email design guide
- Update CLAUDE.md

---

## 📈 EXPECTED OUTCOMES

### Maintainability
- ✅ 1443-line file → 5-6 modular files (~200-350 lines each)
- ✅ Reusable template components
- ✅ Easier to add new email types

### Design Quality
- ✅ Modern 2025 email design
- ✅ Dark mode support
- ✅ Better accessibility (WCAG AA)
- ✅ Consistent with Flutter widget design

### Developer Experience
- ✅ Clear file structure
- ✅ TypeScript strict mode
- ✅ Comprehensive tests
- ✅ Better error handling

### Performance
- ✅ Faster email generation (modular imports)
- ✅ Reduced cold start time
- ✅ Better caching potential

---

## 🚨 RISKS & MITIGATIONS

### Risk 1: Email Client Compatibility
**Impact**: High - Emails might break in Outlook/Gmail
**Mitigation**:
- Test in Litmus/Email on Acid
- Use table-based layout (better support)
- Avoid advanced CSS (flexbox, grid)
- Inline all CSS

### Risk 2: Dark Mode Not Supported
**Impact**: Medium - Some clients don't support prefers-color-scheme
**Mitigation**:
- Light theme is default (works everywhere)
- Dark mode is enhancement
- Use high contrast in both themes

### Risk 3: Breaking Changes
**Impact**: High - Existing emails stop working
**Mitigation**:
- Keep old emailService.ts as backup
- Deploy behind feature flag
- A/B test with small user group
- Rollback plan ready

### Risk 4: Translation/Localization
**Impact**: Medium - All emails currently in Croatian
**Mitigation**:
- Document translation approach
- Use template variables for text
- Prepare for future i18n

---

## 📋 CHECKLIST BEFORE DEPLOYMENT

### Code Quality
- [ ] All TypeScript strict errors resolved
- [ ] No console.log (use logger.ts)
- [ ] All functions have JSDoc comments
- [ ] Error handling on all async operations

### Testing
- [ ] Unit tests pass (>80% coverage)
- [ ] Integration tests pass
- [ ] Manual testing in 3+ email clients
- [ ] Dark mode verified
- [ ] Accessibility audit passed

### Documentation
- [ ] CLAUDE.md updated
- [ ] Email design guide created
- [ ] Migration guide for future templates
- [ ] Comments added to complex logic

### Deployment
- [ ] Backup of current emailService.ts
- [ ] Feature flag implemented (if needed)
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured

---

## 🎯 SUCCESS METRICS

### Quantitative
- Email template file size: 1443 lines → ~800 lines total
- Test coverage: 0% → >80%
- Email render time: baseline → <10% improvement
- Dark mode support: 0% → 60%+ of email clients

### Qualitative
- Easier to add new email types
- Better visual consistency
- Improved accessibility
- Modern, professional appearance

---

## 📝 NEXT STEPS

1. **Review this plan** - Get approval on design direction
2. **Create email mockups** - Design in Figma/HTML first
3. **Start Phase 1** - Begin email template modernization
4. **Test thoroughly** - Don't rush deployment
5. **Deploy gradually** - A/B test if possible

**Estimated Total Time**: 7-10 hours
**Priority**: P0 (Critical - Primary user goal)
**Ready to Start**: ✅ Yes
