/* eslint-disable */
// Admin Bookings — platform-wide booking oversight. Fills the admin nav "Bookings" gap.
// Reuses AdminScaffold (active="bookings") + BBStatusBadge/BBChip/BBInput/BBButton/BBAvatar.

const ABK_STATS = [
  { icon: 'today', label: 'Bookings today', value: '42', delta: '+6', tone: 'success', sub: 'vs yesterday', color: 'var(--bb-primary)' },
  { icon: 'payments', label: 'GMV today', value: '€18,4k', delta: '+9%', tone: 'success', sub: 'gross value', color: 'var(--bb-info)' },
  { icon: 'pending_actions', label: 'Pending approval', value: '17', tone: 'neutral', sub: 'across 12 owners', color: 'var(--bb-tertiary-dark)' },
  { icon: 'event_busy', label: 'Cancellations · 7d', value: '8', delta: '−2', tone: 'success', sub: 'vs prev 7d', color: 'var(--bb-error)' },
];

const ABK_TABS = [
  { id: 'all', label: 'All', count: 3420 },
  { id: 'confirmed', label: 'Confirmed', dot: '#2E7D5B' },
  { id: 'pending', label: 'Pending', dot: '#FFB84D', count: 17 },
  { id: 'completed', label: 'Completed', dot: '#6B4CE6' },
  { id: 'cancelled', label: 'Cancelled', dot: '#718096' },
  { id: 'imported', label: 'Imported', dot: '#4A90D9' },
];

const ABK_CH = {
  'Direct': { fg: 'var(--bb-primary)', bg: 'var(--bb-primary-tint-bg)' },
  'Booking.com': { fg: 'var(--bb-info)', bg: 'var(--bb-info-tint)' },
  'Airbnb': { fg: 'var(--bb-error)', bg: 'var(--bb-error-tint)' },
  'Widget': { fg: 'var(--bb-tertiary-dark)', bg: 'var(--bb-tertiary-tint)' },
};

const ABK_ROWS = [
  { ref: 'BB-2402', guest: 'Marko Horvat', property: 'Vila Marina · Studio 4', owner: 'Davor Kralj', dates: '08.07 – 11.07', ch: 'Direct', amount: '€360', status: 'pending' },
  { ref: 'BB-2398', guest: 'Sandra Kovač', property: 'Stan Lavanda · Apt A', owner: 'Lana Babić', dates: '12.07 – 15.07', ch: 'Direct', amount: '€420', status: 'confirmed' },
  { ref: 'BKG-441', guest: 'M. Schmidt', property: 'Vila Marina · Premium', owner: 'Davor Kralj', dates: '28.06 – 02.07', ch: 'Booking.com', amount: '€940', status: 'imported' },
  { ref: 'BB-2391', guest: 'Luka Babić', property: 'Jadran Stay · Loft', owner: 'Goran Šimić', dates: '24.04 – 27.04', ch: 'Widget', amount: '€540', status: 'completed' },
  { ref: 'ABB-77', guest: 'E. Rossi', property: 'Kvarner Homes · A2', owner: 'Ante Jurić', dates: '15.07 – 22.07', ch: 'Airbnb', amount: '€1.260', status: 'confirmed' },
  { ref: 'BB-2410', guest: 'Ana Pavlović', property: 'Vila Marina · Studio 4', owner: 'Davor Kralj', dates: '22.07 – 24.07', ch: 'Direct', amount: '€240', status: 'confirmed' },
  { ref: 'BB-2385', guest: 'Eva Novak', property: 'Stan Lavanda · Apt A', owner: 'Lana Babić', dates: '09.05 – 12.05', ch: 'Booking.com', amount: '€300', status: 'cancelled' },
  { ref: 'BB-2421', guest: 'T. Weber', property: 'Jadran Stay · Suite', owner: 'Goran Šimić', dates: '01.08 – 06.08', ch: 'Widget', amount: '€880', status: 'pending' },
];

// ──────────────────────────────────────────────────────────────
const ABKStat = ({ s, compact = false }) => {
  const dc = s.tone === 'success' ? 'var(--bb-success)' : s.tone === 'error' ? 'var(--bb-error)' : 'var(--bb-text-tertiary)';
  const db = s.tone === 'success' ? 'var(--bb-success-tint)' : s.tone === 'error' ? 'var(--bb-error-tint)' : 'var(--bb-surface-variant)';
  return (
    <BBCard style={compact ? { padding: 14 } : {}}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ width: 34, height: 34, borderRadius: 10, background: `color-mix(in srgb, ${s.color || 'var(--bb-primary)'} 14%, transparent)`, color: s.color || 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name={s.icon} size={18} />
        </div>
        {s.delta && <span style={{ fontSize: 12, fontWeight: 700, color: dc, background: db, padding: '3px 8px', borderRadius: 6 }}>{s.delta}</span>}
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{s.label}</div>
      <div className="bb-tnum" style={{ fontSize: compact ? 22 : 26, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 2 }}>{s.value}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{s.sub}</div>
    </BBCard>
  );
};

const ABKChannel = ({ ch }) => {
  const c = ABK_CH[ch] || ABK_CH['Direct'];
  return <span style={{ background: c.bg, color: c.fg, fontSize: 11, fontWeight: 700, padding: '3px 9px', borderRadius: 999, whiteSpace: 'nowrap' }}>{ch}</span>;
};

const ABKToolbar = ({ compact = false }) => (
  <div style={{ marginBottom: 16 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14, flexWrap: 'wrap' }}>
      <div style={{ flex: 1, minWidth: 200, maxWidth: 360 }}>
        <BBInput placeholder="Search by ref, guest or owner…" iconLeft="search" size="sm" />
      </div>
      <BBButton variant="secondary" iconLeft="calendar_today" size="sm">Date range</BBButton>
      <BBButton variant="secondary" iconLeft="download" size="sm">Export</BBButton>
    </div>
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
      {ABK_TABS.map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count} size={compact ? 'sm' : 'md'}>{t.label}</BBChip>)}
    </div>
  </div>
);

const ABKTable = ({ rows, compact = false }) => {
  const cols = compact ? '0.9fr 1.4fr 1fr 0.8fr 36px' : '0.9fr 1.4fr 1.8fr 1.1fr 0.9fr 0.8fr 1fr 36px';
  const heads = compact ? ['Ref', 'Guest', 'Dates', 'Status', ''] : ['Ref', 'Guest', 'Property · Owner', 'Dates', 'Channel', 'Amount', 'Status', ''];
  return (
    <BBCard padded={false} style={{ overflow: 'hidden' }}>
      <div style={{ display: 'grid', gridTemplateColumns: cols, gap: 12, padding: '10px 18px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        {heads.map((h, i) => <span key={i} className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{h}</span>)}
      </div>
      {rows.map((r, i) => (
        <div key={i} style={{ display: 'grid', gridTemplateColumns: cols, gap: 12, alignItems: 'center', padding: '11px 18px', borderBottom: i < rows.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
          <span className="bb-mono" style={{ fontSize: 12, fontWeight: 600, color: 'var(--bb-text-secondary)' }}>{r.ref}</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
            <BBAvatar name={r.guest} size="xs" />
            <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.guest}</span>
          </div>
          {!compact && (
            <div style={{ minWidth: 0 }}>
              <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontSize: 13 }}>{r.property}</div>
              <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{r.owner}</div>
            </div>
          )}
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-secondary)' }}>{r.dates}</span>
          {!compact && <span><ABKChannel ch={r.ch} /></span>}
          {!compact && <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{r.amount}</span>}
          <BBStatusBadge status={r.status} size="sm" />
          <BBButton variant="tertiary" asIcon size="sm" iconLeft="more_vert" ariaLabel="Actions" />
        </div>
      ))}
    </BBCard>
  );
};

const ABKPagination = ({ shown }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 14 }}>
    <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Showing <span className="bb-tnum">1–{shown}</span> of <span className="bb-tnum">3.420</span></span>
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prev" />
      {['1', '2', '3', '…', '428'].map((p, i) => (
        <button key={i} type="button" style={{ minWidth: 32, height: 32, borderRadius: 8, border: '1px solid ' + (p === '1' ? 'var(--bb-primary)' : 'var(--bb-border)'), background: p === '1' ? 'var(--bb-primary)' : 'var(--bb-surface)', color: p === '1' ? '#FFFFFF' : 'var(--bb-text-secondary)', fontWeight: 600, fontSize: 13, cursor: 'pointer', fontVariantNumeric: 'tabular-nums' }}>{p}</button>
      ))}
      <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Next" />
    </div>
  </div>
);

// Mobile card
const ABKCard = ({ r }) => (
  <BBCard padded={false}>
    <div style={{ padding: 14 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
        <span className="bb-mono" style={{ fontSize: 12, fontWeight: 600, color: 'var(--bb-text-tertiary)' }}>{r.ref}</span>
        <ABKChannel ch={r.ch} />
        <div style={{ flex: 1 }} />
        <BBStatusBadge status={r.status} size="sm" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <BBAvatar name={r.guest} size="sm" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{r.guest}</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.property}</div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{r.amount}</div>
          <div className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{r.dates}</div>
        </div>
      </div>
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
const AdminBookingsDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="bookings" title="Bookings">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
      {ABK_STATS.map((s, i) => <ABKStat key={i} s={s} />)}
    </div>
    <ABKToolbar />
    <ABKTable rows={ABK_ROWS} />
    <ABKPagination shown={8} />
  </AdminScaffold>
);

const AdminBookingsTablet = () => (
  <AdminScaffold breakpoint="tablet" active="bookings" title="Bookings">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, marginBottom: 14 }}>
      {ABK_STATS.map((s, i) => <ABKStat key={i} s={s} compact />)}
    </div>
    <ABKToolbar compact />
    <ABKTable rows={ABK_ROWS.slice(0, 6)} compact />
  </AdminScaffold>
);

const AdminBookingsMobile = () => (
  <AdminScaffold breakpoint="mobile" active="bookings" title="Bookings">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10, marginBottom: 12 }}>
      {ABK_STATS.slice(0, 2).map((s, i) => <ABKStat key={i} s={s} compact />)}
    </div>
    <div style={{ display: 'flex', gap: 8, marginBottom: 12, flexWrap: 'wrap' }}>
      {ABK_TABS.slice(0, 3).map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count} size="sm">{t.label}</BBChip>)}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {ABK_ROWS.slice(0, 4).map((r, i) => <ABKCard key={i} r={r} />)}
    </div>
  </AdminScaffold>
);

Object.assign(window, { AdminBookingsDesktop, AdminBookingsTablet, AdminBookingsMobile });
