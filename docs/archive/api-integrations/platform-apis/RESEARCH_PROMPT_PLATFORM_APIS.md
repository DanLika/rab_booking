# Research Prompt: Booking.com i Airbnb API Integration

## Prompt za Cloud Research

Koristi ovaj prompt za Cloud Research da istražiš Booking.com i Airbnb API integracije:

---

**RESEARCH PROMPT:**

Potrebno mi je detaljno istraživanje o API integracijama za Booking.com i Airbnb za calendar management i two-way sync funkcionalnost. Konkretno trebam saznati:

### Booking.com API Integration:

1. **Developer Program Access:**
   - Da li postoji Booking.com Developer Program ili Partner Hub?
   - Da li je potrebna registracija kao developer?
   - Da li je potrebna firma/company registracija ili mogu kao individual developer?
   - Koji su zahtjevi za pristup (dokumentacija, business verification, itd.)?
   - Da li postoji free tier ili samo paid plans?
   - Koliko traje approval process?

2. **API Access:**
   - Koji su dostupni API endpoint-ovi za calendar management?
   - Da li postoji Calendar API ili Availability API?
   - Koji su OAuth 2.0 endpoint-ovi (authorization URL, token URL)?
   - Da li postoji sandbox/test environment?
   - Koje su rate limits?
   - Koje su cijene/planovi (ako postoje)?

3. **OAuth Flow:**
   - Kako funkcioniše OAuth 2.0 flow?
   - Koje scope-ove treba tražiti?
   - Kako se dobija refresh token?
   - Koliko traje access token?

4. **Calendar Operations:**
   - Kako se blokiraju datumi (block dates/unavailable dates)?
   - Kako se ažurira availability?
   - Kako se čitaju rezervacije?
   - Da li postoji webhook support za real-time updates?

5. **Documentation:**
   - Gdje se nalazi API dokumentacija?
   - Postoje li code examples ili SDK-ovi?
   - Postoje li best practices guide-ovi?

### Airbnb API Integration:

1. **Developer Program Access:**
   - Da li postoji Airbnb Developer Program ili Partner API?
   - Da li je potrebna registracija kao developer?
   - Da li je potrebna firma/company registracija ili mogu kao individual developer?
   - Koji su zahtjevi za pristup (dokumentacija, business verification, itd.)?
   - Da li postoji free tier ili samo paid plans?
   - Koliko traje approval process?

2. **API Access:**
   - Koji su dostupni API endpoint-ovi za calendar management?
   - Da li postoji Calendar API ili Availability API?
   - Koji su OAuth 2.0 endpoint-ovi (authorization URL, token URL)?
   - Da li postoji sandbox/test environment?
   - Koje su rate limits?
   - Koje su cijene/planovi (ako postoje)?

3. **OAuth Flow:**
   - Kako funkcioniše OAuth 2.0 flow?
   - Koje scope-ove treba tražiti?
   - Kako se dobija refresh token?
   - Koliko traje access token?

4. **Calendar Operations:**
   - Kako se blokiraju datumi (block dates/unavailable dates)?
   - Kako se ažurira availability?
   - Kako se čitaju rezervacije?
   - Da li postoji webhook support za real-time updates?

5. **Documentation:**
   - Gdje se nalazi API dokumentacija?
   - Postoje li code examples ili SDK-ovi?
   - Postoje li best practices guide-ovi?

### Alternativni Pristupi:

1. **Channel Managers:**
   - Da li postoje third-party channel manager servisi koji omogućavaju API pristup?
   - Koji su najpopularniji (npr. Guesty, Hostfully, Syncbnb)?
   - Da li oni omogućavaju API pristup za calendar sync?

2. **iCal Two-Way Sync:**
   - Da li postoji način da se koristi iCal za two-way sync (ne samo read-only)?
   - Postoje li workaround-ovi ili alternativni pristupi?

### Specifična Pitanja:

1. **Za MVP/Startup:**
   - Mogu li početi bez firme/company registracije?
   - Postoji li free tier ili trial period?
   - Koji je najbrži način da dobijem pristup za testing?

2. **Za Produkciju:**
   - Koji su production requirements?
   - Da li je potrebna business verification?
   - Koje su cijene za production use?

3. **Alternativne Platforme:**
   - Postoje li alternative platforme koje imaju bolji API pristup?
   - Da li postoje aggregator servisi koji omogućavaju pristup više platformi kroz jedan API?

### Output Format:

Molim te da organizuješ rezultate u sljedećem formatu:

**Booking.com:**
- [Status: Available/Not Available/Requires Approval]
- [Access Requirements: Lista zahtjeva]
- [API Endpoints: Lista endpoint-ova]
- [OAuth Flow: Detalji]
- [Documentation Links: URL-ovi]
- [Cost: Free/Paid/Custom]
- [Timeline: Koliko traje setup]

**Airbnb:**
- [Status: Available/Not Available/Requires Approval]
- [Access Requirements: Lista zahtjeva]
- [API Endpoints: Lista endpoint-ova]
- [OAuth Flow: Detalji]
- [Documentation Links: URL-ovi]
- [Cost: Free/Paid/Custom]
- [Timeline: Koliko traje setup]

**Alternativni Pristupi:**
- [Channel Managers: Lista opcija]
- [iCal Two-Way: Mogućnosti]
- [Other Options: Ostale opcije]

**Preporuke:**
- [Za MVP: Najbolji pristup]
- [Za Produkciju: Najbolji pristup]
- [Timeline: Realističan timeline za implementaciju]

---

## Kako Koristiti Ovaj Prompt

1. Kopiraj cijeli prompt iznad
2. Otvori Cloud Research tool
3. Zalijepi prompt
4. Analiziraj rezultate
5. Ažuriraj `docs/PLATFORM_API_INTEGRATION_SETUP.md` sa rezultatima

## Dodatni Koraci Nakon Research-a

1. **Ažuriraj dokumentaciju** sa stvarnim informacijama
2. **Kreiraj action plan** za dobijanje pristupa
3. **Ažuriraj kod** sa stvarnim API endpoint-ima
4. **Setup environment variables** nakon dobijanja credentials
5. **Test u sandbox** okruženju (ako postoji)
6. **Deploy i test** u produkciji

