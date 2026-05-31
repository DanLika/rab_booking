/* eslint-disable */
// FAQ / Help — Prompt 16. Top-level nav screen (sidebar item "faq").
// Searchable help center: search + category chips + interactive accordion + contact card.
// Owner scaffold (sidebar/rail/app-bar, active=faq), centered column.

const FAQ_CATS = [
  { id: 'sve', label: 'Sve', icon: 'apps' },
  { id: 'rezervacije', label: 'Rezervacije', icon: 'receipt_long' },
  { id: 'placanja', label: 'Plaćanja', icon: 'payments' },
  { id: 'widget', label: 'Widget', icon: 'code' },
  { id: 'sync', label: 'Sinkronizacija', icon: 'sync' },
  { id: 'racun', label: 'Račun', icon: 'person' },
];
const FAQ_CAT_ICON = { rezervacije: 'receipt_long', placanja: 'payments', widget: 'code', sync: 'sync', racun: 'person' };

const FAQ_DATA = [
  { id: 'q1', cat: 'rezervacije', q: 'Kako odobravam ili odbijam rezervacije?', a: 'Nove rezervacije stižu sa statusom „Na čekanju”. Otvorite Rezervacije ili karticu na Pregledu i odaberite Odobri ili Odbij. Gost automatski dobiva obavijest e-poštom o vašoj odluci.' },
  { id: 'q2', cat: 'rezervacije', q: 'Što se događa kad gost otkaže rezervaciju?', a: 'Termin se odmah oslobađa u kalendaru, a status mijenja u „Otkazano”. Povrat pologa ovisi o vašim pravilima otkazivanja koja postavljate po jedinici.' },
  { id: 'q3', cat: 'placanja', q: 'Kada i kako primam isplate?', a: 'Polozi se isplaćuju na vaš povezani bankovni račun putem Stripe-a, obično 2–3 radna dana nakon dolaska gosta. Preostali iznos naplaćujete gostu izravno na licu mjesta.' },
  { id: 'q4', cat: 'placanja', q: 'Kolika je naknada po rezervaciji?', a: 'Na Besplatnom planu naplaćujemo malu naknadu po potvrđenoj rezervaciji. Na Pro planu nema naknade po rezervaciji — plaćate samo fiksnu mjesečnu pretplatu.' },
  { id: 'q5', cat: 'widget', q: 'Kako postavljam widget na svoju web stranicu?', a: 'U Integracije → Widget kopirajte isječak koda i zalijepite ga u HTML svoje stranice. Widget se automatski prilagođava i radi na bilo kojoj platformi (WordPress, Wix, vlastiti sustav).' },
  { id: 'q6', cat: 'widget', q: 'Mogu li prilagoditi izgled widgeta?', a: 'Da. Možete podesiti naglašnu boju, jezik i zaobljenost rubova kako bi se uklopio u vašu stranicu. Na Pro planu uklanja se i oznaka „Powered by BookBed”.' },
  { id: 'q7', cat: 'sync', q: 'Kako povezujem Booking.com i Airbnb kalendare?', a: 'U Integracije → iCal zalijepite iCal poveznicu s druge platforme. Rezervacije s tih kanala automatski se uvoze i prikazuju kao „Uvezeno”, sprječavajući dvostruke rezervacije.' },
  { id: 'q8', cat: 'sync', q: 'Zašto se neke rezervacije ne sinkroniziraju?', a: 'Sinkronizacija ovisi o intervalu osvježavanja vanjske platforme (često 2–4 sata). Ako vidite grešku uz feed, provjerite je li iCal poveznica ispravna i aktivna.' },
  { id: 'q9', cat: 'racun', q: 'Kako mijenjam lozinku ili e-poštu?', a: 'Otvorite Profil → Račun. Tamo možete urediti kontakt podatke te promijeniti lozinku. Promjena e-pošte zahtijeva potvrdu putem nove adrese.' },
  { id: 'q10', cat: 'racun', q: 'Kako otkazujem pretplatu?', a: 'U Profil → Pretplata odaberite Otkaži pretplatu. Zadržavate Pro značajke do kraja plaćenog razdoblja, nakon čega se račun vraća na Besplatni plan.' },
];

// ──────────────────────────────────────────────────────────────
// Accordion item
// ──────────────────────────────────────────────────────────────
const FaqItem = ({ item, open, onToggle, divider }) => (
  <div style={{ borderBottom: divider ? '1px solid var(--bb-border-subtle)' : 'none' }}>
    <button type="button" onClick={onToggle} style={{
      width: '100%', border: 'none', background: 'transparent', cursor: 'pointer',
      padding: '13px 20px', display: 'flex', alignItems: 'center', gap: 14, textAlign: 'left',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, flexShrink: 0,
        background: open ? 'var(--bb-primary)' : 'var(--bb-primary-tint-bg)',
        color: open ? '#FFFFFF' : 'var(--bb-primary)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        transition: 'background 140ms ease-out',
      }}>
        <BBIcon name={FAQ_CAT_ICON[item.cat] || 'help'} size={18} fill={open ? 1 : 0} />
      </div>
      <span className="bb-body" style={{ flex: 1, color: 'var(--bb-text-primary)', fontWeight: 600, fontSize: 15 }}>{item.q}</span>
      <BBIcon name="expand_more" size={22} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0, transform: open ? 'rotate(180deg)' : 'none', transition: 'transform 200ms ease-out' }} />
    </button>
    {open && (
      <div style={{ padding: '0 20px 14px 66px' }}>
        <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)', lineHeight: 1.6 }}>{item.a}</p>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 14 }}>
          <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>Je li ovo bilo korisno?</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button type="button" aria-label="Korisno" style={faqVoteBtn()}><BBIcon name="thumb_up" size={15} fill={0} /></button>
            <button type="button" aria-label="Nije korisno" style={faqVoteBtn()}><BBIcon name="thumb_down" size={15} fill={0} /></button>
          </div>
        </div>
      </div>
    )}
  </div>
);
function faqVoteBtn() {
  return {
    width: 30, height: 30, borderRadius: 8, cursor: 'pointer',
    border: '1px solid var(--bb-border)', background: 'var(--bb-surface)', color: 'var(--bb-text-tertiary)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
  };
}

// ──────────────────────────────────────────────────────────────
// Contact support card
// ──────────────────────────────────────────────────────────────
const FaqContact = ({ compact = false }) => (
  <div style={{
    marginTop: compact ? 16 : 24,
    display: 'flex', alignItems: 'center', gap: 16,
    padding: compact ? '14px 16px' : '18px 24px',
    background: 'var(--bb-primary-tint-bg)',
    border: '1px solid rgba(107,76,230,0.18)',
    borderRadius: 'var(--bb-radius-md)',
  }}>
    <div style={{ width: 48, height: 48, borderRadius: 14, background: 'var(--bb-surface)', color: 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: 'var(--bb-shadow-sm)' }}>
      <BBIcon name="support_agent" size={26} />
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div className="bb-h3" style={{ color: 'var(--bb-text-primary)', margin: 0 }}>Niste pronašli odgovor?</div>
      <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-secondary)' }}>Naš tim podrške odgovara na hrvatskom, obično unutar nekoliko sati.</p>
    </div>
    <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
      <BBButton variant="secondary" iconLeft="mail" size={compact ? 'sm' : 'md'}>E-pošta</BBButton>
      <BBButton variant="primary" iconLeft="chat" size={compact ? 'sm' : 'md'}>Razgovor uživo</BBButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Body (search + chips + accordion)
// ──────────────────────────────────────────────────────────────
const FaqBody = ({ breakpoint }) => {
  const compact = breakpoint !== 'desktop';
  const mobile = breakpoint === 'mobile';
  const [cat, setCat] = React.useState('sve');
  const [openId, setOpenId] = React.useState('q1');
  let list = cat === 'sve' ? FAQ_DATA : FAQ_DATA.filter(f => f.cat === cat);
  const limit = mobile ? 5 : (breakpoint === 'tablet' ? 6 : 8);
  list = list.slice(0, limit);

  return (
    <div>
      <div style={{ marginBottom: compact ? 14 : 20 }}>
        <h1 className={compact ? 'bb-h1' : 'bb-display'} style={{ margin: 0, color: 'var(--bb-text-primary)', fontSize: compact ? 24 : 32 }}>Često postavljana pitanja</h1>
        {!mobile && <p className="bb-body" style={{ margin: '6px 0 0', color: 'var(--bb-text-tertiary)' }}>Brzi odgovori o rezervacijama, plaćanjima i postavljanju.</p>}
      </div>

      {/* Search */}
      <div style={{ marginBottom: 14 }}>
        <BBInput placeholder="Pretražite pitanja…" iconLeft="search" size={compact ? 'md' : 'lg'} />
      </div>

      {/* Category chips */}
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: compact ? 14 : 18 }}>
        {FAQ_CATS.map(c => (
          <BBChip key={c.id} iconLeft={c.icon} selected={cat === c.id} size={compact ? 'sm' : 'md'} onClick={() => setCat(c.id)}>{c.label}</BBChip>
        ))}
      </div>

      {/* Accordion */}
      <BBCard padded={false}>
        {list.map((item, i) => (
          <FaqItem
            key={item.id}
            item={item}
            open={openId === item.id}
            onToggle={() => setOpenId(openId === item.id ? null : item.id)}
            divider={i < list.length - 1}
          />
        ))}
      </BBCard>

      {!mobile && <FaqContact compact={compact} />}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// Scaffold + pages
// ──────────────────────────────────────────────────────────────
const FaqDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 1440, height: 1100, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebar user={SAMPLE_USER} active="faq" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Pomoć', 'FAQ']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }, { icon: 'light_mode', label: 'Tema' }]} />
      <main style={{ padding: '24px 32px 32px', flex: 1, overflow: 'hidden', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 800, maxWidth: '100%' }}>
          <FaqBody breakpoint="desktop" />
        </div>
      </main>
    </div>
  </div>
);

const FaqTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 768, height: 1024, display: 'flex', background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)' }}>
    <BBSidebarRail active="faq" pendingCount={1} notifCount={6} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Pomoć', 'FAQ']} notifCount={6} actions={[{ icon: 'search', label: 'Pretraži' }]} />
      <main style={{ padding: '20px 24px 24px', flex: 1, overflow: 'hidden' }}>
        <div style={{ maxWidth: 620, margin: '0 auto' }}>
          <FaqBody breakpoint="tablet" />
        </div>
      </main>
    </div>
  </div>
);

const FaqMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{ width: 390, height: 880, background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)', display: 'flex', flexDirection: 'column' }}>
    <BBAppBar title="FAQ" showHamburger notifCount={6} actions={[{ icon: 'support_agent', label: 'Podrška' }]} />
    <main style={{ flex: 1, padding: '14px 16px 0', overflow: 'hidden' }}>
      <FaqBody breakpoint="mobile" />
    </main>
  </div>
);

Object.assign(window, { FaqDesktop, FaqTablet, FaqMobile });
