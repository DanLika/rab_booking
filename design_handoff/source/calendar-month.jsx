/* eslint-disable */
// Calendar · Mjesečni (month view) — Prompt 08.
// Sibling of the Timeline sub-tab. Reuses calendar chrome + shared globals from calendar-timeline.jsx
// (weekdayOf, isWeekend, wkLetters, monthName, daysInMonth, TIMELINE_BOOKINGS, TIMELINE_UNITS, statusBlockColors).
// Month view is its own surface (NOT the frozen Timeline grid) — Google-Calendar-style spanning status bars
// on desktop/tablet, dots + day-agenda on mobile. Monday-start weeks, Croatian.
// MUST load AFTER calendar-timeline.jsx (references its top-level consts at eval time).

const CM_TODAY = 28;       // June 28 = "today"
const CM_SELECTED = 22;    // selected day (mobile agenda)

const CM_BOOKINGS = TIMELINE_BOOKINGS.map(b => ({
  ...b,
  endDay: b.startDay + b.nights - 1,
  unitName: (TIMELINE_UNITS.find(u => u.id === b.unitId) || {}).name || '',
}));

// Build month into Monday-start weeks with per-week lane-packed booking segments
function cmBuildWeeks() {
  const weeks = [];
  const numWeeks = Math.ceil(daysInMonth / 7);
  for (let w = 0; w < numWeeks; w++) {
    const firstDay = w * 7 + 1;
    const weekLastInMonth = Math.min(firstDay + 6, daysInMonth);
    const slots = [];
    for (let c = 0; c < 7; c++) {
      const day = firstDay + c;
      slots.push(day <= daysInMonth ? { day, inMonth: true } : { day: day - daysInMonth, inMonth: false });
    }
    // segments overlapping this week's in-month range
    const segs = [];
    CM_BOOKINGS.forEach(b => {
      const segStart = Math.max(b.startDay, firstDay);
      const segEnd = Math.min(b.endDay, weekLastInMonth);
      if (segStart <= segEnd) {
        segs.push({
          booking: b,
          colStart: segStart - firstDay,
          span: segEnd - segStart + 1,
          contLeft: b.startDay < firstDay,
          contRight: b.endDay > weekLastInMonth,
        });
      }
    });
    // greedy lane packing
    segs.sort((a, b) => a.colStart - b.colStart || b.span - a.span);
    const lanes = [];
    segs.forEach(s => {
      const end = s.colStart + s.span - 1;
      let placed = false;
      for (let li = 0; li < lanes.length; li++) {
        if (!lanes[li].some(o => !(end < o.start || s.colStart > o.end))) {
          lanes[li].push({ start: s.colStart, end });
          s.lane = li; placed = true; break;
        }
      }
      if (!placed) { lanes.push([{ start: s.colStart, end }]); s.lane = lanes.length - 1; }
    });
    weeks.push({ firstDay, slots, segs, laneCount: lanes.length });
  }
  return weeks;
}

// ──────────────────────────────────────────────────────────────
// Shared chrome bits (mirror Timeline)
// ──────────────────────────────────────────────────────────────
const CMSubTabs = ({ size = 'desktop' }) => {
  const sm = size !== 'desktop';
  return (
    <div style={{ display: 'flex', gap: 8, marginBottom: sm ? 10 : 16 }}>
      <BBChip variant="tab" size={sm ? 'sm' : 'md'} iconLeft="view_timeline">Timeline</BBChip>
      <BBChip selected variant="tab" size={sm ? 'sm' : 'md'} iconLeft="calendar_view_month">Mjesečni</BBChip>
    </div>
  );
};

// Premium segmented view switch (matches the Timeline Kalendar chrome) — Mjesečni active
const CMViewSwitch = ({ size = 'md' }) => {
  const pad = size === 'sm' ? '6px 12px' : '8px 14px';
  return (
    <div style={{ display: 'inline-flex', padding: 4, gap: 2, background: 'var(--bb-surface-variant)', borderRadius: 999, border: '1px solid var(--bb-border-subtle)' }}>
      {[['view_timeline', 'Timeline', false], ['calendar_view_month', 'Mjesečni', true]].map(([icon, label, on]) => (
        <button key={label} type="button" style={{
          display: 'inline-flex', alignItems: 'center', gap: 6, padding: pad, border: 'none', cursor: 'pointer', borderRadius: 999,
          background: on ? 'var(--bb-surface)' : 'transparent', color: on ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
          fontFamily: 'var(--bb-font-sans)', fontSize: size === 'sm' ? 12 : 13, fontWeight: 600,
          boxShadow: on ? 'var(--bb-shadow-sm)' : 'none',
        }}>
          <span className="material-symbols-rounded" style={{ fontSize: size === 'sm' ? 16 : 18, fontVariationSettings: `'FILL' ${on ? 1 : 0}, 'wght' 600` }}>{icon}</span>
          {label}
        </button>
      ))}
    </div>
  );
};

// Premium eyebrow + headline + view switch (sibling of the Timeline Kalendar header)
const CMHeader = ({ compact = false }) => (
  <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12, marginBottom: compact ? 12 : 16, flexWrap: 'wrap' }}>
    <div>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--bb-primary)' }}>{monthName} · 4 jedinice</div>
      <h1 style={{ margin: '6px 0 0', fontSize: compact ? 24 : 28, fontWeight: 800, letterSpacing: '-0.025em', color: 'var(--bb-text-primary)' }}>Kalendar</h1>
    </div>
    <CMViewSwitch size={compact ? 'sm' : 'md'} />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Occupancy KPI strip — sibling of the Timeline premium chrome (NOT the grid)
const CM_KPIS = [
  { icon: 'donut_large', tone: 'primary',  label: 'Popunjenost', value: '78%' },
  { icon: 'receipt_long', tone: 'info',     label: 'Rezervacije', value: '6' },
  { icon: 'login',        tone: 'success',  label: 'Dolasci · 7d', value: '3' },
  { icon: 'hotel',        tone: 'tertiary', label: 'Slobodne noći', value: '26' },
];
const CM_TONES = {
  primary:  { bg: 'var(--bb-primary-tint-bg)', fg: 'var(--bb-primary)' },
  success:  { bg: 'var(--bb-success-tint)',    fg: 'var(--bb-success)' },
  info:     { bg: 'var(--bb-info-tint)',       fg: 'var(--bb-info)' },
  tertiary: { bg: 'var(--bb-tertiary-tint)',   fg: 'var(--bb-tertiary-dark)' },
};
const CMKpiStrip = ({ compact = false }) => (
  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: compact ? 8 : 12, marginBottom: compact ? 10 : 14 }}>
    {CM_KPIS.map((k, i) => {
      const t = CM_TONES[k.tone];
      return (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: compact ? 10 : 12, padding: compact ? '9px 11px' : '11px 14px', background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-md)', boxShadow: 'var(--bb-shadow-card)' }}>
          <div style={{ width: compact ? 32 : 36, height: compact ? 32 : 36, borderRadius: 10, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <BBIcon name={k.icon} size={compact ? 18 : 19} />
          </div>
          <div style={{ minWidth: 0 }}>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontWeight: 600, fontSize: 10, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{k.label}</div>
            <div className="bb-tnum" style={{ fontSize: compact ? 19 : 23, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', lineHeight: 1.1 }}>{k.value}</div>
          </div>
        </div>
      );
    })}
  </div>
);

const CMLegend = ({ wrap = false, size = 'md', stat }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: wrap ? 6 : 12, marginBottom: wrap ? 12 : 16,
    flexWrap: wrap ? 'wrap' : 'nowrap',
    padding: wrap ? '8px 10px' : '10px 14px',
    background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-sm)',
  }}>
    {!wrap && <span className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)' }}>Status:</span>}
    <BBStatusBadge status="confirmed" size={size} />
    <BBStatusBadge status="pending" size={size} />
    <BBStatusBadge status="completed" size={size} />
    {!wrap && <BBStatusBadge status="cancelled" size={size} />}
    <BBStatusBadge status="imported" size={size} />
    {stat && <><div style={{ flex: 1 }} /><span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{stat}</span></>}
  </div>
);

// ──────────────────────────────────────────────────────────────
// Month grid (desktop / tablet) — spanning bars
// ──────────────────────────────────────────────────────────────
const cmCellTint = (slot, isToday) => {
  if (!slot.inMonth) return 'var(--bb-surface-variant)';
  if (isToday) return 'var(--bb-primary-tint-bg)';
  if (isWeekend(slot.day)) return 'rgba(255,184,77,0.05)';
  return 'var(--bb-surface)';
};

const CMDayNumber = ({ slot, isToday }) => {
  const muted = !slot.inMonth;
  const wk = slot.inMonth && isWeekend(slot.day);
  if (isToday) {
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        minWidth: 24, height: 24, padding: '0 6px', borderRadius: 999,
        background: 'var(--bb-primary)', color: '#FFFFFF',
        fontSize: 13, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
      }}>{slot.day}</span>
    );
  }
  return (
    <span className="bb-tnum" style={{
      fontSize: 13, fontWeight: 600,
      color: muted ? 'var(--bb-text-disabled)' : wk ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-primary)',
    }}>{slot.day}{!slot.inMonth && slot.day === 1 ? '. srp' : ''}</span>
  );
};

const CMBar = ({ seg, barH }) => {
  const c = statusBlockColors[seg.booking.status] || statusBlockColors.confirmed;
  const radL = seg.contLeft ? 0 : 6;
  const radR = seg.contRight ? 0 : 6;
  return (
    <div style={{
      position: 'absolute',
      left: `calc(${seg.colStart} / 7 * 100% + 4px)`,
      width: `calc(${seg.span} / 7 * 100% - 8px)`,
      top: seg.lane * (barH + 4),
      height: barH,
      background: c.bg, color: c.text,
      borderRadius: `${radL}px ${radR}px ${radR}px ${radL}px`,
      boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.18)',
      display: 'flex', alignItems: 'center', gap: 4,
      padding: '0 8px', overflow: 'hidden',
    }}>
      {seg.contLeft && <BBIcon name="chevron_left" size={13} style={{ marginLeft: -4, opacity: 0.8, flexShrink: 0 }} />}
      <span style={{ fontSize: 11, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>
        {seg.booking.guest}
      </span>
      {seg.span >= 3 && <span className="bb-tnum" style={{ fontSize: 10, fontWeight: 600, opacity: 0.85, flexShrink: 0 }}>{seg.booking.nights}n</span>}
      {seg.contRight && <BBIcon name="chevron_right" size={13} style={{ marginRight: -4, opacity: 0.8, flexShrink: 0 }} />}
    </div>
  );
};

const CMMonthGrid = ({ rowH = 110, barH = 22, headerH = 34 }) => {
  const weeks = cmBuildWeeks();
  const numRowH = 30;
  return (
    <div style={{
      background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)',
      borderRadius: 'var(--bb-radius-md)', overflow: 'hidden', boxShadow: 'var(--bb-shadow-card)',
    }}>
      {/* Weekday header */}
      <div style={{ display: 'flex', height: headerH, background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        {wkLetters.map((d, i) => (
          <div key={d} style={{
            flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
            borderRight: i < 6 ? '1px solid var(--bb-border-subtle)' : 'none',
          }}>
            <span className="bb-eyebrow" style={{ color: i >= 5 ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-tertiary)' }}>{d}</span>
          </div>
        ))}
      </div>
      {/* Weeks */}
      {weeks.map((week, wi) => (
        <div key={wi} style={{ position: 'relative', height: rowH, borderBottom: wi < weeks.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
          {/* Background cells + day numbers */}
          <div style={{ display: 'flex', height: '100%' }}>
            {week.slots.map((slot, c) => {
              const isToday = slot.inMonth && slot.day === CM_TODAY;
              const baseBg = cmCellTint(slot, isToday);
              return (
                <div key={c} style={{
                  flex: 1, borderRight: c < 6 ? '1px solid var(--bb-border-subtle)' : 'none',
                  background: baseBg, padding: '6px 8px',
                  cursor: slot.inMonth ? 'pointer' : 'default',
                  transition: 'background-color .12s ease',
                }}
                onMouseEnter={slot.inMonth ? (e) => { e.currentTarget.style.background = 'var(--bb-primary-tint-bg)'; } : undefined}
                onMouseLeave={slot.inMonth ? (e) => { e.currentTarget.style.background = baseBg; } : undefined}>
                  <CMDayNumber slot={slot} isToday={isToday} />
                </div>
              );
            })}
          </div>
          {/* Booking bars overlay */}
          <div style={{ position: 'absolute', left: 0, right: 0, top: numRowH, bottom: 6 }}>
            {week.segs.map((seg, i) => <CMBar key={i} seg={seg} barH={barH} />)}
          </div>
        </div>
      ))}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Mobile — dots grid + day agenda
// ──────────────────────────────────────────────────────────────
const cmDayBookings = (day) => CM_BOOKINGS.filter(b => b.startDay <= day && b.endDay >= day);

const CMMobileGrid = () => {
  const weeks = cmBuildWeeks();
  return (
    <div style={{
      background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)',
      borderRadius: 'var(--bb-radius-md)', overflow: 'hidden', boxShadow: 'var(--bb-shadow-card)',
    }}>
      <div style={{ display: 'flex', height: 28, background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        {wkLetters.map((d, i) => (
          <div key={d} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.04em', color: i >= 5 ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-tertiary)' }}>{d}</span>
          </div>
        ))}
      </div>
      {weeks.map((week, wi) => (
        <div key={wi} style={{ display: 'flex', borderBottom: wi < weeks.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
          {week.slots.map((slot, c) => {
            const isToday = slot.inMonth && slot.day === CM_TODAY;
            const isSel = slot.inMonth && slot.day === CM_SELECTED;
            const dots = slot.inMonth ? cmDayBookings(slot.day) : [];
            return (
              <div key={c} style={{
                flex: 1, height: 52, borderRight: c < 6 ? '1px solid var(--bb-border-subtle)' : 'none',
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start',
                paddingTop: 6, gap: 4,
                background: isSel ? 'var(--bb-primary-tint-bg)' : (isToday ? 'var(--bb-primary-tint-bg)' : (slot.inMonth && isWeekend(slot.day) ? 'rgba(255,184,77,0.05)' : 'transparent')),
              }}>
                <span style={{
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  width: 22, height: 22, borderRadius: 999,
                  background: isSel ? 'var(--bb-primary)' : 'transparent',
                  border: isToday && !isSel ? '1.5px solid var(--bb-primary)' : 'none',
                  color: isSel ? '#FFFFFF' : (!slot.inMonth ? 'var(--bb-text-disabled)' : isToday ? 'var(--bb-primary)' : 'var(--bb-text-primary)'),
                  fontSize: 12, fontWeight: isSel || isToday ? 700 : 600, fontVariantNumeric: 'tabular-nums',
                }}>{slot.day}</span>
                <div style={{ display: 'flex', gap: 2, height: 5 }}>
                  {dots.slice(0, 3).map((b, i) => (
                    <span key={i} style={{ width: 5, height: 5, borderRadius: '50%', background: (statusBlockColors[b.status] || statusBlockColors.confirmed).bg }} />
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
};

const CMAgenda = () => {
  const events = cmDayBookings(CM_SELECTED).map(b => ({
    ...b, kind: b.startDay === CM_SELECTED ? 'Dolazak' : (b.endDay === CM_SELECTED ? 'Zadnja noć' : 'Boravak'),
  }));
  const kindIcon = { 'Dolazak': 'login', 'Zadnja noć': 'logout', 'Boravak': 'hotel' };
  return (
    <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Pon, <span className="bb-tnum">22.</span> lipnja</h3>
        <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{events.length} rezervacije</span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {events.map((e, i) => {
          const c = statusBlockColors[e.status] || statusBlockColors.confirmed;
          return (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-sm)', borderLeft: `4px solid ${c.bg}` }}>
              <div style={{ width: 34, height: 34, borderRadius: 10, background: 'var(--bb-surface-variant)', color: 'var(--bb-text-secondary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <BBIcon name={kindIcon[e.kind]} size={18} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.guest}</div>
                <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{e.unitName} · {e.kind}</div>
              </div>
              <BBStatusBadge status={e.status} size="sm" />
            </div>
          );
        })}
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const CalendarMonthDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="kalendar-mjesecni" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
      <BBAppBar breadcrumb={['Kalendar', 'Mjesečni']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} />
      <main style={{ padding: '20px 32px 32px', flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        <CMHeader />
        {/* Toolbar */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <BBButton variant="secondary" asIcon iconLeft="chevron_left" ariaLabel="Prethodni mjesec" />
            <div style={{ minWidth: 200, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '0 16px', background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', borderRadius: 'var(--bb-radius-sm)', color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: 14 }}>
              <BBIcon name="calendar_today" size={16} style={{ color: 'var(--bb-primary)' }} />
              <span>{monthName}</span>
            </div>
            <BBButton variant="secondary" asIcon iconLeft="chevron_right" ariaLabel="Sljedeći mjesec" />
          </div>
          <BBButton variant="tertiary" iconLeft="event">Idi na…</BBButton>
          <div style={{ flex: 1 }} />
          <BBButton variant="secondary" iconLeft="today">Danas</BBButton>
          <BBButton variant="secondary" iconLeft="tune">Filteri</BBButton>
          <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
          <BBButton variant="secondary" asIcon iconLeft="more_vert" ariaLabel="Više opcija" />
        </div>
        <CMKpiStrip />
        <CMLegend stat={<><span className="bb-tnum">6</span> rezervacija · <span className="bb-tnum">4</span> jedinice</>} />
        <CMMonthGrid rowH={112} barH={22} />
      </main>
      <button type="button" aria-label="Nova rezervacija" style={{ position: 'absolute', bottom: 32, right: 32, width: 56, height: 56, borderRadius: '50%', background: 'var(--bb-primary)', color: '#FFFFFF', border: 'none', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--bb-shadow-purple)' }}>
        <BBIcon name="add" size={28} />
      </button>
    </div>
  </div>
);

const CalendarMonthTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 768, height: 1024, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebarRail active="kalendar-mjesecni" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
      <BBAppBar breadcrumb={['Kalendar', 'Mjesečni']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} />
      <main style={{ padding: '16px 20px 20px', flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        <CMHeader compact />
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
          <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prethodni" />
          <div style={{ flex: 1, height: 36, padding: '0 12px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', borderRadius: 'var(--bb-radius-sm)', fontWeight: 600, fontSize: 13 }}>
            <BBIcon name="calendar_today" size={14} style={{ color: 'var(--bb-primary)' }} />
            {monthName}
          </div>
          <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Sljedeći" />
          <BBButton variant="secondary" size="sm" iconLeft="today">Danas</BBButton>
          <BBButton variant="primary" size="sm" iconLeft="add">Nova</BBButton>
        </div>
        <CMKpiStrip compact />
        <CMLegend wrap size="sm" />
        <CMMonthGrid rowH={104} barH={20} />
      </main>
      <button type="button" aria-label="Nova rezervacija" style={{ position: 'absolute', bottom: 24, right: 24, width: 52, height: 52, borderRadius: '50%', background: 'var(--bb-primary)', color: '#FFFFFF', border: 'none', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--bb-shadow-purple)' }}>
        <BBIcon name="add" size={24} />
      </button>
    </div>
  </div>
);

const CalendarMonthMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column', position: 'relative' }}>
    <BBAppBar title="Kalendar" showHamburger notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} />
    <main style={{ padding: '12px 16px 0', flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <CMSubTabs size="mobile" />
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
        <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prethodni" />
        <div style={{ flex: 1, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', borderRadius: 'var(--bb-radius-sm)', fontWeight: 600, fontSize: 13, color: 'var(--bb-text-primary)' }}>
          <BBIcon name="calendar_today" size={14} style={{ color: 'var(--bb-primary)' }} />
          {monthName}
        </div>
        <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Sljedeći" />
      </div>
      <CMMobileGrid />
      <CMAgenda />
    </main>
    <button type="button" aria-label="Nova rezervacija" style={{ position: 'absolute', bottom: 24, right: 24, width: 52, height: 52, borderRadius: '50%', background: 'var(--bb-primary)', color: '#FFFFFF', border: 'none', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--bb-shadow-purple)' }}>
      <BBIcon name="add" size={24} />
    </button>
  </div>
);

Object.assign(window, { CalendarMonthDesktop, CalendarMonthTablet, CalendarMonthMobile });
