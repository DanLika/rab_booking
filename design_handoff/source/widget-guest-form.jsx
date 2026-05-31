/* eslint-disable */
// Booking widget · Guest form — Prompt 28.
// Continues widget visual language (mint accent, near-black text). HR-localized CTA.
// Note for Flutter: F-67-03 — NO localStorage persistence of form data (in-memory only).

const WG_MINT = '#3DD9B0';
const WG_MINT_DEEP = '#1FAF87';
const WG_INK = '#1B2330';
const WG_MUTED = '#7C8593';
const WG_BORDER = '#ECEEF1';

// ──────────────────────────────────────────────────────────────
// Field primitives (widget-themed, distinct from BBInput)
// ──────────────────────────────────────────────────────────────
const WField = ({ label, required, icon, value = '', placeholder, type = 'text', error, helper, trailing, focused = false, style = {} }) => {
  const borderColor = error ? '#FF6B6B' : focused ? WG_INK : WG_BORDER;
  return (
    <div style={{ ...style }}>
      {label && (
        <label style={{
          display: 'block', marginBottom: 6,
          fontSize: 12, fontWeight: 600, color: WG_INK, letterSpacing: '0.01em',
        }}>
          {label}{required && <span style={{ color: '#FF6B6B', marginLeft: 2 }}>*</span>}
        </label>
      )}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '0 14px', height: 48,
        background: '#FFFFFF',
        border: `${focused || error ? '2px' : '1px'} solid ${borderColor}`,
        borderRadius: 12,
      }}>
        {icon && <BBIcon name={icon} size={18} style={{ color: WG_MUTED }} />}
        <input
          type={type}
          defaultValue={value}
          placeholder={placeholder}
          style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            fontFamily: 'var(--bb-font-sans)', fontSize: 14, color: WG_INK,
            height: '100%', padding: 0,
          }}
        />
        {trailing}
      </div>
      {(error || helper) && (
        <div style={{
          marginTop: 6, fontSize: 11, fontWeight: 500,
          color: error ? '#FF6B6B' : WG_MUTED,
        }}>{error || helper}</div>
      )}
    </div>
  );
};

const WTextarea = ({ label, value = '', placeholder, rows = 3, charLimit = 500, helper, style = {} }) => (
  <div style={{ ...style }}>
    {label && (
      <label style={{
        display: 'block', marginBottom: 6,
        fontSize: 12, fontWeight: 600, color: WG_INK,
      }}>{label}</label>
    )}
    <textarea
      defaultValue={value}
      placeholder={placeholder}
      rows={rows}
      style={{
        width: '100%', padding: 14,
        background: '#FFFFFF',
        border: `1px solid ${WG_BORDER}`,
        borderRadius: 12,
        fontFamily: 'var(--bb-font-sans)', fontSize: 14, color: WG_INK,
        resize: 'vertical', outline: 'none',
      }}
    />
    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
      <span style={{ fontSize: 11, color: WG_MUTED }}>{helper || ''}</span>
      <span style={{ fontSize: 11, color: WG_MUTED, fontVariantNumeric: 'tabular-nums' }}>{value.length}/{charLimit}</span>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Phone with country prefix
// ──────────────────────────────────────────────────────────────
const WPhoneField = ({ value = '' }) => (
  <div>
    <label style={{
      display: 'block', marginBottom: 6,
      fontSize: 12, fontWeight: 600, color: WG_INK,
    }}>Broj telefona<span style={{ color: '#FF6B6B', marginLeft: 2 }}>*</span></label>
    <div style={{ display: 'flex', gap: 8 }}>
      <button style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        padding: '0 14px', height: 48,
        background: '#FFFFFF',
        border: `1px solid ${WG_BORDER}`,
        borderRadius: 12, cursor: 'pointer',
        fontFamily: 'var(--bb-font-sans)',
      }}>
        <span style={{ fontSize: 16 }}>🇭🇷</span>
        <span style={{ fontSize: 14, fontWeight: 600, color: WG_INK, fontVariantNumeric: 'tabular-nums' }}>+385</span>
        <BBIcon name="expand_more" size={16} style={{ color: WG_MUTED }} />
      </button>
      <div style={{ flex: 1 }}>
        <WField placeholder="91 234 5678" icon="call" value={value} />
      </div>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Guest counter (Adult + Child)
// ──────────────────────────────────────────────────────────────
const GuestCounter = ({ label, sub, value, min = 0, max = 8 }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '14px 16px',
    background: '#FFFFFF',
    border: `1px solid ${WG_BORDER}`,
    borderRadius: 12,
  }}>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 14, fontWeight: 600, color: WG_INK }}>{label}</div>
      <div style={{ fontSize: 12, color: WG_MUTED, marginTop: 2 }}>{sub}</div>
    </div>
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
      <button style={counterBtn(value <= min)}>
        <BBIcon name="remove" size={16} />
      </button>
      <span style={{
        minWidth: 24, textAlign: 'center',
        fontSize: 16, fontWeight: 700, color: WG_INK, fontVariantNumeric: 'tabular-nums',
      }}>{value}</span>
      <button style={counterBtn(value >= max)}>
        <BBIcon name="add" size={16} />
      </button>
    </div>
  </div>
);
function counterBtn(disabled) {
  return {
    width: 32, height: 32, borderRadius: 999, cursor: disabled ? 'not-allowed' : 'pointer',
    background: '#FFFFFF',
    border: `1px solid ${WG_BORDER}`,
    color: WG_INK,
    opacity: disabled ? 0.4 : 1,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  };
}

// ──────────────────────────────────────────────────────────────
// Payment block — credit card option with mint check
// ──────────────────────────────────────────────────────────────
const PaymentOption = ({ icon, title, sub, selected, value }) => (
  <button style={{
    width: '100%', textAlign: 'left',
    padding: 16, gap: 12,
    background: '#FFFFFF',
    border: `${selected ? '2px' : '1px'} solid ${selected ? WG_MINT_DEEP : WG_BORDER}`,
    borderRadius: 14, cursor: 'pointer',
    display: 'flex', alignItems: 'center',
  }}>
    <div style={{
      width: 40, height: 40, borderRadius: 10,
      background: '#F1F2F4', color: WG_INK,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name={icon} size={20} />
    </div>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 14, fontWeight: 700, color: WG_INK }}>{title}</div>
      <div style={{ fontSize: 12, color: WG_MUTED, marginTop: 2 }}>{sub}</div>
    </div>
    <div style={{
      fontSize: 14, fontWeight: 700, color: WG_INK,
      fontVariantNumeric: 'tabular-nums', marginRight: 12,
    }}>{value}</div>
    <span style={{
      width: 20, height: 20, borderRadius: '50%',
      background: selected ? WG_MINT : '#FFFFFF',
      border: `2px solid ${selected ? WG_MINT_DEEP : WG_BORDER}`,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {selected && <BBIcon name="check" size={12} style={{ color: '#FFFFFF' }} />}
    </span>
  </button>
);

// ──────────────────────────────────────────────────────────────
// Tax checkbox
// ──────────────────────────────────────────────────────────────
const TaxCheckbox = ({ checked = false }) => (
  <label style={{
    display: 'flex', gap: 12, padding: '12px 14px',
    background: '#FBFCFE',
    border: `1px solid ${WG_BORDER}`,
    borderRadius: 12, cursor: 'pointer',
  }}>
    <span style={{
      width: 20, height: 20, borderRadius: 6,
      background: checked ? WG_INK : '#FFFFFF',
      border: `1.5px solid ${checked ? WG_INK : WG_BORDER}`,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: 1,
    }}>
      {checked && <BBIcon name="check" size={14} style={{ color: '#FFFFFF' }} />}
    </span>
    <div>
      <div style={{ fontSize: 13, fontWeight: 600, color: WG_INK }}>
        Slažem se s uvjetima rezervacije i pravilima privatnosti
      </div>
      <div style={{ fontSize: 11, color: WG_MUTED, marginTop: 4, lineHeight: 1.5 }}>
        Pročitajte <a href="#" style={{ color: WG_INK, textDecoration: 'underline' }}>Uvjete</a> i <a href="#" style={{ color: WG_INK, textDecoration: 'underline' }}>Pravila privatnosti</a>. Boravišna pristojba (€1,50/noć po osobi) plaća se na licu mjesta.
      </div>
    </div>
  </label>
);

// ──────────────────────────────────────────────────────────────
// Pricing breakdown panel (sticky right on desktop)
// ──────────────────────────────────────────────────────────────
const FormPricingPanel = ({ compact = false, slotId = 'bb-wg-cover' }) => (
  <div style={{
    background: '#FFFFFF',
    borderRadius: 20,
    border: `1px solid ${WG_BORDER}`,
    boxShadow: '0 12px 28px rgba(20, 30, 50, 0.08)',
    padding: compact ? 16 : 20,
  }}>
    {/* Mini hero */}
    <div style={{ display: 'flex', gap: 12, alignItems: 'center', paddingBottom: 14, borderBottom: `1px solid ${WG_BORDER}` }}>
      <image-slot
        id={slotId}
        shape="rounded"
        radius="12"
        placeholder="Foto"
        style={{ width: 56, height: 56, flexShrink: 0, display: 'block' }}
      ></image-slot>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: WG_MUTED }}>Vila Marina</div>
        <div style={{ fontSize: 14, fontWeight: 700, color: WG_INK }}>Studio s pogledom na more</div>
      </div>
    </div>

    {/* Dates pill */}
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '8px 12px', marginTop: 14,
      background: '#F1F2F4', borderRadius: 999,
    }}>
      <BBIcon name="event" size={14} style={{ color: WG_MUTED }} />
      <span style={{ fontSize: 13, fontWeight: 600, color: WG_INK, fontVariantNumeric: 'tabular-nums' }}>
        29.05. – 30.05.2026
      </span>
      <span style={{
        background: WG_MINT, color: '#FFFFFF',
        padding: '2px 8px', borderRadius: 999,
        fontSize: 11, fontWeight: 700,
      }}>1 noć</span>
    </div>

    {/* Lines */}
    <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <PricingRow label="Soba (1 noć)" value="€130,00" />
      <PricingRow label="Boravišna pristojba" value="€1,50" muted helper="2 osobe × 1 noć × €1,50 — naplaćuje se na licu mjesta" />
    </div>

    <div style={{ height: 1, background: WG_BORDER, margin: '14px 0' }} />

    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
      <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: '0.04em', color: WG_INK, textTransform: 'uppercase' }}>Ukupno</span>
      <span style={{ fontSize: 22, fontWeight: 800, color: WG_INK, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>€130,00</span>
    </div>

    <div style={{
      padding: 12, marginBottom: 16,
      background: 'rgba(61, 217, 176, 0.10)',
      border: `1px solid rgba(61, 217, 176, 0.32)`,
      borderRadius: 12,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
        <span style={{ fontSize: 12, fontWeight: 700, color: WG_MINT_DEEP, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Polog danas</span>
        <span style={{ fontSize: 16, fontWeight: 800, color: WG_MINT_DEEP, fontVariantNumeric: 'tabular-nums' }}>€26,00</span>
      </div>
      <div style={{ fontSize: 11, color: WG_MUTED }}>20% — preostatak plaćate vlasniku na licu mjesta.</div>
    </div>

    {/* CTA */}
    <button style={{
      height: 56, width: '100%', border: 'none', cursor: 'pointer',
      background: WG_INK, color: '#FFFFFF',
      borderRadius: 14,
      fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: '0 6px 18px rgba(27,35,48,0.24)',
    }}>
      <BBIcon name="lock" size={16} />
      Plati €26,00 depozit
    </button>
    <div style={{ fontSize: 11, color: WG_MUTED, textAlign: 'center', marginTop: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4 }}>
      <BBIcon name="verified_user" size={12} />
      Sigurna obrada putem Stripe-a
    </div>
  </div>
);

const PricingRow = ({ label, value, muted = false, helper }) => (
  <div>
    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
      <span style={{ fontSize: 13, color: muted ? WG_MUTED : WG_INK }}>{label}</span>
      <span style={{ fontSize: 13, fontWeight: muted ? 500 : 700, color: muted ? WG_MUTED : WG_INK, fontVariantNumeric: 'tabular-nums' }}>{value}</span>
    </div>
    {helper && <div style={{ fontSize: 10, color: WG_MUTED, marginTop: 2 }}>{helper}</div>}
  </div>
);

// ──────────────────────────────────────────────────────────────
// Form sections (shared)
// ──────────────────────────────────────────────────────────────
const FormSectionHeader = ({ number, title, sub }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
    <div style={{
      width: 28, height: 28, borderRadius: '50%',
      background: WG_INK, color: '#FFFFFF',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 13, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
    }}>{number}</div>
    <div>
      <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: WG_INK, letterSpacing: '-0.005em' }}>{title}</h3>
      {sub && <div style={{ fontSize: 12, color: WG_MUTED, marginTop: 2 }}>{sub}</div>}
    </div>
  </div>
);

const GuestForm = ({ compact = false }) => (
  <div>
    {/* Section 1 — Guest */}
    <FormSectionHeader number="1" title="Podaci o gostu" sub="Bit će vidljivi vlasniku objekta" />
    <div style={{
      display: 'grid', gridTemplateColumns: compact ? '1fr' : 'repeat(2, 1fr)',
      gap: 12, marginBottom: 12,
    }}>
      <WField label="Ime" required icon="person" value="Marko" />
      <WField label="Prezime" required icon="badge" value="Horvat" />
    </div>
    <WField label="Email" required icon="mail" type="email" value="marko.horvat@gmail.com" helper="Šaljemo potvrdu i račun na ovu adresu" style={{ marginBottom: 12 }} />
    <div style={{ marginBottom: 24 }}>
      <WPhoneField value="91 234 5678" />
    </div>

    {/* Section 2 — Guests count */}
    <FormSectionHeader number="2" title="Broj gostiju" sub="Maksimalno 2 osobe za ovu jedinicu" />
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 24 }}>
      <GuestCounter label="Odrasli" sub="13+ godina" value={2} min={1} max={2} />
      <GuestCounter label="Djeca" sub="0–12 godina" value={0} max={2} />
    </div>

    {/* Section 3 — Special requests */}
    <FormSectionHeader number="3" title="Posebni zahtjevi" sub="Opcionalno — javit ćemo vlasniku" />
    <WTextarea
      placeholder="npr. Kasniji check-in oko 21h, dijete s alergijom na mačke…"
      value="Stižemo oko 21:00 — molim ostavite ključ kod susjeda."
      rows={3}
      helper="Nije obavezno · ne dijeli se s drugim gostima"
      style={{ marginBottom: 24 }}
    />

    {/* Section 4 — Payment */}
    <FormSectionHeader number="4" title="Način plaćanja" sub="Depozit naplaćujemo odmah — preostatak plaćate na licu mjesta" />
    <PaymentOption icon="credit_card" title="Kreditna kartica" sub="Visa · MasterCard · Amex · putem Stripe-a" value="€26,00" selected />

    {/* Tax checkbox */}
    <div style={{ marginTop: 24, marginBottom: 8 }}>
      <TaxCheckbox checked />
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Mini app-bar header
// ──────────────────────────────────────────────────────────────
const WidgetHeader = ({ title, compact = false }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    paddingBottom: 16, marginBottom: compact ? 16 : 24,
    borderBottom: `1px solid ${WG_BORDER}`,
  }}>
    <button style={iconBtn()}><BBIcon name="arrow_back" size={18} style={{ color: WG_INK }} /></button>
    <div style={{ flex: 1 }}>
      <h2 style={{ margin: 0, fontSize: compact ? 18 : 22, fontWeight: 700, color: WG_INK, letterSpacing: '-0.015em' }}>{title}</h2>
      <div style={{ fontSize: 12, color: WG_MUTED, marginTop: 2 }}>Posljednji korak — još samo par podataka</div>
    </div>
    <button style={iconBtn()}><BBIcon name="light_mode" size={16} style={{ color: WG_INK }} /></button>
    <button style={{ ...iconBtn(), gap: 4, padding: '0 12px', width: 'auto' }}>
      <span style={{ fontSize: 14 }}>🇭🇷</span>
      <BBIcon name="expand_more" size={14} style={{ color: WG_MUTED }} />
    </button>
  </div>
);
function iconBtn() {
  return {
    width: 36, height: 36, borderRadius: '50%',
    border: `1px solid ${WG_BORDER}`, background: '#FFFFFF',
    cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  };
}

const PoweredByFooterW = () => (
  <div style={{ textAlign: 'center', marginTop: 24, color: '#9AA0AC', fontSize: 11 }}>
    Sigurno plaćanje putem Stripe-a · Powered by <span style={{ fontWeight: 700, color: '#6B4CE6' }}>BookBed</span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const WidgetGuestFormDesktop = () => (
  <div style={{
    width: 1080, padding: '32px 40px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)',
    color: WG_INK,
  }}>
    <WidgetHeader title="Dovršite rezervaciju" />
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 380px', gap: 32, alignItems: 'flex-start' }}>
      <div>
        <GuestForm />
      </div>
      <div style={{ position: 'sticky', top: 0 }}>
        <FormPricingPanel slotId="bb-wg-cover-d" />
      </div>
    </div>
    <PoweredByFooterW />
  </div>
);

const WidgetGuestFormTablet = () => (
  <div style={{
    width: 768, padding: 24,
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)',
    color: WG_INK,
    display: 'flex', flexDirection: 'column',
  }}>
    <WidgetHeader title="Dovršite rezervaciju" compact />
    <FormPricingPanel compact slotId="bb-wg-cover-t" />
    <div style={{ height: 20 }} />
    <GuestForm compact />
  </div>
);

const WidgetGuestFormMobile = () => (
  <div style={{
    width: 390, padding: 16,
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)',
    color: WG_INK,
    display: 'flex', flexDirection: 'column', position: 'relative',
  }}>
    <WidgetHeader title="Dovršite rezervaciju" compact />
    {/* Collapsed pricing summary */}
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: 14, marginBottom: 16,
      background: '#FBFCFE',
      border: `1px solid ${WG_BORDER}`,
      borderRadius: 14,
    }}>
      <image-slot
        id="bb-wg-cover-m"
        shape="rounded"
        radius="10"
        placeholder="Foto"
        style={{ width: 44, height: 44, flexShrink: 0, display: 'block' }}
      ></image-slot>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: WG_INK, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Studio s pogledom na more</div>
        <div style={{ fontSize: 11, color: WG_MUTED, fontVariantNumeric: 'tabular-nums' }}>29.05.–30.05. · 1 noć</div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <div style={{ fontSize: 16, fontWeight: 800, color: WG_INK, fontVariantNumeric: 'tabular-nums' }}>€130,00</div>
        <div style={{ fontSize: 10, color: WG_MUTED }}>polog €26</div>
      </div>
    </div>
    <GuestForm compact />
    {/* Sticky bottom CTA */}
    <div style={{
      position: 'sticky', bottom: 0,
      marginLeft: -16, marginRight: -16, marginBottom: -16,
      padding: 14,
      background: '#FFFFFF',
      borderTop: `1px solid ${WG_BORDER}`,
      boxShadow: '0 -8px 24px rgba(20,30,50,0.08)',
    }}>
      <button style={{
        width: '100%', height: 52, border: 'none', cursor: 'pointer',
        background: WG_INK, color: '#FFFFFF',
        borderRadius: 14,
        fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        <BBIcon name="lock" size={16} />
        Plati €26,00 depozit
      </button>
    </div>
  </div>
);

Object.assign(window, {
  WidgetGuestFormDesktop,
  WidgetGuestFormTablet,
  WidgetGuestFormMobile,
});
