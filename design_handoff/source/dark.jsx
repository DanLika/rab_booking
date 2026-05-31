/* eslint-disable */
// Dark mode QA sweep — Prompt 38. Validates the .theme-dark token swap on REAL token-based components
// (reuses RevenueHero, PendingStrip, MetricsRow, ActivitySection, BookingCard, BBSidebar, dialogs, StPanel).

// ──────────────────────────────────────────────────────────────
// Dark dashboard (full owner shell in dark)
// ──────────────────────────────────────────────────────────────
const DarkDashboardDesktop = () => (
  <div className="theme-dark bb-screen" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="pregled" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar title="Pregled" notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'dark_mode', label: 'Tema' }]} />
      <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 20 }}>
          <div>
            <h2 className="bb-h1" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Dobro jutro, Ivana</h2>
            <p className="bb-body" style={{ margin: '4px 0 0', color: 'var(--bb-text-tertiary)' }}>Evo kako vam ide u zadnjih 30 dana.</p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {['7 dana', '30 dana', '90 dana', 'Ova godina'].map((l, i) => <BBChip key={i} selected={i === 1}>{l}</BBChip>)}
          </div>
        </div>
        <RevenueHero />
        <PendingStrip count={1} />
        <MetricsRow />
        <ActivitySection />
      </main>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Dark components board
// ──────────────────────────────────────────────────────────────
const DarkComponentsBoard = () => (
  <div className="theme-dark" style={{ width: 1280, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', padding: 40 }}>
    <div style={{ marginBottom: 28 }}>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)' }}>Prompt 38 · QA sweep</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0', color: 'var(--bb-text-primary)' }}>Dark mode — .theme-dark token swap</h2>
      <p className="bb-body" style={{ margin: '6px 0 0', color: 'var(--bb-text-tertiary)' }}>OLED-friendly surfaces, AA-contrast text, lighter dark-theme primary. Same components as light.</p>
    </div>

    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24, marginBottom: 28 }}>
      <StPanel label="Buttons">
        <BBCard>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <BBButton variant="primary" iconLeft="check">Primary</BBButton>
              <BBButton variant="secondary">Secondary</BBButton>
            </div>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <BBButton variant="tertiary" iconLeft="add">Tertiary</BBButton>
              <BBButton variant="destructive">Destructive</BBButton>
            </div>
          </div>
        </BBCard>
      </StPanel>
      <StPanel label="Inputs">
        <BBCard>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <BBInput label="Email" iconLeft="mail" placeholder="ime@primjer.hr" />
            <BBInput label="Lozinka" iconLeft="lock" value="kratko" error="Najmanje 8 znakova" />
          </div>
        </BBCard>
      </StPanel>
      <StPanel label="Status badges">
        <BBCard>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            <BBStatusBadge status="confirmed" />
            <BBStatusBadge status="pending" />
            <BBStatusBadge status="completed" />
            <BBStatusBadge status="cancelled" />
            <BBStatusBadge status="imported" />
          </div>
          <div style={{ marginTop: 14, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <BBChip selected dotColor="#FFB84D">Na čekanju</BBChip>
            <BBChip>Sve</BBChip>
          </div>
        </BBCard>
      </StPanel>
    </div>

    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, alignItems: 'start' }}>
      <StPanel label="Booking card">
        <BookingCard booking={BOOKINGS[0]} />
      </StPanel>
      <StPanel label="Dialog (on dark)">
        <div style={{ display: 'flex', justifyContent: 'center', padding: 8, background: 'rgba(0,0,0,0.3)', borderRadius: 'var(--bb-radius-lg)' }}>
          <ApproveDialog />
        </div>
      </StPanel>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Dark mobile
// ──────────────────────────────────────────────────────────────
const DarkMobile = () => (
  <div className="theme-dark bb-screen" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <BBAppBar title="Rezervacije" showHamburger notifCount={6} actions={[{ icon: 'dark_mode', label: 'Tema' }]} />
    <main style={{ flex: 1, padding: '12px 16px 0', overflow: 'hidden' }}>
      <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
        <BBChip selected size="sm" dotColor="#FFB84D" count={1}>Na čekanju</BBChip>
        <BBChip size="sm">Sve</BBChip>
        <BBChip size="sm" dotColor="#2E7D5B">Potvrđene</BBChip>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {BOOKINGS.slice(0, 2).map(b => <BookingCard key={b.id} booking={b} compact />)}
      </div>
    </main>
  </div>
);

Object.assign(window, { DarkDashboardDesktop, DarkComponentsBoard, DarkMobile });
