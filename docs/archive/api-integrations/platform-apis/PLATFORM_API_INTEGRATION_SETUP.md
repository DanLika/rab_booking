# Platform API Integration Setup Guide

## ⚠️ Important Update: Direct API Access Reality

**As of late 2024, direct API access to Booking.com and Airbnb is effectively unavailable for individual developers and startups.**

- **Booking.com:** Partner program PAUSED, requires business registration
- **Airbnb:** Invitation-only, no public API

**Recommended Approach:** Use channel manager APIs (Beds24, Hosthub, Guesty) instead. See [Channel Manager Setup Guide](../channel-managers/CHANNEL_MANAGER_SETUP.md) for practical implementation.

**For detailed information:** See [API Access Reality Check](./API_ACCESS_REALITY_CHECK.md)

---

## Overview

This document outlines the setup process for integrating with Booking.com and Airbnb APIs for two-way calendar synchronization. **Note: Direct API access is currently not feasible due to access restrictions.**

## Booking.com API Integration

### Status: ⚠️ NOT AVAILABLE (Partner Program PAUSED)

**Current Situation:**
- Partner program is **PAUSED** for new applications
- Requires business registration (individual developers rejected)
- Requires PCI DSS and EU data protection compliance
- Historical timeline: 3-6 months when accepting applications
- **Currently: Indefinite wait time**

**Technical Details:**
- Does **NOT** use standard OAuth 2.0 (proprietary token-based auth)
- Uses OTA XML format (not JSON)
- No reservation webhooks (must poll Reservations API)
- API is free, but access is tightly controlled

**Documentation:** https://developers.booking.com/connectivity/docs (restricted access)

**Monitor Status:** https://connect.booking.com

## Airbnb API Integration

### Status: ⚠️ NOT AVAILABLE (Invitation-Only)

**Current Situation:**
- **No public API exists**
- Invitation-only program (Airbnb contacts prospects)
- Requires business entity (individuals cannot access)
- Requires security review and NDA
- **No guaranteed approval**

**Technical Details:**
- Uses standard OAuth 2.0 (for approved partners)
- RESTful JSON API
- Webhook support available (must respond within 8 seconds)
- Custom pricing per partner

**Documentation:** https://developer.airbnb.com/ (restricted access)

## Alternative: Channel Manager APIs (RECOMMENDED)

### Why Channel Managers?

Third-party channel managers have already completed partnership certifications with Booking.com and Airbnb. They provide:
- ✅ Immediate API access (no approval needed)
- ✅ Two-way calendar sync (seconds to minutes latency)
- ✅ Webhook support for real-time notifications
- ✅ Standard OAuth 2.0 or API key authentication
- ✅ Individual accounts accepted (no business registration)

### Recommended Options

**For MVP (1-5 properties):**
- **Beds24:** €15.50/month, unlimited free trial, comprehensive API
- **Lodgify:** $16/month, 7-day free trial
- **Hosthub:** $28/month, 14-day free trial

**For Production (5-50 properties):**
- **Beds24:** ~€25-50/month
- **Hosthub:** ~$55-140/month
- **Guesty Lite:** $16/month (3 properties max)

**For Enterprise (50+ properties):**
- **Guesty Pro:** $250-600+/month
- **Hostaway:** Custom (~$50/property)
- **Cloudbeds:** $108+/month

**See:** [Channel Manager Setup Guide](./CHANNEL_MANAGER_SETUP.md) for detailed setup instructions.

## Current Implementation Status

### Direct API Code (Not Feasible)

The following files contain placeholder code for direct API integration:
- `functions/src/bookingComApi.ts` - Booking.com API (marked as NOT AVAILABLE)
- `functions/src/airbnbApi.ts` - Airbnb API (marked as NOT AVAILABLE)

**These files are kept for reference but will not work without partner approval.**

### Channel Manager Code (To Be Implemented)

New implementation needed:
- `functions/src/channelManager/beds24Api.ts` - Beds24 API integration
- `functions/src/channelManager/hosthubApi.ts` - Hosthub API integration
- `functions/src/channelManager/guestyApi.ts` - Guesty API integration

**See:** [Channel Manager Integration Strategy](../../../.cursor/plans/api-integrations/channel_manager_integration_strategy.md)

## Environment Variables

### For Direct API (Not Available)

These would be needed if direct API access becomes available:

```
BOOKING_COM_CLIENT_ID=your_client_id
BOOKING_COM_CLIENT_SECRET=your_client_secret
BOOKING_COM_REDIRECT_URI=https://your-domain.com/api/booking-com-oauth-callback
AIRBNB_CLIENT_ID=your_client_id
AIRBNB_CLIENT_SECRET=your_client_secret
AIRBNB_REDIRECT_URI=https://your-domain.com/api/airbnb-oauth-callback
```

### For Channel Manager APIs (Recommended)

```
BEDS24_API_KEY=your_beds24_api_key
HOSTHUB_API_KEY=your_hosthub_api_key
GUESTY_CLIENT_ID=your_guesty_client_id
GUESTY_CLIENT_SECRET=your_guesty_client_secret
```

## Next Steps

### Immediate (Recommended)

1. **Create Beds24 account** (unlimited free trial)
2. **Connect test listings** (Booking.com, Airbnb)
3. **Get API credentials** (same-day access)
4. **Integrate Beds24 API** (1-2 weeks to production)

**See:** [Channel Manager Setup Guide](./CHANNEL_MANAGER_SETUP.md)

### Long-Term (If Direct API Becomes Available)

1. **Monitor Booking.com status** at https://connect.booking.com
2. **Build business scale** to attract Airbnb partnership attention
3. **Apply when programs reopen** (if they do)
4. **Wait for approval** (months to indefinite)

## Research Resources

- [API Access Reality Check](./API_ACCESS_REALITY_CHECK.md) - Detailed analysis
- [Channel Manager Setup Guide](../channel-managers/CHANNEL_MANAGER_SETUP.md) - Step-by-step setup
- [Channel Manager Integration Strategy](../../../.cursor/plans/api-integrations/channel_manager_integration_strategy.md) - Implementation plan
- [Research Prompt](./RESEARCH_PROMPT_PLATFORM_APIS.md) - Original research prompt

## Summary

**For immediate development:** Use channel manager APIs (Beds24 recommended for MVP)

**For production reliability:** Guesty Pro or Hostaway provide enterprise-grade sync

**For direct API access:** Monitor Booking.com's partner registration status—expect months of waiting when it reopens. For Airbnb, build sufficient business scale to attract their partnership team's attention.

**The reality:** Channel managers aren't just a workaround—they're the intended architecture for API access to these platforms.
