/* eslint-disable */
// Admin Sync health — platform-wide channel-feed monitoring. Fills the admin nav "Sync health" gap.
// Reuses AdminScaffold (active="sync") + BBCard/BBChip/BBButton/BBAvatar/BBIcon. English, dark console.
// Fixed scaffold heights — content sized to fit (overflow:hidden). Real OTA logos from assets/.

const ASY_STATS = [
  { icon: 'rss_feed',     label: 'Active feeds',     value: '1.842', delta: '+34', tone: 'success', sub: 'across 612 properties', color: 'var(--bb-info)' },
  { icon: 'check_circle', label: 'Healthy',          value: '98,6%', delta: '+0,3%', tone: 'success', sub: '1.816 of 1.842', color: 'var(--bb-success)' },
  { icon: 'sync_problem', label: 'Feeds with errors', value: '14', delta: '+5', tone: 'error', sub: '3 critical · 11 degraded', color: 'var(--bb-error)' },
  { icon: 'bolt',         label: 'Avg sync latency', value: '2,4s', delta: '−0,4s', tone: 'success', sub: 'p95 · last 24h', color: 'var(--bb-tertiary-dark)' },
];

// status → tokens
const ASY_STATUS = {
  healthy:  { label: 'Healthy',  fg: 'var(--bb-success)',       bg: 'var(--bb-success-tint)',   dot: '#2E7D5B' },
  syncing:  { label: 'Syncing',  fg: 'var(--bb-info)',          bg: 'var(--bb-info-tint)',      dot: '#4A90D9' },
  degraded: { label: 'Degraded', fg: 'var(--bb-tertiary-dark)', bg: 'var(--bb-tertiary-tint)',  dot: '#FFB84D' },
  error:    { label: 'Error',    fg: 'var(--bb-error)',         bg: 'var(--bb-error-tint)',     dot: '#FF6B6B' },
};
const ASYStatus = ({ status, size = 'md' }) => {
  const s = ASY_STATUS[status] || ASY_STATUS.healthy;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, height: size === 'sm' ? 22 : 26, padding: '0 10px', borderRadius: 999, background: s.bg, color: s.fg, fontSize: 12, fontWeight: 600 }}>
      {status === 'syncing'
        ? <BBIcon name="sync" size={13} style={{ animation: 'bb-spin 1s linear infinite' }} />
        : <span style={{ width: 6, height: 6, borderRadius: '50%', background: s.dot }} />}
      {s.label}
    </span>
  );
};

// channel branding
const ASY_CHANNELS = [
  { id: 'booking', name: 'Booking.com',  logo: 'assets/booking.png', uptime: '99,2%', pct: 99.2, feeds: 642, errors: 4, status: 'healthy' },
  { id: 'airbnb',  name: 'Airbnb',       logo: 'assets/airbnb.png',  uptime: '97,8%', pct: 97.8, feeds: 511, errors: 2, status: 'healthy' },
  { id: 'widget',  name: 'Direct widget', icon: 'bolt',              uptime: '100%',  pct: 100,  feeds: 488, errors: 0, status: 'healthy' },
  { id: 'ical',    name: 'Custom iCal',  icon: 'event',              uptime: '94,1%', pct: 94.1, feeds: 201, errors: 8, status: 'degraded' },
];

const ASYChannelLogo = ({ ch, size = 32 }) => (
  ch.logo
    ? <img src={ch.logo} width={size} height={size} alt={ch.name} style={{ borderRadius: 8, objectFit: 'cover', flexShrink: 0 }} />
    : <span style={{ width: size, height: size, borderRadius: 8, background: ch.id === 'widget' ? 'var(--bb-tertiary-tint)' : 'var(--bb-info-tint)', color: ch.id === 'widget' ? 'var(--bb-tertiary-dark)' : 'var(--bb-info)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><BBIcon name={ch.icon} size={Math.round(size * 0.56)} /></span>
);

const ASYChannelCard = ({ ch, compact = false }) => {
  const st = ASY_STATUS[ch.status];
  return (
    <BBCard style={compact ? { padding: 16 } : {}}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
        <ASYChannelLogo ch={ch} size={32} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{ch.name}</div>
          <div className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{ch.feeds} feeds</div>
        </div>
        <span style={{ width: 8, height: 8, borderRadius: '50%', background: st.dot }} />
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
        <span className="bb-tnum" style={{ fontSize: 24, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>{ch.uptime}</span>
        {ch.errors > 0
          ? <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-error)', fontWeight: 700 }}>{ch.errors} errors</span>
          : <span className="bb-caption" style={{ color: 'var(--bb-success)', fontWeight: 700 }}>All OK</span>}
      </div>
      <div style={{ height: 6, borderRadius: 999, background: 'var(--bb-surface-variant)', overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${ch.pct}%`, borderRadius: 999, background: st.fg }} />
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 8 }}>Uptime · 30 days</div>
    </BBCard>
  );
};

// feeds
const ASY_FEEDS = [
  { property: 'Vila Marina · Studio 4',     owner: 'Davor Kralj',     ch: 'booking', last: '2 min ago',  next: 'in 13 min', latency: '1,8s', status: 'healthy' },
  { property: 'Adria Homes · Penthouse',    owner: 'Davor Kralj',     ch: 'widget',  last: '12 sec ago', next: 'realtime',  latency: '0,3s', status: 'healthy' },
  { property: 'Jadran Stay · Loft',         owner: 'Goran Šimić',     ch: 'ical',    last: '3 h ago',    next: 'overdue',   latency: '—',    status: 'error', msg: 'Feed returned HTTP 404 — URL unreachable' },
  { property: 'Kvarner Homes · A2',         owner: 'Ante Jurić',      ch: 'booking', last: 'now',        next: '—',         latency: '—',    status: 'syncing' },
  { property: 'Villa Perić · Suite',        owner: 'Tomislav Perić',  ch: 'ical',    last: '41 min ago', next: 'in 19 min', latency: '8,7s', status: 'degraded', msg: 'High latency — feed responding slowly' },
  { property: 'Lavanda Rentals · Studio B', owner: 'Lana Babić',      ch: 'airbnb',  last: '1 h ago',    next: 'retry queued', latency: '—', status: 'error', msg: 'OAuth token expired — owner re-auth required' },
];
const ASY_CH_BY_ID = Object.fromEntries(ASY_CHANNELS.map(c => [c.id, c]));

const ASY_TABS = [
  { id: 'all', label: 'All feeds', count: '1.842' },
  { id: 'healthy', label: 'Healthy', dot: '#2E7D5B' },
  { id: 'syncing', label: 'Syncing', dot: '#4A90D9' },
  { id: 'degraded', label: 'Degraded', dot: '#FFB84D', count: 11 },
  { id: 'error', label: 'Error', dot: '#FF6B6B', count: 3 },
];

const ASYStat = ({ s, compact = false }) => {
  const dc = s.tone === 'success' ? 'var(--bb-success)' : s.tone === 'error' ? 'var(--bb-error)' : 'var(--bb-text-tertiary)';
  const db = s.tone === 'success' ? 'var(--bb-success-tint)' : s.tone === 'error' ? 'var(--bb-error-tint)' : 'var(--bb-surface-variant)';
  return (
    <BBCard style={compact ? { padding: 14 } : {}}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ width: 34, height: 34, borderRadius: 10, background: `color-mix(in srgb, ${s.color || 'var(--bb-primary)'} 14%, transparent)`, color: s.color || 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name={s.icon} size={18} />
        </div>
        {s.delta && <span className="bb-tnum" style={{ fontSize: 12, fontWeight: 700, color: dc, background: db, padding: '3px 8px', borderRadius: 6 }}>{s.delta}</span>}
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{s.label}</div>
      <div className="bb-tnum" style={{ fontSize: compact ? 22 : 26, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 2 }}>{s.value}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{s.sub}</div>
    </BBCard>
  );
};

// alert banner
const ASYAlert = ({ compact = false }) => (
  <div style={{
    display: 'flex', alignItems: compact ? 'flex-start' : 'center', gap: 16,
    padding: compact ? 14 : '14px 20px', borderRadius: 'var(--bb-radius-md)',
    background: 'var(--bb-error-tint)', border: '1px solid rgba(255,107,107,0.28)',
    flexDirection: compact ? 'column' : 'row',
  }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 14, width: '100%' }}>
      <div style={{ width: 40, height: 40, borderRadius: 11, background: 'var(--bb-error)', color: '#FFFFFF', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <BBIcon name="warning" size={22} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>
          <span className="bb-tnum">14</span> feeds reporting sync errors
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>3 critical · 11 degraded · oldest unresolved 3h ago</div>
      </div>
    </div>
    <div style={{ display: 'flex', gap: 8, flexShrink: 0, width: compact ? '100%' : 'auto' }}>
      <BBButton variant="secondary" size="sm" iconLeft="refresh" style={compact ? { flex: 1 } : {}}>Retry all</BBButton>
      <BBButton variant="destructive" size="sm" iconRight="arrow_forward" style={compact ? { flex: 1 } : {}}>View errors</BBButton>
    </div>
  </div>
);

// feeds table
const ASY_COLS = '1.9fr 1fr 1fr 0.9fr 0.6fr 1fr 36px';
const ASY_HEADS = ['Feed · owner', 'Channel', 'Last sync', 'Next sync', 'Latency', 'Status', ''];
const ASYTable = ({ feeds = ASY_FEEDS }) => (
  <BBCard padded={false} style={{ overflow: 'hidden' }}>
    <div style={{ display: 'grid', gridTemplateColumns: ASY_COLS, gap: 12, padding: '10px 18px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      {ASY_HEADS.map((h, i) => <span key={i} className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700, textAlign: i === 4 ? 'right' : 'left' }}>{h}</span>)}
    </div>
    {feeds.map((f, i) => {
      const ch = ASY_CH_BY_ID[f.ch];
      const bad = f.status === 'error';
      return (
        <div key={i} className="bb-row-hover" style={{ display: 'grid', gridTemplateColumns: ASY_COLS, gap: 12, alignItems: 'center', padding: '10px 18px', borderBottom: i < feeds.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none', background: bad ? 'rgba(255,107,107,0.05)' : 'transparent' }}>
          <div style={{ minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontSize: 13 }}>{f.property}</div>
            {f.msg
              ? <div className="bb-caption" style={{ color: f.status === 'error' ? 'var(--bb-error)' : 'var(--bb-tertiary-dark)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.msg}</div>
              : <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{f.owner}</div>}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
            <ASYChannelLogo ch={ch} size={22} />
            <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{ch.name}</span>
          </div>
          <span className="bb-caption bb-tnum" style={{ color: bad ? 'var(--bb-error)' : 'var(--bb-text-secondary)' }}>{f.last}</span>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{f.next}</span>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-secondary)', textAlign: 'right' }}>{f.latency}</span>
          <span><ASYStatus status={f.status} size="sm" /></span>
          {f.status === 'error' || f.status === 'degraded'
            ? <BBButton variant="tertiary" asIcon size="sm" iconLeft="refresh" ariaLabel="Retry" />
            : <BBButton variant="tertiary" asIcon size="sm" iconLeft="more_vert" ariaLabel="Actions" />}
        </div>
      );
    })}
  </BBCard>
);

const ASYToolbar = () => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '16px 0 14px', flexWrap: 'wrap' }}>
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', flex: 1 }}>
      {ASY_TABS.map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count}>{t.label}</BBChip>)}
    </div>
    <BBButton variant="secondary" iconLeft="refresh" size="sm">Sync all now</BBButton>
  </div>
);

// mobile feed card
const ASYFeedCard = ({ f }) => {
  const ch = ASY_CH_BY_ID[f.ch];
  const bad = f.status === 'error';
  return (
    <BBCard padded={false} style={bad ? { borderColor: 'rgba(255,107,107,0.35)' } : {}}>
      <div style={{ padding: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <ASYChannelLogo ch={ch} size={28} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.property}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{ch.name} · {f.last}</div>
          </div>
          <ASYStatus status={f.status} size="sm" />
        </div>
        {f.msg && <div className="bb-caption" style={{ color: bad ? 'var(--bb-error)' : 'var(--bb-tertiary-dark)', marginTop: 2 }}>{f.msg}</div>}
      </div>
    </BBCard>
  );
};

// ──────────────────────────────────────────────────────────────
// PAGES
// ──────────────────────────────────────────────────────────────
const AdminSyncDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="sync" title="Sync health">
    <div style={{ marginBottom: 16 }}><ASYAlert /></div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
      {ASY_STATS.map((s, i) => <ASYStat key={i} s={s} />)}
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
      {ASY_CHANNELS.map(ch => <ASYChannelCard key={ch.id} ch={ch} />)}
    </div>
    <ASYToolbar />
    <ASYTable />
  </AdminScaffold>
);

const AdminSyncTablet = () => (
  <AdminScaffold breakpoint="tablet" active="sync" title="Sync health">
    <div style={{ marginBottom: 14 }}><ASYAlert /></div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, marginBottom: 14 }}>
      {ASY_CHANNELS.map(ch => <ASYChannelCard key={ch.id} ch={ch} compact />)}
    </div>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Feeds needing attention</h3>
      <BBButton variant="secondary" size="sm" iconLeft="refresh">Sync all</BBButton>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {ASY_FEEDS.filter(f => f.status === 'error' || f.status === 'degraded').slice(0, 3).map((f, i) => <ASYFeedCard key={i} f={f} />)}
    </div>
  </AdminScaffold>
);

const AdminSyncMobile = () => (
  <AdminScaffold breakpoint="mobile" active="sync" title="Sync health">
    <div style={{ marginBottom: 12 }}><ASYAlert compact /></div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10, marginBottom: 12 }}>
      {ASY_STATS.slice(0, 2).map((s, i) => <ASYStat key={i} s={s} compact />)}
    </div>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Errors</h3>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-error)', fontWeight: 700 }}>3 critical</span>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {ASY_FEEDS.filter(f => f.status === 'error' || f.status === 'degraded').slice(0, 3).map((f, i) => <ASYFeedCard key={i} f={f} />)}
    </div>
  </AdminScaffold>
);

Object.assign(window, { AdminSyncDesktop, AdminSyncTablet, AdminSyncMobile });
