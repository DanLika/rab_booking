/* eslint-disable */
// Subscription — Prompt 14. Owner screen reached from Profil → Pretplata.
// PROFILE_USER is on a Pro trial (12 / 14 days left). Trial-status hero + billing toggle + plan cards.
// Mirrors Profil scaffold (sidebar/rail/app-bar with back, centered column — no save footer).

const SUB_PLANS = [
  {
    id: 'free', name: 'Besplatno', price: '€0', sub: 'zauvijek', desc: 'Za prve korake',
    features: [
      { t: '1 smještajna jedinica', ok: true },
      { t: 'Osnovni booking widget', ok: true },
      { t: 'Email podrška', ok: true },
      { t: 'Napredna analitika', ok: false },
      { t: 'AI Asistent', ok: false },
      { t: 'Bez BookBed oznake', ok: false },
    ],
  },
  {
    id: 'pro', name: 'Pro', featured: true, desc: 'Za ozbiljne iznajmljivače',
    features: [
      { t: 'Neograničeno jedinica', ok: true },
      { t: 'Napredna analitika i izvještaji', ok: true },
      { t: 'AI Asistent', ok: true },
      { t: 'iCal sinkronizacija (Booking, Airbnb)', ok: true },
      { t: 'Prioritetna podrška', ok: true },
      { t: 'Bez BookBed oznake u widgetu', ok: true },
    ],
  },
];

// ──────────────────────────────────────────────────────────────
// Scaffold (no footer)
// ──────────────────────────────────────────────────────────────
const SubScaffold = ({ breakpoint, children }) => {
  if (breakpoint === 'desktop') {
    return (
      <div className="theme-light bb-screen bb-shell" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
        <BBSidebar user={SAMPLE_USER} active="profil" pendingCount={1} notifCount={6} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <BBAppBar breadcrumb={['Profil', 'Pretplata']} showBack notifCount={6} />
          <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden', display: 'flex', justifyContent: 'center' }}>
            <div style={{ width: 860, maxWidth: '100%' }}>{children}</div>
          </main>
        </div>
      </div>
    );
  }
  if (breakpoint === 'tablet') {
    return (
      <div className="theme-light bb-screen bb-shell" style={{ width: 768, height: 1024, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
        <BBSidebarRail active="profil" pendingCount={1} notifCount={6} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <BBAppBar breadcrumb={['Profil', 'Pretplata']} showBack notifCount={6} />
          <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
            <div style={{ maxWidth: 640, margin: '0 auto' }}>{children}</div>
          </main>
        </div>
      </div>
    );
  }
  return (
    <div className="theme-light bb-screen bb-shell" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
      <BBAppBar title="Pretplata" showBack notifCount={6} />
      <main style={{ flex: 1, padding: '14px 16px 0', overflow: 'hidden' }}>{children}</main>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Trial-status hero
// ──────────────────────────────────────────────────────────────
const SubStatusHero = ({ compact = false }) => {
  const total = 14, left = 12;
  return (
    <div style={{
      borderRadius: 'var(--bb-radius-xl)', background: 'var(--bb-gradient-hero)', color: '#FFFFFF',
      padding: compact ? 20 : 28, position: 'relative', overflow: 'hidden',
      boxShadow: 'var(--bb-shadow-purple)', marginBottom: compact ? 16 : 24,
    }}>
      <div style={{ position: 'absolute', top: -80, right: -60, width: 280, height: 280, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0) 70%)', pointerEvents: 'none' }} />
      <div style={{ position: 'relative', display: 'flex', alignItems: compact ? 'flex-start' : 'center', gap: 20, flexDirection: compact ? 'column' : 'row' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.82)' }}>Vaš plan</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 6 }}>
            <h2 style={{ margin: 0, color: '#FFFFFF', fontSize: compact ? 22 : 28, fontWeight: 800, letterSpacing: '-0.02em' }}>Probni period</h2>
            <span style={{ background: 'rgba(255,255,255,0.18)', padding: '3px 10px', borderRadius: 999, fontSize: 12, fontWeight: 700 }}>Pro značajke</span>
          </div>
          {!compact && (
            <p className="bb-body" style={{ margin: '8px 0 0', color: 'rgba(255,255,255,0.82)' }}>
              Uživate sve Pro mogućnosti. Završava <strong style={{ color: '#FFFFFF', fontWeight: 700 }}>10. lipnja 2026.</strong>
            </p>
          )}
          {/* progress */}
          <div style={{ marginTop: compact ? 12 : 16, maxWidth: compact ? '100%' : 420 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span className="bb-caption" style={{ color: 'rgba(255,255,255,0.9)', fontWeight: 600 }}>
                <span className="bb-tnum">{left}</span> od <span className="bb-tnum">{total}</span> dana preostalo
              </span>
              {compact && <span className="bb-caption" style={{ color: 'rgba(255,255,255,0.78)' }}>do 10.06.</span>}
            </div>
            <div style={{ height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.22)', overflow: 'hidden' }}>
              <div style={{ height: '100%', width: `${(left / total) * 100}%`, background: 'linear-gradient(90deg, #FFFFFF 0%, rgba(255,255,255,0.78) 100%)', borderRadius: 999 }} />
            </div>
          </div>
        </div>
        <BBButton variant="on-gradient-solid" iconLeft="workspace_premium" size={compact ? 'md' : 'lg'} style={compact ? { width: '100%' } : {}}>Nadogradi na Pro</BBButton>
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Billing toggle
// ──────────────────────────────────────────────────────────────
const SubBillingToggle = ({ cycle, setCycle, compact = false }) => (
  <div style={{ display: 'flex', justifyContent: 'center', marginBottom: compact ? 16 : 20 }}>
    <div style={{ display: 'inline-flex', padding: 4, background: 'var(--bb-surface-variant)', borderRadius: 999, border: '1px solid var(--bb-border-subtle)' }}>
      {[{ id: 'mo', label: 'Mjesečno' }, { id: 'yr', label: 'Godišnje' }].map(o => {
        const on = cycle === o.id;
        return (
          <button key={o.id} type="button" onClick={() => setCycle(o.id)} style={{
            display: 'inline-flex', alignItems: 'center', gap: 8,
            padding: '8px 18px', border: 'none', cursor: 'pointer', borderRadius: 999,
            background: on ? 'var(--bb-surface)' : 'transparent',
            color: on ? 'var(--bb-text-primary)' : 'var(--bb-text-secondary)',
            fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: 600,
            boxShadow: on ? 'var(--bb-shadow-sm)' : 'none',
          }}>
            {o.label}
            {o.id === 'yr' && (
              <span style={{ background: 'var(--bb-success-tint)', color: 'var(--bb-success)', padding: '2px 7px', borderRadius: 999, fontSize: 11, fontWeight: 700 }}>−20%</span>
            )}
          </button>
        );
      })}
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Plan card
// ──────────────────────────────────────────────────────────────
const SubFeatureRow = ({ f }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '7px 0' }}>
    <BBIcon name={f.ok ? 'check_circle' : 'cancel'} size={18} fill={f.ok ? 1 : 0}
      style={{ color: f.ok ? 'var(--bb-success)' : 'var(--bb-text-disabled)', flexShrink: 0 }} />
    <span className="bb-body" style={{ fontSize: 13, color: f.ok ? 'var(--bb-text-secondary)' : 'var(--bb-text-tertiary)', textDecoration: f.ok ? 'none' : 'line-through' }}>{f.t}</span>
  </div>
);

const SubPlanCard = ({ plan, cycle, collapsed = false, maxFeatures }) => {
  const featured = plan.featured;
  const price = plan.id === 'pro' ? (cycle === 'yr' ? '€15' : '€19') : plan.price;
  const sub = plan.id === 'pro' ? '/mjesec' : plan.sub;
  const feats = maxFeatures ? plan.features.slice(0, maxFeatures) : plan.features;
  const moreCount = maxFeatures ? plan.features.length - maxFeatures : 0;
  return (
    <div style={{
      position: 'relative',
      background: 'var(--bb-surface)',
      border: `${featured ? '2px' : '1px'} solid ${featured ? 'var(--bb-primary)' : 'var(--bb-border-subtle)'}`,
      borderRadius: 'var(--bb-radius-md)',
      boxShadow: featured ? 'var(--bb-shadow-purple-sm)' : 'var(--bb-shadow-sm)',
      padding: 20,
      display: 'flex', flexDirection: 'column',
    }}>
      {featured && (
        <span style={{ position: 'absolute', top: -11, left: 20, background: 'var(--bb-primary)', color: '#FFFFFF', fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 999, letterSpacing: '0.02em', boxShadow: 'var(--bb-shadow-purple-sm)' }}>Preporučeno</span>
      )}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <h3 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{plan.name}</h3>
        {plan.id === 'free' && <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 600 }}>Nakon probe</span>}
      </div>
      <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>{plan.desc}</p>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 14 }}>
        <span className="bb-tnum" style={{ fontSize: 40, fontWeight: 800, letterSpacing: '-0.03em', color: featured ? 'var(--bb-primary)' : 'var(--bb-text-primary)' }}>{price}</span>
        <span className="bb-body" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 500 }}>{sub}</span>
      </div>
      {plan.id === 'pro' && cycle === 'yr' && (
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 4 }}>Naplaćeno godišnje <span className="bb-tnum" style={{ fontWeight: 600, color: 'var(--bb-text-secondary)' }}>€180</span> · uštedite <span className="bb-tnum">€48</span></div>
      )}

      {!collapsed && (
        <>
          <div style={{ height: 1, background: 'var(--bb-border-subtle)', margin: '16px 0' }} />
          <div style={{ flex: 1 }}>
            {feats.map((f, i) => <SubFeatureRow key={i} f={f} />)}
            {moreCount > 0 && (
              <div className="bb-caption" style={{ color: 'var(--bb-primary)', fontWeight: 600, marginTop: 6, paddingLeft: 28 }}>+ još {moreCount} značajke</div>
            )}
          </div>
        </>
      )}

      <div style={{ marginTop: collapsed ? 16 : 18 }}>
        {featured
          ? <BBButton variant="primary" iconLeft="workspace_premium" fullWidth>Nadogradi na Pro</BBButton>
          : <BBButton variant="secondary" fullWidth disabled>Trenutni plan nakon probe</BBButton>}
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Footer note
// ──────────────────────────────────────────────────────────────
const SubFootNote = () => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 20, padding: '12px 16px', background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)' }}>
    <BBIcon name="verified_user" size={18} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }} />
    <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', lineHeight: 1.5 }}>
      Sigurno plaćanje putem Stripe-a. Otkažite bilo kada — pretplata se ne obnavlja nakon otkazivanja. <a href="#" style={{ color: 'var(--bb-primary)', fontWeight: 600, textDecoration: 'none' }}>Usporedi sve značajke</a>
    </span>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Body (holds cycle state)
// ──────────────────────────────────────────────────────────────
const SubFreeInline = () => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', background: 'var(--bb-surface)', border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-md)', boxShadow: 'var(--bb-shadow-sm)' }}>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Besplatno · <span className="bb-tnum">€0</span></div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Plan nakon isteka probe · 1 jedinica</div>
    </div>
    <BBButton variant="tertiary" size="sm">Zadrži besplatno</BBButton>
  </div>
);

const SubscriptionBody = ({ breakpoint }) => {
  const compact = breakpoint !== 'desktop';
  const mobile = breakpoint === 'mobile';
  const [cycle, setCycle] = React.useState('yr');
  return (
    <div>
      <SubStatusHero compact={compact} />
      <SubBillingToggle cycle={cycle} setCycle={setCycle} compact={compact} />
      {mobile ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <SubPlanCard plan={SUB_PLANS[1]} cycle={cycle} maxFeatures={4} />
          <SubFreeInline />
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16, alignItems: 'start' }}>
          <SubPlanCard plan={SUB_PLANS[0]} cycle={cycle} />
          <SubPlanCard plan={SUB_PLANS[1]} cycle={cycle} />
        </div>
      )}
      {!mobile && <SubFootNote />}
    </div>
  );
};

const SubscriptionDesktop = () => <SubScaffold breakpoint="desktop"><SubscriptionBody breakpoint="desktop" /></SubScaffold>;
const SubscriptionTablet  = () => <SubScaffold breakpoint="tablet"><SubscriptionBody breakpoint="tablet" /></SubScaffold>;
const SubscriptionMobile  = () => <SubScaffold breakpoint="mobile"><SubscriptionBody breakpoint="mobile" /></SubScaffold>;

Object.assign(window, { SubscriptionDesktop, SubscriptionTablet, SubscriptionMobile });
