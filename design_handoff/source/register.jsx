/* eslint-disable */
// Auth · Register — Prompt 35. Owner app, HR. Mirrors the login split-screen glass-card pattern (auth.jsx).
// Reuses AuthBackdrop, SsoButton, GoogleLogo, AppleLogo, PitchStat (auth.jsx) + SStrengthMeter (settings.jsx).

const RegTerms = () => (
  <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer', marginTop: 14 }}>
    <span style={{ width: 18, height: 18, borderRadius: 5, flexShrink: 0, marginTop: 2, background: 'var(--bb-primary)', border: '1.5px solid var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <BBIcon name="check" size={12} style={{ color: '#FFFFFF' }} />
    </span>
    <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', lineHeight: 1.5 }}>
      Prihvaćam <a href="#" style={{ color: 'var(--bb-primary)', fontWeight: 600, textDecoration: 'none' }}>Uvjete korištenja</a> i <a href="#" style={{ color: 'var(--bb-primary)', fontWeight: 600, textDecoration: 'none' }}>Pravila privatnosti</a>.
    </span>
  </label>
);

const RegisterCard = ({ size = 'desktop' }) => {
  const isMobile = size === 'mobile';
  return (
    <div style={{
      width: isMobile ? '100%' : 440, maxWidth: '100%',
      padding: isMobile ? 24 : 36,
      background: 'rgba(255, 255, 255, 0.78)',
      backdropFilter: 'blur(24px) saturate(140%)', WebkitBackdropFilter: 'blur(24px) saturate(140%)',
      border: '1px solid rgba(255, 255, 255, 0.65)',
      borderRadius: 'var(--bb-radius-xl)',
      boxShadow: '0 24px 48px -16px rgba(45, 55, 72, 0.18), 0 8px 24px -8px rgba(107, 76, 230, 0.18)',
      position: 'relative', zIndex: 1,
    }}>
      <div style={{ textAlign: 'center', marginBottom: 24 }}>
        <div style={{ display: 'inline-flex', marginBottom: 14, filter: 'drop-shadow(0 6px 18px rgba(107,76,230,0.32))' }}>
          <BBLogo size={52} />
        </div>
        <h1 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Kreirajte račun</h1>
        <p className="bb-body" style={{ margin: '6px 0 0', color: 'var(--bb-text-secondary)' }}>Započnite besplatno — bez kartice.</p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <BBInput label="Ime i prezime" iconLeft="person" placeholder="Ivana Marić" />
        <BBInput label="Email" iconLeft="mail" placeholder="ime@primjer.hr" type="email" />
        <div>
          <BBInput label="Lozinka" iconLeft="lock" placeholder="••••••••" iconRight="visibility_off" type="password" />
          <SStrengthMeter score={3} label="Jaka" />
        </div>
      </div>

      <RegTerms />

      <div style={{ marginTop: 20 }}>
        <BBButton variant="primary" iconLeft="person_add" fullWidth size="lg">Kreiraj račun</BBButton>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '22px 0 16px' }}>
        <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>ili nastavite s</span>
        <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <SsoButton><GoogleLogo size={18} /><span>Registracija preko Googlea</span></SsoButton>
        <SsoButton><AppleLogo size={18} /><span>Registracija preko Applea</span></SsoButton>
      </div>

      <div style={{ textAlign: 'center', marginTop: 22 }}>
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>Već imate račun?</span>{' '}
        <a href="#" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', textDecoration: 'none' }}>Prijava</a>
      </div>
    </div>
  );
};

// Desktop left brand panel (mirror of login, register-flavored)
const RegBrandPanel = () => (
  <div style={{ flex: 1, padding: '64px 80px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative', zIndex: 1 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <BBLogo size={40} />
      <span style={{ fontSize: 22, fontWeight: 700, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>BookBed</span>
    </div>
    <div style={{ maxWidth: 520 }}>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)', marginBottom: 12 }}>Owner aplikacija</div>
      <h2 style={{ margin: 0, fontSize: 48, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.03em', lineHeight: 1.1 }}>
        Počnite upravljati<br />u nekoliko minuta.
      </h2>
      <p className="bb-body-lg" style={{ marginTop: 16, color: 'var(--bb-text-secondary)' }}>
        Dodajte jedinice, povežite kanale i primajte rezervacije izravno na svoju stranicu — bez provizije po rezervaciji na Pro planu.
      </p>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 28 }}>
        {['14 dana Pro besplatno', 'Bez kartice pri registraciji', 'Otkažite bilo kada'].map((t, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <BBIcon name="check_circle" size={20} fill={1} style={{ color: 'var(--bb-success)' }} />
            <span className="bb-body" style={{ color: 'var(--bb-text-secondary)' }}>{t}</span>
          </div>
        ))}
      </div>
    </div>
    <div style={{ display: 'flex', gap: 24 }}>
      <PitchStat value="45+" label="aktivnih vlasnika" />
      <PitchStat value="12k" label="rezervacija godišnje" />
      <PitchStat value="99.9%" label="uptime" />
    </div>
  </div>
);

const RegisterDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, height: 1100, background: 'linear-gradient(135deg, #FAFAFA 0%, #FFFFFF 50%, #F4F1FF 100%)', fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex' }}>
    <AuthBackdrop />
    <RegBrandPanel />
    <div style={{ flex: '0 0 560px', padding: '56px 60px', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative', zIndex: 1 }}>
      <RegisterCard size="desktop" />
    </div>
  </div>
);

const RegisterTablet = () => (
  <div className="theme-light bb-screen" style={{ width: 768, height: 1024, background: 'linear-gradient(135deg, #FAFAFA 0%, #FFFFFF 50%, #F4F1FF 100%)', fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 32 }}>
    <AuthBackdrop />
    <RegisterCard size="tablet" />
  </div>
);

const RegisterMobile = () => (
  <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: 'linear-gradient(160deg, #FAFAFA 0%, #FFFFFF 40%, #F4F1FF 100%)', fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', padding: '20px 16px' }}>
    <AuthBackdrop />
    <RegisterCard size="mobile" />
  </div>
);

Object.assign(window, { RegisterDesktop, RegisterTablet, RegisterMobile });
