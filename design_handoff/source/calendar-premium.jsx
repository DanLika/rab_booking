/* eslint-disable */
// Kalendar · Premium 2026 chrome — Timeline view. CHROME ONLY: the FROZEN TimelineGrid /
// MobileTimeline / BookingBlock (cell dims 50/42/100/60, parallelogram geometry, z-order)
// are reused VERBATIM from calendar-timeline.jsx via window — never restructured here.
// Premium language is applied to the surrounding chrome: eyebrow header, segmented view
// switch, occupancy KPI strip, refined legend, soft-shadow grid card. Loads AFTER
// calendar-timeline.jsx (needs its exposed grid) + screens.jsx (SAMPLE_USER). Fixed heights
// match the classic Timeline so the Classic↔Premium VariantFrame toggle lines up.

const CALP_SHADOW = '0 1px 2px rgba(16,24,40,0.04), 0 4px 10px -2px rgba(16,24,40,0.06), 0 20px 40px -16px rgba(16,24,40,0.10)';
const CALP_SHADOW_SM = '0 1px 2px rgba(16,24,40,0.04), 0 2px 6px -1px rgba(16,24,40,0.06)';
const CALP_MONTH = 'Lipanj 2026';
const { PV_SHELL_BG, PV_TRANSPARENT_CHROME } = window;

const CALPEyebrow = ({ children, style = {} }) => (
  <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--bb-text-tertiary)', ...style }}>{children}</div>
);

// Segmented view switch (Timeline | Mjesečni)
const CALPViewSwitch = ({ size = 'md' }) => {
  const pad = size === 'sm' ? '6px 12px' : '8px 14px';
  return (
    <div style={{ display: 'inline-flex', padding: 4, gap: 2, background: 'var(--bb-surface-variant)', borderRadius: 999, border: '1px solid var(--bb-border-subtle)' }}>
      {[['view_timeline', 'Timeline', true], ['calendar_view_month', 'Mjesečni', false]].map(([icon, label, on]) => (
        <button key={label} type="button" style={{
          display: 'inline-flex', alignItems: 'center', gap: 6, padding: pad, border: 'none', cursor: 'pointer', borderRadius: 999,
          background: on ? 'var(--bb-surface)' : 'transparent', color: on ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
          fontFamily: 'var(--bb-font-sans)', fontSize: size === 'sm' ? 12 : 13, fontWeight: 600,
          boxShadow: on ? CALP_SHADOW_SM : 'none',
        }}>
          <span className="material-symbols-rounded" style={{ fontSize: size === 'sm' ? 16 : 18, fontVariationSettings: `'FILL' ${on ? 1 : 0}, 'wght' 600` }}>{icon}</span>
          {label}
        </button>
      ))}
    </div>
  );
};

// Premium month nav
const CALPMonthNav = ({ compact = false }) => (
  <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
    <BBButton variant="secondary" asIcon size={compact ? 'sm' : 'md'} iconLeft="chevron_left" ariaLabel="Prethodni mjesec" />
    <div style={{
      minWidth: compact ? 150 : 180, height: compact ? 36 : 44, padding: '0 16px',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', borderRadius: 'var(--bb-radius-sm)',
      boxShadow: CALP_SHADOW_SM, color: 'var(--bb-text-primary)', fontWeight: 700, fontSize: compact ? 13 : 14,
    }}>
      <BBIcon name="calendar_today" size={compact ? 14 : 16} style={{ color: 'var(--bb-primary)' }} />
      <span>{CALP_MONTH}</span>
    </div>
    <BBButton variant="secondary" asIcon size={compact ? 'sm' : 'md'} iconLeft="chevron_right" ariaLabel="Sljedeći mjesec" />
  </div>
);

// Occupancy KPI strip (premium chrome — NOT the frozen grid)
const CALP_KPIS = [
  { icon: 'donut_large', tone: 'primary',  label: 'Popunjenost', value: '78%' },
  { icon: 'receipt_long', tone: 'info',     label: 'Rezervacije', value: '6' },
  { icon: 'login',        tone: 'success',  label: 'Dolasci · 7d', value: '3' },
  { icon: 'hotel',        tone: 'tertiary', label: 'Slobodne noći', value: '26' },
];
const CALP_TONES = {
  primary:  { bg: 'var(--bb-primary-tint-bg)', fg: 'var(--bb-primary)' },
  success:  { bg: 'var(--bb-success-tint)',    fg: 'var(--bb-success)' },
  info:     { bg: 'var(--bb-info-tint)',       fg: 'var(--bb-info)' },
  tertiary: { bg: 'var(--bb-tertiary-tint)',   fg: 'var(--bb-tertiary-dark)' },
};
const CALPKpi = ({ k, compact = false }) => {
  const t = CALP_TONES[k.tone];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: compact ? '10px 12px' : '12px 16px', background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-md)', boxShadow: CALP_SHADOW_SM }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <BBIcon name={k.icon} size={19} />
      </div>
      <div style={{ minWidth: 0 }}>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 600, fontSize: 10, whiteSpace: 'nowrap' }}>{k.label}</div>
        <div className="bb-tnum" style={{ fontSize: compact ? 20 : 24, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1.1 }}>{k.value}</div>
      </div>
    </div>
  );
};

// Premium grid card (legend header + FROZEN grid)
const CALPGridCard = ({ children, legendSize = 'md' }) => (
  <div style={{ background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-md)', boxShadow: CALP_SHADOW, overflow: 'hidden' }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap', padding: legendSize === 'sm' ? '10px 12px' : '12px 16px', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <CALPEyebrow>Status</CALPEyebrow>
      <BBStatusBadge status="confirmed" size={legendSize} />
      <BBStatusBadge status="pending" size={legendSize} />
      <BBStatusBadge status="completed" size={legendSize} />
      <BBStatusBadge status="cancelled" size={legendSize} />
      <BBStatusBadge status="imported" size={legendSize} />
      <div style={{ flex: 1 }} />
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>6 rezervacija · 4 jedinice</span>
    </div>
    {/* grid sits flush; it carries its own inner border via the frozen component */}
    <div style={{ padding: 1, background: 'var(--bb-surface)' }}>{children}</div>
  </div>
);

const CALPFab = ({ size = 56 }) => (
  <button type="button" aria-label="Nova rezervacija" style={{
    position: 'absolute', bottom: size === 56 ? 32 : 24, right: size === 56 ? 32 : 24,
    width: size, height: size, borderRadius: '50%', background: 'var(--bb-primary)', color: '#FFFFFF',
    border: 'none', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    boxShadow: 'var(--bb-shadow-purple)',
  }}>
    <BBIcon name="add" size={size === 56 ? 28 : 24} />
  </button>
);

// ──────────────────────────────────────────────────────────────
// Desktop (1440 × 1100) — fixed, matches classic
// ──────────────────────────────────────────────────────────────
const CalendarPremiumDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, height: 1100, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="kalendar-timeline" pendingCount={2} notifCount={6} style={PV_TRANSPARENT_CHROME} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
      <BBAppBar breadcrumb={['Početna', 'Kalendar']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
      <main style={{ padding: '24px 32px 32px', flex: 1, display: 'flex', flexDirection: 'column', gap: 16, minHeight: 0 }}>
        {/* header */}
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div>
            <CALPEyebrow style={{ color: 'var(--bb-primary)' }}>Lipanj 2026 · 4 jedinice</CALPEyebrow>
            <h1 style={{ margin: '6px 0 0', fontSize: 30, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Kalendar</h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <CALPViewSwitch />
            <BBButton variant="secondary" iconLeft="tune">Filteri</BBButton>
            <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
          </div>
        </div>
        {/* controls */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <CALPMonthNav />
          <BBButton variant="secondary" iconLeft="today">Danas</BBButton>
          <BBButton variant="tertiary" iconLeft="event">Idi na…</BBButton>
          <div style={{ flex: 1 }} />
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Prikaz cijelog mjeseca</span>
        </div>
        {/* KPI strip */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {CALP_KPIS.map((k, i) => <CALPKpi key={i} k={k} />)}
        </div>
        {/* FROZEN grid in premium card */}
        <CALPGridCard>
          <TimelineGrid dayW={30} labelW={196} rowH={60} days={30} units={TIMELINE_UNITS} bookings={TIMELINE_BOOKINGS} today={28} />
        </CALPGridCard>
      </main>
      <CALPFab />
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Tablet (768 × 1024) — fixed
// ──────────────────────────────────────────────────────────────
function CalendarPremiumTablet() {
  return (
    <div className="theme-light bb-screen" style={{ width: 768, height: 1024, display: 'flex', background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebarRail active="kalendar-timeline" pendingCount={2} notifCount={6} style={PV_TRANSPARENT_CHROME} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
        <BBAppBar breadcrumb={['Početna', 'Kalendar']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} style={PV_TRANSPARENT_CHROME} />
        <main style={{ padding: '18px 20px 20px', flex: 1, display: 'flex', flexDirection: 'column', gap: 12, minHeight: 0 }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
            <div>
              <CALPEyebrow style={{ color: 'var(--bb-primary)' }}>Lipanj 2026</CALPEyebrow>
              <h1 style={{ margin: '4px 0 0', fontSize: 24, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Kalendar</h1>
            </div>
            <CALPViewSwitch size="sm" />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
            <CALPMonthNav compact />
            <BBButton variant="secondary" size="sm" iconLeft="today">Danas</BBButton>
            <div style={{ flex: 1 }} />
            <BBButton variant="secondary" size="sm" iconLeft="tune">Filteri</BBButton>
            <BBButton variant="primary" size="sm" iconLeft="add">Nova</BBButton>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 10 }}>
            {CALP_KPIS.map((k, i) => <CALPKpi key={i} k={k} compact />)}
          </div>
          <CALPGridCard legendSize="sm">
            <TimelineGrid dayW={22} labelW={156} rowH={56} days={30} units={TIMELINE_UNITS} bookings={TIMELINE_BOOKINGS} today={28} />
          </CALPGridCard>
        </main>
        <CALPFab size={52} />
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Mobile (390 × 880) — fixed
// ──────────────────────────────────────────────────────────────
function CalendarPremiumMobile() {
  return (
    <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: PV_SHELL_BG, fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column', position: 'relative' }}>
      <BBAppBar title="Kalendar" showHamburger notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} style={PV_TRANSPARENT_CHROME} />
      <main style={{ padding: '14px 16px 0', flex: 1, display: 'flex', flexDirection: 'column', gap: 10, minHeight: 0 }}>
        <div>
          <CALPEyebrow style={{ color: 'var(--bb-primary)' }}>Lipanj 2026</CALPEyebrow>
          <h1 style={{ margin: '4px 0 0', fontSize: 22, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Kalendar</h1>
        </div>
        <CALPViewSwitch size="sm" />
        <CALPMonthNav compact />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8 }}>
          {CALP_KPIS.slice(0, 2).map((k, i) => <CALPKpi key={i} k={k} compact />)}
        </div>
        <div style={{ flex: 1, minHeight: 0, position: 'relative' }}>
          <div style={{ background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-md)', boxShadow: CALP_SHADOW, overflow: 'hidden', height: '100%', position: 'relative' }}>
            <div style={{ position: 'absolute', top: 6, right: 6, zIndex: 2, width: 22, height: 22, borderRadius: '50%', background: 'var(--bb-surface-variant)', color: 'var(--bb-text-tertiary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
              <BBIcon name="chevron_right" size={14} />
            </div>
            <MobileTimeline dayW={28} labelW={100} rowH={56} visibleDays={10} startOffset={5} units={TIMELINE_UNITS.slice(0, 3)} bookings={TIMELINE_BOOKINGS} today={9} />
          </div>
        </div>
      </main>
      <CALPFab size={52} />
    </div>
  );
}

Object.assign(window, { CalendarPremiumDesktop, CalendarPremiumTablet, CalendarPremiumMobile });
