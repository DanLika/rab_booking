# Channel Manager Setup Guide

**Status**: 📋 DOKUMENTACIJA ONLY (Kod nije implementiran)
**Last Updated**: 2025-12-16

---

## ⚠️ VAŽNO: Trenutni Status

| Komponenta | Status | Napomena |
|------------|--------|----------|
| **Dokumentacija** | ✅ KOMPLETNA | Setup guide za Beds24, Hosthub, Guesty |
| **BookBed kod** | ❌ NE POSTOJI | Nema `channelManagerApi.ts` fajla |
| **UI u aplikaciji** | ❌ NE POSTOJI | Nema "Connect Beds24" screena |

### Šta RADI trenutno (alternativa)

| Funkcionalnost | Status |
|----------------|--------|
| **iCal Sync** | ✅ IMPLEMENTIRANO - import/export kalendara |

Ako treba samo kalendarska sinhronizacija bez two-way sync, koristi iCal koji već radi.

---

## Overview

This guide provides step-by-step instructions for setting up channel manager integrations (Beds24, Hosthub, Guesty) as the practical alternative to direct Booking.com and Airbnb API access.

## Why Channel Managers?

Direct API access to Booking.com and Airbnb is effectively unavailable:
- **Booking.com:** Partner program PAUSED, requires business registration
- **Airbnb:** Invitation-only, no public API

Channel managers provide:
- ✅ Immediate API access (no approval needed)
- ✅ Two-way calendar sync (seconds to minutes latency)
- ✅ Webhook support for real-time notifications
- ✅ Standard OAuth 2.0 or API key authentication
- ✅ Individual accounts accepted (no business registration)

## Recommended: Beds24 (Best for MVP)

### Step 1: Create Account

1. Go to https://www.beds24.com/
2. Click "Start Free Trial" (unlimited, no credit card required)
3. Sign up with email (individual account accepted)
4. Verify email address

### Step 2: Connect Listings

1. **Add Property:**
   - Go to "Properties" → "Add Property"
   - Enter property details
   - Save property ID (you'll need this for API)

2. **Connect Booking.com:**
   - Go to "Channels" → "Booking.com"
   - Click "Connect"
   - Follow OAuth flow to authorize Beds24
   - Map property to Booking.com listing

3. **Connect Airbnb:**
   - Go to "Channels" → "Airbnb"
   - Click "Connect"
   - Follow OAuth flow to authorize Beds24
   - Map property to Airbnb listing

### Step 3: Get API Credentials

1. Go to "Settings" → "API"
2. Click "Generate API Key"
3. Copy API key (you'll need this for integration)
4. Note your Property ID from Properties page

### Step 4: Test API Connection

```bash
# Test API key
curl -X GET "https://api.beds24.com/v2/properties" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Step 5: Integrate with BookBed

1. **Add Connection in BookBed:**
   - Go to Platform Connections screen
   - Click "Connect Beds24"
   - Enter:
     - Unit ID (your BookBed unit ID)
     - Property ID (from Beds24)
     - API Key (from Beds24)

2. **Test Sync:**
   - Create a booking in BookBed
   - Verify dates are blocked in Beds24
   - Check Booking.com and Airbnb calendars

## Alternative: Hosthub

### Step 1: Create Account

1. Go to https://www.hosthub.com/
2. Click "Start Free Trial" (14 days)
3. Sign up with email
4. Verify email address

### Step 2: Connect Listings

1. **Add Property:**
   - Go to "Properties" → "Add New"
   - Enter property details

2. **Connect Channels:**
   - Go to "Channels" → "Connect"
   - Connect Booking.com and Airbnb
   - Map properties

### Step 3: Get API Credentials

1. Go to "Settings" → "API"
2. Generate API key
3. Copy API key and Property ID

### Step 4: Integrate with BookBed

Similar to Beds24 integration process.

## Alternative: Guesty (Enterprise)

### Step 1: Create Account

1. Go to https://www.guesty.com/
2. Contact sales for demo
3. Sign up for Guesty Pro plan ($250+/month)

### Step 2: Connect Listings

1. **Add Properties:**
   - Import properties via CSV or manual entry
   - Connect Booking.com and Airbnb accounts

### Step 3: Get API Credentials

1. Go to "Settings" → "API"
2. Create OAuth application
3. Get Client ID and Client Secret
4. Follow OAuth 2.0 flow

### Step 4: Integrate with BookBed

Use Guesty's OAuth 2.0 flow for authentication.

## API Integration Code

### Beds24 API Example

```typescript
// Block dates
const response = await fetch(
  `https://api.beds24.com/v2/properties/${propertyId}/calendar/block`,
  {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      start_date: "2024-12-01",
      end_date: "2024-12-05",
      blocked: true,
    }),
  }
);
```

### Webhook Setup

1. **Beds24:**
   - Go to "Settings" → "API" → "Webhooks"
   - Add webhook URL: `https://your-cloud-function.com/webhooks/beds24`
   - Select events: "New Booking", "Booking Modified", "Booking Cancelled"

2. **Hosthub:**
   - Go to "Settings" → "Webhooks"
   - Add webhook URL
   - Select events

3. **Guesty:**
   - Go to "Settings" → "Webhooks"
   - Add webhook URL
   - Select events

## Cost Comparison

| Platform | Monthly Cost (1 property) | Monthly Cost (10 properties) | Free Trial |
|----------|---------------------------|------------------------------|------------|
| **Beds24** | €15.50 | ~€50 | Unlimited |
| **Hosthub** | $28 | ~$140 | 14 days |
| **Lodgify** | $16 | ~$80 | 7 days |
| **Guesty Pro** | $250 | $250 (unlimited) | Demo only |

## Troubleshooting

### API Key Not Working

- Verify API key is correct
- Check API key permissions in channel manager settings
- Ensure property ID matches

### Dates Not Syncing

- Check webhook configuration
- Verify property mapping (BookBed unit → Channel manager property)
- Check channel manager logs for errors

### Webhooks Not Receiving Events

- Verify webhook URL is accessible (HTTPS required)
- Check webhook signature validation
- Review channel manager webhook logs

## Next Steps

1. Choose channel manager (recommend Beds24 for MVP)
2. Create account and connect listings
3. Get API credentials
4. Integrate with BookBed using provided code examples
5. Test end-to-end sync
6. Deploy to production

## Support

- **Beds24:** wiki.beds24.com (API documentation)
- **Hosthub:** support@hosthub.com
- **Guesty:** https://open-api-docs.guesty.com/

