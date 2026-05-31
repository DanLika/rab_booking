/* eslint-disable */
// Booking detail + create/edit — Prompt 23.
// Detail: full record view (reached from Rezervacije). Create/Edit: shared form.
// Reuses globals: CardHeader/KeyValueRow (units), SFormSection/STextarea (settings),
//   WizSelect/WizCounter/WizPriceField/WizFieldLabel (wizard), FiltDate (filters), SAMPLE_BOOKING.
// Owner shell, active=rezervacije. Create's confirm step uses the existing (frozen) Navigator.push confirm dialog.

const BD_BOOKING = {
  ref: 'BB-2402', guestName: 'Marko Horvat', guestEmail: 'marko.horvat@gmail.com', guestPhone: '+385 91 234 5678',
  property: 'Vila Marina', unit: 'Studio 4', checkIn: '08.07.2026', checkOut: '11.07.2026',
  nights: 3, guests: 2, total: 360, paid: 72, remaining: 288, source: 'Direktno', status: 'pending',
};

// ──────────────────────────────────────────────────────────────
// Scaffold (sidebar/rail/app-bar + back, optional sticky footer)
// ──────────────────────────────────────────────────────────────
const BookingScaffold = ({ breakpoint, title, actions = [], footer, centered = false, children }) => {
  const inner = (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar title={title} showBack notifCount={6} actions={actions} />
      <main style={{ padding: breakpoint === 'mobile' ? '14px 16px 0' : (breakpoint === 'tablet' ? '20px 24px 24px' : '24px 32px 32px'), flex: 1, overflow: 'hidden', display: centered ? 'flex' : 'block', justifyContent: 'center' }}>
        {centered ? <div style={{ width: breakpoint === 'tablet' ? 600 : 720, maxWidth: '100%' }}>{children}</div> : children}
      </main>
      {footer && (
        <div style={{ flexShrink: 0, padding: breakpoint === 'mobile' ? 14 : '16px 32px', background: 'var(--bb-surface)', borderTop: '1px solid var(--bb-border-subtle)', boxShadow: '0 -8px 24px rgba(0,0,0,0.05)' }}>
          {footer}
        </div>
      )}
    </div>
  );
  if (breakpoint === 'desktop') {
    return <div className="theme-light bb-screen" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebar user={SAMPLE_USER} active="rezervacije" pendingCount={1} notifCount={6} />{inner}
    </div>;
  }
  if (breakpoint === 'tablet') {
    return <div className="theme-light bb-screen" style={{ width: 768, height: 1024, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
      <BBSidebarRail active="rezervacije" pendingCount={1} notifCount={6} />{inner}
    </div>;
  }
  return <div className="theme-light bb-screen" style={{ width: 390, height: 880, display: 'flex', flexDirection: 'column', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>{inner}</div>;
};

// ──────────────────────────────────────────────────────────────
// DETAIL — cards
// ──────────────────────────────────────────────────────────────
const BDGuestCard = ({ b, compact = false }) => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
      <BBAvatar name={b.guestName} size={compact ? 'md' : 'lg'} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-h3" style={{ color: 'var(--bb-text-primary)', fontWeight: 700 }}>{b.guestName}</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{b.guestEmail} · <span className="bb-tnum">{b.guestPhone}</span></div>
      </div>
      <div style={{ display: 'flex', gap: 8 }}>
        <BBButton variant="secondary" asIcon size="sm" iconLeft="mail" ariaLabel="Email" />
        <BBButton variant="secondary" asIcon size="sm" iconLeft="call" ariaLabel="Nazovi" />
      </div>
    </div>
  </BBCard>
);

const BDStayCard = ({ b }) => (
  <BBCard>
    <CardHeader icon="event" title="Boravak" />
    <KeyValueRow label="Objekt" value={b.property} />
    <KeyValueRow label="Jedinica" value={b.unit} />
    <KeyValueRow label="Dolazak" value={`${b.checkIn} · 14:00`} />
    <KeyValueRow label="Odlazak" value={`${b.checkOut} · 10:00`} />
    <KeyValueRow label="Trajanje" value={`${b.nights} noći`} />
    <KeyValueRow label="Gosti" value={`${b.guests} odrasle osobe`} />
    <KeyValueRow label="Izvor" value={b.source} last />
  </BBCard>
);

const BDMoneyRow = ({ label, value, tone, strong }) => {
  const c = tone === 'success' ? 'var(--bb-success)' : tone === 'warning' ? 'var(--bb-tertiary-dark)' : 'var(--bb-text-primary)';
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '8px 0' }}>
      <span className="bb-body" style={{ color: tone ? 'var(--bb-text-secondary)' : 'var(--bb-text-secondary)', fontSize: 14 }}>{label}</span>
      <span className="bb-tnum" style={{ fontSize: strong ? 18 : 14, fontWeight: strong ? 800 : 600, color: c }}>{value}</span>
    </div>
  );
};

const BDPriceCard = ({ b }) => (
  <BBCard>
    <CardHeader icon="payments" title="Plaćanje" />
    <BDMoneyRow label="Smještaj (3 noći)" value="€360,00" />
    <div style={{ height: 1, background: 'var(--bb-border-subtle)', margin: '6px 0' }} />
    <BDMoneyRow label="Ukupno" value={`€${b.total.toFixed(2).replace('.', ',')}`} strong />
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 12 }}>
      <div style={{ padding: '10px 12px', background: 'var(--bb-success-tint)', borderRadius: 'var(--bb-radius-sm)' }}>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', fontSize: 10, fontWeight: 700, letterSpacing: '0.04em' }}>Plaćeno (polog)</div>
        <div className="bb-tnum" style={{ fontSize: 16, fontWeight: 800, color: 'var(--bb-success)' }}>€{b.paid.toFixed(2).replace('.', ',')}</div>
      </div>
      <div style={{ padding: '10px 12px', background: 'var(--bb-tertiary-tint)', borderRadius: 'var(--bb-radius-sm)' }}>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', fontSize: 10, fontWeight: 700, letterSpacing: '0.04em' }}>Preostalo</div>
        <div className="bb-tnum" style={{ fontSize: 16, fontWeight: 800, color: 'var(--bb-tertiary-dark)' }}>€{b.remaining.toFixed(2).replace('.', ',')}</div>
      </div>
    </div>
  </BBCard>
);

const BDNotesCard = () => (
  <BBCard>
    <CardHeader icon="sticky_note_2" title="Napomena gosta" />
    <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)', lineHeight: 1.6 }}>
      „Stižemo oko 21:00 — molim ostavite ključ kod susjeda. Dolazimo s malim psom (dogovoreno)."
    </p>
  </BBCard>
);

const BD_TIMELINE = [
  { icon: 'event_available', tone: 'tertiary', title: 'Rezervacija primljena', time: '06.06. 14:22' },
  { icon: 'payments', tone: 'success', title: 'Polog €72,00 naplaćen', time: '06.06. 14:22' },
  { icon: 'mail', tone: 'info', title: 'Potvrda poslana gostu', time: '06.06. 14:23' },
];
const BDActivityCard = () => (
  <BBCard padded={false}>
    <div style={{ padding: '16px 20px 8px' }}><CardHeader icon="history" title="Aktivnost" /></div>
    <div style={{ padding: '0 20px 16px' }}>
      {BD_TIMELINE.map((t, i) => {
        const bg = { tertiary: 'var(--bb-tertiary-tint)', success: 'var(--bb-success-tint)', info: 'var(--bb-info-tint)' }[t.tone];
        const fg = { tertiary: 'var(--bb-tertiary-dark)', success: 'var(--bb-success)', info: 'var(--bb-info)' }[t.tone];
        return (
          <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', alignSelf: 'stretch' }}>
              <div style={{ width: 30, height: 30, borderRadius: '50%', background: bg, color: fg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <BBIcon name={t.icon} size={16} />
              </div>
              {i < BD_TIMELINE.length - 1 && <div style={{ width: 2, flex: 1, minHeight: 14, background: 'var(--bb-border-subtle)', marginTop: 2, marginBottom: 2 }} />}
            </div>
            <div style={{ paddingBottom: i < BD_TIMELINE.length - 1 ? 14 : 0, paddingTop: 4 }}>
              <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{t.title}</div>
              <div className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', marginTop: 1 }}>{t.time}</div>
            </div>
          </div>
        );
      })}
    </div>
  </BBCard>
);

const BDStatusActions = ({ b }) => (
  <BBCard>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
      <BBStatusBadge status={b.status} />
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', flex: 1, textAlign: 'right' }}>Primljeno prije 2 dana</span>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <BBButton variant="primary" iconLeft="check" fullWidth>Odobri rezervaciju</BBButton>
      <BBButton variant="destructive-soft" iconLeft="close" fullWidth>Odbij</BBButton>
    </div>
    <div style={{ height: 1, background: 'var(--bb-border-subtle)', margin: '14px 0' }} />
    <div style={{ display: 'flex', gap: 8 }}>
      <BBButton variant="secondary" iconLeft="chat" style={{ flex: 1 }} size="sm">Poruka</BBButton>
      <BBButton variant="secondary" iconLeft="edit" style={{ flex: 1 }} size="sm">Uredi</BBButton>
      <BBButton variant="secondary" asIcon size="sm" iconLeft="more_horiz" ariaLabel="Više" />
    </div>
  </BBCard>
);

const BDMetaCard = ({ b }) => (
  <BBCard>
    <KeyValueRow label="Broj rezervacije" value={`#${b.ref}`} />
    <KeyValueRow label="Kreirano" value="06.06.2026" />
    <KeyValueRow label="Kanal" value={b.source} last />
  </BBCard>
);

const BDPendingAlert = () => (
  <BBCard variant="accent-left" accentTone="tertiary" padded={false}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px' }}>
      <BBIcon name="pending_actions" size={22} style={{ color: 'var(--bb-tertiary-dark)' }} />
      <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, flex: 1 }}>Ova rezervacija čeka vaše odobrenje</span>
    </div>
  </BBCard>
);

// Unit cover photo — user-fillable drop zone (shared id → one photo fills every breakpoint)
const BDCover = ({ h = 180 }) => (
  <div style={{ position: 'relative', borderRadius: 'var(--bb-radius-md)', overflow: 'hidden', border: '1px solid var(--bb-border-subtle)', boxShadow: 'var(--bb-shadow-sm)' }}>
    <image-slot
      id="bb-bd-cover"
      shape="rounded"
      radius="0"
      placeholder="Naslovna fotografija jedinice — povucite ovdje"
      style={{ display: 'block', width: '100%', height: h }}
    ></image-slot>
    <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '28px 16px 12px', background: 'linear-gradient(to top, rgba(16,18,28,0.62), rgba(16,18,28,0))', pointerEvents: 'none' }}>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.07em', textTransform: 'uppercase', color: 'rgba(255,255,255,0.82)' }}>{BD_BOOKING.property}</span>
        <span style={{ width: 3, height: 3, borderRadius: '50%', background: 'rgba(255,255,255,0.55)' }} />
        <span style={{ fontSize: 14, fontWeight: 700, color: '#FFFFFF' }}>{BD_BOOKING.unit}</span>
      </div>
    </div>
  </div>
);

// Detail pages
const BookingDetailDesktop = () => (
  <BookingScaffold breakpoint="desktop" title="Rezervacija #BB-2402" actions={[{ icon: 'print', label: 'Ispis' }, { icon: 'share', label: 'Podijeli' }]}>
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: 24, alignItems: 'start' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <BDCover h={180} />
        <BDPendingAlert />
        <BDGuestCard b={BD_BOOKING} />
        <BDStayCard b={BD_BOOKING} />
        <BDNotesCard />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <BDStatusActions b={BD_BOOKING} />
        <BDPriceCard b={BD_BOOKING} />
        <BDActivityCard />
        <BDMetaCard b={BD_BOOKING} />
      </div>
    </div>
  </BookingScaffold>
);

const BookingDetailTablet = () => (
  <BookingScaffold breakpoint="tablet" title="Rezervacija #BB-2402">
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      <BDCover h={150} />
      <BDPendingAlert />
      <BDGuestCard b={BD_BOOKING} compact />
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, alignItems: 'start' }}>
        <BDStayCard b={BD_BOOKING} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <BDStatusActions b={BD_BOOKING} />
          <BDPriceCard b={BD_BOOKING} />
        </div>
      </div>
    </div>
  </BookingScaffold>
);

const BookingDetailMobile = () => (
  <BookingScaffold breakpoint="mobile" title="#BB-2402" footer={
    <div style={{ display: 'flex', gap: 8 }}>
      <BBButton variant="destructive-soft" iconLeft="close" style={{ flex: 1 }}>Odbij</BBButton>
      <BBButton variant="primary" iconLeft="check" style={{ flex: 2 }}>Odobri</BBButton>
    </div>
  }>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <BDCover h={116} />
      <BDGuestCard b={BD_BOOKING} compact />
      <BDStayCard b={BD_BOOKING} />
      <BDPriceCard b={BD_BOOKING} />
    </div>
  </BookingScaffold>
);

// ──────────────────────────────────────────────────────────────
// CREATE / EDIT — shared form
// ──────────────────────────────────────────────────────────────
// Desktop grid block (no outer margin — grid gap handles spacing)
const FormBlock = ({ title, sub, span = false, children }) => (
  <div style={span ? { gridColumn: '1 / -1' } : undefined}>
    <div style={{ marginBottom: 10 }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h3>
      {sub && <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-tertiary)' }}>{sub}</p>}
    </div>
    <BBCard>{children}</BBCard>
  </div>
);

const NightsBadge = () => (
  <div style={{ height: 44, display: 'inline-flex', alignItems: 'center', padding: '0 12px', background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)', borderRadius: 'var(--bb-radius-sm)', fontWeight: 700, fontSize: 13, whiteSpace: 'nowrap', flexShrink: 0 }} className="bb-tnum">3 noći</div>
);

const BookingForm = ({ mode = 'create', compact = false }) => {
  const v = mode === 'edit'
    ? { name: 'Marko Horvat', email: 'marko.horvat@gmail.com', phone: '+385 91 234 5678' }
    : { name: '', email: '', phone: '' };

  // ── Mobile: trimmed single column (essentials) + price summary ──
  if (compact) {
    return (
      <div>
        <SFormSection title="Gost" compact>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <BBInput label="Ime i prezime" value={v.name} placeholder="npr. Marko Horvat" iconLeft="person" />
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              <BBInput label="Email" value={v.email} placeholder="email@…" iconLeft="mail" type="email" />
              <BBInput label="Telefon" value={v.phone} placeholder="+385 …" iconLeft="call" />
            </div>
          </div>
        </SFormSection>
        <SFormSection title="Smještaj" compact>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <WizSelect label="Objekt" icon="domain" value="Vila Marina" />
            <WizSelect label="Jedinica" icon="bed" value="Studio 4" />
          </div>
        </SFormSection>
        <SFormSection title="Termin" compact>
          <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
            <FiltDate label="Dolazak" value="08.07.2026" />
            <FiltDate label="Odlazak" value="11.07.2026" />
            <NightsBadge />
          </div>
        </SFormSection>
        <SFormSection title="Gosti" compact>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <WizCounter label="Odrasli" icon="group" value={2} min={1} />
            <WizCounter label="Djeca" icon="child_care" value={0} min={0} />
          </div>
        </SFormSection>
        {/* compact price summary */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)' }}>
          <BBIcon name="payments" size={18} style={{ color: 'var(--bb-primary)' }} />
          <span className="bb-label" style={{ color: 'var(--bb-text-secondary)', flex: 1 }}>Ukupno (3 noći)</span>
          <span className="bb-tnum" style={{ fontWeight: 800, color: 'var(--bb-text-primary)' }}>€360,00</span>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>polog €72</span>
        </div>
      </div>
    );
  }

  // ── Desktop / tablet: 2-column grid ──
  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', columnGap: 20, rowGap: 16, alignItems: 'start' }}>
        <FormBlock title="Gost" span>
          <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr', gap: 12 }}>
            <BBInput label="Ime i prezime" value={v.name} placeholder="npr. Marko Horvat" iconLeft="person" />
            <BBInput label="Email" value={v.email} placeholder="email@primjer.hr" iconLeft="mail" type="email" />
            <BBInput label="Telefon" value={v.phone} placeholder="+385 …" iconLeft="call" />
          </div>
        </FormBlock>
        <FormBlock title="Smještaj">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <WizSelect label="Objekt" icon="domain" value="Vila Marina" />
            <WizSelect label="Jedinica" icon="bed" value="Studio 4" />
          </div>
        </FormBlock>
        <FormBlock title="Termin">
          <div style={{ display: 'flex', gap: 12, alignItems: 'flex-end' }}>
            <FiltDate label="Dolazak" value="08.07.2026" />
            <FiltDate label="Odlazak" value="11.07.2026" />
            <NightsBadge />
          </div>
        </FormBlock>
        <FormBlock title="Gosti">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <WizCounter label="Odrasli" icon="group" value={2} min={1} />
            <WizCounter label="Djeca" icon="child_care" value={0} min={0} />
          </div>
        </FormBlock>
        <FormBlock title="Cijena" sub="Polog automatski (20%)">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
            <WizPriceField label="Po noći" value="120" prefix="€" />
            <WizPriceField label="Ukupno" value="360" prefix="€" />
            <WizPriceField label="Polog" value="72" prefix="€" />
          </div>
        </FormBlock>
        <FormBlock title="Izvor">
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {['Direktno', 'Booking.com', 'Airbnb', 'Widget', 'Telefon'].map((s, i) => (
              <BBChip key={s} iconLeft={i === 0 ? 'public' : undefined} selected={i === 0}>{s}</BBChip>
            ))}
          </div>
        </FormBlock>
        <FormBlock title="Napomena" sub="Interno — vidljivo samo vama" span>
          <STextarea value={mode === 'edit' ? 'Gost dolazi kasno, ostaviti ključ kod susjeda.' : ''} placeholder="Bilješke o rezervaciji…" rows={2} charLimit={400} />
        </FormBlock>
      </div>
    </div>
  );
};

const BookingFormFooter = ({ mode, compact }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
    {!compact && mode === 'edit' && (
      <BBButton variant="tertiary" iconLeft="delete" style={{ color: 'var(--bb-error)' }}>Obriši</BBButton>
    )}
    <BBButton variant="secondary" style={compact ? { flex: 1 } : {}}>Odustani</BBButton>
    <div style={{ flex: 1 }} />
    {!compact && mode === 'create' && (
      <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', display: 'inline-flex', alignItems: 'center', gap: 6 }}>
        <BBIcon name="info" size={15} /> Nakon spremanja otvara se potvrda slanja gostu
      </span>
    )}
    <BBButton variant="primary" iconLeft="check" style={compact ? { flex: 2 } : {}}>{mode === 'edit' ? 'Spremi izmjene' : 'Spremi rezervaciju'}</BBButton>
  </div>
);

const BookingCreateDesktop = () => (
  <BookingScaffold breakpoint="desktop" title="Nova rezervacija" centered footer={<BookingFormFooter mode="create" />}>
    <BookingForm mode="create" />
  </BookingScaffold>
);
const BookingEditDesktop = () => (
  <BookingScaffold breakpoint="desktop" title="Uredi rezervaciju #BB-2402" centered footer={<BookingFormFooter mode="edit" />}>
    <BookingForm mode="edit" />
  </BookingScaffold>
);
const BookingCreateMobile = () => (
  <BookingScaffold breakpoint="mobile" title="Nova rezervacija" footer={<BookingFormFooter mode="create" compact />}>
    <BookingForm mode="create" compact />
  </BookingScaffold>
);

Object.assign(window, {
  BookingDetailDesktop, BookingDetailTablet, BookingDetailMobile,
  BookingCreateDesktop, BookingEditDesktop, BookingCreateMobile,
});
