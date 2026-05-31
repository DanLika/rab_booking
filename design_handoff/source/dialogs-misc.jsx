/* eslint-disable */
// Misc owner dialogs + toasts — Prompts 24–25.
// Message guest · Request payment · Block dates · Export · system toasts.
// Reuses DialogShell + Textarea + Checkbox (dialogs.jsx), WizSelect (wizard), FiltDate (filters), SAMPLE_BOOKING.

// ──────────────────────────────────────────────────────────────
// Small shared field label
// ──────────────────────────────────────────────────────────────
const MDLabel = ({ children }) => (
  <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontSize: 11, fontWeight: 700, marginBottom: 10 }}>{children}</div>
);

// Recipient row (guest)
const MDRecipient = ({ name, email }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px', background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)', marginBottom: 18 }}>
    <BBAvatar name={name} size="sm" />
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{name}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{email}</div>
    </div>
    <BBStatusBadge status="confirmed" label="Gost" dot={false} size="sm" />
  </div>
);

// ──────────────────────────────────────────────────────────────
// 1 · Message guest
// ──────────────────────────────────────────────────────────────
const MsgGuestDialog = () => (
  <DialogShell icon="chat" iconTone="primary" title="Poruka gostu" sub="Marko Horvat · BB-2402"
    primary={{ label: 'Pošalji poruku', variant: 'primary', iconLeft: 'send' }} secondary={{ label: 'Odustani' }}>
    <MDRecipient name="Marko Horvat" email="marko.horvat@gmail.com" />
    <MDLabel>Predložak</MDLabel>
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
      <BBChip selected iconLeft="waving_hand">Dobrodošlica</BBChip>
      <BBChip iconLeft="key">Upute za dolazak</BBChip>
      <BBChip iconLeft="schedule">Podsjetnik</BBChip>
      <BBChip iconLeft="favorite">Zahvala</BBChip>
    </div>
    <Textarea label="Poruka" rows={4} charLimit={1000}
      defaultValue={'Poštovani Marko,\n\nveselimo se Vašem dolasku 8.7. Check-in je od 14:00. Javite nam okvirno vrijeme dolaska kako bismo pripremili ključeve.\n\nSrdačan pozdrav,\nApartmani Adria'} />
    <Checkbox label="Pošalji mi kopiju na email" checked />
  </DialogShell>
);

// ──────────────────────────────────────────────────────────────
// 2 · Request payment
// ──────────────────────────────────────────────────────────────
const RequestPaymentDialog = () => (
  <DialogShell icon="request_quote" iconTone="success" title="Zatraži uplatu" sub="Šaljemo gostu sigurnu poveznicu za plaćanje."
    primary={{ label: 'Pošalji zahtjev', variant: 'primary', iconLeft: 'send' }} secondary={{ label: 'Odustani' }}>
    <MDRecipient name="Marko Horvat" email="marko.horvat@gmail.com" />
    <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
      <div style={{ flex: 1 }}>
        <MDLabel>Iznos</MDLabel>
        <div style={{ height: 48, display: 'flex', alignItems: 'center', gap: 6, padding: '0 14px', borderRadius: 'var(--bb-radius-sm)', background: 'var(--bb-surface)', border: '1px solid var(--bb-border)' }}>
          <span className="bb-body" style={{ color: 'var(--bb-text-tertiary)', fontWeight: 700 }}>€</span>
          <input defaultValue="288,00" style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontFamily: 'var(--bb-font-sans)', fontSize: 16, fontWeight: 700, color: 'var(--bb-text-primary)', fontVariantNumeric: 'tabular-nums', padding: 0 }} />
        </div>
      </div>
      <div style={{ flex: 1 }}>
        <MDLabel>Dospijeće</MDLabel>
        <FiltDate label="" value="07.07.2026" />
      </div>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', background: 'var(--bb-info-tint)', borderRadius: 'var(--bb-radius-sm)', marginBottom: 16 }}>
      <BBIcon name="link" size={18} style={{ color: 'var(--bb-info)', flexShrink: 0 }} />
      <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>Gost plaća karticom putem Stripe poveznice. Preostali iznos: <strong style={{ color: 'var(--bb-text-primary)' }}>€288,00</strong> od €360,00.</span>
    </div>
    <Checkbox label="Pošalji podsjetnik 2 dana prije dospijeća" checked />
  </DialogShell>
);

// ──────────────────────────────────────────────────────────────
// 3 · Block dates
// ──────────────────────────────────────────────────────────────
const BlockDatesDialog = () => (
  <DialogShell icon="event_busy" iconTone="tertiary" title="Blokiraj datume" sub="Spriječi rezervacije u odabranom razdoblju."
    primary={{ label: 'Blokiraj termin', variant: 'primary', iconLeft: 'lock' }} secondary={{ label: 'Odustani' }}>
    <div style={{ marginBottom: 16 }}>
      <MDLabel>Jedinica</MDLabel>
      <WizSelect label="" icon="bed" value="Studio 4 · Vila Marina" />
    </div>
    <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
      <FiltDate label="Od" value="15.07.2026" />
      <FiltDate label="Do" value="18.07.2026" />
    </div>
    <MDLabel>Razlog</MDLabel>
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
      <BBChip selected iconLeft="handyman">Održavanje</BBChip>
      <BBChip iconLeft="person">Osobno korištenje</BBChip>
      <BBChip iconLeft="more_horiz">Drugo</BBChip>
    </div>
    <Checkbox label="Sinkroniziraj blokadu na Booking.com i Airbnb" checked />
  </DialogShell>
);

// ──────────────────────────────────────────────────────────────
// 4 · Export
// ──────────────────────────────────────────────────────────────
const MDRadioCard = ({ icon, title, sub, selected }) => (
  <button type="button" style={{
    flex: 1, textAlign: 'left', cursor: 'pointer', padding: 14, borderRadius: 'var(--bb-radius-sm)',
    background: selected ? 'var(--bb-primary-tint-bg)' : 'var(--bb-surface)',
    border: `${selected ? '2px' : '1px'} solid ${selected ? 'var(--bb-primary)' : 'var(--bb-border)'}`,
    display: 'flex', flexDirection: 'column', gap: 6,
  }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <BBIcon name={icon} size={22} style={{ color: selected ? 'var(--bb-primary)' : 'var(--bb-text-secondary)' }} />
      <span style={{ width: 18, height: 18, borderRadius: '50%', flexShrink: 0, background: selected ? 'var(--bb-primary)' : 'var(--bb-surface)', border: `2px solid ${selected ? 'var(--bb-primary)' : 'var(--bb-border)'}`, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        {selected && <BBIcon name="check" size={11} style={{ color: '#FFFFFF' }} />}
      </span>
    </div>
    <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{title}</div>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{sub}</div>
  </button>
);

const ExportDialog = () => (
  <DialogShell icon="download" iconTone="info" title="Izvezi rezervacije" sub="12 rezervacija odgovara trenutnim filterima."
    primary={{ label: 'Izvezi (12)', variant: 'primary', iconLeft: 'download' }} secondary={{ label: 'Odustani' }}>
    <MDLabel>Format</MDLabel>
    <div style={{ display: 'flex', gap: 10, marginBottom: 18 }}>
      <MDRadioCard icon="table_view" title="CSV" sub="Excel / Sheets" selected />
      <MDRadioCard icon="picture_as_pdf" title="PDF" sub="Za ispis" />
      <MDRadioCard icon="event" title="iCal" sub="Kalendar" />
    </div>
    <MDLabel>Razdoblje</MDLabel>
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 16 }}>
      <BBChip iconLeft="all_inclusive">Sve</BBChip>
      <BBChip selected iconLeft="calendar_month">Ovaj mjesec</BBChip>
      <BBChip iconLeft="date_range">Prilagođeno</BBChip>
    </div>
    <Checkbox label="Uključi podatke o plaćanju i gostima" checked />
  </DialogShell>
);

// ──────────────────────────────────────────────────────────────
// 5 · Toasts / snackbars
// ──────────────────────────────────────────────────────────────
const MD_TONES = {
  success: { fg: 'var(--bb-success)', bg: 'var(--bb-success-tint)', icon: 'check_circle' },
  error: { fg: 'var(--bb-error)', bg: 'var(--bb-error-tint)', icon: 'error' },
  info: { fg: 'var(--bb-info)', bg: 'var(--bb-info-tint)', icon: 'info' },
  warning: { fg: 'var(--bb-tertiary-dark)', bg: 'var(--bb-tertiary-tint)', icon: 'warning' },
};
const MDToast = ({ tone = 'success', title, msg, action, width = 380 }) => {
  const t = MD_TONES[tone];
  return (
    <div style={{
      width, display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
      background: 'var(--bb-surface)', borderRadius: 'var(--bb-radius-sm)',
      boxShadow: 'var(--bb-shadow-lg)', borderLeft: `4px solid ${t.fg}`,
    }}>
      <div style={{ width: 34, height: 34, borderRadius: 10, flexShrink: 0, background: t.bg, color: t.fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name={t.icon} size={20} fill={1} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{title}</div>
        {msg && <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 1 }}>{msg}</div>}
      </div>
      {action && <button type="button" style={{ border: 'none', background: 'transparent', color: t.fg, fontWeight: 700, fontSize: 13, cursor: 'pointer', fontFamily: 'var(--bb-font-sans)', flexShrink: 0 }}>{action}</button>}
      <button type="button" aria-label="Zatvori" style={{ width: 28, height: 28, border: 'none', background: 'transparent', color: 'var(--bb-text-tertiary)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <BBIcon name="close" size={16} />
      </button>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Message guest — mobile bottom sheet
// ──────────────────────────────────────────────────────────────
const MsgGuestSheet = () => (
  <div style={{ width: 390, background: 'var(--bb-surface)', borderRadius: 'var(--bb-radius-lg) var(--bb-radius-lg) 0 0', boxShadow: 'var(--bb-shadow-lg)', overflow: 'hidden' }}>
    <div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0 4px' }}>
      <span style={{ width: 40, height: 4, borderRadius: 999, background: 'var(--bb-border)' }} />
    </div>
    <div style={{ padding: '12px 20px 0', display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{ width: 40, height: 40, borderRadius: 10, flexShrink: 0, background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
        <BBIcon name="chat" size={22} />
      </div>
      <div style={{ flex: 1 }}>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Poruka gostu</h3>
        <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-secondary)' }}>Marko Horvat · BB-2402</p>
      </div>
    </div>
    <div style={{ padding: '16px 20px 0' }}>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 14 }}>
        <BBChip selected size="sm" iconLeft="waving_hand">Dobrodošlica</BBChip>
        <BBChip size="sm" iconLeft="key">Upute</BBChip>
        <BBChip size="sm" iconLeft="schedule">Podsjetnik</BBChip>
      </div>
      <Textarea label="Poruka" rows={4}
        defaultValue={'Poštovani Marko,\n\nveselimo se Vašem dolasku 8.7. Check-in je od 14:00.'} />
    </div>
    <div style={{ padding: '8px 20px 24px', display: 'flex', gap: 8, borderTop: '1px solid var(--bb-border-subtle)' }}>
      <BBButton variant="tertiary" fullWidth>Odustani</BBButton>
      <BBButton variant="primary" iconLeft="send" fullWidth>Pošalji</BBButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Galleries
// ──────────────────────────────────────────────────────────────
const MiscDialogsGallery = () => (
  <div className="theme-light" style={{ width: 1200, padding: 48, background: 'rgba(13, 17, 28, 0.78)', fontFamily: 'var(--bb-font-sans)', minHeight: 1500 }}>
    <div style={{ color: '#FFFFFF', textAlign: 'center', marginBottom: 32 }}>
      <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.7)' }}>Prompts 24–25 · Misc</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0' }}>Owner dialogs & feedback</h2>
      <p className="bb-body" style={{ margin: '6px 0 0', color: 'rgba(255,255,255,0.78)' }}>Message · Request payment · Block dates · Export — plus system toasts. All on the shared BBDialog base.</p>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 32, justifyItems: 'center', marginBottom: 36 }}>
      <MsgGuestDialog />
      <RequestPaymentDialog />
      <BlockDatesDialog />
      <ExportDialog />
    </div>
    {/* Toasts */}
    <div style={{ color: '#FFFFFF', textAlign: 'center', marginBottom: 16 }}>
      <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.7)' }}>Toasts / snackbars</div>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12, alignItems: 'center' }}>
      <MDToast tone="success" title="Rezervacija potvrđena" msg="Gostu je poslan email potvrde." action="Poništi" width={460} />
      <MDToast tone="error" title="Sinkronizacija nije uspjela" msg="Airbnb feed vraća grešku 503." action="Pokušaj" width={460} />
      <MDToast tone="info" title="Polog zaprimljen · €72,00" msg="Rezervacija BB-2402" width={460} />
    </div>
  </div>
);

const MiscDialogsMobile = () => (
  <div className="theme-light" style={{ width: 390, height: 880, background: 'rgba(13, 17, 28, 0.55)', fontFamily: 'var(--bb-font-sans)', position: 'relative' }}>
    {/* top toast */}
    <div style={{ position: 'absolute', top: 14, left: 0, right: 0, display: 'flex', justifyContent: 'center', zIndex: 3 }}>
      <MDToast tone="success" title="Poruka poslana" msg="Marko Horvat" width={358} />
    </div>
    {/* faint context */}
    <div style={{ position: 'absolute', inset: 0, padding: 16, background: 'var(--bb-bg)', opacity: 0.4 }}>
      <div style={{ height: 56, background: 'var(--bb-surface)', borderRadius: 12, marginBottom: 16 }} />
      <div style={{ height: 120, background: 'var(--bb-surface)', borderRadius: 16 }} />
    </div>
    <div style={{ position: 'absolute', inset: 0, background: 'rgba(13, 17, 28, 0.40)', backdropFilter: 'blur(2px)', WebkitBackdropFilter: 'blur(2px)' }} />
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}>
      <MsgGuestSheet />
    </div>
  </div>
);

Object.assign(window, { MiscDialogsGallery, MiscDialogsMobile });
