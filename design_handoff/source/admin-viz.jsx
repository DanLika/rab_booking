/* eslint-disable */
// Admin data-viz — deeper platform analytics. Adds three reusable, real SVG charts to the
// admin console and a dedicated "Analytics" screen that showcases them:
//   • AdmTrend  — smooth dual-series area/line trend with y-gridlines, axis labels,
//                 legend + end-point markers (replaces the crude overview/payments bars)
//   • AdmDonut  — channel-mix donut with center total + value/percent legend
//   • AdmCohort — owner-growth retention cohort heatmap (acquisition month × month-N)
// English copy, light surface inside the dark-console chrome, admin purple, tabular figures.
// Reuses AdminScaffold (active="analytics") + BBCard/BBChip/BBButton/BBIcon. Fixed scaffold
// heights — content sized to fit (overflow:hidden). Load any time before App renders.

const ANL_FONT = 'var(--bb-font-sans)';

// ──────────────────────────────────────────────────────────────
// Smooth path helper (monotone-ish Catmull-Rom → cubic bezier)
// ──────────────────────────────────────────────────────────────
const advSmooth = (pts) => {
  if (pts.length < 2) return '';
  let d = `M ${pts[0][0].toFixed(1)} ${pts[0][1].toFixed(1)}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] || pts[i];
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const p3 = pts[i + 2] || p2;
    const t = 0.18;
    const c1x = p1[0] + (p2[0] - p0[0]) * t;
    const c1y = p1[1] + (p2[1] - p0[1]) * t;
    const c2x = p2[0] - (p3[0] - p1[0]) * t;
    const c2y = p2[1] - (p3[1] - p1[1]) * t;
    d += ` C ${c1x.toFixed(1)} ${c1y.toFixed(1)}, ${c2x.toFixed(1)} ${c2y.toFixed(1)}, ${p2[0].toFixed(1)} ${p2[1].toFixed(1)}`;
  }
  return d;
};

let advUid = 0;
const nextUid = () => `adv${++advUid}`;

// ──────────────────────────────────────────────────────────────
// AdmTrend — area/line trend chart
//   series: [{ data:[], color, area?:bool, dashed?:bool, label }]
//   labels: x-axis tick labels (same length as data)
// ──────────────────────────────────────────────────────────────
const AdmTrend = ({
  series = [],
  labels = [],
  width = 720,
  height = 240,
  yTicks = 4,
  yFmt = (v) => v,
  yMaxPad = 1.08,
}) => {
  const uid = React.useMemo(nextUid, []);
  const padL = 46, padR = 14, padT = 16, padB = 26;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;

  const all = series.flatMap(s => s.data);
  const rawMax = Math.max(...all, 1);
  const max = rawMax * yMaxPad;
  const n = labels.length || (series[0]?.data.length ?? 0);

  const xAt = (i) => padL + (n <= 1 ? 0 : (i / (n - 1)) * innerW);
  const yAt = (v) => padT + innerH - (v / max) * innerH;

  const ticks = Array.from({ length: yTicks + 1 }, (_, i) => (max / yTicks) * i);

  return (
    <svg width="100%" viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="xMidYMid meet" style={{ display: 'block', overflow: 'visible', fontFamily: ANL_FONT }}>
      <defs>
        {series.map((s, si) => s.area && (
          <linearGradient key={si} id={`${uid}-g${si}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={s.color} stopOpacity="0.22" />
            <stop offset="100%" stopColor={s.color} stopOpacity="0" />
          </linearGradient>
        ))}
      </defs>

      {/* gridlines + y labels */}
      {ticks.map((t, i) => {
        const y = yAt(t);
        return (
          <g key={i}>
            <line x1={padL} y1={y} x2={width - padR} y2={y} stroke="var(--bb-border-subtle)" strokeWidth="1" />
            <text x={padL - 10} y={y + 3.5} textAnchor="end" fontSize="10.5" fontWeight="600" fill="var(--bb-text-tertiary)" style={{ fontVariantNumeric: 'tabular-nums' }}>{yFmt(t)}</text>
          </g>
        );
      })}

      {/* x labels */}
      {labels.map((lb, i) => (
        <text key={i} x={xAt(i)} y={height - 8} textAnchor="middle" fontSize="10.5" fontWeight="600" fill="var(--bb-text-tertiary)">{lb}</text>
      ))}

      {/* series */}
      {series.map((s, si) => {
        const pts = s.data.map((v, i) => [xAt(i), yAt(v)]);
        const line = advSmooth(pts);
        const last = pts[pts.length - 1];
        return (
          <g key={si}>
            {s.area && <path d={`${line} L ${last[0].toFixed(1)} ${padT + innerH} L ${pts[0][0].toFixed(1)} ${padT + innerH} Z`} fill={`url(#${uid}-g${si})`} />}
            <path d={line} fill="none" stroke={s.color} strokeWidth={s.dashed ? 2 : 2.5} strokeLinecap="round" strokeLinejoin="round" strokeDasharray={s.dashed ? '5 5' : 'none'} opacity={s.dashed ? 0.55 : 1} />
            {!s.dashed && (
              <>
                <circle cx={last[0]} cy={last[1]} r="6.5" fill={s.color} opacity="0.16" />
                <circle cx={last[0]} cy={last[1]} r="3.5" fill={s.color} stroke="var(--bb-surface)" strokeWidth="2" />
              </>
            )}
          </g>
        );
      })}
    </svg>
  );
};

const AdmLegend = ({ items, style = {} }) => (
  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px 20px', ...style }}>
    {items.map((it, i) => (
      <span key={i} style={{ display: 'inline-flex', alignItems: 'center', gap: 7 }}>
        <span style={{ width: 12, height: it.dashed ? 0 : 10, borderRadius: it.dashed ? 0 : 3, background: it.dashed ? 'transparent' : it.color, borderTop: it.dashed ? `2px dashed ${it.color}` : 'none' }} />
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>{it.label}</span>
      </span>
    ))}
  </div>
);

// ──────────────────────────────────────────────────────────────
// AdmDonut — channel-mix donut
//   segments: [{ label, value, color, sub }]
// ──────────────────────────────────────────────────────────────
const AdmDonut = ({ segments = [], size = 176, thickness = 26, centerLabel, centerSub }) => {
  const total = segments.reduce((a, s) => a + s.value, 0) || 1;
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const cx = size / 2;
  const gap = 0.012 * c; // small gap between segments
  let offset = 0;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: 'block' }}>
      <circle cx={cx} cy={cx} r={r} fill="none" stroke="var(--bb-surface-variant)" strokeWidth={thickness} />
      {segments.map((s, i) => {
        const frac = s.value / total;
        const len = Math.max(frac * c - gap, 0);
        const dash = `${len} ${c - len}`;
        const el = (
          <circle key={i} cx={cx} cy={cx} r={r} fill="none" stroke={s.color} strokeWidth={thickness}
            strokeDasharray={dash} strokeDashoffset={-offset} strokeLinecap="round"
            transform={`rotate(-90 ${cx} ${cx})`} />
        );
        offset += frac * c;
        return el;
      })}
      <text x={cx} y={cx - 4} textAnchor="middle" fontSize="26" fontWeight="800" fill="var(--bb-text-primary)" style={{ fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{centerLabel}</text>
      <text x={cx} y={cx + 16} textAnchor="middle" fontSize="11" fontWeight="600" fill="var(--bb-text-tertiary)">{centerSub}</text>
    </svg>
  );
};

const AdmDonutLegend = ({ segments, total }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: 12, flex: 1, minWidth: 0 }}>
    {segments.map((s, i) => {
      const pct = Math.round((s.value / total) * 100);
      return (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ width: 10, height: 10, borderRadius: 3, background: s.color, flexShrink: 0 }} />
          <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.label}</span>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{s.sub}</span>
          <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 700, minWidth: 34, textAlign: 'right' }}>{pct}%</span>
        </div>
      );
    })}
  </div>
);

// ──────────────────────────────────────────────────────────────
// AdmCohort — owner-growth retention heatmap
//   rows: [{ label, size, vals:[100, 92, ...] }]  (vals[0] should be 100)
//   cols: header labels (M0..Mn)
// ──────────────────────────────────────────────────────────────
const cohortCell = (v) => {
  if (v == null) return { bg: 'transparent', fg: 'transparent', border: false };
  const a = 0.10 + (v / 100) * 0.82;
  return {
    bg: `rgba(107,76,230,${a.toFixed(3)})`,
    fg: a > 0.52 ? '#FFFFFF' : 'var(--bb-primary-dark)',
    border: true,
  };
};
const AdmCohort = ({ rows = [], cols = [], cell = 52, compact = false }) => {
  const labW = compact ? 96 : 132;
  const ch = compact ? 40 : 46;
  return (
    <div style={{ width: '100%', overflow: 'hidden' }}>
      {/* header */}
      <div style={{ display: 'grid', gridTemplateColumns: `${labW}px repeat(${cols.length}, 1fr)`, gap: 4, marginBottom: 6 }}>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, alignSelf: 'center' }}>Cohort</span>
        {cols.map((c, i) => (
          <span key={i} className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700, fontSize: 10, textAlign: 'center' }}>{c}</span>
        ))}
      </div>
      {/* rows */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {rows.map((row, ri) => (
          <div key={ri} style={{ display: 'grid', gridTemplateColumns: `${labW}px repeat(${cols.length}, 1fr)`, gap: 4 }}>
            <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', minWidth: 0 }}>
              <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap' }}>{row.label}</span>
              <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', fontSize: 10 }}>{row.size} owners</span>
            </div>
            {cols.map((_, ci) => {
              const v = row.vals[ci];
              const st = cohortCell(v);
              return (
                <div key={ci} style={{
                  height: ch, borderRadius: 8,
                  background: st.bg,
                  border: st.border ? '1px solid rgba(255,255,255,0.35)' : '1px dashed var(--bb-border-subtle)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {v != null && <span className="bb-tnum" style={{ color: st.fg, fontWeight: 700, fontSize: compact ? 11 : 12.5 }}>{v}%</span>}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// DATA
// ──────────────────────────────────────────────────────────────
const ANL_MONTHS = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];

// MRR (€k) — this year vs previous year
const ANL_MRR      = [21.8, 23.1, 24.6, 25.0, 26.7, 28.4, 29.1, 31.2, 33.0, 34.8, 36.5, 38.4];
const ANL_MRR_PREV = [14.2, 15.0, 16.1, 16.4, 17.9, 18.6, 19.4, 20.1, 21.0, 22.2, 23.0, 24.1];

// Active owners — this year
const ANL_OWNERS = [156, 168, 179, 186, 197, 205, 211, 219, 228, 236, 242, 248];

// Channel mix (GMV share, € thousands)
const ANL_CHANNELS = [
  { label: 'Booking.com',   value: 42, sub: '€521k', color: 'var(--bb-info)' },
  { label: 'Airbnb',        value: 31, sub: '€384k', color: 'var(--bb-secondary)' },
  { label: 'Direct widget', value: 18, sub: '€223k', color: 'var(--bb-primary)' },
  { label: 'Custom iCal',   value: 9,  sub: '€112k', color: 'var(--bb-tertiary)' },
];

// Owner retention cohorts
const ANL_COHORT_COLS = ['M0', 'M1', 'M2', 'M3', 'M4', 'M5'];
const ANL_COHORTS = [
  { label: 'Dec 2025', size: 34, vals: [100, 94, 91, 88, 85, 82] },
  { label: 'Jan 2026', size: 41, vals: [100, 93, 89, 86, 83, null] },
  { label: 'Feb 2026', size: 38, vals: [100, 95, 90, 87, null, null] },
  { label: 'Mar 2026', size: 46, vals: [100, 92, 88, null, null, null] },
  { label: 'Apr 2026', size: 52, vals: [100, 96, null, null, null, null] },
  { label: 'May 2026', size: 49, vals: [100, null, null, null, null, null] },
];

// Growth KPIs
const ANL_KPIS = [
  { icon: 'monitoring',     label: 'MRR',                  value: '€38,4k', delta: '+9,2%',  good: true,  sub: 'monthly recurring' },
  { icon: 'group',          label: 'Active owners',        value: '248',    delta: '+12',    good: true,  sub: 'paying + trial' },
  { icon: 'replay',         label: 'Net revenue retention',value: '112%',   delta: '+3pp',   good: true,  sub: 'expansion − churn' },
  { icon: 'logout',         label: 'Logo churn',           value: '1,8%',   delta: '−0,4pp', good: true,  sub: 'monthly, owners' },
];

// ──────────────────────────────────────────────────────────────
// Local card pieces
// ──────────────────────────────────────────────────────────────
const ANLKpi = ({ k, compact = false }) => (
  <BBCard style={compact ? { padding: 14 } : {}}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={k.icon} size={20} />
      </div>
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 12, fontWeight: 700, color: k.good ? 'var(--bb-success)' : 'var(--bb-error)', background: k.good ? 'var(--bb-success-tint)' : 'var(--bb-error-tint)', padding: '3px 8px', borderRadius: 6 }} className="bb-tnum">{k.delta}</span>
    </div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 700, fontSize: 10, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{k.label}</div>
    <div className="bb-tnum" style={{ fontSize: compact ? 24 : 30, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 2 }}>{k.value}</div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{k.sub}</div>
  </BBCard>
);

const ANLTrendCard = ({ height = 210, compact = false }) => {
  const series = [
    { data: ANL_MRR, color: 'var(--bb-primary)', area: true, label: 'MRR · this year' },
    { data: ANL_MRR_PREV, color: 'var(--bb-text-tertiary)', dashed: true, label: 'MRR · prev. year' },
  ];
  return (
    <BBCard>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 6, gap: 12 }}>
        <div>
          <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Recurring revenue</h3>
          <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>Last 12 months · MRR (€k) · platform-wide</p>
        </div>
        {!compact && (
          <div style={{ display: 'flex', gap: 6 }}>
            <BBChip size="sm" selected>MRR</BBChip>
            <BBChip size="sm">Owners</BBChip>
          </div>
        )}
      </div>
      <AdmTrend series={series} labels={ANL_MONTHS} height={height} yFmt={(v) => `€${Math.round(v)}k`} />
      <AdmLegend items={series} style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid var(--bb-border-subtle)' }} />
    </BBCard>
  );
};

const ANLChannelCard = () => {
  const total = ANL_CHANNELS.reduce((a, s) => a + s.value, 0);
  return (
    <BBCard>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <div>
          <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Channel mix</h3>
          <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>GMV by source · 30d</p>
        </div>
        <BBIcon name="donut_large" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
        <AdmDonut segments={ANL_CHANNELS} centerLabel="€1,24M" centerSub="GMV · 30d" />
        <AdmDonutLegend segments={ANL_CHANNELS} total={total} />
      </div>
    </BBCard>
  );
};

const ANLCohortCard = ({ compact = false }) => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 16, gap: 12, flexWrap: 'wrap' }}>
      <div>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Owner retention cohorts</h3>
        <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>% of owners still active, by acquisition month</p>
      </div>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Low</span>
        <span style={{ display: 'inline-flex', height: 10, width: 96, borderRadius: 999, background: 'linear-gradient(90deg, rgba(107,76,230,0.12), rgba(107,76,230,0.92))' }} />
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>High</span>
      </div>
    </div>
    <AdmCohort rows={ANL_COHORTS} cols={ANL_COHORT_COLS} compact={compact} />
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// PAGES
// ──────────────────────────────────────────────────────────────
const AdminAnalyticsDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="analytics" title="Analytics">
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
      <p className="bb-caption" style={{ margin: 0, color: 'var(--bb-text-tertiary)' }}>Growth &amp; revenue health · all owners · updated 5 min ago</p>
      <div style={{ display: 'flex', gap: 8 }}>
        <BBButton variant="secondary" iconLeft="calendar_today" size="sm">Last 12 months</BBButton>
        <BBButton variant="secondary" iconLeft="download" size="sm">Export</BBButton>
      </div>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16 }}>
      {ANL_KPIS.map((k, i) => <ANLKpi key={i} k={k} />)}
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1.55fr 1fr', gap: 16, marginBottom: 16 }}>
      <ANLTrendCard />
      <ANLChannelCard />
    </div>
    <ANLCohortCard />
  </AdminScaffold>
);

const AdminAnalyticsTablet = () => (
  <AdminScaffold breakpoint="tablet" active="analytics" title="Analytics">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, marginBottom: 14 }}>
      {ANL_KPIS.map((k, i) => <ANLKpi key={i} k={k} compact />)}
    </div>
    <div style={{ marginBottom: 14 }}><ANLTrendCard height={180} compact /></div>
    <ANLChannelCard />
  </AdminScaffold>
);

const AdminAnalyticsMobile = () => (
  <AdminScaffold breakpoint="mobile" active="analytics" title="Analytics">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10, marginBottom: 12 }}>
      {ANL_KPIS.slice(0, 2).map((k, i) => <ANLKpi key={i} k={k} compact />)}
    </div>
    <div style={{ marginBottom: 12 }}><ANLTrendCard height={170} compact /></div>
    <BBCard>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Channel mix</h3>
        <BBIcon name="donut_large" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
        <AdmDonut segments={ANL_CHANNELS} size={150} centerLabel="€1,24M" centerSub="GMV" />
      </div>
      <AdmDonutLegend segments={ANL_CHANNELS} total={ANL_CHANNELS.reduce((a, s) => a + s.value, 0)} />
    </BBCard>
  </AdminScaffold>
);

Object.assign(window, {
  AdmTrend, AdmDonut, AdmCohort, AdmLegend, AdmDonutLegend,
  ANL_MONTHS, ANL_MRR, ANL_MRR_PREV, ANL_OWNERS, ANL_CHANNELS,
  AdminAnalyticsDesktop, AdminAnalyticsTablet, AdminAnalyticsMobile,
});
