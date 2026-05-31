/* eslint-disable */
// States QA sweep — Prompt 37. Canonical loading / empty / error / inline state patterns.
// Reuses BBEmptyState, BBSkeleton, BBButton(loading), BBInput(error), BBStatusBadge + MDToast (dialogs-misc, global).

const StPanel = ({ label, children, span = 1 }) => (
  <div style={{ gridColumn: `span ${span}`, display: 'flex', flexDirection: 'column' }}>
    <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 10 }}>{label}</div>
    {children}
  </div>
);

// Skeleton compositions
const SkeletonList = () => (
  <BBCard padded={false}>
    {[0, 1, 2].map(i => (
      <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 18px', borderBottom: i < 2 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
        <BBSkeleton w={40} h={40} radius={12} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <BBSkeleton w="55%" h={12} />
          <BBSkeleton w="80%" h={10} />
        </div>
        <BBSkeleton w={64} h={26} radius={999} />
      </div>
    ))}
  </BBCard>
);

const SkeletonHero = () => (
  <BBCard>
    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
      <BBSkeleton w={120} h={12} />
      <BBSkeleton w={44} h={20} radius={6} />
    </div>
    <BBSkeleton w="60%" h={32} radius={10} />
    <div style={{ height: 12 }} />
    <BBSkeleton w="100%" h={56} radius={12} />
    <div style={{ height: 12 }} />
    <div style={{ display: 'flex', gap: 10 }}>
      <BBSkeleton w="100%" h={40} radius={10} />
      <BBSkeleton w="100%" h={40} radius={10} />
    </div>
  </BBCard>
);

// Error / status blocks
const ErrorBlock = ({ icon, title, body, action }) => (
  <BBCard>
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: 16, gap: 8 }}>
      <div style={{ width: 56, height: 56, borderRadius: 16, background: 'var(--bb-error-tint)', color: 'var(--bb-error)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={icon} size={28} />
      </div>
      <div className="bb-h3" style={{ color: 'var(--bb-text-primary)', margin: 0 }}>{title}</div>
      <p className="bb-caption" style={{ color: 'var(--bb-text-secondary)', margin: 0, maxWidth: 280 }}>{body}</p>
      {action && <div style={{ marginTop: 8 }}><BBButton variant="secondary" iconLeft={action.icon} size="sm">{action.label}</BBButton></div>}
    </div>
  </BBCard>
);

const OfflineBanner = () => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px', background: 'var(--bb-tertiary-tint)', borderRadius: 'var(--bb-radius-md)', border: '1px solid rgba(255,184,77,0.32)' }}>
    <BBIcon name="wifi_off" size={22} style={{ color: 'var(--bb-tertiary-dark)', flexShrink: 0 }} />
    <div style={{ flex: 1 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Niste povezani</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>Prikazujemo zadnje učitane podatke. Sinkronizacija se nastavlja automatski.</div>
    </div>
  </div>
);

// Inline states
const InlineStates = () => (
  <BBCard>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 8, fontWeight: 600 }}>Button — loading</div>
        <div style={{ display: 'flex', gap: 10 }}>
          <BBButton variant="primary" loading>Spremanje…</BBButton>
          <BBButton variant="secondary" disabled>Onemogućeno</BBButton>
        </div>
      </div>
      <div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 8, fontWeight: 600 }}>Input — error</div>
        <BBInput label="Email" value="marko@" iconLeft="mail" error="Neispravna e-adresa" />
      </div>
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Board
// ──────────────────────────────────────────────────────────────
const StatesBoard = () => (
  <div className="theme-light" style={{ width: 1280, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', padding: 40 }}>
    <div style={{ marginBottom: 28 }}>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)' }}>Prompt 37 · QA sweep</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0', color: 'var(--bb-text-primary)' }}>States — loading · empty · error</h2>
      <p className="bb-body" style={{ margin: '6px 0 0', color: 'var(--bb-text-tertiary)' }}>Canonical state patterns reused across owner, admin & widget surfaces.</p>
    </div>

    {/* Loading */}
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, marginBottom: 32 }}>
      <StPanel label="Loading · list (skeleton)"><SkeletonList /></StPanel>
      <StPanel label="Loading · hero (skeleton)"><SkeletonHero /></StPanel>
      <StPanel label="Inline · button + input"><InlineStates /></StPanel>
    </div>

    {/* Empty */}
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, marginBottom: 32 }}>
      <StPanel label="Empty · bookings">
        <BBCard><BBEmptyState compact icon="receipt_long" title="Još nema rezervacija" body="Nove rezervacije pojavit će se ovdje čim ih primite." primary={{ label: 'Nova rezervacija', iconLeft: 'add' }} /></BBCard>
      </StPanel>
      <StPanel label="Empty · notifications">
        <BBCard><BBEmptyState compact icon="notifications_off" title="Sve pročitano" body="Nemate novih obavijesti. Uživajte u miru." /></BBCard>
      </StPanel>
      <StPanel label="Empty · search">
        <BBCard><BBEmptyState compact icon="search_off" title="Nema rezultata" body="Pokušajte s drugim pojmom ili uklonite filtere." secondary={{ label: 'Očisti filtere' }} /></BBCard>
      </StPanel>
    </div>

    {/* Error */}
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, alignItems: 'start' }}>
      <StPanel label="Error · load failed">
        <ErrorBlock icon="cloud_off" title="Učitavanje nije uspjelo" body="Provjerite vezu i pokušajte ponovno." action={{ label: 'Pokušaj ponovno', icon: 'refresh' }} />
      </StPanel>
      <StPanel label="Error · 404 (owner)">
        <ErrorBlock icon="explore_off" title="Stranica nije pronađena" body="Poveznica ne postoji ili je premještena." action={{ label: 'Natrag na Pregled', icon: 'home' }} />
      </StPanel>
      <StPanel label="Banner · offline + toasts">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <OfflineBanner />
          <MDToast tone="error" title="Akcija nije uspjela" msg="Pokušajte ponovno." action="Pokušaj" width="100%" />
        </div>
      </StPanel>
    </div>
  </div>
);

// Mobile — empty + skeleton in a phone frame
const StatesMobile = () => (
  <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <BBAppBar title="Rezervacije" showHamburger notifCount={0} />
    <main style={{ flex: 1, padding: '16px', overflow: 'hidden' }}>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 10 }}>Loading</div>
      <div style={{ marginBottom: 20 }}><SkeletonList /></div>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 10 }}>Empty</div>
      <BBCard><BBEmptyState compact icon="receipt_long" title="Još nema rezervacija" body="Nove rezervacije pojavit će se ovdje." primary={{ label: 'Nova', iconLeft: 'add' }} /></BBCard>
    </main>
  </div>
);

Object.assign(window, { StatesBoard, StatesMobile });
