/* eslint-disable */
// Legal · Terms / Privacy / Cookies — Prompt 36 (part 2). Document reader: segmented switch + TOC + document column.
// HR. Concise representative clauses (layout is the deliverable). Standalone reader (works logged-in or out).

const LEGAL_TABS = [
  { id: 'terms', label: 'Uvjeti korištenja' },
  { id: 'privacy', label: 'Pravila privatnosti' },
  { id: 'cookies', label: 'Kolačići' },
];

const LEGAL_SECTIONS = [
  { id: 's1', title: '1. Uvodne odredbe', body: 'Ovi Uvjeti uređuju korištenje BookBed platforme za upravljanje smještajem i rezervacijama. Otvaranjem računa i korištenjem usluge potvrđujete da ste pročitali i prihvatili ove uvjete.' },
  { id: 's2', title: '2. Korištenje usluge', body: 'Uslugu smiju koristiti vlasnici smještaja stariji od 18 godina. Odgovorni ste za točnost unesenih podataka, sigurnost pristupnih podataka i sve aktivnosti na svom računu.' },
  { id: 's3', title: '3. Rezervacije i plaćanja', body: 'Plaćanja gostiju obrađuju se putem Stripe-a. Ovisno o odabranom planu, BookBed naplaćuje mjesečnu pretplatu ili naknadu po potvrđenoj rezervaciji, kako je prikazano pri kupnji.' },
  { id: 's4', title: '4. Pravila otkazivanja', body: 'Pravila otkazivanja prema gostima određujete sami, po jedinici. BookBed prosljeđuje povrate putem Stripe-a, ali ne posreduje u izravnim sporovima između vlasnika i gosta.' },
  { id: 's5', title: '5. Obveze vlasnika', body: 'Dužni ste održavati točan kalendar dostupnosti, poštovati potvrđene rezervacije te postupati u skladu s važećim propisima o iznajmljivanju i prijavi gostiju.' },
  { id: 's6', title: '6. Ograničenje odgovornosti', body: 'Usluga se pruža „kakva jest”. BookBed ne odgovara za neizravnu štetu nastalu prekidom rada usluga trećih strana (npr. Booking.com, Airbnb, Stripe) izvan naše kontrole.' },
  { id: 's7', title: '7. Izmjene uvjeta', body: 'Zadržavamo pravo izmjene ovih uvjeta. O značajnim promjenama obavijestit ćemo vas e-poštom najmanje 30 dana prije stupanja na snagu.' },
  { id: 's8', title: '8. Kontakt', body: 'Za sva pitanja vezana uz ove uvjete obratite nam se na podrska@bookbed.io.' },
];

const LegalTopbar = ({ compact = false }) => (
  <header style={{ height: 56, flexShrink: 0, background: 'var(--bb-surface)', borderBottom: '1px solid var(--bb-border-subtle)', display: 'flex', alignItems: 'center', gap: 12, padding: '0 20px' }}>
    <BBButton variant="tertiary" asIcon size="md" iconLeft="arrow_back" ariaLabel="Natrag" />
    <h1 className="bb-h2" style={{ margin: 0, flex: 1, color: 'var(--bb-text-primary)' }}>Pravni dokumenti</h1>
    {!compact && <BBButton variant="secondary" size="sm" iconLeft="download">Preuzmi PDF</BBButton>}
  </header>
);

const LegalTabsRow = ({ compact = false }) => (
  <div style={{ display: 'flex', gap: 8, padding: compact ? '12px 16px' : '16px 0', flexWrap: 'wrap' }}>
    {LEGAL_TABS.map(t => <BBChip key={t.id} variant="tab" selected={t.id === 'terms'} size={compact ? 'sm' : 'md'}>{t.label}</BBChip>)}
  </div>
);

const LegalToc = () => (
  <aside style={{ position: 'sticky', top: 0, alignSelf: 'start' }}>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 700, fontSize: 11, marginBottom: 12 }}>Na ovoj stranici</div>
    <nav style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 20 }}>
      {LEGAL_SECTIONS.map((s, i) => (
        <a key={s.id} href={'#' + s.id} style={{
          padding: '7px 12px', borderRadius: 'var(--bb-radius-sm)', textDecoration: 'none',
          fontSize: 13, fontWeight: i === 0 ? 600 : 500,
          color: i === 0 ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
          background: i === 0 ? 'var(--bb-primary-tint-bg)' : 'transparent',
          borderLeft: i === 0 ? '2px solid var(--bb-primary)' : '2px solid transparent',
        }}>{s.title}</a>
      ))}
    </nav>
    <div style={{ padding: '10px 12px', background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-sm)' }}>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Posljednja izmjena</div>
      <div className="bb-label bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>1. svibnja 2026.</div>
    </div>
  </aside>
);

const LegalSection = ({ s }) => (
  <section id={s.id} style={{ marginBottom: 22 }}>
    <h2 className="bb-h3" style={{ margin: '0 0 8px', color: 'var(--bb-text-primary)' }}>{s.title}</h2>
    <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)', lineHeight: 1.65 }}>{s.body}</p>
  </section>
);

const LegalDocHeader = () => (
  <div style={{ marginBottom: 22 }}>
    <h1 className="bb-display" style={{ margin: 0, color: 'var(--bb-text-primary)', fontSize: 30 }}>Uvjeti korištenja</h1>
    <p className="bb-caption" style={{ margin: '8px 0 0', color: 'var(--bb-text-tertiary)' }}>Vrijedi od <span className="bb-tnum">1. svibnja 2026.</span> · BookBed Inc.</p>
  </div>
);

const LegalDesktop = () => (
  <div className="theme-light bb-screen" style={{ width: 1440, height: 1100, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <LegalTopbar />
    <main style={{ flex: 1, overflow: 'hidden', display: 'flex', justifyContent: 'center', padding: '8px 32px 32px' }}>
      <div style={{ width: 980, maxWidth: '100%' }}>
        <LegalTabsRow />
        <div style={{ display: 'grid', gridTemplateColumns: '240px 1fr', gap: 48, alignItems: 'start' }}>
          <LegalToc />
          <div>
            <LegalDocHeader />
            {LEGAL_SECTIONS.map(s => <LegalSection key={s.id} s={s} />)}
          </div>
        </div>
      </div>
    </main>
  </div>
);

const LegalMobile = () => (
  <div className="theme-light bb-screen" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <LegalTopbar compact />
    <div style={{ borderBottom: '1px solid var(--bb-border-subtle)', background: 'var(--bb-surface)', overflowX: 'auto' }}>
      <LegalTabsRow compact />
    </div>
    <main style={{ flex: 1, overflow: 'hidden', padding: '16px' }}>
      <LegalDocHeader />
      {LEGAL_SECTIONS.slice(0, 4).map(s => <LegalSection key={s.id} s={s} />)}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--bb-text-tertiary)', justifyContent: 'center', marginTop: 4 }}>
        <BBIcon name="expand_more" size={16} />
        <span className="bb-caption">Pomaknite za više</span>
      </div>
    </main>
  </div>
);

Object.assign(window, { LegalDesktop, LegalMobile });
