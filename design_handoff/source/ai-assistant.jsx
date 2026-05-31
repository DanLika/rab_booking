/* eslint-disable */
// AI Asistent — Prompt 17.
// Consent state + chat surface (split on desktop, single pane on mobile).

const AI_CONVERSATIONS = [
  { id: 'c1', title: 'Kako blokirati datume za održavanje?', preview: 'Bulk blokada termina je dostupna kroz...', time: 'sad', active: true },
  { id: 'c2', title: 'Postavke widgeta za Apartman A', preview: 'Pošaljite gostima link s parametrima...', time: 'prije 2h' },
  { id: 'c3', title: 'Stripe greška u plaćanju', preview: 'Provjerite chargesEnabled status...', time: 'jučer' },
  { id: 'c4', title: 'Cijene za ljetnu sezonu', preview: 'U Cjenovniku odaberite raspon datuma...', time: 'prije 3d' },
  { id: 'c5', title: 'Sinkronizacija s Booking.com', preview: 'Auto-import provjerava svakih 15 min...', time: 'prije 5d' },
];

const AI_MESSAGES = [
  { id: 1, role: 'user', text: 'Kako blokirati datume za održavanje?', time: '09:14' },
  { id: 2, role: 'assistant', text: 'U Timeline kalendaru kliknite na datum koji želite blokirati i odaberite "Blokiraj termin". Ako želite blokirati raspon, kliknite na prvi datum i povucite do zadnjeg.\n\nBlokirani termini se odmah šalju na sve povezane platforme (Booking.com, Airbnb) — bez čekanja sinkronizacije.', time: '09:14' },
  { id: 3, role: 'user', text: 'A mogu li to napraviti za više jedinica odjednom?', time: '09:16' },
  { id: 4, role: 'assistant', text: 'Da. Otvorite **Timeline** → ⋯ menu → **"Bulk blokada termina"**. Tamo možete:\n\n• odabrati više jedinica iz tree-a\n• odabrati raspon datuma\n• opcionalno upisati razlog (npr. „Renovacija kupaonice")\n\nRazlog se NE dijeli s gostima — koristi se interno.', time: '09:16' },
];

const AI_SUGGESTIONS = [
  'Kako dodati apartman?',
  'Sinkronizacija s Booking.com?',
  'Postavke Stripe povrata',
  'Kako promijeniti cijenu za vikend?',
];

const CONSENT_BULLETS = [
  { icon: 'shield', title: 'Privatnost je zajamčena', body: 'Razgovori se ne dijele s drugim vlasnicima i ne koriste za treniranje modela.' },
  { icon: 'data_object', title: 'Pristupa samo vašim podacima', body: 'AI vidi vaše rezervacije, jedinice i postavke — ništa drugih korisnika.' },
  { icon: 'history', title: 'Povijest se može obrisati', body: 'Bilo koji razgovor možete obrisati u jednom kliku, trajno.' },
  { icon: 'gavel', title: 'Pravna izjava', body: 'AI odgovori su orijentacijski — uvijek provjerite kritične postavke prije primjene.' },
];

// ──────────────────────────────────────────────────────────────
// Conversation list
// ──────────────────────────────────────────────────────────────
const ConversationList = ({ conversations, compact = false }) => (
  <div style={{ display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0 }}>
    <div style={{
      padding: compact ? '12px 14px' : '16px 20px',
      borderBottom: '1px solid var(--bb-border-subtle)',
    }}>
      <BBButton variant="primary" iconLeft="add" fullWidth>Novi razgovor</BBButton>
    </div>
    <div style={{
      padding: compact ? '10px 10px' : '12px 12px',
      flex: 1, overflow: 'hidden',
      display: 'flex', flexDirection: 'column', gap: 4,
    }}>
      <div className="bb-eyebrow" style={{
        color: 'var(--bb-text-tertiary)',
        padding: '6px 10px', marginBottom: 4,
      }}>Razgovori · {conversations.length}</div>
      {conversations.map(c => (
        <button key={c.id} type="button" style={{
          width: '100%', border: 'none', cursor: 'pointer',
          background: c.active ? 'var(--bb-primary-tint-bg)' : 'transparent',
          borderRadius: 'var(--bb-radius-sm)',
          padding: '10px 12px',
          display: 'flex', flexDirection: 'column', gap: 4,
          textAlign: 'left',
          borderLeft: c.active ? '3px solid var(--bb-primary)' : '3px solid transparent',
          paddingLeft: c.active ? 9 : 12,
        }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{
              flex: 1,
              fontSize: 13, fontWeight: c.active ? 600 : 500,
              color: c.active ? 'var(--bb-primary)' : 'var(--bb-text-primary)',
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
            }}>{c.title}</span>
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }}>{c.time}</span>
          </div>
          <span className="bb-caption" style={{
            color: 'var(--bb-text-tertiary)',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{c.preview}</span>
        </button>
      ))}
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Chat surface
// ──────────────────────────────────────────────────────────────
const ChatSurface = ({ messages, suggestions, showSuggestions, size = 'desktop' }) => {
  const isCompact = size !== 'desktop';
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0,
      background: 'var(--bb-bg)',
    }}>
      {/* Conversation header */}
      <div style={{
        padding: isCompact ? '12px 16px' : '14px 24px',
        background: 'var(--bb-surface)',
        borderBottom: '1px solid var(--bb-border-subtle)',
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10,
          background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          padding: 4,
        }}>
          <img src="assets/assistant.png" alt="" width={28} height={28} style={{ objectFit: 'contain' }} />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>
            Kako blokirati datume za održavanje?
          </div>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--bb-success)', display: 'inline-block', marginRight: 6, verticalAlign: 'middle' }} />
            BookBed AI · trenutno aktivan
          </div>
        </div>
        <BBButton variant="tertiary" asIcon size="sm" iconLeft="content_copy" ariaLabel="Kopiraj poveznicu" />
        <BBButton variant="tertiary" asIcon size="sm" iconLeft="delete" ariaLabel="Obriši razgovor" />
      </div>

      {/* Messages */}
      <div style={{
        flex: 1, padding: isCompact ? '16px 16px' : '24px 32px',
        display: 'flex', flexDirection: 'column', gap: 14,
        overflow: 'hidden',
      }}>
        {messages.map(m => <MessageBubble key={m.id} message={m} compact={isCompact} />)}
      </div>

      {/* Suggestions + input */}
      <div style={{
        background: 'var(--bb-surface)',
        borderTop: '1px solid var(--bb-border-subtle)',
        padding: isCompact ? '12px 16px 14px' : '16px 32px 20px',
      }}>
        {showSuggestions && (
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 10 }}>
            <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', alignSelf: 'center', marginRight: 4 }}>Predloženo:</span>
            {suggestions.map((s, i) => (
              <BBChip key={i} size="sm" iconLeft="auto_awesome">{s}</BBChip>
            ))}
          </div>
        )}
        <div style={{
          display: 'flex', alignItems: 'flex-end', gap: 8,
          padding: 4,
          background: 'var(--bb-surface)',
          border: '1px solid var(--bb-border)',
          borderRadius: 'var(--bb-radius-md)',
        }}>
          <textarea
            placeholder="Pitajte BookBed AI — npr. 'Kako odobriti rezervaciju emailom?'"
            rows={isCompact ? 1 : 2}
            style={{
              flex: 1, border: 'none', outline: 'none', resize: 'none',
              padding: '10px 12px',
              fontFamily: 'var(--bb-font-sans)', fontSize: 14,
              color: 'var(--bb-text-primary)', background: 'transparent',
            }}
          />
          <BBButton variant="tertiary" asIcon size="md" iconLeft="attach_file" ariaLabel="Priloži datoteku" />
          <BBButton variant="primary" asIcon size="md" iconLeft="send" ariaLabel="Pošalji" />
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textAlign: 'center', marginTop: 8 }}>
          AI odgovori su orijentacijski — uvijek provjerite kritične postavke prije primjene.
        </div>
      </div>
    </div>
  );
};

const MessageBubble = ({ message, compact }) => {
  const isUser = message.role === 'user';
  return (
    <div style={{
      display: 'flex', flexDirection: isUser ? 'row-reverse' : 'row',
      gap: 10, alignItems: 'flex-start',
    }}>
      {!isUser ? (
        <div style={{
          width: 32, height: 32, borderRadius: 10, flexShrink: 0,
          background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          padding: 3,
        }}>
          <img src="assets/assistant.png" alt="" width={24} height={24} style={{ objectFit: 'contain' }} />
        </div>
      ) : (
        <BBAvatar name="Ivana Marić" size="sm" />
      )}
      <div style={{
        maxWidth: compact ? '78%' : '70%',
        padding: '12px 14px',
        background: isUser ? 'var(--bb-primary)' : 'var(--bb-surface)',
        color: isUser ? '#FFFFFF' : 'var(--bb-text-primary)',
        border: isUser ? 'none' : '1px solid var(--bb-border-subtle)',
        borderRadius: 'var(--bb-radius-md)',
        borderTopLeftRadius: !isUser ? 6 : 'var(--bb-radius-md)',
        borderTopRightRadius: isUser ? 6 : 'var(--bb-radius-md)',
        boxShadow: 'var(--bb-shadow-sm)',
      }}>
        <div style={{ fontSize: 14, lineHeight: 1.55, whiteSpace: 'pre-line' }}>{renderMd(message.text)}</div>
        <div style={{
          fontSize: 11, marginTop: 6,
          color: isUser ? 'rgba(255,255,255,0.7)' : 'var(--bb-text-tertiary)',
          textAlign: isUser ? 'right' : 'left',
        }}>{message.time}</div>
      </div>
    </div>
  );
};

// Minimal markdown: **bold** + bullets (•)
function renderMd(text) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return parts.map((p, i) => {
    if (p.startsWith('**') && p.endsWith('**')) {
      return <strong key={i} style={{ fontWeight: 700 }}>{p.slice(2, -2)}</strong>;
    }
    return <span key={i}>{p}</span>;
  });
}

// ──────────────────────────────────────────────────────────────
// Consent / onboarding state
// ──────────────────────────────────────────────────────────────
const ConsentScreen = ({ compact = false }) => (
  <div style={{
    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
    padding: compact ? 24 : 48, minHeight: '100%',
    background: 'var(--bb-bg)',
  }}>
    <div style={{ position: 'relative', marginBottom: 24 }}>
      <div style={{
        position: 'absolute', inset: -28,
        background: 'radial-gradient(circle, rgba(107,76,230,0.32) 0%, rgba(107,76,230,0) 70%)',
        borderRadius: '50%', pointerEvents: 'none',
      }} />
      <img src="assets/assistant.png" alt="BookBed AI" width={compact ? 120 : 168} height={compact ? 120 : 168} style={{ position: 'relative', display: 'block' }} />
    </div>
    <div className="bb-eyebrow" style={{ color: 'var(--bb-primary)' }}>BookBed AI</div>
    <h2 className="bb-h1" style={{ margin: '6px 0 8px', color: 'var(--bb-text-primary)', textAlign: 'center' }}>
      Vaš pomoćnik za sve oko BookBed-a
    </h2>
    <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)', textAlign: 'center', maxWidth: 540 }}>
      Pitajte AI o rezervacijama, cijenama, integracijama ili bilo čemu vezanom uz aplikaciju.
      Prije nego započnete, pročitajte ovo:
    </p>

    <div style={{
      display: 'grid',
      gridTemplateColumns: compact ? '1fr' : 'repeat(2, 1fr)',
      gap: 12, marginTop: 24, marginBottom: 24, width: '100%', maxWidth: 720,
    }}>
      {CONSENT_BULLETS.map((b, i) => (
        <BBCard key={i} style={{ padding: 16 }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10, flexShrink: 0,
              background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <BBIcon name={b.icon} size={20} />
            </div>
            <div>
              <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{b.title}</div>
              <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', marginTop: 2 }}>{b.body}</div>
            </div>
          </div>
        </BBCard>
      ))}
    </div>

    <div style={{ display: 'flex', gap: 8 }}>
      <BBButton variant="secondary">Saznaj više</BBButton>
      <BBButton variant="primary" iconRight="arrow_forward">Razumijem, započni</BBButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Pages
// ──────────────────────────────────────────────────────────────
const AIChatDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 1440, height: 1100, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebar user={SAMPLE_USER} active="ai-asistent" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Početna', 'AI Asistent']} notifCount={3} actions={[
        { icon: 'history', label: 'Povijest' },
        { icon: 'help', label: 'Kako koristiti AI' },
      ]} />
      <div style={{ flex: 1, display: 'flex', minWidth: 0 }}>
        {/* Conversation list */}
        <aside style={{
          width: 300, flexShrink: 0,
          background: 'var(--bb-surface)',
          borderRight: '1px solid var(--bb-border-subtle)',
          display: 'flex', flexDirection: 'column', minHeight: 0,
        }}>
          <ConversationList conversations={AI_CONVERSATIONS} />
        </aside>
        {/* Chat */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <ChatSurface messages={AI_MESSAGES} suggestions={AI_SUGGESTIONS} showSuggestions size="desktop" />
        </div>
      </div>
    </div>
  </div>
);

const AIConsentDesktop = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 1440, height: 1100, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebar user={SAMPLE_USER} active="ai-asistent" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Početna', 'AI Asistent']} notifCount={3} />
      <main style={{ flex: 1, overflow: 'hidden' }}>
        <ConsentScreen />
      </main>
    </div>
  </div>
);

const AIChatTablet = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 768, height: 1024, display: 'flex',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBSidebarRail active="ai-asistent" pendingCount={1} notifCount={3} />
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
      <BBAppBar breadcrumb={['Početna', 'AI Asistent']} notifCount={3} actions={[
        { icon: 'menu_open', label: 'Razgovori' },
        { icon: 'add', label: 'Novi razgovor' },
      ]} />
      <ChatSurface messages={AI_MESSAGES} suggestions={AI_SUGGESTIONS.slice(0, 3)} showSuggestions size="tablet" />
    </div>
  </div>
);

const AIChatMobile = () => (
  <div className="theme-light bb-screen bb-shell" style={{
    width: 390, height: 880, display: 'flex', flexDirection: 'column',
    background: 'var(--bb-bg)', fontFamily: 'var(--bb-font-sans)',
  }}>
    <BBAppBar title="AI Asistent" showHamburger notifCount={3} actions={[
      { icon: 'add', label: 'Novi' },
    ]} />
    <ChatSurface messages={AI_MESSAGES} suggestions={AI_SUGGESTIONS.slice(0, 2)} showSuggestions size="mobile" />
  </div>
);

Object.assign(window, {
  AIChatDesktop,
  AIConsentDesktop,
  AIChatTablet,
  AIChatMobile,
});
