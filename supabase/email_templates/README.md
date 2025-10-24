# 📧 RAB Booking Email Templates

Beautiful, responsive, branded email templates for authentication flows.

## 🎨 Design

- **Mediterranean Azure Blue** gradient (#0066FF) - matches HomePage UI
- **Responsive** - works on desktop, mobile, tablet
- **Premium look** - glassmorphism, shadows, animations
- **Branded** - RAB Booking logo, colors, and style

## 📁 Templates Included

| Template | File | Use Case | Gradient |
|---|---|---|---|
| **Signup Verification** | `confirm_signup.html` | Email verification after signup | Azure Blue |
| **User Invitation** | `invite.html` | Invite user to platform | Sunset (Gold→Coral→Blue) |
| **Magic Link** | `magic_link.html` | Passwordless login | Green→Blue |
| **Email Change** | `change_email.html` | Confirm email address change | Azure Blue |
| **Password Reset** | `reset_password.html` | Reset forgotten password | Red |
| **Reauthentication** | `reauthenticate.html` | 2FA / verification code | Azure Blue |

## 🚀 How to Use

### 1. Copy Template to Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij/auth/templates
2. Click on a template (e.g., "Confirm signup")
3. Copy HTML from corresponding `.html` file
4. Paste into "Message (HTML)" field
5. Click "Save"
6. Send test email to verify

### 2. Configure Site URL

Go to: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij/auth/url-configuration

**For Web App:**
- Site URL: `https://rabbooking-gui6m.sevalla.page`
- Redirect URLs: `https://rabbooking-gui6m.sevalla.page/**`

**For Mobile App (Deep Links):**
- Site URL: `rabbooking://auth/callback`
- Redirect URLs: `rabbooking://auth/**`

See `../../DEEP_LINKS_SETUP.md` for full mobile configuration.

## 🎨 Color Palette

```css
/* Primary Gradient - Azure Blue */
background: linear-gradient(135deg, #3385FF 0%, #0066FF 50%, #0052CC 100%);

/* Secondary Gradient - Coral Sunset */
background: linear-gradient(135deg, #FF8E8E 0%, #FF6B6B 50%, #E63946 100%);

/* Tertiary Gradient - Golden Sand */
background: linear-gradient(135deg, #FFCA80 0%, #FFB84D 50%, #FF9500 100%);

/* Success Gradient - Emerald */
background: linear-gradient(135deg, #10B981 0%, #0066FF 100%);

/* Error Gradient - Red */
background: linear-gradient(135deg, #EF4444 0%, #DC2626 100%);
```

## 📱 Variables Available

Use these in your templates:

| Variable | Description | Example |
|---|---|---|
| `{{ .ConfirmationURL }}` | Verification/reset link | https://... or rabbooking://... |
| `{{ .SiteURL }}` | Your site URL | https://rabbooking-gui6m.sevalla.page |
| `{{ .Email }}` | User's current email | user@example.com |
| `{{ .NewEmail }}` | New email (change email) | newemail@example.com |
| `{{ .Token }}` | Reauthentication code | 123456 |

## 🧪 Testing

### Send Test Email (Supabase Dashboard)

1. Open template in Dashboard
2. Click "Send test email"
3. Enter your email
4. Check inbox (and spam!)

### Test Real Flow

1. Sign up at: https://rabbooking-gui6m.sevalla.page/signup
2. Check email
3. Click "Verify Email" button
4. Should redirect to Site URL

## 🎯 Template Features

### All Templates Include:

✅ Responsive design (mobile, tablet, desktop)
✅ Email-client compatible (Gmail, Outlook, Apple Mail)
✅ Inline CSS (for maximum compatibility)
✅ Footer with brand info and links
✅ Security notices (expiration, warnings)
✅ Copy-paste fallback link (if button doesn't work)
✅ Professional gradient header
✅ Icon badges with matching colors
✅ CTA buttons with hover effects (where supported)

## 📂 File Structure

```
email_templates/
├── README.md                       # This file
├── email_template_base.html        # Base template (reference only)
├── confirm_signup.html             # ✉️ Email verification
├── invite.html                     # 🎊 User invitation
├── magic_link.html                 # 🔑 Magic link login
├── change_email.html               # 📧 Email change
├── reset_password.html             # 🔒 Password reset
└── reauthenticate.html             # 🔐 2FA code
```

## 🔧 Customization

### Change Logo Text

```html
<!-- Find this in any template: -->
<div class="logo">RAB Booking</div>
<div class="logo-subtitle">Luxury Vacation Rentals</div>

<!-- Change to: -->
<div class="logo">Your Brand</div>
<div class="logo-subtitle">Your Tagline</div>
```

### Change Primary Color

```html
<!-- Find gradient: -->
background: linear-gradient(135deg, #3385FF 0%, #0066FF 50%, #0052CC 100%);

<!-- Replace with your color: -->
background: linear-gradient(135deg, #YOUR_COLOR_1 0%, #YOUR_COLOR_2 50%, #YOUR_COLOR_3 100%);
```

### Add Footer Links

```html
<!-- Find footer section: -->
<div class="footer-links">
  <a href="{{ .SiteURL }}/properties" class="footer-link">Properties</a>
  <!-- Add your link: -->
  <a href="{{ .SiteURL }}/your-page" class="footer-link">Your Page</a>
</div>
```

## 📊 Email Client Compatibility

Tested and working on:
- ✅ Gmail (Web)
- ✅ Gmail (iOS/Android App)
- ✅ Apple Mail (macOS/iOS)
- ✅ Outlook (Web)
- ✅ Outlook (Desktop)
- ✅ Yahoo Mail
- ✅ ProtonMail

## 🐛 Troubleshooting

### Email not arriving?

- Check spam folder
- Verify email auth is enabled in Supabase Dashboard
- Check rate limits (max 4 emails/hour in free tier)

### Link goes to localhost?

- Update Site URL in Supabase Dashboard → Auth → URL Configuration

### Design looks broken?

- Some email clients strip CSS
- Templates use inline styles for maximum compatibility
- Test in different email clients

## 📚 Resources

- **Full Setup Guide:** `../../EMAIL_TEMPLATES_SETUP_GUIDE.md`
- **Deep Links Setup:** `../../DEEP_LINKS_SETUP.md`
- **Supabase Auth Docs:** https://supabase.com/docs/guides/auth/auth-email-templates

---

**Made with 💙 for RAB Booking**
