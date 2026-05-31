/* eslint-disable */
// Screen compositions — Foundation gallery, Pregled, Rezervacije.

const { useState: useS } = React;

// ──────────────────────────────────────────────────────────────
// SAMPLE DATA
// ──────────────────────────────────────────────────────────────
const SAMPLE_USER = { name: 'Ivana Marić', email: 'ivana@apartmaniadria.hr' };
const SPARK_DATA = [42, 58, 49, 64, 71, 55, 68, 73, 62, 79, 88, 76, 84, 92, 81, 89, 96, 84, 91, 102, 95, 108, 116, 109, 121, 128, 119, 134, 142, 138];
const ACTIVITY = [
  { id: 1, type: 'booking-pending', icon: 'event_available', tone: 'tertiary', title: 'Nova rezervacija primljena', subtitle: 'Vila Marina · Studio 4 — BB-2402', time: 'prije 2h', actionLabel: 'Odobri' },
  { id: 2, type: 'payment', icon: 'payments', tone: 'success', title: 'Plaćanje zaprimljeno', subtitle: 'Stan Lavanda · €420.00 — BB-2398', time: 'prije 5h' },
  { id: 3, type: 'completed', icon: 'check_circle', tone: 'primary', title: 'Rezervacija završena', subtitle: 'Vila Marina · Premium suite — BB-2391', time: 'prije 1d' },
  { id: 4, type: 'sync', icon: 'sync', tone: 'info', title: 'Booking.com sinkronizacija', subtitle: '4 nove rezervacije uvezene', time: 'prije 1d' },
  { id: 5, type: 'review', icon: 'star', tone: 'tertiary', title: 'Nova ocjena · 5,0', subtitle: 'Stan Lavanda · "Sve je bilo savršeno"', time: 'prije 2d' },
];

const BOOKINGS = [
  {
    id: 'BB-2402',
    guestName: 'Marko Horvat',
    guestEmail: 'marko.horvat@gmail.com',
    property: 'Vila Marina',
    unit: 'Studio 4',
    checkIn: '08.07.2026',
    checkOut: '11.07.2026',
    nights: 3,
    guests: 2,
    status: 'pending',
    total: 360,
    paid: 72,
    remaining: 288,
    source: 'Direktno',
  },
  {
    id: 'BB-2398',
    guestName: 'Sandra Kovač',
    guestEmail: 'sandra.kovac@outlook.com',
    property: 'Stan Lavanda',
    unit: 'Apartman A',
    checkIn: '12.07.2026',
    checkOut: '15.07.2026',
    nights: 3,
    guests: 4,
    status: 'confirmed',
    total: 420,
    paid: 420,
    remaining: 0,
    source: 'Direktno',
  },
  {
    id: 'BB-2391',
    guestName: 'Luka Babić',
    guestEmail: 'l.babic@me.com',
    property: 'Vila Marina',
    unit: 'Premium suite',
    checkIn: '24.04.2026',
    checkOut: '27.04.2026',
    nights: 3,
    guests: 2,
    status: 'completed',
    total: 540,
    paid: 540,
    remaining: 0,
    source: 'Direktno',
  },
  {
    id: 'BB-2385',
    guestName: 'Eva Novak',
    guestEmail: 'eva.novak@gmail.com',
    property: 'Stan Lavanda',
    unit: 'Apartman A',
    checkIn: '09.05.2026',
    checkOut: '12.05.2026',
    nights: 3,
    guests: 3,
    status: 'completed',
    total: 300,
    paid: 300,
    remaining: 0,
    source: 'Booking.com',
  },
];

// ──────────────────────────────────────────────────────────────
// PREGLED — DESKTOP (1440 × 1100)
// ──────────────────────────────────────────────────────────────
const PregledDesktop = () => {
  const [range, setRange] = useS('30');
  return (
    <div className="theme-light bb-screen" style={{
      width: 1440, height: 1100, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebar user={SAMPLE_USER} active="pregled" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar
          title="Pregled"
          notifCount={6}
          actions={[
            { icon: 'search', label: 'Pretraži' },
            { icon: 'light_mode', label: 'Promijeni temu' },
          ]}
        />
        <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden' }}>
          {/* Header row: greeting + date range */}
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 20 }}>
            <div>
              <h2 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Dobro jutro, Ivana</h2>
              <p className="bb-body" style={{ margin: '4px 0 0', color: 'var(--bb-text-tertiary)' }}>Evo kako vam ide u zadnjih 30 dana.</p>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              {[
                { id: '7', label: '7 dana' },
                { id: '30', label: '30 dana' },
                { id: '90', label: '90 dana' },
                { id: 'year', label: 'Ova godina' },
              ].map(c => (
                <BBChip key={c.id} selected={range === c.id} size="md" onClick={() => setRange(c.id)}>
                  {c.label}
                </BBChip>
              ))}
            </div>
          </div>

          <RevenueHero />
          <PendingStrip count={1} />
          <MetricsRow />
          <ActivitySection />
        </main>
      </div>
    </div>
  );
};

// ── Data-viz helpers (design polish pass) ──
const smoothPath = (pts) => {
  let d = `M ${pts[0][0]} ${pts[0][1]}`;
  for (let i = 1; i < pts.length; i++) {
    const [x0, y0] = pts[i - 1];
    const [x1, y1] = pts[i];
    const cx = (x0 + x1) / 2;
    d += ` C ${cx} ${y0} ${cx} ${y1} ${x1} ${y1}`;
  }
  return d;
};

// Smooth gradient-filled area chart (replaces flat sparkline in heroes)
const HeroAreaChart = ({ data, width, height, accent = '#FFFFFF', showGrid = true, showDot = true }) => {
  const pad = 8;
  const max = Math.max(...data), min = Math.min(...data);
  const n = data.length;
  const xs = (i) => pad + (i / (n - 1)) * (width - pad * 2);
  const ys = (v) => height - pad - ((v - min) / (max - min || 1)) * (height - pad * 2);
  const pts = data.map((v, i) => [xs(i), ys(v)]);
  const line = smoothPath(pts);
  const area = `${line} L ${pts[n - 1][0]} ${height} L ${pts[0][0]} ${height} Z`;
  const gid = `hg${width}x${height}`;
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ display: 'block', overflow: 'visible' }}>
      <defs>
        <linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={accent} stopOpacity="0.38" />
          <stop offset="100%" stopColor={accent} stopOpacity="0" />
        </linearGradient>
      </defs>
      {showGrid && [0.33, 0.66].map((f, i) => {
        const y = pad + f * (height - pad * 2);
        return <line key={i} x1={pad} x2={width - pad} y1={y} y2={y} stroke="rgba(255,255,255,0.14)" strokeWidth="1" strokeDasharray="2 4" />;
      })}
      <path d={area} fill={`url(#${gid})`} />
      <path d={line} fill="none" stroke={accent} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      {showDot && <React.Fragment>
        <circle cx={pts[n - 1][0]} cy={pts[n - 1][1]} r="9" fill={accent} opacity="0.22" />
        <circle cx={pts[n - 1][0]} cy={pts[n - 1][1]} r="4.5" fill={accent} />
      </React.Fragment>}
    </svg>
  );
};

// Tiny bar chart for metric tiles
const MiniBars = ({ data, color = 'var(--bb-primary)', height = 32 }) => {
  const max = Math.max(...data) || 1;
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height }}>
      {data.map((v, i) => (
        <div key={i} style={{
          flex: 1, height: `${Math.max((v / max) * 100, 8)}%`, minHeight: 3, borderRadius: 2,
          background: i === data.length - 1 ? color : `color-mix(in srgb, ${color} 22%, transparent)`,
        }} />
      ))}
    </div>
  );
};

const HeroKpi = ({ value, label }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
    <span className="bb-tnum" style={{ fontSize: 18, fontWeight: 700, color: '#FFFFFF', letterSpacing: '-0.01em' }}>{value}</span>
    <span style={{ fontSize: 11, fontWeight: 500, color: 'rgba(255,255,255,0.7)' }}>{label}</span>
  </div>
);
const HeroKpiDivider = () => <div style={{ width: 1, height: 32, background: 'rgba(255,255,255,0.18)' }} />;

// Revenue hero — purple gradient, big number, area chart, trend, KPI strip
const RevenueHero = () => (
  <div style={{
    background: 'var(--bb-gradient-hero)',
    borderRadius: 'var(--bb-radius-xl)',
    padding: '22px 32px',
    color: '#FFFFFF',
    boxShadow: 'var(--bb-shadow-purple)',
    position: 'relative', overflow: 'hidden', marginBottom: 16,
  }}>
    <div style={{ position: 'absolute', top: -100, right: -80, width: 360, height: 360, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0) 70%)', pointerEvents: 'none' }} />
    <div style={{ position: 'absolute', bottom: -130, left: -70, width: 300, height: 300, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.10) 0%, rgba(255,255,255,0) 70%)', pointerEvents: 'none' }} />
    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', position: 'relative', zIndex: 1, gap: 24 }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.8)' }}>Zarada · zadnjih 30 dana</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 8 }}>
          <span className="bb-display-lg bb-tnum" style={{ color: '#FFFFFF' }}>€3.840</span>
          <span className="bb-h2 bb-tnum" style={{ color: 'rgba(255,255,255,0.7)' }}>,00</span>
        </div>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 12, background: 'rgba(79,174,127,0.32)', color: '#FFFFFF', padding: '6px 12px', borderRadius: 999, fontSize: 13, fontWeight: 600 }}>
          <BBIcon name="trending_up" size={16} />
          <span className="bb-tnum">+12,4%</span>
          <span style={{ opacity: 0.78, fontWeight: 500 }}>vs. prethodno razdoblje</span>
        </div>
      </div>
      <div style={{ flexShrink: 0, paddingTop: 4 }}>
        <HeroAreaChart data={SPARK_DATA} width={340} height={96} accent="#FFFFFF" />
      </div>
    </div>
    {/* KPI strip */}
    <div style={{ display: 'flex', alignItems: 'center', gap: 30, marginTop: 12, paddingTop: 12, borderTop: '1px solid rgba(255,255,255,0.18)', position: 'relative', zIndex: 1 }}>
      <HeroKpi value="14" label="Rezervacija" />
      <HeroKpiDivider />
      <HeroKpi value="€274" label="Prosjek / rezervaciji" />
      <HeroKpiDivider />
      <HeroKpi value="78%" label="Popunjenost" />
      <HeroKpiDivider />
      <HeroKpi value="4,9 ★" label="Prosječna ocjena" />
    </div>
  </div>
);

// Pending action strip
const PendingStrip = ({ count }) => (
  <BBCard variant="accent-left" accentTone="tertiary" padded={false} style={{ marginBottom: 24 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '14px 20px' }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12,
        background: 'var(--bb-tertiary-tint)', color: 'var(--bb-tertiary-dark)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name="pending_actions" size={22} />
      </div>
      <div style={{ flex: 1 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>
          {count} rezervacija čeka vaše odobrenje
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
          Marko Horvat · Vila Marina · 08.07. – 11.07.
        </div>
      </div>
      <BBButton variant="primary" size="sm" iconRight="arrow_forward">Pregledaj</BBButton>
    </div>
  </BBCard>
);

// 3 metric tiles with mini data-viz
const MetricsRow = () => (
  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: 16 }}>
    <MetricTile icon="receipt_long" label="Rezervacije" value="14" delta="+3" deltaTone="success" bars={[3, 5, 4, 6, 5, 7, 8, 6, 9, 11]} />
    <MetricTile icon="login" label="Nadolazeći check-in" value="3" sub="sljedećih 7 dana" bars={[1, 0, 2, 1, 0, 1, 3]} barColor="var(--bb-info)" />
    <MetricTile icon="donut_large" label="Popunjenost" value="78" suffix="%" delta="+8 pp" deltaTone="success" progress={78} />
  </div>
);

const MetricTile = ({ icon, label, value, suffix = '', sub, delta, deltaTone, bars, progress, barColor = 'var(--bb-primary)' }) => (
  <div className="bb-lift" style={{ borderRadius: 'var(--bb-radius-md)' }}>
    <BBCard style={{ height: '100%' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
        <div style={{
          width: 40, height: 40, borderRadius: 12,
          background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <BBIcon name={icon} size={20} />
        </div>
        {delta && (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 12, fontWeight: 700,
            color: deltaTone === 'success' ? 'var(--bb-success)' : 'var(--bb-error)',
            background: deltaTone === 'success' ? 'var(--bb-success-tint)' : 'var(--bb-error-tint)',
            padding: '4px 8px', borderRadius: 6,
          }}>
            <BBIcon name={deltaTone === 'success' ? 'arrow_upward' : 'arrow_downward'} size={13} />
            <span className="bb-tnum">{delta}</span>
          </span>
        )}
      </div>
      <div className="bb-caption" style={{
        color: 'var(--bb-text-tertiary)', marginTop: 16,
        textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600,
      }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 4 }}>
        <span className="bb-display bb-tnum" style={{ color: 'var(--bb-text-primary)', fontSize: 32 }}>{value}</span>
        {suffix && <span className="bb-h3" style={{ color: 'var(--bb-text-secondary)' }}>{suffix}</span>}
      </div>
      {sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 4 }}>{sub}</div>}
      {bars && <div style={{ marginTop: 10 }}><MiniBars data={bars} color={barColor} height={32} /></div>}
      {progress != null && (
        <div style={{ marginTop: 10 }}>
          <div style={{ height: 8, borderRadius: 999, background: 'var(--bb-surface-variant)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${progress}%`, borderRadius: 999, background: 'linear-gradient(90deg, var(--bb-primary) 0%, var(--bb-primary-light) 100%)' }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Cilj 85%</span>
            <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>23 / 30 noći</span>
          </div>
        </div>
      )}
    </BBCard>
  </div>
);

// Recent activity section
const ActivitySection = () => (
  <div>
    <BBSectionHeader title="Nedavne aktivnosti" action={{ label: 'Sve aktivnosti' }} />
    <BBCard padded={false}>
      {ACTIVITY.map((a, i) => (
        <ActivityRow key={a.id} activity={a} divider={i < ACTIVITY.length - 1} />
      ))}
    </BBCard>
  </div>
);

const ActivityRow = ({ activity, divider }) => {
  const toneColors = {
    primary: 'var(--bb-primary)',
    success: 'var(--bb-success)',
    tertiary: 'var(--bb-tertiary-dark)',
    info: 'var(--bb-info)',
  };
  const toneBg = {
    primary: 'var(--bb-primary-tint-bg)',
    success: 'var(--bb-success-tint)',
    tertiary: 'var(--bb-tertiary-tint)',
    info: 'var(--bb-info-tint)',
  };
  return (
    <div className="bb-row-hover" style={{
      padding: '10px 20px',
      display: 'flex', alignItems: 'center', gap: 16,
      borderBottom: divider ? '1px solid var(--bb-border-subtle)' : 'none',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 12, flexShrink: 0,
        background: toneBg[activity.tone] || 'var(--bb-surface-variant)',
        color: toneColors[activity.tone] || 'var(--bb-text-secondary)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name={activity.icon} size={20} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{activity.title}</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>{activity.subtitle}</div>
      </div>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }}>{activity.time}</span>
      {activity.actionLabel && (
        <BBButton variant="tertiary" size="sm" iconRight="arrow_forward">{activity.actionLabel}</BBButton>
      )}
      {!activity.actionLabel && (
        <BBIcon name="chevron_right" size={18} style={{ color: 'var(--bb-text-tertiary)' }} />
      )}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// PREGLED — MOBILE (390 × 880)
// ──────────────────────────────────────────────────────────────
const PregledMobile = () => {
  const [range, setRange] = useS('30');
  return (
    <div className="theme-light bb-screen" style={{
      width: 390, height: 880,
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
      display: 'flex', flexDirection: 'column',
    }}>
      <BBAppBar title="Pregled" showHamburger notifCount={6} />
      <main style={{ flex: 1, padding: '16px 16px 0', overflow: 'hidden' }}>
        {/* Date range chips wrap */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
          {['7 dana', '30 dana', '90 dana', 'Ova godina'].map((l, i) => (
            <BBChip key={i} selected={i === 1} size="sm">{l}</BBChip>
          ))}
        </div>

        {/* Compact revenue hero */}
        <div style={{
          background: 'var(--bb-gradient-hero)',
          borderRadius: 'var(--bb-radius-xl)',
          padding: '20px 20px 16px',
          color: '#FFFFFF',
          boxShadow: 'var(--bb-shadow-purple-sm)',
          marginBottom: 12, position: 'relative', overflow: 'hidden',
        }}>
          <div style={{
            position: 'absolute', top: -60, right: -50, width: 200, height: 200,
            borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.20) 0%, rgba(255,255,255,0) 70%)',
            pointerEvents: 'none',
          }} />
          <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.8)' }}>Zarada · 30 dana</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
            <span className="bb-tnum" style={{ fontSize: 36, fontWeight: 800, letterSpacing: '-0.03em' }}>€3.840</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 8 }}>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              background: 'rgba(79,174,127,0.32)', color: '#FFFFFF',
              padding: '4px 8px', borderRadius: 999,
              fontSize: 12, fontWeight: 600,
            }}>
              <BBIcon name="trending_up" size={14} />
              <span className="bb-tnum">+12,4%</span>
            </span>
            <HeroAreaChart data={SPARK_DATA} width={140} height={40} accent="#FFFFFF" showGrid={false} showDot={false} />
          </div>
        </div>

        {/* Pending strip */}
        <BBCard variant="accent-left" accentTone="tertiary" padded={false} style={{ marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px' }}>
            <div style={{
              width: 32, height: 32, borderRadius: 10,
              background: 'var(--bb-tertiary-tint)', color: 'var(--bb-tertiary-dark)',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <BBIcon name="pending_actions" size={18} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: 13 }}>
                1 rezervacija čeka odobrenje
              </div>
              <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Marko Horvat · 08.07.</div>
            </div>
            <BBIcon name="chevron_right" size={20} style={{ color: 'var(--bb-tertiary-dark)' }} />
          </div>
        </BBCard>

        {/* 3 compact tiles */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: 16 }}>
          <MobileMetric icon="receipt_long" value="14" label="Rezerv." />
          <MobileMetric icon="login" value="3" label="Check-in" />
          <MobileMetric icon="donut_large" value="78%" label="Popun." />
        </div>

        {/* Activity */}
        <BBSectionHeader title="Aktivnosti" level="h3" action={{ label: 'Sve' }} style={{ marginBottom: 10 }} />
        <BBCard padded={false}>
          {ACTIVITY.slice(0, 3).map((a, i) => (
            <ActivityRowMobile key={a.id} activity={a} divider={i < 2} />
          ))}
        </BBCard>
      </main>
    </div>
  );
};

const MobileMetric = ({ icon, value, label }) => (
  <BBCard style={{ padding: 12 }}>
    <div style={{
      width: 28, height: 28, borderRadius: 8,
      background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      marginBottom: 8,
    }}>
      <BBIcon name={icon} size={16} />
    </div>
    <div className="bb-tnum" style={{ fontSize: 22, fontWeight: 700, color: 'var(--bb-text-primary)', lineHeight: 1.1 }}>{value}</div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{label}</div>
  </BBCard>
);

const ActivityRowMobile = ({ activity, divider }) => {
  const toneColors = {
    primary: 'var(--bb-primary)', success: 'var(--bb-success)',
    tertiary: 'var(--bb-tertiary-dark)', info: 'var(--bb-info)',
  };
  const toneBg = {
    primary: 'var(--bb-primary-tint-bg)', success: 'var(--bb-success-tint)',
    tertiary: 'var(--bb-tertiary-tint)', info: 'var(--bb-info-tint)',
  };
  return (
    <div style={{
      padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
      borderBottom: divider ? '1px solid var(--bb-border-subtle)' : 'none',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 10, flexShrink: 0,
        background: toneBg[activity.tone], color: toneColors[activity.tone],
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name={activity.icon} size={18} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: 13, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{activity.title}</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{activity.subtitle}</div>
      </div>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }}>{activity.time}</span>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// REZERVACIJE — DESKTOP (1440 × 1100)
// ──────────────────────────────────────────────────────────────
const RezervacijeDesktop = () => {
  const [tab, setTab] = useS('pending');
  return (
    <div className="theme-light bb-screen" style={{
      width: 1440, height: 1100, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebar user={SAMPLE_USER} active="rezervacije" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar
          title="Rezervacije"
          notifCount={6}
          actions={[
            { icon: 'view_module', label: 'Pregled kartica' },
            { icon: 'view_list', label: 'Pregled tablice' },
            { icon: 'download', label: 'Izvezi' },
          ]}
        />
        <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden' }}>
          {/* Filter row */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
            <BBInput placeholder="Pretraži po imenu, broju ili objektu…" iconLeft="search" fullWidth style={{ flex: 1, maxWidth: 480 }} />
            <BBButton variant="secondary" iconLeft="tune">Filteri</BBButton>
            <BBButton variant="secondary" iconLeft="calendar_today">Razdoblje</BBButton>
            <div style={{ flex: 1 }} />
            <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
          </div>

          {/* Pending-first tabs */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
            <BBChip selected={tab === 'pending'} onClick={() => setTab('pending')} dotColor="#FFB84D" count={1} countColor={tab === 'pending' ? null : '#FFB84D'}>Na čekanju</BBChip>
            <BBChip selected={tab === 'all'} onClick={() => setTab('all')}>Sve</BBChip>
            <BBChip selected={tab === 'confirmed'} onClick={() => setTab('confirmed')} dotColor="#2E7D5B">Potvrđene</BBChip>
            <BBChip selected={tab === 'completed'} onClick={() => setTab('completed')} dotColor="#6B4CE6">Završene</BBChip>
            <BBChip selected={tab === 'cancelled'} onClick={() => setTab('cancelled')} dotColor="#718096">Otkazane</BBChip>
            <BBChip selected={tab === 'imported'} onClick={() => setTab('imported')} iconLeft="cloud_download">Uvezene</BBChip>
          </div>

          {/* Bookings grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
            {BOOKINGS.map(b => <BookingCard key={b.id} booking={b} />)}
          </div>
        </main>
      </div>
    </div>
  );
};

const fmtEur = (n) => `€${n.toFixed(2).replace('.', ',')}`;

// Payment progress block — paid vs total (ties to deposit narrative)
const PaymentBlock = ({ booking, compact = false }) => {
  const pct = booking.total ? Math.round((booking.paid / booking.total) * 100) : 0;
  const full = booking.remaining <= 0;
  return (
    <div style={{ padding: compact ? '10px 12px' : '12px 14px', background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)' }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: compact ? 6 : 8 }}>
        <span className="bb-caption" style={{ color: full ? 'var(--bb-success)' : 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, fontSize: 10, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          {full && <BBIcon name="check_circle" size={13} />}
          {full ? 'Plaćeno u cijelosti' : 'Plaćeno'}
        </span>
        <span className="bb-tnum" style={{ fontSize: 14 }}>
          <span style={{ fontWeight: 700, color: full ? 'var(--bb-success)' : 'var(--bb-text-primary)' }}>{fmtEur(booking.paid)}</span>
          <span style={{ color: 'var(--bb-text-tertiary)', fontWeight: 500 }}> / {fmtEur(booking.total)}</span>
        </span>
      </div>
      <div style={{ height: 8, borderRadius: 999, background: 'var(--bb-border-subtle)', overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${pct}%`, borderRadius: 999, background: 'linear-gradient(90deg, var(--bb-success) 0%, #4FAE7F 100%)' }} />
      </div>
      {!full && (
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: compact ? 4 : 8 }}>
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Preostali polog na licu mjesta</span>
          <span className="bb-tnum" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-tertiary-dark)' }}>{fmtEur(booking.remaining)}</span>
        </div>
      )}
    </div>
  );
};

const BookingCard = ({ booking, compact = false }) => (
  <BBCard hoverable padded={false}>
    {/* Top: status + reference */}
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: compact ? '14px 16px 10px' : '18px 20px 12px',
      borderBottom: '1px solid var(--bb-border-subtle)',
    }}>
      <BBStatusBadge status={booking.status} />
      <span className="bb-mono" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>#{booking.id}</span>
    </div>

    {/* Body */}
    <div style={{ padding: compact ? 16 : 20, paddingBottom: compact ? 12 : 16 }}>
      {/* Guest */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
        <BBAvatar name={booking.guestName} size={compact ? 'sm' : 'md'} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className={compact ? 'bb-label' : 'bb-h3'} style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{booking.guestName}</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{booking.guestEmail}</div>
        </div>
      </div>

      {/* Meta rows */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
        <MetaRow icon="apartment" primary={booking.property} secondary={booking.unit} />
        <MetaRow icon="event" primary={`${booking.checkIn} – ${booking.checkOut}`} badge={`${booking.nights} noći`} />
        <MetaRow icon="group" primary={`${booking.guests} ${booking.guests === 1 ? 'gost' : 'gosta'}`} secondary={booking.source} />
      </div>

      {/* Money */}
      <PaymentBlock booking={booking} compact={compact} />
    </div>

    {/* Footer: actions for pending, chevron for others */}
    {booking.status === 'pending' ? (
      <div style={{
        display: 'flex', gap: 8, padding: '12px 16px',
        borderTop: '1px solid var(--bb-border-subtle)',
        background: 'var(--bb-surface-variant)',
      }}>
        <BBButton variant="primary" iconLeft="check" fullWidth size="sm">Odobri</BBButton>
        <BBButton variant="destructive-soft" iconLeft="close" fullWidth size="sm">Odbij</BBButton>
        <BBButton variant="secondary" asIcon size="sm" iconLeft="more_horiz" ariaLabel="Više akcija" />
      </div>
    ) : (
      <button type="button" style={{
        width: '100%', padding: '12px 20px',
        border: 'none', background: 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        borderTop: '1px solid var(--bb-border-subtle)',
        color: 'var(--bb-primary)', fontWeight: 600, fontSize: 13,
        cursor: 'pointer',
      }}>
        <span>Pregledaj detalje</span>
        <BBIcon name="arrow_forward" size={18} />
      </button>
    )}
  </BBCard>
);

const MetaRow = ({ icon, primary, secondary, badge }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
    <BBIcon name={icon} size={16} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }} />
    <div style={{ flex: 1, minWidth: 0, display: 'flex', alignItems: 'baseline', gap: 6 }}>
      <span className="bb-body" style={{ color: 'var(--bb-text-primary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{primary}</span>
      {secondary && <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>· {secondary}</span>}
    </div>
    {badge && (
      <span style={{
        background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
        padding: '2px 8px', borderRadius: 999, fontSize: 11, fontWeight: 600,
      }}>{badge}</span>
    )}
  </div>
);

const MoneyCol = ({ label, value, strong = false, tone }) => {
  const toneColor = tone === 'success' ? 'var(--bb-success)' : tone === 'warning' ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-primary)';
  return (
    <div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, fontSize: 10 }}>{label}</div>
      <div className="bb-tnum" style={{ marginTop: 2, fontSize: 15, fontWeight: strong ? 700 : 600, color: toneColor }}>{value}</div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// REZERVACIJE — MOBILE (390 × 880)
// ──────────────────────────────────────────────────────────────
const RezervacijeMobile = () => {
  const [tab, setTab] = useS('pending');
  return (
    <div className="theme-light bb-screen" style={{
      width: 390, height: 880,
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
      display: 'flex', flexDirection: 'column',
    }}>
      <BBAppBar title="Rezervacije" showHamburger notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} />
      <main style={{ flex: 1, padding: '8px 16px 0', overflow: 'hidden' }}>
        {/* Filters */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
          <BBButton variant="secondary" iconLeft="tune" size="sm" fullWidth>Filteri</BBButton>
          <BBButton variant="secondary" iconLeft="calendar_today" size="sm" fullWidth>Razdoblje</BBButton>
        </div>

        {/* Tabs wrap */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 10, flexWrap: 'wrap' }}>
          <BBChip selected={tab === 'pending'} size="sm" onClick={() => setTab('pending')} dotColor="#FFB84D" count={1} countColor={tab === 'pending' ? null : '#FFB84D'}>Na čekanju</BBChip>
          <BBChip selected={tab === 'all'} size="sm" onClick={() => setTab('all')}>Sve</BBChip>
          <BBChip selected={tab === 'confirmed'} size="sm" onClick={() => setTab('confirmed')} dotColor="#2E7D5B">Potvrđene</BBChip>
          <BBChip selected={tab === 'completed'} size="sm" onClick={() => setTab('completed')} dotColor="#6B4CE6">Završene</BBChip>
        </div>

        {/* List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {BOOKINGS.slice(0, 2).map(b => <BookingCard key={b.id} booking={b} compact />)}
        </div>
      </main>
    </div>
  );
};

Object.assign(window, {
  PregledDesktop,
  PregledMobile,
  PregledTablet,
  RezervacijeDesktop,
  RezervacijeMobile,
  RezervacijeTablet,
});

// ──────────────────────────────────────────────────────────────
// PREGLED — TABLET (768 × 1024)
// ──────────────────────────────────────────────────────────────
function PregledTablet() {
  const [range, setR] = useS('30');
  return (
    <div className="theme-light bb-screen" style={{
      width: 768, height: 1024, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebarRail active="pregled" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar title="Pregled" notifCount={6} actions={[
          { icon: 'search', label: 'Pretraži' },
          { icon: 'light_mode', label: 'Tema' },
        ]} />
        <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <div>
              <h2 className="bb-h2" style={{ margin: 0 }}>Dobro jutro, Ivana</h2>
              <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>Zadnjih 30 dana.</p>
            </div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {[{id:'7',l:'7 dana'},{id:'30',l:'30 dana'},{id:'90',l:'90 dana'},{id:'year',l:'Godina'}].map(c => (
                <BBChip key={c.id} selected={range===c.id} size="sm" onClick={()=>setR(c.id)}>{c.l}</BBChip>
              ))}
            </div>
          </div>

          {/* Compact revenue hero */}
          <div style={{
            background: 'var(--bb-gradient-hero)',
            borderRadius: 'var(--bb-radius-xl)',
            padding: 24, color: '#FFFFFF',
            boxShadow: 'var(--bb-shadow-purple)',
            position: 'relative', overflow: 'hidden',
            marginBottom: 14,
          }}>
            <div style={{
              position: 'absolute', top: -80, right: -60, width: 260, height: 260,
              borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0) 70%)',
            }} />
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', position: 'relative' }}>
              <div style={{ flex: 1 }}>
                <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.8)' }}>Zarada · 30 dana</div>
                <div style={{ fontSize: 40, fontWeight: 800, letterSpacing: '-0.025em', marginTop: 6 }} className="bb-tnum">€3.840</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
                  <span style={{
                    background: 'rgba(79,174,127,0.32)', color: '#FFFFFF',
                    padding: '4px 10px', borderRadius: 999, fontSize: 12, fontWeight: 600,
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                  }}>
                    <BBIcon name="trending_up" size={14} />
                    <span className="bb-tnum">+12,4%</span>
                  </span>
                  <span className="bb-caption" style={{ color: 'rgba(255,255,255,0.78)' }}>vs. prethodno razdoblje</span>
                </div>
              </div>
              <HeroAreaChart data={SPARK_DATA} width={220} height={72} accent="#FFFFFF" />
            </div>
          </div>

          <PendingStrip count={1} />
          <MetricsRow />
          <ActivitySection />
        </main>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// REZERVACIJE — TABLET (768 × 1024)
// ──────────────────────────────────────────────────────────────
function RezervacijeTablet() {
  const [tab, setT] = useS('pending');
  return (
    <div className="theme-light bb-screen" style={{
      width: 768, height: 1024, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebarRail active="rezervacije" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar title="Rezervacije" notifCount={6} actions={[
          { icon: 'view_module', label: 'Kartice' },
          { icon: 'view_list', label: 'Tablica' },
        ]} />
        <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
            <BBInput placeholder="Pretraži…" iconLeft="search" style={{ flex: 1 }} />
            <BBButton variant="secondary" iconLeft="tune">Filteri</BBButton>
            <BBButton variant="primary" iconLeft="add">Nova</BBButton>
          </div>

          <div style={{ display: 'flex', gap: 8, marginBottom: 16, flexWrap: 'wrap' }}>
            <BBChip selected={tab==='pending'} onClick={()=>setT('pending')} dotColor="#FFB84D" count={1} countColor={tab==='pending'?null:'#FFB84D'}>Na čekanju</BBChip>
            <BBChip selected={tab==='all'} onClick={()=>setT('all')}>Sve</BBChip>
            <BBChip selected={tab==='confirmed'} onClick={()=>setT('confirmed')} dotColor="#2E7D5B">Potvrđene</BBChip>
            <BBChip selected={tab==='completed'} onClick={()=>setT('completed')} dotColor="#6B4CE6">Završene</BBChip>
            <BBChip selected={tab==='cancelled'} onClick={()=>setT('cancelled')} dotColor="#718096">Otkazane</BBChip>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14 }}>
            {BOOKINGS.map(b => <BookingCard key={b.id} booking={b} compact />)}
          </div>
        </main>
      </div>
    </div>
  );
}
