/* eslint-disable */
// Booking widget · Error & Not-found states — Prompt 30.
// Continues widget visual language. Three guest-facing failure states, one shared shell.
//  1. Plaćanje nije uspjelo  (payment declined — card NOT charged)
//  2. Stranica nije pronađena (invalid/expired booking link — 404)
//  3. Termin više nije dostupan (race: dates taken during checkout)

const WX_MINT = '#3DD9B0';
const WX_MINT_DEEP = '#1FAF87';
const WX_INK = '#1B2330';
const WX_MUTED = '#7C8593';
const WX_BORDER = '#ECEEF1';
const WX_CORAL = '#FF6B6B';
const WX_CORAL_DEEP = '#E14F4F';
const WX_AMBER = '#E69A28';

const WX_TONES = {
  error:    { fg: WX_CORAL_DEEP, soft: 'rgba(255, 107, 107, 0.12)', ring: 'rgba(255, 107, 107, 0.16)' },
  neutral:  { fg: WX_INK,        soft: '#F1F2F4',                    ring: '#F6F7F8' },
  warning:  { fg: WX_AMBER,      soft: 'rgba(255, 184, 77, 0.16)',   ring: 'rgba(255, 184, 77, 0.10)' },
};

// ──────────────────────────────────────────────────────────────
// State mark — tone-colored disc (mirror of success mark)
// ──────────────────────────────────────────────────────────────
const WXMark = ({ icon, tone = 'error', size = 88 }) => {
  const t = WX_TONES[tone] || WX_TONES.error;
  return (
    <div style={{
      width: size, height: size, position: 'relative', flexShrink: 0,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{ position: 'absolute', inset: -10, borderRadius: '50%', background: t.ring }} />
      <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: t.soft }} />
      <div style={{
        width: size - 20, height: size - 20, borderRadius: '50%',
        background: '#FFFFFF', border: `2px solid ${t.fg}`,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        color: t.fg,
        boxShadow: '0 8px 20px rgba(20, 30, 50, 0.10)',
      }}>
        <BBIcon name={icon} size={size * 0.42} />
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Buttons (shared with widget language)
// ──────────────────────────────────────────────────────────────
const WXInkButton = ({ icon, children, full = false, height = 52 }) => (
  <button style={{
    height, width: full ? '100%' : 'auto', padding: full ? 0 : '0 22px',
    border: 'none', cursor: 'pointer',
    background: WX_INK, color: '#FFFFFF', borderRadius: 14,
    fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    boxShadow: '0 6px 18px rgba(27,35,48,0.22)',
  }}>
    {icon && <BBIcon name={icon} size={18} />}
    {children}
  </button>
);

const WXGhostButton = ({ icon, children, full = false, height = 52 }) => (
  <button style={{
    height, width: full ? '100%' : 'auto', padding: full ? 0 : '0 22px',
    cursor: 'pointer',
    background: '#FFFFFF', color: WX_INK, border: `1px solid ${WX_BORDER}`, borderRadius: 14,
    fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
  }}>
    {icon && <BBIcon name={icon} size={18} />}
    {children}
  </button>
);

const WXPoweredBy = ({ style = {} }) => (
  <div style={{ textAlign: 'center', color: '#9AA0AC', fontSize: 11, ...style }}>
    Powered by <span style={{ fontWeight: 700, color: '#6B4CE6' }}>BookBed</span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Detail strip — small contextual note under the body (optional)
// ──────────────────────────────────────────────────────────────
const WXDetail = ({ icon, tone = 'neutral', children }) => {
  const t = WX_TONES[tone] || WX_TONES.neutral;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '12px 14px',
      background: tone === 'neutral' ? '#FBFCFE' : t.soft,
      border: `1px solid ${tone === 'neutral' ? WX_BORDER : 'transparent'}`,
      borderRadius: 12, textAlign: 'left',
    }}>
      <BBIcon name={icon} size={18} style={{ color: t.fg, flexShrink: 0 }} />
      <span style={{ fontSize: 12, color: WX_MUTED, lineHeight: 1.5 }}>{children}</span>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// State shell — centered column used by every state
// ──────────────────────────────────────────────────────────────
const WXStateShell = ({ tone, icon, eyebrow, title, body, detail, actions, footHint, compact = false }) => (
  <div style={{
    display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center',
    gap: compact ? 10 : 14, maxWidth: 460, margin: '0 auto', width: '100%',
  }}>
    <WXMark icon={icon} tone={tone} size={compact ? 76 : 88} />
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase', color: (WX_TONES[tone] || WX_TONES.error).fg }}>
      {eyebrow}
    </div>
    <h1 style={{ margin: 0, fontSize: compact ? 24 : 30, fontWeight: 800, color: WX_INK, letterSpacing: '-0.02em' }}>{title}</h1>
    <p style={{ margin: 0, fontSize: compact ? 14 : 15, color: WX_MUTED, lineHeight: 1.55, maxWidth: 400 }}>{body}</p>
    {detail && <div style={{ width: '100%', marginTop: 4 }}>{detail}</div>}
    {actions && <div style={{ display: 'flex', gap: 12, marginTop: compact ? 8 : 14, width: compact ? '100%' : 'auto', flexDirection: compact ? 'column' : 'row' }}>{actions}</div>}
    {footHint && <div style={{ fontSize: 12, color: WX_MUTED, marginTop: 6 }}>{footHint}</div>}
  </div>
);

// ──────────────────────────────────────────────────────────────
// State content definitions (so desktop + mobile stay in sync)
// ──────────────────────────────────────────────────────────────
const PaymentErrorContent = ({ compact }) => (
  <WXStateShell
    compact={compact}
    tone="error"
    icon="credit_card_off"
    eyebrow="Plaćanje nije uspjelo"
    title="Plaćanje nije prošlo"
    body="Vaša kartica nije terećena. Provjerite podatke ili pokušajte drugom karticom — vaš termin čuvamo još 9 minuta."
    detail={<WXDetail icon="info" tone="error">Razlog: banka je odbila transakciju (kôd <span style={{ fontWeight: 600, color: WX_INK }}>card_declined</span>). Polog <span style={{ fontWeight: 600, color: WX_INK }}>€26,00</span> nije naplaćen.</WXDetail>}
    actions={<>
      <WXInkButton icon="refresh" full={compact}>Pokušaj ponovno</WXInkButton>
      <WXGhostButton icon="credit_card" full={compact}>Druga kartica</WXGhostButton>
    </>}
    footHint="Termin se oslobađa za 9:00 ako plaćanje ne uspije."
  />
);

const NotFoundContent = ({ compact }) => (
  <WXStateShell
    compact={compact}
    tone="neutral"
    icon="link_off"
    eyebrow="Greška 404"
    title="Stranica nije pronađena"
    body="Ova poveznica za rezervaciju više ne postoji ili je istekla. Moguće je da je vlasnik uklonio ovaj oglas."
    actions={<>
      <WXInkButton icon="home" full={compact}>Natrag na početak</WXInkButton>
      <WXGhostButton icon="mail" full={compact}>Kontaktiraj vlasnika</WXGhostButton>
    </>}
    footHint="Mislite da je riječ o pogrešci? Osvježite stranicu."
  />
);

const UnavailableContent = ({ compact }) => (
  <WXStateShell
    compact={compact}
    tone="warning"
    icon="event_busy"
    eyebrow="Termin zauzet"
    title="Termin više nije dostupan"
    body="Nažalost, netko je upravo rezervirao ove datume. Polog nije naplaćen — odaberite drugi termin za isti smještaj."
    detail={<WXDetail icon="calendar_month" tone="warning"><span style={{ fontWeight: 600, color: WX_INK }}>29.05. – 30.05.2026</span> · Studio s pogledom na more više nije slobodan.</WXDetail>}
    actions={<>
      <WXInkButton icon="calendar_month" full={compact}>Odaberi nove datume</WXInkButton>
    </>}
    footHint="Slični slobodni termini: 02.06., 05.06., 11.06."
  />
);

// ──────────────────────────────────────────────────────────────
// Embedded frame wrapper (1080) — centered state inside host width
// ──────────────────────────────────────────────────────────────
const WXEmbeddedFrame = ({ children }) => (
  <div style={{
    width: 1080, padding: '72px 40px 48px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', color: WX_INK,
    display: 'flex', flexDirection: 'column', minHeight: 620,
  }}>
    <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {children}
    </div>
    <WXPoweredBy style={{ marginTop: 40 }} />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pages — embedded states
// ──────────────────────────────────────────────────────────────
const WidgetErrorPayment = () => (
  <WXEmbeddedFrame><PaymentErrorContent /></WXEmbeddedFrame>
);

const WidgetNotFound = () => (
  <WXEmbeddedFrame><NotFoundContent /></WXEmbeddedFrame>
);

const WidgetUnavailable = () => (
  <WXEmbeddedFrame><UnavailableContent /></WXEmbeddedFrame>
);

// ──────────────────────────────────────────────────────────────
// Mobile — payment error (sticky bottom actions)
// ──────────────────────────────────────────────────────────────
const WidgetErrorMobile = () => (
  <div style={{
    width: 390, height: 880, padding: '40px 16px 16px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', color: WX_INK,
    display: 'flex', flexDirection: 'column', position: 'relative',
  }}>
    <div style={{ flex: 1, display: 'flex', alignItems: 'center' }}>
      <WXStateShell
        compact
        tone="error"
        icon="credit_card_off"
        eyebrow="Plaćanje nije uspjelo"
        title="Plaćanje nije prošlo"
        body="Vaša kartica nije terećena. Termin čuvamo još 9 minuta."
        detail={<WXDetail icon="info" tone="error">Banka je odbila transakciju. Polog <span style={{ fontWeight: 600, color: WX_INK }}>€26,00</span> nije naplaćen.</WXDetail>}
      />
    </div>
    {/* Sticky bottom actions */}
    <div style={{
      position: 'sticky', bottom: 0,
      marginLeft: -16, marginRight: -16, marginBottom: -16,
      padding: 14,
      background: '#FFFFFF', borderTop: `1px solid ${WX_BORDER}`,
      boxShadow: '0 -8px 24px rgba(20,30,50,0.08)',
      display: 'flex', flexDirection: 'column', gap: 8,
    }}>
      <WXInkButton icon="refresh" full height={50}>Pokušaj ponovno</WXInkButton>
      <WXGhostButton icon="credit_card" full height={46}>Pokušaj drugom karticom</WXGhostButton>
      <WXPoweredBy style={{ marginTop: 4 }} />
    </div>
  </div>
);

Object.assign(window, {
  WidgetErrorPayment,
  WidgetNotFound,
  WidgetUnavailable,
  WidgetErrorMobile,
});
