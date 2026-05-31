/* eslint-disable */
// Auth · Account recovery — Prompt 36 (part 1). Forgot password → reset-sent → email verify.
// Glass cards on the auth gradient backdrop (reuses AuthBackdrop). HR.

const RecCard = ({ icon, iconTone = 'primary', title, sub, children, size = 'desktop' }) => {
  const isMobile = size === 'mobile';
  const toneBg = { primary: 'var(--bb-primary-tint-bg)', success: 'var(--bb-success-tint)', tertiary: 'var(--bb-tertiary-tint)' }[iconTone];
  const toneFg = { primary: 'var(--bb-primary)', success: 'var(--bb-success)', tertiary: 'var(--bb-tertiary-dark)' }[iconTone];
  return (
    <div style={{
      width: isMobile ? '100%' : 420, maxWidth: '100%',
      padding: isMobile ? 24 : 36,
      background: 'rgba(255, 255, 255, 0.82)',
      backdropFilter: 'blur(24px) saturate(140%)', WebkitBackdropFilter: 'blur(24px) saturate(140%)',
      border: '1px solid rgba(255, 255, 255, 0.65)',
      borderRadius: 'var(--bb-radius-xl)',
      boxShadow: '0 24px 48px -16px rgba(45, 55, 72, 0.18), 0 8px 24px -8px rgba(107, 76, 230, 0.18)',
      position: 'relative', zIndex: 1, textAlign: 'center',
    }}>
      <div style={{ width: 64, height: 64, borderRadius: 18, background: toneBg, color: toneFg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 18 }}>
        <BBIcon name={icon} size={32} />
      </div>
      <h1 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h1>
      <p className="bb-body" style={{ margin: '8px 0 24px', color: 'var(--bb-text-secondary)', lineHeight: 1.55 }}>{sub}</p>
      <div style={{ textAlign: 'left' }}>{children}</div>
    </div>
  );
};

const RecBackLink = () => (
  <div style={{ textAlign: 'center', marginTop: 22 }}>
    <a href="#" style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', textDecoration: 'none' }}>
      <BBIcon name="arrow_back" size={16} /> Natrag na prijavu
    </a>
  </div>
);

// 1 · Forgot password (request)
const ForgotCard = ({ size = 'desktop' }) => (
  <RecCard size={size} icon="lock_reset" title="Zaboravljena lozinka" sub="Unesite e-poštu i poslat ćemo vam poveznicu za promjenu lozinke.">
    <BBInput label="Email" iconLeft="mail" placeholder="ime@primjer.hr" type="email" />
    <div style={{ marginTop: 18 }}>
      <BBButton variant="primary" iconLeft="send" fullWidth size="lg">Pošalji poveznicu</BBButton>
    </div>
    <RecBackLink />
  </RecCard>
);

// 2 · Reset link sent
const SentCard = ({ size = 'desktop' }) => (
  <RecCard size={size} icon="mark_email_read" iconTone="success" title="Provjerite e-poštu" sub={<>Poslali smo poveznicu za promjenu lozinke na <strong style={{ color: 'var(--bb-text-primary)' }}>ivana@apartmaniadria.hr</strong>.</>}>
    <BBButton variant="secondary" iconLeft="open_in_new" fullWidth size="lg">Otvori e-poštu</BBButton>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', marginTop: 16 }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Niste primili?</span>
      <a href="#" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-text-disabled)', textDecoration: 'none' }} className="bb-tnum">Pošalji ponovno (0:42)</a>
    </div>
    <RecBackLink />
  </RecCard>
);

// 3 · Email verification (code)
const CodeInput = ({ digits, focusIndex }) => (
  <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
    {digits.map((d, i) => {
      const focused = i === focusIndex;
      return (
        <div key={i} style={{
          width: 48, height: 56, borderRadius: 'var(--bb-radius-sm)',
          background: 'var(--bb-surface)',
          border: `${focused || d ? '2px' : '1px'} solid ${focused ? 'var(--bb-primary)' : d ? 'var(--bb-border)' : 'var(--bb-border)'}`,
          boxShadow: focused ? 'var(--bb-focus-ring)' : 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 22, fontWeight: 700, color: 'var(--bb-text-primary)', fontVariantNumeric: 'tabular-nums',
        }}>{d || (focused ? <span style={{ width: 2, height: 24, background: 'var(--bb-primary)', borderRadius: 2 }} /> : '')}</div>
      );
    })}
  </div>
);

const VerifyCard = ({ size = 'desktop' }) => (
  <RecCard size={size} icon="mark_email_unread" iconTone="primary" title="Potvrdite e-poštu" sub={<>Unesite 6-znamenkasti kôd poslan na <strong style={{ color: 'var(--bb-text-primary)' }}>ivana@…hr</strong>.</>}>
    <CodeInput digits={['4', '8', '2', '', '', '']} focusIndex={3} />
    <div style={{ marginTop: 20 }}>
      <BBButton variant="primary" iconLeft="check" fullWidth size="lg">Potvrdi</BBButton>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', marginTop: 16 }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Pošalji ponovno za</span>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>0:42</span>
    </div>
    <div style={{ textAlign: 'center', marginTop: 6 }}>
      <a href="#" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', textDecoration: 'none' }}>Promijenite e-poštu</a>
    </div>
  </RecCard>
);

// ──────────────────────────────────────────────────────────────
// Gallery (3-step flow) + mobile
// ──────────────────────────────────────────────────────────────
const RecStep = ({ n, label, children }) => (
  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
      <span style={{ width: 26, height: 26, borderRadius: '50%', background: 'rgba(255,255,255,0.9)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 800, fontVariantNumeric: 'tabular-nums' }}>{n}</span>
      <span style={{ color: 'rgba(255,255,255,0.92)', fontSize: 13, fontWeight: 700, letterSpacing: '0.02em' }}>{label}</span>
    </div>
    {children}
  </div>
);

const RecoveryGalleryDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, height: 1100, background: 'linear-gradient(135deg, #2A1D5E 0%, #3A2A7A 55%, #2A1D5E 100%)', fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 28, padding: 40 }}>
    <AuthBackdrop />
    <div style={{ position: 'relative', zIndex: 1, textAlign: 'center', marginBottom: 4 }}>
      <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.7)' }}>Prompt 36 · Account recovery</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0', color: '#FFFFFF' }}>Oporavak računa</h2>
    </div>
    <div style={{ position: 'relative', zIndex: 1, display: 'flex', gap: 28, alignItems: 'flex-start' }}>
      <RecStep n="1" label="Zatraži"><ForgotCard /></RecStep>
      <RecStep n="2" label="Provjeri e-poštu"><SentCard /></RecStep>
      <RecStep n="3" label="Potvrdi"><VerifyCard /></RecStep>
    </div>
  </div>
);

const RecoveryVerifyMobile = () => (
  <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: 'linear-gradient(160deg, #FAFAFA 0%, #FFFFFF 40%, #F4F1FF 100%)', fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', padding: '20px 16px' }}>
    <AuthBackdrop />
    <VerifyCard size="mobile" />
  </div>
);

const RecoveryForgotMobile = () => (
  <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: 'linear-gradient(160deg, #FAFAFA 0%, #FFFFFF 40%, #F4F1FF 100%)', fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', padding: '20px 16px' }}>
    <AuthBackdrop />
    <ForgotCard size="mobile" />
  </div>
);

Object.assign(window, { RecoveryGalleryDesktop, RecoveryVerifyMobile, RecoveryForgotMobile });
