/* eslint-disable */
// Booking widget · Calendar — Prompt 26.
// Minimalist embeddable widget. Mint accent (kept distinct from owner purple).
// Subtle BookBed brand hint via "Powered by BookBed" footer.

const W_MINT = '#3DD9B0';
const W_MINT_LIGHT = '#A8EFD9';
const W_MINT_DEEP = '#1FAF87';

// May 2026 — starts Friday. 31 days.
function wMay2026(day) {
  // May 1, 2026 = Friday. Mon=0...Sun=6 layout.
  const startCol = 4; // Friday
  return startCol + (day - 1);
}
function wIsWeekendDay(day) {
  const idx = wMay2026(day) % 7;
  return idx === 5 || idx === 6;
}

const SELECTED_RANGE = { start: 29, end: 30 }; // 29-30 May (1 night)

// ──────────────────────────────────────────────────────────────
// Day cell
// ──────────────────────────────────────────────────────────────
const DayCell = ({ day, price, isPast, isToday, isStart, isEnd, isInRange, isWeekend, available = true, size = 'lg' }) => {
  const cellH = size === 'sm' ? 44 : size === 'md' ? 56 : 72;
  const fontSize = size === 'sm' ? 13 : size === 'md' ? 15 : 17;
  const priceSize = size === 'sm' ? 10 : 11;

  const isSelected = isStart || isEnd;
  const bg = isSelected ? W_MINT
    : isInRange ? W_MINT_LIGHT
    : isPast ? '#F8F8F8'
    : '#FFFFFF';
  const textColor = isSelected ? '#FFFFFF'
    : isPast ? '#C5CAD2'
    : isInRange ? '#0B5A45'
    : '#1B2330';
  const priceColor = isSelected ? 'rgba(255,255,255,0.92)'
    : isPast ? '#D7DAE0'
    : isWeekend ? '#FF7A6B'
    : '#7C8593';

  const hoverable = available && !isPast && !isSelected && !isToday;
  return (
    <div style={{
      height: cellH,
      borderRadius: 12,
      background: bg,
      border: isToday ? `2px solid ${W_MINT_DEEP}` : '1px solid #ECEEF1',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 2,
      color: textColor,
      cursor: isPast ? 'not-allowed' : 'pointer',
      boxShadow: isSelected ? '0 4px 14px rgba(61, 217, 176, 0.45)' : 'none',
      transition: 'transform 120ms ease-out, border-color 120ms ease-out, box-shadow 120ms ease-out',
    }}
    onMouseEnter={hoverable ? (e) => {
      e.currentTarget.style.borderColor = W_MINT;
      e.currentTarget.style.transform = 'translateY(-2px)';
      e.currentTarget.style.boxShadow = '0 4px 12px rgba(61, 217, 176, 0.22)';
    } : undefined}
    onMouseLeave={hoverable ? (e) => {
      e.currentTarget.style.borderColor = '#ECEEF1';
      e.currentTarget.style.transform = 'none';
      e.currentTarget.style.boxShadow = 'none';
    } : undefined}>
      <span style={{ fontSize, fontWeight: isSelected ? 700 : 600, lineHeight: 1, fontVariantNumeric: 'tabular-nums' }}>{day}</span>
      {available && price && (
        <span style={{ fontSize: priceSize, fontWeight: 600, color: priceColor, fontVariantNumeric: 'tabular-nums' }}>
          €{price}
        </span>
      )}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Calendar grid (5 weeks)
// ──────────────────────────────────────────────────────────────
const WidgetCalendarGrid = ({ size = 'lg', selected = SELECTED_RANGE }) => {
  const headers = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const cells = [];
  // Empty cells before May 1 (Friday = column 4)
  for (let i = 0; i < 4; i++) cells.push({ empty: true, key: `e${i}` });
  for (let d = 1; d <= 31; d++) {
    const wk = wIsWeekendDay(d);
    const price = wk ? 130 : 120;
    const isPast = d < 14;
    const isToday = d === 14;
    const inRange = d >= selected.start && d <= selected.end;
    const isStart = d === selected.start;
    const isEnd = d === selected.end;
    cells.push({
      day: d, price, isPast, isToday,
      isStart, isEnd, isInRange: inRange && !isStart && !isEnd,
      isWeekend: wk, available: !isPast,
      key: `d${d}`,
    });
  }

  return (
    <div style={{ width: '100%' }}>
      {/* Day headers */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6, marginBottom: 6 }}>
        {headers.map(h => (
          <div key={h} style={{
            textAlign: 'center', padding: '6px 0',
            fontSize: 10, fontWeight: 700, letterSpacing: '0.08em',
            color: '#7C8593',
          }}>{h}</div>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6 }}>
        {cells.map(c => c.empty
          ? <div key={c.key} />
          : <DayCell key={c.key} {...c} size={size} />
        )}
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Top toolbar — month/year toggle + theme + language + month nav
// ──────────────────────────────────────────────────────────────
const WidgetToolbar = ({ compact = false }) => (
  <div style={{
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    gap: 8, marginBottom: compact ? 12 : 20, flexWrap: 'wrap',
  }}>
    {/* Month/Year segmented control */}
    <div style={{
      display: 'inline-flex', padding: 4,
      background: '#F1F2F4', borderRadius: 999,
      flexShrink: 0,
    }}>
      <SegBtn icon="dashboard" label="Mjesec" active />
      <SegBtn icon="grid_view" label="Godina" />
    </div>
    {/* Theme + language */}
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
      <button style={iconBtnStyle()}><BBIcon name="light_mode" size={18} style={{ color: '#1B2330' }} /></button>
      <button style={{ ...iconBtnStyle(), gap: 4, padding: '0 12px', width: 'auto' }}>
        <span style={{ width: 18, fontSize: 14 }}>🇭🇷</span>
        <BBIcon name="expand_more" size={16} style={{ color: '#7C8593' }} />
      </button>
    </div>
    {/* Month nav */}
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
      <button style={iconBtnStyle()}><BBIcon name="chevron_left" size={18} style={{ color: '#1B2330' }} /></button>
      <span style={{ fontSize: 15, fontWeight: 700, color: '#1B2330', padding: '0 12px', minWidth: 110, textAlign: 'center' }}>
        Svibanj 2026
      </span>
      <button style={iconBtnStyle()}><BBIcon name="chevron_right" size={18} style={{ color: '#1B2330' }} /></button>
    </div>
  </div>
);

const SegBtn = ({ icon, label, active }) => (
  <button style={{
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '6px 14px', borderRadius: 999, border: 'none', cursor: 'pointer',
    background: active ? '#1B2330' : 'transparent',
    color: active ? '#FFFFFF' : '#5B6573',
    fontSize: 13, fontWeight: 600, fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBIcon name={icon} size={14} />
    {label}
  </button>
);

function iconBtnStyle() {
  return {
    width: 36, height: 36, borderRadius: '50%',
    border: 'none', background: '#FFFFFF',
    boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
    cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  };
}

// ──────────────────────────────────────────────────────────────
// Hero unit card (Sketch C)
// ──────────────────────────────────────────────────────────────
const HeroUnitCard = ({ compact = false }) => (
  <div style={{
    background: '#F6FBF9',
    borderRadius: 20, padding: compact ? 16 : 20,
    display: 'flex', alignItems: 'center', gap: compact ? 14 : 20,
    marginBottom: compact ? 16 : 24,
    border: '1px solid #E4EFEA',
  }}>
    {/* Photo placeholder */}
    <image-slot
      id="bb-widget-unit"
      shape="rounded"
      radius="16"
      placeholder="Foto"
      style={{ display: 'block', width: compact ? 64 : 96, height: compact ? 64 : 96, flexShrink: 0 }}
    ></image-slot>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: '#7C8593', marginBottom: 2 }}>
        Vila Marina
      </div>
      <h2 style={{
        margin: 0, fontSize: compact ? 18 : 22, fontWeight: 700,
        color: '#1B2330', letterSpacing: '-0.015em',
      }}>Studio s pogledom na more</h2>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 6, flexWrap: 'wrap' }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, color: '#5B6573' }}>
          <BBIcon name="group" size={14} /> do 2 gosta
        </span>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, color: '#5B6573' }}>
          <BBIcon name="hotel" size={14} /> 1 spavaća
        </span>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, color: '#5B6573' }}>
          <BBIcon name="event" size={14} /> min. 2 noći
        </span>
      </div>
    </div>
    <div style={{ textAlign: 'right', flexShrink: 0 }}>
      <div style={{ fontSize: 10, fontWeight: 600, color: '#7C8593', letterSpacing: '0.04em' }}>OD</div>
      <div style={{ fontSize: compact ? 22 : 28, fontWeight: 800, color: '#1B2330', letterSpacing: '-0.02em', fontVariantNumeric: 'tabular-nums' }}>
        €120
      </div>
      <div style={{ fontSize: 11, color: '#7C8593' }}>po noći</div>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pricing breakdown panel (sticky right on desktop)
// ──────────────────────────────────────────────────────────────
const PricingPanel = ({ compact = false }) => (
  <div style={{
    background: '#FFFFFF',
    borderRadius: 20,
    border: '1px solid #ECEEF1',
    boxShadow: '0 12px 28px rgba(20, 30, 50, 0.08)',
    padding: compact ? 16 : 20,
    display: 'flex', flexDirection: 'column',
  }}>
    {/* Date range pill */}
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 8,
      padding: '8px 12px', alignSelf: 'flex-start',
      background: '#F1F2F4', borderRadius: 999,
      marginBottom: 16,
    }}>
      <BBIcon name="event" size={14} style={{ color: '#5B6573' }} />
      <span style={{ fontSize: 13, fontWeight: 600, color: '#1B2330', fontVariantNumeric: 'tabular-nums' }}>
        29.05. – 30.05.2026
      </span>
      <span style={{
        background: W_MINT, color: '#FFFFFF',
        padding: '2px 8px', borderRadius: 999,
        fontSize: 11, fontWeight: 700,
      }}>1 noć</span>
    </div>

    {/* Breakdown */}
    <div style={{
      border: '1px solid #ECEEF1', borderRadius: 16,
      padding: 16, marginBottom: 16,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
        <span style={{ fontSize: 14, color: '#5B6573' }}>Soba (1 noć)</span>
        <span style={{ fontSize: 14, fontWeight: 700, color: '#1B2330', fontVariantNumeric: 'tabular-nums' }}>€130,00</span>
      </div>
      <div style={{ height: 1, background: '#ECEEF1', margin: '12px 0' }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
        <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: '0.04em', color: '#1B2330', textTransform: 'uppercase' }}>Ukupno</span>
        <span style={{ fontSize: 18, fontWeight: 800, color: '#1B2330', fontVariantNumeric: 'tabular-nums' }}>€130,00</span>
      </div>
      <div style={{ fontSize: 12, color: '#7C8593', textAlign: 'center' }}>
        Polog: <span style={{ fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>€26,00 (20%)</span>
      </div>
    </div>

    {/* CTA */}
    <button style={{
      height: 52, width: '100%', border: 'none', cursor: 'pointer',
      background: '#1B2330', color: '#FFFFFF',
      borderRadius: 16,
      fontSize: 15, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: '0 6px 18px rgba(27,35,48,0.24)',
    }}>
      Rezerviraj sad
      <BBIcon name="arrow_forward" size={18} />
    </button>
    <div style={{ fontSize: 11, color: '#7C8593', textAlign: 'center', marginTop: 10 }}>
      Bez naplate. Plaćate tek nakon potvrde vlasnika.
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Min-stay pill (above grid)
// ──────────────────────────────────────────────────────────────
const MinStayPill = () => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '6px 12px',
    background: '#F1F2F4',
    borderRadius: 999,
    marginBottom: 12,
  }}>
    <BBIcon name="info" size={14} style={{ color: '#5B6573' }} />
    <span style={{ fontSize: 12, fontWeight: 600, color: '#1B2330' }}>Min. boravak: 2 noći</span>
  </div>
);

const PoweredByFooter = () => (
  <div style={{ textAlign: 'center', marginTop: 16, color: '#9AA0AC', fontSize: 11 }}>
    Powered by <span style={{ fontWeight: 700, color: '#6B4CE6' }}>BookBed</span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const WidgetCalendarDesktop = () => (
  <div style={{
    width: 1080, padding: '32px 40px',
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)',
    color: '#1B2330',
  }}>
    <WidgetToolbar />
    <HeroUnitCard />
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: 24, alignItems: 'flex-start' }}>
      <div>
        <MinStayPill />
        <WidgetCalendarGrid size="lg" />
      </div>
      <PricingPanel />
    </div>
    <PoweredByFooter />
  </div>
);

const WidgetCalendarTablet = () => (
  <div style={{
    width: 768, height: 1024, padding: 24,
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)',
    color: '#1B2330',
    display: 'flex', flexDirection: 'column',
  }}>
    <WidgetToolbar compact />
    <HeroUnitCard compact />
    <MinStayPill />
    <WidgetCalendarGrid size="md" />
    {/* Sticky bottom CTA showing range */}
    <div style={{
      marginTop: 16, padding: 14,
      background: '#1B2330', borderRadius: 16, color: '#FFFFFF',
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 11, opacity: 0.7, fontWeight: 600 }}>29.05. – 30.05.2026 · 1 noć</div>
        <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: '-0.02em', fontVariantNumeric: 'tabular-nums' }}>€130,00</div>
      </div>
      <button style={{
        height: 44, padding: '0 18px', border: 'none', cursor: 'pointer',
        background: W_MINT, color: '#FFFFFF',
        borderRadius: 14,
        fontSize: 14, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
        display: 'inline-flex', alignItems: 'center', gap: 6,
      }}>
        Rezerviraj <BBIcon name="arrow_forward" size={16} />
      </button>
    </div>
    <PoweredByFooter />
  </div>
);

const WidgetCalendarMobile = () => (
  <div style={{
    width: 390, height: 880, padding: 16,
    background: '#FFFFFF', fontFamily: 'var(--bb-font-sans)',
    color: '#1B2330',
    display: 'flex', flexDirection: 'column', position: 'relative',
  }}>
    <WidgetToolbar compact />
    <HeroUnitCard compact />
    <MinStayPill />
    <WidgetCalendarGrid size="sm" />
    <div style={{ flex: 1 }} />
    {/* Sticky bottom sheet pricing */}
    <div style={{
      position: 'sticky', bottom: 0,
      marginLeft: -16, marginRight: -16, marginBottom: -16,
      padding: 14,
      background: '#FFFFFF',
      borderTop: '1px solid #ECEEF1',
      boxShadow: '0 -8px 24px rgba(20,30,50,0.08)',
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 10, fontWeight: 600, color: '#7C8593', letterSpacing: '0.04em' }}>29.05. – 30.05. · 1 NOĆ</div>
        <div style={{ fontSize: 20, fontWeight: 800, color: '#1B2330', fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>€130,00</div>
      </div>
      <button style={{
        height: 44, padding: '0 18px', border: 'none', cursor: 'pointer',
        background: '#1B2330', color: '#FFFFFF',
        borderRadius: 14,
        fontSize: 14, fontWeight: 700, fontFamily: 'var(--bb-font-sans)',
      }}>
        Rezerviraj
      </button>
    </div>
  </div>
);

Object.assign(window, {
  WidgetCalendarDesktop,
  WidgetCalendarTablet,
  WidgetCalendarMobile,
});
