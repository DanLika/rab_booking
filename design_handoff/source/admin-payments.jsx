/* eslint-disable */
// Admin Payments — platform-wide payment & payout oversight. Fills the admin nav "Payments" gap.
// Reuses AdminScaffold (active="payments") + BBCard/BBChip/BBInput/BBButton/BBAvatar/BBIcon.
// English copy, dark-console chrome. Fixed scaffold heights — content sized to fit (overflow:hidden).

const APY_STATS = [
  { icon: 'account_balance_wallet', label: 'Gross volume · 30d', value: '€1,24M', delta: '+11%', tone: 'success', sub: 'all channels', color: 'var(--bb-primary)' },
  { icon: 'percent',                label: 'Platform fees · 30d', value: '€37,2k', delta: '+11%', tone: 'success', sub: '3,0% avg take rate', color: 'var(--bb-info)' },
  { icon: 'payments',               label: 'Owner payouts · 30d', value: '€1,18M', delta: '+10%', tone: 'success', sub: 'net to owners', color: 'var(--bb-success)' },
  { icon: 'gpp_maybe',              label: 'Refunds & disputes', value: '€9,8k', delta: '+€1,4k', tone: 'error', sub: '0,8% of volume', color: 'var(--bb-error)' },
];

// payment status → token mapping
const APY_STATUS = {
  paid:      { label: 'Paid',       fg: 'var(--bb-success)',       bg: 'var(--bb-success-tint)',   dot: '#2E7D5B' },
  transit:   { label: 'In transit', fg: 'var(--bb-info)',          bg: 'var(--bb-info-tint)',      dot: '#4A90D9' },
  scheduled: { label: 'Scheduled',  fg: 'var(--bb-tertiary-dark)', bg: 'var(--bb-tertiary-tint)',  dot: '#FFB84D' },
  refunded:  { label: 'Refunded',   fg: 'var(--bb-text-secondary)',bg: 'var(--bb-surface-variant)',dot: '#718096' },
  disputed:  { label: 'Disputed',   fg: 'var(--bb-error)',         bg: 'var(--bb-error-tint)',     dot: '#FF6B6B' },
};
const APYStatus = ({ status, size = 'md' }) => {
  const s = APY_STATUS[status] || APY_STATUS.paid;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, height: size === 'sm' ? 22 : 26, padding: '0 10px', borderRadius: 999, background: s.bg, color: s.fg, fontSize: 12, fontWeight: 600 }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: s.dot }} />
      {s.label}
    </span>
  );
};

const APY_METHODS = {
  Card: { icon: 'credit_card', fg: 'var(--bb-primary)', bg: 'var(--bb-primary-tint-bg)' },
  SEPA: { icon: 'account_balance', fg: 'var(--bb-info)', bg: 'var(--bb-info-tint)' },
};
const APYMethod = ({ method, detail }) => {
  const m = APY_METHODS[method] || APY_METHODS.Card;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7, minWidth: 0 }}>
      <span style={{ width: 26, height: 26, borderRadius: 7, background: m.bg, color: m.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <BBIcon name={m.icon} size={15} />
      </span>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-secondary)', whiteSpace: 'nowrap' }}>{detail}</span>
    </span>
  );
};

const APY_ROWS = [
  { txn: 'TXN-8841', owner: 'Davor Kralj',    ref: 'BB-2402', method: 'Card', detail: '•• 4242', gross: '€360',   fee: '€10,80', net: '€349,20',   status: 'paid',      date: '29 May' },
  { txn: 'TXN-8840', owner: 'Lana Babić',     ref: 'BB-2398', method: 'SEPA', detail: 'HR •• 81', gross: '€420',   fee: '€12,60', net: '€407,40',   status: 'transit',   date: '29 May' },
  { txn: 'TXN-8839', owner: 'Goran Šimić',    ref: 'BB-2391', method: 'Card', detail: '•• 0199', gross: '€540',   fee: '€16,20', net: '€523,80',   status: 'paid',      date: '28 May' },
  { txn: 'TXN-8838', owner: 'Ante Jurić',     ref: 'ABB-77',  method: 'Card', detail: '•• 7741', gross: '€1.260', fee: '€37,80', net: '€1.222,20', status: 'paid',      date: '28 May' },
  { txn: 'TXN-8837', owner: 'Davor Kralj',    ref: 'BB-2410', method: 'Card', detail: '•• 4242', gross: '€240',   fee: '€7,20',  net: '€232,80',   status: 'scheduled', date: '27 May' },
  { txn: 'TXN-8836', owner: 'Lana Babić',     ref: 'BB-2385', method: 'SEPA', detail: 'HR •• 81', gross: '€300',   fee: '€0,00',  net: '−€300,00',  status: 'refunded',  date: '27 May' },
  { txn: 'TXN-8835', owner: 'Maja Novak',     ref: 'BKG-441', method: 'Card', detail: '•• 5520', gross: '€940',   fee: '€28,20', net: '€911,80',   status: 'disputed',  date: '26 May' },
];

const APY_TABS = [
  { id: 'all', label: 'All', count: '14.2k' },
  { id: 'paid', label: 'Paid', dot: '#2E7D5B' },
  { id: 'transit', label: 'In transit', dot: '#4A90D9' },
  { id: 'scheduled', label: 'Scheduled', dot: '#FFB84D', count: 42 },
  { id: 'refunded', label: 'Refunded', dot: '#718096' },
  { id: 'disputed', label: 'Disputed', dot: '#FF6B6B', count: 3 },
];

// ── Stat tile (admin pattern) ──
const APYStat = ({ s, compact = false }) => {
  const dc = s.tone === 'success' ? 'var(--bb-success)' : s.tone === 'error' ? 'var(--bb-error)' : 'var(--bb-text-tertiary)';
  const db = s.tone === 'success' ? 'var(--bb-success-tint)' : s.tone === 'error' ? 'var(--bb-error-tint)' : 'var(--bb-surface-variant)';
  return (
    <BBCard style={compact ? { padding: 14 } : {}}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ width: 34, height: 34, borderRadius: 10, background: `color-mix(in srgb, ${s.color || 'var(--bb-primary)'} 14%, transparent)`, color: s.color || 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name={s.icon} size={18} />
        </div>
        {s.delta && <span style={{ fontSize: 12, fontWeight: 700, color: dc, background: db, padding: '3px 8px', borderRadius: 6 }} className="bb-tnum">{s.delta}</span>}
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{s.label}</div>
      <div className="bb-tnum" style={{ fontSize: compact ? 22 : 26, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 2 }}>{s.value}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{s.sub}</div>
    </BBCard>
  );
};

// ── Volume trend (gross, last 12 months) — real area/line vs previous year ──
const APY_GROSS = [0.74, 0.88, 0.69, 0.95, 0.82, 1.04, 0.93, 1.12, 0.99, 1.18, 1.09, 1.24];
const APY_GROSS_PREV = [0.52, 0.61, 0.49, 0.66, 0.58, 0.72, 0.65, 0.79, 0.71, 0.84, 0.78, 0.89];
const APY_BAR_LABELS = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

const APYVolumeCard = () => {
  const series = [
    { data: APY_GROSS, color: 'var(--bb-primary)', area: true, label: 'This year' },
    { data: APY_GROSS_PREV, color: 'var(--bb-text-tertiary)', dashed: true, label: 'Previous year' },
  ];
  return (
    <BBCard>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 8 }}>
        <div>
          <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Payment volume</h3>
          <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>Last 12 months · gross processed (€M)</p>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <BBChip size="sm" selected>Gross</BBChip>
          <BBChip size="sm">Fees</BBChip>
          <BBChip size="sm">Net</BBChip>
        </div>
      </div>
      <AdmTrend series={series} labels={APY_BAR_LABELS} height={170} yFmt={(v) => `€${v.toFixed(1)}M`} />
      <AdmLegend items={series} style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid var(--bb-border-subtle)' }} />
    </BBCard>
  );
};

// ── Payout pipeline ──
const APY_PIPELINE = [
  { label: 'Available now', amount: '€214,0k', pct: 68, color: 'var(--bb-success)' },
  { label: 'In transit',    amount: '€86,4k',  pct: 27, color: 'var(--bb-info)' },
  { label: 'On hold',       amount: '€12,2k',  pct: 5,  color: 'var(--bb-tertiary)' },
];
const APYPipelineCard = () => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Payout pipeline</h3>
      <BBIcon name="account_balance" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
    </div>
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 16 }}>
      <span className="bb-tnum" style={{ fontSize: 28, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>€312,6k</span>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>scheduled to owners</span>
    </div>
    {/* stacked bar */}
    <div style={{ display: 'flex', height: 12, borderRadius: 999, overflow: 'hidden', gap: 2, marginBottom: 18 }}>
      {APY_PIPELINE.map((p, i) => <div key={i} style={{ width: `${p.pct}%`, background: p.color, borderRadius: 4 }} />)}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      {APY_PIPELINE.map((p, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 10, height: 10, borderRadius: 3, background: p.color }} />
            <span className="bb-label" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{p.label}</span>
          </span>
          <span className="bb-tnum" style={{ fontWeight: 700, color: 'var(--bb-text-primary)', fontSize: 14 }}>{p.amount}</span>
        </div>
      ))}
    </div>
    {/* Stripe Connect health */}
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 18, paddingTop: 16, borderTop: '1px solid var(--bb-border-subtle)' }}>
      <div style={{ width: 34, height: 34, borderRadius: 9, background: 'var(--bb-success-tint)', color: 'var(--bb-success)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name="bolt" size={18} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Stripe Connect</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Next payout · 02 Jun</div>
      </div>
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: 'var(--bb-success)', fontWeight: 700, fontSize: 12 }}>
        <span style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--bb-success)' }} /> Operational
      </span>
    </div>
  </BBCard>
);

// ── Toolbar (tabs + actions) ──
const APYToolbar = ({ compact = false }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '16px 0 14px', flexWrap: 'wrap' }}>
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', flex: 1 }}>
      {APY_TABS.map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count} size={compact ? 'sm' : 'md'}>{t.label}</BBChip>)}
    </div>
    {!compact && (
      <div style={{ display: 'flex', gap: 8 }}>
        <BBButton variant="secondary" iconLeft="calendar_today" size="sm">Date range</BBButton>
        <BBButton variant="secondary" iconLeft="download" size="sm">Export</BBButton>
      </div>
    )}
  </div>
);

// ── Transactions ledger ──
const APY_COLS = '0.95fr 1.4fr 0.8fr 1fr 0.7fr 0.65fr 0.9fr 1fr 36px';
const APY_HEADS = ['Txn', 'Owner', 'Booking', 'Method', 'Gross', 'Fee', 'Net payout', 'Status', ''];
const APYTable = ({ rows = APY_ROWS }) => (
  <BBCard padded={false} style={{ overflow: 'hidden' }}>
    <div style={{ display: 'grid', gridTemplateColumns: APY_COLS, gap: 12, padding: '10px 18px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      {APY_HEADS.map((h, i) => <span key={i} className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700, textAlign: (i === 4 || i === 5 || i === 6) ? 'right' : 'left' }}>{h}</span>)}
    </div>
    {rows.map((r, i) => (
      <div key={i} className="bb-row-hover" style={{ display: 'grid', gridTemplateColumns: APY_COLS, gap: 12, alignItems: 'center', padding: '11px 18px', borderBottom: i < rows.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
        <span className="bb-mono" style={{ fontSize: 12, fontWeight: 600, color: 'var(--bb-text-secondary)' }}>{r.txn}</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
          <BBAvatar name={r.owner} size="xs" />
          <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.owner}</span>
        </div>
        <span className="bb-mono" style={{ fontSize: 12, color: 'var(--bb-text-tertiary)' }}>{r.ref}</span>
        <APYMethod method={r.method} detail={r.detail} />
        <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, textAlign: 'right' }}>{r.gross}</span>
        <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', textAlign: 'right' }}>{r.fee}</span>
        <span className="bb-label bb-tnum" style={{ color: r.status === 'refunded' ? 'var(--bb-text-tertiary)' : 'var(--bb-text-primary)', fontWeight: 700, textAlign: 'right' }}>{r.net}</span>
        <span><APYStatus status={r.status} size="sm" /></span>
        <BBButton variant="tertiary" asIcon size="sm" iconLeft="more_vert" ariaLabel="Actions" />
      </div>
    ))}
  </BBCard>
);

const APYPagination = ({ shown = 7 }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 14 }}>
    <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Showing <span className="bb-tnum">1–{shown}</span> of <span className="bb-tnum">14.214</span> transactions</span>
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prev" />
      {['1', '2', '3', '…', '2031'].map((p, i) => (
        <button key={i} type="button" style={{ minWidth: 32, height: 32, borderRadius: 8, border: '1px solid ' + (p === '1' ? 'var(--bb-primary)' : 'var(--bb-border)'), background: p === '1' ? 'var(--bb-primary)' : 'var(--bb-surface)', color: p === '1' ? '#FFFFFF' : 'var(--bb-text-secondary)', fontWeight: 600, fontSize: 13, cursor: 'pointer', fontVariantNumeric: 'tabular-nums' }}>{p}</button>
      ))}
      <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Next" />
    </div>
  </div>
);

// ── Mobile transaction card ──
const APYCard = ({ r }) => (
  <BBCard padded={false}>
    <div style={{ padding: 14 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
        <span className="bb-mono" style={{ fontSize: 12, fontWeight: 600, color: 'var(--bb-text-tertiary)' }}>{r.txn}</span>
        <div style={{ flex: 1 }} />
        <APYStatus status={r.status} size="sm" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <BBAvatar name={r.owner} size="sm" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{r.owner}</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{r.ref} · {r.method} {r.detail}</div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{r.net}</div>
          <div className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>fee {r.fee}</div>
        </div>
      </div>
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// PAGES
// ──────────────────────────────────────────────────────────────
const AdminPaymentsDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="payments" title="Payments">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
      {APY_STATS.map((s, i) => <APYStat key={i} s={s} />)}
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1.55fr 1fr', gap: 16 }}>
      <APYVolumeCard />
      <APYPipelineCard />
    </div>
    <APYToolbar />
    <APYTable rows={APY_ROWS.slice(0, 6)} />
    <APYPagination shown={6} />
  </AdminScaffold>
);

const AdminPaymentsTablet = () => (
  <AdminScaffold breakpoint="tablet" active="payments" title="Payments">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, marginBottom: 14 }}>
      {APY_STATS.map((s, i) => <APYStat key={i} s={s} compact />)}
    </div>
    <APYPipelineCard />
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '16px 0 12px' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Recent transactions</h3>
      <BBButton variant="tertiary" size="sm" iconRight="arrow_forward">View all</BBButton>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {APY_ROWS.slice(0, 2).map((r, i) => <APYCard key={i} r={r} />)}
    </div>
  </AdminScaffold>
);

const AdminPaymentsMobile = () => (
  <AdminScaffold breakpoint="mobile" active="payments" title="Payments">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10, marginBottom: 12 }}>
      {APY_STATS.slice(0, 2).map((s, i) => <APYStat key={i} s={s} compact />)}
    </div>
    <div style={{ display: 'flex', gap: 8, marginBottom: 12, flexWrap: 'wrap' }}>
      {APY_TABS.slice(0, 3).map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count} size="sm">{t.label}</BBChip>)}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {APY_ROWS.slice(0, 4).map((r, i) => <APYCard key={i} r={r} />)}
    </div>
  </AdminScaffold>
);

Object.assign(window, { AdminPaymentsDesktop, AdminPaymentsTablet, AdminPaymentsMobile });
