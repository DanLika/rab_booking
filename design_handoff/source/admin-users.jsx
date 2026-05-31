/* eslint-disable */
// Admin users / Owners management — Prompt 33. Reuses AdminScaffold (active="owners") + AdmPlanTag from admin-shell.jsx.
// Desktop = master-detail (owners table + owner detail panel w/ actions). Tablet = table. Mobile-web = owner cards.

const AU_TABS = [
  { id: 'all', label: 'All', count: 248 },
  { id: 'active', label: 'Active', count: 210 },
  { id: 'trial', label: 'Trial', count: 26 },
  { id: 'suspended', label: 'Suspended', count: 12 },
];

const AU_OWNERS = [
  { name: 'Davor Kralj', email: 'd.kralj@adriahomes.hr', plan: 'Pro', props: 8, bookings: 142, gmv: '€48.2k', status: 'active', joined: '14.01.2024', last: '2h ago', phone: '+385 91 552 0188', city: 'Split' },
  { name: 'Tomislav Perić', email: 'tom@villaperic.hr', plan: 'Pro', props: 5, bookings: 96, gmv: '€31.0k', status: 'active', joined: '03.03.2024', last: '5h ago' },
  { name: 'Ivana Marić', email: 'ivana@apartmaniadria.hr', plan: 'Trial', props: 2, bookings: 14, gmv: '€3.8k', status: 'active', joined: '29.05.2026', last: '1h ago' },
  { name: 'Lana Babić', email: 'lana@lavandarentals.hr', plan: 'Trial', props: 3, bookings: 22, gmv: '€6.1k', status: 'active', joined: '25.05.2026', last: '1d ago' },
  { name: 'Maja Novak', email: 'maja.novak@gmail.com', plan: 'Free', props: 1, bookings: 4, gmv: '€0.9k', status: 'active', joined: '27.05.2026', last: '3d ago' },
  { name: 'Goran Šimić', email: 'goran@jadran-stay.hr', plan: 'Pro', props: 12, bookings: 210, gmv: '€72.4k', status: 'active', joined: '11.09.2023', last: '20m ago' },
  { name: 'Petra Vuković', email: 'petra.v@seaside.hr', plan: 'Free', props: 1, bookings: 0, gmv: '€0', status: 'suspended', joined: '02.02.2025', last: '41d ago' },
  { name: 'Ante Jurić', email: 'ante@kvarner-homes.hr', plan: 'Pro', props: 6, bookings: 118, gmv: '€39.7k', status: 'active', joined: '19.06.2024', last: '8h ago' },
];

const AU_STATUS = {
  active: { badge: 'confirmed', label: 'Active' },
  suspended: { badge: 'cancelled', label: 'Suspended' },
};

// ──────────────────────────────────────────────────────────────
// Toolbar
// ──────────────────────────────────────────────────────────────
const AUToolbar = ({ compact = false }) => (
  <div style={{ marginBottom: 16 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14, flexWrap: 'wrap' }}>
      <div style={{ flex: 1 }}>
        <h2 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Owners</h2>
        <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}><span className="bb-tnum">248</span> total accounts</p>
      </div>
      <BBButton variant="secondary" iconLeft="download" size={compact ? 'sm' : 'md'}>Export</BBButton>
      <BBButton variant="primary" iconLeft="person_add" size={compact ? 'sm' : 'md'}>Invite owner</BBButton>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
      {AU_TABS.map(t => (
        <BBChip key={t.id} selected={t.id === 'all'} count={t.count} size={compact ? 'sm' : 'md'}>{t.label}</BBChip>
      ))}
      <div style={{ flex: 1 }} />
      {!compact && <BBButton variant="secondary" iconLeft="tune" size="sm">Filters</BBButton>}
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Table
// ──────────────────────────────────────────────────────────────
const AUTable = ({ rows, selectedName, master = false }) => {
  const cols = master ? '2fr 0.8fr 0.8fr 1fr 36px' : '2.2fr 0.8fr 0.9fr 1fr 1.1fr 1fr 36px';
  return (
    <BBCard padded={false} style={{ overflow: 'hidden' }}>
      <div style={{ display: 'grid', gridTemplateColumns: cols, gap: 12, padding: '10px 18px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        {(master ? ['Owner', 'Plan', 'Props', 'Status', ''] : ['Owner', 'Plan', 'Props', 'Bookings', 'Status', 'Last active', '']).map((h, i) => (
          <span key={i} className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{h}</span>
        ))}
      </div>
      {rows.map((r, i) => {
        const sel = r.name === selectedName;
        const st = AU_STATUS[r.status];
        return (
          <div key={i} style={{ display: 'grid', gridTemplateColumns: cols, gap: 12, alignItems: 'center', padding: '11px 18px', borderBottom: i < rows.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none', background: sel ? 'var(--bb-primary-tint-bg)' : 'transparent', cursor: 'pointer', borderLeft: sel ? '3px solid var(--bb-primary)' : '3px solid transparent' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
              <BBAvatar name={r.name} size="sm" />
              <div style={{ minWidth: 0 }}>
                <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.email}</div>
              </div>
            </div>
            <span><AdmPlanTag plan={r.plan} /></span>
            <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-secondary)' }}>{r.props}</span>
            {!master && <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-secondary)' }}>{r.bookings}</span>}
            <BBStatusBadge status={st.badge} label={st.label} size="sm" />
            {!master && <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{r.last}</span>}
            <BBButton variant="tertiary" asIcon size="sm" iconLeft="more_vert" ariaLabel="Actions" />
          </div>
        );
      })}
    </BBCard>
  );
};

const AUPagination = ({ shown = 8 }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 14 }}>
    <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Showing <span className="bb-tnum">1–{shown}</span> of <span className="bb-tnum">248</span></span>
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prev" />
      {['1', '2', '3', '…', '25'].map((p, i) => (
        <button key={i} type="button" style={{ minWidth: 32, height: 32, borderRadius: 8, border: '1px solid ' + (p === '1' ? 'var(--bb-primary)' : 'var(--bb-border)'), background: p === '1' ? 'var(--bb-primary)' : 'var(--bb-surface)', color: p === '1' ? '#FFFFFF' : 'var(--bb-text-secondary)', fontWeight: 600, fontSize: 13, cursor: 'pointer', fontVariantNumeric: 'tabular-nums' }}>{p}</button>
      ))}
      <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Next" />
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Owner detail panel (master-detail)
// ──────────────────────────────────────────────────────────────
const AUOwnerPanel = ({ o }) => (
  <BBCard padded={false} style={{ display: 'flex', flexDirection: 'column', height: '100%', overflow: 'hidden' }}>
    <div style={{ padding: 20, borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
        <BBAvatar name={o.name} size="lg" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-h3" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{o.name}</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{o.email}</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
            <AdmPlanTag plan={o.plan} />
            <BBStatusBadge status={AU_STATUS[o.status].badge} label={AU_STATUS[o.status].label} size="sm" />
          </div>
        </div>
        <BBButton variant="tertiary" asIcon size="sm" iconLeft="close" ariaLabel="Close" />
      </div>
    </div>
    {/* stats */}
    <div style={{ padding: 20, borderBottom: '1px solid var(--bb-border-subtle)', display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
      <AUStat label="Properties" value={String(o.props)} />
      <AUStat label="Bookings (all)" value={String(o.bookings)} />
      <AUStat label="GMV (lifetime)" value={o.gmv} />
      <AUStat label="Member since" value="Jan 2024" />
    </div>
    {/* contact */}
    <div style={{ padding: 20, borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <KeyValueRow label="Phone" value={o.phone || '—'} />
      <KeyValueRow label="Location" value={o.city || '—'} />
      <KeyValueRow label="Last active" value={o.last} last />
    </div>
    {/* actions */}
    <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <BBButton variant="primary" iconLeft="visibility" fullWidth>View as owner</BBButton>
      <div style={{ display: 'flex', gap: 8 }}>
        <BBButton variant="secondary" iconLeft="mail" style={{ flex: 1 }} size="sm">Message</BBButton>
        <BBButton variant="secondary" iconLeft="lock_reset" style={{ flex: 1 }} size="sm">Reset password</BBButton>
      </div>
      <BBButton variant="destructive-soft" iconLeft="block" fullWidth size="sm">Suspend account</BBButton>
    </div>
  </BBCard>
);

const AUStat = ({ label, value }) => (
  <div style={{ padding: '10px 12px', background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)' }}>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{label}</div>
    <div className="bb-tnum" style={{ fontSize: 18, fontWeight: 800, color: 'var(--bb-text-primary)', marginTop: 2 }}>{value}</div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Mobile owner cards
// ──────────────────────────────────────────────────────────────
const AUMobileCard = ({ o }) => (
  <BBCard padded={false}>
    <div style={{ padding: 14 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
        <BBAvatar name={o.name} size="sm" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{o.name}</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{o.email}</div>
        </div>
        <BBStatusBadge status={AU_STATUS[o.status].badge} label={AU_STATUS[o.status].label} size="sm" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <AdmPlanTag plan={o.plan} />
        <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-secondary)' }}>{o.props} props · {o.bookings} bookings</span>
        <div style={{ flex: 1 }} />
        <BBIcon name="chevron_right" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
      </div>
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const AdminUsersDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="owners" title="Owners">
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: 20, alignItems: 'start', height: '100%' }}>
      <div style={{ minWidth: 0 }}>
        <AUToolbar />
        <AUTable rows={AU_OWNERS} selectedName="Davor Kralj" master />
        <AUPagination />
      </div>
      <div style={{ height: '100%', maxHeight: '100%' }}>
        <AUOwnerPanel o={AU_OWNERS[0]} />
      </div>
    </div>
  </AdminScaffold>
);

const AdminUsersTablet = () => (
  <AdminScaffold breakpoint="tablet" active="owners" title="Owners">
    <AUToolbar compact />
    <AUTable rows={AU_OWNERS.slice(0, 6)} />
    <AUPagination shown={6} />
  </AdminScaffold>
);

const AdminUsersMobile = () => (
  <AdminScaffold breakpoint="mobile" active="owners" title="Owners">
    <div style={{ marginBottom: 12 }}>
      <BBInput placeholder="Search owners…" iconLeft="search" size="sm" />
    </div>
    <div style={{ display: 'flex', gap: 8, marginBottom: 12, flexWrap: 'wrap' }}>
      {AU_TABS.slice(0, 3).map(t => <BBChip key={t.id} selected={t.id === 'all'} count={t.count} size="sm">{t.label}</BBChip>)}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {AU_OWNERS.slice(0, 5).map((o, i) => <AUMobileCard key={i} o={o} />)}
    </div>
  </AdminScaffold>
);

Object.assign(window, { AdminUsersDesktop, AdminUsersTablet, AdminUsersMobile });
