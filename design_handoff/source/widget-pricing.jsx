/* eslint-disable */
// Booking widget · Pricing panel + breakdown modal — Prompt 27.
// Continues widget visual language (mint accent, near-black ink). HR-localized.
// Anchored to owner sample booking BB-2402: Studio · 08.07–11.07 (3 noći) · €360 total · €72 polog (20%).
// Weekend night (Pet) priced €130, length-of-stay discount nets back to €360.

const WP_MINT = '#3DD9B0';
const WP_MINT_DEEP = '#1FAF87';
const WP_INK = '#1B2330';
const WP_MUTED = '#7C8593';
const WP_BORDER = '#ECEEF1';

const WP_NIGHTS = [
  { dow: 'Sri', date: '08.07.', rate: '€130,00' },
  { dow: 'Čet', date: '09.07.', rate: '€130,00' },
  { dow: 'Pet', date: '10.07.', rate: '€130,00', weekend: true },
];

// ──────────────────────────────────────────────────────────────
// Mini unit hero (shared)
// ──────────────────────────────────────────────────────────────
const WPMiniHero = ({ compact = false }) => (
  <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
    <div style={{
      width: compact ? 44 : 52, height: compact ? 44 : 52, borderRadius: 12, flexShrink: 0,
      background: 'linear-gradient(135deg, #6B4CE6 0%, #8B6FFF 50%, #A78BFF 100%)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: '#FFFFFF',
      boxShadow: '0 4px 12px rgba(107, 76, 230, 0.26)',
    }}>
      <BBIcon name="apartment" size={compact ? 20 : 24} />
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: WP_MUTED }}>Vila Marina</div>
      <div style={{ fontSize: compact ? 14 : 15, fontWeight: 700, color: WP_INK, letterSpacing: '-0.005em' }}>Studio s pogledom na more</div>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Date pill (shared)
// ──────────────────────────────────────────────────────────────
const WPDatePill = () => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 8,
    padding: '8px 12px', background: '#F1F2F4', borderRadius: 999,
  }}>
    <BBIcon name="event" size={14} style={{ color: WP_MUTED }} />
    <span style={{ fontSize: 13, fontWeight: 600, color: WP_INK, fontVariantNumeric: 'tabular-nums' }}>08.07. – 11.07.2026</span>
    <span style={{ background: WP_MINT, color: '#FFFFFF', padding: '2px 8px', borderRadius: 999, fontSize: 11, fontWeight: 700 }}>3 noći</span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Line item rows
// ──────────────────────────────────────────────────────────────
const WPNightRow = ({ dow, date, rate, weekend }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0' }}>
    <div style={{
      width: 40, textAlign: 'center', flexShrink: 0,
    }}>
      <div style={{ fontSize: 11, fontWeight: 600, color: weekend ? '#FF7A6B' : WP_MUTED, textTransform: 'uppercase', letterSpacing: '0.04em' }}>{dow}</div>
      <div style={{ fontSize: 13, fontWeight: 700, color: WP_INK, fontVariantNumeric: 'tabular-nums' }}>{date}</div>
    </div>
    <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
      <span style={{ fontSize: 13, color: WP_INK }}>Noćenje</span>
      {weekend && (
        <span style={{ fontSize: 10, fontWeight: 700, color: '#FF7A6B', background: 'rgba(255,122,107,0.12)', padding: '2px 7px', borderRadius: 999 }}>VIKEND</span>
      )}
    </div>
    <span style={{ fontSize: 14, fontWeight: 600, color: WP_INK, fontVariantNumeric: 'tabular-nums' }}>{rate}</span>
  </div>
);

const WPLine = ({ label, value, note, tone, strong = false, badge }) => {
  const color = tone === 'discount' ? WP_MINT_DEEP : tone === 'muted' ? WP_MUTED : WP_INK;
  return (
    <div style={{ padding: '6px 0' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
        <span style={{ fontSize: 13, fontWeight: strong ? 700 : 500, color: tone === 'muted' ? WP_MUTED : WP_INK, display: 'inline-flex', alignItems: 'center', gap: 8 }}>
          {label}
          {badge && <span style={{ fontSize: 10, fontWeight: 700, color: WP_MUTED, background: '#F1F2F4', padding: '2px 7px', borderRadius: 999 }}>{badge}</span>}
        </span>
        <span style={{ fontSize: strong ? 14 : 13, fontWeight: strong ? 800 : 600, color, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
      </div>
      {note && <div style={{ fontSize: 11, color: WP_MUTED, marginTop: 2 }}>{note}</div>}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Deposit band (shared)
// ──────────────────────────────────────────────────────────────
const WPDepositBand = () => (
  <div style={{
    padding: 14,
    background: 'rgba(61, 217, 176, 0.10)',
    border: '1px solid rgba(61, 217, 176, 0.32)',
    borderRadius: 12,
  }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
      <span style={{ fontSize: 12, fontWeight: 700, color: WP_MINT_DEEP, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Polog danas</span>
      <span style={{ fontSize: 18, fontWeight: 800, color: WP_MINT_DEEP, fontVariantNumeric: 'tabular-nums' }}>€72,00</span>
    </div>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 6 }}>
      <span style={{ fontSize: 11, color: WP_MUTED }}>20% — preostatak plaćate vlasniku na licu mjesta</span>
      <span style={{ fontSize: 12, fontWeight: 600, color: WP_MUTED, fontVariantNumeric: 'tabular-nums' }}>€288,00</span>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Full breakdown body (shared by modal + sheet)
// ──────────────────────────────────────────────────────────────
const WPBreakdownBody = () => (
  <div>
    {/* Per-night list */}
    <div style={{ borderBottom: `1px solid ${WP_BORDER}` }}>
      {WP_NIGHTS.map((n, i) => <WPNightRow key={i} {...n} />)}
    </div>
    {/* Adjustments */}
    <div style={{ padding: '8px 0', borderBottom: `1px solid ${WP_BORDER}` }}>
      <WPLine label="Međuzbroj noćenja" value="€390,00" tone="muted" />
      <WPLine label="Popust za duži boravak" value="−€30,00" tone="discount" badge="3+ noći" note="Automatski popust za boravak od 3 i više noći." />
    </div>
    {/* Tax (on site) */}
    <div style={{ padding: '8px 0', borderBottom: `1px solid ${WP_BORDER}` }}>
      <WPLine label="Boravišna pristojba" value="€9,00" tone="muted" badge="Na licu mjesta" note="2 osobe × 3 noći × €1,50 — ne ulazi u online plaćanje." />
    </div>
    {/* Total */}
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '14px 0' }}>
      <span style={{ fontSize: 13, fontWeight: 700, color: WP_INK, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Ukupno smještaj</span>
      <span style={{ fontSize: 24, fontWeight: 800, color: WP_INK, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>€360,00</span>
    </div>
    <WPDepositBand />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Buttons
// ──────────────────────────────────────────────────────────────
const WPInkButton = ({ icon, children, full = false, height = 52 }) => (
  <button style={{
    height, width: full ? '100%' : 'auto', padding: full ? 0 : '0 22px',
    border: 'none', cursor: 'pointer',
    background: WP_INK, color: '#FFFFFF', borderRadius: 14,
    fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    boxShadow: '0 6px 18px rgba(27,35,48,0.22)',
  }}>
    {children}
    {icon && <BBIcon name={icon} size={18} />}
  </button>
);

const WPCloseBtn = () => (
  <button style={{
    width: 36, height: 36, borderRadius: '50%', border: `1px solid ${WP_BORDER}`,
    background: '#FFFFFF', cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
  }} aria-label="Zatvori">
    <BBIcon name="close" size={18} style={{ color: WP_INK }} />
  </button>
);

const WPPoweredBy = ({ style = {} }) => (
  <div style={{ textAlign: 'center', color: '#9AA0AC', fontSize: 11, ...style }}>
    Powered by <span style={{ fontWeight: 700, color: '#6B4CE6' }}>BookBed</span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pricing PANEL (embedded standalone — collapsed summary + trigger)
// ──────────────────────────────────────────────────────────────
const WPPanel = ({ compact = false }) => (
  <div style={{
    width: '100%',
    background: '#FFFFFF', borderRadius: 20,
    border: `1px solid ${WP_BORDER}`,
    boxShadow: '0 12px 28px rgba(20, 30, 50, 0.08)',
    padding: compact ? 16 : 20,
  }}>
    <WPMiniHero compact={compact} />
    <div style={{ marginTop: 14 }}><WPDatePill /></div>

    {/* Collapsed lines */}
    <div style={{ marginTop: 16, paddingTop: 4 }}>
      <WPLine label="Smještaj" value="€360,00" badge="3 noći" note="Uključen popust za duži boravak (−€30,00)." />
      <WPLine label="Boravišna pristojba" value="€9,00" tone="muted" badge="Na licu mjesta" />
    </div>

    {/* Show details trigger */}
    <button style={{
      display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 8,
      border: 'none', background: 'transparent', cursor: 'pointer', padding: 0,
      color: WP_INK, fontSize: 13, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBIcon name="receipt_long" size={16} />
      Prikaži razradu cijene
      <BBIcon name="expand_more" size={16} style={{ color: WP_MUTED }} />
    </button>

    <div style={{ height: 1, background: WP_BORDER, margin: '16px 0' }} />

    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
      <span style={{ fontSize: 12, fontWeight: 700, color: WP_INK, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Ukupno</span>
      <span style={{ fontSize: 22, fontWeight: 800, color: WP_INK, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>€360,00</span>
    </div>

    <div style={{ marginBottom: 16 }}><WPDepositBand /></div>

    <button style={{
      height: 52, width: '100%', border: 'none', cursor: 'pointer',
      background: WP_INK, color: '#FFFFFF', borderRadius: 14,
      fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: '0 6px 18px rgba(27,35,48,0.24)',
    }}>
      Rezerviraj sad
      <BBIcon name="arrow_forward" size={18} />
    </button>
    <div style={{ fontSize: 11, color: WP_MUTED, textAlign: 'center', marginTop: 10 }}>
      Naplaćujemo samo polog. Preostatak plaćate na licu mjesta.
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Modal card (shared inner)
// ──────────────────────────────────────────────────────────────
const WPModalCard = ({ width = 460 }) => (
  <div style={{
    width, maxWidth: '100%',
    background: '#FFFFFF', borderRadius: 24,
    boxShadow: '0 32px 64px rgba(15, 22, 38, 0.32)',
    overflow: 'hidden',
    fontFamily: 'var(--bb-font-sans)', color: WP_INK,
  }}>
    {/* Header */}
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 12,
      padding: '20px 20px 16px', borderBottom: `1px solid ${WP_BORDER}`,
    }}>
      <div style={{ flex: 1 }}>
        <h3 style={{ margin: 0, fontSize: 18, fontWeight: 800, color: WP_INK, letterSpacing: '-0.01em' }}>Razrada cijene</h3>
        <div style={{ fontSize: 12, color: WP_MUTED, marginTop: 4 }}>Studio s pogledom na more · 08.07.–11.07.2026</div>
      </div>
      <WPCloseBtn />
    </div>
    {/* Body */}
    <div style={{ padding: '8px 20px 20px' }}>
      <WPBreakdownBody />
    </div>
    {/* Footer */}
    <div style={{ padding: 16, borderTop: `1px solid ${WP_BORDER}`, background: '#FBFCFE' }}>
      <WPInkButton icon="arrow_forward" full>Nastavi na plaćanje</WPInkButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────

// Panel — embedded (1080 host frame, panel centered narrow)
const WidgetPricingPanelEmbedded = () => (
  <div style={{
    width: 1080, padding: '40px 40px 28px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', color: WP_INK,
  }}>
    <div style={{ maxWidth: 760, margin: '0 auto' }}>
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase', color: WP_MUTED }}>Korak 2 od 3</div>
        <h1 style={{ margin: '6px 0 0', fontSize: 26, fontWeight: 800, color: WP_INK, letterSpacing: '-0.02em' }}>Pregled cijene</h1>
      </div>
      <div style={{ maxWidth: 420, margin: '0 auto' }}>
        <WPPanel />
      </div>
    </div>
    <WPPoweredBy style={{ marginTop: 28 }} />
  </div>
);

// Modal — desktop (dimmed backdrop + centered card)
const WidgetPricingModalDesktop = () => (
  <div style={{
    width: 960, height: 760, position: 'relative',
    background: 'rgba(15, 22, 38, 0.55)',
    fontFamily: 'var(--bb-font-sans)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    padding: 24,
  }}>
    {/* faint host hint behind the scrim */}
    <div style={{
      position: 'absolute', inset: 0,
      background: 'repeating-linear-gradient(135deg, rgba(255,255,255,0.04) 0 14px, rgba(255,255,255,0) 14px 28px)',
      pointerEvents: 'none',
    }} />
    <WPModalCard width={460} />
  </div>
);

// Modal — mobile bottom sheet
const WidgetPricingModalMobile = () => (
  <div style={{
    width: 390, height: 880, position: 'relative',
    background: 'rgba(15, 22, 38, 0.55)',
    fontFamily: 'var(--bb-font-sans)', color: WP_INK,
    display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
  }}>
    <div style={{
      background: '#FFFFFF',
      borderRadius: '24px 24px 0 0',
      boxShadow: '0 -16px 40px rgba(15, 22, 38, 0.28)',
      maxHeight: 800, display: 'flex', flexDirection: 'column',
    }}>
      {/* grabber */}
      <div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0 4px' }}>
        <span style={{ width: 40, height: 4, borderRadius: 999, background: WP_BORDER }} />
      </div>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '8px 16px 14px', borderBottom: `1px solid ${WP_BORDER}` }}>
        <div style={{ flex: 1 }}>
          <h3 style={{ margin: 0, fontSize: 17, fontWeight: 800, color: WP_INK, letterSpacing: '-0.01em' }}>Razrada cijene</h3>
          <div style={{ fontSize: 12, color: WP_MUTED, marginTop: 3 }}>Studio · 08.07.–11.07.2026</div>
        </div>
        <WPCloseBtn />
      </div>
      {/* body */}
      <div style={{ padding: '4px 16px 12px', overflow: 'hidden' }}>
        <WPBreakdownBody />
      </div>
      {/* footer */}
      <div style={{ padding: 14, borderTop: `1px solid ${WP_BORDER}`, background: '#FBFCFE' }}>
        <WPInkButton icon="arrow_forward" full height={50}>Nastavi na plaćanje</WPInkButton>
      </div>
    </div>
  </div>
);

Object.assign(window, {
  WidgetPricingPanelEmbedded,
  WidgetPricingModalDesktop,
  WidgetPricingModalMobile,
});
