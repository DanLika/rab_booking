/* eslint-disable */
// Calendar · Timeline — CHROME redesign (Prompt 07).
// Internals (grid + booking-block parallelogram) shown as visual reference;
// in Flutter the calendar repository + cell dims (50/42/100/60px) are FROZEN.

const { useState: useStCal } = React;

// ──────────────────────────────────────────────────────────────
// Sample data: June 2026, 4 units, mixed statuses
// ──────────────────────────────────────────────────────────────
const TIMELINE_UNITS = [
  { id: 'u1', property: 'Vila Marina', name: 'Studio 4',       capacity: 2 },
  { id: 'u2', property: 'Vila Marina', name: 'Premium suite',  capacity: 4 },
  { id: 'u3', property: 'Stan Lavanda', name: 'Apartman A',    capacity: 4 },
  { id: 'u4', property: 'Stan Lavanda', name: 'Studio B',      capacity: 2 }, // empty row
];

const TIMELINE_BOOKINGS = [
  { id: 'BB-2402', unitId: 'u1', startDay: 8,  nights: 3, status: 'pending',   guest: 'Marko Horvat', ref: 'BB-2402' },
  { id: 'BB-2410', unitId: 'u1', startDay: 22, nights: 3, status: 'confirmed', guest: 'Ana Pavlović', ref: 'BB-2410' },
  { id: 'BB-2398', unitId: 'u2', startDay: 14, nights: 3, status: 'confirmed', guest: 'Sandra Kovač', ref: 'BB-2398' },
  { id: 'BB-2411', unitId: 'u2', startDay: 28, nights: 3, status: 'imported',  guest: 'Booking.com · Schmidt', ref: 'BKG-441' },
  { id: 'BB-2391', unitId: 'u3', startDay: 5,  nights: 2, status: 'completed', guest: 'Luka Babić',   ref: 'BB-2391' },
  { id: 'BB-2407', unitId: 'u3', startDay: 19, nights: 5, status: 'confirmed', guest: 'Petra Marić',  ref: 'BB-2407' },
  // unit u4 has no bookings → empty-state hint
];

// June 2026: starts on Monday (1st), 30 days
const monthName = 'Lipanj 2026';
const daysInMonth = 30;
const todayIndex = 28; // June 28 = "today" marker in mock

// Croatian weekday letters (Pon = Mon)
const wkLetters = ['Pon','Uto','Sri','Čet','Pet','Sub','Ned'];
// June 1, 2026 is a Monday → weekday index for day N = (N - 1) % 7
function weekdayOf(day) { return (day - 1) % 7; }
function isWeekend(day) { const w = weekdayOf(day); return w === 5 || w === 6; }

// ──────────────────────────────────────────────────────────────
// CalendarTimelineDesktop (1440 × 1100)
// ──────────────────────────────────────────────────────────────
const CalendarTimelineDesktop = () => {
  const dayW = 30;
  const labelW = 196;
  const rowH = 60;

  return (
    <div className="theme-light bb-screen" style={{
      width: 1440, height: 1100, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebar user={SAMPLE_USER} active="kalendar-timeline" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
        <BBAppBar
          title="Kalendar"
          notifCount={6}
          actions={[
            { icon: 'search', label: 'Pretraži rezervacije' },
            { icon: 'light_mode', label: 'Promijeni temu' },
          ]}
        />

        <main style={{ padding: '20px 32px 32px', flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          {/* Sub-tab: Timeline ↔ Mjesečni */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
            <BBChip selected variant="tab" iconLeft="view_timeline">Timeline</BBChip>
            <BBChip variant="tab" iconLeft="calendar_view_month">Mjesečni</BBChip>
          </div>

          {/* Toolbar: month nav (left) + primary actions (right) */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 12,
            marginBottom: 12,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <BBButton variant="secondary" asIcon iconLeft="chevron_left" ariaLabel="Prethodni mjesec" />
              <div style={{
                minWidth: 200, height: 44,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                padding: '0 16px',
                background: 'var(--bb-surface)',
                border: '1px solid var(--bb-border)',
                borderRadius: 'var(--bb-radius-sm)',
                color: 'var(--bb-text-primary)',
                fontWeight: 600, fontSize: 14,
              }}>
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

          {/* Status legend */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16,
            padding: '10px 14px',
            background: 'var(--bb-surface)',
            border: '1px solid var(--bb-border-subtle)',
            borderRadius: 'var(--bb-radius-sm)',
          }}>
            <span className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)' }}>Status:</span>
            <BBStatusBadge status="confirmed" />
            <BBStatusBadge status="pending" />
            <BBStatusBadge status="completed" />
            <BBStatusBadge status="cancelled" />
            <BBStatusBadge status="imported" />
            <div style={{ flex: 1 }} />
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
              <span className="bb-tnum">6</span> rezervacija · <span className="bb-tnum">4</span> jedinice
            </span>
          </div>

          {/* Calendar grid */}
          <TimelineGrid
            dayW={dayW}
            labelW={labelW}
            rowH={rowH}
            days={daysInMonth}
            units={TIMELINE_UNITS}
            bookings={TIMELINE_BOOKINGS}
            today={todayIndex}
          />
        </main>

        {/* FAB */}
        <button type="button" aria-label="Nova rezervacija" style={{
          position: 'absolute', bottom: 32, right: 32,
          width: 56, height: 56, borderRadius: '50%',
          background: 'var(--bb-primary)', color: '#FFFFFF',
          border: 'none', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: 'var(--bb-shadow-purple)',
        }}>
          <BBIcon name="add" size={28} />
        </button>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// TimelineGrid — header row + unit rows w/ booking parallelograms
// ──────────────────────────────────────────────────────────────
const TimelineGrid = ({ dayW, labelW, rowH, days, units, bookings, today }) => {
  const headerH = 36;
  const gridW = labelW + dayW * days;

  return (
    <div style={{
      background: 'var(--bb-surface)',
      border: '1px solid var(--bb-border-subtle)',
      borderRadius: 'var(--bb-radius-md)',
      overflow: 'hidden',
      boxShadow: 'var(--bb-shadow-sm)',
    }}>
      {/* Header row: weekday + day number */}
      <div style={{
        display: 'flex',
        height: headerH,
        borderBottom: '1px solid var(--bb-border-subtle)',
        background: 'var(--bb-surface-variant)',
      }}>
        <div style={{
          width: labelW, flexShrink: 0,
          display: 'flex', alignItems: 'center',
          padding: '0 16px',
          borderRight: '1px solid var(--bb-border-subtle)',
        }}>
          <span className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)' }}>Smještajna jedinica</span>
        </div>
        {Array.from({ length: days }).map((_, i) => {
          const day = i + 1;
          const wk = weekdayOf(day);
          const isWk = isWeekend(day);
          const isToday = day === today;
          return (
            <div key={day} style={{
              width: dayW, flexShrink: 0,
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              borderRight: '1px solid var(--bb-border-subtle)',
              background: isToday ? 'var(--bb-primary-tint-bg)' : (isWk ? 'rgba(255,184,77,0.05)' : 'transparent'),
              position: 'relative',
            }}>
              <span style={{
                fontSize: 9, fontWeight: 600, letterSpacing: '0.06em',
                color: isWk ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-tertiary)',
                textTransform: 'uppercase',
              }}>{wkLetters[wk]}</span>
              <span className="bb-tnum" style={{
                fontSize: 13, fontWeight: isToday ? 700 : 600,
                color: isToday ? 'var(--bb-primary)' : 'var(--bb-text-primary)',
              }}>{day}</span>
              {isToday && (
                <span style={{
                  position: 'absolute', bottom: 2, width: 5, height: 5, borderRadius: '50%',
                  background: 'var(--bb-primary)',
                }} />
              )}
            </div>
          );
        })}
      </div>

      {/* Unit rows */}
      {units.map((unit, ui) => (
        <UnitRow
          key={unit.id}
          unit={unit}
          unitIndex={ui}
          dayW={dayW}
          labelW={labelW}
          rowH={rowH}
          days={days}
          today={today}
          bookings={bookings.filter(b => b.unitId === unit.id)}
          isLast={ui === units.length - 1}
        />
      ))}
    </div>
  );
};

const UnitRow = ({ unit, unitIndex, dayW, labelW, rowH, days, today, bookings, isLast }) => {
  const hasBookings = bookings.length > 0;
  return (
    <div style={{
      display: 'flex', height: rowH,
      borderBottom: isLast ? 'none' : '1px solid var(--bb-border-subtle)',
      position: 'relative',
    }}>
      {/* Label column */}
      <div style={{
        width: labelW, flexShrink: 0,
        padding: '0 16px',
        display: 'flex', alignItems: 'center', gap: 10,
        borderRight: '1px solid var(--bb-border-subtle)',
        background: 'var(--bb-surface)',
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 10,
          background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <BBIcon name="bed" size={18} />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{unit.name}</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{unit.property}</div>
        </div>
      </div>

      {/* Day cells (background grid) */}
      <div style={{ position: 'relative', flex: '1 1 auto', minWidth: 0, display: 'flex' }}>
        {Array.from({ length: days }).map((_, i) => {
          const day = i + 1;
          const isWk = isWeekend(day);
          const isToday = day === today;
          return (
            <div key={day} style={{
              width: dayW, flexShrink: 0,
              borderRight: '1px solid var(--bb-border-subtle)',
              background: isToday ? 'var(--bb-primary-tint-bg)' : (isWk ? 'rgba(255,184,77,0.04)' : (unitIndex % 2 === 1 ? 'rgba(0,0,0,0.012)' : 'transparent')),
            }} />
          );
        })}

        {/* Today vertical line */}
        <div style={{
          position: 'absolute', top: 0, bottom: 0,
          left: (today - 1) * dayW + dayW / 2,
          width: 2, background: 'var(--bb-primary)',
          opacity: 0.32, transform: 'translateX(-1px)',
          pointerEvents: 'none',
        }} />

        {/* Bookings */}
        {bookings.map(b => (
          <BookingBlock key={b.id} booking={b} dayW={dayW} rowH={rowH} />
        ))}

        {/* Empty state hint */}
        {!hasBookings && (
          <div style={{
            position: 'absolute', inset: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'var(--bb-text-tertiary)',
            gap: 8, fontSize: 12, fontWeight: 500,
          }}>
            <BBIcon name="event_busy" size={16} />
            <span>Nema rezervacija u ovom razdoblju</span>
            <BBButton variant="tertiary" size="sm" iconLeft="add" style={{ marginLeft: 8 }}>Dodaj</BBButton>
          </div>
        )}
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// BookingBlock — the FROZEN parallelogram shape (visual reference)
// ──────────────────────────────────────────────────────────────
const statusBlockColors = {
  confirmed: { bg: '#4FAE7F',  text: '#FFFFFF' },
  pending:   { bg: '#FFB84D',  text: '#5C3500' },
  completed: { bg: '#9B86F1',  text: '#FFFFFF' },
  cancelled: { bg: '#A0AEC0',  text: '#FFFFFF' },
  imported:  { bg: '#6BA8E8',  text: '#FFFFFF' },
};

const BookingBlock = ({ booking, dayW, rowH }) => {
  const colors = statusBlockColors[booking.status] || statusBlockColors.confirmed;
  const left = (booking.startDay - 1) * dayW;
  const widthPx = booking.nights * dayW;
  const slope = 10;
  const blockH = 42;
  const top = (rowH - blockH) / 2;

  // z-order per FROZEN spec: cancelled at base, confirmed on top.
  const zOrder = { cancelled: 1, imported: 2, completed: 3, pending: 4, confirmed: 5 };

  return (
    <div style={{
      position: 'absolute',
      left, top,
      width: widthPx, height: blockH,
      zIndex: zOrder[booking.status] || 3,
    }}>
      {/* Parallelogram body */}
      <div style={{
        width: '100%', height: '100%',
        background: colors.bg,
        clipPath: `polygon(${slope}px 0, 100% 0, calc(100% - ${slope}px) 100%, 0 100%)`,
        boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.18)',
      }} />
      {/* Label overlay (matches parallelogram via padding) */}
      <div style={{
        position: 'absolute', inset: 0,
        padding: `0 ${slope + 6}px`,
        display: 'flex', flexDirection: 'column', justifyContent: 'center',
        color: colors.text,
        pointerEvents: 'none',
      }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: '-0.005em',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', lineHeight: 1.2,
        }}>{booking.guest}</div>
        <div style={{
          fontSize: 10, opacity: 0.85, fontWeight: 600, lineHeight: 1.2,
          fontVariantNumeric: 'tabular-nums',
        }}>{booking.ref} · {booking.nights}n</div>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// CalendarTimelineMobile (390 × 880)
// ──────────────────────────────────────────────────────────────
const CalendarTimelineMobile = () => {
  const dayW = 28;
  const labelW = 100;
  const rowH = 56;
  const visibleDays = 10; // show days 5–14 in the artboard window
  const startOffset = 5;  // start at day 5

  return (
    <div className="theme-light bb-screen" style={{
      width: 390, height: 880,
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
      display: 'flex', flexDirection: 'column', position: 'relative',
    }}>
      <BBAppBar title="Kalendar" showHamburger notifCount={6} actions={[
        { icon: 'search', label: 'Pretraži' },
      ]} />

      <main style={{ padding: '12px 16px 0', flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        {/* Sub-tab */}
        <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
          <BBChip selected variant="tab" size="sm" iconLeft="view_timeline">Timeline</BBChip>
          <BBChip variant="tab" size="sm" iconLeft="calendar_view_month">Mjesečni</BBChip>
        </div>

        {/* Month nav row */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
          <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prethodni" />
          <div style={{
            flex: 1, height: 36,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            background: 'var(--bb-surface)',
            border: '1px solid var(--bb-border)',
            borderRadius: 'var(--bb-radius-sm)',
            fontWeight: 600, fontSize: 13, color: 'var(--bb-text-primary)',
          }}>
            <BBIcon name="calendar_today" size={14} style={{ color: 'var(--bb-primary)' }} />
            {monthName}
          </div>
          <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Sljedeći" />
        </div>

        {/* Compact toolbar */}
        <div style={{ display: 'flex', gap: 6, marginBottom: 10 }}>
          <BBButton variant="secondary" size="sm" iconLeft="today" fullWidth>Danas</BBButton>
          <BBButton variant="secondary" size="sm" iconLeft="tune" fullWidth>Filteri</BBButton>
          <BBButton variant="secondary" asIcon size="sm" iconLeft="more_vert" ariaLabel="Više" />
        </div>

        {/* Status legend (wraps) */}
        <div style={{
          display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 12,
          padding: '8px 10px',
          background: 'var(--bb-surface)',
          border: '1px solid var(--bb-border-subtle)',
          borderRadius: 'var(--bb-radius-sm)',
        }}>
          <BBStatusBadge status="confirmed" size="sm" />
          <BBStatusBadge status="pending" size="sm" />
          <BBStatusBadge status="completed" size="sm" />
          <BBStatusBadge status="imported" size="sm" />
        </div>

        {/* Calendar window — shows partial range, hints at scroll */}
        <div style={{
          background: 'var(--bb-surface)',
          border: '1px solid var(--bb-border-subtle)',
          borderRadius: 'var(--bb-radius-md)',
          overflow: 'hidden',
          flex: 1, minHeight: 0,
          position: 'relative',
        }}>
          {/* Scroll hint chevron */}
          <div style={{
            position: 'absolute', top: 6, right: 6, zIndex: 2,
            width: 22, height: 22, borderRadius: '50%',
            background: 'var(--bb-surface-variant)', color: 'var(--bb-text-tertiary)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 10, fontWeight: 600,
          }}>
            <BBIcon name="chevron_right" size={14} />
          </div>

          <MobileTimeline
            dayW={dayW}
            labelW={labelW}
            rowH={rowH}
            visibleDays={visibleDays}
            startOffset={startOffset}
            units={TIMELINE_UNITS.slice(0, 3)}
            bookings={TIMELINE_BOOKINGS}
            today={9}
          />
        </div>
      </main>

      {/* FAB */}
      <button type="button" aria-label="Nova rezervacija" style={{
        position: 'absolute', bottom: 24, right: 24,
        width: 52, height: 52, borderRadius: '50%',
        background: 'var(--bb-primary)', color: '#FFFFFF',
        border: 'none', cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: 'var(--bb-shadow-purple)',
      }}>
        <BBIcon name="add" size={24} />
      </button>
    </div>
  );
};

const MobileTimeline = ({ dayW, labelW, rowH, visibleDays, startOffset, units, bookings, today }) => {
  const headerH = 32;
  return (
    <div>
      {/* Header */}
      <div style={{
        display: 'flex', height: headerH,
        background: 'var(--bb-surface-variant)',
        borderBottom: '1px solid var(--bb-border-subtle)',
      }}>
        <div style={{
          width: labelW, flexShrink: 0,
          padding: '0 10px', display: 'flex', alignItems: 'center',
          borderRight: '1px solid var(--bb-border-subtle)',
        }}>
          <span className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', fontSize: 9 }}>Jedinica</span>
        </div>
        {Array.from({ length: visibleDays }).map((_, i) => {
          const day = startOffset + i;
          const isWk = isWeekend(day);
          const isToday = day === today;
          return (
            <div key={day} style={{
              width: dayW, flexShrink: 0,
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              borderRight: '1px solid var(--bb-border-subtle)',
              background: isToday ? 'var(--bb-primary-tint-bg)' : (isWk ? 'rgba(255,184,77,0.05)' : 'transparent'),
            }}>
              <span style={{
                fontSize: 8, fontWeight: 600,
                color: isWk ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-tertiary)',
                textTransform: 'uppercase', letterSpacing: '0.04em',
              }}>{wkLetters[weekdayOf(day)]}</span>
              <span className="bb-tnum" style={{
                fontSize: 11, fontWeight: isToday ? 700 : 600,
                color: isToday ? 'var(--bb-primary)' : 'var(--bb-text-primary)',
              }}>{day}</span>
            </div>
          );
        })}
      </div>

      {/* Rows */}
      {units.map((unit, ui) => {
        const ub = bookings
          .filter(b => b.unitId === unit.id)
          .map(b => ({
            ...b,
            // Re-base start to the visible window
            visibleStart: b.startDay - startOffset,
            clip: { left: 0, right: 0 },
          }))
          .filter(b => b.visibleStart + b.nights > 0 && b.visibleStart < visibleDays);
        return (
          <div key={unit.id} style={{
            display: 'flex', height: rowH,
            borderBottom: ui < units.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none',
            position: 'relative',
          }}>
            {/* Label */}
            <div style={{
              width: labelW, flexShrink: 0,
              padding: '0 10px',
              display: 'flex', alignItems: 'center', gap: 8,
              borderRight: '1px solid var(--bb-border-subtle)',
            }}>
              <div style={{
                width: 24, height: 24, borderRadius: 8, flexShrink: 0,
                background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <BBIcon name="bed" size={14} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="bb-caption" style={{
                  color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: 11,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{unit.name}</div>
              </div>
            </div>

            {/* Day cells + bookings */}
            <div style={{ position: 'relative', flex: '1 1 auto', minWidth: 0, display: 'flex' }}>
              {Array.from({ length: visibleDays }).map((_, i) => {
                const day = startOffset + i;
                const isWk = isWeekend(day);
                const isToday = day === today;
                return (
                  <div key={day} style={{
                    width: dayW, flexShrink: 0,
                    borderRight: '1px solid var(--bb-border-subtle)',
                    background: isToday ? 'var(--bb-primary-tint-bg)' : (isWk ? 'rgba(255,184,77,0.04)' : 'transparent'),
                  }} />
                );
              })}
              {ub.map(b => (
                <BookingBlock key={b.id} booking={{ ...b, startDay: b.visibleStart + 1 }} dayW={dayW} rowH={rowH} />
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
};

Object.assign(window, {
  CalendarTimelineDesktop,
  CalendarTimelineMobile,
  CalendarTimelineTablet,
  // Exposed FROZEN grid internals (geometry unchanged) so the premium-chrome
  // variant can reuse them verbatim instead of duplicating the spec:
  TimelineGrid,
  MobileTimeline,
  TIMELINE_UNITS,
  TIMELINE_BOOKINGS,
});

// ──────────────────────────────────────────────────────────────
// CalendarTimelineTablet (768 × 1024)
// ──────────────────────────────────────────────────────────────
function CalendarTimelineTablet() {
  const dayW = 22;
  const labelW = 156;
  const rowH = 56;

  return (
    <div className="theme-light bb-screen" style={{
      width: 768, height: 1024, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebarRail active="kalendar-timeline" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, position: 'relative' }}>
        <BBAppBar title="Kalendar" notifCount={6} actions={[
          { icon: 'search', label: 'Pretraži' },
          { icon: 'light_mode', label: 'Tema' },
        ]} />

        <main style={{ padding: '16px 20px 20px', flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
          <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
            <BBChip selected variant="tab" size="sm" iconLeft="view_timeline">Timeline</BBChip>
            <BBChip variant="tab" size="sm" iconLeft="calendar_view_month">Mjesečni</BBChip>
          </div>

          {/* Toolbar */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_left" ariaLabel="Prethodni" />
            <div style={{
              flex: 1, height: 36, padding: '0 12px',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              background: 'var(--bb-surface)',
              border: '1px solid var(--bb-border)',
              borderRadius: 'var(--bb-radius-sm)',
              fontWeight: 600, fontSize: 13,
            }}>
              <BBIcon name="calendar_today" size={14} style={{ color: 'var(--bb-primary)' }} />
              {monthName}
            </div>
            <BBButton variant="secondary" asIcon size="sm" iconLeft="chevron_right" ariaLabel="Sljedeći" />
            <BBButton variant="secondary" size="sm" iconLeft="today">Danas</BBButton>
            <BBButton variant="secondary" size="sm" iconLeft="tune">Filteri</BBButton>
            <BBButton variant="primary" size="sm" iconLeft="add">Nova</BBButton>
          </div>

          {/* Legend */}
          <div style={{
            display: 'flex', flexWrap: 'wrap', gap: 8, alignItems: 'center',
            padding: '8px 12px', marginBottom: 12,
            background: 'var(--bb-surface)',
            border: '1px solid var(--bb-border-subtle)',
            borderRadius: 'var(--bb-radius-sm)',
          }}>
            <span className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)' }}>Status:</span>
            <BBStatusBadge status="confirmed" size="sm" />
            <BBStatusBadge status="pending" size="sm" />
            <BBStatusBadge status="completed" size="sm" />
            <BBStatusBadge status="imported" size="sm" />
          </div>

          {/* Grid */}
          <TimelineGrid
            dayW={dayW}
            labelW={labelW}
            rowH={rowH}
            days={daysInMonth}
            units={TIMELINE_UNITS}
            bookings={TIMELINE_BOOKINGS}
            today={todayIndex}
          />
        </main>

        <button type="button" aria-label="Nova rezervacija" style={{
          position: 'absolute', bottom: 24, right: 24,
          width: 52, height: 52, borderRadius: '50%',
          background: 'var(--bb-primary)', color: '#FFFFFF',
          border: 'none', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: 'var(--bb-shadow-purple)',
        }}>
          <BBIcon name="add" size={24} />
        </button>
      </div>
    </div>
  );
}
