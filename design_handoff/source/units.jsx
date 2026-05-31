/* eslint-disable */
// Units hub + Osnovno tab — Prompt 09 redesign.
// Cjenovnik tab is FROZEN (only €amounts bolded + colors token-ized).

const { useState: useStU } = React;

const PROPERTIES = [
  {
    id: 'p1', name: 'iOS Test Vila', units: [
      { id: 'u1', name: 'Test Unit A', status: 'available', capacity: 4, price: 120, slug: null },
    ],
  },
  {
    id: 'p2', name: 'Vila Marina', units: [
      { id: 'u2', name: 'Studio 4', status: 'available', capacity: 2, price: 140, slug: 'vm-studio-4' },
      { id: 'u3', name: 'Premium suite', status: 'available', capacity: 4, price: 280, slug: 'vm-premium-suite' },
    ],
  },
  {
    id: 'p3', name: 'Stan Lavanda', units: [
      { id: 'u4', name: 'Apartman A', status: 'available', capacity: 4, price: 120, slug: 'lavanda-a' },
      { id: 'u5', name: 'Studio B', status: 'off', capacity: 2, price: 90, slug: 'lavanda-b' },
    ],
  },
];

const SELECTED_UNIT = PROPERTIES[0].units[0]; // Test Unit A

// ──────────────────────────────────────────────────────────────
// Property tree (desktop left panel)
// ──────────────────────────────────────────────────────────────
const PropertyTree = ({ selectedId, totalUnits, showSearch }) => (
  <aside style={{
    width: 280, flexShrink: 0,
    background: 'var(--bb-surface)',
    border: '1px solid var(--bb-border-subtle)',
    borderRadius: 'var(--bb-radius-md)',
    boxShadow: 'var(--bb-shadow-sm)',
    overflow: 'hidden',
    height: 'fit-content',
  }}>
    <div style={{
      padding: '14px 16px 10px',
      display: 'flex', alignItems: 'center', gap: 8,
      borderBottom: '1px solid var(--bb-border-subtle)',
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 10,
        background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name="apartment" size={18} />
      </div>
      <div style={{ flex: 1 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Objekti i Jedinice</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
          <span className="bb-tnum">{PROPERTIES.length}</span> objekta · <span className="bb-tnum">{totalUnits}</span> jedinica
        </div>
      </div>
      <BBButton variant="tertiary" asIcon size="sm" iconLeft="add" ariaLabel="Novi objekt" />
    </div>

    {showSearch && (
      <div style={{ padding: '12px 12px 0' }}>
        <BBInput placeholder="Pretraži…" iconLeft="search" size="sm" />
      </div>
    )}

    <div style={{ padding: 12 }}>
      {PROPERTIES.map((prop, i) => (
        <div key={prop.id} style={{ marginBottom: i === PROPERTIES.length - 1 ? 0 : 8 }}>
          {/* Property header */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '8px 8px', borderRadius: 'var(--bb-radius-sm)',
          }}>
            <BBIcon name="expand_more" size={16} style={{ color: 'var(--bb-text-tertiary)' }} />
            <BBIcon name="domain" size={16} style={{ color: 'var(--bb-text-secondary)' }} />
            <span style={{ flex: 1, fontSize: 13, fontWeight: 600, color: 'var(--bb-text-primary)' }}>{prop.name}</span>
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
              <span className="bb-tnum">{prop.units.length}</span>
            </span>
          </div>
          {/* Units */}
          <div style={{ paddingLeft: 14 }}>
            {prop.units.map(u => (
              <UnitTreeItem key={u.id} unit={u} selected={u.id === selectedId} />
            ))}
          </div>
        </div>
      ))}
    </div>
  </aside>
);

const statusLabel = { available: 'Dostupno', off: 'Nedostupno', occupied: 'Zauzeto' };
const UnitTreeItem = ({ unit, selected }) => (
  <button type="button" style={{
    width: '100%', border: 'none', cursor: 'pointer',
    background: selected ? 'var(--bb-primary-tint-bg)' : 'transparent',
    borderRadius: 'var(--bb-radius-sm)',
    padding: '8px 10px', marginBottom: 4,
    display: 'flex', flexDirection: 'column', gap: 4,
    textAlign: 'left',
    borderLeft: selected ? '3px solid var(--bb-primary)' : '3px solid transparent',
  }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <BBIcon name="bed" size={14} style={{ color: selected ? 'var(--bb-primary)' : 'var(--bb-text-tertiary)' }} />
      <span style={{
        flex: 1, fontSize: 13, fontWeight: selected ? 600 : 500,
        color: selected ? 'var(--bb-primary)' : 'var(--bb-text-primary)',
      }}>{unit.name}</span>
      <span style={{
        fontSize: 10, fontWeight: 700, letterSpacing: '0.04em', textTransform: 'uppercase',
        color: unit.status === 'available' ? 'var(--bb-success)' : 'var(--bb-text-tertiary)',
      }}>{statusLabel[unit.status]}</span>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, paddingLeft: 22 }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
        <BBIcon name="group" size={11} style={{ verticalAlign: 'middle', marginRight: 2 }} />
        <span className="bb-tnum">{unit.capacity}</span>
      </span>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>
        €{unit.price}/noć
      </span>
    </div>
  </button>
);

// ──────────────────────────────────────────────────────────────
// Tabs
// ──────────────────────────────────────────────────────────────
const UnitTabs = ({ active = 'osnovno', size = 'desktop' }) => {
  const isCompact = size === 'mobile' || size === 'tablet';
  const tabs = [
    { id: 'osnovno',   icon: 'description',    label: 'Osnovno' },
    { id: 'cjenovnik', icon: 'payments',       label: 'Cjenovnik' },
    { id: 'widget',    icon: 'code',           label: 'Widget' },
    { id: 'napredno',  icon: 'tune',           label: 'Napredno' },
  ];
  return (
    <div style={{
      display: 'flex', gap: 4,
      borderBottom: '1px solid var(--bb-border-subtle)',
      marginBottom: 20,
      flexWrap: isCompact ? 'nowrap' : 'wrap',
      overflowX: isCompact ? 'auto' : 'visible',
    }}>
      {tabs.map(t => {
        const isActive = t.id === active;
        return (
          <button key={t.id} type="button" style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            padding: isCompact ? '12px 12px' : '14px 16px',
            border: 'none', background: 'transparent', cursor: 'pointer',
            color: isActive ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
            fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: isActive ? 600 : 500,
            borderBottom: `2px solid ${isActive ? 'var(--bb-primary)' : 'transparent'}`,
            marginBottom: -1,
            whiteSpace: 'nowrap', flexShrink: 0,
          }}>
            <BBIcon name={t.icon} size={18} fill={isActive ? 1 : 0} />
            {t.label}
            {t.id === 'cjenovnik' && (
              <span style={{
                fontSize: 9, fontWeight: 700,
                color: 'var(--bb-text-tertiary)',
                background: 'var(--bb-surface-variant)',
                padding: '2px 6px', borderRadius: 4,
                marginLeft: 2,
              }}>FROZEN</span>
            )}
          </button>
        );
      })}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Osnovno tab content
// ──────────────────────────────────────────────────────────────
const OsnovnoTabContent = ({ unit, compact = false, mobile = false }) => (
  <div>
    {/* Property gallery (desktop only — real photo drop zones: cover + extras) */}
    {!compact && (
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 8, height: 200, marginBottom: 16 }}>
        <image-slot
          id="bb-unit-cover"
          shape="rounded"
          radius="20"
          placeholder="Naslovna fotografija jedinice — povucite ovdje"
          style={{ display: 'block', width: '100%', height: '100%' }}
        ></image-slot>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr', gap: 8 }}>
          {[
            { id: 'bb-unit-photo-1', ph: 'Foto 2' },
            { id: 'bb-unit-photo-2', ph: 'Foto 3' },
            { id: 'bb-unit-photo-3', ph: 'Foto 4' },
            { id: 'bb-unit-photo-4', ph: 'Foto 5' },
          ].map(s => (
            <div key={s.id} style={{ position: 'relative' }}>
              <image-slot
                id={s.id}
                shape="rounded"
                radius="16"
                placeholder={s.ph}
                style={{ display: 'block', width: '100%', height: '100%' }}
              ></image-slot>
            </div>
          ))}
        </div>
      </div>
    )}
    {/* Header row */}
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      marginBottom: mobile ? 12 : 16,
    }}>
      <div>
        <h3 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{unit.name}</h3>
        <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>
          Osnovni podaci jedinice
        </p>
      </div>
      <div style={{ display: 'flex', gap: 8 }}>
        <BBButton variant="secondary" iconLeft="content_copy" size={compact ? 'sm' : 'md'}>Kopiraj</BBButton>
        <BBButton variant="primary" iconLeft="edit" size={compact ? 'sm' : 'md'}>Uredi</BBButton>
      </div>
    </div>

    {/* 2-col cards */}
    <div style={{
      display: 'grid',
      gridTemplateColumns: mobile ? 'repeat(2, 1fr)' : (compact ? '1fr' : 'repeat(2, 1fr)'),
      gap: mobile ? 12 : 16, marginBottom: mobile ? 12 : 16,
    }}>
      <BBCard>
        <CardHeader icon="info" title="Informacije" />
        <KeyValueRow label="Naziv" value={unit.name} stack={mobile} />
        <KeyValueRow label="URL slug" value={unit.slug ? unit.slug : null} placeholder="Nije postavljeno" stack={mobile} />
        <KeyValueRow label="Status" stack={mobile}>
          <BBStatusBadge status={unit.status === 'available' ? 'confirmed' : 'cancelled'}
                         label={unit.status === 'available' ? 'Dostupna' : 'Nedostupna'} dot size="sm" />
        </KeyValueRow>
        <KeyValueRow label="Vidljivost" value="Javno · widget aktivan" last stack={mobile} />
      </BBCard>

      <BBCard>
        <CardHeader icon="hotel" title="Kapacitet" />
        <KeyValueRow label="Spavaće sobe" value="1" stack={mobile} />
        <KeyValueRow label="Kupaonice" value="1" stack={mobile} />
        <KeyValueRow label="Maks. gostiju" value={String(unit.capacity)} stack={mobile} />
        <KeyValueRow label="Površina" value="42 m²" last stack={mobile} />
      </BBCard>
    </div>

    <BBCard>
      <CardHeader icon="euro" title="Cijena" />
      <div style={{
        display: 'grid',
        gridTemplateColumns: compact ? 'repeat(3, 1fr)' : 'repeat(4, 1fr)',
        gap: 16, marginTop: 14,
      }}>
        <PriceTile label="Cijena po noći" value="€120" emphasis />
        <PriceTile label="Vikend (Pet–Sub)" value="€130" />
        <PriceTile label="Min. boravak" value="1 noć" />
        {!compact && <PriceTile label="Polog" value="20%" />}
      </div>
      <div style={{
        marginTop: 16, padding: '10px 12px',
        display: 'flex', alignItems: 'center', gap: 10,
        background: 'var(--bb-primary-tint-bg)', borderRadius: 'var(--bb-radius-sm)',
      }}>
        <BBIcon name="info" size={16} style={{ color: 'var(--bb-primary)', flexShrink: 0 }} />
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>
          Napredne cijene po datumu uređuju se u tabu <strong style={{ color: 'var(--bb-primary)', fontWeight: 600 }}>Cjenovnik</strong>.
        </span>
      </div>
    </BBCard>
  </div>
);

const CardHeader = ({ icon, title }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
    <div style={{
      width: 32, height: 32, borderRadius: 10,
      background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name={icon} size={18} />
    </div>
    <h4 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h4>
  </div>
);

const KeyValueRow = ({ label, value, placeholder, children, last = false, stack = false }) => (
  <div style={{
    display: 'flex',
    flexDirection: stack ? 'column' : 'row',
    alignItems: stack ? 'flex-start' : 'center',
    justifyContent: 'space-between',
    gap: stack ? 3 : 0,
    padding: stack ? '8px 0' : '10px 0',
    borderBottom: last ? 'none' : '1px solid var(--bb-border-subtle)',
  }}>
    <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 11, fontWeight: 600 }}>
      {label}
    </span>
    {children ? children : (
      value ? (
        <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{value}</span>
      ) : (
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontStyle: 'italic' }}>{placeholder}</span>
      )
    )}
  </div>
);

const PriceTile = ({ label, value, emphasis }) => (
  <div style={{
    padding: 14,
    background: emphasis ? 'var(--bb-primary-tint-bg)' : 'var(--bb-surface-variant)',
    borderRadius: 'var(--bb-radius-sm)',
    border: emphasis ? '1px solid rgba(107,76,230,0.2)' : 'none',
  }}>
    <div className="bb-caption" style={{
      color: 'var(--bb-text-tertiary)', textTransform: 'uppercase',
      letterSpacing: '0.04em', fontSize: 10, fontWeight: 600, marginBottom: 4,
    }}>{label}</div>
    <div className="bb-tnum" style={{
      fontSize: 22, fontWeight: 700,
      color: emphasis ? 'var(--bb-primary)' : 'var(--bb-text-primary)',
    }}>{value}</div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Unit picker dropdown (tablet + mobile alternative to left tree)
// ──────────────────────────────────────────────────────────────
const UnitDropdown = ({ unit }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '12px 14px',
    background: 'var(--bb-surface)',
    border: '1px solid var(--bb-border)',
    borderRadius: 'var(--bb-radius-sm)',
    cursor: 'pointer',
    marginBottom: 16,
  }}>
    <div style={{
      width: 36, height: 36, borderRadius: 10,
      background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name="bed" size={18} />
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{unit.name}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
        iOS Test Vila · 5 jedinica ukupno
      </div>
    </div>
    <BBStatusBadge status="confirmed" label="Dostupna" size="sm" />
    <BBIcon name="expand_more" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
  </div>
);

// ──────────────────────────────────────────────────────────────
// UnitsDesktop (1440 × 1100)
// ──────────────────────────────────────────────────────────────
const UnitsDesktop = () => {
  const totalUnits = PROPERTIES.reduce((s, p) => s + p.units.length, 0);
  return (
    <div className="theme-light bb-screen bb-shell" style={{
      width: 1440, height: 1100, display: 'flex',
      background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    }}>
      <BBSidebar user={SAMPLE_USER} active="jedinice" pendingCount={1} notifCount={6} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <BBAppBar
          breadcrumb={['Početna', 'Smještajne Jedinice']}
          notifCount={6}
          actions={[
            { icon: 'search', label: 'Pretraži' },
            { icon: 'light_mode', label: 'Tema' },
          ]}
        />
        <main style={{ padding: '24px 32px 32px', flex: 1, display: 'flex', gap: 20, overflow: 'hidden' }}>
          <PropertyTree selectedId={SELECTED_UNIT.id} totalUnits={totalUnits} showSearch={totalUnits > 5} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <UnitTabs active="osnovno" size="desktop" />
            <OsnovnoTabContent unit={SELECTED_UNIT} />
          </div>
          <div style={{ width: 56, flexShrink: 0 }}>
            <BBButton variant="primary" asIcon iconLeft="add" ariaLabel="Nova jedinica" size="lg" />
          </div>
        </main>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// UnitsTablet (768 × 1024)
// ──────────────────────────────────────────────────────────────
const UnitsTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 768, height: 1024, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebarRail active="jedinice" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Početna', 'Smještajne Jedinice']} notifCount={6} actions={[
        { icon: 'add', label: 'Nova jedinica' },
      ]} />
      <main style={{ padding: '16px 24px 16px', flex: 1, overflow: 'hidden' }}>
        <UnitDropdown unit={SELECTED_UNIT} />
        <UnitTabs active="osnovno" size="tablet" />
        <OsnovnoTabContent unit={SELECTED_UNIT} compact />
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// UnitsMobile (390 × 880)
// ──────────────────────────────────────────────────────────────
const UnitsMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 390, height: 880,
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    display: 'flex', flexDirection: 'column',
  }}>
    <BBAppBar title="Jedinice" showHamburger notifCount={6} actions={[{ icon: 'add', label: 'Nova' }]} />
    <main style={{ padding: '12px 16px 0', flex: 1, overflow: 'hidden' }}>
      <UnitDropdown unit={SELECTED_UNIT} />
      <UnitTabs active="osnovno" size="mobile" />
      <OsnovnoTabContent unit={SELECTED_UNIT} compact mobile />
    </main>
  </div>
);

Object.assign(window, { UnitsDesktop, UnitsTablet, UnitsMobile });
