/* eslint-disable */
// Admin Support — staff helpdesk console. Fills the admin nav "Support" gap.
// Reuses AdminScaffold (active="support") + BB primitives. Chrome is English (staff tool);
// the owner↔agent ticket thread is Croatian (real conversation with an HR owner).
// Fixed scaffold heights — content sized to fit (overflow:hidden). Desktop = master-detail
// (ticket queue + conversation). Tablet/mobile = ticket cards.

const SUP_STATS = [
  { icon: 'inbox',               label: 'Open tickets',   value: '37', delta: '+5',  tone: 'neutral', sub: '8 unassigned', color: 'var(--bb-primary)' },
  { icon: 'mark_email_unread',   label: 'Awaiting reply', value: '12', tone: 'neutral', sub: 'owner waiting', color: 'var(--bb-info)' },
  { icon: 'timer',               label: 'Breaching SLA',  value: '3',  delta: '+1',  tone: 'error',   sub: '< 30 min left', color: 'var(--bb-error)' },
  { icon: 'task_alt',            label: 'Resolved today', value: '28', delta: '+4',  tone: 'success', sub: 'avg 3h 12m', color: 'var(--bb-success)' },
];

const SUP_PRIORITY = {
  urgent: { label: 'Urgent', color: '#FF6B6B' },
  high:   { label: 'High',   color: '#FFB84D' },
  normal: { label: 'Normal', color: '#4A90D9' },
  low:    { label: 'Low',    color: '#718096' },
};
const SUP_TICKET_STATUS = {
  open:     { label: 'Open',     fg: 'var(--bb-info)',          bg: 'var(--bb-info-tint)' },
  pending:  { label: 'Pending',  fg: 'var(--bb-tertiary-dark)', bg: 'var(--bb-tertiary-tint)' },
  resolved: { label: 'Resolved', fg: 'var(--bb-success)',       bg: 'var(--bb-success-tint)' },
};

const SUP_TICKETS = [
  { id: 'TK-3041', owner: 'Davor Kralj',    subject: 'Payout not received for May',      preview: 'Bok, nije mi sjela isplata za svibanj…', cat: 'Payments',   priority: 'high',   status: 'open',     time: '2h',  sla: '1h 12m', unread: true },
  { id: 'TK-3040', owner: 'Lana Babić',     subject: 'iCal feed not syncing with Airbnb', preview: 'Kalendar pokazuje dvostruke rezervacije…', cat: 'Sync',      priority: 'urgent', status: 'open',     time: '38m', sla: '22m',   unread: true },
  { id: 'TK-3039', owner: 'Maja Novak',     subject: 'How do I add a second property?',  preview: 'Nadogradila sam na Pro ali ne mogu…',    cat: 'Onboarding', priority: 'normal', status: 'pending',  time: '4h',  sla: '5h' },
  { id: 'TK-3038', owner: 'Goran Šimić',    subject: 'Refund request for cancellation',  preview: 'Gost je otkazao unutar 24h…',            cat: 'Payments',   priority: 'high',   status: 'open',     time: '5h',  sla: '3h' },
  { id: 'TK-3037', owner: 'Ante Jurić',     subject: 'Widget not loading on my site',    preview: 'Booking widget prikazuje praznu…',       cat: 'Widget',     priority: 'normal', status: 'pending',  time: '6h',  sla: '8h' },
  { id: 'TK-3036', owner: 'Tomislav Perić', subject: 'Change billing email',             preview: 'Molim promijenite e-mail za račune…',    cat: 'Account',    priority: 'low',    status: 'open',     time: '8h',  sla: '1d' },
  { id: 'TK-3035', owner: 'Petra Vuković',  subject: 'Suspended account — why?',         preview: 'Račun mi je suspendiran bez…',           cat: 'Account',    priority: 'urgent', status: 'open',     time: '1d',  sla: 'breached' },
  { id: 'TK-3034', owner: 'Ivana Marić',    subject: 'Thank you!',                       preview: 'Sve sada radi savršeno…',                cat: 'General',    priority: 'low',    status: 'resolved', time: '1d',  sla: '—' },
];

const SUP_THREAD = [
  { from: 'owner', name: 'Davor Kralj', time: '2h ago', text: 'Bok, nije mi sjela isplata za svibanj (€48,20). Trebala je stići do 30.05. Možete provjeriti što se događa?' },
  { from: 'agent', name: 'Petra K.', time: '1h 48m ago', text: 'Pozdrav Davore, hvala na javljanju. Provjeravam status isplate kod Stripea — vraćam se za par minuta.' },
  { from: 'note', name: 'Petra K.', time: '1h 40m ago', text: 'Stripe shows payout in transit — ETA 02 Jun. SEPA delay on the owner\'s bank side, not our issue.' },
  { from: 'agent', name: 'Petra K.', time: '1h 39m ago', text: 'Isplata je u obradi i trebala bi sjesti do 02.06. Radi se o kašnjenju SEPA naloga kod banke. Javite ako ne stigne do tada.' },
  { from: 'owner', name: 'Davor Kralj', time: '1h 30m ago', text: 'Super, hvala na brzom odgovoru!' },
];

const SUP_TABS = [
  { id: 'all', label: 'All open', count: 37 },
  { id: 'mine', label: 'Assigned to me', count: 9 },
  { id: 'unassigned', label: 'Unassigned', count: 8 },
  { id: 'urgent', label: 'Urgent', dot: '#FF6B6B', count: 3 },
];

// ── shared bits ──
const SUPStat = ({ s, compact = false }) => {
  const dc = s.tone === 'success' ? 'var(--bb-success)' : s.tone === 'error' ? 'var(--bb-error)' : 'var(--bb-text-tertiary)';
  const db = s.tone === 'success' ? 'var(--bb-success-tint)' : s.tone === 'error' ? 'var(--bb-error-tint)' : 'var(--bb-surface-variant)';
  return (
    <BBCard style={compact ? { padding: 14 } : {}}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ width: 34, height: 34, borderRadius: 10, background: `color-mix(in srgb, ${s.color || 'var(--bb-primary)'} 14%, transparent)`, color: s.color || 'var(--bb-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
          <BBIcon name={s.icon} size={18} />
        </div>
        {s.delta && <span className="bb-tnum" style={{ fontSize: 12, fontWeight: 700, color: dc, background: db, padding: '3px 8px', borderRadius: 6 }}>{s.delta}</span>}
      </div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10, fontWeight: 700 }}>{s.label}</div>
      <div className="bb-tnum" style={{ fontSize: compact ? 22 : 26, fontWeight: 800, color: 'var(--bb-text-primary)', letterSpacing: '-0.02em', marginTop: 2 }}>{s.value}</div>
      <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', marginTop: 2 }}>{s.sub}</div>
    </BBCard>
  );
};

const SUPSla = ({ sla, size = 'sm' }) => {
  const breached = sla === 'breached';
  if (sla === '—') return <span className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>—</span>;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, height: 20, padding: '0 8px', borderRadius: 999, background: breached ? 'var(--bb-error-tint)' : 'var(--bb-tertiary-tint)', color: breached ? 'var(--bb-error)' : 'var(--bb-tertiary-dark)', fontSize: 11, fontWeight: 700 }}>
      <BBIcon name={breached ? 'timer_off' : 'timer'} size={12} />
      <span className="bb-tnum">{breached ? 'SLA breached' : sla}</span>
    </span>
  );
};

const SUPCatTag = ({ cat }) => (
  <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--bb-text-secondary)', background: 'var(--bb-surface-variant)', padding: '2px 8px', borderRadius: 6 }}>{cat}</span>
);

// ── ticket list row ──
const SUPTicketRow = ({ t, selected, onClick, divider }) => {
  const pr = SUP_PRIORITY[t.priority];
  return (
    <button type="button" onClick={onClick} className="bb-row-hover" style={{
      width: '100%', border: 'none', cursor: 'pointer', textAlign: 'left',
      display: 'flex', gap: 12, padding: '12px 16px',
      borderBottom: divider ? '1px solid var(--bb-border-subtle)' : 'none',
      background: selected ? 'var(--bb-primary-tint-bg)' : 'transparent',
      borderLeft: `3px solid ${selected ? 'var(--bb-primary)' : 'transparent'}`,
    }}>
      <div style={{ position: 'relative', flexShrink: 0 }}>
        <BBAvatar name={t.owner} size="sm" />
        {t.unread && <span style={{ position: 'absolute', top: -1, right: -1, width: 9, height: 9, borderRadius: '50%', background: 'var(--bb-primary)', border: '2px solid var(--bb-surface)' }} />}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <span className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: t.unread ? 700 : 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{t.subject}</span>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }}>{t.time}</span>
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', margin: '2px 0 7px' }}>{t.owner} · {t.preview}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}>
            <span style={{ width: 7, height: 7, borderRadius: '50%', background: pr.color }} />
            <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{pr.label}</span>
          </span>
          <SUPCatTag cat={t.cat} />
          <div style={{ flex: 1 }} />
          <SUPSla sla={t.sla} />
        </div>
      </div>
    </button>
  );
};

const SUPQueue = ({ selectedId, fillHeight = false }) => (
  <BBCard padded={false} style={{ overflow: 'hidden', display: 'flex', flexDirection: 'column', height: fillHeight ? '100%' : 'auto' }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px 16px', borderBottom: '1px solid var(--bb-border-subtle)' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Inbox</h3>
      <span className="bb-tnum" style={{ fontSize: 12, fontWeight: 700, color: 'var(--bb-primary)', background: 'var(--bb-primary-tint-bg)', padding: '2px 8px', borderRadius: 999 }}>37</span>
      <div style={{ flex: 1 }} />
      <BBButton variant="tertiary" asIcon size="sm" iconLeft="filter_list" ariaLabel="Filter" />
      <BBButton variant="tertiary" asIcon size="sm" iconLeft="swap_vert" ariaLabel="Sort" />
    </div>
    <div style={{ flex: 1, minHeight: 0 }}>
      {SUP_TICKETS.map((t, i) => (
        <SUPTicketRow key={t.id} t={t} selected={t.id === selectedId} divider={i < SUP_TICKETS.length - 1} />
      ))}
    </div>
  </BBCard>
);

// ── conversation detail ──
const SUPBubble = ({ m }) => {
  if (m.from === 'note') {
    return (
      <div style={{ background: 'var(--bb-tertiary-tint)', border: '1px solid rgba(255,184,77,0.35)', borderRadius: 'var(--bb-radius-sm)', padding: '12px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
          <BBIcon name="lock" size={13} style={{ color: 'var(--bb-tertiary-dark)' }} />
          <span className="bb-caption" style={{ color: 'var(--bb-tertiary-dark)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 10 }}>Internal note · {m.name}</span>
          <div style={{ flex: 1 }} />
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{m.time}</span>
        </div>
        <div className="bb-body" style={{ color: 'var(--bb-text-primary)' }}>{m.text}</div>
      </div>
    );
  }
  const agent = m.from === 'agent';
  return (
    <div style={{ display: 'flex', flexDirection: agent ? 'row-reverse' : 'row', gap: 10, alignItems: 'flex-end' }}>
      <BBAvatar name={m.name} size="xs" tone={agent ? 'primary' : 'neutral'} />
      <div style={{ maxWidth: '74%' }}>
        <div style={{ display: 'flex', gap: 8, marginBottom: 4, justifyContent: agent ? 'flex-end' : 'flex-start' }}>
          <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{agent ? `${m.name} · Support` : m.name}</span>
          <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{m.time}</span>
        </div>
        <div className="bb-body" style={{
          color: agent ? '#FFFFFF' : 'var(--bb-text-primary)',
          background: agent ? 'var(--bb-primary)' : 'var(--bb-surface-variant)',
          padding: '10px 14px', borderRadius: 14,
          borderBottomRightRadius: agent ? 4 : 14, borderBottomLeftRadius: agent ? 14 : 4,
        }}>{m.text}</div>
      </div>
    </div>
  );
};

const SUPMetaItem = ({ label, value, color }) => (
  <div style={{ minWidth: 0 }}>
    <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 9, fontWeight: 700 }}>{label}</div>
    <div className="bb-label" style={{ color: color || 'var(--bb-text-primary)', fontWeight: 600, marginTop: 1, whiteSpace: 'nowrap' }}>{value}</div>
  </div>
);

const SUPConversation = ({ t }) => {
  const st = SUP_TICKET_STATUS[t.status];
  return (
    <BBCard padded={false} style={{ overflow: 'hidden', display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* header */}
      <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <h2 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.subject}</h2>
              <span className="bb-mono" style={{ fontSize: 12, color: 'var(--bb-text-tertiary)', flexShrink: 0 }}>#{t.id}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
              <BBAvatar name={t.owner} size="xs" />
              <span className="bb-label" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{t.owner}</span>
              <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--bb-primary)', background: 'var(--bb-primary-tint-bg)', padding: '2px 8px', borderRadius: 999 }}>Pro</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
            <BBButton variant="secondary" size="sm" iconLeft="person_add">Assign</BBButton>
            <BBButton variant="success" size="sm" iconLeft="check">Resolve</BBButton>
            <BBButton variant="tertiary" asIcon size="sm" iconLeft="more_vert" ariaLabel="More" />
          </div>
        </div>
      </div>
      {/* meta strip */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 28, padding: '12px 20px', background: 'var(--bb-surface-variant)', borderBottom: '1px solid var(--bb-border-subtle)' }}>
        <SUPMetaItem label="Status" value={st.label} color={st.fg} />
        <SUPMetaItem label="Priority" value={SUP_PRIORITY[t.priority].label} color={SUP_PRIORITY[t.priority].color} />
        <SUPMetaItem label="Category" value={t.cat} />
        <SUPMetaItem label="Assignee" value="Petra K." />
        <div style={{ flex: 1 }} />
        <div style={{ textAlign: 'right' }}>
          <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.04em', fontSize: 9, fontWeight: 700, marginBottom: 3 }}>First response SLA</div>
          <SUPSla sla={t.sla} />
        </div>
      </div>
      {/* thread */}
      <div style={{ flex: 1, minHeight: 0, padding: 20, display: 'flex', flexDirection: 'column', gap: 16 }}>
        {SUP_THREAD.map((m, i) => <SUPBubble key={i} m={m} />)}
      </div>
      {/* composer */}
      <div style={{ borderTop: '1px solid var(--bb-border-subtle)', padding: 14 }}>
        <div style={{ display: 'flex', gap: 6, marginBottom: 10 }}>
          <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-primary)', borderBottom: '2px solid var(--bb-primary)', padding: '4px 6px' }}>Reply</span>
          <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--bb-text-tertiary)', padding: '4px 6px' }}>Internal note</span>
        </div>
        <div style={{ border: '1px solid var(--bb-border)', borderRadius: 'var(--bb-radius-sm)', padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          <span className="bb-body" style={{ color: 'var(--bb-text-tertiary)' }}>Upišite odgovor Davoru…</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <BBButton variant="tertiary" asIcon size="sm" iconLeft="attach_file" ariaLabel="Attach" />
            <BBButton variant="tertiary" asIcon size="sm" iconLeft="bolt" ariaLabel="Canned response" />
            <div style={{ flex: 1 }} />
            <BBButton variant="primary" size="sm" iconRight="send">Send reply</BBButton>
          </div>
        </div>
      </div>
    </BBCard>
  );
};

// ── mobile/tablet ticket card ──
const SUPTicketCard = ({ t }) => {
  const pr = SUP_PRIORITY[t.priority];
  const st = SUP_TICKET_STATUS[t.status];
  return (
    <BBCard padded={false}>
      <div style={{ padding: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <BBAvatar name={t.owner} size="sm" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.subject}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{t.owner} · {t.time}</div>
          </div>
          <span style={{ fontSize: 11, fontWeight: 700, color: st.fg, background: st.bg, padding: '3px 9px', borderRadius: 999 }}>{st.label}</span>
        </div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginBottom: 10 }}>{t.preview}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}>
            <span style={{ width: 7, height: 7, borderRadius: '50%', background: pr.color }} />
            <span className="bb-caption" style={{ color: 'var(--bb-text-secondary)', fontWeight: 600 }}>{pr.label}</span>
          </span>
          <SUPCatTag cat={t.cat} />
          <div style={{ flex: 1 }} />
          <SUPSla sla={t.sla} />
        </div>
      </div>
    </BBCard>
  );
};

// ──────────────────────────────────────────────────────────────
// PAGES
// ──────────────────────────────────────────────────────────────
const AdminSupportDesktop = () => (
  <AdminScaffold breakpoint="desktop" active="support" title="Support">
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 16, flexShrink: 0 }}>
        {SUP_STATS.map((s, i) => <SUPStat key={i} s={s} />)}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '380px 1fr', gap: 16, flex: 1, minHeight: 0 }}>
        <SUPQueue selectedId="TK-3041" fillHeight />
        <SUPConversation t={SUP_TICKETS[0]} />
      </div>
    </div>
  </AdminScaffold>
);

const AdminSupportTablet = () => (
  <AdminScaffold breakpoint="tablet" active="support" title="Support">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14, marginBottom: 14 }}>
      {SUP_STATS.map((s, i) => <SUPStat key={i} s={s} compact />)}
    </div>
    <div style={{ display: 'flex', gap: 8, marginBottom: 12, flexWrap: 'wrap' }}>
      {SUP_TABS.map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count} size="sm">{t.label}</BBChip>)}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {SUP_TICKETS.slice(0, 4).map(t => <SUPTicketCard key={t.id} t={t} />)}
    </div>
  </AdminScaffold>
);

const AdminSupportMobile = () => (
  <AdminScaffold breakpoint="mobile" active="support" title="Support">
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10, marginBottom: 12 }}>
      {SUP_STATS.slice(0, 2).map((s, i) => <SUPStat key={i} s={s} compact />)}
    </div>
    <div style={{ display: 'flex', gap: 8, marginBottom: 12, flexWrap: 'wrap' }}>
      {SUP_TABS.slice(0, 3).map(t => <BBChip key={t.id} selected={t.id === 'all'} dotColor={t.dot} count={t.count} size="sm">{t.label}</BBChip>)}
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {SUP_TICKETS.slice(0, 4).map(t => <SUPTicketCard key={t.id} t={t} />)}
    </div>
  </AdminScaffold>
);

Object.assign(window, { AdminSupportDesktop, AdminSupportTablet, AdminSupportMobile });
