/* eslint-disable */
// Booking widget · Confirmation / success — Prompt 29.
// Continues widget visual language (mint accent, near-black ink). HR-localized.
// Flow: guest paid the deposit → request sent to owner → success screen.
// Numbers continue the guest-form booking (Marko Horvat · Studio · 29.05–30.05 · €130 · €26 polog).

const WC_MINT = '#3DD9B0';
const WC_MINT_DEEP = '#1FAF87';
const WC_INK = '#1B2330';
const WC_MUTED = '#7C8593';
const WC_BORDER = '#ECEEF1';

// ──────────────────────────────────────────────────────────────
// Success mark — layered mint disc with check (no inline SVG art)
// ──────────────────────────────────────────────────────────────
const WCSuccessMark = ({ size = 88 }) => (
  <div style={{
    width: size, height: size, position: 'relative', flexShrink: 0,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  }}>
    {/* soft ring */}
    <div style={{
      position: 'absolute', inset: -10, borderRadius: '50%',
      background: 'rgba(61, 217, 176, 0.14)',
    }} />
    <div style={{
      position: 'absolute', inset: 0, borderRadius: '50%',
      background: 'rgba(61, 217, 176, 0.22)',
    }} />
    {/* core disc */}
    <div style={{
      width: size - 20, height: size - 20, borderRadius: '50%',
      background: `linear-gradient(135deg, ${WC_MINT} 0%, ${WC_MINT_DEEP} 100%)`,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      color: '#FFFFFF',
      boxShadow: '0 10px 24px rgba(31, 175, 135, 0.40)',
    }}>
      <BBIcon name="check" size={size * 0.46} weight={700} />
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Reference pill — mono booking number + copy affordance
// ──────────────────────────────────────────────────────────────
const WCRefPill = ({ id = 'BB-2403' }) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 10,
    padding: '8px 8px 8px 16px',
    background: '#F1F2F4', borderRadius: 999,
  }}>
    <span style={{ fontSize: 12, fontWeight: 600, color: WC_MUTED }}>Broj rezervacije</span>
    <span className="bb-mono" style={{ fontSize: 14, fontWeight: 600, color: WC_INK, letterSpacing: 0 }}>#{id}</span>
    <button style={{
      width: 28, height: 28, borderRadius: 999, border: 'none', cursor: 'pointer',
      background: '#FFFFFF', color: WC_INK,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 1px 2px rgba(0,0,0,0.08)',
    }} aria-label="Kopiraj broj rezervacije">
      <BBIcon name="content_copy" size={15} fill={0} />
    </button>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Booking summary card
// ──────────────────────────────────────────────────────────────
const WCSummaryCard = ({ compact = false }) => (
  <div style={{
    background: '#FFFFFF',
    borderRadius: 20,
    border: `1px solid ${WC_BORDER}`,
    boxShadow: '0 12px 28px rgba(20, 30, 50, 0.07)',
    overflow: 'hidden',
    textAlign: 'left',
  }}>
    {/* Mini hero */}
    <div style={{
      display: 'flex', gap: 14, alignItems: 'center',
      padding: compact ? 16 : 20,
      borderBottom: `1px solid ${WC_BORDER}`,
    }}>
      <image-slot
        id="bb-widget-unit"
        shape="rounded"
        radius="12"
        placeholder="Foto"
        style={{ display: 'block', width: compact ? 48 : 56, height: compact ? 48 : 56, flexShrink: 0 }}
      ></image-slot>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: WC_MUTED }}>Vila Marina</div>
        <div style={{ fontSize: compact ? 14 : 16, fontWeight: 700, color: WC_INK, letterSpacing: '-0.005em' }}>Studio s pogledom na more</div>
      </div>
    </div>

    {/* Detail rows */}
    <div style={{ padding: compact ? '8px 16px' : '8px 20px' }}>
      <WCDetailRow icon="event" label="Dolazak — odlazak" value="29.05. – 30.05.2026" badge="1 noć" />
      <WCDetailRow icon="schedule" label="Check-in / Check-out" value="od 14:00 / do 10:00" />
      <WCDetailRow icon="group" label="Gosti" value="2 odrasle osobe" last />
    </div>

    {/* Deposit band */}
    <div style={{
      padding: compact ? 16 : '16px 20px',
      background: 'rgba(61, 217, 176, 0.08)',
      borderTop: `1px solid ${WC_BORDER}`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
          <BBIcon name="task_alt" size={18} style={{ color: WC_MINT_DEEP }} />
          <span style={{ fontSize: 13, fontWeight: 700, color: WC_MINT_DEEP, letterSpacing: '0.02em' }}>Polog plaćen</span>
        </div>
        <span style={{ fontSize: 18, fontWeight: 800, color: WC_INK, fontVariantNumeric: 'tabular-nums' }}>€26,00</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 8 }}>
        <span style={{ fontSize: 12, color: WC_MUTED }}>Preostatak — plaćate na licu mjesta</span>
        <span style={{ fontSize: 13, fontWeight: 600, color: WC_MUTED, fontVariantNumeric: 'tabular-nums' }}>€104,00</span>
      </div>
    </div>
  </div>
);

const WCDetailRow = ({ icon, label, value, badge, last = false }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '12px 0',
    borderBottom: last ? 'none' : `1px solid ${WC_BORDER}`,
  }}>
    <BBIcon name={icon} size={18} style={{ color: WC_MUTED, flexShrink: 0 }} />
    <span style={{ fontSize: 13, color: WC_MUTED, flex: 1 }}>{label}</span>
    <span style={{ fontSize: 13, fontWeight: 600, color: WC_INK, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
    {badge && (
      <span style={{
        background: WC_MINT, color: '#FFFFFF',
        padding: '2px 8px', borderRadius: 999, fontSize: 11, fontWeight: 700,
      }}>{badge}</span>
    )}
  </div>
);

// ──────────────────────────────────────────────────────────────
// "What happens next" — 3-step vertical timeline
// ──────────────────────────────────────────────────────────────
const WC_STEPS = [
  { icon: 'hourglass_top', title: 'Vlasnik potvrđuje rezervaciju', sub: 'Obično unutar 24 sata', state: 'active' },
  { icon: 'mark_email_read', title: 'Šaljemo potvrdu na email', sub: 'S detaljima i uputama za dolazak', state: 'todo' },
  { icon: 'payments', title: 'Preostatak plaćate pri dolasku', sub: '€104,00 izravno vlasniku', state: 'todo' },
];

const WCSteps = ({ compact = false }) => (
  <div style={{ textAlign: 'left' }}>
    <div style={{ fontSize: 13, fontWeight: 700, color: WC_INK, marginBottom: 14, letterSpacing: '0.01em' }}>Što slijedi?</div>
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      {WC_STEPS.map((s, i) => {
        const active = s.state === 'active';
        return (
          <div key={i} style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
            {/* Rail + node */}
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', alignSelf: 'stretch' }}>
              <div style={{
                width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
                background: active ? WC_MINT : '#F1F2F4',
                color: active ? '#FFFFFF' : WC_MUTED,
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: active ? '0 4px 12px rgba(61, 217, 176, 0.40)' : 'none',
              }}>
                <BBIcon name={s.icon} size={18} fill={active ? 1 : 0} />
              </div>
              {i < WC_STEPS.length - 1 && (
                <div style={{ width: 2, flex: 1, minHeight: 18, background: WC_BORDER, marginTop: 4, marginBottom: 4 }} />
              )}
            </div>
            {/* Text */}
            <div style={{ paddingBottom: i < WC_STEPS.length - 1 ? 18 : 0, paddingTop: 6 }}>
              <div style={{ fontSize: 14, fontWeight: 600, color: WC_INK }}>{s.title}</div>
              <div style={{ fontSize: 12, color: WC_MUTED, marginTop: 2 }}>{s.sub}</div>
            </div>
          </div>
        );
      })}
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Email confirmation note + actions
// ──────────────────────────────────────────────────────────────
const WCEmailNote = () => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 10,
    padding: '12px 14px',
    background: '#FBFCFE', border: `1px solid ${WC_BORDER}`, borderRadius: 12,
    textAlign: 'left',
  }}>
    <BBIcon name="mail" size={18} style={{ color: WC_MUTED, flexShrink: 0 }} />
    <span style={{ fontSize: 12, color: WC_MUTED, lineHeight: 1.5 }}>
      Potvrda je poslana na <span style={{ color: WC_INK, fontWeight: 600 }}>marko.horvat@gmail.com</span>. Ne vidite je? Provjerite neželjenu poštu.
    </span>
  </div>
);

const WCInkButton = ({ icon, children, full = false, height = 52 }) => (
  <button style={{
    height, width: full ? '100%' : 'auto', padding: full ? 0 : '0 22px',
    border: 'none', cursor: 'pointer',
    background: WC_INK, color: '#FFFFFF', borderRadius: 14,
    fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    boxShadow: '0 6px 18px rgba(27,35,48,0.22)',
  }}>
    {icon && <BBIcon name={icon} size={18} />}
    {children}
  </button>
);

const WCGhostButton = ({ icon, children, full = false, height = 52 }) => (
  <button style={{
    height, width: full ? '100%' : 'auto', padding: full ? 0 : '0 22px',
    cursor: 'pointer',
    background: '#FFFFFF', color: WC_INK, border: `1px solid ${WC_BORDER}`, borderRadius: 14,
    fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
  }}>
    {icon && <BBIcon name={icon} size={18} />}
    {children}
  </button>
);

const WCPoweredBy = ({ style = {} }) => (
  <div style={{ textAlign: 'center', color: '#9AA0AC', fontSize: 11, ...style }}>
    Sigurno plaćanje obrađeno putem Stripe-a · Powered by <span style={{ fontWeight: 700, color: '#6B4CE6' }}>BookBed</span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Shared header band (success) — eyebrow + heading + ref
// ──────────────────────────────────────────────────────────────
const WCHeadline = ({ compact = false }) => (
  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: compact ? 10 : 14 }}>
    <WCSuccessMark size={compact ? 76 : 88} />
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.10em', textTransform: 'uppercase', color: WC_MINT_DEEP }}>
      Plaćanje uspješno
    </div>
    <h1 style={{ margin: 0, fontSize: compact ? 24 : 30, fontWeight: 800, color: WC_INK, letterSpacing: '-0.02em' }}>
      Rezervacija je zaprimljena
    </h1>
    <p style={{ margin: 0, fontSize: compact ? 14 : 15, color: WC_MUTED, lineHeight: 1.55, maxWidth: 420 }}>
      Poslali smo vaš zahtjev vlasniku. Čim ga potvrdi, dobit ćete konačnu potvrdu e-poštom.
    </p>
    <WCRefPill />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const WidgetConfirmationDesktop = () => (
  <div style={{
    width: 1080, padding: '48px 40px 36px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', color: WC_INK,
  }}>
    <div style={{ maxWidth: 760, margin: '0 auto' }}>
      <WCHeadline />

      {/* Two-column body */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 28, alignItems: 'flex-start', marginTop: 36 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <WCSummaryCard />
          <WCEmailNote />
        </div>
        <div style={{
          background: '#FBFCFE', border: `1px solid ${WC_BORDER}`, borderRadius: 20,
          padding: 20,
        }}>
          <WCSteps />
        </div>
      </div>

      {/* Actions */}
      <div style={{ display: 'flex', gap: 12, marginTop: 28, justifyContent: 'center' }}>
        <WCInkButton icon="calendar_add_on">Dodaj u kalendar</WCInkButton>
        <WCGhostButton icon="download">Preuzmi potvrdu (PDF)</WCGhostButton>
      </div>

      <WCPoweredBy style={{ marginTop: 28 }} />
    </div>
  </div>
);

const WidgetConfirmationTablet = () => (
  <div style={{
    width: 768, height: 1024, padding: '36px 32px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', color: WC_INK,
    display: 'flex', flexDirection: 'column',
  }}>
    <div style={{ maxWidth: 560, margin: '0 auto', width: '100%' }}>
      <WCHeadline />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16, marginTop: 28 }}>
        <WCSummaryCard />
        <div style={{
          background: '#FBFCFE', border: `1px solid ${WC_BORDER}`, borderRadius: 20, padding: 20,
        }}>
          <WCSteps />
        </div>
        <WCEmailNote />
        <div style={{ display: 'flex', gap: 12, marginTop: 4 }}>
          <WCInkButton icon="calendar_add_on" full>Dodaj u kalendar</WCInkButton>
          <WCGhostButton icon="download" full>Potvrda (PDF)</WCGhostButton>
        </div>
      </div>
      <WCPoweredBy style={{ marginTop: 24 }} />
    </div>
  </div>
);

const WidgetConfirmationMobile = () => (
  <div style={{
    width: 390, height: 880, padding: '28px 16px 16px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', color: WC_INK,
    display: 'flex', flexDirection: 'column', position: 'relative',
  }}>
    <WCHeadline compact />
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginTop: 22 }}>
      <WCSummaryCard compact />
      <div style={{
        background: '#FBFCFE', border: `1px solid ${WC_BORDER}`, borderRadius: 16, padding: 16,
      }}>
        <WCSteps compact />
      </div>
    </div>
    <div style={{ flex: 1 }} />
    {/* Sticky bottom CTA */}
    <div style={{
      position: 'sticky', bottom: 0,
      marginLeft: -16, marginRight: -16, marginBottom: -16,
      padding: 14,
      background: '#FFFFFF', borderTop: `1px solid ${WC_BORDER}`,
      boxShadow: '0 -8px 24px rgba(20,30,50,0.08)',
      display: 'flex', flexDirection: 'column', gap: 8,
    }}>
      <WCInkButton icon="calendar_add_on" full height={50}>Dodaj u kalendar</WCInkButton>
      <WCPoweredBy />
    </div>
  </div>
);

Object.assign(window, {
  WidgetConfirmationDesktop,
  WidgetConfirmationTablet,
  WidgetConfirmationMobile,
});
