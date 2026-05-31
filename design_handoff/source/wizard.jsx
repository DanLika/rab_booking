/* eslint-disable */
// Unit Wizard — Prompts 10–11. Focused full-screen creation flow ("Nova jedinica", Navigator.push route).
// 4-step stepper · Osnovno → Kapacitet → Fotografije → Cijena i objava.
// Publish flow (Step 4) is FROZEN — structure locked, only chrome. Marked with a FROZEN badge on the stepper.
// No sidebar (pushed route). Composes from BB primitives + wizard-specific controls.

const WIZ_STEPS = [
  { n: 1, label: 'Osnovno',    icon: 'description' },
  { n: 2, label: 'Kapacitet',  icon: 'hotel' },
  { n: 3, label: 'Fotografije', icon: 'photo_library' },
  { n: 4, label: 'Objava',     icon: 'rocket_launch', frozen: true },
];
const WIZ_META = {
  1: { title: 'Osnovni podaci',        sub: 'Naziv, tip i opis nove smještajne jedinice' },
  2: { title: 'Kapacitet i sadržaji',  sub: 'Koliko gostiju prima i što nudi' },
  3: { title: 'Fotografije',           sub: 'Prva fotografija je naslovna' },
  4: { title: 'Cijena i objava',       sub: 'Postavite cijene i objavite jedinicu' },
};

// ──────────────────────────────────────────────────────────────
// Stepper
// ──────────────────────────────────────────────────────────────
const FrozenBadge = ({ style = {} }) => (
  <span style={{
    fontSize: 9, fontWeight: 700, color: 'var(--bb-text-tertiary)',
    background: 'var(--bb-surface-variant)', padding: '2px 6px', borderRadius: 4,
    letterSpacing: '0.04em', ...style,
  }}>FROZEN</span>
);

const WizStepper = ({ current = 1, compact = false }) => {
  if (compact) {
    return (
      <div style={{ padding: '12px 16px', borderBottom: '1px solid var(--bb-border-subtle)', background: 'var(--bb-surface)' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 8 }}>
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>
            Korak <span className="bb-tnum">{current}</span> od <span className="bb-tnum">4</span>
          </span>
          <span className="bb-label" style={{ color: 'var(--bb-primary)', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            {WIZ_STEPS[current - 1].label}
            {WIZ_STEPS[current - 1].frozen && <FrozenBadge />}
          </span>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {WIZ_STEPS.map(s => (
            <div key={s.n} style={{ flex: 1, height: 6, borderRadius: 999, background: s.n <= current ? 'var(--bb-primary)' : 'var(--bb-border)' }} />
          ))}
        </div>
      </div>
    );
  }
  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '20px 28px', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      {WIZ_STEPS.map((s, i) => {
        const done = current > s.n;
        const cur = current === s.n;
        const nodeBg = done || cur ? 'var(--bb-primary)' : 'var(--bb-surface)';
        const nodeColor = done || cur ? '#FFFFFF' : 'var(--bb-text-tertiary)';
        return (
          <React.Fragment key={s.n}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
              <div style={{
                width: 34, height: 34, borderRadius: '50%', flexShrink: 0,
                background: nodeBg, color: nodeColor,
                border: done || cur ? 'none' : '1.5px solid var(--bb-border)',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 14, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
                boxShadow: cur ? 'var(--bb-shadow-purple-sm)' : 'none',
              }}>
                {done ? <BBIcon name="check" size={18} /> : s.n}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span className="bb-label" style={{ color: cur ? 'var(--bb-primary)' : done ? 'var(--bb-text-secondary)' : 'var(--bb-text-tertiary)', fontWeight: cur ? 700 : 600 }}>{s.label}</span>
                {s.frozen && <FrozenBadge />}
              </div>
            </div>
            {i < WIZ_STEPS.length - 1 && (
              <div style={{ flex: 1, height: 2, margin: '0 14px', borderRadius: 999, background: done ? 'var(--bb-primary)' : 'var(--bb-border)' }} />
            )}
          </React.Fragment>
        );
      })}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Wizard-specific controls
// ──────────────────────────────────────────────────────────────
const WizSelect = ({ label, value, icon, helper }) => (
  <div>
    {label && <label className="bb-label" style={{ display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)' }}>{label}</label>}
    <div style={{ height: 48, display: 'flex', alignItems: 'center', gap: 10, padding: '0 14px', borderRadius: 'var(--bb-radius-sm)', background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', cursor: 'pointer' }}>
      {icon && <BBIcon name={icon} size={18} style={{ color: 'var(--bb-text-tertiary)' }} />}
      <span style={{ flex: 1, fontSize: 14, color: 'var(--bb-text-primary)', fontWeight: 500 }}>{value}</span>
      <BBIcon name="expand_more" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
    </div>
    {helper && <div className="bb-caption" style={{ marginTop: 6, color: 'var(--bb-text-tertiary)' }}>{helper}</div>}
  </div>
);

const WizCounter = ({ label, icon, value, min = 0 }) => (
  <div style={{ padding: 14, border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-sm)', background: 'var(--bb-surface)' }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
      <BBIcon name={icon} size={16} style={{ color: 'var(--bb-text-tertiary)' }} />
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{label}</span>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <button type="button" style={wizCounterBtn(value <= min)} aria-label="Smanji"><BBIcon name="remove" size={16} /></button>
      <span className="bb-tnum" style={{ fontSize: 20, fontWeight: 700, color: 'var(--bb-text-primary)' }}>{value}</span>
      <button type="button" style={wizCounterBtn(false)} aria-label="Povećaj"><BBIcon name="add" size={16} /></button>
    </div>
  </div>
);
function wizCounterBtn(disabled) {
  return {
    width: 34, height: 34, borderRadius: 999, cursor: disabled ? 'not-allowed' : 'pointer',
    background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', color: 'var(--bb-text-primary)',
    opacity: disabled ? 0.4 : 1, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
  };
}

const WizTextarea = ({ label, value, placeholder, rows = 3, helper, charLimit = 600 }) => (
  <div>
    {label && <label className="bb-label" style={{ display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)' }}>{label}</label>}
    <textarea defaultValue={value} placeholder={placeholder} rows={rows} style={{
      width: '100%', padding: 14, resize: 'vertical', outline: 'none',
      background: 'var(--bb-surface)', border: '1px solid var(--bb-border)', borderRadius: 'var(--bb-radius-sm)',
      color: 'var(--bb-text-primary)', fontFamily: 'var(--bb-font-sans)', fontSize: 14, lineHeight: 1.5,
    }} />
    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{helper || ''}</span>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{(value || '').length}/{charLimit}</span>
    </div>
  </div>
);

const WizFieldLabel = ({ children }) => (
  <h4 className="bb-label" style={{ margin: '0 0 12px', color: 'var(--bb-text-primary)', fontWeight: 700, fontSize: 14 }}>{children}</h4>
);

// ──────────────────────────────────────────────────────────────
// Step 1 · Osnovni podaci
// ──────────────────────────────────────────────────────────────
const WIZ_TYPES = [
  { id: 'studio', icon: 'single_bed', label: 'Studio' },
  { id: 'apartman', icon: 'bed', label: 'Apartman' },
  { id: 'soba', icon: 'meeting_room', label: 'Soba' },
  { id: 'vila', icon: 'villa', label: 'Vila' },
  { id: 'kuca', icon: 'home', label: 'Kuća' },
];

const WizStep1 = ({ compact = false }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: compact ? 18 : 22 }}>
    <WizSelect label="Objekt" icon="domain" value="Vila Marina" helper="Jedinica će biti dodana ovom objektu" />
    <BBInput label="Naziv jedinice" value="Studio s pogledom na more" iconLeft="bed" />
    <div>
      <WizFieldLabel>Tip jedinice</WizFieldLabel>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        {WIZ_TYPES.map(t => (
          <BBChip key={t.id} iconLeft={t.icon} selected={t.id === 'studio'}>{t.label}</BBChip>
        ))}
      </div>
    </div>
    {!compact && (
      <WizTextarea label="Kratak opis" value="Svijetli studio s balkonom i pogledom na more, 50 m od plaže. Klima, brzi WiFi i potpuno opremljena kuhinja." placeholder="Opišite jedinicu gostima…" rows={3} helper="Prikazuje se u widgetu pri rezervaciji" charLimit={600} />
    )}
    <BBInput label="URL slug" value="vm-studio-more" iconLeft="link" helper="Automatski iz naziva · koristi se u widget poveznici" />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Step 2 · Kapacitet i sadržaji
// ──────────────────────────────────────────────────────────────
const WIZ_AMENITIES = [
  { icon: 'wifi', label: 'WiFi', on: true },
  { icon: 'ac_unit', label: 'Klima', on: true },
  { icon: 'local_parking', label: 'Parking', on: true },
  { icon: 'kitchen', label: 'Kuhinja', on: true },
  { icon: 'tv', label: 'TV', on: true },
  { icon: 'deck', label: 'Terasa', on: true },
  { icon: 'water', label: 'Pogled na more', on: true },
  { icon: 'local_laundry_service', label: 'Perilica rublja', on: false },
  { icon: 'pool', label: 'Bazen', on: false },
  { icon: 'pets', label: 'Ljubimci', on: false },
  { icon: 'elevator', label: 'Lift', on: false },
  { icon: 'smoke_free', label: 'Zabranjeno pušenje', on: true },
];

const WizStep2 = ({ compact = false }) => {
  const amenities = compact ? WIZ_AMENITIES.slice(0, 8) : WIZ_AMENITIES;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: compact ? 18 : 24 }}>
      <div>
        <WizFieldLabel>Kapacitet</WizFieldLabel>
        <div style={{ display: 'grid', gridTemplateColumns: compact ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)', gap: 12 }}>
          <WizCounter label="Spavaće sobe" icon="hotel" value={1} min={0} />
          <WizCounter label="Kupaonice" icon="bathtub" value={1} min={1} />
          <WizCounter label="Maks. gostiju" icon="group" value={2} min={1} />
          <WizCounter label="Kreveti" icon="king_bed" value={1} min={1} />
        </div>
      </div>
      <BBInput label="Površina (m²)" value="42" iconLeft="square_foot" />
      <div>
        <WizFieldLabel>Sadržaji</WizFieldLabel>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {amenities.map((a, i) => (
            <BBChip key={i} iconLeft={a.icon} selected={a.on}>{a.label}</BBChip>
          ))}
          {compact && <BBChip iconLeft="add">Više</BBChip>}
        </div>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Step 3 · Fotografije
// ──────────────────────────────────────────────────────────────
const WizPhotoTile = ({ cover = false }) => (
  <div style={{
    position: 'relative', aspectRatio: '4 / 3', borderRadius: 'var(--bb-radius-sm)', overflow: 'hidden',
    background: 'repeating-linear-gradient(135deg, var(--bb-surface-variant) 0 9px, var(--bb-bg) 9px 18px)',
    border: '1px solid var(--bb-border-subtle)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  }}>
    <BBIcon name="image" size={28} style={{ color: 'var(--bb-text-disabled)' }} />
    {cover && (
      <span style={{ position: 'absolute', top: 8, left: 8, background: 'var(--bb-primary)', color: '#FFFFFF', fontSize: 10, fontWeight: 700, padding: '3px 8px', borderRadius: 999, letterSpacing: '0.03em' }}>Naslovna</span>
    )}
    <button type="button" aria-label="Ukloni" style={{ position: 'absolute', top: 6, right: 6, width: 26, height: 26, borderRadius: 999, border: 'none', background: 'rgba(27,35,48,0.7)', color: '#FFFFFF', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <BBIcon name="close" size={15} />
    </button>
  </div>
);

const WizAddTile = () => (
  <button type="button" style={{
    aspectRatio: '4 / 3', borderRadius: 'var(--bb-radius-sm)', cursor: 'pointer',
    border: '2px dashed var(--bb-border)', background: 'var(--bb-surface)',
    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4,
    color: 'var(--bb-text-tertiary)',
  }}>
    <BBIcon name="add_photo_alternate" size={26} style={{ color: 'var(--bb-primary)' }} />
    <span className="bb-caption" style={{ fontWeight: 600 }}>Dodaj</span>
  </button>
);

const WizStep3 = ({ compact = false }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
    {/* Drop zone */}
    <div style={{
      border: '2px dashed var(--bb-border)', borderRadius: 'var(--bb-radius-md)',
      background: 'var(--bb-primary-tint-bg)',
      padding: compact ? 24 : 32, textAlign: 'center',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
    }}>
      <div style={{ width: 52, height: 52, borderRadius: 14, background: 'var(--bb-surface)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--bb-shadow-sm)' }}>
        <BBIcon name="cloud_upload" size={26} />
      </div>
      <div className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Povucite fotografije ovdje</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>ili kliknite za odabir · JPG ili PNG do 5 MB</div>
      <div style={{ marginTop: 8 }}><BBButton variant="secondary" size="sm" iconLeft="upload">Odaberi datoteke</BBButton></div>
    </div>
    {/* Gallery */}
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <WizFieldLabel>Učitane fotografije <span className="bb-tnum" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>· 4</span></WizFieldLabel>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Povucite za promjenu redoslijeda</span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: compact ? 'repeat(3, 1fr)' : 'repeat(5, 1fr)', gap: 12 }}>
        {[
          { id: 'bb-wiz-photo-1', cover: true, ph: 'Naslovna' },
          { id: 'bb-wiz-photo-2', ph: 'Fotografija 2' },
          { id: 'bb-wiz-photo-3', ph: 'Fotografija 3' },
          { id: 'bb-wiz-photo-4', ph: 'Fotografija 4' },
        ].map(s => (
          <div key={s.id} style={{ position: 'relative', aspectRatio: '4 / 3' }}>
            <image-slot
              id={s.id}
              shape="rounded"
              radius="12"
              placeholder={s.ph}
              style={{ display: 'block', width: '100%', height: '100%' }}
            ></image-slot>
            {s.cover && (
              <span style={{
                position: 'absolute', top: 8, left: 8, pointerEvents: 'none',
                background: 'var(--bb-primary)', color: '#FFFFFF',
                fontSize: 10, fontWeight: 700, padding: '3px 8px', borderRadius: 999, letterSpacing: '0.03em',
                boxShadow: 'var(--bb-shadow-purple-sm)',
              }}>Naslovna</span>
            )}
          </div>
        ))}
        <WizAddTile />
      </div>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Step 4 · Cijena i objava  (FROZEN publish flow)
// ──────────────────────────────────────────────────────────────
const WizPriceField = ({ label, value, prefix, suffix, icon }) => (
  <div>
    <label className="bb-label" style={{ display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)' }}>{label}</label>
    <div style={{ height: 48, display: 'flex', alignItems: 'center', gap: 8, padding: '0 14px', borderRadius: 'var(--bb-radius-sm)', background: 'var(--bb-surface)', border: '1px solid var(--bb-border)' }}>
      {icon && <BBIcon name={icon} size={18} style={{ color: 'var(--bb-text-tertiary)' }} />}
      {prefix && <span className="bb-body" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>{prefix}</span>}
      <input defaultValue={value} style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: 600, color: 'var(--bb-text-primary)', fontVariantNumeric: 'tabular-nums', padding: 0 }} />
      {suffix && <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{suffix}</span>}
    </div>
  </div>
);

const WizVisibilityOption = ({ icon, title, sub, selected }) => (
  <button type="button" style={{
    flex: 1, textAlign: 'left', cursor: 'pointer',
    padding: 14, borderRadius: 'var(--bb-radius-sm)',
    background: selected ? 'var(--bb-primary-tint-bg)' : 'var(--bb-surface)',
    border: `${selected ? '2px' : '1px'} solid ${selected ? 'var(--bb-primary)' : 'var(--bb-border)'}`,
    display: 'flex', alignItems: 'center', gap: 12,
  }}>
    <div style={{ width: 36, height: 36, borderRadius: 10, background: selected ? 'var(--bb-primary)' : 'var(--bb-surface-variant)', color: selected ? '#FFFFFF' : 'var(--bb-text-secondary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
      <BBIcon name={icon} size={18} />
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{title}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{sub}</div>
    </div>
    <span style={{ width: 20, height: 20, borderRadius: '50%', flexShrink: 0, background: selected ? 'var(--bb-primary)' : 'var(--bb-surface)', border: `2px solid ${selected ? 'var(--bb-primary)' : 'var(--bb-border)'}`, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      {selected && <BBIcon name="check" size={12} style={{ color: '#FFFFFF' }} />}
    </span>
  </button>
);

const WizSummary = ({ compact = false }) => (
  <div style={{ borderRadius: 'var(--bb-radius-md)', border: '1px solid var(--bb-border-subtle)', background: 'var(--bb-surface-variant)', padding: compact ? 16 : 18 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
      <div style={{ width: 44, height: 44, borderRadius: 12, background: 'var(--bb-gradient-hero)', color: '#FFFFFF', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: 'var(--bb-shadow-purple-sm)' }}>
        <BBIcon name="bed" size={22} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>Studio s pogledom na more</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Vila Marina · Studio · do 2 gosta</div>
      </div>
      <BBStatusBadge status="confirmed" label="Spremno" dot size="sm" />
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
      <WizSummaryStat label="Cijena/noć" value="€120" />
      <WizSummaryStat label="Fotografije" value="4" />
      <WizSummaryStat label="Sadržaji" value="8" />
    </div>
  </div>
);
const WizSummaryStat = ({ label, value }) => (
  <div style={{ padding: '10px 12px', background: 'var(--bb-surface)', borderRadius: 'var(--bb-radius-sm)' }}>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{label}</div>
    <div className="bb-tnum" style={{ fontSize: 18, fontWeight: 700, color: 'var(--bb-text-primary)', marginTop: 2 }}>{value}</div>
  </div>
);

const WizStep4 = ({ compact = false }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: compact ? 18 : 22 }}>
    <div>
      <WizFieldLabel>Cijene</WizFieldLabel>
      <div style={{ display: 'grid', gridTemplateColumns: compact ? 'repeat(2, 1fr)' : 'repeat(4, 1fr)', gap: 12 }}>
        <WizPriceField label="Cijena po noći" value="120" prefix="€" icon="payments" />
        <WizPriceField label="Vikend (Pet–Sub)" value="130" prefix="€" />
        <WizPriceField label="Min. boravak" value="1" suffix="noć" />
        <WizPriceField label="Polog" value="20" suffix="%" />
      </div>
      <div style={{ marginTop: 10, padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 10, background: 'var(--bb-primary-tint-bg)', borderRadius: 'var(--bb-radius-sm)' }}>
        <BBIcon name="info" size={16} style={{ color: 'var(--bb-primary)', flexShrink: 0 }} />
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>Cijene po datumu uređujete kasnije u tabu <strong style={{ color: 'var(--bb-primary)', fontWeight: 600 }}>Cjenovnik</strong>.</span>
      </div>
    </div>
    <div>
      <WizFieldLabel>Vidljivost</WizFieldLabel>
      <div style={{ display: 'flex', gap: 12, flexDirection: compact ? 'column' : 'row' }}>
        <WizVisibilityOption icon="public" title="Javno" sub="Vidljivo u widgetu odmah" selected />
        <WizVisibilityOption icon="visibility_off" title="Skriveno" sub="Spremi kao skicu" />
      </div>
    </div>
    <div>
      <WizFieldLabel>Pregled prije objave</WizFieldLabel>
      <WizSummary compact={compact} />
    </div>
  </div>
);

const wizContent = (step, compact) => {
  if (step === 1) return <WizStep1 compact={compact} />;
  if (step === 2) return <WizStep2 compact={compact} />;
  if (step === 3) return <WizStep3 compact={compact} />;
  return <WizStep4 compact={compact} />;
};

// ──────────────────────────────────────────────────────────────
// Footer
// ──────────────────────────────────────────────────────────────
const WizFooter = ({ step, compact = false }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: compact ? 14 : '16px 28px',
    borderTop: '1px solid var(--bb-border-subtle)', background: 'var(--bb-surface)',
  }}>
    {step > 1
      ? <BBButton variant="secondary" iconLeft="arrow_back" size={compact ? 'md' : 'md'} style={compact ? { flex: 1 } : {}}>Natrag</BBButton>
      : <BBButton variant="tertiary" size="md" style={compact ? { flex: 1 } : {}}>Odustani</BBButton>}
    <div style={{ flex: compact ? 0 : 1 }} />
    {!compact && (
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', display: 'inline-flex', alignItems: 'center', gap: 6 }}>
        <BBIcon name="cloud_done" size={15} style={{ color: 'var(--bb-success)' }} /> Skica spremljena
      </span>
    )}
    {step < 4
      ? <BBButton variant="primary" iconRight="arrow_forward" style={compact ? { flex: 2 } : {}}>Dalje</BBButton>
      : <BBButton variant="primary" iconLeft="rocket_launch" style={compact ? { flex: 2 } : {}}>Objavi jedinicu</BBButton>}
  </div>
);

// ──────────────────────────────────────────────────────────────
// Header (in-card / mobile app-bar)
// ──────────────────────────────────────────────────────────────
const WizHeader = ({ step, compact = false }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: compact ? '0 12px' : '0 28px',
    height: compact ? 56 : 64,
    borderBottom: compact ? '1px solid var(--bb-border-subtle)' : 'none',
    background: 'var(--bb-surface)',
    flexShrink: 0,
  }}>
    <button type="button" aria-label="Zatvori" style={{
      width: 40, height: 40, borderRadius: 'var(--bb-radius-sm)', border: 'none', background: 'transparent',
      color: 'var(--bb-text-secondary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginLeft: -8,
    }}>
      <BBIcon name="close" size={22} />
    </button>
    <div style={{ flex: 1, minWidth: 0 }}>
      <h2 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Nova jedinica</h2>
      {!compact && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 1 }}>{WIZ_META[step].title} · {WIZ_META[step].sub}</div>}
    </div>
    {!compact && (
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>Korak {step} / 4</span>
    )}
  </div>
);

// ──────────────────────────────────────────────────────────────
// Shells
// ──────────────────────────────────────────────────────────────
const WizardDesktop = ({ step }) => (
  <div className="theme-light bb-screen" style={{
    width: 1440, height: 1100, fontFamily: 'var(--bb-font-sans)',
    background: 'linear-gradient(180deg, var(--bb-surface-variant) 0%, var(--bb-bg) 60%)',
    display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '48px 0',
  }}>
    <div style={{
      width: 820, maxWidth: '94%',
      background: 'var(--bb-surface)', borderRadius: 'var(--bb-radius-xl)',
      boxShadow: 'var(--bb-shadow-lg)', border: '1px solid var(--bb-border-subtle)',
      overflow: 'hidden', display: 'flex', flexDirection: 'column',
    }}>
      <WizHeader step={step} />
      <WizStepper current={step} />
      <div style={{ padding: '24px 28px' }}>
        {wizContent(step, false)}
      </div>
      <WizFooter step={step} />
    </div>
  </div>
);

const WizardTablet = ({ step }) => (
  <div className="theme-light bb-screen" style={{
    width: 768, height: 1024, fontFamily: 'var(--bb-font-sans)',
    background: 'linear-gradient(180deg, var(--bb-surface-variant) 0%, var(--bb-bg) 60%)',
    display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '32px 0',
  }}>
    <div style={{
      width: 640, maxWidth: '92%',
      background: 'var(--bb-surface)', borderRadius: 'var(--bb-radius-xl)',
      boxShadow: 'var(--bb-shadow-lg)', border: '1px solid var(--bb-border-subtle)',
      overflow: 'hidden', display: 'flex', flexDirection: 'column',
    }}>
      <WizHeader step={step} />
      <WizStepper current={step} />
      <div style={{ padding: '22px 24px' }}>
        {wizContent(step, true)}
      </div>
      <WizFooter step={step} />
    </div>
  </div>
);

const WizardMobile = ({ step }) => (
  <div className="theme-light bb-screen" style={{
    width: 390, height: 880, fontFamily: 'var(--bb-font-sans)',
    background: 'var(--bb-bg)', display: 'flex', flexDirection: 'column',
  }}>
    <WizHeader step={step} compact />
    <WizStepper current={step} compact />
    <main style={{ flex: 1, padding: '16px 16px 12px', overflow: 'hidden' }}>
      {wizContent(step, true)}
    </main>
    <WizFooter step={step} compact />
  </div>
);

// Step-specific exports
const WizardStep1Desktop = () => <WizardDesktop step={1} />;
const WizardStep2Desktop = () => <WizardDesktop step={2} />;
const WizardStep3Desktop = () => <WizardDesktop step={3} />;
const WizardStep4Desktop = () => <WizardDesktop step={4} />;
const WizardStep2Tablet  = () => <WizardTablet step={2} />;
const WizardStep1Mobile  = () => <WizardMobile step={1} />;
const WizardStep4Mobile  = () => <WizardMobile step={4} />;

Object.assign(window, {
  WizardStep1Desktop, WizardStep2Desktop, WizardStep3Desktop, WizardStep4Desktop,
  WizardStep2Tablet, WizardStep1Mobile, WizardStep4Mobile,
});
