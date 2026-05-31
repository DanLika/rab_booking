/* eslint-disable */
// Notifications — Prompt 15.
// Typed categories · inline actions for actionable items · mark-all-read · empty/loading states.

const NOTIFICATIONS = [
  {
    id: 'n1', group: 'Danas', type: 'new-booking',
    icon: 'event_available', tone: 'tertiary',
    title: 'Nova rezervacija čeka odobrenje',
    body: 'Marko Horvat · Vila Marina – Studio 4 · 08.07. – 11.07. (3 noći)',
    time: 'prije 22min',
    fullTime: 'Danas u 09:14',
    unread: true,
    action: { label: 'Odobri', tone: 'primary' },
  },
  {
    id: 'n2', group: 'Danas', type: 'new-booking',
    icon: 'event_available', tone: 'tertiary',
    title: 'Nova rezervacija čeka odobrenje',
    body: 'Ana Pavlović · Vila Marina – Studio 4 · 22.07. – 25.07. (3 noći)',
    time: 'prije 3h',
    fullTime: 'Danas u 06:42',
    unread: true,
    action: { label: 'Odobri', tone: 'primary' },
  },
  {
    id: 'n3', group: 'Danas', type: 'payment',
    icon: 'payments', tone: 'success',
    title: 'Plaćanje zaprimljeno',
    body: 'Sandra Kovač · Stan Lavanda – Apartman A · €420,00 putem Stripe-a',
    time: 'prije 5h',
    fullTime: 'Danas u 04:31',
    unread: true,
  },
  {
    id: 'n4', group: 'Jučer', type: 'completed',
    icon: 'check_circle', tone: 'primary',
    title: 'Rezervacija završena',
    body: 'Vila Marina – Premium suite · BB-2391 · ostavite ocjenu gostu',
    time: 'jučer',
    fullTime: 'Jučer u 11:00',
    unread: false,
    action: { label: 'Ocijeni', tone: 'tertiary' },
  },
  {
    id: 'n5', group: 'Jučer', type: 'sync',
    icon: 'sync', tone: 'info',
    title: 'Booking.com sinkronizacija',
    body: '4 nove rezervacije uvezene · 2 ažurirana statusa · 0 grešaka',
    time: 'jučer',
    fullTime: 'Jučer u 09:00',
    unread: false,
  },
  {
    id: 'n6', group: 'Ovaj tjedan', type: 'cancellation',
    icon: 'event_busy', tone: 'error',
    title: 'Gost otkazao rezervaciju',
    body: 'Petra Marić · Stan Lavanda – Apartman A · povrat €280,00 pokrenut',
    time: 'prije 2d',
    fullTime: 'Pon, 25.05.2026 u 14:22',
    unread: false,
  },
  {
    id: 'n7', group: 'Ovaj tjedan', type: 'review',
    icon: 'star', tone: 'tertiary',
    title: 'Nova ocjena · 5,0 ★',
    body: '"Sve je bilo savršeno, preporučujem!" — Luka Babić · Stan Lavanda',
    time: 'prije 3d',
    fullTime: 'Ned, 24.05.2026 u 19:48',
    unread: false,
  },
  {
    id: 'n8', group: 'Ovaj tjedan', type: 'system',
    icon: 'shield', tone: 'info',
    title: 'Sigurnosno ažuriranje',
    body: 'BookBed v3.4.1 dostupan · sigurnosne zakrpe za widget i Stripe integraciju',
    time: 'prije 5d',
    fullTime: 'Pet, 22.05.2026 u 08:00',
    unread: false,
  },
];

// Tone resolvers
const TONE_BG = {
  primary: 'var(--bb-primary-tint-bg)',
  success: 'var(--bb-success-tint)',
  tertiary: 'var(--bb-tertiary-tint)',
  info: 'var(--bb-info-tint)',
  error: 'var(--bb-error-tint)',
};
const TONE_FG = {
  primary: 'var(--bb-primary)',
  success: 'var(--bb-success)',
  tertiary: 'var(--bb-tertiary-dark)',
  info: 'var(--bb-info)',
  error: 'var(--bb-error)',
};

// Group notifications by their .group field, preserving order
function groupNotifications(items) {
  const groups = [];
  let current = null;
  items.forEach(n => {
    if (!current || current.label !== n.group) {
      current = { label: n.group, items: [] };
      groups.push(current);
    }
    current.items.push(n);
  });
  return groups;
}

// ──────────────────────────────────────────────────────────────
// Notification row
// ──────────────────────────────────────────────────────────────
const NotifRow = ({ n, divider, compact = false, showAction = true }) => {
  const padX = compact ? 14 : 18;
  const padY = compact ? 14 : 16;
  return (
    <div style={{
      position: 'relative',
      display: 'flex', alignItems: 'flex-start', gap: 14,
      padding: `${padY}px ${padX}px`,
      borderBottom: divider ? '1px solid var(--bb-border-subtle)' : 'none',
      background: n.unread ? 'var(--bb-primary-tint-bg)' : 'transparent',
      cursor: 'pointer',
      transition: 'background 120ms ease-out',
    }}>
      {/* Unread bar */}
      {n.unread && (
        <span style={{
          position: 'absolute', left: 0, top: 8, bottom: 8, width: 3,
          background: 'var(--bb-primary)', borderRadius: '0 3px 3px 0',
        }} />
      )}
      <div style={{
        width: compact ? 36 : 40, height: compact ? 36 : 40, borderRadius: 12, flexShrink: 0,
        background: TONE_BG[n.tone], color: TONE_FG[n.tone],
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name={n.icon} size={compact ? 18 : 20} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
          <span className="bb-label" style={{
            color: 'var(--bb-text-primary)',
            fontWeight: n.unread ? 700 : 600,
            fontSize: compact ? 13 : 14,
          }}>{n.title}</span>
          <span className="bb-caption bb-tnum" title={n.fullTime} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }}>
            {n.time}
          </span>
        </div>
        <p style={{
          margin: '2px 0 0', color: 'var(--bb-text-secondary)',
          fontSize: compact ? 12 : 13, lineHeight: 1.5,
        }}>{n.body}</p>
        {showAction && n.action && (
          <div style={{ marginTop: 10 }}>
            <BBButton variant={n.action.tone === 'primary' ? 'primary' : 'secondary'} size="sm" iconRight="arrow_forward">
              {n.action.label}
            </BBButton>
          </div>
        )}
      </div>
      {!n.action && !compact && (
        <BBIcon name="chevron_right" size={18} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0, marginTop: 10 }} />
      )}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Group label
// ──────────────────────────────────────────────────────────────
const NotifGroupLabel = ({ label, style = {} }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 10,
    margin: '20px 0 8px', ...style,
  }}>
    <span style={{
      display: 'inline-block',
      padding: '4px 10px', borderRadius: 999,
      background: 'var(--bb-primary-tint-bg)',
      color: 'var(--bb-primary)',
      fontSize: 11, fontWeight: 700, letterSpacing: '0.04em', textTransform: 'uppercase',
    }}>{label}</span>
    <div style={{ flex: 1, height: 1, background: 'var(--bb-border-subtle)' }} />
  </div>
);

// ──────────────────────────────────────────────────────────────
// Filter chip row
// ──────────────────────────────────────────────────────────────
const NotifFilters = ({ active = 'sve', size = 'md' }) => (
  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
    <BBChip selected={active === 'sve'} size={size} count={8}>Sve</BBChip>
    <BBChip selected={active === 'nepročitano'} size={size} dotColor="#6B4CE6" count={3} countColor={active === 'nepročitano' ? null : '#6B4CE6'}>Nepročitano</BBChip>
    <BBChip selected={active === 'rezervacije'} size={size} iconLeft="event_available">Rezervacije</BBChip>
    <BBChip selected={active === 'plaćanja'} size={size} iconLeft="payments">Plaćanja</BBChip>
    <BBChip selected={active === 'sustav'} size={size} iconLeft="settings">Sustav</BBChip>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Empty + Loading states (shown as side panels on desktop artboard)
// ──────────────────────────────────────────────────────────────
const NotifEmptyState = () => (
  <BBCard padded={false} style={{ background: 'var(--bb-surface)' }}>
    <BBEmptyState
      compact
      icon="notifications_off"
      title="Sve čisto, nema obavijesti"
      body="Kad stignu nove rezervacije, plaćanja ili recenzije, ovdje ćete ih prvi vidjeti."
      primary={{ label: 'Postavke obavijesti', iconLeft: 'tune' }}
    />
  </BBCard>
);

const NotifLoadingState = () => (
  <BBCard padded={false} style={{ background: 'var(--bb-surface)' }}>
    {[0, 1, 2].map(i => (
      <div key={i} style={{
        display: 'flex', alignItems: 'flex-start', gap: 14,
        padding: '16px 18px',
        borderBottom: i < 2 ? '1px solid var(--bb-border-subtle)' : 'none',
      }}>
        <BBSkeleton w={40} h={40} radius={12} />
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
            <BBSkeleton w="55%" h={12} />
            <BBSkeleton w={50} h={10} />
          </div>
          <div style={{ height: 8 }} />
          <BBSkeleton w="85%" h={10} />
          <div style={{ height: 4 }} />
          <BBSkeleton w="40%" h={10} />
        </div>
      </div>
    ))}
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Main list (shared across breakpoints)
// ──────────────────────────────────────────────────────────────
const NotifList = ({ items, compact = false, showAction = true }) => {
  const groups = groupNotifications(items);
  return (
    <div>
      {groups.map(g => (
        <div key={g.label}>
          <NotifGroupLabel label={g.label} />
          <BBCard padded={false}>
            {g.items.map((n, i) => (
              <NotifRow
                key={n.id}
                n={n}
                divider={i < g.items.length - 1}
                compact={compact}
                showAction={showAction}
              />
            ))}
          </BBCard>
        </div>
      ))}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// NotificationsDesktop (1440 × 1100) — list + empty/loading sidebar
// ──────────────────────────────────────────────────────────────
const NotificationsDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 1440, height: 1100, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebar user={SAMPLE_USER} active="obavjestenja" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Pomoć', 'Obavještenja']} notifCount={3} actions={[
        { icon: 'tune', label: 'Postavke' },
      ]} />
      <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden', display: 'grid', gridTemplateColumns: '1fr 320px', gap: 24 }}>
        <div>
          {/* Header row */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <div>
              <h2 className="bb-h1" style={{ margin: 0 }}>Obavještenja</h2>
              <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>
                <span className="bb-tnum">3</span> nepročitano · ukupno <span className="bb-tnum">8</span>
              </p>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <BBButton variant="tertiary" iconLeft="done_all">Označi sve kao pročitano</BBButton>
              <BBButton variant="secondary" iconLeft="checklist">Odaberi</BBButton>
            </div>
          </div>

          <NotifFilters active="sve" />
          <NotifList items={NOTIFICATIONS} />
        </div>

        {/* Right sidebar: states preview */}
        <aside style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div>
            <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 8 }}>STANJA · LOADING</div>
            <NotifLoadingState />
          </div>
          <div>
            <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 8 }}>STANJA · EMPTY</div>
            <NotifEmptyState />
          </div>
        </aside>
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// NotificationsTablet (768 × 1024)
// ──────────────────────────────────────────────────────────────
const NotificationsTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 768, height: 1024, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebarRail active="obavjestenja" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Pomoć', 'Obavještenja']} notifCount={3} actions={[
        { icon: 'done_all', label: 'Označi sve pročitano' },
        { icon: 'tune', label: 'Postavke' },
      ]} />
      <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
        <NotifFilters active="sve" size="sm" />
        <NotifList items={NOTIFICATIONS.slice(0, 5)} compact />
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// NotificationsMobile (390 × 880)
// ──────────────────────────────────────────────────────────────
const NotificationsMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 390, height: 880,
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    display: 'flex', flexDirection: 'column', position: 'relative',
  }}>
    <BBAppBar title="Obavještenja" showHamburger notifCount={3} actions={[
      { icon: 'done_all', label: 'Označi sve' },
    ]} />
    <main style={{ flex: 1, padding: '12px 16px 0', overflow: 'hidden' }}>
      <NotifFilters active="sve" size="sm" />
      <NotifList items={NOTIFICATIONS.slice(0, 4)} compact />
    </main>
    {/* Bulk-select FAB */}
    <button type="button" aria-label="Bulk odabir" style={{
      position: 'absolute', bottom: 24, right: 24,
      width: 52, height: 52, borderRadius: '50%',
      background: 'var(--bb-primary)', color: '#FFFFFF',
      border: 'none', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: 'var(--bb-shadow-purple)',
    }}>
      <BBIcon name="checklist" size={24} />
    </button>
  </div>
);

Object.assign(window, {
  NotificationsDesktop,
  NotificationsTablet,
  NotificationsMobile,
});
