/* eslint-disable */
// Booking action dialogs — Prompt 21.
// 5 dialogs sharing one BBDialog base: Approve · Reject · Cancel · Complete · Delete.

const SAMPLE_BOOKING = {
  ref: 'BB-2402',
  guestName: 'Marko Horvat',
  guestEmail: 'marko.horvat@gmail.com',
  property: 'Vila Marina',
  unit: 'Studio 4',
  checkIn: '08.07.2026',
  checkOut: '11.07.2026',
  nights: 3,
  guests: 2,
  total: 360,
  status: 'pending',
};

// ──────────────────────────────────────────────────────────────
// Booking summary header (shared across all 5 dialogs)
// ──────────────────────────────────────────────────────────────
const BookingSummary = ({ booking, status = 'pending' }) => (
  <div style={{
    background: 'var(--bb-surface-variant)',
    border: '1px solid var(--bb-border-subtle)',
    borderRadius: 'var(--bb-radius-sm)',
    padding: 14,
    marginBottom: 20,
  }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
      <BBAvatar name={booking.guestName} size="md" />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{booking.guestName}</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)' }}>{booking.guestEmail}</div>
      </div>
      <BBStatusBadge status={status} size="sm" />
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
      <BBIcon name="apartment" size={14} style={{ color: 'var(--bb-text-tertiary)' }} />
      <span className="bb-caption" style={{ color: 'var(--bb-text-primary)' }}>{booking.property} · {booking.unit}</span>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
      <BBIcon name="event" size={14} style={{ color: 'var(--bb-text-tertiary)' }} />
      <span className="bb-caption" style={{ color: 'var(--bb-text-primary)' }}>
        <span className="bb-tnum">{booking.checkIn}</span> – <span className="bb-tnum">{booking.checkOut}</span>
      </span>
      <span style={{
        background: 'var(--bb-primary-tint-bg)', color: 'var(--bb-primary)',
        padding: '2px 7px', borderRadius: 999, fontSize: 10, fontWeight: 600,
      }}>{booking.nights} noći</span>
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <BBIcon name="receipt" size={14} style={{ color: 'var(--bb-text-tertiary)' }} />
      <span className="bb-mono" style={{ color: 'var(--bb-text-primary)' }}>#{booking.ref}</span>
      <span style={{ flex: 1 }} />
      <span className="bb-tnum" style={{ color: 'var(--bb-text-primary)', fontWeight: 700, fontSize: 14 }}>€{booking.total.toFixed(2).replace('.', ',')}</span>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Textarea + Checkbox helpers
// ──────────────────────────────────────────────────────────────
const Textarea = ({ label, placeholder, defaultValue = '', charLimit, rows = 3, optional = false }) => (
  <div style={{ marginBottom: 20 }}>
    <label className="bb-label" style={{ color: 'var(--bb-text-secondary)', display: 'block', marginBottom: 6 }}>
      {label} {optional && <span style={{ color: 'var(--bb-text-tertiary)', fontWeight: 400 }}>(opcionalno)</span>}
    </label>
    <textarea
      defaultValue={defaultValue}
      placeholder={placeholder}
      rows={rows}
      style={{
        width: '100%', padding: 12,
        border: '1px solid var(--bb-border)',
        borderRadius: 'var(--bb-radius-sm)',
        background: 'var(--bb-surface)',
        fontFamily: 'var(--bb-font-sans)', fontSize: 14, color: 'var(--bb-text-primary)',
        resize: 'vertical', outline: 'none',
      }}
    />
    {charLimit && (
      <div className="bb-caption bb-tnum" style={{ textAlign: 'right', color: 'var(--bb-text-tertiary)', marginTop: 4 }}>
        {defaultValue.length}/{charLimit}
      </div>
    )}
  </div>
);

const Checkbox = ({ label, sub, checked = false }) => (
  <label style={{
    display: 'flex', alignItems: 'flex-start', gap: 12,
    padding: '12px 14px', marginBottom: 16,
    background: 'var(--bb-primary-tint-bg)',
    borderRadius: 'var(--bb-radius-sm)',
    cursor: 'pointer',
  }}>
    <span style={{
      width: 20, height: 20, borderRadius: 6, flexShrink: 0,
      background: checked ? 'var(--bb-primary)' : 'var(--bb-surface)',
      border: `1.5px solid ${checked ? 'var(--bb-primary)' : 'var(--bb-border)'}`,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      marginTop: 2,
    }}>
      {checked && <BBIcon name="check" size={14} style={{ color: '#FFFFFF' }} />}
    </span>
    <div>
      <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600 }}>{label}</div>
      {sub && <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', marginTop: 2 }}>{sub}</div>}
    </div>
  </label>
);

// ──────────────────────────────────────────────────────────────
// Dialog shell — title + body + footer actions, all on BBDialog base
// ──────────────────────────────────────────────────────────────
const DialogShell = ({ icon, iconTone = 'primary', title, sub, children, primary, secondary, width = 480, primaryDisabled = false }) => {
  const toneBg = {
    primary: 'var(--bb-primary-tint-bg)',
    success: 'var(--bb-success-tint)',
    error: 'var(--bb-error-tint)',
    tertiary: 'var(--bb-tertiary-tint)',
    info: 'var(--bb-info-tint)',
  };
  const toneFg = {
    primary: 'var(--bb-primary)',
    success: 'var(--bb-success)',
    error: 'var(--bb-error)',
    tertiary: 'var(--bb-tertiary-dark)',
    info: 'var(--bb-info)',
  };
  return (
    <div style={{
      width,
      background: 'var(--bb-surface)',
      borderRadius: 'var(--bb-radius-lg)',
      boxShadow: 'var(--bb-shadow-lg)',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{ padding: '24px 24px 0', display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12, flexShrink: 0,
          background: toneBg[iconTone], color: toneFg[iconTone],
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <BBIcon name={icon} size={24} />
        </div>
        <div style={{ flex: 1 }}>
          <h3 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h3>
          {sub && <p className="bb-caption" style={{ margin: '4px 0 0', color: 'var(--bb-text-secondary)' }}>{sub}</p>}
        </div>
        <button type="button" aria-label="Zatvori" style={{
          width: 36, height: 36, border: 'none', borderRadius: 'var(--bb-radius-sm)',
          background: 'transparent', color: 'var(--bb-text-tertiary)', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <BBIcon name="close" size={20} />
        </button>
      </div>
      {/* Body */}
      <div style={{ padding: '20px 24px 0' }}>
        {children}
      </div>
      {/* Footer */}
      <div style={{
        padding: '16px 24px 24px',
        display: 'flex', justifyContent: 'flex-end', gap: 8,
      }}>
        {secondary && <BBButton variant="tertiary">{secondary.label}</BBButton>}
        {primary && (
          <BBButton variant={primary.variant || 'primary'} iconLeft={primary.iconLeft} disabled={primaryDisabled}>
            {primary.label}
          </BBButton>
        )}
      </div>
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// 5 dialogs
// ──────────────────────────────────────────────────────────────
const ApproveDialog = () => (
  <DialogShell
    icon="check_circle"
    iconTone="success"
    title="Potvrdi rezervaciju"
    sub="Gost će biti obaviješten emailom."
    primary={{ label: 'Potvrdi', variant: 'primary', iconLeft: 'check' }}
    secondary={{ label: 'Odustani' }}
  >
    <BookingSummary booking={SAMPLE_BOOKING} status="pending" />
  </DialogShell>
);

const RejectDialog = () => (
  <DialogShell
    icon="block"
    iconTone="error"
    title="Odbij rezervaciju"
    sub="Gost će dobiti email o odbijanju."
    primary={{ label: 'Odbij', variant: 'destructive' }}
    secondary={{ label: 'Odustani' }}
  >
    <BookingSummary booking={SAMPLE_BOOKING} status="pending" />
    <Textarea
      label="Razlog odbijanja"
      optional
      placeholder="npr. Datumi nisu više dostupni, traženje grupe veće od kapaciteta…"
      rows={3}
      charLimit={500}
    />
  </DialogShell>
);

const CancelDialog = () => (
  <DialogShell
    icon="event_busy"
    iconTone="error"
    title="Otkaži rezervaciju"
    sub="Razlog je obavezan za sve otkazivanja od strane vlasnika."
    primary={{ label: 'Otkaži rezervaciju', variant: 'destructive' }}
    secondary={{ label: 'Odustani' }}
  >
    <BookingSummary booking={{ ...SAMPLE_BOOKING, ref: 'BB-2398' }} status="confirmed" />
    <Textarea
      label="Razlog otkazivanja"
      placeholder="Bit će prikazan u Stripe povratu novca i u emailu gostu."
      defaultValue="Hitan kvar bojlera — apartman privremeno nedostupan."
      rows={3}
      charLimit={500}
    />
    <Checkbox
      label="Pošalji email gostu"
      sub="Preporučeno. Stripe povrat se pokreće automatski."
      checked
    />
  </DialogShell>
);

const CompleteDialog = () => (
  <DialogShell
    icon="task_alt"
    iconTone="primary"
    title="Završi rezervaciju"
    sub="Označi check-out kao gotov."
    primary={{ label: 'Završi', variant: 'primary', iconLeft: 'check' }}
    secondary={{ label: 'Odustani' }}
  >
    <BookingSummary booking={{ ...SAMPLE_BOOKING, ref: 'BB-2391', status: 'confirmed', total: 540 }} status="confirmed" />
  </DialogShell>
);

const DeleteDialog = () => (
  <DialogShell
    icon="delete_forever"
    iconTone="error"
    title="Obriši rezervaciju TRAJNO"
    sub="Ova akcija se ne može poništiti."
    primary={{ label: 'Obriši zauvijek', variant: 'destructive', iconLeft: 'delete_forever' }}
    secondary={{ label: 'Odustani' }}
    primaryDisabled
  >
    <BookingSummary booking={{ ...SAMPLE_BOOKING, ref: 'BB-2385' }} status="completed" />
    <div style={{
      padding: '12px 14px',
      background: 'var(--bb-error-tint)',
      border: '1px solid rgba(255,107,107,0.32)',
      borderRadius: 'var(--bb-radius-sm)',
      marginBottom: 16,
      display: 'flex', gap: 10, alignItems: 'flex-start',
    }}>
      <BBIcon name="warning" size={20} style={{ color: 'var(--bb-error)', flexShrink: 0, marginTop: 2 }} />
      <div>
        <div className="bb-label" style={{ color: 'var(--bb-error)', fontWeight: 600 }}>Trajna akcija</div>
        <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)', marginTop: 4 }}>
          Brišu se svi povezani podaci: plaćanja, povijest poruka, recenzije. Plaćanja se NE vraćaju automatski — koristite Otkaži ako želite povrat.
        </div>
      </div>
    </div>
    <BBInput label="Upišite OBRIŠI za potvrdu" placeholder="OBRIŠI" iconLeft="keyboard" />
  </DialogShell>
);

// ──────────────────────────────────────────────────────────────
// Cancel — mobile bottom-sheet treatment
// ──────────────────────────────────────────────────────────────
const CancelBottomSheet = () => (
  <div style={{
    width: 390, background: 'var(--bb-surface)',
    borderRadius: 'var(--bb-radius-lg) var(--bb-radius-lg) 0 0',
    boxShadow: 'var(--bb-shadow-lg)',
    overflow: 'hidden',
  }}>
    {/* Handle bar */}
    <div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0 4px' }}>
      <span style={{ width: 40, height: 4, borderRadius: 999, background: 'var(--bb-border)' }} />
    </div>
    {/* Header */}
    <div style={{ padding: '12px 20px 0', display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{
        width: 40, height: 40, borderRadius: 10, flexShrink: 0,
        background: 'var(--bb-error-tint)', color: 'var(--bb-error)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <BBIcon name="event_busy" size={22} />
      </div>
      <div style={{ flex: 1 }}>
        <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>Otkaži rezervaciju</h3>
        <p className="bb-caption" style={{ margin: '2px 0 0', color: 'var(--bb-text-secondary)' }}>Razlog je obavezan.</p>
      </div>
    </div>
    {/* Body */}
    <div style={{ padding: '16px 20px 0' }}>
      <BookingSummary booking={{ ...SAMPLE_BOOKING, ref: 'BB-2398' }} status="confirmed" />
      <Textarea
        label="Razlog otkazivanja"
        placeholder="Bit će prikazan gostu."
        defaultValue="Hitan kvar bojlera."
        rows={2}
      />
      <Checkbox label="Pošalji email gostu" checked />
    </div>
    {/* Sticky footer */}
    <div style={{
      padding: '12px 20px 24px',
      display: 'flex', gap: 8,
      borderTop: '1px solid var(--bb-border-subtle)',
    }}>
      <BBButton variant="tertiary" fullWidth>Odustani</BBButton>
      <BBButton variant="destructive" fullWidth>Otkaži rezervaciju</BBButton>
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// Gallery layouts
// ──────────────────────────────────────────────────────────────
const DialogsDesktopGallery = () => (
  <div style={{
    width: 1200,
    padding: 48,
    background: 'rgba(13, 17, 28, 0.78)',
    fontFamily: 'var(--bb-font-sans)',
    minHeight: 1280,
  }} className="theme-light">
    <div style={{ color: '#FFFFFF', textAlign: 'center', marginBottom: 32 }}>
      <div className="bb-eyebrow" style={{ color: 'rgba(255,255,255,0.7)' }}>Prompt 21 · Unified base</div>
      <h2 className="bb-h1" style={{ margin: '4px 0 0' }}>Booking action dialogs</h2>
      <p className="bb-body" style={{ margin: '6px 0 0', color: 'rgba(255,255,255,0.78)' }}>
        All 5 share: BBDialog base · booking summary header · role-colored CTA · mobile-auto bottom-sheet.
      </p>
    </div>
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(2, 1fr)',
      gap: 32, justifyItems: 'center',
    }}>
      <ApproveDialog />
      <RejectDialog />
      <CancelDialog />
      <CompleteDialog />
      <div style={{ gridColumn: '1 / span 2', display: 'flex', justifyContent: 'center' }}>
        <DeleteDialog />
      </div>
    </div>
  </div>
);

const DialogsMobileSheet = () => (
  <div style={{
    width: 390, height: 880,
    background: 'rgba(13, 17, 28, 0.55)',
    fontFamily: 'var(--bb-font-sans)',
    position: 'relative',
  }} className="theme-light">
    {/* Mock content behind the sheet (to give context) */}
    <div style={{
      position: 'absolute', inset: 0, padding: 16,
      background: 'var(--bb-bg)',
      opacity: 0.4,
    }}>
      <div style={{ height: 56, background: 'var(--bb-surface)', borderRadius: 12, marginBottom: 16 }} />
      <div style={{ height: 220, background: 'var(--bb-surface)', borderRadius: 16, marginBottom: 12 }} />
      <div style={{ height: 80, background: 'var(--bb-surface)', borderRadius: 16, marginBottom: 12 }} />
    </div>
    {/* Scrim */}
    <div style={{
      position: 'absolute', inset: 0,
      background: 'rgba(13, 17, 28, 0.46)',
      backdropFilter: 'blur(2px)', WebkitBackdropFilter: 'blur(2px)',
    }} />
    {/* Sheet */}
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}>
      <CancelBottomSheet />
    </div>
  </div>
);

Object.assign(window, {
  DialogsDesktopGallery,
  DialogsMobileSheet,
});
