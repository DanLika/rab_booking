/* eslint-disable */
// Cross-platform parity — Prompt 39. Validates breakpoint consistency: nav adaptation, specs, parity checklist.
// Reuses BBSidebar / BBSidebarRail / BBAppBar (real components) + StPanel.

const CP_SPECS = [
  { bp: 'Desktop', icon: 'computer', range: '≥ 1024px', dims: '1440 × 1100', nav: 'Sidebar 260px', cols: '2–4 stupca', notes: 'Hover stanja · guste tablice · master-detail' },
  { bp: 'Tablet', icon: 'tablet_mac', range: '768–1023px', dims: '768 × 1024', nav: 'Ikonska traka 72px', cols: '1–2 stupca', notes: 'Dodir + hover · kompaktne kartice' },
  { bp: 'Mobile', icon: 'smartphone', range: '< 768px', dims: '390 × 880', nav: 'App bar + hamburger', cols: '1 stupac', notes: 'Lijepljive CTA · bottom-sheets · 44px mete' },
];

const CP_PARITY = [
  { ok: true, t: 'Hrvatski tekst na svim platformama' },
  { ok: true, t: 'Tabularne brojke na svim numeričkim vrijednostima' },
  { ok: true, t: 'Min. 44px dodirne mete (mobilno)' },
  { ok: true, t: '8px mreža razmaka (bez 12px)' },
  { ok: true, t: 'Dosljedne statusne boje (potvrđeno / čekanje / …)' },
  { ok: true, t: 'Svijetla i tamna tema (.theme-light / .theme-dark)' },
  { ok: true, t: 'Sigurnosni razmaci (safe-area) na mobitelu' },
  { ok: true, t: 'Poštivanje „smanji animacije” (reduced-motion)' },
];

const CPNavPanel = ({ label, sub, children }) => (
  <div style={{ display: 'flex', flexDirection: 'column' }}>
    <div style={{ marginBottom: 10 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{label}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{sub}</div>
    </div>
    <div style={{ height: 440, display: 'flex', overflow: 'hidden', borderRadius: 'var(--bb-radius-md)', border: '1px solid var(--bb-border-subtle)', boxShadow: 'var(--bb-shadow-sm)' }}>
      {children}
    </div>
  </div>
);

const CPSpecCard = ({ s }) => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
      <div style={{ width: 40, height: 40, borderRadius: 12, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={s.icon} size={22} />
      </div>
      <div>
        <div className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{s.bp}</div>
        <div className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{s.range}</div>
      </div>
    </div>
    <KeyValueRow label="Dimenzije" value={s.dims} />
    <KeyValueRow label="Navigacija" value={s.nav} />
    <KeyValueRow label="Stupci" value={s.cols} />
    <div style={{ paddingTop: 10 }}>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700, marginBottom: 4 }}>Naglasci</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', lineHeight: 1.5 }}>{s.notes}</div>
    </div>
  </BBCard>
);

const CPBoard = () => (
  <div className="theme-light" style={{ width: 1320, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', padding: 40 }}>
    <div style={{ marginBottom: 28 }}>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)' }}>Prompt 39 · QA sweep</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0', color: 'var(--bb-text-primary)' }}>Cross-platform parity</h2>
      <p className="bb-body" style={{ margin: '6px 0 0', color: 'var(--bb-text-tertiary)' }}>Ista informacijska arhitektura i komponente — navigacija se prilagođava širini.</p>
    </div>

    {/* Nav adaptation */}
    <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 14 }}>Prilagodba navigacije</div>
    <div style={{ display: 'grid', gridTemplateColumns: '260px 120px 1fr', gap: 24, marginBottom: 36, alignItems: 'start' }}>
      <CPNavPanel label="Desktop" sub="Sidebar 260px">
        <BBSidebar user={SAMPLE_USER} active="pregled" pendingCount={1} notifCount={6} />
      </CPNavPanel>
      <CPNavPanel label="Tablet" sub="Rail 72px">
        <BBSidebarRail active="pregled" pendingCount={1} notifCount={6} />
      </CPNavPanel>
      <CPNavPanel label="Mobile" sub="App bar + hamburger + drawer">
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: 'var(--bb-bg)' }}>
          <BBAppBar title="Pregled" showHamburger notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} />
          <div style={{ flex: 1, padding: 16, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <BBSkeleton w="100%" h={88} radius={16} />
            <div style={{ display: 'flex', gap: 12 }}>
              <BBSkeleton w="100%" h={64} radius={12} />
              <BBSkeleton w="100%" h={64} radius={12} />
              <BBSkeleton w="100%" h={64} radius={12} />
            </div>
            <BBSkeleton w="100%" h={140} radius={16} />
          </div>
        </div>
      </CPNavPanel>
    </div>

    {/* Specs */}
    <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 14 }}>Specifikacije po točki loma</div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, marginBottom: 36 }}>
      {CP_SPECS.map((s, i) => <CPSpecCard key={i} s={s} />)}
    </div>

    {/* Parity checklist */}
    <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 14 }}>Jamstva dosljednosti</div>
    <BBCard>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14 }}>
        {CP_PARITY.map((p, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <BBIcon name="check_circle" size={20} fill={1} style={{ color: 'var(--bb-success)', flexShrink: 0 }} />
            <span className="bb-body" style={{ color: 'var(--bb-text-secondary)', fontSize: 14 }}>{p.t}</span>
          </div>
        ))}
      </div>
    </BBCard>
  </div>
);

Object.assign(window, { CPBoard });
