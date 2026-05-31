/* eslint-disable */
// Admin shell + dashboard — Prompt 32. Internal staff console (English). Distinct chrome from the owner app:
// DARK console sidebar (vs owner's white + purple-gradient), admin topbar with global search + env badge.
// Exposes AdminScaffold + AdminNav for reuse by Admin Users (Prompt 33).

const ADM_NAV = [
  { id: 'overview', icon: 'space_dashboard', label: 'Overview' },
  { id: 'analytics', icon: 'insights', label: 'Analytics' },
  { id: 'owners', icon: 'group', label: 'Owners' },
  { id: 'properties', icon: 'apartment', label: 'Properties' },
  { id: 'bookings', icon: 'receipt_long', label: 'Bookings' },
  { id: 'payments', icon: 'payments', label: 'Payments' },
  { id: 'sync', icon: 'sync', label: 'Sync health', badge: 14 },
  { id: 'support', icon: 'support_agent', label: 'Support', badge: 3 },
  { id: 'settings', icon: 'settings', label: 'Settings' },
];

const ADM_SB_BG = '#1E1A33';
const ADM_SB_TXT = 'rgba(255,255,255,0.72)';
const ADM_SB_BORDER = 'rgba(255,255,255,0.08)';

// ──────────────────────────────────────────────────────────────
// Sidebar (full) + Rail (icons)
// ──────────────────────────────────────────────────────────────
const AdminNavItem = ({ item, active, rail = false }) => {
  const on = item.id === active;
  if (rail) {
    return (
      <button type="button" title={item.label} className={on ? '' : 'adm-nav'} style={{
        position: 'relative', width: 48, height: 48, border: 'none', cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 12,
        background: on ? 'var(--bb-gradient-hero)' : 'rgba(255,255,255,0.05)',
        color: on ? '#FFFFFF' : ADM_SB_TXT,
        boxShadow: on ? '0 6px 14px rgba(139,111,255,0.40)' : 'none',
      }}>
        <BBIcon name={item.icon} size={22} fill={on ? 1 : 0} />
        {item.badge && <span style={{ position: 'absolute', top: 7, right: 9, width: 7, height: 7, borderRadius: '50%', background: item.id === 'sync' ? 'var(--bb-tertiary)' : 'var(--bb-error)' }} />}
      </button>
    );
  }
  return (
    <button type="button" title={item.label} className={on ? '' : 'adm-nav'} style={{
      width: '100%', cursor: 'pointer',
      display: 'flex', alignItems: 'center', gap: 11, height: 44, padding: '0 10px', borderRadius: 12,
      border: '1px solid', borderColor: on ? 'rgba(255,255,255,0.10)' : 'transparent',
      background: on ? 'rgba(255,255,255,0.08)' : 'transparent',
      color: on ? '#FFFFFF' : ADM_SB_TXT,
      fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: on ? 600 : 500,
      position: 'relative',
    }}>
      <span style={{
        width: 28, height: 28, flexShrink: 0, borderRadius: 9,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        background: on ? 'var(--bb-gradient-hero)' : 'rgba(255,255,255,0.06)',
        color: '#FFFFFF', boxShadow: on ? '0 4px 12px rgba(139,111,255,0.40)' : 'none',
      }}>
        <BBIcon name={item.icon} size={18} fill={on ? 1 : 0} />
      </span>
      <span style={{ flex: 1, textAlign: 'left' }}>{item.label}</span>
      {item.badge && (
        <span style={{ minWidth: 20, height: 20, padding: '0 6px', borderRadius: 999, background: item.id === 'sync' ? 'var(--bb-tertiary)' : 'var(--bb-error)', color: '#FFFFFF', fontSize: 11, fontWeight: 700, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontVariantNumeric: 'tabular-nums' }}>{item.badge}</span>
      )}
    </button>
  );
};

const ADM_GROUPS = [
  { label: 'Platform', ids: ['overview', 'analytics', 'owners', 'properties', 'bookings'] },
  { label: 'Operations', ids: ['payments', 'sync', 'support'] },
  { label: 'System', ids: ['settings'] },
];
const AdmNavLabel = ({ children }) => (
  <div style={{ padding: '14px 12px 6px', fontSize: 10.5, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'rgba(255,255,255,0.40)' }}>{children}</div>
);

const AdminSidebar = ({ active }) => (
  <aside style={{ width: 240, flexShrink: 0, background: ADM_SB_BG, display: 'flex', flexDirection: 'column' }}>
    <div style={{ padding: '18px 18px 14px', display: 'flex', alignItems: 'center', gap: 10, borderBottom: `1px solid ${ADM_SB_BORDER}` }}>
      <BBLogo size={28} />
      <span style={{ fontSize: 16, fontWeight: 700, color: '#FFFFFF', letterSpacing: '-0.02em', flex: 1 }}>BookBed</span>
      <span style={{ background: 'rgba(139,111,255,0.28)', color: '#C9BBFF', fontSize: 9, fontWeight: 800, letterSpacing: '0.1em', padding: '3px 7px', borderRadius: 5 }}>ADMIN</span>
    </div>
    <nav style={{ flex: 1, padding: '6px 10px 12px', display: 'flex', flexDirection: 'column', gap: 2, overflowY: 'auto' }}>
      {ADM_GROUPS.map((g, gi) => (
        <div key={gi}>
          <AdmNavLabel>{g.label}</AdmNavLabel>
          {g.ids.map(id => <AdminNavItem key={id} item={ADM_NAV.find(n => n.id === id)} active={active} />)}
        </div>
      ))}
    </nav>
    <div style={{ padding: 12, borderTop: `1px solid ${ADM_SB_BORDER}` }}>
      <div className="adm-nav" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px', borderRadius: 12, cursor: 'pointer' }}>
        <BBAvatar name="Petra Knežević" size="sm" tone="on-gradient" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: '#FFFFFF', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Petra Knežević</div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)' }}>Administrator</div>
        </div>
        <BBIcon name="logout" size={18} style={{ color: 'rgba(255,255,255,0.5)' }} />
      </div>
    </div>
  </aside>
);

const AdminRail = ({ active }) => (
  <aside style={{ width: 64, flexShrink: 0, background: ADM_SB_BG, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '14px 0', gap: 6 }}>
    <div style={{ marginBottom: 10 }}><BBLogo size={28} /></div>
    <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4, width: 48 }}>
      {ADM_NAV.map(it => <AdminNavItem key={it.id} item={it} active={active} rail />)}
    </nav>
    <BBAvatar name="Petra Knežević" size="sm" tone="on-gradient" />
  </aside>
);

// ──────────────────────────────────────────────────────────────
// Topbar
// ──────────────────────────────────────────────────────────────
const AdminTopbar = ({ title, breakpoint }) => (
  <header style={{ height: 60, flexShrink: 0, background: 'var(--bb-surface)', borderBottom: '1px solid var(--bb-border-subtle)', display: 'flex', alignItems: 'center', gap: 16, padding: '0 24px' }}>
    {breakpoint === 'mobile' && <BBButton variant="tertiary" asIcon size="md" iconLeft="menu" ariaLabel="Menu" />}
    <h1 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h1>
    {breakpoint !== 'mobile' && (
      <div style={{ flex: 1, maxWidth: 420, marginLeft: 12 }}>
        <BBInput placeholder="Search owners, bookings, properties…" iconLeft="search" size="sm" />
      </div>
    )}
    <div style={{ flex: 1 }} />
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '5px 10px', background: 'var(--bb-success-tint)', borderRadius: 999 }}>
      <span style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--bb-success)' }} />
      <span className="bb-caption" style={{ color: 'var(--bb-success)', fontWeight: 700 }}>Production</span>
    </div>
    <button type="button" aria-label="Notifications" style={{ position: 'relative', width: 40, height: 40, border: 'none', borderRadius: 'var(--bb-radius-sm)', background: 'transparent', color: 'var(--bb-text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <BBIcon name="notifications" size={20} />
      <span style={{ position: 'absolute', top: 7, right: 7, width: 8, height: 8, borderRadius: '50%', background: 'var(--bb-error)', border: '2px solid var(--bb-surface)' }} />
    </button>
    {breakpoint !== 'mobile' && <BBAvatar name="Petra Knežević" size="sm" />}
  </header>
);

// ──────────────────────────────────────────────────────────────
// Scaffold (exposed for reuse)
// ──────────────────────────────────────────────────────────────
const AdminScaffold = ({ breakpoint, active, title, children }) => {
  const dims = { desktop: [1440, 1100], tablet: [768, 1024], mobile: [390, 880] }[breakpoint];
  return (
    <div className="theme-light bb-screen" style={{ width: dims[0], height: dims[1], display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
      {breakpoint === 'desktop' && <AdminSidebar active={active} />}
      {breakpoint === 'tablet' && <AdminRail active={active} />}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <AdminTopbar title={title} breakpoint={breakpoint} />
        <main style={{ flex: 1, overflow: 'hidden', padding: breakpoint === 'mobile' ? '16px' : '24px 28px' }}>{children}</main>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Dashboard pieces
// ──────────────────────────────────────────────────────────────
const ADM_KPIS = [
  { icon: 'group', label: 'Owners', value: '248', delta: '+12', sub: 'this month', color: 'var(--bb-primary)' },
  { icon: 'apartment', label: 'Properties', value: '612', delta: '+28', sub: 'active listings', color: 'var(--bb-info)' },
  { icon: 'receipt_long', label: 'Bookings · 30d', value: '3.420', delta: '+8,4%', sub: 'vs prev 30d', color: 'var(--bb-success)' },
  { icon: 'payments', label: 'GMV · 30d', value: '€1,24M', delta: '+11%', sub: 'gross booking value', color: 'var(--bb-tertiary-dark)' },
];
const AdmKpi = ({ k, compact = false }) => (
  <BBCard style={compact ? { padding: 14 } : {}}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: `color-mix(in srgb, ${k.color || 'var(--bb-primary)'} 14%, transparent)`, color: k.color || 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={k.icon} size={20} />
      </div>
      <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--bb-success)', background: 'var(--bb-success-tint)', padding: '3px 8px', borderRadius: 6 }}>{k.delta}</span>
    </div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, fontSize: 10 }}>{k.label}</div>
    <div className="bb-tnum" style={{ fontSize: compact ? 24 : 30, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 2 }}>{k.value}</div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{k.sub}</div>
  </BBCard>
);

const ADM_BARS = [62, 74, 58, 81, 69, 88, 76, 94, 85, 102, 96, 118];
const ADM_BAR_LABELS = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
const AdmBarChart = ({ height = 150 }) => {
  const max = Math.max(...ADM_BARS);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height }}>
      {ADM_BARS.map((v, i) => {
        const last = i === ADM_BARS.length - 1;
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{ width: '100%', height: (v / max) * (height - 22), background: last ? 'var(--bb-gradient-primary)' : 'var(--bb-primary-tint-bg)', border: last ? 'none' : '1px solid rgba(107,76,230,0.18)', borderRadius: '6px 6px 0 0' }} />
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontSize: 10, fontWeight: 600 }}>{ADM_BAR_LABELS[i]}</span>
          </div>
        );
      })}
    </div>
  );
};

const ADM_SYNC = [
  { name: 'Booking.com', pct: 99.2, tone: 'success' },
  { name: 'Airbnb', pct: 97.8, tone: 'success' },
  { name: 'Direct widget', pct: 100, tone: 'success' },
  { name: 'Custom iCal', pct: 94.1, tone: 'warning' },
];
const AdmSyncHealth = () => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Sync health</h3>
      <span className="bb-caption" style={{ color: 'var(--bb-error)', fontWeight: 600 }}>14 feeds with errors</span>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      {ADM_SYNC.map((s, i) => {
        const fg = s.tone === 'success' ? 'var(--bb-success)' : 'var(--bb-tertiary-dark)';
        return (
          <div key={i}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span className="bb-label" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{s.name}</span>
              <span className="bb-caption bb-tnum" style={{ color: fg, fontWeight: 700 }}>{String(s.pct).replace('.', ',')}%</span>
            </div>
            <div style={{ height: 6, borderRadius: 999, background: 'var(--bb-surface-variant)', overflow: 'hidden' }}>
              <div style={{ height: '100%', width: `${s.pct}%`, background: fg, borderRadius: 999 }} />
            </div>
          </div>
        );
      })}
    </div>
  </BBCard>
);

const ADM_SIGNUPS = [
  { name: 'Ivana Marić', email: 'ivana@apartmaniadria.hr', plan: 'Trial', props: 2, joined: '29.05.', status: 'active' },
  { name: 'Tomislav Perić', email: 'tom@villaperic.hr', plan: 'Pro', props: 5, joined: '28.05.', status: 'active' },
  { name: 'Maja Novak', email: 'maja.novak@gmail.com', plan: 'Free', props: 1, joined: '27.05.', status: 'pending' },
  { name: 'Davor Kralj', email: 'd.kralj@adriahomes.hr', plan: 'Pro', props: 8, joined: '26.05.', status: 'active' },
  { name: 'Lana Babić', email: 'lana@lavandarentals.hr', plan: 'Trial', props: 3, joined: '25.05.', status: 'active' },
];
const AdmPlanTag = ({ plan }) => {
  const m = { Pro: { bg: 'var(--bb-primary-tint-bg)', fg: 'var(--bb-primary)' }, Trial: { bg: 'var(--bb-tertiary-tint)', fg: 'var(--bb-tertiary-dark)' }, Free: { bg: 'var(--bb-surface-variant)', fg: 'var(--bb-text-secondary)' } }[plan];
  return <span style={{ background: m.bg, color: m.fg, fontSize: 11, fontWeight: 700, padding: '3px 9px', borderRadius: 999 }}>{plan}</span>;
};
const AdmSignups = ({ rows, compact = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: '16px 20px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Recent owner signups</h3>
      <BBButton variant="tertiary" size="sm" iconRight="arrow_forward">View all</BBButton>
    </div>
    {/* header */}
    {!compact && (
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr 1fr 1fr', gap: 12, padding: '8px 20px', background: 'var(--bb-surface-variant)', borderTop: '1px solid var(--bb-border-subtle)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        {['Owner', 'Plan', 'Properties', 'Joined', 'Status'].map(h => <span key={h} className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{h}</span>)}
      </div>
    )}
    {rows.map((r, i) => (
      <div key={i} style={{ display: 'grid', gridTemplateColumns: compact ? '1fr auto' : '2fr 1fr 1fr 1fr 1fr', gap: 12, alignItems: 'center', padding: compact ? '12px 16px' : '12px 20px', borderBottom: i < rows.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
          <BBAvatar name={r.name} size="sm" />
          <div style={{ minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.email}</div>
          </div>
        </div>
        {compact ? (
          <AdmPlanTag plan={r.plan} />
        ) : (
          <>
            <span><AdmPlanTag plan={r.plan} /></span>
            <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-secondary)' }}>{r.props}</span>
            <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-secondary)' }}>{r.joined}</span>
            <BBStatusBadge status={r.status === 'active' ? 'confirmed' : 'pending'} label={r.status === 'active' ? 'Active' : 'Pending'} size="sm" />
          </>
        )}
      </div>
    ))}
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Dashboard body + pages
// ──────────────────────────────────────────────────────────────
// Bookings volume — real area/line trend (current vs previous 12 months)
const ADM_TREND_NOW  = [62, 74, 58, 81, 69, 88, 76, 94, 85, 102, 96, 118];
const ADM_TREND_PREV = [44, 52, 47, 60, 55, 64, 58, 71, 66, 78, 73, 86];
const ADM_TREND_LABELS = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
const AdmChartCard = () => {
  const series = [
    { data: ADM_TREND_NOW, color: 'var(--bb-primary)', area: true, label: 'This year' },
    { data: ADM_TREND_PREV, color: 'var(--bb-text-tertiary)', dashed: true, label: 'Previous year' },
  ];
  return (
    <BBCard>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 8 }}>
        <div>
          <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Bookings volume</h3>
          <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>Last 12 months · platform-wide</p>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <BBChip size="sm" selected>Bookings</BBChip>
          <BBChip size="sm">GMV</BBChip>
        </div>
      </div>
      <AdmTrend series={series} labels={ADM_TREND_LABELS} height={190} yFmt={(v) => Math.round(v)} />
      <AdmLegend items={series} style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid var(--bb-border-subtle)' }} />
    </BBCard>
  );
};

const AdminDashboardDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="overview" title="Overview">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
      {ADM_KPIS.map((k, i) => <AdmKpi key={i} k={k} />)}
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1.6fr 1fr', gap: 16, marginBottom: 16 }}>
      <AdmChartCard />
      <AdmSyncHealth />
    </div>
    <AdmSignups rows={ADM_SIGNUPS} />
  </AdminScaffold>
);

const AdminDashboardTablet = () => (
  <AdminScaffold breakpoint="tablet" active="overview" title="Overview">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, marginBottom: 14 }}>
      {ADM_KPIS.map((k, i) => <AdmKpi key={i} k={k} compact />)}
    </div>
    <div style={{ marginBottom: 14 }}><AdmChartCard /></div>
    <AdmSyncHealth />
  </AdminScaffold>
);

const AdminDashboardMobile = () => (
  <AdminScaffold breakpoint="mobile" active="overview" title="Overview">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12, marginBottom: 12 }}>
      {ADM_KPIS.map((k, i) => <AdmKpi key={i} k={k} compact />)}
    </div>
    <div style={{ marginBottom: 12 }}><AdmSyncHealth /></div>
  </AdminScaffold>
);

Object.assign(window, {
  AdminScaffold, AdminSidebar, AdminRail, AdminTopbar,
  AdminDashboardDesktop, AdminDashboardTablet, AdminDashboardMobile,
});
