/* eslint-disable */
// Foundation Gallery — the design system showcase artboard.

const FoundationGallery = () => (
  <div className="theme-light" style={{
    width: 1280, padding: 48,
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
    color: 'var(--bb-text-primary)',
  }}>
    {/* HEADER */}
    <div style={{ marginBottom: 40 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
        <BBLogo size={56} />
        <div>
          <h1 className="bb-display" style={{ margin: 0 }}>BookBed Design System</h1>
          <p className="bb-body" style={{ margin: '4px 0 0', color: 'var(--bb-text-secondary)' }}>
            Foundation tokens + core primitives. Prompt 00 reference.
          </p>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <PillTag>Inter (variable)</PillTag>
        <PillTag>8px grid</PillTag>
        <PillTag>Radius sm 12 mandate</PillTag>
        <PillTag>Light + Dark</PillTag>
        <PillTag>Reduced-motion safe</PillTag>
        <PillTag>≥48px tap targets</PillTag>
        <PillTag>Tabular figures on numerics</PillTag>
      </div>
    </div>

    {/* COLORS */}
    <Section eyebrow="Foundations · 01" title="Color">
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
        <Swatch name="primary"      value="#6B4CE6" cssVar="--bb-primary" textOnDark />
        <Swatch name="primary-dark" value="#5638C7" cssVar="--bb-primary-dark" textOnDark />
        <Swatch name="secondary"    value="#FF6B6B" cssVar="--bb-secondary" textOnDark />
        <Swatch name="tertiary"     value="#FFB84D" cssVar="--bb-tertiary" />
      </div>
      <div style={{ height: 16 }} />
      <SubSection title="Booking status (semantic)">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 12 }}>
          <Swatch name="confirmed" value="#2E7D5B" cssVar="--bb-status-confirmed" textOnDark />
          <Swatch name="pending"   value="#FFB84D" cssVar="--bb-status-pending" />
          <Swatch name="cancelled" value="#718096" cssVar="--bb-status-cancelled" textOnDark />
          <Swatch name="completed" value="#6B4CE6" cssVar="--bb-status-completed" textOnDark />
          <Swatch name="imported"  value="#4A90D9" cssVar="--bb-status-imported" textOnDark />
        </div>
      </SubSection>
      <SubSection title="Surfaces & text">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          <Swatch name="bg" value="#FAFAFA" cssVar="--bb-bg" />
          <Swatch name="surface" value="#FFFFFF" cssVar="--bb-surface" bordered />
          <Swatch name="surface-variant" value="#F5F5F5" cssVar="--bb-surface-variant" />
          <Swatch name="border" value="#E2E8F0" cssVar="--bb-border" />
        </div>
        <div style={{ height: 8 }} />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
          <Swatch name="text-primary"   value="#2D3748" cssVar="--bb-text-primary" textOnDark />
          <Swatch name="text-secondary" value="#4A5568" cssVar="--bb-text-secondary" textOnDark />
          <Swatch name="text-tertiary"  value="#718096" cssVar="--bb-text-tertiary" textOnDark />
        </div>
      </SubSection>
    </Section>

    {/* TYPOGRAPHY */}
    <Section eyebrow="Foundations · 02" title="Typography · Inter">
      <BBCard padded={true} style={{ padding: 28 }}>
        <TypeRow tag="display-lg" sample="€3.840,00" meta="48 / 800 · -0.03em · tnum" className="bb-display-lg bb-tnum" />
        <TypeRow tag="display"    sample="Dobro jutro, Ivana" meta="32 / 700 · -0.02em" className="bb-display" />
        <TypeRow tag="h1"         sample="Rezervacije" meta="24 / 700 · -0.015em" className="bb-h1" />
        <TypeRow tag="h2"         sample="Pregled · Nedavne aktivnosti" meta="20 / 600 · -0.01em" className="bb-h2" />
        <TypeRow tag="h3"         sample="Vila Marina · Studio 4" meta="18 / 600" className="bb-h3" />
        <TypeRow tag="body-lg"    sample="Census data, school ratings — sve na jednom mjestu." meta="16 / 400 · lh 1.5" className="bb-body-lg" />
        <TypeRow tag="body"       sample="Pregledajte kako se područja uspoređuju po metrikama koje vam najviše znače." meta="14 / 400 · lh 1.5" className="bb-body" />
        <TypeRow tag="label"      sample="Cijena po noći" meta="13 / 500 · 0.01em" className="bb-label" />
        <TypeRow tag="caption"    sample="prije 4 dana" meta="12 / 400" className="bb-caption" />
        <TypeRow tag="mono"       sample="BB-2402 · BB-TEST03" meta="JetBrains Mono · 13 / 500" className="bb-mono" />
        <TypeRow tag="eyebrow"    sample="DEMOGRAFIJA · ZADNJIH 30 DANA" meta="11 / 600 · 0.08em · uppercase" className="bb-eyebrow" last />
      </BBCard>
    </Section>

    {/* SPACING + RADIUS */}
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 32 }}>
      <Section eyebrow="Foundations · 03" title="Spacing · 8px grid">
        <BBCard>
          {[4, 8, 16, 24, 32, 48, 64].map((px, i) => (
            <div key={px} style={{ display: 'flex', alignItems: 'center', gap: 16, paddingBottom: i === 6 ? 0 : 12 }}>
              <span className="bb-mono" style={{ width: 40, color: 'var(--bb-text-tertiary)' }}>{px}px</span>
              <span className="bb-label" style={{ width: 80, color: 'var(--bb-text-secondary)' }}>{['xxs','xs','sm','md','lg','xl','xxl'][i]}</span>
              <div style={{ height: 8, width: px, background: 'var(--bb-primary)', borderRadius: 4 }} />
            </div>
          ))}
        </BBCard>
        <p className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 8 }}>
          Note: 12px is intentionally NOT in the spacing scale — only used as radius-sm on buttons/inputs/chips per CLAUDE.md.
        </p>
      </Section>
      <Section eyebrow="Foundations · 04" title="Radius & shadow">
        <BBCard>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 12, marginBottom: 24 }}>
            {[
              { k: 'xs', v: 6 }, { k: 'sm', v: 12 }, { k: 'md', v: 20 },
              { k: 'lg', v: 24 }, { k: 'xl', v: 32 }, { k: 'full', v: 999 },
            ].map(r => (
              <div key={r.k} style={{ textAlign: 'center' }}>
                <div style={{
                  height: 64, background: 'var(--bb-primary-tint-bg)',
                  borderRadius: r.v, marginBottom: 6,
                  border: '1px solid var(--bb-border-subtle)',
                }} />
                <div className="bb-caption" style={{ fontWeight: 600 }}>{r.k}</div>
                <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{r.v === 999 ? '∞' : `${r.v}px`}</div>
              </div>
            ))}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
            {[
              { k: 'sm', s: 'var(--bb-shadow-sm)' },
              { k: 'md', s: 'var(--bb-shadow-md)' },
              { k: 'lg', s: 'var(--bb-shadow-lg)' },
              { k: 'purple', s: 'var(--bb-shadow-purple)' },
            ].map(sh => (
              <div key={sh.k} style={{ textAlign: 'center' }}>
                <div style={{
                  height: 64, background: 'var(--bb-surface)',
                  borderRadius: 16, marginBottom: 6,
                  boxShadow: sh.s,
                  border: '1px solid var(--bb-border-subtle)',
                }} />
                <div className="bb-caption" style={{ fontWeight: 600 }}>{sh.k}</div>
              </div>
            ))}
          </div>
        </BBCard>
      </Section>
    </div>

    {/* BUTTONS */}
    <Section eyebrow="Primitives · 01" title="BBButton">
      <BBCard>
        <SubLabel>Variants × md size</SubLabel>
        <Row>
          <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
          <BBButton variant="secondary" iconLeft="tune">Filteri</BBButton>
          <BBButton variant="tertiary" iconRight="arrow_forward">Sve aktivnosti</BBButton>
          <BBButton variant="destructive" iconLeft="delete">Obriši</BBButton>
          <BBButton variant="destructive-soft" iconLeft="close">Odbij</BBButton>
          <BBButton variant="success" iconLeft="check">Odobri</BBButton>
        </Row>
        <SubLabel>Sizes</SubLabel>
        <Row>
          <BBButton variant="primary" size="sm">Small · 36px</BBButton>
          <BBButton variant="primary" size="md">Medium · 44px</BBButton>
          <BBButton variant="primary" size="lg">Large · 52px</BBButton>
        </Row>
        <SubLabel>States</SubLabel>
        <Row>
          <BBButton variant="primary">Default</BBButton>
          <BBButton variant="primary" disabled>Disabled</BBButton>
          <BBButton variant="primary" loading>Loading</BBButton>
          <BBButton variant="secondary" asIcon iconLeft="more_horiz" ariaLabel="Više" />
          <BBButton variant="primary" asIcon iconLeft="add" ariaLabel="Dodaj" />
        </Row>
      </BBCard>
    </Section>

    {/* INPUTS */}
    <Section eyebrow="Primitives · 02" title="BBInput">
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <BBCard>
          <SubLabel>Default + focused + error</SubLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <BBInput label="Email" iconLeft="mail" placeholder="ime@primjer.hr" />
            <BBInput label="Lozinka" iconLeft="lock" placeholder="••••••••" iconRight="visibility_off" focused />
            <BBInput label="IBAN" iconLeft="account_balance" value="HR12 1001 0051 8630" error="IBAN nije važeći format" />
          </div>
        </BBCard>
        <BBCard>
          <SubLabel>With helper / counter / disabled</SubLabel>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <BBInput label="URL slug" iconLeft="link" placeholder="studio-4" helper="Koristi se u URL-u widgeta" />
            <BBInput label="Opis jedinice" placeholder="Dodatne informacije za goste…" value="Prostran apartman s pogledom na more, 2 spavaće sobe i terasa od 12 m²." charLimit={500} />
            <BBInput label="Email (potvrđen)" iconLeft="verified" value="ivana@apartmaniadria.hr" disabled />
          </div>
        </BBCard>
      </div>
    </Section>

    {/* CARDS + STATUS + CHIPS + AVATARS */}
    <Section eyebrow="Primitives · 03–06" title="Cards, status, chips, avatars">
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
        <BBCard hoverable>
          <SubLabel>Card · hoverable</SubLabel>
          <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)' }}>Resting state. Hover for elevation lift + shadow-md.</p>
        </BBCard>
        <BBCard selected>
          <SubLabel>Card · selected</SubLabel>
          <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)' }}>Primary 1px border, no shadow change.</p>
        </BBCard>
        <BBCard variant="accent-left" accentTone="tertiary">
          <SubLabel>Card · accent-left (gold)</SubLabel>
          <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)' }}>For pending-action nudges and informational strips.</p>
        </BBCard>
        <BBCard variant="accent-left" accentTone="success">
          <SubLabel>Card · accent-left (success)</SubLabel>
          <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)' }}>For confirmations, completed states.</p>
        </BBCard>
      </div>

      <BBCard>
        <SubLabel>BBStatusBadge — 5 booking statuses</SubLabel>
        <Row>
          <BBStatusBadge status="pending" />
          <BBStatusBadge status="confirmed" />
          <BBStatusBadge status="completed" />
          <BBStatusBadge status="cancelled" />
          <BBStatusBadge status="imported" />
        </Row>

        <SubLabel>BBChip — filter chips, with counts and dots</SubLabel>
        <Row>
          <BBChip selected dotColor="#FFB84D" count={3}>Na čekanju</BBChip>
          <BBChip dotColor="#FFB84D" count={3} countColor="#FFB84D">Na čekanju</BBChip>
          <BBChip dotColor="#2E7D5B">Potvrđene</BBChip>
          <BBChip dotColor="#6B4CE6">Završene</BBChip>
          <BBChip dotColor="#718096">Otkazane</BBChip>
          <BBChip iconLeft="cloud_download">Uvezene</BBChip>
        </Row>

        <SubLabel>BBAvatar — sm / md / lg + group + ring</SubLabel>
        <Row>
          <BBAvatar name="Ivana Marić" size="sm" />
          <BBAvatar name="Marko Horvat" size="md" />
          <BBAvatar name="Sandra Kovač" size="lg" />
          <BBAvatar name="Luka Babić" size="xl" tone="success" />
          <div style={{ display: 'flex', marginLeft: 8 }}>
            {['Ivana Marić', 'Marko Horvat', 'Sandra Kovač'].map((n, i) => (
              <span key={n} style={{ marginLeft: i ? -10 : 0, boxShadow: '0 0 0 2px var(--bb-surface)' }}>
                <BBAvatar name={n} size="md" tone={['primary', 'success', 'tertiary'][i]} />
              </span>
            ))}
          </div>
        </Row>
      </BBCard>
    </Section>

    {/* EMPTY STATE */}
    <Section eyebrow="Primitives · 07" title="BBEmptyState · the iCal-import gold-standard">
      <BBCard padded={false}>
        <BBEmptyState
          icon="bed"
          title="Spremni za prvu rezervaciju?"
          body="Dodajte smještajnu jedinicu i podijelite widget na svojoj web stranici da primite prve goste."
          primary={{ label: 'Dodaj jedinicu', iconLeft: 'add' }}
          secondary={{ label: 'Postavke widgeta' }}
          benefits={[
            { icon: 'sync', title: 'Automatska sinkronizacija', body: 'Booking.com, Airbnb i druge platforme uvoze se svakih 15 min.' },
            { icon: 'event_busy', title: 'Bez dvostrukih rezervacija', body: 'Termini se odmah blokiraju na svim platformama.' },
            { icon: 'shield', title: 'Sigurno i privatno', body: 'Podaci su enkriptirani, plaćanja preko Stripe-a.' },
          ]}
        />
      </BBCard>
    </Section>

    {/* SKELETON */}
    <Section eyebrow="Primitives · 08" title="BBSkeleton — shaped loading">
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <BBCard>
          <SubLabel>Stat-tile skeleton</SubLabel>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
            {[0,1,2].map(i => (
              <div key={i}>
                <BBSkeleton w={40} h={40} radius={12} />
                <div style={{ height: 16 }} />
                <BBSkeleton w="60%" h={11} />
                <div style={{ height: 8 }} />
                <BBSkeleton w="80%" h={28} />
              </div>
            ))}
          </div>
        </BBCard>
        <BBCard padded={false}>
          <SubLabel style={{ padding: '20px 20px 0' }}>Activity-row skeleton</SubLabel>
          <div style={{ padding: '12px 0 16px' }}>
            {[0,1,2].map(i => (
              <div key={i} style={{
                padding: '12px 20px', display: 'flex', alignItems: 'center', gap: 14,
                borderBottom: i < 2 ? '1px solid var(--bb-border-subtle)' : 'none',
              }}>
                <BBSkeleton w={40} h={40} radius={12} />
                <div style={{ flex: 1 }}>
                  <BBSkeleton w="50%" h={12} />
                  <div style={{ height: 6 }} />
                  <BBSkeleton w="70%" h={10} />
                </div>
                <BBSkeleton w={50} h={11} />
              </div>
            ))}
          </div>
        </BBCard>
      </div>
    </Section>

    {/* APP BAR */}
    <Section eyebrow="Chrome · 01" title="BBAppBar · slim, surface-tinted (replaces heavy purple slab)">
      <div style={{
        borderRadius: 'var(--bb-radius-md)',
        overflow: 'hidden',
        boxShadow: 'var(--bb-shadow-sm)',
        border: '1px solid var(--bb-border-subtle)',
      }}>
        <BBAppBar title="Pregled" notifCount={6} actions={[
          { icon: 'search', label: 'Pretraži' },
          { icon: 'light_mode', label: 'Tema' },
        ]} />
        <div style={{ height: 1, background: 'var(--bb-border-subtle)' }} />
        <BBAppBar title="Uredi profil" showBack actions={[{ icon: 'save', label: 'Spremi' }]} />
      </div>
    </Section>

    {/* DIALOGS + SHEETS */}
    <Section eyebrow="Chrome · 02" title="BBDialog + BBBottomSheet">
      <div style={{
        background: 'var(--bb-surface-variant)',
        borderRadius: 'var(--bb-radius-md)',
        padding: 32,
        display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 24,
      }}>
        <div>
          <SubLabel>Dialog · constructive</SubLabel>
          <BBDialog
            title="Potvrdi rezervaciju"
            body="Marko Horvat · Vila Marina · 08.07. – 11.07.2026 (3 noći). Gost će biti obaviješten emailom."
            primary={{ label: 'Potvrdi' }}
            secondary={{ label: 'Odustani' }}
          />
        </div>
        <div>
          <SubLabel>Dialog · destructive</SubLabel>
          <BBDialog
            title="Obriši rezervaciju"
            body="Ova akcija je TRAJNA i ne može se poništiti. Plaćanja će biti vraćena prema Stripe pravilima."
            primary={{ label: 'Obriši' }}
            secondary={{ label: 'Odustani' }}
            destructive
          />
        </div>
        <div>
          <SubLabel>Bottom sheet · mobile picker</SubLabel>
          <BBBottomSheet title="Odaberi temu">
            <PickerRow icon="light_mode" label="Svijetla" sub="Uvijek svijetla" />
            <PickerRow icon="dark_mode" label="Tamna" sub="Uvijek tamna" />
            <PickerRow icon="brightness_auto" label="Sustavna" sub="Prati sustavnu temu" selected />
          </BBBottomSheet>
        </div>
      </div>
    </Section>

    {/* DARK MODE STRIP */}
    <Section eyebrow="Themes · 01" title="Dark mode parity">
      <div className="theme-dark" style={{
        background: 'var(--bb-bg)', color: 'var(--bb-text-primary)',
        padding: 32, borderRadius: 'var(--bb-radius-md)',
        border: '1px solid var(--bb-border)',
      }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.4fr', gap: 24, alignItems: 'flex-start' }}>
          {/* Hero card sample */}
          <div style={{
            background: 'var(--bb-gradient-hero)',
            borderRadius: 'var(--bb-radius-xl)',
            padding: 24, color: '#FFFFFF',
            boxShadow: 'var(--bb-shadow-purple)',
            position: 'relative', overflow: 'hidden',
          }}>
            <div style={{
              position: 'absolute', top: -60, right: -50, width: 200, height: 200,
              borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,255,255,0.16) 0%, rgba(255,255,255,0) 70%)',
            }} />
            <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.8)' }}>Zarada · 30 dana</div>
            <div style={{ fontSize: 36, fontWeight: 800, marginTop: 8, letterSpacing: '-0.03em' }} className="bb-tnum">€3.840,00</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 12 }}>
              <span style={{
                background: 'rgba(79,174,127,0.32)', color: '#FFFFFF',
                padding: '4px 8px', borderRadius: 999, fontSize: 12, fontWeight: 600,
                display: 'inline-flex', alignItems: 'center', gap: 4,
              }}>
                <BBIcon name="trending_up" size={14} /> <span className="bb-tnum">+12,4%</span>
              </span>
              <BBSparkline data={SPARK_DATA} width={140} height={36} color="#FFFFFF" fillColor="rgba(255,255,255,0.20)" strokeWidth={2} showDot={false} />
            </div>
          </div>

          {/* Components in dark */}
          <BBCard>
            <SubLabel>Components on dark surface</SubLabel>
            <Row>
              <BBButton variant="primary" iconLeft="add">Nova rezervacija</BBButton>
              <BBButton variant="secondary">Filteri</BBButton>
              <BBButton variant="destructive-soft" iconLeft="close">Odbij</BBButton>
            </Row>
            <Row>
              <BBStatusBadge status="pending" />
              <BBStatusBadge status="confirmed" />
              <BBStatusBadge status="completed" />
              <BBStatusBadge status="cancelled" />
              <BBStatusBadge status="imported" />
            </Row>
            <Row>
              <BBChip selected dotColor="#FFC872" count={3}>Na čekanju</BBChip>
              <BBChip dotColor="#4FAE7F">Potvrđene</BBChip>
              <BBChip dotColor="#8B6FFF">Završene</BBChip>
            </Row>
            <SubLabel>Input</SubLabel>
            <BBInput label="Email" iconLeft="mail" placeholder="ime@primjer.hr" />
          </BBCard>
        </div>
      </div>
    </Section>

    <p className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textAlign: 'center', marginTop: 32 }}>
      All primitives compose only from BB tokens. No hardcoded colors, radii, or shadows in primitives.
    </p>
  </div>
);

// Helpers
const PillTag = ({ children }) => (
  <span style={{
    fontSize: 12, fontWeight: 600,
    color: 'var(--bb-text-secondary)',
    background: 'var(--bb-surface)',
    border: '1px solid var(--bb-border)',
    padding: '5px 12px', borderRadius: 999,
  }}>{children}</span>
);

const Section = ({ eyebrow, title, children }) => (
  <section style={{ marginBottom: 40 }}>
    <div style={{ marginBottom: 16 }}>
      <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)' }}>{eyebrow}</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0', color: 'var(--bb-text-primary)' }}>{title}</h2>
    </div>
    {children}
  </section>
);

const SubSection = ({ title, children }) => (
  <div style={{ marginTop: 16 }}>
    <div className="bb-eyebrow" style={{ color: 'var(--bb-text-tertiary)', marginBottom: 8 }}>{title}</div>
    {children}
  </div>
);

const SubLabel = ({ children, style = {} }) => (
  <div className="bb-eyebrow" style={{
    color: 'var(--bb-text-tertiary)', marginBottom: 12, marginTop: 4, ...style,
  }}>{children}</div>
);

const Row = ({ children }) => (
  <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center', marginBottom: 16 }}>{children}</div>
);

const Swatch = ({ name, value, cssVar, textOnDark = false, bordered = false }) => (
  <div style={{
    height: 100, padding: 16,
    background: `var(${cssVar})`,
    borderRadius: 'var(--bb-radius-md)',
    border: bordered ? '1px solid var(--bb-border)' : 'none',
    color: textOnDark ? '#FFFFFF' : 'var(--bb-text-primary)',
    display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
  }}>
    <div className="bb-label" style={{ fontWeight: 600 }}>{name}</div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      <span className="bb-mono" style={{ opacity: 0.82, fontSize: 12 }}>{value}</span>
      <span className="bb-caption" style={{ opacity: 0.62, fontSize: 11 }}>{cssVar}</span>
    </div>
  </div>
);

const TypeRow = ({ tag, sample, meta, className, last = false }) => (
  <div style={{
    display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 24,
    paddingBottom: last ? 0 : 14, marginBottom: last ? 0 : 14,
    borderBottom: last ? 'none' : '1px solid var(--bb-border-subtle)',
  }}>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className={className} style={{ color: 'var(--bb-text-primary)' }}>{sample}</div>
    </div>
    <div style={{ flexShrink: 0, textAlign: 'right' }}>
      <div className="bb-mono" style={{ color: 'var(--bb-primary)', fontWeight: 600 }}>{tag}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{meta}</div>
    </div>
  </div>
);

const PickerRow = ({ icon, label, sub, selected }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '12px 20px',
  }}>
    <div style={{
      width: 36, height: 36, borderRadius: 10,
      background: selected ? 'var(--bb-primary)' : 'var(--bb-surface-variant)',
      color: selected ? '#FFFFFF' : 'var(--bb-text-secondary)',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <BBIcon name={icon} size={18} />
    </div>
    <div style={{ flex: 1 }}>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{label}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{sub}</div>
    </div>
    {selected && <BBIcon name="check_circle" size={20} style={{ color: 'var(--bb-primary)' }} />}
  </div>
);

Object.assign(window, { FoundationGallery });
