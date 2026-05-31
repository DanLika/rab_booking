/* eslint-disable */
// Rezervacije · Premium 2026 — flagship bookings command center.
// Carries the Premium dashboard language into the bookings surface: soft layered cards,
// eyebrow-date header, segmented period pill, signature AI nudge, sparkline KPI summary,
// a PENDING PRIORITY QUEUE (north-star action items), and a premium bookings LEDGER table
// with inline payment progress + status pills + quick actions. Calm, hierarchy-driven.
// Reuses SAMPLE_USER / SPARK_DATA globals + BB primitives. Loads AFTER screens.jsx.

const RZP_SHADOW = '0 1px 2px rgba(16,24,40,0.04), 0 4px 10px -2px rgba(16,24,40,0.06), 0 24px 48px -16px rgba(16,24,40,0.10)';
const RZP_SHADOW_SM = '0 1px 2px rgba(16,24,40,0.04), 0 2px 6px -1px rgba(16,24,40,0.06)';

const rzpEur = (n) => `€${Number(n).toLocaleString('hr-HR')}`;
const rzpEur2 = (n) => `€${Number(n).toFixed(2).replace('.', ',')}`;

// ── Extended booking ledger (premium needs a fuller table) ──
const RZP_BOOKINGS = [
  { id: 'BB-2403', guestName: 'Petra Jurić',     guestEmail: 'petra.juric@gmail.com',   property: 'Stan Lavanda', unit: 'Apartman A',    checkIn: '18.07', checkOut: '22.07', range: '18.–22. srp', nights: 4, guests: 2, status: 'pending',   total: 520, paid: 104, remaining: 416, source: 'Booking.com', wait: 'prije 3 h' },
  { id: 'BB-2402', guestName: 'Marko Horvat',    guestEmail: 'marko.horvat@gmail.com',  property: 'Vila Marina',  unit: 'Studio 4',      checkIn: '08.07', checkOut: '11.07', range: '8.–11. srp',  nights: 3, guests: 2, status: 'pending',   total: 360, paid: 72,  remaining: 288, source: 'Direktno',    wait: 'prije 14 h' },
  { id: 'BB-2405', guestName: 'Ivan Perić',      guestEmail: 'ivan.peric@me.com',       property: 'Vila Marina',  unit: 'Premium suite', checkIn: '15.07', checkOut: '20.07', range: '15.–20. srp', nights: 5, guests: 2, status: 'confirmed', total: 900, paid: 180, remaining: 720, source: 'Direktno' },
  { id: 'BB-2398', guestName: 'Sandra Kovač',    guestEmail: 'sandra.kovac@outlook.com', property: 'Stan Lavanda', unit: 'Apartman A',   checkIn: '12.07', checkOut: '15.07', range: '12.–15. srp', nights: 3, guests: 4, status: 'confirmed', total: 420, paid: 420, remaining: 0,   source: 'Direktno' },
  { id: 'BB-2410', guestName: 'Tomislav Vukić',  guestEmail: 't.vukic@gmail.com',       property: 'Stan Lavanda', unit: 'Studio B',      checkIn: '25.07', checkOut: '28.07', range: '25.–28. srp', nights: 3, guests: 2, status: 'imported',  total: 330, paid: 0,   remaining: 330, source: 'Booking.com' },
  { id: 'BB-2391', guestName: 'Luka Babić',      guestEmail: 'l.babic@me.com',          property: 'Vila Marina',  unit: 'Premium suite', checkIn: '24.04', checkOut: '27.04', range: '24.–27. tra', nights: 3, guests: 2, status: 'completed', total: 540, paid: 540, remaining: 0,   source: 'Direktno' },
  { id: 'BB-2385', guestName: 'Eva Novak',       guestEmail: 'eva.novak@gmail.com',     property: 'Stan Lavanda', unit: 'Apartman A',    checkIn: '09.05', checkOut: '12.05', range: '9.–12. svi',  nights: 3, guests: 3, status: 'completed', total: 300, paid: 300, remaining: 0,   source: 'Booking.com' },
  { id: 'BB-2380', guestName: 'Ana Šimić',       guestEmail: 'ana.simic@gmail.com',     property: 'Vila Marina',  unit: 'Studio 4',      checkIn: '02.05', checkOut: '05.05', range: '2.–5. svi',   nights: 3, guests: 2, status: 'cancelled', total: 0,   paid: 0,   remaining: 0,   source: 'Airbnb' },
];
const RZP_PENDING = RZP_BOOKINGS.filter(b => b.status === 'pending');

// ──────────────────────────────────────────────────────────────
// Local premium primitives (RZP-prefixed to avoid scope collisions)
// ──────────────────────────────────────────────────────────────
const RZPCard = ({ children, pad = 24, className = '', style = {} }) => (
  <div className={className} style={{
    background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)',
    borderRadius: 'var(--bb-radius-md)', boxShadow: RZP_SHADOW, padding: pad, ...style,
  }}>{children}</div>
);

const RZPEyebrow = ({ children, style = {} }) => (
  <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--bb-text-tertiary)', ...style }}>{children}</div>
);

const RZPDelta = ({ value, positive = true, subtle = false }) => (
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

const rzpSmooth = (pts) => {
  let d = `M ${pts[0][0]} ${pts[0][1]}`;
  for (let i = 1; i < pts.length; i++) {
    const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
    const cx = (x0 + x1) / 2;
    d += ` C ${cx} ${y0} ${cx} ${y1} ${x1} ${y1}`;
  }
  return d;
};

const RZPSpark = ({ data, width = 92, height = 32, color = 'var(--bb-primary)' }) => {
  const max = Math.max(...data), min = Math.min(...data);
  const n = data.length;
  const xs = (i) => (i / (n - 1)) * width;
  const ys = (v) => height - 3 - ((v - min) / (max - min || 1)) * (height - 6);
  const pts = data.map((v, i) => [xs(i), ys(v)]);
  const line = rzpSmooth(pts);
  const gid = 'rzpspk' + Math.round(data[0] * 97 + data.length * 13 + max);
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

// Segmented period pill (matches premium dashboard)
const RZPPeriod = () => (
  <div style={{ display: 'inline-flex', padding: 4, background: 'var(--bb-surface-variant)', borderRadius: 999, border: '1px solid var(--bb-border-subtle)' }}>
    {['7 dana', '30 dana', '90 dana', 'Godina'].map((l, i) => (
      <button key={i} type="button" style={{
        padding: '7px 14px', border: 'none', cursor: 'pointer', borderRadius: 999,
        background: i === 1 ? 'var(--bb-surface)' : 'transparent',
        color: i === 1 ? 'var(--bb-text-primary)' : 'var(--bb-text-secondary)',
        fontFamily: 'var(--bb-font-sans)', fontSize: 13, fontWeight: 600,
        boxShadow: i === 1 ? RZP_SHADOW_SM : 'none',
      }}>{l}</button>
    ))}
  </div>
);

// ──────────────────────────────────────────────────────────────
// KPI summary cards
// ──────────────────────────────────────────────────────────────
const RZP_TONES = {
  primary:  { bg: 'var(--bb-primary-tint-bg)', fg: 'var(--bb-primary)' },
  success:  { bg: 'var(--bb-success-tint)',    fg: 'var(--bb-success)' },
  info:     { bg: 'var(--bb-info-tint)',       fg: 'var(--bb-info)' },
  tertiary: { bg: 'var(--bb-tertiary-tint)',   fg: 'var(--bb-tertiary-dark)' },
};

const RZPStatCard = ({ icon, iconTone = 'primary', label, value, delta, positive = true, spark, sparkColor, sub, compact = false }) => {
  const t = RZP_TONES[iconTone] || RZP_TONES.primary;
  return (
    <RZPCard pad={20} className="bb-lift" style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name={icon} size={19} />
        </div>
        {delta && <RZPDelta value={delta} positive={positive} subtle />}
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, marginTop: 16, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 10, marginTop: 4 }}>
        <span className="bb-tnum" style={{ fontSize: compact ? 26 : 30, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1 }}>{value}</span>
        {spark && <RZPSpark data={spark} color={sparkColor || t.fg} width={compact ? 56 : 88} />}
      </div>
      {sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 8 }}>{sub}</div>}
    </RZPCard>
  );
};

const RZPStatStrip = ({ cols = 4, compact = false }) => (
  <div style={{ display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: compact ? 12 : 16 }}>
    <RZPStatCard icon="pending_actions" iconTone="tertiary" label="Na čekanju" value="2" sub="€880 vrijednost · čeka odgovor" compact={compact} />
    <RZPStatCard icon="event_available" iconTone="success" label="Potvrđeno (mj.)" value="9" delta="+3" positive spark={[4,5,5,6,7,6,8,9]} sparkColor="var(--bb-success)" compact={compact} />
    <RZPStatCard icon="payments" iconTone="primary" label="Zarada (mj.)" value="€3.840" delta="+12,4%" positive spark={SPARK_DATA.slice(-9)} compact={compact} />
    <RZPStatCard icon="login" iconTone="info" label="Nadolazeći dolasci" value="4" sub="sljedećih 7 dana" compact={compact} />
  </div>
);

// ──────────────────────────────────────────────────────────────
// AI nudge — bookings-specific (respond faster → more confirmations)
// ──────────────────────────────────────────────────────────────
const RZPAINudge = ({ compact = false }) => (
  <div className="bb-lift" style={{
    position: 'relative', overflow: 'hidden', borderRadius: 'var(--bb-radius-md)',
    background: 'linear-gradient(105deg, rgba(255,184,77,0.12) 0%, rgba(107,76,230,0.06) 55%, rgba(61,217,176,0.07) 100%)',
    border: '1px solid rgba(255,184,77,0.30)', boxShadow: RZP_SHADOW_SM,
    padding: compact ? 16 : '18px 22px',
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
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Prioritet danas</span>
        </div>
        <div className="bb-body" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: compact ? 14 : 15 }}>
          <span className="bb-tnum">Markova</span> rezervacija čeka odgovor <span style={{ color: 'var(--bb-tertiary-dark)' }}>14 sati</span>. Gosti s odgovorom unutar sat vremena <span style={{ color: 'var(--bb-success)' }}>30%</span> češće potvrde — odgovorite sada da ne izgubite termin.
        </div>
      </div>
    </div>
    <div style={{ display: 'flex', gap: 8, flexShrink: 0, width: compact ? '100%' : 'auto', paddingLeft: compact ? 58 : 0 }}>
      {!compact && <BBButton variant="secondary" size="sm">Kasnije</BBButton>}
      <BBButton variant="primary" size="sm" iconRight="arrow_forward" style={compact ? { flex: 1 } : {}}>Odgovori</BBButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pending priority queue — the north-star action items
// ──────────────────────────────────────────────────────────────
const RZPStayFact = ({ icon, children }) => (
  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: 'var(--bb-text-secondary)' }}>
    <BBIcon name={icon} size={16} style={{ color: 'var(--bb-text-tertiary)' }} />
    <span className="bb-body" style={{ fontWeight: 500 }}>{children}</span>
  </span>
);

const RZPPendingCard = ({ b }) => {
  const pct = b.total ? Math.round((b.paid / b.total) * 100) : 0;
  return (
    <RZPCard pad={0} className="bb-lift" style={{ overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
      {/* amber priority rail header */}
      <div style={{ height: 4, background: 'linear-gradient(90deg, var(--bb-tertiary) 0%, #FFD08A 100%)' }} />
      <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 16, flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <BBStatusBadge status="pending" />
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, color: 'var(--bb-tertiary-dark)' }}>
            <BBIcon name="schedule" size={15} />
            <span className="bb-caption" style={{ fontWeight: 600 }}>{b.wait}</span>
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <BBAvatar name={b.guestName} size="md" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-h3" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{b.guestName}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.guestEmail} · <span className="bb-mono">#{b.id}</span></div>
          </div>
        </div>

        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px 20px' }}>
          <RZPStayFact icon="apartment">{b.property} · {b.unit}</RZPStayFact>
          <RZPStayFact icon="event">{b.range}</RZPStayFact>
          <RZPStayFact icon="group">{b.guests} gosta · {b.nights} noći</RZPStayFact>
          <RZPStayFact icon="sell">{b.source}</RZPStayFact>
        </div>

        {/* payment line */}
        <div style={{ background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)', padding: '12px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600, fontSize: 10 }}>Polog plaćen</span>
            <span className="bb-tnum" style={{ fontSize: 14 }}>
              <span style={{ fontWeight: 700, color: 'var(--bb-text-primary)' }}>{rzpEur2(b.paid)}</span>
              <span style={{ color: 'var(--bb-text-tertiary)', fontWeight: 500 }}> / {rzpEur2(b.total)}</span>
            </span>
          </div>
          <div style={{ height: 8, borderRadius: 999, background: 'var(--bb-border-subtle)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${pct}%`, borderRadius: 999, background: 'linear-gradient(90deg, var(--bb-success) 0%, #4FAE7F 100%)' }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Preostalo na dolasku</span>
            <span className="bb-caption bb-tnum" style={{ fontWeight: 600, color: 'var(--bb-tertiary-dark)' }}>{rzpEur2(b.remaining)}</span>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, marginTop: 'auto' }}>
          <BBButton variant="primary" iconLeft="check" size="md" style={{ flex: 1 }}>Odobri</BBButton>
          <BBButton variant="destructive-soft" iconLeft="close" size="md" style={{ flex: 1 }}>Odbij</BBButton>
          <BBButton variant="secondary" asIcon size="md" iconLeft="more_horiz" ariaLabel="Više akcija" />
        </div>
      </div>
    </RZPCard>
  );
};

const RZPPendingQueue = ({ cols = 2 }) => (
  <div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
      <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--bb-tertiary)' }} />
      <h2 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Zahtijeva vašu pažnju</h2>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{RZP_PENDING.length}</span>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 16 }}>
      {RZP_PENDING.map(b => <RZPPendingCard key={b.id} b={b} />)}
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Status tabs (segmented) + bookings ledger table
// ──────────────────────────────────────────────────────────────
const RZP_TABS = [
  { id: 'all', label: 'Sve', count: RZP_BOOKINGS.length },
  { id: 'pending', label: 'Na čekanju', count: 2, dot: '#FFB84D' },
  { id: 'confirmed', label: 'Potvrđene', count: 2, dot: '#2E7D5B' },
  { id: 'completed', label: 'Završene', count: 2, dot: '#6B4CE6' },
  { id: 'cancelled', label: 'Otkazane', count: 1, dot: '#718096' },
  { id: 'imported', label: 'Uvezene', count: 1, dot: '#4A90D9' },
];

const RZPTabs = ({ active, onSelect }) => (
  <div style={{ display: 'inline-flex', padding: 4, background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)', border: '1px solid var(--bb-border-subtle)', flexWrap: 'wrap', gap: 2 }}>
    {RZP_TABS.map(t => {
      const sel = active === t.id;
      return (
        <button key={t.id} type="button" onClick={() => onSelect?.(t.id)} style={{
          display: 'inline-flex', alignItems: 'center', gap: 7,
          padding: '8px 14px', border: 'none', cursor: 'pointer', borderRadius: 9,
          background: sel ? 'var(--bb-surface)' : 'transparent',
          color: sel ? 'var(--bb-text-primary)' : 'var(--bb-text-secondary)',
          fontFamily: 'var(--bb-font-sans)', fontSize: 13, fontWeight: 600,
          boxShadow: sel ? RZP_SHADOW_SM : 'none',
        }}>
          {t.dot && <span style={{ width: 7, height: 7, borderRadius: '50%', background: t.dot }} />}
          <span>{t.label}</span>
          <span className="bb-tnum" style={{
            minWidth: 18, height: 18, padding: '0 5px', borderRadius: 999,
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            background: sel ? 'var(--bb-primary-tint-bg)' : 'var(--bb-border-subtle)',
            color: sel ? 'var(--bb-primary)' : 'var(--bb-text-tertiary)',
            fontSize: 11, fontWeight: 700,
          }}>{t.count}</span>
        </button>
      );
    })}
  </div>
);

// inline payment progress (table cell)
const RZPPayCell = ({ b }) => {
  if (b.status === 'cancelled') return <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>—</span>;
  const pct = b.total ? Math.round((b.paid / b.total) * 100) : 0;
  const full = b.remaining <= 0 && b.total > 0;
  return (
    <div style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 5, gap: 8 }}>
        <span className="bb-caption bb-tnum" style={{ color: full ? 'var(--bb-success)' : 'var(--bb-text-secondary)', fontWeight: 600 }}>
          {full ? 'Plaćeno' : `${rzpEur(b.paid)}`}
        </span>
        {!full && <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{pct}%</span>}
      </div>
      <div style={{ height: 6, borderRadius: 999, background: 'var(--bb-surface-variant)', overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${pct}%`, borderRadius: 999, background: full ? 'var(--bb-success)' : 'linear-gradient(90deg, var(--bb-success) 0%, #4FAE7F 100%)' }} />
      </div>
    </div>
  );
};

const RZP_GRID = 'minmax(0,1.7fr) minmax(0,1.15fr) 150px minmax(110px,1fr) 92px 116px 40px';

const RZPLedgerHeader = () => (
  <div style={{
    display: 'grid', gridTemplateColumns: RZP_GRID, gap: 16, alignItems: 'center',
    padding: '10px 20px', background: 'var(--bb-surface-variant)',
    borderTop: '1px solid var(--bb-border-subtle)', borderBottom: '1px solid var(--bb-border-subtle)',
  }}>
    {['Gost', 'Objekt', 'Termin', 'Plaćanje', 'Iznos', 'Status', ''].map((h, i) => (
      <span key={i} className="bb-caption" style={{
        color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 700, fontSize: 10,
        textAlign: i === 4 ? 'right' : 'left',
      }}>{h}</span>
    ))}
  </div>
);

const RZPLedgerRow = ({ b, last, first }) => (
  <div className="bb-row-hover" style={{
    display: 'grid', gridTemplateColumns: RZP_GRID, gap: 16, alignItems: 'center',
    padding: '14px 20px', borderTop: first ? 'none' : '1px solid var(--bb-border-subtle)',
  }}>
    {/* Gost */}
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, minWidth: 0 }}>
      <BBAvatar name={b.guestName} size="sm" />
      <div style={{ minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.guestName}</div>
        <div className="bb-mono" style={{ color: 'var(--bb-text-tertiary)', fontSize: 11 }}>#{b.id}</div>
      </div>
    </div>
    {/* Objekt */}
    <div style={{ minWidth: 0 }}>
      <div className="bb-body" style={{ color: 'var(--bb-text-primary)', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.property}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.unit}</div>
    </div>
    {/* Termin */}
    <div>
      <div className="bb-body bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 500 }}>{b.range}</div>
      <div className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{b.nights} noći · {b.guests} gosta</div>
    </div>
    {/* Plaćanje */}
    <RZPPayCell b={b} />
    {/* Iznos */}
    <div className="bb-tnum" style={{ textAlign: 'right', fontWeight: 700, fontSize: 15, color: b.status === 'cancelled' ? 'var(--bb-text-tertiary)' : 'var(--bb-text-primary)', textDecoration: b.status === 'cancelled' ? 'line-through' : 'none' }}>{rzpEur(b.total)}</div>
    {/* Status */}
    <div><BBStatusBadge status={b.status} size="sm" /></div>
    {/* Action */}
    <button type="button" aria-label="Detalji" style={{
      width: 32, height: 32, border: 'none', borderRadius: 8, background: 'transparent',
      color: 'var(--bb-text-tertiary)', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name="chevron_right" size={20} />
    </button>
  </div>
);

const RZPLedger = ({ active, onSelect }) => (
  <RZPCard pad={0} style={{ overflow: 'hidden' }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '18px 20px', gap: 16, flexWrap: 'wrap' }}>
      <RZPTabs active={active} onSelect={onSelect} />
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <BBButton variant="secondary" iconLeft="tune" size="sm">Filteri</BBButton>
        <BBButton variant="secondary" iconLeft="swap_vert" size="sm">Sortiraj</BBButton>
      </div>
    </div>
    <div style={{ paddingTop: 0 }}>
      <RZPLedgerHeader />
      {RZP_BOOKINGS.map((b, i) => <RZPLedgerRow key={b.id} b={b} last={i === RZP_BOOKINGS.length - 1} first={i === 0} />)}
    </div>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 20px', borderTop: '1px solid var(--bb-border-subtle)' }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Prikazano <span className="bb-tnum">{RZP_BOOKINGS.length}</span> od <span className="bb-tnum">{RZP_BOOKINGS.length}</span> rezervacija</span>
      <div style={{ display: 'flex', gap: 6 }}>
        <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prethodna" disabled />
        <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Sljedeća" />
      </div>
    </div>
  </RZPCard>
);

// ──────────────────────────────────────────────────────────────
// Mobile booking row (premium list)
// ──────────────────────────────────────────────────────────────
const RZPMobileRow = ({ b, divider }) => (
  <div className="bb-row-hover" style={{
    display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
    borderTop: divider ? '1px solid var(--bb-border-subtle)' : 'none',
  }}>
    <BBAvatar name={b.guestName} size="sm" />
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
        <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.guestName}</span>
        <span className="bb-tnum" style={{ fontWeight: 700, fontSize: 14, color: b.status === 'cancelled' ? 'var(--bb-text-tertiary)' : 'var(--bb-text-primary)', flexShrink: 0 }}>{rzpEur(b.total)}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginTop: 3 }}>
        <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.range} · {b.property}</span>
        <BBStatusBadge status={b.status} size="sm" dot={false} />
      </div>
    </div>
  </div>
);

const { PV_SHELL_BG, PV_PANEL_BG, PV_PANEL_SHADOW, PV_PANEL_RADIUS, PV_TRANSPARENT_CHROME } = window;

// ──────────────────────────────────────────────────────────────
// PAGE — Desktop (1440, auto-height)
// ──────────────────────────────────────────────────────────────
const RezervacijePremiumDesktop = () => {
  const [tab, setTab] = useS('all');
  return (
    <div className="theme-light bb-screen" style={{ width: 1440, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebar user={SAMPLE_USER} active="rezervacije" pendingCount={2} notifCount={6} style={PV_TRANSPARENT_CHROME} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar breadcrumb={['Početna', 'Rezervacije']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
        <div style={{ flex: 1, minWidth: 0, padding: '4px 28px 28px 16px' }}>
        <main style={{ background: PV_PANEL_BG, borderRadius: PV_PANEL_RADIUS, border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW, padding: '28px 32px 36px', display: 'flex', flexDirection: 'column', gap: 20 }}>
          {/* Header */}
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
            <div>
              <RZPEyebrow style={{ color: 'var(--bb-primary)' }}>Subota · 30. svibnja 2026</RZPEyebrow>
              <h1 style={{ margin: '6px 0 0', fontSize: 30, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Rezervacije</h1>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <RZPPeriod />
              <BBButton variant="secondary" iconLeft="download">Izvezi</BBButton>
              <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
            </div>
          </div>

          <RZPStatStrip cols={4} />
          <RZPAINudge />
          <RZPPendingQueue cols={2} />
          <RZPLedger active={tab} onSelect={setTab} />
        </main>
        </div>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// PAGE — Tablet (768, rail, auto-height)
// ──────────────────────────────────────────────────────────────
function RezervacijePremiumTablet() {
  const [tab, setTab] = useS('all');
  return (
    <div className="theme-light bb-screen" style={{ width: 768, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebarRail active="rezervacije" pendingCount={2} notifCount={6} style={PV_TRANSPARENT_CHROME} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar breadcrumb={['Početna', 'Rezervacije']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'view_list', label: 'Tablica' }]} style={PV_TRANSPARENT_CHROME} />
        <div style={{ flex: 1, minWidth: 0, padding: '0 18px 18px 6px' }}>
        <main style={{ background: PV_PANEL_BG, borderRadius: 24, border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW, padding: '22px 24px 28px', display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
            <div>
              <RZPEyebrow style={{ color: 'var(--bb-primary)' }}>Subota · 30. svibnja 2026</RZPEyebrow>
              <h1 style={{ margin: '6px 0 0', fontSize: 26, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Rezervacije</h1>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <RZPPeriod />
              <BBButton variant="primary" iconLeft="add">Nova</BBButton>
            </div>
          </div>

          <RZPStatStrip cols={2} compact />
          <RZPAINudge />
          <RZPPendingQueue cols={1} />

          {/* Tabs (scroll) + condensed booking cards */}
          <div style={{ overflowX: 'auto', paddingBottom: 2 }}><RZPTabs active={tab} onSelect={setTab} /></div>
          <RZPCard pad={0} style={{ overflow: 'hidden' }}>
            {RZP_BOOKINGS.map((b, i) => <RZPMobileRow key={b.id} b={b} divider={i > 0} />)}
          </RZPCard>
        </main>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// PAGE — Mobile (390, app bar, auto-height)
// ──────────────────────────────────────────────────────────────
function RezervacijePremiumMobile() {
  const [tab, setTab] = useS('all');
  return (
    <div className="theme-light bb-screen" style={{ width: 390, background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
      <BBAppBar title="Rezervacije" showHamburger notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} style={PV_TRANSPARENT_CHROME} />
      <div style={{ padding: '0 12px 16px' }}>
      <main style={{ background: PV_PANEL_BG, borderRadius: 24, border: '1px solid var(--bb-panel-border)', boxShadow: PV_PANEL_SHADOW, padding: '16px 16px 24px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div>
          <RZPEyebrow style={{ color: 'var(--bb-primary)' }}>Subota · 30. svibnja</RZPEyebrow>
          <h1 style={{ margin: '6px 0 0', fontSize: 24, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Rezervacije</h1>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
          <RZPStatCard icon="pending_actions" iconTone="tertiary" label="Na čekanju" value="2" sub="€880 vrijednost" compact />
          <RZPStatCard icon="payments" iconTone="primary" label="Zarada (mj.)" value="€3.840" delta="+12,4%" positive spark={SPARK_DATA.slice(-9)} compact />
        </div>

        <RZPAINudge compact />

        {/* Pending priority */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 2 }}>
          <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--bb-tertiary)' }} />
          <h2 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Zahtijeva pažnju</h2>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{RZP_PENDING.length}</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {RZP_PENDING.map(b => <RZPPendingCard key={b.id} b={b} />)}
        </div>

        {/* Tabs + list */}
        <div style={{ overflowX: 'auto', margin: '4px -16px 0', padding: '0 16px' }}><RZPTabs active={tab} onSelect={setTab} /></div>
        <RZPCard pad={0} style={{ overflow: 'hidden' }}>
          {RZP_BOOKINGS.map((b, i) => <RZPMobileRow key={b.id} b={b} divider={i > 0} />)}
        </RZPCard>
      </main>
      </div>
    </div>
  );
}

Object.assign(window, { RezervacijePremiumDesktop, RezervacijePremiumTablet, RezervacijePremiumMobile });
