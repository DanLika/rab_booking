/* eslint-disable */
// Profil · Premium 2026 — flagship host account command center.
// Carries the Premium language into Profil: soft layered cards, eyebrow header, a premium
// IDENTITY card with a profile-completion radial gauge + verified-status chips, a row of
// HOST-TRUST KPI stats (rating / response rate / response time / completed stays), a richer
// BookBed Pro upgrade card with trial progress, and grouped settings restyled into premium
// cards with the destructive zone at the foot. Reuses BB primitives. Loads AFTER profile.jsx.

const PFP_SHADOW = '0 1px 2px rgba(16,24,40,0.04), 0 4px 10px -2px rgba(16,24,40,0.06), 0 24px 48px -16px rgba(16,24,40,0.10)';
const PFP_SHADOW_SM = '0 1px 2px rgba(16,24,40,0.04), 0 2px 6px -1px rgba(16,24,40,0.06)';

const PFP_USER = {
  name: 'Ivana Marić',
  email: 'ivana@apartmaniadria.hr',
  location: 'Split, Hrvatska',
  memberSince: '2023',
  profilePct: 64,
  units: 2,
};

// ──────────────────────────────────────────────────────────────
// Local premium primitives (PFP-prefixed to avoid scope collisions)
// ──────────────────────────────────────────────────────────────
const PFPCard = ({ children, pad = 24, className = '', style = {} }) => (
  <div className={className} style={{
    background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)',
    borderRadius: 'var(--bb-radius-md)', boxShadow: PFP_SHADOW, padding: pad, ...style,
  }}>{children}</div>
);

const PFPEyebrow = ({ children, style = {} }) => (
  <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--bb-text-tertiary)', ...style }}>{children}</div>
);

const PFPDelta = ({ value, positive = true }) => (
  <span style={{
    display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 12, fontWeight: 700,
    color: positive ? 'var(--bb-success)' : 'var(--bb-error)',
  }}>
    <BBIcon name={positive ? 'trending_up' : 'trending_down'} size={14} />
    <span className="bb-tnum">{value}</span>
  </span>
);

const pfpSmooth = (pts) => {
  let d = `M ${pts[0][0]} ${pts[0][1]}`;
  for (let i = 1; i < pts.length; i++) {
    const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
    const cx = (x0 + x1) / 2;
    d += ` C ${cx} ${y0} ${cx} ${y1} ${x1} ${y1}`;
  }
  return d;
};

const PFPSpark = ({ data, width = 84, height = 30, color = 'var(--bb-primary)' }) => {
  const max = Math.max(...data), min = Math.min(...data);
  const n = data.length;
  const xs = (i) => (i / (n - 1)) * width;
  const ys = (v) => height - 3 - ((v - min) / (max - min || 1)) * (height - 6);
  const pts = data.map((v, i) => [xs(i), ys(v)]);
  const line = pfpSmooth(pts);
  const gid = 'pfpspk' + Math.round(data[0] * 91 + data.length * 7 + max);
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ display: 'block', overflow: 'visible' }}>
      <defs>
        <linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.22" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={`${line} L ${width} ${height} L 0 ${height} Z`} fill={`url(#${gid})`} />
      <path d={line} fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" />
      <circle cx={pts[n - 1][0]} cy={pts[n - 1][1]} r="3" fill={color} />
    </svg>
  );
};

// Radial completion gauge
const PFPRadial = ({ value, size = 132, stroke = 13, label, sublabel }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c * (1 - value / 100);
  const cx = size / 2;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <defs>
          <linearGradient id="pfpGauge" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#6B4CE6" />
            <stop offset="100%" stopColor="#8B6FFF" />
          </linearGradient>
        </defs>
        <circle cx={cx} cy={cx} r={r} fill="none" stroke="var(--bb-surface-variant)" strokeWidth={stroke} />
        <circle cx={cx} cy={cx} r={r} fill="none" stroke="url(#pfpGauge)" strokeWidth={stroke}
          strokeDasharray={c} strokeDashoffset={off} strokeLinecap="round" transform={`rotate(-90 ${cx} ${cx})`} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <span className="bb-tnum" style={{ fontSize: 28, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1 }}>{label}</span>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{sublabel}</span>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Verified-status chip
// ──────────────────────────────────────────────────────────────
const PFPVerifyChip = ({ icon, label, state }) => {
  const styles = {
    done:    { bg: 'var(--bb-success-tint)',  fg: 'var(--bb-success)',  icon: 'check_circle' },
    pending: { bg: 'var(--bb-tertiary-tint)', fg: 'var(--bb-tertiary-dark)', icon: 'error' },
  }[state] || { bg: 'var(--bb-surface-variant)', fg: 'var(--bb-text-secondary)', icon };
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6, height: 28, padding: '0 12px',
      borderRadius: 999, background: styles.bg, color: styles.fg,
      fontSize: 12, fontWeight: 600,
    }}>
      <BBIcon name={styles.icon} size={15} />
      {label}
    </span>
  );
};

// ──────────────────────────────────────────────────────────────
// Identity command card
// ──────────────────────────────────────────────────────────────
const PFPIdentity = ({ compact = false }) => (
  <PFPCard pad={0} className="bb-lift" style={{ overflow: 'hidden' }}>
    {/* gradient accent strip */}
    <div style={{ height: 6, background: 'var(--bb-gradient-hero)' }} />
    <div style={{
      padding: compact ? 20 : 28,
      display: 'flex', alignItems: compact ? 'flex-start' : 'center', gap: compact ? 18 : 28,
      flexDirection: compact ? 'column' : 'row',
    }}>
      {/* identity */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 18, flex: 1, minWidth: 0, width: compact ? '100%' : 'auto' }}>
        <div style={{
          position: 'relative', flexShrink: 0,
          padding: 5, borderRadius: '50%', background: 'var(--bb-gradient-hero)',
          boxShadow: 'var(--bb-shadow-purple-sm)',
        }}>
          <div style={{ borderRadius: '50%', padding: 3, background: 'var(--bb-surface)' }}>
            <BBAvatarSlot id="bb-owner-avatar" size={80} placeholder="Foto" />
          </div>
        </div>
        <div style={{ minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <h1 style={{ margin: 0, fontSize: compact ? 22 : 26, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>{PFP_USER.name}</h1>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--bb-primary)', background: 'var(--bb-primary-tint-bg)', padding: '3px 9px', borderRadius: 999, fontSize: 11, fontWeight: 700 }}>
              <BBIcon name="verified" size={14} /> Domaćin
            </span>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '6px 14px', marginTop: 8 }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, color: 'var(--bb-text-secondary)' }}>
              <BBIcon name="mail" size={15} style={{ color: 'var(--bb-text-tertiary)' }} />
              <span className="bb-body">{PFP_USER.email}</span>
            </span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, color: 'var(--bb-text-secondary)' }}>
              <BBIcon name="place" size={15} style={{ color: 'var(--bb-text-tertiary)' }} />
              <span className="bb-body">{PFP_USER.location}</span>
            </span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, color: 'var(--bb-text-secondary)' }}>
              <BBIcon name="calendar_month" size={15} style={{ color: 'var(--bb-text-tertiary)' }} />
              <span className="bb-body">Član od {PFP_USER.memberSince}</span>
            </span>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
            <PFPVerifyChip label="Email potvrđen" state="done" />
            <PFPVerifyChip label="Telefon potvrđen" state="done" />
            <PFPVerifyChip label="Identitet" state="pending" />
          </div>
        </div>
      </div>

      {/* completion */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 18, flexShrink: 0,
        width: compact ? '100%' : 'auto',
        paddingTop: compact ? 18 : 0, marginTop: compact ? 4 : 0,
        borderTop: compact ? '1px solid var(--bb-border-subtle)' : 'none',
        borderLeft: compact ? 'none' : '1px solid var(--bb-border-subtle)',
        paddingLeft: compact ? 0 : 28,
      }}>
        <PFPRadial value={PFP_USER.profilePct} label={`${PFP_USER.profilePct}%`} sublabel="ispunjeno" />
        <div style={{ minWidth: 0 }}>
          <div className="bb-h3" style={{ color: 'var(--bb-text-primary)', margin: 0 }}>Dovršite profil</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', marginTop: 4, maxWidth: 200 }}>
            Još <span className="bb-tnum" style={{ fontWeight: 700, color: 'var(--bb-text-primary)' }}>3 koraka</span> do 100% — više povjerenja gostiju.
          </div>
          <div style={{ marginTop: 12 }}>
            <BBButton variant="primary" size="sm" iconRight="arrow_forward">Dovrši</BBButton>
          </div>
        </div>
      </div>
    </div>
  </PFPCard>
);

// ──────────────────────────────────────────────────────────────
// Host-trust KPI stats
// ──────────────────────────────────────────────────────────────
const PFP_STATS = [
  { icon: 'star', tone: 'tertiary', label: 'Ocjena domaćina', value: '4,9', delta: '+0,2', spark: [4.5, 4.6, 4.6, 4.7, 4.8, 4.8, 4.9] },
  { icon: 'mark_chat_read', tone: 'success', label: 'Stopa odgovora', value: '98%', delta: '+3%', spark: [88, 90, 92, 94, 95, 97, 98] },
  { icon: 'schedule', tone: 'info', label: 'Vrijeme odgovora', value: '~1 h', sub: 'prosjek zadnjih 30 dana' },
  { icon: 'task_alt', tone: 'primary', label: 'Završene rezervacije', value: '48', delta: '+6', spark: [30, 34, 37, 40, 43, 45, 48] },
];

const PFP_TONES = {
  primary:  { bg: 'var(--bb-primary-tint-bg)', fg: 'var(--bb-primary)' },
  success:  { bg: 'var(--bb-success-tint)',    fg: 'var(--bb-success)' },
  info:     { bg: 'var(--bb-info-tint)',       fg: 'var(--bb-info)' },
  tertiary: { bg: 'var(--bb-tertiary-tint)',   fg: 'var(--bb-tertiary-dark)' },
};

const PFPStat = ({ s, compact = false }) => {
  const t = PFP_TONES[s.tone] || PFP_TONES.primary;
  return (
    <PFPCard pad={20} className="bb-lift" style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name={s.icon} size={19} />
        </div>
        {s.delta && <PFPDelta value={s.delta} positive />}
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, marginTop: 16, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.label}</div>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 10, marginTop: 4 }}>
        <span className="bb-tnum" style={{ fontSize: compact ? 26 : 30, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1 }}>{s.value}</span>
        {s.spark && <PFPSpark data={s.spark} color={t.fg} width={compact ? 56 : 80} />}
      </div>
      {s.sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 8 }}>{s.sub}</div>}
    </PFPCard>
  );
};

// ──────────────────────────────────────────────────────────────
// BookBed Pro upgrade card (premium, trial-aware)
// ──────────────────────────────────────────────────────────────
const PFP_PRO_BENEFITS = [
  { icon: 'apartment', label: 'Neograničeno jedinica' },
  { icon: 'insights', label: 'Napredna analitika' },
  { icon: 'smart_toy', label: 'AI asistent bez ograničenja' },
  { icon: 'support_agent', label: 'Prioritetna podrška' },
];

const PFPProCard = ({ compact = false }) => (
  <div className="bb-lift" style={{
    position: 'relative', overflow: 'hidden', borderRadius: 'var(--bb-radius-md)',
    background: 'linear-gradient(120deg, rgba(107,76,230,0.10) 0%, rgba(139,111,255,0.06) 50%, rgba(61,217,176,0.06) 100%)',
    border: '1px solid rgba(107,76,230,0.20)', boxShadow: PFP_SHADOW_SM,
    padding: compact ? 20 : 28,
  }}>
    <div style={{ display: 'flex', alignItems: compact ? 'flex-start' : 'center', justifyContent: 'space-between', gap: 20, flexDirection: compact ? 'column' : 'row' }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          <div style={{ width: 46, height: 46, borderRadius: 14, flexShrink: 0, background: 'var(--bb-gradient-hero)', color: '#FFFFFF', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--bb-shadow-purple-sm)' }}>
            <BBIcon name="workspace_premium" size={24} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 16, fontWeight: 800, letterSpacing: '-0.01em', color: 'var(--bb-text-primary)' }}>BookBed Pro</span>
              <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--bb-tertiary-dark)', background: 'var(--bb-tertiary-tint)', padding: '2px 8px', borderRadius: 6 }}>Probni period</span>
            </div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', marginTop: 2 }}>Otključajte neograničen rast vašeg smještaja.</div>
          </div>
        </div>

        {/* benefits */}
        <div style={{ display: 'grid', gridTemplateColumns: compact ? '1fr 1fr' : 'repeat(4, auto)', gap: '8px 18px', marginBottom: 16 }}>
          {PFP_PRO_BENEFITS.map((b, i) => (
            <span key={i} style={{ display: 'inline-flex', alignItems: 'center', gap: 7, minWidth: 0 }}>
              <BBIcon name="check_circle" size={16} style={{ color: 'var(--bb-success)', flexShrink: 0 }} />
              <span className="bb-body" style={{ color: 'var(--bb-text-primary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.label}</span>
            </span>
          ))}
        </div>

        {/* trial progress */}
        <div style={{ maxWidth: compact ? '100%' : 360 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>Probni period</span>
            <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>12 od 14 dana</span>
          </div>
          <div style={{ height: 8, borderRadius: 999, background: 'rgba(107,76,230,0.12)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: '86%', borderRadius: 999, background: 'var(--bb-gradient-hero)' }} />
          </div>
        </div>
      </div>

      {/* CTA */}
      <div style={{ flexShrink: 0, textAlign: compact ? 'left' : 'right', width: compact ? '100%' : 'auto' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, justifyContent: compact ? 'flex-start' : 'flex-end', marginBottom: 10 }}>
          <span className="bb-tnum" style={{ fontSize: 30, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>€19</span>
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>/ mjesečno</span>
        </div>
        <BBButton variant="primary" iconRight="arrow_forward" fullWidth={compact}>Nadogradi na Pro</BBButton>
      </div>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Premium settings groups
// ──────────────────────────────────────────────────────────────
const PFP_GROUPS = [
  {
    id: 'racun', title: 'Račun', icon: 'manage_accounts',
    rows: [
      { id: 'edit-profile',  icon: 'badge',             label: 'Uredi profil',        sub: 'Ime, telefon, kontakt' },
      { id: 'password',      icon: 'lock_reset',        label: 'Promijeni lozinku',   sub: 'Promijenjena prije 47 dana' },
      { id: 'notifications', icon: 'notifications',     label: 'Postavke obavijesti', sub: 'Email i push' },
      { id: 'subscription',  icon: 'workspace_premium', label: 'Pretplata',           badge: 'Probni period' },
      { id: 'language',      icon: 'language',          label: 'Jezik',               value: 'Hrvatski' },
      { id: 'theme',         icon: 'palette',           label: 'Tema',                value: 'Sustavna' },
    ],
  },
  {
    id: 'aplikacija', title: 'Aplikacija', icon: 'apps',
    rows: [
      { id: 'help',  icon: 'help_outline', label: 'Pomoć i podrška', sub: 'FAQ · kontakt · vodič' },
      { id: 'about', icon: 'info',         label: 'O aplikaciji',    value: 'v3.4.1' },
    ],
  },
  {
    id: 'pravno', title: 'Pravno', icon: 'gavel',
    rows: [
      { id: 'terms',   icon: 'description',   label: 'Uvjeti korištenja' },
      { id: 'privacy', icon: 'verified_user', label: 'Pravila privatnosti' },
      { id: 'cookies', icon: 'cookie',        label: 'Politika kolačića' },
    ],
  },
  {
    id: 'opasno', title: 'Opasna zona', icon: 'warning', destructive: true,
    rows: [
      { id: 'delete', icon: 'delete_forever', label: 'Obriši račun', sub: 'Trajno briše sve podatke', destructive: true },
      { id: 'logout', icon: 'logout',         label: 'Odjava', destructive: true },
    ],
  },
];

const PFPSettingsRow = ({ row, divider }) => {
  const tintBg = row.destructive ? 'var(--bb-error-tint)' : 'var(--bb-surface-variant)';
  const tintFg = row.destructive ? 'var(--bb-error)' : 'var(--bb-text-secondary)';
  const labelColor = row.destructive ? 'var(--bb-error)' : 'var(--bb-text-primary)';
  return (
    <button type="button" className="bb-row-hover" style={{
      width: '100%', border: 'none', background: 'transparent', cursor: 'pointer',
      padding: '14px 20px', display: 'flex', alignItems: 'center', gap: 14,
      borderTop: divider ? '1px solid var(--bb-border-subtle)' : 'none', textAlign: 'left',
    }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: tintBg, color: tintFg, flexShrink: 0, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={row.icon} size={20} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: labelColor, fontWeight: 600 }}>{row.label}</div>
        {row.sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{row.sub}</div>}
      </div>
      {row.value && <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>{row.value}</span>}
      {row.badge && <BBStatusBadge status="pending" label={row.badge} dot={false} size="sm" />}
      <BBIcon name="chevron_right" size={20} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }} />
    </button>
  );
};

const PFPGroup = ({ group }) => (
  <div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '0 4px 10px' }}>
      <BBIcon name={group.icon} size={16} style={{ color: group.destructive ? 'var(--bb-error)' : 'var(--bb-text-tertiary)' }} />
      <h3 className="bb-eyebrow" style={{ margin: 0, color: group.destructive ? 'var(--bb-error)' : 'var(--bb-text-tertiary)' }}>{group.title}</h3>
    </div>
    <PFPCard pad={0} style={{ overflow: 'hidden', borderColor: group.destructive ? 'var(--bb-error-tint)' : 'var(--bb-border-subtle)' }}>
      {group.rows.map((row, i) => <PFPSettingsRow key={row.id} row={row} divider={i > 0} />)}
    </PFPCard>
  </div>
);

const { PV_SHELL_BG, PV_PANEL_BG, PV_PANEL_SHADOW, PV_PANEL_RADIUS, PV_TRANSPARENT_CHROME } = window;

// ──────────────────────────────────────────────────────────────
// PAGE — Desktop (1440, auto-height)
// ──────────────────────────────────────────────────────────────
const ProfilePremiumDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="profil" pendingCount={2} notifCount={6} style={PV_TRANSPARENT_CHROME} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Početna', 'Profil']} notifCount={6} actions={[{ icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
      <main style={{ padding: '4px 28px 28px', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 1040, maxWidth: '100%', display: 'flex', flexDirection: 'column', gap: 20, background: PV_PANEL_BG, borderRadius: PV_PANEL_RADIUS, border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW, padding: 28 }}>
          {/* Header */}
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
            <div>
              <PFPEyebrow style={{ color: 'var(--bb-primary)' }}>Račun · vlasnik</PFPEyebrow>
              <h1 style={{ margin: '6px 0 0', fontSize: 30, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Profil</h1>
            </div>
            <div style={{ display: 'flex', gap: 12 }}>
              <BBButton variant="secondary" iconLeft="visibility">Javni profil</BBButton>
              <BBButton variant="primary" iconLeft="edit">Uredi profil</BBButton>
            </div>
          </div>

          <PFPIdentity />

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
            {PFP_STATS.map((s, i) => <PFPStat key={i} s={s} />)}
          </div>

          <PFPProCard />

          {/* settings two-column */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, alignItems: 'start' }}>
            <PFPGroup group={PFP_GROUPS[0]} />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              <PFPGroup group={PFP_GROUPS[1]} />
              <PFPGroup group={PFP_GROUPS[2]} />
              <PFPGroup group={PFP_GROUPS[3]} />
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// PAGE — Tablet (768, rail, auto-height)
// ──────────────────────────────────────────────────────────────
function ProfilePremiumTablet() {
  return (
    <div className="theme-light bb-screen" style={{ width: 768, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebarRail active="profil" pendingCount={2} notifCount={6} style={PV_TRANSPARENT_CHROME} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar breadcrumb={['Početna', 'Profil']} notifCount={6} actions={[{ icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
        <div style={{ flex: 1, minWidth: 0, padding: '0 18px 18px 6px' }}>
        <main style={{ background: PV_PANEL_BG, borderRadius: 24, border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW, padding: '22px 24px 28px', display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
            <div>
              <PFPEyebrow style={{ color: 'var(--bb-primary)' }}>Račun · vlasnik</PFPEyebrow>
              <h1 style={{ margin: '6px 0 0', fontSize: 26, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Profil</h1>
            </div>
            <BBButton variant="primary" iconLeft="edit">Uredi profil</BBButton>
          </div>

          <PFPIdentity compact />
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
            {PFP_STATS.map((s, i) => <PFPStat key={i} s={s} compact />)}
          </div>
          <PFPProCard compact />
          <PFPGroup group={PFP_GROUPS[0]} />
          <PFPGroup group={PFP_GROUPS[1]} />
          <PFPGroup group={PFP_GROUPS[2]} />
          <PFPGroup group={PFP_GROUPS[3]} />
        </main>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// PAGE — Mobile (390, app bar, auto-height)
// ──────────────────────────────────────────────────────────────
function ProfilePremiumMobile() {
  return (
    <div className="theme-light bb-screen" style={{ width: 390, background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
      <BBAppBar title="Profil" showHamburger notifCount={6} actions={[{ icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
      <div style={{ padding: '0 12px 16px' }}>
      <main style={{ background: PV_PANEL_BG, borderRadius: 24, border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW, padding: '16px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <PFPEyebrow style={{ color: 'var(--bb-primary)' }}>Račun · vlasnik</PFPEyebrow>
          <h1 style={{ margin: '6px 0 0', fontSize: 24, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Profil</h1>
        </div>
        <PFPIdentity compact />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
          {PFP_STATS.map((s, i) => <PFPStat key={i} s={s} compact />)}
        </div>
        <PFPProCard compact />
        <PFPGroup group={PFP_GROUPS[0]} />
        <PFPGroup group={PFP_GROUPS[1]} />
        <PFPGroup group={PFP_GROUPS[2]} />
        <PFPGroup group={PFP_GROUPS[3]} />
      </main>
      </div>
    </div>
  );
}

Object.assign(window, { ProfilePremiumDesktop, ProfilePremiumTablet, ProfilePremiumMobile });
