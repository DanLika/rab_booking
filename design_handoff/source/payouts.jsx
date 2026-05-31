/* eslint-disable */
// Stripe Connect + bank / Isplate — Prompt 19. Payout setup, reached from Profil.
// Connection status + balance + payout bank account (IBAN) + payout schedule + recent payouts.
// Reuses SettingsToggleRow + ToggleSwitch from ical.jsx (top-level globals). Scaffold mirrors Subscription.
// NOTE: Stripe shown as a neutral indigo tile + label (not a reproduction of the Stripe logo).

const STRIPE_INDIGO = '#635BFF';

const PAYOUTS_DATA = [
  { date: '27.05.2026', amount: '€420,00', status: 'confirmed', ref: 'po_2Kx91', dest: 'Zagrebačka banka ····1234' },
  { date: '20.05.2026', amount: '€288,00', status: 'pending',   ref: 'po_2Kw84', dest: 'Zagrebačka banka ····1234' },
  { date: '14.05.2026', amount: '€540,00', status: 'confirmed', ref: 'po_2Kv57', dest: 'Zagrebačka banka ····1234' },
  { date: '06.05.2026', amount: '€300,00', status: 'confirmed', ref: 'po_2Ku22', dest: 'Zagrebačka banka ····1234' },
];

// ──────────────────────────────────────────────────────────────
// Stripe Connect status card (connected + verified)
// ──────────────────────────────────────────────────────────────
const StripeStatusCard = ({ compact = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? 16 : 20, display: 'flex', alignItems: 'center', gap: 14 }}>
      <div style={{
        width: compact ? 48 : 56, height: compact ? 48 : 56, borderRadius: 14, flexShrink: 0,
        background: STRIPE_INDIGO, color: '#FFFFFF',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 4px 12px rgba(99,91,255,0.32)',
      }}>
        <BBIcon name="account_balance_wallet" size={compact ? 24 : 28} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <h3 className={compact ? 'bb-label' : 'bb-h3'} style={{ margin: 0, color: 'var(--bb-text-primary)', fontWeight: 700 }}>Stripe Connect</h3>
          <BBStatusBadge status="confirmed" label="Povezano" size="sm" />
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', marginTop: 2 }}>Naplata i isplate omogućene</div>
        <div className="bb-mono" style={{ color: 'var(--bb-text-tertiary)', fontSize: 11, marginTop: 4 }}>acct_1Q7xK2··D7n</div>
      </div>
      {!compact && <BBButton variant="secondary" iconRight="open_in_new">Upravljaj na Stripe-u</BBButton>}
    </div>
    {/* verified checks */}
    <div style={{
      display: 'flex', gap: compact ? 8 : 0, flexWrap: 'wrap',
      borderTop: '1px solid var(--bb-border-subtle)', background: 'var(--bb-surface-variant)',
    }}>
      {[
        { icon: 'verified_user', label: 'Identitet potvrđen' },
        { icon: 'payments', label: 'Naplata omogućena' },
        { icon: 'account_balance', label: 'Isplate omogućene' },
      ].map((c, i) => (
        <div key={i} style={{ flex: compact ? '1 1 100%' : 1, display: 'flex', alignItems: 'center', gap: 8, padding: compact ? '8px 16px' : '12px 20px', borderRight: !compact && i < 2 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
          <BBIcon name="check_circle" size={18} fill={1} style={{ color: 'var(--bb-success)', flexShrink: 0 }} />
          <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{c.label}</span>
        </div>
      ))}
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Balance tiles
// ──────────────────────────────────────────────────────────────
const BalanceTile = ({ label, value, valueColor, sub, icon, accent = 'var(--bb-primary)' }) => (
  <BBCard>
    <div style={{ width: 36, height: 36, borderRadius: 10, marginBottom: 12, background: `color-mix(in srgb, ${accent} 14%, transparent)`, color: accent, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <BBIcon name={icon} size={19} />
    </div>
    <span className="bb-caption" style={{ display: 'block', color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{label}</span>
    <div className="bb-tnum" style={{ fontSize: 26, fontWeight: 800, color: valueColor || 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 4 }}>{value}</div>
    {sub && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{sub}</div>}
  </BBCard>
);

const BalanceTiles = ({ mobile = false }) => (
  <div style={{ display: 'grid', gridTemplateColumns: mobile ? 'repeat(2, 1fr)' : 'repeat(3, 1fr)', gap: 16 }}>
    <BalanceTile icon="account_balance_wallet" label="Dostupno za isplatu" value="€1.240,00" accent="var(--bb-success)" valueColor="var(--bb-success)" sub="Isplata sutra" />
    <BalanceTile icon="hourglass_top" label="U obradi" value="€288,00" accent="var(--bb-tertiary-dark)" sub="Nakon dolaska gosta" />
    {!mobile && <BalanceTile icon="payments" label="Isplaćeno (svibanj)" value="€3.840,00" accent="var(--bb-primary)" sub="14 isplata" />}
  </div>
);

// ──────────────────────────────────────────────────────────────
// Bank account card
// ──────────────────────────────────────────────────────────────
const BankCard = ({ compact = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? '14px 16px 10px' : '16px 20px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Bankovni račun za isplate</h3>
      <BBButton variant="tertiary" size="sm" iconLeft="edit">Promijeni</BBButton>
    </div>
    <div style={{ padding: compact ? '0 16px 16px' : '0 20px 18px', display: 'flex', alignItems: 'center', gap: 14 }}>
      <div style={{ width: 48, height: 48, borderRadius: 12, flexShrink: 0, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name="account_balance" size={24} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>Zagrebačka banka</div>
        <div className="bb-mono" style={{ color: 'var(--bb-text-secondary)', fontSize: 13, marginTop: 2 }}>HR12 ···· ···· ···· 1234</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>Vlasnik: Ivana Marić · EUR</div>
      </div>
      <BBStatusBadge status="confirmed" label="Aktivan" dot size="sm" />
    </div>
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Payout schedule (reuses SettingsToggleRow from ical.jsx)
// ──────────────────────────────────────────────────────────────
const PayoutScheduleCard = ({ compact = false }) => (
  <BBCard padded={false}>
    <div style={{ padding: compact ? '14px 16px 10px' : '16px 20px 12px' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Raspored isplata</h3>
    </div>
    <SettingsToggleRow icon="schedule" label="Učestalost isplata" value="Automatski · 2 radna dana" hasChevron />
    <SettingsToggleRow icon="payments" label="Minimalni iznos isplate" value="€50,00" hasChevron />
    <SettingsToggleRow icon="notifications" label="Obavijest o svakoj isplati" sub="Email kad isplata krene prema banci" toggle on last />
  </BBCard>
);

// ──────────────────────────────────────────────────────────────
// Recent payouts
// ──────────────────────────────────────────────────────────────
const RecentPayouts = ({ rows, compact = false }) => (
  <div>
    <BBSectionHeader title="Nedavne isplate" level="h3" action={{ label: 'Sve isplate' }} style={{ marginBottom: 10 }} />
    <BBCard padded={false}>
      {rows.map((p, i) => {
        const isPaid = p.status === 'confirmed';
        return (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: compact ? '12px 16px' : '14px 20px', borderBottom: i < rows.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, flexShrink: 0, background: isPaid ? 'var(--bb-success-tint)' : 'var(--bb-tertiary-tint)', color: isPaid ? 'var(--bb-success)' : 'var(--bb-tertiary-dark)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
              <BBIcon name={isPaid ? 'north_east' : 'hourglass_top'} size={18} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Isplata na {p.dest}</div>
              <div className="bb-caption bb-mono" style={{ color: 'var(--bb-text-tertiary)', fontSize: 11, marginTop: 2 }}>{p.ref} · {p.date}</div>
            </div>
            <div style={{ textAlign: 'right', flexShrink: 0 }}>
              <div className="bb-tnum" style={{ fontSize: 15, fontWeight: 700, color: 'var(--bb-text-primary)' }}>{p.amount}</div>
              <BBStatusBadge status={isPaid ? 'confirmed' : 'pending'} label={isPaid ? 'Isplaćeno' : 'U obradi'} dot={false} size="sm" style={{ marginTop: 4 }} />
            </div>
          </div>
        );
      })}
    </BBCard>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Scaffold + pages
// ──────────────────────────────────────────────────────────────
const PayoutsDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="profil" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Profil', 'Isplate']} showBack notifCount={6} actions={[{ icon: 'help', label: 'Pomoć' }]} />
      <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 760, maxWidth: '100%', display: 'flex', flexDirection: 'column', gap: 16 }}>
          <StripeStatusCard />
          <BalanceTiles />
          <BankCard />
          <PayoutScheduleCard />
          <RecentPayouts rows={PAYOUTS_DATA.slice(0, 3)} />
        </div>
      </main>
    </div>
  </div>
);

const PayoutsTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 768, height: 1024, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebarRail active="profil" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Profil', 'Isplate']} showBack notifCount={6} />
      <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
        <div style={{ maxWidth: 620, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: 14 }}>
          <StripeStatusCard compact />
          <BalanceTiles />
          <BankCard compact />
          <RecentPayouts rows={PAYOUTS_DATA.slice(0, 3)} compact />
        </div>
      </main>
    </div>
  </div>
);

const PayoutsMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <BBAppBar title="Isplate" showBack notifCount={6} />
    <main style={{ flex: 1, padding: '14px 16px 0', overflow: 'hidden' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <StripeStatusCard compact />
        <BalanceTiles mobile />
        <BankCard compact />
        <RecentPayouts rows={PAYOUTS_DATA.slice(0, 2)} compact />
      </div>
    </main>
  </div>
);

Object.assign(window, { PayoutsDesktop, PayoutsTablet, PayoutsMobile });
