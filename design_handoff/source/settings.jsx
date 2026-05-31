/* eslint-disable */
// Settings sub-screens — Prompt 13.
// Three detail screens reached from Profil → Račun: Uredi profil · Promijeni lozinku · Postavke obavijesti.
// Owner-app purple brand. Shared scaffold (sidebar/rail/app-bar + back) + centered form column.
// Composes from BB primitives; adds a few settings-specific controls (toggle, password field, strength meter).

// ──────────────────────────────────────────────────────────────
// Settings-specific controls
// ──────────────────────────────────────────────────────────────
const SToggle = ({ on = false, disabled = false, size = 'md' }) => {
  const w = size === 'sm' ? 38 : 44;
  const h = size === 'sm' ? 22 : 26;
  const knob = h - 6;
  return (
    <span style={{
      width: w, height: h, borderRadius: 999, padding: 3, flexShrink: 0,
      background: on ? 'var(--bb-primary)' : 'var(--bb-border)',
      display: 'inline-flex', alignItems: 'center',
      justifyContent: on ? 'flex-end' : 'flex-start',
      cursor: disabled ? 'not-allowed' : 'pointer', opacity: disabled ? 0.45 : 1,
      transition: 'background 140ms ease-out',
      boxShadow: on ? 'inset 0 0 0 1px rgba(0,0,0,0.02)' : 'none',
    }}>
      <span style={{ width: knob, height: knob, borderRadius: '50%', background: '#FFFFFF', boxShadow: '0 1px 3px rgba(0,0,0,0.22)' }} />
    </span>
  );
};

const SPasswordField = ({ label, value = 'Lozinka123!', helper, error, reveal = false }) => (
  <BBInput
    label={label}
    type={reveal ? 'text' : 'password'}
    value={value}
    iconLeft="lock"
    helper={helper}
    error={error}
    trailingAction={
      <button type="button" aria-label="Prikaži lozinku" style={{
        border: 'none', background: 'transparent', cursor: 'pointer', padding: 0,
        color: 'var(--bb-text-tertiary)', display: 'inline-flex', alignItems: 'center',
      }}>
        <BBIcon name={reveal ? 'visibility' : 'visibility_off'} size={18} fill={0} />
      </button>
    }
  />
);

const STextarea = ({ label, value = '', placeholder, rows = 3, helper, charLimit = 280 }) => (
  <div>
    {label && <label className="bb-label" style={{ display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)' }}>{label}</label>}
    <textarea defaultValue={value} placeholder={placeholder} rows={rows} style={{
      width: '100%', padding: 14, resize: 'vertical', outline: 'none',
      background: 'var(--bb-surface)', border: '1px solid var(--bb-border)',
      borderRadius: 'var(--bb-radius-sm)', color: 'var(--bb-text-primary)',
      fontFamily: 'var(--bb-font-sans)', fontSize: 14, lineHeight: 1.5,
    }} />
    <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{helper || ''}</span>
      <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{value.length}/{charLimit}</span>
    </div>
  </div>
);

// Form section: header + card body
const SFormSection = ({ title, sub, children, padded = true, compact = false }) => (
  <div style={{ marginBottom: compact ? 16 : 20 }}>
    <div style={{ marginBottom: 10 }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h3>
      {sub && <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>{sub}</p>}
    </div>
    <BBCard padded={false}>
      <div style={{ padding: padded ? (compact ? 16 : 20) : 0 }}>{children}</div>
    </BBCard>
  </div>
);

const SInfoBanner = ({ icon = 'info', tone = 'info', children }) => {
  const map = {
    info: { bg: 'var(--bb-info-tint)', fg: 'var(--bb-info)' },
    tertiary: { bg: 'var(--bb-tertiary-tint)', fg: 'var(--bb-tertiary-dark)' },
  };
  const t = map[tone] || map.info;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16,
      padding: '12px 16px', borderRadius: 'var(--bb-radius-sm)',
      background: t.bg,
    }}>
      <BBIcon name={icon} size={20} style={{ color: t.fg, flexShrink: 0 }} />
      <span className="bb-body" style={{ color: 'var(--bb-text-secondary)', fontSize: 13 }}>{children}</span>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Scaffold — sidebar/rail/app-bar + back, centered column, save bar
// ──────────────────────────────────────────────────────────────
const SettingsScaffold = ({ breakpoint, title, primaryLabel = 'Spremi promjene', primaryIcon = 'check', children }) => {
  if (breakpoint === 'desktop') {
    return (
      <div className="theme-light bb-screen bb-shell" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
        <BBSidebar user={SAMPLE_USER} active="profil" pendingCount={1} notifCount={6} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <BBAppBar breadcrumb={['Profil', title]} showBack notifCount={6} />
          <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden', display: 'flex', justifyContent: 'center' }}>
            <div style={{ width: 680, maxWidth: '100%' }}>
              {children}
              <SInlineSaveBar primaryLabel={primaryLabel} primaryIcon={primaryIcon} />
            </div>
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
          <BBAppBar breadcrumb={['Profil', title]} showBack notifCount={6} />
          <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
            <div style={{ maxWidth: 600, margin: '0 auto' }}>
              {children}
              <SInlineSaveBar primaryLabel={primaryLabel} primaryIcon={primaryIcon} />
            </div>
          </main>
        </div>
      </div>
    );
  }
  // mobile
  return (
    <div className="theme-light bb-screen bb-shell" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
      <BBAppBar title={title} showBack notifCount={6} />
      <main style={{ flex: 1, padding: '14px 16px 12px', overflow: 'hidden' }}>
        {children}
      </main>
      <div style={{
        flexShrink: 0, padding: 14,
        background: 'var(--bb-surface)', borderTop: '1px solid var(--bb-border-subtle)',
        boxShadow: '0 -8px 24px rgba(0,0,0,0.05)',
        display: 'flex', gap: 10,
      }}>
        <BBButton variant="secondary" size="md" style={{ flex: 1 }}>Odustani</BBButton>
        <BBButton variant="primary" size="md" iconLeft={primaryIcon} style={{ flex: 2 }}>{primaryLabel}</BBButton>
      </div>
    </div>
  );
};

const SInlineSaveBar = ({ primaryLabel, primaryIcon }) => (
  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 8 }}>
    <BBButton variant="secondary">Odustani</BBButton>
    <BBButton variant="primary" iconLeft={primaryIcon}>{primaryLabel}</BBButton>
  </div>
);

// ──────────────────────────────────────────────────────────────
// 1 · UREDI PROFIL
// ──────────────────────────────────────────────────────────────
const EditProfileContent = ({ compact = false }) => (
  <div>
    <SFormSection title="Profilna fotografija" compact={compact}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <BBAvatarSlot id="bb-owner-avatar" size={compact ? 56 : 80} placeholder="Foto" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <BBButton variant="secondary" size="sm" iconLeft="photo_camera">Promijeni</BBButton>
            <BBButton variant="tertiary" size="sm" iconLeft="delete">Ukloni</BBButton>
          </div>
          <p className="bb-caption" style={{ margin: '8px 0 0', color: 'var(--bb-text-tertiary)' }}>JPG ili PNG, do 5 MB. Preporučeno 400×400 px.</p>
        </div>
      </div>
    </SFormSection>

    <SFormSection title="Osobni podaci" compact={compact}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <BBInput label="Ime" value="Ivana" iconLeft="person" />
          <BBInput label="Prezime" value="Marić" iconLeft="badge" />
        </div>
        <BBInput label="Broj telefona" value="+385 91 234 5678" iconLeft="call" helper="Vidljiv gostima nakon potvrde rezervacije" />
      </div>
    </SFormSection>

    <SFormSection title="Kontakt e-pošta" sub="Koristi se za prijavu i obavijesti" compact={compact}>
      <BBInput
        label="Email adresa"
        value="ivana@apartmaniadria.hr"
        iconLeft="mail"
        trailingAction={
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--bb-success)', fontSize: 12, fontWeight: 600 }}>
            <BBIcon name="verified" size={16} /> Potvrđeno
          </span>
        }
      />
    </SFormSection>

    {!compact && (
      <SFormSection title="O meni" sub="Kratak opis vidljiv gostima na javnom profilu" compact={compact}>
        <STextarea
          value="Obiteljski apartmani uz more u srcu Dalmacije. Trudimo se da se svaki gost osjeća kao kod kuće."
          placeholder="Recite gostima nešto o sebi…"
          rows={3}
          charLimit={280}
          helper="Pomaže u izgradnji povjerenja"
        />
      </SFormSection>
    )}
  </div>
);

const EditProfileDesktop = () => <SettingsScaffold breakpoint="desktop" title="Uredi profil"><EditProfileContent /></SettingsScaffold>;
const EditProfileTablet  = () => <SettingsScaffold breakpoint="tablet" title="Uredi profil"><EditProfileContent compact /></SettingsScaffold>;
const EditProfileMobile  = () => <SettingsScaffold breakpoint="mobile" title="Uredi profil"><EditProfileContent compact /></SettingsScaffold>;

// ──────────────────────────────────────────────────────────────
// 2 · PROMIJENI LOZINKU
// ──────────────────────────────────────────────────────────────
const SStrengthMeter = ({ score = 3, max = 4, label = 'Jaka' }) => (
  <div style={{ marginTop: 12 }}>
    <div style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
      {Array.from({ length: max }).map((_, i) => (
        <div key={i} style={{ flex: 1, height: 5, borderRadius: 999, background: i < score ? 'var(--bb-success)' : 'var(--bb-border)' }} />
      ))}
    </div>
    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Snaga lozinke</span>
      <span className="bb-caption" style={{ color: 'var(--bb-success)', fontWeight: 700 }}>{label}</span>
    </div>
  </div>
);

const SReqList = ({ items }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 14 }}>
    {items.map((it, i) => (
      <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <BBIcon name={it.met ? 'check_circle' : 'radio_button_unchecked'} size={16} fill={it.met ? 1 : 0}
          style={{ color: it.met ? 'var(--bb-success)' : 'var(--bb-text-tertiary)' }} />
        <span className="bb-caption" style={{ color: it.met ? 'var(--bb-text-secondary)' : 'var(--bb-text-tertiary)' }}>{it.label}</span>
      </div>
    ))}
  </div>
);

const ChangePasswordContent = ({ compact = false }) => (
  <div>
    <SInfoBanner icon="schedule" tone="tertiary">Posljednja promjena lozinke prije <strong style={{ color: 'var(--bb-text-primary)' }}>47 dana</strong>.</SInfoBanner>

    <SFormSection title="Trenutna lozinka" compact={compact}>
      <SPasswordField label="Unesite trenutnu lozinku" helper="Zaboravili ste? Možete je resetirati putem e-pošte." />
    </SFormSection>

    <SFormSection title="Nova lozinka" compact={compact}>
      <SPasswordField label="Nova lozinka" />
      <SStrengthMeter score={3} label="Jaka" />
      <SReqList items={[
        { met: true, label: 'Najmanje 8 znakova' },
        { met: true, label: 'Veliko i malo slovo' },
        { met: true, label: 'Barem jedan broj' },
        { met: false, label: 'Barem jedan poseban znak (!?#…)' },
      ]} />
      <div style={{ height: 16 }} />
      <SPasswordField label="Potvrdite novu lozinku" />
    </SFormSection>

    <BBCard padded={false}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: compact ? 16 : 20 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>Odjavi me sa svih ostalih uređaja</div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>Preporučeno ako sumnjate na neovlašteni pristup</div>
        </div>
        <SToggle on />
      </div>
    </BBCard>
  </div>
);

const ChangePasswordDesktop = () => <SettingsScaffold breakpoint="desktop" title="Promijeni lozinku" primaryLabel="Promijeni lozinku" primaryIcon="lock_reset"><ChangePasswordContent /></SettingsScaffold>;
const ChangePasswordTablet  = () => <SettingsScaffold breakpoint="tablet" title="Promijeni lozinku" primaryLabel="Promijeni lozinku" primaryIcon="lock_reset"><ChangePasswordContent compact /></SettingsScaffold>;
const ChangePasswordMobile  = () => <SettingsScaffold breakpoint="mobile" title="Promijeni lozinku" primaryLabel="Spremi" primaryIcon="lock_reset"><ChangePasswordContent compact /></SettingsScaffold>;

// ──────────────────────────────────────────────────────────────
// 3 · POSTAVKE OBAVIJESTI
// ──────────────────────────────────────────────────────────────
const NOTIF_CATS = [
  { icon: 'event_available', tone: 'tertiary', label: 'Nove rezervacije', sub: 'Kad gost zatraži rezervaciju', email: true, push: true },
  { icon: 'event_busy', tone: 'error', label: 'Otkazivanja', sub: 'Otkazane ili izmijenjene rezervacije', email: true, push: true },
  { icon: 'payments', tone: 'success', label: 'Plaćanja i isplate', sub: 'Primljeni depoziti i isplate', email: true, push: true },
  { icon: 'chat', tone: 'info', label: 'Poruke gostiju', sub: 'Novi upiti i poruke', email: false, push: true },
  { icon: 'login', tone: 'primary', label: 'Podsjetnici za dolazak/odlazak', sub: 'Dan prije check-in i check-out', email: false, push: true },
  { icon: 'sync', tone: 'info', label: 'iCal sinkronizacija', sub: 'Greške i nove uvezene rezervacije', email: true, push: false },
  { icon: 'campaign', tone: 'primary', label: 'Savjeti i novosti', sub: 'Proizvodne novosti i marketing', email: true, push: false },
];

const notifTone = (tone) => ({
  primary: { bg: 'var(--bb-primary-tint-bg)', fg: 'var(--bb-primary)' },
  success: { bg: 'var(--bb-success-tint)', fg: 'var(--bb-success)' },
  tertiary: { bg: 'var(--bb-tertiary-tint)', fg: 'var(--bb-tertiary-dark)' },
  info: { bg: 'var(--bb-info-tint)', fg: 'var(--bb-info)' },
  error: { bg: 'var(--bb-error-tint)', fg: 'var(--bb-error)' },
}[tone] || { bg: 'var(--bb-surface-variant)', fg: 'var(--bb-text-secondary)' });

// Desktop/tablet: two toggle columns
const NotifTable = ({ compact = false }) => (
  <BBCard padded={false}>
    {/* Column header */}
    <div style={{ display: 'flex', alignItems: 'center', padding: compact ? '10px 16px' : '12px 20px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <div style={{ flex: 1 }} />
      <div style={{ width: 64, textAlign: 'center' }}><span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', fontSize: 10 }}>Email</span></div>
      <div style={{ width: 64, textAlign: 'center' }}><span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em', fontSize: 10 }}>Push</span></div>
    </div>
    {NOTIF_CATS.map((c, i) => {
      const t = notifTone(c.tone);
      return (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: compact ? '12px 16px' : '14px 20px', borderBottom: i < NOTIF_CATS.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
          <div style={{ width: compact ? 32 : 36, height: compact ? 32 : 36, borderRadius: 10, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <BBIcon name={c.icon} size={compact ? 18 : 20} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: compact ? 13 : 14 }}>{c.label}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{c.sub}</div>
          </div>
          <div style={{ width: 64, display: 'flex', justifyContent: 'center' }}><SToggle on={c.email} /></div>
          <div style={{ width: 64, display: 'flex', justifyContent: 'center' }}><SToggle on={c.push} /></div>
        </div>
      );
    })}
  </BBCard>
);

// Mobile: single compact row per category + Email/Push header (fits 390×880)
const NotifListMobile = () => (
  <BBCard padded={false}>
    <div style={{ display: 'flex', alignItems: 'center', padding: '8px 14px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <div style={{ flex: 1 }} />
      <div style={{ width: 48, textAlign: 'center' }}><span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10 }}>Email</span></div>
      <div style={{ width: 48, textAlign: 'center' }}><span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10 }}>Push</span></div>
    </div>
    {NOTIF_CATS.map((c, i) => {
      const t = notifTone(c.tone);
      return (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 14px', borderBottom: i < NOTIF_CATS.length - 1 ? '1px solid var(--bb-border-subtle)' : 'none' }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <BBIcon name={c.icon} size={16} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: 13, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.label}</div>
          </div>
          <div style={{ width: 48, display: 'flex', justifyContent: 'center' }}><SToggle on={c.email} size="sm" /></div>
          <div style={{ width: 48, display: 'flex', justifyContent: 'center' }}><SToggle on={c.push} size="sm" /></div>
        </div>
      );
    })}
  </BBCard>
);

const QuietHours = ({ compact = false }) => (
  <BBCard padded={false}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: compact ? '12px 16px' : '14px 20px', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <div style={{ width: compact ? 32 : 36, height: compact ? 32 : 36, borderRadius: 10, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <BBIcon name="bedtime" size={compact ? 18 : 20} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: compact ? 13 : 14 }}>Tihi sati</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>Bez push obavijesti tijekom noći</div>
      </div>
      <SToggle on />
    </div>
    <button type="button" style={{ width: '100%', border: 'none', background: 'transparent', cursor: 'pointer', padding: compact ? '12px 16px' : '14px 20px', display: 'flex', alignItems: 'center', gap: 14, textAlign: 'left' }}>
      <div style={{ width: compact ? 32 : 36, flexShrink: 0 }} />
      <span className="bb-label" style={{ flex: 1, color: 'var(--bb-text-secondary)', fontWeight: 500 }}>Razdoblje</span>
      <span className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>22:00 – 07:00</span>
      <BBIcon name="chevron_right" size={20} style={{ color: 'var(--bb-text-tertiary)' }} />
    </button>
  </BBCard>
);

const NotificationContent = ({ compact = false, mobile = false }) => (
  <div>
    <SInfoBanner icon="notifications_active" tone="info">Odaberite kako želite biti obaviješteni. Kritične obavijesti o plaćanju uvijek šaljemo e-poštom.</SInfoBanner>
    <div style={{ marginBottom: compact ? 16 : 20 }}>
      <h3 className="bb-h3" style={{ margin: '0 0 10px', color: 'var(--bb-text-primary)' }}>Vrste obavijesti</h3>
      {mobile ? <NotifListMobile /> : <NotifTable compact={compact} />}
    </div>
    <div>
      <h3 className="bb-h3" style={{ margin: '0 0 10px', color: 'var(--bb-text-primary)' }}>Raspored</h3>
      <QuietHours compact={compact} />
    </div>
  </div>
);

const NotificationSettingsDesktop = () => <SettingsScaffold breakpoint="desktop" title="Postavke obavijesti"><NotificationContent /></SettingsScaffold>;
const NotificationSettingsTablet  = () => <SettingsScaffold breakpoint="tablet" title="Postavke obavijesti"><NotificationContent compact /></SettingsScaffold>;
const NotificationSettingsMobile  = () => <SettingsScaffold breakpoint="mobile" title="Obavijesti"><NotificationContent compact mobile /></SettingsScaffold>;

Object.assign(window, {
  EditProfileDesktop, EditProfileTablet, EditProfileMobile,
  ChangePasswordDesktop, ChangePasswordTablet, ChangePasswordMobile,
  NotificationSettingsDesktop, NotificationSettingsTablet, NotificationSettingsMobile,
});
