/* eslint-disable */
// Bookings filters dialog — Prompt 22. Opens from the "Filteri" button on Rezervacije.
// Modal (desktop) auto-converts to bottom-sheet (mobile). Interactive multi-select chip groups.
// Footer: reset (left) + apply-with-count (right). Shares the dialog visual language (scrim + BBDialog base).

const FILT_STATUS = [
  { id: 'pending', label: 'Na čekanju', dot: '#FFB84D' },
  { id: 'confirmed', label: 'Potvrđeno', dot: '#2E7D5B' },
  { id: 'completed', label: 'Završeno', dot: '#6B4CE6' },
  { id: 'cancelled', label: 'Otkazano', dot: '#718096' },
  { id: 'imported', label: 'Uvezeno', dot: '#4A90D9' },
];
const FILT_OBJEKT = [
  { id: 'svi', label: 'Svi objekti' },
  { id: 'marina', label: 'Vila Marina' },
  { id: 'lavanda', label: 'Stan Lavanda' },
];
const FILT_PERIOD = [
  { id: 'bilo', label: 'Bilo kada' },
  { id: 'mjesec', label: 'Ovaj mjesec' },
  { id: '30', label: 'Sljedećih 30 dana' },
  { id: 'custom', label: 'Prilagođeno' },
];
const FILT_SOURCE = [
  { id: 'direkt', label: 'Direktno', icon: 'public' },
  { id: 'booking', label: 'Booking.com', icon: 'cloud_download' },
  { id: 'airbnb', label: 'Airbnb', icon: 'cloud_download' },
  { id: 'widget', label: 'Widget', icon: 'code' },
];
const FILT_PAY = [
  { id: 'paid', label: 'Plaćeno u cijelosti' },
  { id: 'partial', label: 'Djelomično' },
  { id: 'unpaid', label: 'Neplaćeno' },
];

// ──────────────────────────────────────────────────────────────
// Bits
// ──────────────────────────────────────────────────────────────
const FiltSection = ({ label, children }) => (
  <div style={{ marginBottom: 18 }}>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontSize: 11, fontWeight: 700, marginBottom: 10 }}>{label}</div>
    {children}
  </div>
);

const FiltChips = ({ options, selected, onToggle, size = 'md' }) => (
  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
    {options.map(o => (
      <BBChip key={o.id} selected={selected.includes(o.id)} dotColor={o.dot} iconLeft={o.icon} size={size} onClick={() => onToggle(o.id)}>{o.label}</BBChip>
    ))}
  </div>
);

const FiltDate = ({ label, value }) => (
  <div style={{ flex: 1 }}>
    <label className="bb-label" style={{ display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)' }}>{label}</label>
    <div style={{ height: 44, display: 'flex', alignItems: 'center', gap: 8, padding: '0 12px', borderRadius: 'var(--bb-radius-sm)', background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', cursor: 'pointer' }}>
      <BBIcon name="calendar_today" size={16} style={{ color: 'var(--bb-text-tertiary)' }} />
      <span className="bb-body bb-tnum" style={{ flex: 1, fontSize: 14, color: 'var(--bb-text-primary)' }}>{value}</span>
    </div>
  </div>
);

const FiltAmount = ({ label, value }) => (
  <div style={{ flex: 1 }}>
    <label className="bb-label" style={{ display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)' }}>{label}</label>
    <div style={{ height: 44, display: 'flex', alignItems: 'center', gap: 6, padding: '0 12px', borderRadius: 'var(--bb-radius-sm)', background: 'var(--bb-surface)', border: '1px solid var(--bb-border)' }}>
      <span className="bb-body" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>€</span>
      <input defaultValue={value} style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: 600, color: 'var(--bb-text-primary)', fontVariantNumeric: 'tabular-nums', padding: 0 }} />
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Filter panel (shared modal/sheet body)
// ──────────────────────────────────────────────────────────────
const FilterPanel = ({ mobile = false }) => {
  const [status, setStatus] = React.useState(['pending', 'confirmed']);
  const [objekt, setObjekt] = React.useState(['marina']);
  const [period, setPeriod] = React.useState('custom');
  const [source, setSource] = React.useState(['direkt']);
  const [pay, setPay] = React.useState([]);

  const multi = (set) => (id) => set(s => s.includes(id) ? s.filter(x => x !== id) : [...s, id]);
  const activeCount = status.length + source.length + pay.length + (objekt.includes('svi') || objekt.length === 0 ? 0 : objekt.length) + (period !== 'bilo' ? 1 : 0);

  return (
    <div style={{
      width: mobile ? '100%' : 520,
      background: 'var(--bb-surface)',
      borderRadius: mobile ? 'var(--bb-radius-lg) var(--bb-radius-lg) 0 0' : 'var(--bb-radius-lg)',
      boxShadow: 'var(--bb-shadow-lg)', overflow: 'hidden',
      display: 'flex', flexDirection: 'column', maxHeight: mobile ? 760 : 'none',
    }}>
      {/* Handle (mobile) */}
      {mobile && (
        <div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0 2px', flexShrink: 0 }}>
          <span style={{ width: 40, height: 4, borderRadius: 999, background: 'var(--bb-border)' }} />
        </div>
      )}
      {/* Header */}
      <div style={{ padding: mobile ? '10px 20px 14px' : '20px 24px', display: 'flex', alignItems: 'center', gap: 14, borderBottom: '1px solid var(--bb-border-subtle)', flexShrink: 0 }}>
        <div style={{ width: 40, height: 40, borderRadius: 12, flexShrink: 0, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name="tune" size={22} />
        </div>
        <div style={{ flex: 1 }}>
          <h3 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Filtriraj rezervacije</h3>
          <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>
            <span className="bb-tnum">{activeCount}</span> {activeCount === 1 ? 'aktivan filter' : 'aktivnih filtera'}
          </p>
        </div>
        {!mobile && (
          <button type="button" aria-label="Zatvori" style={{ width: 36, height: 36, border: 'none', borderRadius: 'var(--bb-radius-sm)', background: 'transparent', color: 'var(--bb-text-tertiary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <BBIcon name="close" size={20} />
          </button>
        )}
      </div>

      {/* Body */}
      <div style={{ padding: mobile ? '16px 20px 8px' : '20px 24px 8px', overflowY: 'auto', flex: mobile ? 1 : 'none' }}>
        <FiltSection label="Status">
          <FiltChips options={FILT_STATUS} selected={status} onToggle={multi(setStatus)} size={mobile ? 'sm' : 'md'} />
        </FiltSection>
        <FiltSection label="Objekt">
          <FiltChips options={FILT_OBJEKT} selected={objekt} onToggle={(id) => setObjekt([id])} size={mobile ? 'sm' : 'md'} />
        </FiltSection>
        <FiltSection label="Razdoblje dolaska">
          <FiltChips options={FILT_PERIOD} selected={[period]} onToggle={(id) => setPeriod(id)} size={mobile ? 'sm' : 'md'} />
          {period === 'custom' && (
            <div style={{ display: 'flex', gap: 12, marginTop: 12 }}>
              <FiltDate label="Od" value="01.06.2026" />
              <FiltDate label="Do" value="30.06.2026" />
            </div>
          )}
        </FiltSection>
        <FiltSection label="Izvor rezervacije">
          <FiltChips options={FILT_SOURCE} selected={source} onToggle={multi(setSource)} size={mobile ? 'sm' : 'md'} />
        </FiltSection>
        <FiltSection label="Status plaćanja">
          <FiltChips options={FILT_PAY} selected={pay} onToggle={multi(setPay)} size={mobile ? 'sm' : 'md'} />
        </FiltSection>
        {!mobile && (
          <FiltSection label="Raspon iznosa">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <FiltAmount label="Najmanje" value="0" />
              <span style={{ color: 'var(--bb-text-tertiary)', marginTop: 22 }}>–</span>
              <FiltAmount label="Najviše" value="1000" />
            </div>
          </FiltSection>
        )}
      </div>

      {/* Footer */}
      <div style={{ padding: mobile ? '12px 20px 22px' : '16px 24px', display: 'flex', alignItems: 'center', gap: 12, borderTop: '1px solid var(--bb-border-subtle)', background: 'var(--bb-surface)', flexShrink: 0 }}>
        <BBButton variant="tertiary" iconLeft="restart_alt" disabled={activeCount === 0}>Poništi sve</BBButton>
        <div style={{ flex: 1 }} />
        <BBButton variant="primary" iconLeft="check" style={mobile ? { flex: 1 } : {}}>Prikaži 12 rezervacija</BBButton>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Gallery wrappers
// ──────────────────────────────────────────────────────────────
const FiltersDialogDesktop = () => (
  <div className="theme-light" style={{
    width: 960, height: 900, background: 'rgba(13, 17, 28, 0.72)',
    fontFamily: 'var(--bb-font-sans)',
    display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24,
  }}>
    <FilterPanel />
  </div>
);

const FiltersDialogMobile = () => (
  <div className="theme-light" style={{
    width: 390, height: 880, background: 'rgba(13, 17, 28, 0.55)',
    fontFamily: 'var(--bb-font-sans)', position: 'relative',
  }}>
    {/* faint context behind scrim */}
    <div style={{ position: 'absolute', inset: 0, padding: 16, background: 'var(--bb-bg)', opacity: 0.4 }}>
      <div style={{ height: 56, background: 'var(--bb-surface)', borderRadius: 12, marginBottom: 16 }} />
      <div style={{ height: 120, background: 'var(--bb-surface)', borderRadius: 16, marginBottom: 12 }} />
      <div style={{ height: 120, background: 'var(--bb-surface)', borderRadius: 16 }} />
    </div>
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(13, 17, 28, 0.40)', backdropFilter: 'blur(2px)', WebkitBackdropFilter: 'blur(2px)' }} />
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}>
      <FilterPanel mobile />
    </div>
  </div>
);

Object.assign(window, { FiltersDialogDesktop, FiltersDialogMobile });
