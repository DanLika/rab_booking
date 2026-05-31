/* eslint-disable */
// iCal · Sinkronizacija — Prompt 18.
// Empty state (BBEmptyState) + populated feed list + sync settings.

const ICAL_FEEDS = [
  {
    id: 'f1',
    name: 'Booking.com',
    logo: 'assets/booking.png',
    accent: '#003580',
    description: 'Vila Marina — Studio 4',
    url: 'https://ical.booking.com/v1/export?t=…2af9',
    direction: 'import',
    status: 'synced',
    lastSync: 'prije 2 min',
    nextSync: 'za 13 min',
    importedThisMonth: 14,
  },
  {
    id: 'f2',
    name: 'Airbnb',
    logo: 'assets/airbnb.png',
    accent: '#FF5A5F',
    description: 'Vila Marina — Premium suite',
    url: 'https://airbnb.com/calendar/ical/74521.ics',
    direction: 'import',
    status: 'error',
    lastSync: 'prije 1d',
    errorMessage: 'Feed je vraćao 503 — ponovo pokušavamo svakih 5 min.',
    importedThisMonth: 8,
  },
  {
    id: 'f3',
    name: 'Vlastiti iCal feed',
    logo: 'assets/other-sync.png',
    accent: '#6B4CE6',
    description: 'Stan Lavanda — Apartman A',
    url: 'https://moj-pms.hr/feed/lavanda-a.ics',
    direction: 'export',
    status: 'pending',
    lastSync: 'nikad',
    importedThisMonth: 0,
  },
];

const ICAL_BENEFITS = [
  { icon: 'sync', title: 'Automatska sinkronizacija', body: 'Rezervacije se uvoze svakih 15 minuta — bez čekanja.' },
  { icon: 'event_busy', title: 'Bez dvostrukih rezervacija', body: 'Termini se odmah blokiraju na svim platformama.' },
  { icon: 'shield', title: 'Sigurno i privatno', body: 'Kriptirano, automatska sigurnosna kopija.' },
];

// ──────────────────────────────────────────────────────────────
// FeedCard
// ──────────────────────────────────────────────────────────────
const FeedCard = ({ feed, compact = false }) => {
  const statusMap = {
    synced: { badge: 'confirmed', label: 'Sinkronizirano' },
    error:  { badge: 'cancelled', label: 'Greška', destructive: true },
    pending:{ badge: 'pending', label: 'Čeka prvu sinkronizaciju' },
  };
  const s = statusMap[feed.status] || statusMap.synced;
  return (
    <BBCard padded={false} hoverable>
      {/* Top */}
      <div style={{
        padding: compact ? 16 : 20,
        display: 'flex', alignItems: 'flex-start', gap: 14,
        borderBottom: '1px solid var(--bb-border-subtle)',
      }}>
        <div style={{
          width: compact ? 44 : 52, height: compact ? 44 : 52, borderRadius: 14, flexShrink: 0,
          background: '#FFFFFF',
          border: '1px solid var(--bb-border-subtle)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          padding: 6,
          boxShadow: '0 1px 2px rgba(0,0,0,0.04)',
        }}>
          <img src={feed.logo} alt={feed.name} width={compact ? 28 : 34} height={compact ? 28 : 34} />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
            <h3 className={compact ? 'bb-label' : 'bb-h3'} style={{ margin: 0, color: 'var(--bb-text-primary)', fontWeight: 700 }}>{feed.name}</h3>
            <span style={{
              padding: '2px 7px', borderRadius: 4,
              fontSize: 9, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase',
              color: feed.direction === 'import' ? 'var(--bb-info)' : 'var(--bb-primary)',
              background: feed.direction === 'import' ? 'var(--bb-info-tint)' : 'var(--bb-primary-tint-bg)',
            }}>{feed.direction === 'import' ? 'Uvoz' : 'Izvoz'}</span>
          </div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>{feed.description}</div>
          <div className="bb-mono" style={{
            color: 'var(--bb-text-tertiary)', fontSize: 11, marginTop: 6,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{feed.url}</div>
        </div>
      </div>

      {/* Status row */}
      <div style={{
        padding: compact ? '12px 16px' : '14px 20px',
        display: 'flex', alignItems: 'center', gap: 10,
        background: feed.status === 'error' ? 'var(--bb-error-tint)' : 'var(--bb-surface-variant)',
      }}>
        <BBStatusBadge status={s.badge} label={s.label} size="sm" />
        <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', flex: 1 }}>
          {feed.status === 'error' ? feed.errorMessage : (
            <>posljednja sinkronizacija {feed.lastSync}{feed.nextSync ? ` · sljedeća ${feed.nextSync}` : ''}</>
          )}
        </span>
      </div>

      {/* Footer actions */}
      <div style={{
        padding: compact ? '10px 14px' : '12px 20px',
        display: 'flex', gap: 8, alignItems: 'center',
        borderTop: '1px solid var(--bb-border-subtle)',
      }}>
        <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
          <span className="bb-tnum">{feed.importedThisMonth}</span> rezervacija ovaj mjesec
        </span>
        <div style={{ flex: 1 }} />
        <BBButton variant="tertiary" size="sm" iconLeft="sync">Sinkroniziraj</BBButton>
        <BBButton variant="secondary" asIcon size="sm" iconLeft="edit" ariaLabel="Uredi feed" />
        <BBButton variant="secondary" asIcon size="sm" iconLeft="delete" ariaLabel="Obriši feed" />
      </div>
    </BBCard>
  );
};

// Add-feed card
const AddFeedCard = ({ compact = false }) => (
  <BBCard style={{
    border: '2px dashed var(--bb-border)',
    background: 'transparent',
    boxShadow: 'none',
    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
    gap: 8, padding: compact ? 24 : 24,
    minHeight: compact ? 200 : 150,
    cursor: 'pointer',
  }}>
    <div style={{
      width: 48, height: 48, borderRadius: 14,
      background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name="add_link" size={24} />
    </div>
    <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Dodaj novi feed</div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textAlign: 'center' }}>
      Booking.com, Airbnb ili vlastiti .ics URL
    </div>
  </BBCard>
);

// Sync settings card
const SyncSettingsCard = ({ compact = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? '14px 16px 10px' : '16px 20px 12px' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Postavke sinkronizacije</h3>
      <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>
        Primjenjuje se na sve aktivne feedove
      </p>
    </div>
    <SettingsToggleRow icon="schedule" label="Frekvencija provjere" value="Svakih 15 min" hasChevron />
    <SettingsToggleRow icon="event_busy" label="Auto-blokiranje pri sukobu" sub="Blokira datum na svim platformama" toggle on />
    <SettingsToggleRow icon="mail" label="Email obavijesti o greškama" sub="Šaljemo email ako 3 sinkronizacije zaredom padnu" toggle on />
    <SettingsToggleRow icon="summarize" label="Dnevni sažetak" sub="Statistika sinkronizacija svaki dan u 09:00" toggle off last />
  </BBCard>
);

const SettingsToggleRow = ({ icon, label, sub, value, hasChevron, toggle, on, last }) => (
  <div style={{
    padding: '12px 20px',
    display: 'flex', alignItems: 'center', gap: 14,
    borderTop: '1px solid var(--bb-border-subtle)',
  }}>
    <div style={{
      width: 36, height: 36, borderRadius: 10,
      background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name={icon} size={18} />
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{label}</div>
      {sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{sub}</div>}
    </div>
    {value && <span className="bb-label" style={{ color: 'var(--bb-text-secondary)', fontWeight: 500 }}>{value}</span>}
    {hasChevron && <BBIcon name="chevron_right" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />}
    {toggle && <ToggleSwitch on={on} />}
  </div>
);

const ToggleSwitch = ({ on }) => (
  <span style={{
    width: 40, height: 24, borderRadius: 999,
    background: on ? 'var(--bb-primary)' : 'var(--bb-border)',
    position: 'relative', display: 'inline-block',
    transition: 'background 160ms ease-out',
  }}>
    <span style={{
      position: 'absolute', top: 3, left: on ? 19 : 3,
      width: 18, height: 18, borderRadius: '50%',
      background: '#FFFFFF',
      boxShadow: '0 1px 3px rgba(0,0,0,0.16)',
      transition: 'left 160ms ease-out',
    }} />
  </span>
);

// ──────────────────────────────────────────────────────────────
// Why-iCal benefits panel (light, sidebar on desktop)
// ──────────────────────────────────────────────────────────────
const WhyiCalPanel = () => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: 'var(--bb-tertiary-tint)', color: 'var(--bb-tertiary-dark)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name="lightbulb" size={20} />
      </div>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Zašto iCal?</h3>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      {ICAL_BENEFITS.map((b, i) => (
        <div key={i} style={{ display: 'flex', gap: 12 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 10, flexShrink: 0,
            background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <BBIcon name={b.icon} size={16} />
          </div>
          <div>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{b.title}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>{b.body}</div>
          </div>
        </div>
      ))}
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const ICalDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 1440, height: 1100, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebar user={SAMPLE_USER} active="ical" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Integracije', 'iCal']} notifCount={3} actions={[
        { icon: 'history', label: 'Povijest sinkronizacija' },
      ]} />
      <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
          <div>
            <h2 className="bb-h1" style={{ margin: 0 }}>iCal feedovi</h2>
            <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>
              <span className="bb-tnum">3</span> aktivna feeda · <span className="bb-tnum">22</span> rezervacije uvezene ovaj mjesec
            </p>
          </div>
          <BBButton variant="primary" iconLeft="add_link">Dodaj novi feed</BBButton>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: 24, alignItems: 'start' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {ICAL_FEEDS.map(f => <FeedCard key={f.id} feed={f} />)}
            <AddFeedCard />
          </div>
          <aside style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <WhyiCalPanel />
            <SyncSettingsCard />
          </aside>
        </div>
      </main>
    </div>
  </div>
);

const ICalTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 768, height: 1024, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebarRail active="ical" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Integracije', 'iCal']} notifCount={3} actions={[
        { icon: 'add_link', label: 'Dodaj feed' },
      ]} />
      <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {ICAL_FEEDS.slice(0, 2).map(f => <FeedCard key={f.id} feed={f} compact />)}
          <AddFeedCard compact />
        </div>
      </main>
    </div>
  </div>
);

const ICalMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 390, height: 880,
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    display: 'flex', flexDirection: 'column', position: 'relative',
  }}>
    <BBAppBar title="iCal sinkronizacija" showHamburger notifCount={3} actions={[
      { icon: 'add_link', label: 'Dodaj feed' },
    ]} />
    <main style={{ flex: 1, padding: '12px 16px 0', overflow: 'hidden' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {ICAL_FEEDS.slice(0, 2).map(f => <FeedCard key={f.id} feed={f} compact />)}
      </div>
    </main>
    <button type="button" aria-label="Dodaj feed" style={{
      position: 'absolute', bottom: 24, right: 24,
      width: 52, height: 52, borderRadius: '50%',
      background: 'var(--bb-primary)', color: '#FFFFFF',
      border: 'none', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: 'var(--bb-shadow-purple)',
    }}>
      <BBIcon name="add_link" size={22} />
    </button>
  </div>
);

Object.assign(window, {
  ICalDesktop,
  ICalTablet,
  ICalMobile,
});
