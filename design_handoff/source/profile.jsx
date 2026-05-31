/* eslint-disable */
// Profile hub — Prompt 12 redesign.
// Hero identity card · "Nadogradite na Pro" promo below Account · grouped sections · Opasna zona.

const { useState: useStP } = React;

const PROFILE_USER = {
  name: 'Ivana Marić',
  email: 'ivana@apartmaniadria.hr',
  profilePct: 64,
  plan: 'Probni period',
  trialDaysLeft: 12,
  language: 'Hrvatski',
  theme: 'Sustavna',
};

// Settings groups (shared across breakpoints)
const PROFILE_GROUPS = [
  {
    id: 'racun', title: 'Račun',
    rows: [
      { id: 'edit-profile',  icon: 'badge',          label: 'Uredi profil',        sub: 'Ime, telefon, kontakt' },
      { id: 'password',      icon: 'lock_reset',     label: 'Promijeni lozinku',   sub: 'Posljednja promjena prije 47 dana' },
      { id: 'notifications', icon: 'notifications',  label: 'Postavke obavijesti', sub: 'Email i push' },
      { id: 'subscription',  icon: 'workspace_premium', label: 'Pretplata',         valueBadge: { label: 'Probni period', tone: 'tertiary' } },
      { id: 'language',      icon: 'language',       label: 'Jezik',               value: PROFILE_USER.language },
      { id: 'theme',         icon: 'palette',        label: 'Tema',                value: PROFILE_USER.theme },
    ],
  },
  {
    id: 'aplikacija', title: 'Aplikacija',
    rows: [
      { id: 'help',  icon: 'help_outline', label: 'Pomoć i podrška', sub: 'FAQ · kontakt · vodič' },
      { id: 'about', icon: 'info',         label: 'O aplikaciji',    value: 'v3.4.1' },
    ],
  },
  {
    id: 'pravno', title: 'Pravno',
    rows: [
      { id: 'terms',   icon: 'description', label: 'Uvjeti korištenja' },
      { id: 'privacy', icon: 'verified_user', label: 'Pravila privatnosti' },
      { id: 'cookies', icon: 'cookie',      label: 'Politika kolačića' },
    ],
  },
  {
    id: 'opasno', title: 'Opasna zona', destructive: true,
    rows: [
      { id: 'delete', icon: 'delete_forever', label: 'Obriši račun', sub: 'Trajno briše sve podatke', destructive: true },
      { id: 'logout', icon: 'logout',         label: 'Odjava', destructive: true },
    ],
  },
];

// ──────────────────────────────────────────────────────────────
// IdentityHero (shared, just scales)
// ──────────────────────────────────────────────────────────────
const IdentityHero = ({ size = 'desktop' }) => {
  const isMobile = size === 'mobile';
  const isCompact = size === 'mobile' || size === 'tablet';
  const padding = isMobile ? 20 : 28;
  const avatarSize = isMobile ? 'lg' : 'xl';

  return (
    <div style={{
      borderRadius: 'var(--bb-radius-xl)',
      background: 'var(--bb-gradient-hero)',
      color: '#FFFFFF',
      padding,
      position: 'relative',
      overflow: 'hidden',
      boxShadow: 'var(--bb-shadow-purple)',
      marginBottom: isMobile ? 12 : 20,
    }}>
      {/* Decorative blobs */}
      <div style={{
        position: 'absolute', top: -80, right: -60, width: 280, height: 280,
        borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.20) 0%, rgba(255,255,255,0) 70%)',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', bottom: -60, left: -40, width: 220, height: 220,
        borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.10) 0%, rgba(255,255,255,0) 70%)',
        pointerEvents: 'none',
      }} />

      <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: isCompact ? 14 : 20 }}>
        <BBAvatarSlot id="bb-owner-avatar" size={avatarSize === 'lg' ? 56 : 80} ring ringColor="rgba(255,255,255,0.4)" placeholder="Foto" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <h2 style={{
            margin: 0, color: '#FFFFFF',
            fontSize: isMobile ? 22 : 28, fontWeight: 700, letterSpacing: '-0.02em',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{PROFILE_USER.name}</h2>
          {/* Email pill */}
          <div style={{ display: 'inline-flex', marginTop: 6, alignItems: 'center', gap: 6 }}>
            <span style={{
              background: 'rgba(255,255,255,0.18)', color: '#FFFFFF',
              padding: '4px 10px', borderRadius: 999,
              fontSize: 12, fontWeight: 500,
              backdropFilter: 'blur(6px)', WebkitBackdropFilter: 'blur(6px)',
            }}>
              <BBIcon name="mail" size={12} style={{ verticalAlign: 'text-bottom', marginRight: 4 }} />
              {PROFILE_USER.email}
            </span>
            <span style={{
              background: 'rgba(255,255,255,0.18)', color: '#FFFFFF',
              padding: '4px 10px', borderRadius: 999,
              fontSize: 12, fontWeight: 500,
            }}>
              <BBIcon name="hotel" size={12} style={{ verticalAlign: 'text-bottom', marginRight: 4 }} />
              2 jedinice
            </span>
          </div>
        </div>
        {!isMobile && (
          <BBButton variant="on-gradient" iconLeft="edit">Uredi</BBButton>
        )}
      </div>

      {/* Frosted progress panel */}
      <div style={{
        position: 'relative', marginTop: isMobile ? 16 : 22,
        background: 'rgba(255,255,255,0.16)',
        border: '1px solid rgba(255,255,255,0.22)',
        backdropFilter: 'blur(12px)', WebkitBackdropFilter: 'blur(12px)',
        borderRadius: 'var(--bb-radius-md)',
        padding: '14px 16px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <span className="bb-label" style={{ color: 'rgba(255,255,255,0.92)', fontWeight: 600 }}>
            Profil <span className="bb-tnum">{PROFILE_USER.profilePct}%</span> ispunjen
          </span>
          <span className="bb-caption" style={{ color: 'rgba(255,255,255,0.76)' }}>
            Ispunite za više povjerenja gostiju
          </span>
        </div>
        {/* Progress bar */}
        <div style={{
          height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.22)',
          overflow: 'hidden',
        }}>
          <div style={{
            height: '100%',
            width: `${PROFILE_USER.profilePct}%`,
            background: 'linear-gradient(90deg, #FFFFFF 0%, rgba(255,255,255,0.78) 100%)',
            borderRadius: 999,
          }} />
        </div>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Slim Pro promo banner
// ──────────────────────────────────────────────────────────────
const ProBanner = ({ compact = false }) => (
  <BBCard variant="accent-left" accentTone="primary" padded={false} style={{ marginBottom: 24 }}>
    <div style={{
      display: 'flex', alignItems: 'center', gap: compact ? 12 : 16,
      padding: compact ? '12px 14px' : '14px 20px',
    }}>
      <div style={{
        width: compact ? 36 : 44, height: compact ? 36 : 44, borderRadius: 12,
        background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}>
        <BBIcon name="workspace_premium" size={compact ? 20 : 24} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>
          Nadogradite na Pro
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>
          Neograničeno jedinica · napredna analitika · prioritetna podrška
        </div>
      </div>
      <BBButton variant="primary" size={compact ? 'sm' : 'md'} iconRight="arrow_forward">
        {compact ? 'Saznaj više' : 'Nadogradi'}
      </BBButton>
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// SettingsGroup — section header + card with rows
// ──────────────────────────────────────────────────────────────
const SettingsGroup = ({ group, compact = false }) => (
  <div style={{ marginBottom: 24 }}>
    <BBSectionHeader title={group.title} level="h3" style={{ marginBottom: 10 }} />
    <BBCard padded={false}>
      {group.rows.map((row, i) => (
        <SettingsRow key={row.id} row={row} divider={i < group.rows.length - 1} compact={compact} />
      ))}
    </BBCard>
  </div>
);

const SettingsRow = ({ row, divider, compact }) => {
  const tintBg = row.destructive ? 'var(--bb-error-tint)' : 'var(--bb-primary-tint-bg)';
  const tintFg = row.destructive ? 'var(--bb-error)' : 'var(--bb-primary)';
  const labelColor = row.destructive ? 'var(--bb-error)' : 'var(--bb-text-primary)';
  return (
    <button type="button" style={{
      width: '100%', border: 'none', background: 'transparent', cursor: 'pointer',
      padding: compact ? '12px 14px' : '14px 20px',
      display: 'flex', alignItems: 'center', gap: 14,
      borderBottom: divider ? '1px solid var(--bb-border-subtle)' : 'none',
      textAlign: 'left',
      transition: 'background 120ms ease-out',
    }}
    onMouseEnter={e => e.currentTarget.style.background = row.destructive ? 'var(--bb-error-tint)' : 'var(--bb-primary-tint-bg)'}
    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
      <div style={{
        width: compact ? 32 : 36, height: compact ? 32 : 36, borderRadius: 10,
        background: tintBg, color: tintFg, flexShrink: 0,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name={row.icon} size={compact ? 18 : 20} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: labelColor, fontWeight: 600, fontSize: compact ? 13 : 14 }}>
          {row.label}
        </div>
        {row.sub && (
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{row.sub}</div>
        )}
      </div>
      {row.value && (
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>{row.value}</span>
      )}
      {row.valueBadge && (
        <BBStatusBadge
          status={row.valueBadge.tone === 'tertiary' ? 'pending' : 'confirmed'}
          label={row.valueBadge.label}
          dot={false}
          size="sm"
        />
      )}
      <BBIcon name="chevron_right" size={20} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }} />
    </button>
  );
};

// ──────────────────────────────────────────────────────────────
// ProfileDesktop (1440 × 1100)
// ──────────────────────────────────────────────────────────────
const ProfileDesktop = () => (
  <div className="theme-light bb-screen" style={{
    width: 1440, height: 1100, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebar user={SAMPLE_USER} active="profil" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar title="Profil" notifCount={6} actions={[
        { icon: 'light_mode', label: 'Tema' },
      ]} />
      <main style={{
        padding: '24px 32px 32px', flex: 1, overflow: 'hidden',
        display: 'flex', justifyContent: 'center',
      }}>
        <div style={{ width: 800, maxWidth: '100%' }}>
          <IdentityHero size="desktop" />

          {/* Two-column settings layout */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, alignItems: 'start' }}>
            <div>
              <SettingsGroup group={PROFILE_GROUPS[0]} />
            </div>
            <div>
              <ProBanner />
              <SettingsGroup group={PROFILE_GROUPS[1]} />
              <SettingsGroup group={PROFILE_GROUPS[3]} />
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// ProfileTablet (768 × 1024)
// ──────────────────────────────────────────────────────────────
const ProfileTablet = () => (
  <div className="theme-light bb-screen" style={{
    width: 768, height: 1024, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebarRail active="profil" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar title="Profil" notifCount={6} actions={[{ icon: 'light_mode', label: 'Tema' }]} />
      <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
        <div style={{ maxWidth: 600, margin: '0 auto' }}>
          <IdentityHero size="tablet" />
          <SettingsGroup group={PROFILE_GROUPS[0]} compact />
          <ProBanner compact />
          <SettingsGroup group={PROFILE_GROUPS[3]} compact />
        </div>
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// ProfileMobile (390 × 880)
// ──────────────────────────────────────────────────────────────
const ProfileMobile = () => (
  <div className="theme-light bb-screen" style={{
    width: 390, height: 880,
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    display: 'flex', flexDirection: 'column',
  }}>
    <BBAppBar title="Profil" showHamburger notifCount={6} actions={[{ icon: 'light_mode', label: 'Tema' }]} />
    <main style={{ flex: 1, padding: '12px 16px 0', overflow: 'hidden' }}>
      <IdentityHero size="mobile" />
      <SettingsGroup group={PROFILE_GROUPS[0]} compact />
      <ProBanner compact />
    </main>
  </div>
);

Object.assign(window, { ProfileDesktop, ProfileTablet, ProfileMobile });
