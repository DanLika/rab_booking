/* eslint-disable */
// Pregled · Premium 2026 — flagship owner dashboard.
// Best-in-class 2026 patterns: north-star revenue dominant, AI insight callout, dual-series
// revenue chart (this vs previous period), radial occupancy gauge, sparkline KPI cards,
// revenue-by-channel breakdown, upcoming arrivals. Calm, hierarchy-driven, premium craft.
// Reuses SAMPLE_USER / SPARK_DATA / BOOKINGS globals + BB primitives. Loads AFTER screens.jsx.

const PV_SHADOW = '0 1px 2px rgba(16,24,40,0.04), 0 4px 10px -2px rgba(16,24,40,0.06), 0 24px 48px -16px rgba(16,24,40,0.10)';
const PV_SHADOW_SM = '0 1px 2px rgba(16,24,40,0.04), 0 2px 6px -1px rgba(16,24,40,0.06)';

// ── Layered "console" shell (comment request) ────────────────────────────────
// Layer 1: sidebar + top bar + gutter share ONE continuous tinted surface.
// Layer 2: the main content floats above it as an elevated, rounded panel.
// Layer 3: the white KPI/cards still pop on the soft off-white panel.
// All values are DESIGN TOKENS (tokens.css) so they're consistent + dark-theme aware.
const PV_SHELL_BG = 'var(--bb-shell-bg)';
const PV_PANEL_BG = 'var(--bb-panel-bg)';
const PV_PANEL_SHADOW = 'var(--bb-panel-shadow)';
const PV_PANEL_BORDER = 'var(--bb-panel-border)';
const PV_PANEL_RADIUS = 28;
const PV_TRANSPARENT_CHROME = { background: 'transparent', borderRight: 'none', borderBottom: 'none' };
// Share the console-shell tokens with the other premium modules (they load after this one)
Object.assign(window, { PV_SHELL_BG, PV_PANEL_BG, PV_PANEL_SHADOW, PV_PANEL_BORDER, PV_PANEL_RADIUS, PV_TRANSPARENT_CHROME });

// Previous-period series (slightly lower, for the ghost line)
const PV_PREV = SPARK_DATA.map((v, i) => Math.round(v * (0.72 + 0.10 * (i / SPARK_DATA.length))));

// Count-up hook — animates a number from 0 → target on mount (cubic ease-out)
const usePVCountUp = (target, duration = 1100) => {
  const [val, setVal] = React.useState(0);
  React.useEffect(() => {
    if (typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setVal(target); return;
    }
    let raf, start;
    const tick = (t) => {
      if (start == null) start = t;
      const p = Math.min((t - start) / duration, 1);
      setVal(target * (1 - Math.pow(1 - p, 3)));
      if (p < 1) raf = requestAnimationFrame(tick); else setVal(target);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [target, duration]);
  return val;
};

// ──────────────────────────────────────────────────────────────
// Primitives
// ──────────────────────────────────────────────────────────────
const PVCard = ({ children, pad = 24, className = '', style = {} }) => (
  <div className={className} style={{
    background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)',
    borderRadius: 'var(--bb-radius-md)', boxShadow: PV_SHADOW, padding: pad, ...style,
  }}>{children}</div>
);

const PVEyebrow = ({ children, style = {} }) => (
  <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--bb-text-tertiary)', ...style }}>{children}</div>
);

const PVDelta = ({ value, positive = true, subtle = false }) => (
  <span style={{
    display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 12, fontWeight: 700,
    color: positive ? 'var(--bb-success)' : 'var(--bb-error)',
    background: subtle ? 'transparent' : (positive ? 'var(--bb-success-tint)' : 'var(--bb-error-tint)'),
    padding: subtle ? 0 : '4px 8px', borderRadius: 999,
  }}>
    <BBIcon name={positive ? 'trending_up' : 'trending_down'} size={14} />
    <span className="bb-tnum">{value}</span>
  </span>
);

// ──────────────────────────────────────────────────────────────
// Charts
// ──────────────────────────────────────────────────────────────
const pvSmooth = (pts) => {
  let d = `M ${pts[0][0]} ${pts[0][1]}`;
  for (let i = 1; i < pts.length; i++) {
    const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
    const cx = (x0 + x1) / 2;
    d += ` C ${cx} ${y0} ${cx} ${y1} ${x1} ${y1}`;
  }
  return d;
};

// Dual-series area chart — current (filled, accent) vs previous (dashed ghost)
const PVDualChart = ({ cur, prev, width, height }) => {
  const padX = 4, padTop = 14, padBot = 22;
  const all = cur.concat(prev);
  const max = Math.max(...all), min = Math.min(...all);
  const n = cur.length;
  const xs = (i) => padX + (i / (n - 1)) * (width - padX * 2);
  const ys = (v) => height - padBot - ((v - min) / (max - min || 1)) * (height - padTop - padBot);
  const curPts = cur.map((v, i) => [xs(i), ys(v)]);
  const prevPts = prev.map((v, i) => [xs(i), ys(v)]);
  const curLine = pvSmooth(curPts);
  const area = `${curLine} L ${curPts[n - 1][0]} ${height - padBot} L ${curPts[0][0]} ${height - padBot} Z`;
  const last = curPts[n - 1];
  const labels = ['1.', '8.', '15.', '22.', '30.'];
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ display: 'block', overflow: 'visible' }}>
      <defs>
        <linearGradient id="pvArea" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="var(--bb-primary)" stopOpacity="0.22" />
          <stop offset="100%" stopColor="var(--bb-primary)" stopOpacity="0" />
        </linearGradient>
        <linearGradient id="pvLine" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#6B4CE6" />
          <stop offset="100%" stopColor="#8B6FFF" />
        </linearGradient>
      </defs>
      {/* gridlines */}
      {[0, 0.5, 1].map((f, i) => {
        const y = padTop + f * (height - padTop - padBot);
        return <line key={i} x1={padX} x2={width - padX} y1={y} y2={y} stroke="var(--bb-border-subtle)" strokeWidth="1" />;
      })}
      {/* previous (ghost) */}
      <path d={pvSmooth(prevPts)} fill="none" stroke="var(--bb-text-disabled)" strokeWidth="2" strokeDasharray="4 4" opacity="0.7" />
      {/* current */}
      <path className="pv-fade-in" d={area} fill="url(#pvArea)" />
      <path className="pv-draw" pathLength={1} d={curLine} fill="none" stroke="url(#pvLine)" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={last[0]} cy={last[1]} r="10" fill="var(--bb-primary)" opacity="0.16" />
      <circle cx={last[0]} cy={last[1]} r="5" fill="var(--bb-primary)" stroke="#FFFFFF" strokeWidth="2.5" />
      {/* x labels */}
      {labels.map((lb, i) => (
        <text key={i} x={padX + (i / (labels.length - 1)) * (width - padX * 2)} y={height - 4}
          textAnchor={i === 0 ? 'start' : i === labels.length - 1 ? 'end' : 'middle'}
          fontSize="10" fontWeight="600" fill="var(--bb-text-tertiary)" fontFamily="var(--bb-font-sans)">{lb}</text>
      ))}
    </svg>
  );
};

// Radial gauge
const PVRadial = ({ value, size = 168, stroke = 16, label, sublabel }) => {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c * (1 - value / 100);
  const cx = size / 2;
  const [dash, setDash] = React.useState(c);
  React.useEffect(() => {
    const reduce = typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduce) { setDash(off); return; }
    const id = requestAnimationFrame(() => setDash(off));
    return () => cancelAnimationFrame(id);
  }, [off]);
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <defs>
          <linearGradient id="pvGauge" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#6B4CE6" />
            <stop offset="100%" stopColor="#8B6FFF" />
          </linearGradient>
        </defs>
        <circle cx={cx} cy={cx} r={r} fill="none" stroke="var(--bb-surface-variant)" strokeWidth={stroke} />
        <circle cx={cx} cy={cx} r={r} fill="none" stroke="url(#pvGauge)" strokeWidth={stroke}
          strokeDasharray={c} strokeDashoffset={dash} strokeLinecap="round" transform={`rotate(-90 ${cx} ${cx})`}
          style={{ transition: 'stroke-dashoffset 1.2s cubic-bezier(.2,.8,.2,1)' }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <span className="bb-tnum" style={{ fontSize: 34, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1 }}>{label}</span>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 4 }}>{sublabel}</span>
      </div>
    </div>
  );
};

// Mini sparkline for KPI cards
const PVSpark = ({ data, width = 96, height = 34, color = 'var(--bb-primary)' }) => {
  const max = Math.max(...data), min = Math.min(...data);
  const n = data.length;
  const xs = (i) => (i / (n - 1)) * width;
  const ys = (v) => height - 3 - ((v - min) / (max - min || 1)) * (height - 6);
  const pts = data.map((v, i) => [xs(i), ys(v)]);
  const line = pvSmooth(pts);
  const gid = 'pvspk' + Math.round(data[0] * 99 + data.length);
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ display: 'block', overflow: 'visible' }}>
      <defs>
        <linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.22" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path className="pv-fade-in" d={`${line} L ${width} ${height} L 0 ${height} Z`} fill={`url(#${gid})`} />
      <path className="pv-draw" pathLength={1} d={line} fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" />
      <circle cx={pts[n - 1][0]} cy={pts[n - 1][1]} r="3" fill={color} />
    </svg>
  );
};

// ──────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────
const PVPeriod = () => (
  <div style={{ display: 'inline-flex', padding: 4, background: 'var(--bb-surface-variant)', borderRadius: 999, border: '1px solid var(--bb-border-subtle)' }}>
    {['7 dana', '30 dana', '90 dana', 'Godina'].map((l, i) => (
      <button key={i} type="button" style={{
        padding: '7px 14px', border: 'none', cursor: 'pointer', borderRadius: 999,
        background: i === 1 ? 'var(--bb-surface)' : 'transparent',
        color: i === 1 ? 'var(--bb-text-primary)' : 'var(--bb-text-secondary)',
        fontFamily: 'var(--bb-font-sans)', fontSize: 13, fontWeight: 600,
        boxShadow: i === 1 ? PV_SHADOW_SM : 'none',
      }}>{l}</button>
    ))}
  </div>
);

// ──────────────────────────────────────────────────────────────
// AI insight banner (2026 signature)
// ──────────────────────────────────────────────────────────────
const PVAIInsight = ({ compact = false }) => (
  <div className="bb-lift" style={{
    position: 'relative', overflow: 'hidden', borderRadius: 'var(--bb-radius-md)',
    background: 'linear-gradient(105deg, rgba(107,76,230,0.10) 0%, rgba(139,111,255,0.05) 45%, rgba(61,217,176,0.07) 100%)',
    border: '1px solid rgba(107,76,230,0.18)', boxShadow: PV_SHADOW_SM,
    padding: compact ? '16px 16px' : '18px 22px',
    display: 'flex', alignItems: compact ? 'flex-start' : 'center', gap: compact ? 12 : 18,
    flexDirection: compact ? 'column' : 'row',
  }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: compact ? 12 : 18, width: '100%' }}>
    <div style={{
      width: 46, height: 46, borderRadius: 14, flexShrink: 0,
      background: 'var(--bb-gradient-hero)', color: '#FFFFFF',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: 'var(--bb-shadow-purple-sm)',
    }}>
      <BBIcon name="auto_awesome" size={24} />
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
        <span style={{ fontSize: 10, fontWeight: 800, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--bb-primary)', background: 'var(--bb-primary-tint-bg)', padding: '2px 8px', borderRadius: 6 }}>BookBed AI</span>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Uvid tjedna</span>
      </div>
      <div className="bb-body" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: compact ? 14 : 15 }}>
        Vikend-termini u srpnju popunjeni su <span style={{ color: 'var(--bb-primary)' }}>94%</span>. Povećajte cijenu za <span className="bb-tnum">+15%</span> i zaradite oko <span className="bb-tnum" style={{ color: 'var(--bb-success)' }}>€420</span> više bez gubitka rezervacija.
      </div>
    </div>
    </div>
    <div style={{ display: 'flex', gap: 8, flexShrink: 0, width: compact ? '100%' : 'auto', paddingLeft: compact ? 58 : 0 }}>
      {!compact && <BBButton variant="secondary" size="sm">Odbaci</BBButton>}
      <BBButton variant="primary" size="sm" iconRight="arrow_forward" style={compact ? { flex: 1 } : {}}>Primijeni</BBButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Revenue command card (north-star, dominant)
// ──────────────────────────────────────────────────────────────
const PVLegendDot = ({ color, dashed, label }) => (
  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
    <span style={{ width: 14, height: dashed ? 0 : 8, borderRadius: 999, borderTop: dashed ? '2px dashed var(--bb-text-disabled)' : 'none', background: dashed ? 'transparent' : color }} />
    <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 500 }}>{label}</span>
  </span>
);

const PVRevenueCommand = ({ compact = false, chartW = 620 }) => {
  const revenue = usePVCountUp(3840, 1200);
  return (
  <PVCard pad={compact ? 20 : 28} className="bb-lift" style={{ display: 'flex', flexDirection: 'column', position: 'relative', overflow: 'hidden' }}>
    {/* faint gradient wash behind the north-star number */}
    <div aria-hidden="true" style={{
      position: 'absolute', top: -90, left: -70, width: 340, height: 240, pointerEvents: 'none',
      background: 'radial-gradient(60% 60% at 30% 35%, rgba(107,76,230,0.13) 0%, rgba(139,111,255,0.05) 45%, rgba(255,255,255,0) 72%)',
    }} />
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 6, position: 'relative' }}>
      <div>
        <PVEyebrow>Ukupna zarada · zadnjih 30 dana</PVEyebrow>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 14, marginTop: 10 }}>
          <span className="bb-tnum" style={{ fontSize: compact ? 40 : 56, fontWeight: 800, letterSpacing: '-0.035em', color: 'var(--bb-text-primary)', lineHeight: 1 }}>€{Math.round(revenue).toLocaleString('de-DE')}</span>
          <PVDelta value="+12,4%" positive />
        </div>
        <div className="bb-body" style={{ color: 'var(--bb-text-tertiary)', marginTop: 8 }}>
          <span className="bb-tnum" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>€3.416</span> u prethodnom razdoblju · <span className="bb-tnum" style={{ color: 'var(--bb-success)', fontWeight: 600 }}>+€424</span>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-end' }}>
        <PVLegendDot color="var(--bb-primary)" label="Ovaj period" />
        <PVLegendDot dashed label="Prošli period" />
      </div>
    </div>
    <div style={{ marginTop: 14, position: 'relative' }}>
      <PVDualChart cur={SPARK_DATA} prev={PV_PREV} width={chartW} height={compact ? 170 : 210} />
    </div>
  </PVCard>
  );
};

// ──────────────────────────────────────────────────────────────
// Occupancy + deposit (right rail of hero)
// ──────────────────────────────────────────────────────────────
const PVOccupancy = () => {
  const occ = usePVCountUp(78, 1200);
  return (
  <PVCard className="bb-lift" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
    <div style={{ alignSelf: 'flex-start' }}><PVEyebrow>Popunjenost</PVEyebrow></div>
    <div style={{ margin: '12px 0 8px' }}>
      <PVRadial value={78} label={`${Math.round(occ)}%`} sublabel="23 / 30 noći" />
    </div>
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <PVDelta value="+8 pp" positive subtle />
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>vs. prošli mjesec</span>
    </div>
  </PVCard>
  );
};

const PVDeposit = () => (
  <PVCard className="bb-lift">
    <PVEyebrow>Naplaćeni depoziti</PVEyebrow>
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 10 }}>
      <span className="bb-tnum" style={{ fontSize: 28, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em' }}>€768</span>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>/ €3.840 očekivano</span>
    </div>
    <div style={{ height: 8, borderRadius: 999, background: 'var(--bb-surface-variant)', overflow: 'hidden', marginTop: 14 }}>
      <div style={{ height: '100%', width: '20%', borderRadius: 999, background: 'linear-gradient(90deg, var(--bb-success) 0%, #4FAE7F 100%)' }} />
    </div>
    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Polog (20%)</span>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>€3.072 na dolasku</span>
    </div>
  </PVCard>
);

// ──────────────────────────────────────────────────────────────
// KPI cards with sparklines
// ──────────────────────────────────────────────────────────────
const PV_KPIS = [
  { icon: 'receipt_long', label: 'Rezervacije', value: '14', num: 14, fmt: (v) => Math.round(v), delta: '+3', positive: true, spark: [6, 8, 7, 9, 8, 11, 10, 12, 14], color: 'var(--bb-primary)' },
  { icon: 'payments', label: 'Prosječna cijena', value: '€274', num: 274, fmt: (v) => '€' + Math.round(v), delta: '+6%', positive: true, spark: [240, 250, 245, 260, 268, 262, 270, 274], color: 'var(--bb-info)' },
  { icon: 'person_add', label: 'Novi gosti', value: '9', num: 9, fmt: (v) => Math.round(v), delta: '+4', positive: true, spark: [3, 4, 3, 5, 6, 5, 7, 9], color: 'var(--bb-success)' },
  { icon: 'star', label: 'Prosječna ocjena', value: '4,9', num: 4.9, fmt: (v) => v.toFixed(1).replace('.', ','), delta: '+0,2', positive: true, spark: [4.5, 4.6, 4.6, 4.7, 4.8, 4.8, 4.9], color: 'var(--bb-tertiary-dark)' },
];

const PVKpiCard = ({ k, compact = false }) => {
  const v = usePVCountUp(k.num != null ? k.num : 0, 1000);
  return (
  <PVCard pad={20} className="bb-lift" style={{ minWidth: 0 }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: `color-mix(in srgb, ${k.color} 14%, transparent)`, color: k.color, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={k.icon} size={19} />
      </div>
      <PVDelta value={k.delta} positive={k.positive} subtle />
    </div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, marginTop: 16, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{k.label}</div>
    <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 10, marginTop: 4 }}>
      <span className="bb-tnum" style={{ fontSize: 30, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1 }}>{k.fmt ? k.fmt(v) : k.value}</span>
      <PVSpark data={k.spark} color={k.color} width={compact ? 56 : 96} />
    </div>
  </PVCard>
  );
};

// ──────────────────────────────────────────────────────────────
// Upcoming arrivals
// ──────────────────────────────────────────────────────────────
const PV_ARRIVALS = [
  { name: 'Marko Horvat', unit: 'Vila Marina · Studio 4', date: '8. srp', day: 'Sub', nights: 3, status: 'pending', next: true },
  { name: 'Sandra Kovač', unit: 'Stan Lavanda · Apartman A', date: '12. srp', day: 'Sri', nights: 3, status: 'confirmed' },
  { name: 'Eva Novak', unit: 'Vila Marina · Premium', date: '15. srp', day: 'Sub', nights: 5, status: 'confirmed' },
  { name: 'Luka Babić', unit: 'Stan Lavanda · Studio B', date: '19. srp', day: 'Sri', nights: 2, status: 'confirmed' },
];

const PVArrivals = () => (
  <PVCard pad={0} className="bb-lift">
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px 14px' }}>
      <div>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Nadolazeći dolasci</h3>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Sljedećih 14 dana</span>
      </div>
      <BBButton variant="tertiary" size="sm" iconRight="arrow_forward">Kalendar</BBButton>
    </div>
    <div>
      {PV_ARRIVALS.map((a, i) => (
        <div key={i} className="bb-row-hover" style={{
          display: 'flex', alignItems: 'center', gap: 14, padding: '12px 24px',
          borderTop: '1px solid var(--bb-border-subtle)',
        }}>
          <div style={{ width: 48, flexShrink: 0, textAlign: 'center', padding: '4px 0', borderRadius: 10, background: a.next ? 'var(--bb-gradient-hero)' : 'var(--bb-surface-variant)', boxShadow: a.next ? 'var(--bb-shadow-purple-sm)' : 'none' }}>
            <div className="bb-caption" style={{ color: a.next ? 'rgba(255,255,255,0.82)' : 'var(--bb-text-tertiary)', fontWeight: 600, fontSize: 10, textTransform: 'uppercase' }}>{a.day}</div>
            <div className="bb-tnum" style={{ fontSize: 14, fontWeight: 700, color: a.next ? '#FFFFFF' : 'var(--bb-text-primary)' }}>{a.date.split(' ')[0]}</div>
          </div>
          <BBAvatar name={a.name} size="sm" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{a.name}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{a.unit} · {a.nights} noći</div>
          </div>
          <BBStatusBadge status={a.status} size="sm" />
        </div>
      ))}
    </div>
  </PVCard>
);

// ──────────────────────────────────────────────────────────────
// Revenue by channel
// ──────────────────────────────────────────────────────────────
const PV_CHANNELS = [
  { label: 'Direktno', value: '€2.640', pct: 69, color: '#6B4CE6' },
  { label: 'Booking.com', value: '€840', pct: 22, color: '#4A90D9' },
  { label: 'Airbnb', value: '€360', pct: 9, color: '#FF6B6B' },
];

const PVChannels = () => (
  <PVCard className="bb-lift" style={{ display: 'flex', flexDirection: 'column' }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
      <div>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Zarada po kanalu</h3>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Udio izvora rezervacija</span>
      </div>
      <BBIcon name="donut_small" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
    </div>
    {/* Stacked bar */}
    <div style={{ display: 'flex', height: 12, borderRadius: 999, overflow: 'hidden', gap: 2, marginBottom: 20 }}>
      {PV_CHANNELS.map((c, i) => (
        <div key={i} style={{ width: `${c.pct}%`, background: c.color, borderRadius: 4 }} />
      ))}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {PV_CHANNELS.map((c, i) => (
        <div key={i}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
              <span style={{ width: 10, height: 10, borderRadius: 3, background: c.color }} />
              <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{c.label}</span>
            </span>
            <span style={{ display: 'inline-flex', alignItems: 'baseline', gap: 8 }}>
              <span className="bb-tnum" style={{ fontWeight: 700, color: 'var(--bb-text-primary)', fontSize: 14 }}>{c.value}</span>
              <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', width: 32, textAlign: 'right' }}>{c.pct}%</span>
            </span>
          </div>
          <div style={{ height: 6, borderRadius: 999, background: 'var(--bb-surface-variant)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${c.pct}%`, borderRadius: 999, background: c.color }} />
          </div>
        </div>
      ))}
    </div>
  </PVCard>
);

// ──────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────
const PregledPremiumDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="pregled" pendingCount={1} notifCount={6} style={PV_TRANSPARENT_CHROME} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Početna', 'Pregled']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
      <div style={{ flex: 1, minWidth: 0, padding: '4px 28px 28px 16px' }}>
        <main style={{
          background: PV_PANEL_BG, borderRadius: PV_PANEL_RADIUS,
          border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW,
          padding: '28px 32px 36px', display: 'flex', flexDirection: 'column', gap: 20,
        }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <PVEyebrow style={{ color: 'var(--bb-primary)' }}>Subota · 30. svibnja 2026</PVEyebrow>
            <h1 style={{ margin: '6px 0 0', fontSize: 30, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Dobro jutro, Ivana</h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <PVPeriod />
            <BBButton variant="secondary" iconLeft="download">Izvezi</BBButton>
            <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
          </div>
        </div>

        {/* AI insight */}
        <PVAIInsight />

        {/* Hero: revenue command + occupancy/deposit rail */}
        <div style={{ display: 'grid', gridTemplateColumns: '1.85fr 1fr', gap: 20, alignItems: 'stretch' }}>
          <PVRevenueCommand />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
            <PVOccupancy />
            <PVDeposit />
          </div>
        </div>

        {/* KPI cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <PVEyebrow>Ključni pokazatelji</PVEyebrow>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
            {PV_KPIS.map((k, i) => <PVKpiCard key={i} k={k} />)}
          </div>
        </div>

        {/* Lower: arrivals + channels */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <PVEyebrow>Detalji</PVEyebrow>
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 20, alignItems: 'start' }}>
            <PVArrivals />
            <PVChannels />
          </div>
        </div>
      </main>
      </div>
    </div>
  </div>
);

Object.assign(window, { PregledPremiumDesktop, PregledPremiumTablet, PregledPremiumMobile });

// ──────────────────────────────────────────────────────────────
// Tablet (768) — rail nav, stacked, auto-height
// ──────────────────────────────────────────────────────────────
function PregledPremiumTablet() {
  return (
    <div className="theme-light bb-screen" style={{ width: 768, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebarRail active="pregled" pendingCount={1} notifCount={6} style={PV_TRANSPARENT_CHROME} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar breadcrumb={['Početna', 'Pregled']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
        <div style={{ flex: 1, minWidth: 0, padding: '0 18px 18px 6px' }}>
          <main style={{
            background: PV_PANEL_BG, borderRadius: 24,
            border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW,
            padding: '22px 24px 28px', display: 'flex', flexDirection: 'column', gap: 16,
          }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
            <div>
              <PVEyebrow style={{ color: 'var(--bb-primary)' }}>Subota · 30. svibnja 2026</PVEyebrow>
              <h1 style={{ margin: '6px 0 0', fontSize: 26, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Dobro jutro, Ivana</h1>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <PVPeriod />
              <BBButton variant="primary" iconLeft="add">Nova</BBButton>
            </div>
          </div>
          <PVAIInsight />
          <PVRevenueCommand chartW={540} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            <PVOccupancy />
            <PVDeposit />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
            {PV_KPIS.map((k, i) => <PVKpiCard key={i} k={k} />)}
          </div>
          <PVArrivals />
          <PVChannels />
        </main>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Mobile (390) — app bar, single column, auto-height
// ──────────────────────────────────────────────────────────────
function PregledPremiumMobile() {
  return (
    <div className="theme-light bb-screen" style={{ width: 390, background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
      <BBAppBar title="Pregled" showHamburger notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} style={PV_TRANSPARENT_CHROME} />
      <div style={{ padding: '0 12px 16px' }}>
        <main style={{
          background: PV_PANEL_BG, borderRadius: 24,
          border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW,
          padding: '16px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14,
        }}>
        <div>
          <PVEyebrow style={{ color: 'var(--bb-primary)' }}>Subota · 30. svibnja 2026</PVEyebrow>
          <h1 style={{ margin: '6px 0 0', fontSize: 24, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Dobro jutro, Ivana</h1>
        </div>
        <div style={{ display: 'flex', justifyContent: 'center' }}><PVPeriod /></div>
        <PVAIInsight compact />
        <PVRevenueCommand compact chartW={300} />
        <PVOccupancy />
        <PVDeposit />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
          {PV_KPIS.map((k, i) => <PVKpiCard key={i} k={k} compact />)}
        </div>
        <PVArrivals />
        <PVChannels />
      </main>
      </div>
    </div>
  );
}
