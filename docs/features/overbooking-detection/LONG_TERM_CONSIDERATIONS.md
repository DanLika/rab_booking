# Long-Term Considerations for API Integrations

**Status:** 📋 PLANNING / FUTURE WORK
**Zadnje ažurirano:** 2025-12-16

---

## 1. Premium Feature Consideration

### Current Status
API integracije su trenutno dostupne svim korisnicima.
**Napomena:** Direktni API pristup (Booking.com, Airbnb) trenutno NIJE dostupan - vidi [DEVELOPER_SETUP_CHECKLIST.md](../../api-integrations/platform-apis/DEVELOPER_SETUP_CHECKLIST.md)

### Recommendation
**Razmotriti API integracije kao premium feature.**

### Rationale
- **Cost:** API access može biti skup (ako platforme naplaćuju)
- **Value:** Dodaje značajnu vrijednost za korisnike
- **Maintenance:** Zahtijeva održavanje i monitoring
- **Differentiation:** Može biti diferencijator za premium plan

### Implementation Options

#### Option A: Feature Flag per User
```typescript
// Check if user has premium feature enabled
const hasApiSyncAccess = await checkPremiumFeature(userId, 'api_sync');
if (!hasApiSyncAccess) {
  throw new HttpsError('permission-denied', 'API sync is a premium feature');
}
```

#### Option B: Tiered Pricing
- **Basic Plan:** iCal sync only (read-only)
- **Premium Plan:** API sync (two-way)
- **Enterprise Plan:** Advanced features + priority support

#### Option C: Usage-Based Pricing
- Free tier: X sync operations per month
- Paid tier: Unlimited sync operations

### Action Items
- [ ] Implementirati feature flag system
- [ ] Dodati billing check prije omogućavanja API integracija
- [ ] Razmotriti tiered pricing model
- [ ] Ažurirati UI da prikazuje premium badge

## 2. Focus on Update (Not Cancel)

### Current Implementation
✅ **Automatski block** kada se booking kreira/update-uje
✅ **Automatski unblock** kada se booking završi (completed)
❌ **NE automatski unblock** kada se booking cancel-uje

### Rationale
**Cancel operacije su rizične:**
- Ako se booking cancel-uje greškom, datumi se automatski unblock-uju
- To može dovesti do double-booking ako se cancel-ovani booking ponovo aktivira
- Owner možda ne želi da se datumi automatski unblock-uju

### Safety Measures Implemented

1. **Cancel Protection:**
   - Cancelled bookings **NE** automatski unblock-uju datume
   - Zahtijeva manual action sa upozorenjem

2. **Update Focus:**
   - Fokus na update operacije (kreiranje, promjena datuma)
   - Update operacije su sigurnije jer samo blokiraju nove datume

3. **Manual Unblock:**
   - Owner mora eksplicitno odabrati da unblock-uje datume
   - Warning dialog prije unblock operacije

### Future Enhancements

1. **Smart Cancel Rules:**
   - Owner može konfigurisati kada se datumi unblock-uju
   - Opcija za "never auto-unblock on cancel"
   - Opcija za "unblock only if booking was pending"

2. **Confirmation Dialogs:**
   - Prije svake cancel operacije koja unblock-uje datume
   - Prije bulk operacija
   - Prije prve API sync operacije

## 3. Clear Warnings About Consequences

### Implemented Warnings

#### A. Platform Connection Warning
**Location:** `PlatformConnectionsScreen._handleConnectBookingCom()` / `_handleConnectAirbnb()`

**Content:**
- Objašnjenje šta znači two-way sync
- Upozorenje da će se datumi automatski blokirati
- Upozorenje o rizicima i odgovornosti
- Disclaimer o odgovornosti za double-booking

#### B. Header Warning
**Location:** `PlatformConnectionsScreen._buildHeader()`

**Content:**
- Visual warning box sa ikonom
- Lista važnih informacija
- Upozorenje o cancel operacijama

#### C. Code Comments
**Location:** `twoWaySync.ts`

**Content:**
- Jasni komentari o safety measures
- Objašnjenje zašto cancel ne unblock-uje automatski
- Long-term considerations

### Additional Warnings Needed

#### D. Manual Unblock Warning (Future)
```dart
// Prije manual unblock operacije
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('⚠️ Warning: Unblock Dates'),
    content: Text(
      'Unblocking dates will make them available on ${platformName}.\n\n'
      'This could lead to double-booking if:\n'
      '• The booking was cancelled by mistake\n'
      '• You plan to reactivate the booking\n'
      '• Another booking already exists for these dates\n\n'
      'Are you sure you want to unblock these dates?'
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: Text('Yes, Unblock'),
      ),
    ],
  ),
);
```

#### E. Update Warning (Future)
```dart
// Prije update operacije koja mijenja datume
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('⚠️ Update Booking Dates'),
    content: Text(
      'Updating booking dates will:\n'
      '• Unblock old dates on external platforms\n'
      '• Block new dates on external platforms\n\n'
      'Make sure the new dates are not already booked on external platforms.'
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Update'),
      ),
    ],
  ),
);
```

## Implementation Status

### ✅ Completed
- [x] Cancel protection (ne unblock-uje automatski)
- [x] Warning dialog prije povezivanja platforme
- [x] Header warning sa informacijama
- [x] Code comments sa objašnjenjima
- [x] Documentation o rizicima
- [x] iCal Sync (import/export) - **RADI**

### ❌ NOT Implemented (Future Work)
- [ ] Manual unblock warning dialog
- [ ] Update warning dialog
- [ ] Feature flag system za premium
- [ ] Billing integration
- [ ] Smart cancel rules (configurable)
- [ ] Conflict detection prije sync-a
- [ ] Rollback mechanism
- [ ] Audit trail UI
- [ ] Channel Manager API integration (Beds24, etc.)
- [ ] Direktni Booking.com/Airbnb API (zahtijeva partner approval)

## Best Practices

1. **Always warn before destructive operations**
2. **Require explicit confirmation for risky actions**
3. **Provide clear explanations of consequences**
4. **Log all sync operations for audit**
5. **Monitor and alert on unusual patterns**
6. **Provide easy rollback options**

## Compliance

- **Terms of Service:** Owner preuzima odgovornost za sync operacije
- **Data Privacy:** OAuth tokens se enkriptuju
- **Rate Limiting:** Respect platform rate limits
- **Error Handling:** Comprehensive error handling i retry logic

