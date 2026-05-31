/* eslint-disable */
// Embed guide — Prompt 20. Integracije → Widget. Developer-facing install screen.
// Copyable embed snippet (centerpiece) + live mint-widget preview + customization + per-platform steps.
// Owner purple chrome (active=widget). Reuses ToggleSwitch from ical.jsx (global). Mint preview matches the widget.

const EMB_INK = '#1B2330';
const EMB_MUTED = '#7C8593';

const EMB_ACCENTS = [
  { id: 'mint', hex: '#3DD9B0' },
  { id: 'purple', hex: '#6B4CE6' },
  { id: 'blue', hex: '#4A90D9' },
  { id: 'coral', hex: '#FF6B6B' },
  { id: 'ink', hex: '#1B2330' },
];

const EMB_PLATFORMS = [
  { id: 'html', label: 'HTML', icon: 'code', steps: [
    'Kopirajte isječak koda iznad.',
    'Zalijepite ga u <body> stranice, ondje gdje želite widget.',
    'Spremite i objavite — widget se učitava automatski.',
  ] },
  { id: 'wordpress', label: 'WordPress', icon: 'web', steps: [
    'U uređivaču dodajte blok „Prilagođeni HTML”.',
    'Zalijepite isječak koda u blok.',
    'Ažurirajte stranicu (izbjegavajte „Vizualni” način).',
  ] },
  { id: 'wix', label: 'Wix', icon: 'widgets', steps: [
    'Dodajte element Embed → „Ugradi kôd”.',
    'Zalijepite isječak i postavite veličinu okvira.',
    'Objavite stranicu.',
  ] },
];

const EMB_MODES = [
  { id: 'inline', label: 'Ugrađeno' },
  { id: 'popup', label: 'Skočni gumb' },
  { id: 'link', label: 'Poveznica' },
];

function embSnippet(mode, accent) {
  if (mode === 'link') {
    return `https://book.bookbed.io/vm-studio-more?lang=hr`;
  }
  if (mode === 'popup') {
    return `<!-- BookBed widget · skočni gumb -->
<script src="https://widget.bookbed.io/v1/embed.js"
        data-unit="vm-studio-more"
        data-mode="popup"
        data-accent="${accent}"></script>
<button data-bookbed-open>Rezerviraj</button>`;
  }
  return `<!-- BookBed widget -->
<script src="https://widget.bookbed.io/v1/embed.js"
        data-unit="vm-studio-more"
        data-lang="hr"
        data-accent="${accent}"></script>
<div id="bookbed-widget"></div>`;
}

// ──────────────────────────────────────────────────────────────
// Code block
// ──────────────────────────────────────────────────────────────
const EmbCodeCard = ({ mode, setMode, accent, compact = false, mobile = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? '14px 16px 0' : '16px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
      <div>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Kôd za ugradnju</h3>
        <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>Zalijepite na svoju web stranicu</p>
      </div>
      <div style={{ display: 'flex', gap: 6 }}>
        {EMB_MODES.map(m => (
          <BBChip key={m.id} selected={mode === m.id} size="sm" onClick={() => setMode(m.id)}>{m.label}</BBChip>
        ))}
      </div>
    </div>
    <div style={{ padding: compact ? '12px 16px 16px' : '14px 20px 20px' }}>
      <div style={{ position: 'relative', borderRadius: 'var(--bb-radius-sm)', overflow: 'hidden', border: '1px solid var(--bb-border)' }}>
        <pre style={{
          margin: 0, padding: mobile ? '12px 12px' : (compact ? '14px 14px' : '16px 18px'),
          background: '#1B2330', color: '#E6EAF2',
          fontFamily: 'var(--bb-font-mono)', fontSize: mobile ? 10.5 : (compact ? 11 : 12.5), lineHeight: mobile ? 1.5 : 1.65,
          overflowX: 'auto', whiteSpace: 'pre',
        }}>{embSnippet(mode, accent)}</pre>
        <button type="button" style={{
          position: 'absolute', top: 10, right: 10,
          display: 'inline-flex', alignItems: 'center', gap: 6,
          height: 32, padding: '0 12px', borderRadius: 8, cursor: 'pointer',
          background: 'rgba(255,255,255,0.12)', color: '#FFFFFF', border: '1px solid rgba(255,255,255,0.2)',
          fontFamily: 'var(--bb-font-sans)', fontSize: 12, fontWeight: 600,
        }}>
          <BBIcon name="content_copy" size={15} fill={0} /> Kopiraj
        </button>
      </div>
      {!mobile && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12 }}>
          <BBIcon name="lock" size={14} style={{ color: 'var(--bb-success)' }} />
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Učitava se preko HTTPS-a · ne usporava vašu stranicu (async).</span>
        </div>
      )}
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Platform instructions (tabbed)
// ──────────────────────────────────────────────────────────────
const EmbPlatformCard = ({ tab, setTab, compact = false }) => {
  const p = EMB_PLATFORMS.find(x => x.id === tab) || EMB_PLATFORMS[0];
  return (
    <BBCard padded={false}>
      <div style={{ padding: compact ? '14px 16px 0' : '16px 20px 0' }}>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Upute za postavljanje</h3>
      </div>
      <div style={{ display: 'flex', gap: 4, padding: compact ? '12px 16px 0' : '14px 20px 0', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        {EMB_PLATFORMS.map(pl => {
          const on = pl.id === tab;
          return (
            <button key={pl.id} type="button" onClick={() => setTab(pl.id)} style={{
              display: 'inline-flex', alignItems: 'center', gap: 6, padding: '10px 14px',
              border: 'none', background: 'transparent', cursor: 'pointer',
              color: on ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
              fontFamily: 'var(--bb-font-sans)', fontSize: 13, fontWeight: on ? 600 : 500,
              borderBottom: `2px solid ${on ? 'var(--bb-primary)' : 'transparent'}`, marginBottom: -1,
            }}>
              <BBIcon name={pl.icon} size={16} fill={on ? 1 : 0} />{pl.label}
            </button>
          );
        })}
      </div>
      <div style={{ padding: compact ? 16 : 20, display: 'flex', flexDirection: 'column', gap: 14 }}>
        {p.steps.map((s, i) => (
          <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <div style={{ width: 26, height: 26, borderRadius: '50%', flexShrink: 0, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{i + 1}</div>
            <span className="bb-body" style={{ color: 'var(--bb-text-secondary)', fontSize: 14, paddingTop: 3 }}>{s}</span>
          </div>
        ))}
      </div>
    </BBCard>
  );
};

// ──────────────────────────────────────────────────────────────
// Live preview (mint widget mini)
// ──────────────────────────────────────────────────────────────
const EmbPreview = ({ accent, compact = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? '12px 16px' : '14px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Pregled uživo</h3>
      <BBButton variant="tertiary" size="sm" iconRight="open_in_new">Otvori</BBButton>
    </div>
    <div style={{ padding: 16, background: 'var(--bb-surface-variant)' }}>
      {/* the embedded mint widget mock */}
      <div style={{ background: '#FFFFFF', borderRadius: 16, border: '1px solid #ECEEF1', boxShadow: '0 8px 24px rgba(20,30,50,0.10)', padding: 16, fontFamily: 'var(--bb-font-sans)', color: EMB_INK }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase', color: EMB_MUTED }}>Vila Marina</div>
            <div style={{ fontSize: 14, fontWeight: 700, color: EMB_INK }}>Studio s pogledom</div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 16, fontWeight: 800, color: EMB_INK, fontVariantNumeric: 'tabular-nums' }}>€120</div>
            <div style={{ fontSize: 10, color: EMB_MUTED }}>po noći</div>
          </div>
        </div>
        {/* mini week */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4, marginBottom: 12 }}>
          {['P','U','S','Č','P','S','N'].map((d, i) => (
            <div key={i} style={{ textAlign: 'center', fontSize: 9, fontWeight: 700, color: EMB_MUTED }}>{d}</div>
          ))}
          {Array.from({ length: 7 }).map((_, i) => {
            const sel = i === 3 || i === 4;
            return (
              <div key={i} style={{
                height: 26, borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, fontWeight: 600, fontVariantNumeric: 'tabular-nums',
                background: sel ? accent : '#F4F5F7',
                color: sel ? '#FFFFFF' : EMB_INK,
              }}>{12 + i}</div>
            );
          })}
        </div>
        <button style={{ width: '100%', height: 40, border: 'none', borderRadius: 12, cursor: 'pointer', background: EMB_INK, color: '#FFFFFF', fontFamily: 'var(--bb-font-sans)', fontSize: 13, fontWeight: 700, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
          Rezerviraj
        </button>
        <div style={{ textAlign: 'center', marginTop: 10, fontSize: 10, color: '#9AA0AC' }}>
          Powered by <span style={{ fontWeight: 700, color: '#6B4CE6' }}>BookBed</span>
        </div>
      </div>
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Customization
// ──────────────────────────────────────────────────────────────
const EmbCustomize = ({ accent, setAccent, compact = false, mobile = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? '14px 16px 10px' : '16px 20px 12px' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Izgled</h3>
    </div>
    {/* Accent */}
    <div style={{ padding: compact ? '0 16px 14px' : '0 20px 16px', borderBottom: mobile ? 'none' : '1px solid var(--bb-border-subtle)' }}>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700, marginBottom: 10 }}>Naglašna boja</div>
      <div style={{ display: 'flex', gap: 10 }}>
        {EMB_ACCENTS.map(a => (
          <button key={a.id} type="button" onClick={() => setAccent(a.hex)} aria-label={a.id} style={{
            width: 32, height: 32, borderRadius: '50%', cursor: 'pointer', background: a.hex,
            border: accent === a.hex ? '2px solid var(--bb-text-primary)' : '2px solid transparent',
            boxShadow: accent === a.hex ? '0 0 0 2px var(--bb-surface), 0 0 0 4px ' + a.hex : 'none',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {accent === a.hex && <BBIcon name="check" size={16} style={{ color: '#FFFFFF' }} />}
          </button>
        ))}
      </div>
    </div>
    {/* Selects as rows */}
    {!mobile && <EmbRow label="Jezik" value="Hrvatski" />}
    {!mobile && <EmbRow label="Tema" value="Svijetla" />}
    {!mobile && <EmbRow label="Zaobljenost rubova" value="Zaobljeno" last={compact} />}
    {!compact && (
      <>
        <EmbToggleRow label="Prikaži cijene u kalendaru" on />
        <EmbToggleRow label="Oznaka „Powered by BookBed”" sub="Uklonite uz Pro" on locked last />
      </>
    )}
  </BBCard>
);

const EmbRow = ({ label, value, last }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 20px', borderBottom: last ? 'none' : '1px solid var(--bb-border-subtle)', cursor: 'pointer' }}>
    <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{label}</span>
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <span className="bb-label" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>{value}</span>
      <BBIcon name="expand_more" size={18} style={{ color: 'var(--bb-text-tertiary)' }} />
    </span>
  </div>
);

const EmbToggleRow = ({ label, sub, on, locked, last }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 20px', borderBottom: last ? 'none' : '1px solid var(--bb-border-subtle)' }}>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 8 }}>
        {label}
        {locked && <span style={{ fontSize: 9, fontWeight: 700, color: 'var(--bb-primary)', background: 'var(--bb-primary-tint-bg)', padding: '2px 6px', borderRadius: 4 }}>PRO</span>}
      </div>
      {sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{sub}</div>}
    </div>
    <ToggleSwitch on={on} />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────
const EmbHeader = ({ compact = false }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: compact ? 14 : 20, gap: 12 }}>
    <div>
      <h2 className={compact ? 'bb-h1' : 'bb-h1'} style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Widget za rezervacije</h2>
      {!compact && <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>Ugradite kalendar rezervacija na svoju web stranicu</p>}
    </div>
    <BBStatusBadge status="confirmed" label="Aktivan" size="md" />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Body + pages
// ──────────────────────────────────────────────────────────────
const EmbedBody = ({ breakpoint }) => {
  const compact = breakpoint !== 'desktop';
  const mobile = breakpoint === 'mobile';
  const [mode, setMode] = React.useState('inline');
  const [tab, setTab] = React.useState('html');
  const [accent, setAccent] = React.useState('#3DD9B0');

  if (breakpoint === 'desktop') {
    return (
      <div>
        <EmbHeader />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: 24, alignItems: 'start' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <EmbCodeCard mode={mode} setMode={setMode} accent={accent} />
            <EmbPlatformCard tab={tab} setTab={setTab} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <EmbPreview accent={accent} />
            <EmbCustomize accent={accent} setAccent={setAccent} />
          </div>
        </div>
      </div>
    );
  }
  if (breakpoint === 'tablet') {
    return (
      <div>
        <EmbHeader compact />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <EmbCodeCard mode={mode} setMode={setMode} accent={accent} compact />
          <EmbCustomize accent={accent} setAccent={setAccent} compact />
          <EmbPlatformCard tab={tab} setTab={setTab} compact />
        </div>
      </div>
    );
  }
  // mobile
  return (
    <div>
      <EmbHeader compact />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <EmbCodeCard mode={mode} setMode={setMode} accent={accent} compact mobile />
        <EmbCustomize accent={accent} setAccent={setAccent} compact mobile />
        <EmbPlatformCard tab={tab} setTab={setTab} compact />
      </div>
    </div>
  );
};

const EmbedDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="widget" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Integracije', 'Widget']} notifCount={6} actions={[{ icon: 'open_in_new', label: 'Otvori widget' }, { icon: 'light_mode', label: 'Tema' }]} />
      <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden' }}>
        <EmbedBody breakpoint="desktop" />
      </main>
    </div>
  </div>
);

const EmbedTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 768, height: 1024, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebarRail active="widget" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Integracije', 'Widget']} notifCount={6} actions={[{ icon: 'open_in_new', label: 'Otvori widget' }]} />
      <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
        <div style={{ maxWidth: 620, margin: '0 auto' }}>
          <EmbedBody breakpoint="tablet" />
        </div>
      </main>
    </div>
  </div>
);

const EmbedMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <BBAppBar title="Widget" showHamburger notifCount={6} actions={[{ icon: 'open_in_new', label: 'Otvori' }]} />
    <main style={{ flex: 1, padding: '14px 16px 0', overflow: 'hidden' }}>
      <EmbedBody breakpoint="mobile" />
    </main>
  </div>
);

Object.assign(window, { EmbedDesktop, EmbedTablet, EmbedMobile });
