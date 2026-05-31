/* eslint-disable */
// Admin login — Prompt 31. Separate instance from the owner app: ENGLISH, internal-console tone, purple-accented.
// Web-only but responsive (desktop / tablet / mobile-web). Reuses SsoButton + GoogleLogo from auth.jsx.

const ADMIN_PURPLE_BG = 'radial-gradient(1200px 600px at 80% -10%, rgba(139,111,255,0.35) 0%, rgba(139,111,255,0) 60%), linear-gradient(135deg, #241A52 0%, #36277A 55%, #241A52 100%)';

const AdminGridPattern = () => (
  <div style={{
    position: 'absolute', inset: 0, zIndex: 0, pointerEvents: 'none', opacity: 0.5,
    backgroundImage: 'linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px)',
    backgroundSize: '40px 40px',
    maskImage: 'radial-gradient(ellipse at center, #000 0%, transparent 75%)',
    WebkitMaskImage: 'radial-gradient(ellipse at center, #000 0%, transparent 75%)',
  }} />
);

const AdminCheck = ({ label }) => (
  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
    <span style={{ width: 18, height: 18, borderRadius: 5, background: 'var(--bb-primary)', border: '1.5px solid var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <BBIcon name="check" size={12} style={{ color: '#FFFFFF' }} />
    </span>
    <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>{label}</span>
  </label>
);

const AdminLoginCard = ({ size = 'desktop' }) => {
  const isMobile = size === 'mobile';
  return (
    <div style={{
      width: isMobile ? '100%' : 420, maxWidth: '100%',
      background: 'var(--bb-surface)',
      borderRadius: 'var(--bb-radius-xl)',
      boxShadow: '0 32px 64px -24px rgba(10, 6, 30, 0.6), 0 8px 24px -8px rgba(107,76,230,0.3)',
      overflow: 'hidden', position: 'relative', zIndex: 1,
    }}>
      {/* top accent bar */}
      <div style={{ height: 5, background: 'var(--bb-gradient-primary)' }} />
      <div style={{ padding: isMobile ? 24 : 36 }}>
        {/* brand + admin pill */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24 }}>
          <BBLogo size={32} />
          <span style={{ fontSize: 18, fontWeight: 700, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>BookBed</span>
          <span style={{ background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', fontSize: 10, fontWeight: 800, letterSpacing: '0.1em', padding: '3px 8px', borderRadius: 6 }}>ADMIN</span>
        </div>

        <h1 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Welcome back</h1>
        <p className="bb-body" style={{ margin: '6px 0 24px', color: 'var(--bb-text-secondary)' }}>Sign in to the BookBed admin console.</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <BBInput label="Work email" iconLeft="mail" placeholder="you@bookbed.io" type="email" />
          <BBInput label="Password" iconLeft="lock" placeholder="••••••••" iconRight="visibility_off" type="password" />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 16, marginBottom: 20 }}>
          <AdminCheck label="Remember this device" />
          <a href="#" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', textDecoration: 'none' }}>Forgot password?</a>
        </div>

        <BBButton variant="primary" iconLeft="login" fullWidth size="lg">Sign in</BBButton>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '22px 0 16px' }}>
          <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>or</span>
          <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
        </div>

        <SsoButton>
          <GoogleLogo size={18} />
          <span>Continue with Google Workspace</span>
        </SsoButton>

        {/* 2FA note */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 20, padding: '10px 12px', background: 'var(--bb-success-tint)', borderRadius: 'var(--bb-radius-sm)' }}>
          <BBIcon name="shield" size={16} style={{ color: 'var(--bb-success)', flexShrink: 0 }} />
          <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>Protected by two-factor authentication.</span>
        </div>

        <p className="bb-caption" style={{ textAlign: 'center', margin: '20px 0 0', color: 'var(--bb-text-tertiary)' }}>
          Authorized staff only. Activity is logged.
        </p>
      </div>
    </div>
  );
};

// Console chrome label (desktop/tablet)
const AdminConsoleMark = () => (
  <div style={{ position: 'absolute', top: 28, left: 32, zIndex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
    <BBIcon name="admin_panel_settings" size={20} style={{ color: 'rgba(255,255,255,0.85)' }} />
    <span style={{ color: 'rgba(255,255,255,0.85)', fontSize: 14, fontWeight: 600, letterSpacing: '0.01em' }}>BookBed Admin Console</span>
  </div>
);
const AdminFootMark = () => (
  <div style={{ position: 'absolute', bottom: 24, left: 0, right: 0, textAlign: 'center', zIndex: 1 }}>
    <span style={{ color: 'rgba(255,255,255,0.55)', fontSize: 12 }} className="bb-tnum">v2.4 · Internal tool · © 2026 BookBed Inc.</span>
  </div>
);

const AdminLoginDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, height: 1100, background: ADMIN_PURPLE_BG, fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
    <AdminGridPattern />
    <AdminConsoleMark />
    <AdminLoginCard size="desktop" />
    <AdminFootMark />
  </div>
);

const AdminLoginTablet = () => (
  <div className="theme-light bb-screen" style={{ width: 768, height: 1024, background: ADMIN_PURPLE_BG, fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 32 }}>
    <AdminGridPattern />
    <AdminConsoleMark />
    <AdminLoginCard size="tablet" />
    <AdminFootMark />
  </div>
);

const AdminLoginMobile = () => (
  <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: ADMIN_PURPLE_BG, fontFamily: 'var(--bb-font-sans)', position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', padding: '20px 16px' }}>
    <AdminGridPattern />
    <AdminLoginCard size="mobile" />
  </div>
);

Object.assign(window, { AdminLoginDesktop, AdminLoginTablet, AdminLoginMobile });
