/* eslint-disable */
// Auth · Login — Prompt 34.
// Glass card on tinted gradient. BBInput + BBButton primitives. Localized HR social SSO.

// ──────────────────────────────────────────────────────────────
// Brand logos (SSO)
// ──────────────────────────────────────────────────────────────
const GoogleLogo = ({ size = 18 }) => (
  <img src="assets/google.png" width={size} height={size} alt="" style={{ display: 'inline-block' }} />
);

const AppleLogo = ({ size = 18 }) => (
  <img src="assets/apple.png" width={size} height={size} alt="" style={{ display: 'inline-block' }} />
);

// Decorative gradient backdrop
const AuthBackdrop = () => (
  <>
    {/* Top-right purple blob */}
    <div style={{
      position: 'absolute', top: -160, right: -120, width: 520, height: 520,
      borderRadius: '50%',
      background: 'radial-gradient(circle, rgba(139,111,255,0.35) 0%, rgba(139,111,255,0) 70%)',
      pointerEvents: 'none', zIndex: 0,
    }} />
    {/* Bottom-left coral blob */}
    <div style={{
      position: 'absolute', bottom: -200, left: -120, width: 520, height: 520,
      borderRadius: '50%',
      background: 'radial-gradient(circle, rgba(255,107,107,0.18) 0%, rgba(255,107,107,0) 70%)',
      pointerEvents: 'none', zIndex: 0,
    }} />
    {/* Mid amber accent */}
    <div style={{
      position: 'absolute', top: '40%', left: '30%', width: 320, height: 320,
      borderRadius: '50%',
      background: 'radial-gradient(circle, rgba(255,184,77,0.12) 0%, rgba(255,184,77,0) 70%)',
      pointerEvents: 'none', zIndex: 0,
    }} />
  </>
);

// ──────────────────────────────────────────────────────────────
// LoginCard — shared between breakpoints, just scales
// ──────────────────────────────────────────────────────────────
const LoginCard = ({ size = 'desktop' }) => {
  const isMobile = size === 'mobile';
  const cardW = isMobile ? '100%' : 440;
  return (
    <div style={{
      width: cardW, maxWidth: '100%',
      padding: isMobile ? 24 : 36,
      background: 'rgba(255, 255, 255, 0.78)',
      backdropFilter: 'blur(24px) saturate(140%)',
      WebkitBackdropFilter: 'blur(24px) saturate(140%)',
      border: '1px solid rgba(255, 255, 255, 0.65)',
      borderRadius: 'var(--bb-radius-xl)',
      boxShadow: '0 24px 48px -16px rgba(45, 55, 72, 0.18), 0 8px 24px -8px rgba(107, 76, 230, 0.18)',
      position: 'relative',
      zIndex: 1,
    }}>
      {/* Logo + headings */}
      <div style={{ textAlign: 'center', marginBottom: 28 }}>
        <div style={{ display: 'inline-flex', marginBottom: 16, filter: 'drop-shadow(0 6px 18px rgba(107,76,230,0.32))' }}>
          <BBLogo size={56} />
        </div>
        <h1 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Prijava vlasnika</h1>
        <p className="bb-body" style={{ margin: '6px 0 0', color: 'var(--bb-text-secondary)' }}>
          Upravljajte nekretninama i rezervacijama
        </p>
      </div>

      {/* Fields */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <BBInput label="Email" iconLeft="mail" placeholder="ime@primjer.hr" type="email" />
        <BBInput label="Lozinka" iconLeft="lock" placeholder="••••••••" iconRight="visibility_off" type="password" />
      </div>

      {/* Remember + forgot */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginTop: 16, marginBottom: 20,
      }}>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
          <span style={{
            width: 18, height: 18, borderRadius: 5,
            background: 'var(--bb-primary)',
            border: '1.5px solid var(--bb-primary)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <BBIcon name="check" size={12} style={{ color: '#FFFFFF' }} />
          </span>
          <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>
            Zapamti me
          </span>
        </label>
        <a href="#" style={{
          fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', textDecoration: 'none',
        }}>Zaboravili lozinku?</a>
      </div>

      {/* Submit */}
      <BBButton variant="primary" iconLeft="login" fullWidth size="lg">Prijava</BBButton>

      {/* Divider */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12, margin: '24px 0 16px',
      }}>
        <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>ili nastavite s</span>
        <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
      </div>

      {/* SSO buttons */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <SsoButton>
          <GoogleLogo size={18} />
          <span>Prijava preko Googlea</span>
        </SsoButton>
        <SsoButton>
          <AppleLogo size={18} />
          <span>Prijava preko Applea</span>
        </SsoButton>
      </div>

      {/* Foot */}
      <div style={{ textAlign: 'center', marginTop: 24 }}>
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>Nemate račun?</span>
        {' '}
        <a href="#" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', textDecoration: 'none' }}>
          Kreiraj račun
        </a>
      </div>
    </div>
  );
};

const SsoButton = ({ dark = false, children }) => (
  <button type="button" style={{
    height: 48,
    width: '100%',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10,
    padding: '0 16px',
    background: dark ? '#000000' : 'var(--bb-surface)',
    color: dark ? '#FFFFFF' : 'var(--bb-text-primary)',
    border: dark ? '1px solid #000000' : '1px solid var(--bb-border)',
    borderRadius: 'var(--bb-radius-sm)',
    fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: 600,
    cursor: 'pointer',
    transition: 'background 120ms ease-out, transform 120ms ease-out',
  }}>
    {children}
  </button>
);

// ──────────────────────────────────────────────────────────────
// Page wrappers
// ──────────────────────────────────────────────────────────────
const AuthLoginDesktop = () => (
  <div className="theme-light bb-screen" style={{
    width: 1440, height: 1100,
    background: 'linear-gradient(135deg, #FAFAFA 0%, #FFFFFF 50%, #F4F1FF 100%)',
    fontFamily: 'var(--bb-font-sans)',
    position: 'relative', overflow: 'hidden',
    display: 'flex',
  }}>
    <AuthBackdrop />

    {/* Left side: brand / pitch */}
    <div style={{
      flex: 1, padding: '64px 80px',
      display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
      position: 'relative', zIndex: 1,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <BBLogo size={40} />
        <span style={{ fontSize: 22, fontWeight: 700, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>BookBed</span>
      </div>

      <div style={{ maxWidth: 520 }}>
        <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)', marginBottom: 12 }}>Owner aplikacija</div>
        <h2 style={{
          margin: 0, fontSize: 48, fontWeight: 800,
          color: 'var(--bb-text-primary)', letterSpacing: '-0.03em', lineHeight: 1.1,
        }}>
          Sve vaše rezervacije.<br />Jedno mjesto.
        </h2>
        <p className="bb-body-lg" style={{ marginTop: 16, color: 'var(--bb-text-secondary)' }}>
          Booking.com, Airbnb i vlastiti widget — sinkronizirano svakih 15 minuta. Bez dvostrukih rezervacija.
        </p>
        <div style={{ display: 'flex', gap: 24, marginTop: 32 }}>
          <PitchStat value="45+" label="aktivnih vlasnika" />
          <PitchStat value="12k" label="rezervacija godišnje" />
          <PitchStat value="99.9%" label="uptime" />
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>© 2026 BookBed Inc.</span>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>·</span>
        <a href="#" style={{ fontSize: 12, color: 'var(--bb-text-tertiary)', textDecoration: 'none' }}>Uvjeti</a>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>·</span>
        <a href="#" style={{ fontSize: 12, color: 'var(--bb-text-tertiary)', textDecoration: 'none' }}>Privatnost</a>
      </div>
    </div>

    {/* Right side: login card */}
    <div style={{
      flex: '0 0 560px', padding: '64px 60px',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative', zIndex: 1,
    }}>
      <LoginCard size="desktop" />
    </div>
  </div>
);

const PitchStat = ({ value, label }) => (
  <div>
    <div className="bb-tnum" style={{ fontSize: 28, fontWeight: 800, color: 'var(--bb-primary)', letterSpacing: '-0.02em' }}>{value}</div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>{label}</div>
  </div>
);

const AuthLoginTablet = () => (
  <div className="theme-light bb-screen" style={{
    width: 768, height: 1024,
    background: 'linear-gradient(135deg, #FAFAFA 0%, #FFFFFF 50%, #F4F1FF 100%)',
    fontFamily: 'var(--bb-font-sans)',
    position: 'relative', overflow: 'hidden',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    padding: 32,
  }}>
    <AuthBackdrop />
    <LoginCard size="tablet" />
  </div>
);

const AuthLoginMobile = () => (
  <div className="theme-light bb-screen" style={{
    width: 390, height: 880,
    background: 'linear-gradient(160deg, #FAFAFA 0%, #FFFFFF 40%, #F4F1FF 100%)',
    fontFamily: 'var(--bb-font-sans)',
    position: 'relative', overflow: 'hidden',
    display: 'flex', alignItems: 'center',
    padding: '20px 16px',
  }}>
    <AuthBackdrop />
    <LoginCard size="mobile" />
  </div>
);

Object.assign(window, { AuthLoginDesktop, AuthLoginTablet, AuthLoginMobile });
